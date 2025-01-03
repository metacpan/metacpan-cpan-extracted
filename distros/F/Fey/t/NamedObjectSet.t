use strict;
use warnings;

use Test::More 0.88;

use Fey::NamedObjectSet;

{
    my $set = Fey::NamedObjectSet->new();

    my $bob  = Name->new( name => 'bob' );
    my $faye = Name->new( name => 'faye' );

    $set->add($bob);
    my @objects = $set->objects();
    is( scalar @objects,     1,     'set has one object' );
    is( $objects[0]->name(), 'bob', 'that one object is bob' );

    $set->add($faye);
    @objects = sort { $a->name() cmp $b->name() } $set->objects();
    is( scalar @objects, 2, 'set has two objects' );
    is_deeply(
        [ map { $_->name() } @objects ],
        [ 'bob', 'faye' ],
        'those objects are bob and faye'
    );

    $set->delete($bob);
    @objects = $set->objects();
    is( scalar @objects,     1,      'set has one object' );
    is( $objects[0]->name(), 'faye', 'that one object is faye' );

    $set->add($bob);
    @objects = $set->objects('bob');
    is( scalar @objects,     1, 'objects() returns one object named bob' );
    is( $objects[0]->name(), 'bob', 'that one object is bob' );

    is(
        $set->object('bob')->name(), 'bob',
        'object() returns one object by name and it is bob'
    );

    ok(
        $set->is_same_as($set),
        'set is_same_as() itself'
    );

    my $other_set = Fey::NamedObjectSet->new();
    ok(
        !$set->is_same_as($other_set),
        'set not is_same_as() empty set'
    );

    $other_set->add($bob);
    ok(
        !$set->is_same_as($other_set),
        'set not is_same_as() other set with just one object'
    );

    $other_set->add($faye);
    ok(
        $set->is_same_as($other_set),
        'set not is_same_as() other set which has the same objects'
    );
}

{
    my $bob  = Name->new( name => 'bob' );
    my $faye = Name->new( name => 'faye' );

    my $set1 = Fey::NamedObjectSet->new( $bob, $faye );

    my $set2 = Fey::NamedObjectSet->new();
    $set2->add($_) for $bob, $faye;

    ok(
        $set1->is_same_as($set2),
        'set with items added at construction is same as set with items added via add()'
    );
}

done_testing();

package NoName;

sub new { return bless {}, shift }

package Name;

use Moose 2.1200;

BEGIN {
    has 'name' => (
        is  => 'ro',
        isa => 'Str',
    );

    with 'Fey::Role::Named';
}
