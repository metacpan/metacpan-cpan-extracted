
use strict;
use warnings;
use Test::More;
use Test::Warnings;
use English;

use Log::Deep;

my $deep;
eval { $deep = Log::Deep->new; };

SKIP:
{
	if ($EVAL_ERROR) {
		skip("Could not wright log file: $EVAL_ERROR", 26) if $EVAL_ERROR;
	}

	my $level = $deep->level;
	is_deeply( $level, { fatal=>1, error=>1, warn=>1, debug=>0, message=>0, info=>0 }, "Check that the default setup is as expected" );

	$level = $deep->level('debug');
	is_deeply( $level, { fatal=>1, error=>1, warn=>1, debug=>1, message=>0, info=>0 }, "turn on debug and higher" );

	$level = $deep->level(1);
	is_deeply( $level, { fatal=>1, error=>1, warn=>1, debug=>1, message=>1, info=>0 }, "turn on message and higher" );

	$deep->level( -set => 'info' );
	$level = $deep->level;
	is_deeply( $level, { fatal=>1, error=>1, warn=>1, debug=>1, message=>1, info=>1 }, "trun on just info" );

	$deep->level( -unset => 'message' );
	$level = $deep->level;
	is_deeply( $level, { fatal=>1, error=>1, warn=>1, debug=>1, message=>0, info=>1 }, "trun off just message" );

	$deep->enable('info');
	ok( $deep->level->{info}, 'Enabled info' );
	ok( $deep->is_info, 'Enabled info via is' );
	$deep->disable('info');
	ok( !$deep->is_info, 'Disabled info' );

	$deep->enable('message');
	ok( $deep->level->{message}, 'Enabled message' );
	ok( $deep->is_message, 'Enabled message via is' );
	$deep->disable('message');
	ok( !$deep->is_message, 'Disabled message' );

	$deep->enable('debug');
	ok( $deep->level->{debug}, 'Enabled debug' );
	ok( $deep->is_debug, 'Enabled debug via is' );
	$deep->disable('debug');
	ok( !$deep->is_debug, 'Disabled debug' );

	$deep->enable('warn');
	ok( $deep->level->{warn}, 'Enabled warn' );
	ok( $deep->is_warn, 'Enabled warn via is' );
	$deep->disable('warn');
	ok( !$deep->is_warn, 'Disabled warn' );

	$deep->enable('error');
	ok( $deep->level->{error}, 'Enabled error' );
	ok( $deep->is_error, 'Enabled error via is' );
	$deep->disable('error');
	ok( !$deep->is_error, 'Disabled error' );

	$deep->enable('fatal');
	ok( $deep->level->{fatal}, 'Enabled fatal' );
	ok( $deep->is_fatal, 'Enabled fatal via is' );
	$deep->disable('fatal');
	ok( !$deep->is_fatal, 'Disabled fatal' );

	ok( $deep->is_security, 'Enabled security via is' );

	# setting levels with new
	$deep = Log::Deep->new( -level => [qw/fatal error/] );

	$level = $deep->level;
	is_deeply( $level, { fatal=>1, error=>1, warn=>0, debug=>0, message=>0, info=>0 }, "Check that the default setup is as expected" );

	$deep = Log::Deep->new( -level => 2 );

	$level = $deep->level;
	is_deeply( $level, { fatal=>1, error=>1, warn=>1, debug=>1, message=>0, info=>0 }, "Check that the default setup is as expected" );
}
done_testing();
