use strict;
use Test::More tests => 6;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Album;
use Form::Artist;

my $db = NewDB->new();

$db->init();

my $artist = RDBO::Artist->new( name => 'Rage' );
$artist->albums( { title => 'album1' }, { title => 'album2' } );
$artist->save( cascade => 1 );

my $albums = $artist->albums;
is( scalar @$albums,       2 );
is( $albums->[ 0 ]->title, 'album1' );

my $album = RDBO::Album->new( title => 'album3' );
$album->save();

my $form = Form::Artist->new( $artist );

ok( $form );

ok( $form->validate( { name => 'Rage', albums => 1 } ) );

$artist = $form->update_from_form();
$artist->save( cascade => 1 );

$albums = $artist->albums;
is( scalar @$albums,       1 );
is( $albums->[ 0 ]->title, 'album1' );

$artist->delete( cascade => 1 );

my $albums =
  Rose::DB::Object::Manager->get_objects( object_class => 'RDBO::Album' );

$_->delete foreach @$albums;
