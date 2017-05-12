use Forks::Super ':test';
use Test::More tests => 3;
use Carp;
use strict;
use warnings;


if ($^O eq 'MSWin32') {
    Forks::Super::Config::CONFIG_module("Win32::API");
    if ($Win32::API::VERSION && $Win32::API::VERSION < 0.71) {
	warn qq[

Win32::API v$Win32::API::VERSION found. v>=0.71 may be required
to pass this test and use the features exercised by this test.

];
    }
}

# force loading of more modules in parent proc
# so fast fail (see test#17, test#8) isn't slowed
# down so much
Forks::Super::Job::Timeout::warm_up();

#
# test that jobs respect deadlines for jobs to
# complete when the jobs specify "timeout" or
# "expiration" options
#

SKIP: {

##########################################################

    my $t0 = Time::HiRes::time();
    my $pid = fork { cmd => [ $^X, "t/external-command.pl", "-s=15" ], 
		   timeout => 2 };
    my $t = Time::HiRes::time();
    waitpid $pid, 0;
    my $t2 = Time::HiRes::time();
    ($t0,$t) = ($t2-$t0,$t2-$t);
    okl($t <= 6.95,             ### 1 ### was 3.0 obs 3.10,3.82,4.36,6.63,9.32
	"cmd-style respects timeout ${t}s ${t0}s "
	."expected ~2s"); 

    $t0 = Time::HiRes::time();
    $pid = fork { exec => [ $^X, "t/external-command.pl", "-s=11" ], 
		  timeout => 2 };
    $t = Time::HiRes::time();
    waitpid $pid, 0;
    $t2 = Time::HiRes::time();
    ($t0,$t) = ($t2-$t0,$t2-$t);
    okl($t < 7 && $t0 < 7.5, ### 2 ### obs 7.30
	'exec-style DOES respect timeout (since v0.55) '
	. "${t}s ${t0}s expected ~2s");

    # make sure timeout works with command with metacharacters
    $t0 = Time::HiRes::time();
    $pid = fork { exec => [ $^X, "t/external command.pl", "-s=11" ], 
		  timeout => 2 };
    $t = Time::HiRes::time();
    waitpid $pid, 0;
    $t2 = Time::HiRes::time();
    ($t0,$t) = ($t2-$t0,$t2-$t);
    okl($t < 7 && $t0 < 7.5, ### 2 ### obs 7.30
	'exec-style DOES respect timeout (since v0.55) '
	. "${t}s ${t0}s expected ~2s");

######################################################################

} # end SKIP
