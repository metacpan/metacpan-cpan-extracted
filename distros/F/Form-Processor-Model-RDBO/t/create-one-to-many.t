use strict;
use Test::More tests => 5;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Album;
use Form::Artist;

my $db = NewDB->new();

$db->init();

foreach my $album ( qw/ album1 album2 / ) {
    RDBO::Album->new( title => $album )->save();
}

my $form = Form::Artist->new();

ok( $form );

ok( $form->validate( { name => 'Rage', albums => [ 1, 2 ] } ) );

my $artist = $form->update_from_form();
$artist->save( cascade => 1 );

my $albums = $artist->albums;
is( scalar @$albums, 2 );
is( $albums->[0]->title, 'album1' );
is( $albums->[1]->title, 'album2' );

$artist->delete( cascade => 1 );
