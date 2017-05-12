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

sub _build_meerkat_options {
    my ($self) = @_;
    return {
        model_namespace      => 'My::Model',
        collection_namespace => 'My::Collection',
        database_name        => 'test',
    };
}

test 'custom collection' => sub {
    my $self   = shift;
    my $person = $self->person;
    isa_ok( $person, "My::Collection::Person" );
    ok( my $obj1 = $self->create_person, "created person" );
    ok( my $obj2 = $person->find_name( $obj1->name ), "searched by custom query" );
    is_deeply( $obj1, $obj2, "objects are the same" );
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
