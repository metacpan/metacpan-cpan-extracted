use Forks::Super ':test';
use Test::More tests => 3;
use Carp;
use strict;
use warnings;

# force loading of more modules in parent proc
# so fast fail (see test#17, test#8) isn't slowed
# down so much
Forks::Super::Job::Timeout::warm_up();

#
# test that jobs respect deadlines for jobs to
# complete when the jobs specify "timeout" or
# "expiration" options
#

#######################################################

my $future = Time::HiRes::time() - 5;
my $pid = fork { sub => sub { sleep 5; exit 0 }, expiration => $future };
my $t = Time::HiRes::time();
my $p = wait;
$t = Time::HiRes::time() - $t;
ok($p == $pid, "wait succeeded");
# A "fast fail" can still take longer than a second. 
# "fast fail" invokes Carp::croak, which wants to load
# Carp::Heavy, Scalar::Util, List::Util, List::Util::XS.
# That can add up.
#okl($t <= 1.0, "expected fast fail took ${t}s"); ### 17 ###
okl($t <= 1.9, "expected fast fail took ${t}s"); ### 17 ###
ok($? != 0, "job expired with non-zero exit STATUS");

#######################################################

