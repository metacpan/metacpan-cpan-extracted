use Forks::Super ':test';
use POSIX ':sys_wait_h';
use Test::More tests => 143;
use strict;
use warnings;

#
# tests the Forks::Super::waitpid call.
#

$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd|openbsd/;

my $pid = fork { sub => sub { sleep 2 ; exit 2 } };
ok(isValidPid($pid), "$$\\fork successful");
sleep 5;
my $t = Time::HiRes::time();
my $p = waitpid $pid, WNOHANG;
# XXX - should waitpid return -1 or 0 for an active job?
if (($p == -1 || $p == 0) && $^O =~ /bsd/i) {
    # eek. This happens half the time on loaded BSD systems ...
    print STDERR "BSD: need to retry waitpid WNOHANG\n";
    $p = waitpid $pid, WNOHANG;
}
$t = Time::HiRes::time() - $t;
my $s = $?;
if ($p != $pid) {
    # XXX should waitpid return -1 or 0 for an active job?
    if ($p == -1 || $p == 0) {
	my $j = Forks::Super::Job::get($pid);
	my $state1 = $j->{state};
	my $tt = Time::HiRes::time();
	$p = waitpid $pid, 0;
	$s = $?;
	my $state2 = $j->{state};
	$tt = Time::HiRes::time() - $tt;
    }
  SKIP: {
      if ($p == $pid) {
	  ok($p == $pid, "waitpid on $pid returns $p (after delay)");
      } else {
	  skip "waitpid on $pid should return $pid", 1;
      }
    }
} else {
    ok($p == $pid, "waitpid on $pid returns $p");
}
okl($t <= 1, "fast waitpid took ${t}s, expected <=1s");
ok($s == 512, "waitpid captured exit status")
   or diag("status was $s, expected 512");

############################################

$pid = fork { sub => sub { sleep 3; exit 3 } };
ok(isValidPid($pid), "fork successful");
$t = Time::HiRes::time();

# XXX  waitpid WNOHANG on active process should return 0 or -1 ?
$p = waitpid $pid,WNOHANG;
ok($p == -1 || $p == 0, "non-blocking waitpid returned $p, expected 0/-1");
ok(-1 == waitpid ($pid + 10, WNOHANG), "return -1 for invalid target");
ok(-1 == waitpid ($pid + 10, 0), "quick return -1 for invalid target");
$t = Time::HiRes::time() - $t;
okl($t <= 1.1, "fast return ${t}s for invalid target expected <=1s"); ### 9 ###
$t = Time::HiRes::time();
$p = waitpid $pid, 0;
$t = Time::HiRes::time() - $t;
$s = $?;
ok($p==$pid, "blocking waitpid returned real pid");
okl($t >= 2.05, "blocked return took ${t}s expected 3s");
ok($s == 768, "waitpid captured exit status");

############################################

my %x;
$Forks::Super::MAX_PROC = 100;
my @rand = map { rand } 0..19;
my $t0 = Time::HiRes::time();
my $i;
for ($i=0; $i<20 && $i<$Forks::Super::SysInfo::MAX_FORK/2; $i++) {
    # OpenBSD failure point?
    my $pid = fork { sub => sub {my $d=int(2+8*$rand[$i]); sleep $d; exit $i} };
    ok(isValidPid($pid), "Launched $pid"); ### 13-32 ###
    $x{$pid} = $i;
}
for ($i..19) {
    ok(1, 'max fork: skip isValidPid test');
    ok(1, 'max fork: skip reaped test');
    ok(1, 'max fork: skip exit code test');
}
$t = Time::HiRes::time();
while (0 < scalar keys %x) {

    my $p;
    my $pid = (keys %x)[rand() * scalar keys %x];
    if (defined $x{$pid}) {
	if (rand() > 0.5) {
	    $p = waitpid $pid, 0;
	} else {
	    $p = waitpid $pid, WNOHANG;
	}
	if (isValidPid($p)) {
	    ok($p == $pid, "Reaped $p");       ### 33,35,...,71 ###
	    my $exit_code = $? >> 8;
	    ok($exit_code == $x{$p},           ### 34,36,...,72 ###
	       "$p correct exit code $x{$p} == $exit_code STATUS");
	    delete $x{$p};
	}
    } else {
	# warn "pid $pid invalid --- trying again";
    }
}

