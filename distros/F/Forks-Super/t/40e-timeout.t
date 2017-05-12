use Forks::Super ':test';
use Test::More tests => 3;
use Carp;
use strict;
use warnings;

# force loading of more modules in parent proc
# so fast fail tests aren't slowed down so much
Forks::Super::Job::Timeout::warm_up();

#
# test that jobs respect deadlines for jobs to
# complete when the jobs specify "timeout" or
# "expiration" options
#

my $future = Time::HiRes::time() + 15;
my $pid = fork { sub => sub { sleep 5; exit 0 }, expiration => $future };
my $t = Time::HiRes::time();
my $p = wait;
$t = Time::HiRes::time() - $t;
ok($p == $pid, "wait successful");
okl($t < 10, "job completed before expiration ${t}s expected ~5s");
ok($? == 0, "job completed with zero exit STATUS");
