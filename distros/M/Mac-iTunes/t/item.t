BEGIN { $^W = 0; }

use Test::More tests => 7;

use Mac::iTunes::Item;

use lib  qw(./t/lib ./lib);

require "test_data.pl";

my $item;

# can we create an item?
isa_ok( $item = Mac::iTunes::Item->new_from_mp3( $iTunesTest::Test_mp3 ), 
	'Mac::iTunes::Item' );
is( $iTunesTest::Title,      $item->title,   'Item title' );
is( $iTunesTest::Genre,      $item->genre,   'Item genre' );
is( $iTunesTest::Artist,     $item->artist,  'Item artist' );
is( $iTunesTest::Time,       $item->seconds, 'Item seconds' );
is( $iTunesTest::Test_mp3,   $item->file,    'Item file' );

# can we not create an item?
is( Mac::iTunes::Item->new_from_mp3( 'foo.mp' ), undef,
	'Do not make item from missing file' );

