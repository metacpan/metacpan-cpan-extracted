#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 6;

# See https://rt.cpan.org/Public/Bug/Display.html?id=39186

BEGIN {
	use_ok('Log::Dispatch');
	use_ok('Log::Dispatch::Null');
	use_ok('Log::WarnDie');
}

RT39186: {
	my $dispatcher = new_ok('Log::Dispatch');

	my $channel = Log::Dispatch::Null->new( qw(name default min_level debug));
	isa_ok($channel, 'Log::Dispatch::Null');

	$dispatcher->add( $channel );
	is($dispatcher->output('default'), $channel, 'Check if channel activated');

	Log::WarnDie->dispatcher($dispatcher);

	print STDERR 'test output/1';
	printf (STDERR 'test output/2');
}
