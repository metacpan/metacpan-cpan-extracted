use strict;
use warnings;
use Test::Roo;
use Test::FailWarnings;
use Test::Fatal;
use Test::Requires qw/MongoDB/;

my $conn = eval { MongoDB::MongoClient->new; };
plan skip_all => "No MongoDB on localhost"
  unless eval { $conn->get_database("admin")->run_command( [ ismaster => 1 ] ) };

use lib 't/lib';

with 'TestFixtures';

test 'collection' => sub {
    my $self = shift;
    ok( my $coll1 = $self->meerkat->collection("Person"), "get a collection" );
    ok( my $coll2 = $self->person, "get another one" );
    isnt( $coll1, $coll2, "collections are different objects" );
    is( $coll1->_mongo_collection, $coll2->_mongo_collection,
        "collections share a mongodb collection object" );

};

test 'create arguments' => sub {
    my $self = shift;
    ok( !eval { $self->person->create }, "no attributes fails required" );
    ok( $self->person->create( name => $self->faker->name, birthday => time ), "list" );
    ok( $self->person->create( { name => $self->faker->name, birthday => time } ),
        "hashref" );
};

test 'round trip' => sub {
    my $self = shift;

    ok( my $obj1 = $self->create_person, "created object" );
    ok( $self->create_person, "created second object" );

    my $obj2 = $self->person->find_id( $obj1->_id );
    is_deeply( $obj2, $obj1, "retrieve first object from database by OID" );

    my $obj3 = $self->person->find_id( $obj1->_id->value );
    is_deeply( $obj3, $obj1, "retrieve first object from database by string" );

    ok( my $cursor = $self->person->find( { name => $obj1->name } ), "find query ran" );
    isa_ok( $cursor, 'Meerkat::Cursor' );
    my $obj4 = $cursor->next;
    is_deeply( $obj4, $obj1, "retrieve first object from database by cursor" );

};

test 'not found' => sub {
    my $self = shift;
    ok( my $obj1 = $self->create_person, "created object" );

    my $fake_id = MongoDB::OID->new;
    is( $self->person->find_id($fake_id),
        undef, "find_id on non-existent doc returns undef" );
    is( $self->person->find_one( { _id => $fake_id } ),
        undef, "find_one on non-existent doc returns undef" );
};

test 'remove' => sub {
    my $self = shift;
    ok( my $obj1 = $self->create_person, "created object" );
    ok( my $obj2 = $self->person->find_one( { name => $obj1->name } ),
        "found it in DB" );
    is( $obj1->_id, $obj2->_id, "objects are same" );
    ok( $obj1->remove,     "removed first object" );
    ok( $obj1->is_removed, "object marked as removed" );
    ok( !$obj2->sync,      "sync of second objects finds it removed" );
    ok( !$obj2->sync,      "repeated sync is NOP" );
    ok( $obj2->is_removed, "second object now marked as removed" );
    ok( $obj2->remove,     "remove on second object is NOP" );
};

test 'count' => sub {
    my $self = shift;

    my @obs =
      map { my $n = $_; ok( my $p = $self->create_person, "created object $n" ); $p }
      1 .. 10;

    is( $self->person->count, 10, "collection count" );
    is( $self->person->count( { name => $obs[0]->name } ), 1, "count with query" );
};

test 'update' => sub {
    my $self = shift;
    my $obj  = $self->create_person;
    ok( my $obj2 = $self->person->find_id( $obj->_id ), "getting copy of object" );
    is( $obj->likes, 0, "likes 0" );
    like(
        exception { $obj->update( { name => "Joe Bob" } ) },
        qr/only accepts MongoDB update operators/,
        "exception thrown updating without update operators"
    );
    my $count = 3;
    for my $i ( 1 .. $count ) {
        $obj->update( { '$inc' => { 'likes' => 1 } } );
        is( $obj->likes, $i, "likes $i" );
    }
    is( $obj2->likes, 0, "copy has old likes count" );
    ok( $obj2->sync, "sync'd copy" );
    is( $obj2->likes, $count, "copy has correct likes count" );
    ok( $obj->remove, "removing object" );
    ok( !$obj->update( { '$inc' => { 'likes' => 1 } } ),
        "update after remove return false" );
    ok(
        !$obj2->update( { '$inc' => { 'likes' => 1 } } ),
        "update on copy after remove return false"
    );
    ok( $obj2->is_removed, "copy marked removed" );
};

test 'reinsert' => sub {
    my $self = shift;
    ok( my $obj1 = $self->create_person, "created object" );
    ok( my $obj2 = $self->person->find_one( { name => $obj1->name } ),
        "found it in DB" );
    ok( !$obj1->reinsert, "reinsert first object should fail" );
    ok( $obj2->update_set( name => 'Larry Wall' ), "changed name via second object" );
    ok( $obj1->reinsert( force => 1 ), "forced reinsertion of first object" );
    ok( $obj2->sync, "sync second object" );
    is( $obj2->name, $obj1->name, "insertion overrode name change" );
    ok( $obj1->remove,      "removed first object" );
    ok( $obj1->is_removed,  "object marked as removed" );
    ok( !$obj2->sync,       "sync of second object finds it removed" );
    ok( $obj1->reinsert,    "reinserted first object" );
    ok( !$obj1->is_removed, "first object not marked as removed" );
    ok( $obj2->sync,        "sync of second object succeeds" );
    ok( !$obj2->is_removed, "second object not marked as removed" );
    is( $obj2->name, $obj1->name, "objects have same name" );
};

test 'create indexes' => sub {
    my $self = shift;
    $self->create_person;
    ok( $self->person->ensure_indexes, "created indexes" );
    my @got      = $self->person->_mongo_collection->indexes->list->all;
    my @expected = $self->person->class->_indexes;
    is( scalar @got, 1 + @expected, "correct number of indexes" )
      or diag explain \@expected;
};

run_me;
done_testing;
#
# This file is part of Meerkat
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
