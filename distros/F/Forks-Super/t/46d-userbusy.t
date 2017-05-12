use Forks::Super ':test';
use Test::More tests => 9;
use strict;
use warnings;

#
# user can supply their own subroutine to decide
# whether the system is too busy to fork a new
# process.
#

sub do_launch { 1; }
sub dont_launch { 0; }
my $launch_after_nap = sub { sleep 10; return 1 };
my $sleepy = sub { return sleep 30 };

sub dont_launch_external {
    # block jobs that invoke external commands
    # but use the default handler for other jobs
    my $job = shift;
    bless $job, "Forks::Super::Job";
    return 0 if defined $job->{cmd};
    return $job->_can_launch;
}

$Forks::Super::MAX_PROC = sub { 1 };
$Forks::Super::ON_BUSY = "fail";

my $pid = fork { sub => $sleepy };
ok(isValidPid($pid), "successful fork");
my $pid2 = fork { sub => $sleepy };
ok(!isValidPid($pid2), "failed fork") or diag "current script age: ",time-$^T;
my $pid3 = fork { sub => $sleepy , can_launch => 'main::do_launch' };
ok(isValidPid($pid3), "successful user fork");
my $t = Time::HiRes::time();
my $pid4 = fork { sub => $sleepy , can_launch => $launch_after_nap };
$t = Time::HiRes::time() - $t;
ok(isValidPid($pid4), "successful delayed fork");
okl($t >= 8.8, "fork was delayed ${t}s expected >10s");

$Forks::Super::MAX_PROC = sub { 50 };
my $pid5 = fork { sub => $sleepy };
ok(isValidPid($pid5), "successful fork");
my $pid6 = fork { sub => $sleepy , can_launch => \&dont_launch };
ok(!isValidPid($pid6), "force failed fork");

# PERL_SIGNALS=unsafe: can hang here

my @to_kill = grep { isValidPid($_) 
		   } ($pid, $pid2, $pid3, $pid4, $pid5, $pid6);
if ($^O eq 'MSWin32') {
   diag("This is pid $$. Sending SIGTERM to: @to_kill");
}
Forks::Super::kill('TERM', @to_kill) if @to_kill > 0;
waitall;

$Forks::Super::MAX_PROC = sub { 3 };
my $pid7 = fork { cmd => [ $^X,"t/external-command.pl", "-e=Hello" ],
		 can_launch => \&dont_launch_external };
my $pid8 = fork { sub => sub { sleep 2 } };
ok(!isValidPid($pid7), "failed fork with logic");
ok(isValidPid($pid8), "successful fork with logic");
waitall;

