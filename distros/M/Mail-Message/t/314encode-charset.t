#!/usr/bin/env perl
# Conversion of character-sets
#

use strict;
use warnings;
use utf8;

use Mail::Message::Test;
use Mail::Message::Body;

use Scalar::Util 'refaddr';
use Test::More;

my $src = "märkøv\n";  # fragile!  must be utf8, not latin1
ok utf8::is_utf8($src), 'string with utf8';

my $dec = Mail::Message::Body->new(data => $src)->decoded;

isa_ok($dec, 'Mail::Message::Body');
is($dec->charset, 'PERL', 'default charset PERL');

my $enc1 = $dec->encode(charset => 'PERL');
is(ref $dec, ref $enc1, 'same type');
is(refaddr $dec, refaddr $enc1, 'same object');
is($enc1->charset, 'PERL', 'charset PERL');

my $enc2 = $dec->encode(charset => 'utf8', transfer_encoding => 'quoted-printable');
is ref $dec, ref $enc2, 'same type';
isnt refaddr $dec, refaddr $enc2, 'new object';

is $enc2->charset, 'utf8';
my @lines = $enc2->lines;
cmp_ok scalar @lines, '==', 1, 'body has 1 line';
is $lines[0], "m=C3=A4rk=C3=B8v\n";
ok !utf8::is_utf8($lines[0]), 'raw bytes';

my $rec = $enc2->encode(charset => 'PERL', transfer_encoding => 'none');
is(ref $rec, ref $enc2, 'same type');
isnt(refaddr $rec, refaddr $enc2, 'new object');
isnt(refaddr $rec, refaddr $dec, 'new object');
ok($rec->charset.'', 'PERL');
@lines = $rec->lines;
cmp_ok(scalar @lines, '==', 1);
is($lines[0], $src, 'transfer decoded');
ok(utf8::is_utf8($lines[0]), 'is perl utf-8');

done_testing;
