use strict;

use Test::More;
use Mac::iTunes;

eval { use Mac::iTunes::AppleScript };

if( $@ )
	{
	plan skip_all => "Skipping tests: Need Mac::iTunes::Applescript"
	}
else
	{
	plan tests => 6;
	}

my $controller = Mac::iTunes->controller;
isa_ok( $controller, 'Mac::iTunes::AppleScript' );

$controller->stop;
is( $controller->player_state, Mac::iTunes::AppleScript::STOPPED, 
	'Player is stopped' );
is( $controller->position, 0, 'Player is at start of track' );

$controller->play;
is( $controller->player_state, Mac::iTunes::AppleScript::PLAYING, 
	'Player is playing' );
defined_ok( $controller->position );
sleep 3;
cmp_ok( $controller->position, '>', 2, "The tune is playing" );
