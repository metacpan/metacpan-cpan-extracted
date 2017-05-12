use strict;
use warnings;

=head1 NAME

multikey.t - create and load some records with multi-attribute keys

=cut

use Test::More tests => 37;
use_ok('DustyDB');

# Declare a multi-attribute key model
package Point;
use DustyDB::Object;

has key x => (
    is => 'rw',
    isa => 'Int',
);

has key y => (
    is => 'rw',
    isa => 'Int',
);

has name => (
    is => 'rw',
    isa => 'Str',
);

has foo => (
    is => 'rw',
    isa => 'Point',
);

package main;

my $db = DustyDB->new( path => 't/multikey.db' );
ok($db, 'Loaded the database object');
isa_ok($db, 'DustyDB');

my $point = $db->model('Point');
ok($point, 'got a model');

{
    my $origin = $point->create( x => 0, y => 0 );
    ok($origin, 'have an origin');
    is($origin->x, 0, 'origin.x == 0');
    is($origin->y, 0, 'origin.y == 0');

    my $origin_x = $point->create( x => 0, y => 1 );
    ok($origin_x, 'have origin_x');
    is($origin_x->x, 0, 'origin.x == 0');
    is($origin_x->y, 1, 'origin.y == 1');

    my $origin_y = $point->create( x => 1, y => 0 );
    ok($origin_y, 'have an origin');
    is($origin_y->x, 1, 'origin.x == 1');
    is($origin_y->y, 0, 'origin.y == 0');

    my $second = $point->create( x => 42, y => 69 );
    ok($second, 'has a second point');
    is($second->x, 42, 'second.x == 42');
    is($second->y, 69, 'second.y == 69');
}

{
    my $origin = $point->load( x => 0, y => 0 );
    ok($origin, 'have an origin');
    is($origin->x, 0, 'origin.x == 0');
    is($origin->y, 0, 'origin.y == 0');

    my $origin_x = $point->load( x => 0, y => 1 );
    ok($origin_x, 'have origin_x');
    is($origin_x->x, 0, 'origin.x == 0');
    is($origin_x->y, 1, 'origin.y == 1');

    my $origin_y = $point->load( x => 1, y => 0 );
    ok($origin_y, 'have an origin');
    is($origin_y->x, 1, 'origin.x == 1');
    is($origin_y->y, 0, 'origin.y == 0');

    my $second = $point->load( x => 42, y => 69 );
    ok($second, 'has a second point');
    is($second->x, 42, 'second.x == 42');
    is($second->y, 69, 'second.y == 69');
}

{
    my @point = $point->all;
    is(scalar @point, 4, 'we have 4 points');
    is($point[0]->x, 0, 'point 0 x 0');
    is($point[0]->y, 0, 'point 0 y 0');
    is($point[1]->x, 1, 'point 1 x 1');
    is($point[1]->y, 0, 'point 1 y 0');
    is($point[2]->x, 0, 'point 2 x 0');
    is($point[2]->y, 1, 'point 2 y 1');
    is($point[3]->x, 42, 'point 3 x 42');
    is($point[3]->y, 69, 'point 3 y 69');
}

unlink 't/multikey.db';
