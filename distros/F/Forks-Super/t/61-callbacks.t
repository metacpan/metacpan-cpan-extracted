use Test::More tests => 15;
use Forks::Super ':test';
use strict;
use warnings;

#
# single callbacks
#

my $var = 1;
sub var5 { $var = 5 }
my $var6 = sub { $var = 6 };

my $pid = fork { sub => sub { sleep 3 },
		   callback => sub { $var = 4 } };
my $j = Forks::Super::Job::get($pid);
ok($var == 1, "finish callback waits until finish");
sleep 1;
ok($var == 1, "finish callback waits until finish");
for (my $i=0; $i<10 && $j->{state} eq 'ACTIVE'; $i++) {
    Forks::Super::pause(1);
}
ok($var == 4, "finish runs after finish, before reap");
waitpid $pid, 0;
ok($var == 4, "finish callback runs after finish");

$var = 2;
$pid = fork { sub => sub { sleep 2 }, callback => 'var5' };
sleep 1;
ok($var == 2, "finish callback waits");
waitpid $pid, 0;
ok($var == 5, "finish callback from unqualified sub name");

$var = 3;
$pid = fork { sub => sub { sleep 3 }, callback => $var6 };
sleep 1;
ok($var == 3, "finish callback waits")
    or diag("\$var was $var, expected 3");
waitpid $pid, 0;
ok($var == 6, "finish callback from assigned code ref");

#
# multiple callbacks
#

my $w = 14;
$pid = fork { sub => sub { sleep 2 },
		callback => { start => sub { $w = 11 },
			      finish => sub { $w = 9 } } };
ok($w == 11, "start callback invoked");
$j = Forks::Super::Job::get($pid);
for (my $i = 0; $i < 7 && $j->{state} eq 'ACTIVE'; $i++) {
    Forks::Super::pause(1);
}
ok($w == 9, "finish callback invoked"); ### 10 ###
waitpid $pid,0;

$w = 26;
my $pid1 = fork { sub => sub { sleep 4 }, name => 'foo' };
my $pid2 = fork { sub => sub { sleep 4 }, depend_on => 'foo' ,
		    on_busy => "queue",
		    callback => { queue => sub { $w = 27 },
				  start => sub { $w = 28 },
				  finish => sub { $w = 29 } } };
ok($w == 27, "queue callback runs") or diag "\$w=$w";
wait;
ok($w == 28, "start callback runs") or diag "\$w=$w";
wait;
ok($w == 29, "finish callback runs") or diag "\$w=$w";


$w = 33;
$pid1 = fork { sub => sub { sleep 2 }, name => 'quux' };
$pid2 = fork { sub => sub { sleep 2 }, depend_on => 'quux',
		 on_busy => "fail",
		   callback => { queue => sub { $w = 37 },
				 fail => sub { $w = 38 },
				 start => sub { $w = 39 },
				 finish => sub { $w = 40 },
				 bogus => sub { $w =41 } } };
ok($w == 38, "fail callback runs");

# $Forks::Super::Util::DEFAULT_PAUSE = 
waitall;
ok($w == 38, "no other callbacks after fail");

