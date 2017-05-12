use strict;

use lib  qw(./t/lib ./lib);

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


require "test_data.pl";

my $controller = Mac::iTunes->controller;
isa_ok( $controller, 'Mac::iTunes::AppleScript' );

my $lists = $controller->get_track_names_in_playlist( 
	$iTunesTest::Test_playlist );
isa_ok( $lists, 'ARRAY' );
