use Test::More;
use Storable qw(thaw dclone);

use strict;
use warnings;

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::Redis';
use ok 'KiokuDB::Collapser';
use ok 'KiokuDB::LiveObjects';
use ok 'KiokuDB::TypeMap::Resolver';

{
    package Foo;
    use Moose;

    has id => (
        isa => "Str",
        is  => "rw",
    );

    has name => (
        isa => "Str",
        is  => "rw",
    );

    has friend => (
        isa => "Foo",
        is  => "rw",
    );
}

SKIP: {
    skip 'Must set KIOKU_REDIS_URL environment variable', 1 unless defined($ENV{KIOKU_REDIS_URL});

    my $kioku = KiokuDB->connect('Redis:server='.$ENV{KIOKU_REDIS_URL});
    my $b = $kioku->backend;

    my $obj = Foo->new(
        id => "shlomo",
        name => "שלמה",
        friend => Foo->new(
            id => "moshe",
            name => "משה",
        ),
    );
    $obj->friend->friend($obj);

    my $c = KiokuDB::Collapser->new(
        backend => $b,
        live_objects => my $l = KiokuDB::LiveObjects->new,
        typemap_resolver => KiokuDB::TypeMap::Resolver->new(
            typemap => KiokuDB::TypeMap->new
        ),
    );

    my $s = $l->new_scope;

    my ( $buffer ) = $c->collapse( objects => [ $obj ]);

    my @entries = values %{ $buffer->entries };

    is( scalar(@entries), 2, "two entries" );

    is_deeply(
        [ map { !$_ } $b->exists(map { $_->id } @entries) ],
        [ 1, 1 ],
        "none exist yet",
    );

    $b->insert(@entries);

    is_deeply(
        [ $b->exists(map { $_->id } @entries) ],
        [ 1, 1 ],
        "both exist",
    );

    foreach my $entry ( @entries ) {
        ok( my $data = $b->_redis->get($entry->id), "got from db" );

        $data = $b->deserialize($data);

        isa_ok( $data, "KiokuDB::Entry" );
        is( ref $data->data, 'HASH', "hash loaded" );

        is( $data->id, $entry->id, "id is correct" );
    }

    my @clones = map { dclone($_) } @entries;

    is_deeply(
        [ $b->get(map { $_->id } @entries) ],
        [ @clones ],
        "loaded",
    );

    $b->delete($entries[0]->id);

    is_deeply(
        [ map { !$_ } $b->exists(map { $_->id } @entries) ],
        [ 1, !1 ],
        "deleted",
    );

    is_deeply(
        [ map { !$_ } $b->get(map { $_->id } @entries) ],
        [ ],
        "get for with some non-existent entries returns nothing",
    );
};

done_testing;