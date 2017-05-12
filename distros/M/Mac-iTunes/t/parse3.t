use Test::More tests => 7;

use Mac::iTunes;
use Mac::iTunes::Library::Parse;

require Data::Dumper if $ENV{ITUNES_DEBUG};

my $File = "mp3/iTunes_3_Music_Library";
my $fh;

ok( open( $fh, $File ), 'Open music library' );
isa_ok( Mac::iTunes::Library::Parse->parse( $fh ), 'Mac::iTunes' );

my $itunes = Mac::iTunes->read( $File );
isa_ok( $itunes, 'Mac::iTunes' );

ok( $itunes->playlist_exists( 'Library' ), 'Library playlist exists' );

my $playlist = $itunes->get_playlist( 'Library' );
isa_ok( $playlist, 'Mac::iTunes::Playlist' );
is( scalar $playlist->items, 1 );

my( $item ) = $playlist->items;
isa_ok( $item, 'Mac::iTunes::Item' );

print STDERR Data::Dumper::Dumper( $itunes ) if $ENV{ITUNES_DEBUG}
