#!/usr/bin/perl -w
use strict;
use bytes;

use Test::More tests => 25;

use Digest::Skein ':all';
use Digest ();
use MIME::Base64 'encode_base64';

my $foo_256 = '8a62e0aa350e48167888bce63cbe19dbe6f7050a741b9aea9a71fcadae3135bd';
my $foo_512 =
'1e31c95343e74032ae2fa2ea51215617fd7bc7f8433d49363d7a43e9c98852c3e8cc2ec75de2b2963ff9676f56fdd708eaa85731b862cf2afd75929f93868d5c';
my $foo_1024 =
'e21acc3706f1c54d438ad8e821c40ecf2b0fee642c1a5aaed2c83218a645a976fe798868fe6fc7e3f506ef46704eea800345bf9a6c79d0d82fc4e4e24832cabf67227f57c7ae4e5f5eef92f7157fd22d8b7b94595fc0b5cb8c4d4ebddc053ec8bdae62e4f07d59ecc80dae396b8d27bcef05dd4b6e36f8ee494324e9e372a7c6';

is( lc Digest::Skein::Skein( 256, 'foo' ), lc $foo_256, 'Skein256("foo")' );

# procedural

is( unpack( 'H*', skein_256('foo') ),  lc $foo_256,  'skein_256("foo")'  );
is( unpack( 'H*', skein_512('foo') ),  lc $foo_512,  'skein_512("foo")'  );
is( unpack( 'H*', skein_1024('foo') ), lc $foo_1024, 'skein_1024("foo")' );

is( skein_256_hex('foo'),  lc $foo_256,  '256_hex(foo)'  );
is( skein_512_hex('foo'),  lc $foo_512,  '512_hex(foo)'  );
is( skein_1024_hex('foo'), lc $foo_1024, '1024_hex(foo)' );

is( encode_base64( skein_512('foo') ), skein_512_base64('foo'), 'base64' );

# OO interface

ok( my $digest = Digest->Skein(256), 'new 256' );
ok( $digest->add("f"), 'add "f"' );

is( $digest,            $digest->add("oo"), 'chaining' );
is( $digest->hexdigest, lc $foo_256,        '256(foo)' );

is( Digest->new('Skein')->add('bar')->hexdigest, Digest->Skein->new(512)->add('bar')->hexdigest, 'default=512' );

is( Digest->Skein(256)->add('foo')->hexdigest,  lc $foo_256,  '256(foo)'  );
is( Digest->Skein(512)->add('foo')->hexdigest,  lc $foo_512,  '512(foo)'  );
is( Digest->Skein(1024)->add('foo')->hexdigest, lc $foo_1024, '1024(foo)' );

ok( $digest->new(128), 'new(128)' );
is( $digest->hashbitlen, 128, 'hashbitlen()' );

$digest->add(qw/f o o/);

ok( $digest->new,             'new() as a method' );
is( $digest->hashbitlen, 128, 'new() as a method retains hashbitlen by default' );
ok( $digest->new(256),        '...but hashbitlen can be forced...' );
is( $digest->hashbitlen, 256, '...and it actually works' );

is( $digest->add("foo")->hexdigest,        lc $foo_256, 'prepare for reset() test...' );
is( $digest->reset->add("foo")->hexdigest, lc $foo_256, 'reset() returns a clean object' );
is( $digest->add("foo")->hexdigest,        lc $foo_256, 'digest() also resets the object' );

# vim: ts=4 sw=4 noet
