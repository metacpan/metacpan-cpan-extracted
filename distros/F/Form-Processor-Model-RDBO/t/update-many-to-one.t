use strict;
use Test::More tests => 3;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Album;
use Form::Album;

my $db = NewDB->new();

$db->init();

foreach my $artist ( qw/ Rage Purgen / ) {
    RDBO::Artist->new( name => $artist )->save();
}

my $album = RDBO::Album->new( title => 'album1' );
$album->artist_fk( 1 );
$album->save();

my $form = Form::Album->new( $album );

ok( $form );

ok( $form->validate( { title => 'album2', artist_fk => 2 } ) );

my $album = $form->update_from_form();
$album->save();

is( $album->artist_id, 2 );

$album->delete();

my $items = Rose::DB::Object::Manager->get_objects(object_class => 'RDBO::Artist');

$_->delete() foreach @$items;
