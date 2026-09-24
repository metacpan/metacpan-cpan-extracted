#!/usr/bin/env perl
# The ENCODING POD contract: a UTF-8-flagged string is stored as its UTF-8
# bytes, and values come back as byte strings without the flag.
use strict;
use warnings;
use utf8;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use Encode qw(encode_utf8 decode_utf8 is_utf8);

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $available;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $prefix = "/test_encoding_$$";

my $literal = "café";
ok(is_utf8($literal), 'literal has UTF-8 flag');

my $put_ok;
$client->put("$prefix/utf8", $literal, sub { $put_ok = !$_[1]; EV::break });
EV::run;
ok($put_ok, 'put utf8-flagged value succeeded');

my $got;
$client->get("$prefix/utf8", sub { $got = $_[0]; EV::break });
EV::run;

my $bytes = $got->{kvs}[0]{value};
ok(!is_utf8($bytes), 'returned value is a byte string (no UTF-8 flag)');
is(length $bytes, 5, 'returned value is 5 bytes (4-char string had a 2-byte é)');
is($bytes, encode_utf8($literal), 'returned bytes equal encode_utf8 of original');
is(decode_utf8($bytes), $literal, 'decode_utf8 round-trips');

my $pre = encode_utf8("naïve");
$client->put("$prefix/bytes", $pre, sub { EV::break });
EV::run;
$client->get("$prefix/bytes", sub { $got = $_[0]; EV::break });
EV::run;
is($got->{kvs}[0]{value}, $pre, 'pre-encoded bytes round-trip');

my $with_nul = "before\0after";
$client->put("$prefix/nul", $with_nul, sub { EV::break });
EV::run;
$client->get("$prefix/nul", sub { $got = $_[0]; EV::break });
EV::run;
is($got->{kvs}[0]{value}, $with_nul, 'embedded NUL survives');
is(length $got->{kvs}[0]{value}, length $with_nul, 'embedded NUL length preserved');

$client->delete("$prefix/", { prefix => 1 }, sub { EV::break });
my $tg = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
