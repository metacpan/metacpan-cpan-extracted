#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Requires 'Crypt::Rijndael';
use Test::Requires 'Crypt::CFB';
use Test::Requires 'DateTime';

use KiokuDB;
use KiokuDB::Util;
use KiokuDB::Serializer::Crypt;

my $backend = KiokuDB::Util::dsn_to_backend(
    'hash',
    serializer => KiokuDB::Serializer::Crypt->new(
        serializer   => 'json',
        crypt_cipher => 'Rijndael',
        crypt_mode   => 'CFB',
        crypt_key    => 'foo',
    ),
);

my $d = KiokuDB->new(backend => $backend);
my $obj = [DateTime->now];

{
    my $s = $d->new_scope;
    $d->insert(obj => $obj);
}

{
    my $s = $d->new_scope;
    my $db_obj = $d->lookup('obj');
    is(ref($db_obj), 'ARRAY', "got array back");
    isa_ok($db_obj->[0], 'DateTime');
    is_deeply($db_obj, $obj, "got the right obj");
}

done_testing;
