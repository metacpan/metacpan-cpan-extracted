use strict;
use Test::More tests => 3;

use lib 't/lib';

use NewDB;
use RDBO::Artist;
use RDBO::Album;
use Form::Album;

my $db = NewDB->new();

$db->init();

foreach my $artist ( qw/ purgen rage / ) {
    RDBO::Artist->new( name => $artist )->save();
}

my $form = Form::Album->new();

ok( $form );

ok( $form->validate( { title => 'Album1', artist_fk => 1 } ) );

my $item = $form->update_from_form();
$item->save();

is( $item->artist_id, 1 );

$item->delete();

my $items = Rose::DB::Object::Manager->get_objects(object_class => 'RDBO::Artist');

$_->delete() foreach @$items;
