use Test::More tests => 4;

use_ok( "Mac::iTunes" );
use_ok( "Mac::iTunes::Library::Parse" );

$ENV{ITUNES_DEBUG} = 1;

my $File = "mp3/iTunes_4_6_Music_Library";
my $fh;

ok( open( $fh, $File ), 'Open music library' );

my $itunes;

eval{ Mac::iTunes::Library::Parse->parse( $fh ) };
ok( $@, "Parser dies for version 4.6" );
