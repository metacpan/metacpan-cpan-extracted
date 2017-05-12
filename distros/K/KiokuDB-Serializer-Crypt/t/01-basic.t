#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Crypt::Rijndael';
use Test::Requires 'Crypt::CFB';
use Test::Requires 'JSON';

use Crypt::Util;
use KiokuDB;
use KiokuDB::Util;
use Storable 'thaw';

use KiokuDB::Serializer::Crypt;

{
    my $backend = KiokuDB::Backend::Hash->new(
        serializer => KiokuDB::Serializer::Crypt->new(crypt_key => 's3cr3t'),
    );
    my $d = KiokuDB->new(backend => $backend);

    {
        my $s = $d->new_scope;
        my $foo = Moose::Meta::Class->create('Foo')->new_object;
        $d->insert(foo => $foo);
    }

    {
        my $storage = $d->backend->storage;
        my $serialized_foo = $storage->{foo};

        my $crypt = Crypt::Util->new(default_key => 's3cr3t');
        my $decrypted = $crypt->decrypt_string($serialized_foo);
        my $data = thaw($decrypted);
        is_deeply(
            $data,
            {
                class => 'Foo',
                root  => 1,
                id    => 'foo',
                data  => {},
            },
            "encrypted properly"
        );
    }

    {
        my $s = $d->new_scope;
        my $foo = $d->lookup('foo');
        isa_ok($foo, 'Foo');
    }
}

{
    my $backend = KiokuDB::Backend::Hash->new(
        serializer => KiokuDB::Serializer::Crypt->new(
            crypt_key  => 's3cr3t',
            serializer => 'json',
        ),
    );
    my $d = KiokuDB->new(backend => $backend);

    {
        my $s = $d->new_scope;
        my $foo = Moose::Meta::Class->create('Bar')->new_object;
        $d->insert(foo => $foo);
    }

    {
        my $storage = $d->backend->storage;
        my $serialized_foo = $storage->{foo};

        my $crypt = Crypt::Util->new(default_key => 's3cr3t');
        my $decrypted = $crypt->decrypt_string($serialized_foo);
        my $data = JSON->new->decode($decrypted);
        is_deeply(
            $data,
            {
                __CLASS__ => 'Bar',
                root      => 'true',
                id        => 'foo',
                data      => {},
            },
            "encrypted properly"
        );
    }

    {
        my $s = $d->new_scope;
        my $foo = $d->lookup('foo');
        isa_ok($foo, 'Bar');
    }
}

{
    my $backend = KiokuDB::Backend::Hash->new(
        serializer => KiokuDB::Serializer::Crypt->new(
            crypt      => Crypt::Util->new(default_key => 's3cr3t'),
            serializer => 'json',
        ),
    );
    my $d = KiokuDB->new(backend => $backend);

    {
        my $s = $d->new_scope;
        my $foo = Moose::Meta::Class->create('Baz')->new_object;
        $d->insert(foo => $foo);
    }

    {
        my $storage = $d->backend->storage;
        my $serialized_foo = $storage->{foo};

        my $crypt = Crypt::Util->new(default_key => 's3cr3t');
        my $decrypted = $crypt->decrypt_string($serialized_foo);
        my $data = JSON->new->decode($decrypted);
        is_deeply(
            $data,
            {
                __CLASS__ => 'Baz',
                root      => 'true',
                id        => 'foo',
                data      => {},
            },
            "encrypted properly"
        );
    }

    {
        my $s = $d->new_scope;
        my $foo = $d->lookup('foo');
        isa_ok($foo, 'Baz');
    }
}

done_testing;
