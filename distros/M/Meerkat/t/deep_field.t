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

test 'deep_field lookup' => sub {
    my $self = shift;
    my $obj  = $self->create_person;

    # invalid attribute
    like(
        exception { $obj->_deep_field("ldkfjadlkf.lkadlk.dlka") },
        qr/Invalid attribute 'ldkfjadlkf'/,
        "croaks on non-attribute"
    );

    # undef attribute
    is( $obj->_deep_field('payload'),      undef, "empty attribute" );
    is( $obj->_deep_field('payload.deep'), undef, "empty attribute with deep field" );

    # scalar attribute
    $obj->update( { '$set' => { payload => 'foo' } } );
    is( $obj->_deep_field('payload'), 'foo', "scalar attribute" );
    like(
        exception { $obj->_deep_field("payload.bar") },
        qr/not a reference/,
        "croaks on deep field on scalar"
    );

    # array attribute
    $obj->update( { '$set' => { payload => [] } } );
    is( ref $obj->_deep_field('payload'), 'ARRAY', "array attribute" );
    is( $obj->_deep_field('payload.0'),   undef,   "array attribute, index 0" );
    ok( $obj->update_push( payload => 'foo' ), "pushed a value" );
    is( $obj->_deep_field('payload.0'), 'foo', "array attribute, index 0" );
    is( $obj->_deep_field('payload.3'), undef, "array attribute, index 3" );
    is( scalar @{ $obj->payload },      1,     "only one item still" );
    like(
        exception { $obj->_deep_field("payload.bar") },
        qr/not positive integer/,
        "croaks on deep field on scalar"
    );
    like(
        exception { $obj->_deep_field("payload.0.bar") },
        qr/not a reference/,
        "croaks on deep field on scalar in arrayref"
    );

    # hash attribute
    $obj->update( { '$set' => { payload => {} } } );
    is( ref $obj->_deep_field('payload'), 'HASH', "hash attribute" );
    is( $obj->_deep_field('payload.bar'), undef,  "hash attribute, key" );
    ok( !exists $obj->payload->{bar}, "hash value still doesn't exist" );
    ok( $obj->update_set( 'payload.foo' => 'foo' ), "set a value to a key" );
    like(
        exception { $obj->_deep_field("payload.foo.bar") },
        qr/not a reference/,
        "croaks on deep field on scalar in hashref"
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
