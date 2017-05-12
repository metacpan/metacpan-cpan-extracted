use Forks::Super ':test';
use Forks::Super::SysInfo;
use Test::More tests => 301;
use Carp;
use strict;
use warnings;

#
# arrange for many jobs to finish at about the same time.
# Is the signal handler able to handle all the SIGCHLDs and reap all the 
# jobs on time? If not, do we invoke the signal handler manually and reap the
# unhandled jobs in a timely way?
# 

#
# solaris seems to have particular trouble with this test -- the script
# often aborts
#

# $SIG_DEBUG is special flag to instruct SIGCHLD handler to record what goes on
$Forks::Super::Sigchld::SIG_DEBUG = 1;
$Forks::Super::MAX_PROC = 1000;

SKIP: {
    if ($ENV{WRONG_MAKEFILE_OK}) {
	skip "ok to run $0 with inconsistent version of perl", 2;
    }
    ok($Forks::Super::SysInfo::SYSTEM eq $^O,
       "Forks::Super::SysInfo configured for "
       . "$Forks::Super::SysInfo::SYSTEM==$^O");
    ok($Forks::Super::SysInfo::PERL_VERSION <= $],
       "Forks::Super::SysInfo configured for "
       . "$Forks::Super::SysInfo::PERL_VERSION<=$]");
}

my $NN = 149;
my $nn = $NN;
SKIP: {
    $nn = int(0.5 * $Forks::Super::SysInfo::MAX_FORK) || 5;
    if ($ENV{WRONG_MAKEFILE_OK}) {
	$nn = 10;  # safe low number
    }
    $nn = $NN if $nn > $NN;

    # solaris tends to barf on this test even though it passes the others.
    # (raises SIGSYS? can that be trapped?)
    # This test was disabled on solaris for a long time.
    # Reenable with v0.38 and see if this test can pass now.
    if ($^O =~ /solaris/) {
	$nn = 9 if $nn > 9;
    }

    # use a less stressful stress test on freebsd
    if ($^O =~ /freebsd/) {
        $nn = 49 if $nn > 49;
    }


    if ($nn < $NN) {
	skip "Max ~$nn proc on $^O v$], can only do ".((2*$nn)+1)." tests", 
	2*($NN-$nn);
    }
}


print "\$nn is $nn $NN\n";

my $THR_avail = Forks::Super::Config::CONFIG_module("Time::HiRes");
for (my $i=0; $i<$nn; $i++) {
    # failure point on some systems: 
    #    Maximal count of pending signals (nnn) exceeded

    my $pid = fork { sub => sub { sleep 5 } };
    if (!isValidPid($pid)) {
	croak "fork failed i=$i/$nn OS=$^O V=$]";
    }
    $THR_avail && Time::HiRes::sleep(0.001);
}

for (my $i=0; $i<$nn; $i++) {
    &check_CHLD_handle_history_for_interleaving;
    my $p = wait 15;
    ok(isValidPid($p), "reaped $p");
}

#print @Forks::Super::CHLD_HANDLE_HISTORY;
my $p = wait 2;
ok($p == -1, "Nothing to reap");


sub check_CHLD_handle_history_for_interleaving {
    my $start = 0;
    my $end = 0;
    my $fail = 0;
    foreach my $h (@Forks::Super::CHLD_HANDLE_HISTORY) {
	$start++ if $h =~ /start/;
	$end++ if $h =~ /end/;
	if ($start-$end > 1) {
	    $fail++;
	}
    }
    $fail+=100 if $start > $end;
    ok($fail == 0, "CHLD_handle history consistent " . 
       scalar @Forks::Super::CHLD_HANDLE_HISTORY . " records fail=$fail");

    return $test::fail = $fail;
}
if ($test::fail > 0) {
    print STDERR "Errors in $0\n";
    print STDERR "Writing SIGCHLD handler history to\n";
    print STDERR "'t/out/sigchld.debug.$$' for analysis.\n";
    open(my $D, ">", "t/out/sigchld.debug.$$");
    print $D @Forks::Super::CHLD_HANDLE_HISTORY;
    close $D;
}
