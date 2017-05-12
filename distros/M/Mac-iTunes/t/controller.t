use Test::More;

use Mac::iTunes;
eval "use Mac::iTunes::AppleScript qw(:boolean :state :size)";

if( $@ )
	{
	plan skip_all => "Skipping tests for Mac::iTunes::Applescript"
	}
else
	{
	plan tests => 44;
	}

my $controller = Mac::iTunes->controller;
isa_ok( $controller, 'Mac::iTunes::AppleScript' );

my %old_values;

my @properties = qw(volume mute sound_volume player_state 
		player_position EQ_enabled fixed_indexing current_visual
		visuals_enabled visual_size full_screen
		current_encoder frontmost);

my $Debug = $ENV{ITUNES_DEBUG} || 0;

foreach my $property ( @properties )
	{
	my $value = $controller->$property;
	$hash{$property} = $value;
	diag( "$property is $value" ) if $Debug;
	}

ok( $controller->activate,         'Activate iTunes'    );

SKIP: {
skip "iTunes doesn't handle frontmost correctly (yet)", 4, "set frontmost to 0";
ok( $controller->frontmost(TRUE),  'Send to background' );
is( $controller->frontmost, TRUE,  'Player is in background' );
ok( $controller->frontmost(0),     'Send to background' );
is( $controller->frontmost, FALSE, 'Player is in background' );
};

my $volume = 65;
is( $controller->volume($volume), $volume,  'Set volume'   );
is( $controller->volume,          $volume,  'Fetch volume' );
is( $controller->volume(150),         100,  'Set volume past maximum' );
is( $controller->volume(-5),            0,  'Fetch volume below minimum' );
is( $controller->volume(50),           50,  'Fetch volume to middle of range' );

ok(  $controller->mute(TRUE),  'Set mute on'   );
ok(  $controller->mute,        'Fetch mute while on' );
ok( !$controller->mute(FALSE), 'Set mute off' );
ok( !$controller->mute,        'Fetch mute while off' );

SKIP: {
skip "iTunes seems to have problems reporting state", 8;
ok( $controller->stop,           'Stop controller'   );
is( $controller->state, STOPPED, 'Player is stopped' );
ok( $controller->play,           'Play controller'   );
is( $controller->state, PLAYING, 'Player is playing' );
ok( $controller->pause,          'Pause controller'  );
is( $controller->state, PAUSED,  'Player is paused' );
ok( $controller->playpause,      'Toggle playpause to play'  );
is( $controller->state, PLAYING, 'Player is playing' );
};

sleep 3;
ok( $controller->playpause,      'Toggle playpause to pause'  );
is( $controller->state, PAUSED,  'Player is paused' );

# the application needs to be visible for these tests
is( $controller->browser_window_visible(TRUE), TRUE, 'Make browser visible' );

ok(  $controller->visuals_enabled(FALSE),   'Set visuals to false' );
ok( !$controller->visuals_enabled,	    'Set visuals to false' );
ok(  $controller->full_screen(FALSE),	    'Set full-screen to false' );
ok( !$controller->full_screen,		    'Full screen is false' );
ok(  $controller->visuals_enabled(TRUE),    'Set visuals to true' );
ok(  $controller->visuals_enabled,	    'Visuals to true' );
ok(  $controller->full_screen(TRUE),	    'Set full-screen to true' );
is(  $controller->full_screen, TRUE,	    'Full screen is true' );
ok(  $controller->full_screen(FALSE),	    'Set full-screen to false' );
ok( !$controller->full_screen,		    'Full screen is false' );

foreach my $size ( SMALL, MEDIUM, LARGE )
	{
	ok( $controller->visual_size($size), "Set visual size to $size" );
	is( $controller->visual_size, $size, "Visual size is $size" );
	}
	
ok(  $controller->visuals_enabled(FALSE), 'Set visuals to false' );
ok( !$controller->visuals_enabled,	  'Set visuals to false' );
