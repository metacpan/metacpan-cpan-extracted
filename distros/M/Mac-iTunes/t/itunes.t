use Test::More tests => 18;

BEGIN { use_ok( 'Mac::iTunes::Playlist' ); }
BEGIN { use_ok( 'Mac::iTunes' ); }

my $Title = 'Schoolhouse Rock';

my $playlist = Mac::iTunes::Playlist->new( $Title );
isa_ok( $playlist, 'Mac::iTunes::Playlist' );

my $iTunes = Mac::iTunes->new();
isa_ok( $iTunes, 'Mac::iTunes' );

ok( $iTunes->add_playlist( $playlist ),    'Add to playlist' );
ok( $iTunes->playlist_exists( $playlist ), 'Playlist exist'  );
is( $iTunes->playlists, 1,                 'Playlist count'  );

my $fetched;
ok( $fetched = $iTunes->get_playlist( $Title ),  'Fetch playlist'  );
is( $fetched, $playlist,                         'Playlist test'   );

is( $iTunes->get_playlist( "Doesn't Exist" ), undef, 'Non-existent playlist' );

ok( $iTunes->playlist_exists( $playlist ),      'Playlist exist before delete' );
ok( $iTunes->delete_playlist( $playlist ),      'Delete playlist' );
ok( $iTunes->playlist_exists( $playlist ) == 0, 'Playlist exists after delete' );
is( $iTunes->playlists, 0,                      'Playlist count after delete'  );

is( $iTunes->add_playlist( ),         undef,  'Check null playlist'   );
is( $iTunes->add_playlist( undef ),   undef,  'Check undef playlist'  );
is( $iTunes->add_playlist( 'Title' ), undef,  'Check string playlist' );
is( $iTunes->add_playlist( $iTunes ), undef,  'Check object type'     );
