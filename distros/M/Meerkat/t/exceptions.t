use strict;
use warnings;
use Test::Roo;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;
use Test::Requires qw/MongoDB/;

my $conn = eval { MongoDB::MongoClient->new; };
plan skip_all => "No MongoDB on localhost"
  unless eval { $conn->get_database("admin")->run_command( [ ismaster => 1 ] ) };

use lib 't/lib';

with 'TestFixtures';

test 'bad sync' => sub {
    my $self = shift;
    my $obj  = $self->create_person;
    my $copy = $self->person->find_id( $obj->_id );

    # intentionally create a bad document
    $self->person->_mongo_collection->replace_one( { _id => $obj->_id },
        { name => [] } );

    like(
        exception { $obj->sync },
        qr/Could not inflate updated document/,
        "syncing a bad document threw an exception"
    );
    cmp_deeply( $obj, $copy, "object is unchanged" );
};

test 'update_set must be on scalar or undef or same type' => sub {
    my $self = shift;
    my $obj  = $self->create_person;

    # payload starts undef
    $self->pass_update( update_set => $obj, payload => 'foo' );
    # then payload has a scalar value
    $self->pass_update( update_set => $obj, payload => 'bar' );
    # tags is already array ref
    $self->pass_update( update_set => $obj, tags => ['bar'] );
    # parents is already hashref
    $self->pass_update( update_set => $obj, parents => { dad => 'Vader' } );

    $self->fail_type_update( update_set => $obj, tags    => 'foo' );
    $self->fail_type_update( update_set => $obj, parents => 'foo' );
};

test 'update_inc must be on scalar number or undef' => sub {
    my $self = shift;
    my $obj  = $self->create_person;

    # payload starts undef
    $self->pass_update( update_inc => $obj, payload => 1 );
    # then payload has a scalar numeric value
    $self->pass_update( update_inc => $obj, payload => -1 );

    like( exception { $obj->update_inc( name => 1 ) },
        qr/non-numeric/, "update_inc on non-numeric field croaks" );

    $self->fail_update( update_inc => $obj, tags    => 1 );
    $self->fail_update( update_inc => $obj, parents => 1 );
};

test 'update_push/add must be on undef or ARRAY' => sub {
    my $self = shift;

    for my $op (qw/update_push update_add/) {
        my $obj = $self->create_person;
        # payload starts undef
        $self->pass_update( $op => $obj, payload => 'foo' );
        # then payload has a ARRAY
        $self->pass_update( $op => $obj, payload => 'bar' );

        # name is scalar
        $self->fail_update( $op => $obj, name => 'foo' );
        # parents is hash
        $self->fail_update( $op => $obj, parents => 'foo' );
    }
};

test 'update_pop/shift must be on undef or ARRAY' => sub {
    my $self = shift;

    for my $op (qw/update_pop update_shift /) {
        my $obj = $self->create_person;
        # payload starts undef
        $self->pass_update( $op => $obj, 'payload' );
        # then push on a value
        $obj->update_push( payload => 'foo' );
        # then payload has a ARRAY
        $self->pass_update( $op => $obj, 'payload' );

        # name is scalar
        $self->fail_update( $op => $obj, 'name' );
        # parents is hash
        $self->fail_update( $op => $obj, 'parents' );
    }
};

test 'update_remove must be on undef or ARRAY' => sub {
    my $self = shift;

    for my $op (qw/update_remove/) {
        my $obj = $self->create_person;
        # payload starts undef
        $self->pass_update( $op => $obj, payload => 'foo' );
        # then push on a value
        $obj->update_push( payload => 'foo' );
        # then payload has a ARRAY
        $self->pass_update( $op => $obj, payload => 'bar' );

        # name is scalar
        $self->fail_update( $op => $obj, name => 'foo' );
        # parents is hash
        $self->fail_update( $op => $obj, parents => 'foo' );
    }
};

test 'update_clear works on undef, scalar, ARRAY or HASH' => sub {
    my $self = shift;

    for my $op (qw/update_clear/) {
        my $obj = $self->create_person;
        # payload starts undef
        $self->pass_update( $op => $obj, 'payload' );
        # then set a value
        $obj->update_set( payload => 'foo' );
        # then payload has a scalar
        $self->pass_update( $op => $obj, 'payload' );
        # tags is array
        $self->pass_update( $op => $obj, 'tags' );
        # parents is hash
        $self->pass_update( $op => $obj, 'parents' );
    }
};

test 'exception on bad index args' => sub {
    my $self = shift;

    my $meerkat = Meerkat->new(
        model_namespace => "Bad::Model",
        database_name   => "test$$",
    );
    my $person = $meerkat->collection("Person");

    like(
        exception { $person->ensure_indexes },
        qr{_indexes must provide a list of key/value pairs},
        "bad _index format threw error"
    );
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
