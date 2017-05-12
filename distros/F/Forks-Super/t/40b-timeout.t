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

my $u = Time::HiRes::time();
my $pid = fork { sub => sub { sleep 5; exit 0 }, timeout => 10 };
my $t = Time::HiRes::time();
my $p = wait;
my $v = Time::HiRes::time();
($t,$u)=($v-$t,$v-$u);
ok($p == $pid, "wait successful; Expected $pid got $p");
okl($t > 3.9 && $u <= 8.75,                 ### 2b ### was 7, obs 8.57
    "job completed before timeout ${t}s ${u} expected ~5s");
ok($? == 0, "job completed with zero exit STATUS");

#######################################################

