use strict;
use Test::More tests => 5;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Genre;
use Form::Artist;

my $db = NewDB->new();

$db->init();

foreach my $genre ( qw/ metal punk / ) {
    RDBO::Genre->new( name => $genre )->save();
}

my $form = Form::Artist->new();

ok( $form );

ok( $form->validate( { name => 'Rage', genres => [ 1, 2 ] } ) );

my $artist = $form->update_from_form();
$artist->save( cascade => 1 );

my $genres = $artist->genres;

is( scalar @$genres, 2 );

is( $genres->[ 0 ]->name, 'metal' );
is( $genres->[ 1 ]->name, 'punk' );

$artist->delete(cascade => 1);

my $genres =
  Rose::DB::Object::Manager->get_objects( object_class => 'RDBO::Genre' );

$_->delete() foreach @$genres;
