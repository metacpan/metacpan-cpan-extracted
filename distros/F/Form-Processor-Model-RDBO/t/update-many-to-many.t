use strict;
use Test::More tests => 4;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Genre;
use Form::Artist;

my $db = NewDB->new();

$db->init();

my $artist = RDBO::Artist->new( name => 'Rage' );
$artist->genres( { name => 'metal' }, { name => 'rock' } );
$artist->save( cascade => 1 );

my $form = Form::Artist->new( $artist );

ok( $form );

ok( $form->validate( { name => 'Purgen', genres => 1 } ) );

my $artist = $form->update_from_form();
$artist->save( cascade => 1 );

my $genres = $artist->genres;

is( scalar @$genres, 1 );
is( $genres->[0]->name, 'metal' );

$artist->delete( cascade => 1 );

my $genres =
  Rose::DB::Object::Manager->get_objects( object_class => 'RDBO::Genre' );

$_->delete() foreach @$genres;
