#!perl -T
use Test::More tests => 43;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($FATAL);

use Launcher::Cascade::Simple;

my $value = 0;
my $A = new Launcher::Cascade::Simple
    -name => 'Launcher A',
    -max_retries => 2, 
    -test_hook => sub { return ++$value == 7  ? SUCCESS
	                     : $value   == 10 ? FAILURE
			     :                  UNDEFINED; },
    -launch_hook => sub { $value++ },
;

# Run only once, test thrice, finally fails (exhausted retries)
for ( 1 .. 2 ) {
    $A->run();
    is($value, $_, "\$value == $value");
    ok(!$A->has_run(), 'still no status');

    $A->check_status();
    is($value, $_+1, "\$value == $value");
    is($A->retries(), $_, "Attempt $_");
    ok(!$A->has_run(), 'still no status');
}
$A->run();
is($value, 3, "\$value == $value");
ok(!$A->has_run(), 'still no status');

$A->check_status();
is($value, 4, "\$value == $value");
ok($A->is_failure(), 'failed');


# Run only once, test twice, second test succeeds
$A->reset();
$A->run();
is($value, 5, "\$value == $value");
ok(!$A->has_run(), 'still no status');

$A->check_status();
is($value, 6, "\$value == $value");
is($A->retries(), 1, "Attempt 1");
ok(!$A->has_run(), 'still no status');
$A->run();
is($value, 6, "\$value == $value");
ok(!$A->has_run(), 'still no status');

$A->check_status();
is($value, 7, "\$value == $value");
ok($A->is_success(), 'success');

# Run only once, test twice, second test fails.
$A->reset();
$A->run();
is($value, 8, "\$value == $value");
ok(!$A->has_run(), 'still no status');

$A->check_status();
is($value, 9, "\$value == $value");
is($A->retries(), 1, "Attempt 1");
ok(!$A->has_run(), 'still no status');
$A->run();
is($value, 9, "\$value == $value");
ok(!$A->has_run(), 'still no status');

$A->check_status();
is($value, 10, "\$value == $value");
ok($A->is_failure(), 'failure');

# Run only once, test once, fails immediately (no retries)
$A->reset();
$A->max_retries(0);
$A->run();
is($value, 11, "\$value == $value");
ok(!$A->has_run(), 'still no status');

$A->check_status();
is($value, 12, "\$value == $value");
ok($A->is_failure(), 'failure');

# Time between retries
$A->time_between_retries(4);
$A->max_retries(2);
$A->reset();
$value = 0;
my $time = time;
while ( !$A->has_run() && $A->retries() == 0 ) {
    $A->run();
    $A->check_status();
}
ok(time - $time < 1, 'not waiting for the first attempt');
ok(!$A->has_run(), 'still retries left');
$time = time;
while ( !$A->has_run() && $A->retries() == 1 ) {
    $A->run();
    $A->check_status();
}
ok(time - $time > 3, 'waiting long enough');
ok(!$A->has_run(), 'still retries left');

$time = time;
while ( !$A->has_run() && $A->retries() == 2 ) {
    $A->run();
    $A->check_status();
}
ok(time - $time > 3, 'waiting long enough');
ok(time - $time < 5, 'not waiting too long either');
ok($A->has_run(), 'test is over after two retries');
