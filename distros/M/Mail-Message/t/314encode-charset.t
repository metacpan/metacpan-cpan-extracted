#!/usr/bin/env perl
# Conversion of character-sets
#

use strict;
use warnings;
use utf8;

use Mail::Message::Test;
use Mail::Message::Body;

use Scalar::Util 'refaddr';
use Data::Dumper;
use Test::More tests => 19;


my $src = "märkøv\n";  # fragile!  must be utf8, not latin1
ok utf8::is_utf8($src), 'string with utf8';

my $dec = Mail::Message::Body->new(data => $src)->decoded;

isa_ok($dec, 'Mail::Message::Body');
is($dec->charset, 'PERL', 'default charset PERL');

my $enc = $dec->encode(charset => 'PERL');
is(ref $dec, ref $enc, 'same type');
is(refaddr $dec, refaddr $enc, 'same object');
is($enc->charset, 'PERL', 'charset PERL');

$enc = $dec->encode(charset => 'utf8', transfer_encoding => 'quoted-printable');
is(ref $dec, ref $enc, 'same type');
isnt(refaddr $dec, refaddr $enc, 'new object');

is($enc->charset, 'utf8');
my @lines = $enc->lines;
cmp_ok(scalar @lines, '==', 1);
is($lines[0], "m=C3=A4rk=C3=B8v\n");
ok(!utf8::is_utf8($lines[0]), 'raw bytes');

my $rec = $enc->encode(charset => 'PERL', transfer_encoding => 'none');
is(ref $rec, ref $enc, 'same type');
isnt(refaddr $rec, refaddr $enc, 'new object');
isnt(refaddr $rec, refaddr $dec, 'new object');
ok($rec->charset.'', 'PERL');
@lines = $rec->lines;
cmp_ok(scalar @lines, '==', 1);
is($lines[0], $src, 'transfer decoded');
ok(utf8::is_utf8($lines[0]), 'is perl utf-8');