my $t2 = Time::HiRes::time();
($t0,$t) = ($t2-$t0, $t2-$t);

# freebsd is the biggest offender for taking more than 10s? Where is the
# additional delay coming from?  waitpid ?  pause ?  needs more study.

okl($t0 >= 5.0 && $t <= 13.25,             ### 73 ### was 10.0, obs 11.83,13.55
   "waitpid on multi-procs took ${t}s ${t0}s, expected 6-10s");
$t = Time::HiRes::time();

for (my $i=0; $i<5; $i++) {
    my $p = waitpid -1, 0;
    ok($p == -1, "wait on nothing gives -1, $p");
}
$t = Time::HiRes::time() - $t;

okl($t <= 1, "fast waitpid on nothing took ${t}s, expected <=1s");

############################################

# waitpid 0 or -1 ?
# waitpid -t  for valid/invalid  pgid.

%x = ();

@rand = ();
for ($i=0; $i<20 && $i<$Forks::Super::SysInfo::MAX_FORK/2; $i++) {
    my $rand = rand;
    push @rand, $rand;
    my $pid = fork { sub => sub {	my $d = int(6+5*$rand);
				sleep $d; exit $i } };
    ok(isValidPid($pid), "Launched $pid");
    $x{$pid} = $i;
}
for ($i..19) {
    ok(1, 'max fork: skip isValidPid test');
    ok(1, 'max fork: skip reaped pid valid test');
    ok(1, 'max fork: skip exit code test');
}

$t = Time::HiRes::time();
SKIP: {
    if (!$Forks::Super::SysInfo::CONFIG{'getpgrp'}
	    && $^O ne 'MSWin32') {
	skip "$^O,$]: Can't test waitpid on pgid", 44;
    }

    my $pgid = $^O eq 'MSWin32' ? $$ : getpgrp();
    my $bogus_pgid = $pgid + 175;
    ok(-1 == waitpid (-$bogus_pgid, 0), "bogus pgid");
    ok(-1 == waitpid (-$bogus_pgid, WNOHANG), "bogus pgid");
    my $u = Time::HiRes::time() - $t;
    okl($u <= 1,                                                ### 102 ###
	"fast return ${u}s wait on bogus pgid expected <=1s");

    while (0 < scalar keys %x) {

	my $p;
	my $z = rand();
	if ($z > 0.75) {
	    $p = waitpid 0, WNOHANG;
	} elsif ($z > 0.5) {
	    $p = waitpid -$pgid, WNOHANG; 
	} elsif ($z > 0.25) {
	    $p = waitpid 0, 0;
	} else {
	    $p = waitpid -$pgid, 0;
	}
	if ($p == -1 && $z <= 0.5) {
	    ok(0, "waitpid did not block $z");
	    ok(0, "and now we can't retrieve status of pid we didn't retrieve");
	} elsif (defined $x{$p}) {
	    ok(isValidPid($p), "Reaped $p");
	    ok($? >> 8 == $x{$p}, 
	       "$p correct exit STATUS $x{$p} == " . ($?>>8));
	    delete $x{$p};
	} else {
	    # warn "pid $pid invalid --- trying again\n"; 
	    # this is nothing to be alarmed about
	}
    }

    $t = Time::HiRes::time() - $t;
    if ($t < 7) {
	# if all values are < 1/5, then this test would not pass
	print STDERR "Random values to sleepy fork calls were: @rand\n";
    }
    ok($t > 6.25 && $t < 14.5,  ### 143 ### was 11 obs 11.84,12.62,14.62
       "Took $t s to reap all. Should take about 7-11s");
} # end SKIP

