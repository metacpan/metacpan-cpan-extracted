#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Util qw(:all);
use Test::More;

can_ok('File::KDBX::Util', qw{
    assert_64bit
    can_fork
    dumper
    empty
    erase
    erase_scoped
    format_uuid
    generate_uuid
    gunzip
    gzip
    load_optional
    nonempty
    pad_pkcs7
    query
    search
    simple_expression_query
    snakify
    split_url
    trim
    uri_escape_utf8
    uri_unescape_utf8
    uuid
});

subtest 'Emptiness' => sub {
    my @empty;
    my @nonempty = 0;
    ok empty(@empty), 'Empty array should be empty';
    ok !nonempty(@empty), 'Empty array should be !nonempty';
    ok !empty(@nonempty), 'Array should be !empty';
    ok nonempty(@nonempty), 'Array should be nonempty';

    my %empty;
    my %nonempty = (a => 'b');
    ok empty(%empty), 'Empty hash should be empty';
    ok !nonempty(%empty), 'Empty hash should be !nonempty';
    ok !empty(%nonempty), 'Hash should be !empty';
    ok nonempty(%nonempty), 'Hash should be nonempty';

    my $empty = '';
    my $nonempty = '0';
    my $eref1 = \$empty;
    my $eref2 = \$eref1;
    my $nref1 = \$nonempty;
    my $nref2 = \$nref1;

    for my $test (
        [0, $empty,     'Empty string'],
        [0, undef,      'Undef'],
        [0, \undef,     'Reference to undef'],
        [0, {},         'Empty hashref'],
        [0, [],         'Empty arrayref'],
        [0, $eref1,     'Reference to empty string'],
        [0, $eref2,     'Reference to reference to empty string'],
        [0, \\\\\\\'',  'Deep reference to empty string'],
        [1, $nonempty,  'String'],
        [1, 'hi',       'String'],
        [1, 1,          'Number'],
        [1, 0,          'Zero'],
        [1, {a => 'b'}, 'Hashref'],
        [1, [0],        'Arrayref'],
        [1, $nref1,     'Reference to string'],
        [1, $nref2,     'Reference to reference to string'],
        [1, \\\\\\\'z', 'Deep reference to string'],
    ) {
        my ($expected, $thing, $note) = @$test;
        if ($expected) {
            ok !empty($thing), "$note should be !empty";
            ok nonempty($thing), "$note should be nonempty";
        }
        else {
            ok empty($thing), "$note should be empty";
            ok !nonempty($thing), "$note should be !nonempty";
        }
    }
};

subtest 'UUIDs' => sub {
    my $uuid  = "\x01\x23\x45\x67\x89\xab\xcd\xef\x01\x23\x45\x67\x89\xab\xcd\xef";
    my $uuid1 = uuid('01234567-89AB-CDEF-0123-456789ABCDEF');
    my $uuid2 = uuid('0123456789ABCDEF0123456789ABCDEF');
    my $uuid3 = uuid('012-3-4-56-789AB-CDEF---012-34567-89ABC-DEF');

    is $uuid1, $uuid, 'Formatted UUID is packed';
    is $uuid2, $uuid, 'Formatted UUID does not need dashes';
    is $uuid2, $uuid, 'Formatted UUID can have weird dashes';

    is format_uuid($uuid), '0123456789ABCDEF0123456789ABCDEF', 'UUID unpacks to hex string';
    is format_uuid($uuid, '-'), '01234567-89AB-CDEF-0123-456789ABCDEF', 'Formatted UUID can be delimited';

    my %uuid_set = ($uuid => 'whatever');

    my $new_uuid = generate_uuid(\%uuid_set);
    isnt $new_uuid, $uuid, 'Generated UUID is not in set';

    $new_uuid = generate_uuid(sub { !$uuid_set{$_} });
    isnt $new_uuid, $uuid, 'Generated UUID passes a test function';

    like generate_uuid(print => 1),     qr/^[A-Za-z0-9]+$/, 'Printable UUID is printable (1)';
    like generate_uuid(printable => 1), qr/^[A-Za-z0-9]+$/, 'Printable UUID is printable (2)';
};

subtest 'Snakification' => sub {
    is snakify('FooBar'), 'foo_bar', 'Basic snakification';
    is snakify('MyUUIDSet'), 'my_uuid_set', 'Acronym snakification';
    is snakify('Numbers123'), 'numbers_123', 'Snake case with numbers';
    is snakify('456Baz'), '456_baz', 'Prefixed numbers';
};

subtest 'Padding' => sub {
    plan tests => 8;

    is pad_pkcs7('foo', 2), "foo\x01", 'Pad one byte to fill the second block';
    is pad_pkcs7('foo', 4), "foo\x01", 'Pad one byte to fill one block';
    is pad_pkcs7('foo', 8), "foo\x05\x05\x05\x05\x05", 'Pad to fill one block';
    is pad_pkcs7('moof', 4), "moof\x04\x04\x04\x04", 'Add a whole block of padding';
    is pad_pkcs7('', 3), "\x03\x03\x03", 'Pad an empty string';
    like exception { pad_pkcs7(undef, 8) }, qr/must provide a string/i, 'String must be defined';
    like exception { pad_pkcs7('bar') }, qr/must provide block size/i, 'Size must defined';
    like exception { pad_pkcs7('bar', 0) }, qr/must provide block size/i, 'Size must be non-zero';
};

done_testing;
