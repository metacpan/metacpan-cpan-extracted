use Forks::Super ':test';
use Test::More tests => 9;
use POSIX ':sys_wait_h';
use strict;
use warnings;

##################################################################
# wait(timeout)

$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd/;

my $t = Time::HiRes::time();
my $pid = fork { sub => sub { sleep 2 } };
my $p = wait;
$t = Time::HiRes::time() - $t;
okl($t >= 1.60, "wait waits for job to finish ${t}s expected ~2s"); #obs 1.66
ok($p == $pid, "wait returns pid of job");

$t = Time::HiRes::time();
$pid = fork { sub => sub { sleep 2 } };
$p = wait 8;
$t = Time::HiRes::time() - $t;
okl($t >= 1.60 && $t <= 5.5,          ### 3 ### was 2.85 obs 3.16,3.93,1.62
   "wait with long timeout returned when job finished ${t}s expected ~2s");
ok($p == $pid, "wait with long timeout returns pid of job $p==$pid");
$p = wait 4;
ok($p == -1, "wait returns $p==-1 when nothing to wait for");

$t = Time::HiRes::time();
$pid = fork { sub => sub { sleep 6 } };
my $t2 = Time::HiRes::time();
$p = wait 3;
my $t3 = Time::HiRes::time();
($t,$t2) = ($t3-$t,$t3-$t2);
okl($t2 >= 1.2 && $t2 <= 4.5,         ### 6 ###
   "wait with short timeout returns at end of timeout ${t}s ${t2}s "
   . "expected ~3s");     # obs 1.23

# failure point on 0.85/netbsd
ok($p == &Forks::Super::Wait::TIMEOUT, "wait timeout returns TIMEOUT")
    or diag "wait rv was $p, expected TIMEOUT";    ### 7 ###
$t2 = Time::HiRes::time();
$p = wait(12);
$t2 = Time::HiRes::time() - $t2;
okl($t2 > 1.20 && $t2 <= 6.5,        ### 8 ### was 2.85, obs 4.37,5.62,1.22
   "subsequent wait with long timeout returned when job finished "
   . "in ${t2}s, expected ~3s");
ok($p == $pid, 
   "wait with subsequent long timeout returns $p==$pid pid of job");

waitall;
