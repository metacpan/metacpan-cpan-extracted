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

is_deeply(
    [ $form->field( 'artist_fk' )->options ],
    [
        { value => 1, label => 'purgen' },
        { value => 2, label => 'rage' },
    ]
);

is_deeply(
    [ $form->field( 'artist_rel' )->options ],
    [
        { value => 1, label => 'purgen' },
        { value => 2, label => 'rage' },
    ]
);

my $items = Rose::DB::Object::Manager->get_objects(object_class => 'RDBO::Artist');

$_->delete() foreach @$items;
