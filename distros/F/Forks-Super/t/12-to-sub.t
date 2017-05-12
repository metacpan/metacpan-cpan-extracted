use Forks::Super ':test';
use Test::More tests => 29;
use strict;
use warnings;

#
# test forking a child process and invoking a Perl subroutine
#


#
# a mock internal command that can
#    * delay before returning
#    * produce simple output to stdout or to file
#    * collect simple env info like PID
#    * exit with arbitrary status
#
# See t/external-command.pl
#
sub internal_command {
    my (@args) = @_;
    my $out;
    foreach my $arg (@args) {
	my ($key,$val) = split /=/, $arg;
	if ($key eq "--output" or $key eq "-o") {
	    open($out, ">", $val);
	    select $out;
	    $out->autoflush(1);
	} elsif ($key eq "--echo" or $key eq "-e") {
	    print $val, " ";
	} elsif ($key eq "--ppid" or $key eq "-p") {
	    my $pid = $$;
      print $pid, " ";
	} elsif ($key eq "--sleep" or $key eq "-s") {
	    sleep $val || 1;
	} elsif ($key eq "--exit" or $key eq "-x") {
	    select STDOUT;
	    close $out;
	    exit($val || 0);
	}
    }
    select STDOUT;
    close $out;
}

my $output = "t/out/test12.$$";

# test fork => $::

unlink $output;
my $pid = fork { sub => 'main::internal_command',
		args => [ "-o=$output", "-e=Hello,", 
                          "-e=Wurrled", "-p" ] };
ok(isValidPid($pid), 
   "fork to \$qualified::subroutineName successful, pid=$pid");
my $p = wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? $? == 0");                       ### 3 ###
my $z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
my $target_z = "Hello, Wurrled $pid";
ok($z eq $target_z, 
	"child produced child output \'$z\' vs. \'$target_z\'");

#############################################################################

# test fork => $

unlink $output;
$pid = fork { sub => 'internal_command',
	      args => [ "-o=$output", "-e=Hello,", 
                        "-e=Wurrled", "-p" ] };
ok(isValidPid($pid), "fork to \$subroutineName successful, pid=$pid");
$p = wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? $? == 0");                       ### 7 ###
$z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
$target_z = "Hello, Wurrled $pid";
ok($z eq $target_z, 
	"child produced child output \'$z\' vs. \'$target_z\'");

#############################################################################

# test  fork  sub => \&

unlink $output;
$pid = fork { sub => \&internal_command,
		args => ["-o=$output", "-e=Hello,", "-e=Wurrled", "-p" ] };
ok(isValidPid($pid), "fork to \\\&subroutine successful");
$p = wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? $? == 0");
$z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
$target_z = "Hello, Wurrled $pid";
ok($z eq $target_z,
	"child produced child output \'$z\' vs. \'$target_z\'");

#############################################################################

# test fork to anonymous sub

unlink $output;
$pid = fork { sub => sub { my (@x) = @_;
			   open(my $T, ">", $output);
			   print $T "@x - $$\n";
			   close $T;
			   exit 14;
			 },
			   args => [ "Hello", "-", "World" ] };
ok(isValidPid($pid), "fork to anonymous sub successful");
$p = wait;

# failure point on linux under load ...

ok($?>>8 == 14, "child STATUS \$? $? != 0");     ### 14 ###
ok($pid == $p, "wait reaped child $pid == $p");  ### 15 ###
$z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
$target_z = "Hello - World - $pid";
ok($z eq $target_z,
	"child produced child output \'$z\' vs. \'$target_z\'");

#############################################################################

# test that timing of reap is correct

my $u = Time::HiRes::time();
$pid = fork { sub => sub { sleep 3 } };
ok(isValidPid($pid), "fork to sleepy sub ok");
my $t = Time::HiRes::time();
$p = wait;
my $v = Time::HiRes::time();
($t,$u) = ($v-$t, $v-$u);
ok($p == $pid, "wait on sleepy sub ok");         ### 18 ###
okl($u >= 2.05 && $t <= 5.75,                     ### 19 ### was 4 obs 5.68,2.09
   "background sub ran ${t}s ${u}s, expected 3-4s");

##################################################################

# test exit status

$pid = fork { sub => sub { exit 7 } };
ok(isValidPid($pid), "fork to false sub ok");
$p = Forks::Super::wait;
ok($p == $pid, "wait on false sub ok");
ok($?>>8 == 7, "captured correct non-zero STATUS $?");
ok($Forks::Super::ALL_JOBS{$pid}->{status} == 7 << 8,
   "captured exit status from sub with exit statement");

##################################################################

$pid = fork { sub => sub {} };
ok(isValidPid($pid), "fork to trivial sub ok");
$p = wait;
ok($? == 0, "captured correct zero STATUS $? from trivial sub");
ok($p == $pid, "wait on trivial sub ok");

##################################################################

# test fork sub { ... } syntax (v0.72)

$u = Time::HiRes::time();
$pid = fork sub { sleep 3 };
ok(isValidPid($pid), "fork sub {...} syntax ok");
$t = Time::HiRes::time();
$p = wait;
$v = Time::HiRes::time();
($t,$u) = ($v-$t, $v-$u);
ok($p == $pid, "wait on fork sub {...} proc ok");         ### 28 ###
okl($u >= 2.35 && $t <= 5.75,                     ### 29 ### was 4 obs 5.68,2.36
   "fork sub {...} proc ran ${t}s ${u}s, expected 3-4s");

#############################################################################

unlink $output;

