use Forks::Super ':test';
use Test::More tests => 3;
use Carp;
use strict;
use warnings;

############################################################
# IF THIS TEST FAILS (AND PARTICULARLY IF IT HANGS):
# your system may benefit from using the "poor man's alarm".
# Try setting  $PREFER_ALTERNATE_ALARM = 1
# in  lib/Forks/Super/SysInfo.pm  or run  Makefile.PL
# with the environment variable "PREFER_ALT_ALARM" set to
# a true value.
# Also try running the script  spike-pma.pl  in this
# distribution and report the results (output and exit
# status) to  mob@cpan.org
#############################################################

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

#SKIP: {

#######################################################

my $now = Time::HiRes::time();
my $future = Time::HiRes::time() + 3;
my $pid = fork { sub => sub { sleep 20; exit 0 },
		 debug => $^O =~ /freebsd/i ? 1 : 0,
		 expiration => $future };
my $t = Time::HiRes::time();
my $p = wait;
$t = Time::HiRes::time() - $t;
ok($p == $pid, "$$\\wait successful");
okl($t < 9.95, "wait took ${t}s, expected ~3s");                    ### 2 ###

## this is an intermittent (5%?) failure point on solaris, v0.44-0.49.
ok($? != 0, "job expired with non-zero STATUS $? should be != 0"); ### 3 ###

#######################################################

#} # end SKIP
