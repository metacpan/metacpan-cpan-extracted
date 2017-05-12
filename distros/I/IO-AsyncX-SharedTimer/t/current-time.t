use strict;
use warnings;

use Test::More;

use IO::AsyncX::SharedTimer;

use IO::Async::Loop;

sub float_is($$;$) {
	my ($actual, $expected, $msg) = @_;
	my $delta = 0.0000001;
	if(abs($actual - $expected) <= $delta) {
		pass($msg);
	} else {
		is($actual, $expected, $msg);
	}
}

my $loop = IO::Async::Loop->new;
$loop->add(
	my $timer = new_ok('IO::AsyncX::SharedTimer', [
		resolution => '0.001',
	])
);

float_is($timer->resolution, 0.001, 'resolution looks about right');
my $now = $timer->now;
{
	cmp_ok(abs($loop->time - $timer->now), '<=', 1.5 * $timer->resolution, 'current time is within expected resolution');
	# make sure we have at least some sort of delay
	Time::HiRes::sleep(0.001);
	my $again = $timer->now;
	# stringify for numerical reasons
	is("$again", "$now", 'time has not changed if we have not yet cycled the loop');
}

$loop->delay_future(
	after => 1
)->get;
cmp_ok(abs($loop->time - $timer->now), '<=', 1.5 * $timer->resolution, 'current time is still within expected resolution');
{
	my $again = $timer->now;
	isnt("$again", "$now", 'time has changed after loop entry');
}
done_testing;

