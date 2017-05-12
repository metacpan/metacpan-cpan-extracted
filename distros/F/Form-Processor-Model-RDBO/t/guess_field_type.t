use strict;
use Test::More tests => 5;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Album;
use Form::AlbumAuto;

my $db = NewDB->new();

$db->init();

foreach my $artist ( qw/ purgen rage / ) {
    RDBO::Artist->new( name => $artist )->save();
}

my $form = Form::AlbumAuto->new();

ok( $form );

isa_ok( $form->field( 'artist_fk' ), 'Form::Processor::Field::Select' );

isa_ok( $form->field( 'extra' ), 'Form::Processor::Field::Text' );

is_deeply( [ $form->field( 'artist_fk' )->options ],
    [ { value => 1, label => 'purgen' }, { value => 2, label => 'rage' }, ] );

is_deeply( [ $form->field( 'artist_rel' )->options ],
    [ { value => 1, label => 'purgen' }, { value => 2, label => 'rage' }, ] );

my $items = Rose::DB::Object::Manager->get_objects(object_class => 'RDBO::Artist');

$_->delete() foreach @$items;
