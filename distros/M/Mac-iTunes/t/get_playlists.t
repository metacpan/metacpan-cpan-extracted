use strict;

use Test::More;

use Mac::iTunes;

eval "use Mac::iTunes::AppleScript qw(:boolean :state :size)";

if( $@ )
	{
	plan skip_all => "Skipping tests: Need Mac::iTunes::Applescript"
	}
else
	{
	plan tests => 2;
	}

my $controller = Mac::iTunes->controller;
isa_ok( $controller, 'Mac::iTunes::AppleScript' );

my $lists = $controller->get_playlists;
isa_ok( $lists, 'ARRAY' );
