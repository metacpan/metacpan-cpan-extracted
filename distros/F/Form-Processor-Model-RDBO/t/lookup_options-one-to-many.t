use strict;
use Test::More tests => 2;

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

is_deeply( [ $form->field( 'albums' )->options ],
    [ { value => 1, label => 'album1' }, { value => 2, label => 'album2' }, ] );

my $items =
  Rose::DB::Object::Manager->get_objects( object_class => 'RDBO::Album' );

$_->delete() foreach @$items;
