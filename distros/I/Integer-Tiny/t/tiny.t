#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use Test::More 'tests' => 23;
use Test::Exception;

use Math::BigInt;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Integer::Tiny;

my $it;

dies_ok(sub { Integer::Tiny->new() },      'Missing key');
dies_ok(sub { Integer::Tiny->new('X') },   'Key too short');
dies_ok(sub { Integer::Tiny->new('lol') }, 'Key contains duplicated characters');

lives_ok(sub { $it = Integer::Tiny->new('01') }, 'Valid 2 char key');
dies_ok(sub { $it->encrypt() },      'Encrypt without param');
dies_ok(sub { $it->encrypt('lol') }, 'Encrypt no Integer value');
dies_ok(sub { $it->decrypt() },      'Decrypt without param');
dies_ok(sub { $it->decrypt('') },    'Decrypt empty string');
dies_ok(sub { $it->decrypt('!') },   'Decrypt string with characters not in key');
is($it->encrypt(0),   '0', 'Encrypt bool false');
is($it->decrypt('0'), 0,   'Decrypt bool false');
is($it->encrypt(1),   '1', 'Encrypt bool true');
is($it->decrypt('1'), 1,   'Decrypt bool true');

lives_ok(sub { $it = Integer::Tiny->new('GCAT') }, 'Valid 4 char key');
is($it->encrypt(48888851145),          'ATCAGAGGGGAAAATGAC', 'encrypt 48888851145');
is($it->decrypt('ATCAGAGGGGAAAATGAC'), 48888851145,          'decrypt ATCAGAGGGGAAAATGAC');

lives_ok(sub { $it = Integer::Tiny->new('hc2riK8fku7ezavCBJdMPwmntZ1s0yU4bOLI3SHRqANXFVD69gTG5oYQjExplW') },
    'Valid alphanumeric key');
is($it->encrypt(48888851145), 'om3R4e',    'encrypt 48888851145');
is($it->decrypt('om3R4e'),    48888851145, 'decrypt om3R4e');

lives_ok(sub { $it = Integer::Tiny->new('☺☻') }, 'Valid utf8 char key');
is( $it->encrypt(48888851145),
    '☻☺☻☻☺☻☻☺☺☺☻☺☺☺☺☺☺☺☺☺☻☺☻☺☻☺☻☺☻☻☺☺☻☺☺☻',
    'encrypt utf'
);
is( $it->decrypt(
        '☻☺☻☻☺☻☻☺☺☺☻☺☺☺☺☺☺☺☺☺☻☺☻☺☻☺☻☺☻☻☺☺☻☺☺☻'),
    48888851145,
    'decrypt utf'
);

{

    # heavy load test
    # encrypt 512-digit number using Katakana 95-char key

    my $n = 1 + int rand 9;
    $n .= join('', map { int rand 10 } 1 .. 511);

    my $huge_number = Math::BigInt->new($n);

    my $katakana = join('', map { chr $_ } 0x30a1 .. 0x30ff);

    $it = Integer::Tiny->new($katakana);
    my $encrypted = $it->encrypt($huge_number);
    my $decrypted = $it->decrypt($encrypted);

    is($huge_number->bstr(), $decrypted->bstr(), '512-digit number using Katakana 95-char key');
}
