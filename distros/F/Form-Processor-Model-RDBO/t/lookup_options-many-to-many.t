use strict;
use Test::More tests => 2;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Genre;
use Form::Artist;

my $db = NewDB->new();

$db->init();

foreach my $genre ( qw/ metal rock / ) {
    RDBO::Genre->new( name => $genre )->save();
}

my $form = Form::Artist->new();

ok( $form );

is_deeply( [ $form->field( 'genres' )->options ],
    [ { value => 1, label => 'metal' }, { value => 2, label => 'rock' }, ] );

my $genres =
  Rose::DB::Object::Manager->get_objects( object_class => 'RDBO::Genre' );

$_->delete() foreach @$genres;
