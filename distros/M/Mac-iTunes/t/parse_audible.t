use Test::More tests => 4;

use Mac::iTunes;
use Mac::iTunes::Library::Parse;

 $ENV{ITUNES_DEBUG} = 1;

my $File = "mp3/Audible_file";
my $fh;

ok( open( $fh, $File ), 'Open music library' );

my $itunes;
isa_ok( Mac::iTunes::Library::Parse->parse( $fh ), 'Mac::iTunes' );
isa_ok( $itunes = Mac::iTunes->read( $File ), 'Mac::iTunes' );

is( scalar $itunes->playlists, 7, 'Correct number of playlists' );
