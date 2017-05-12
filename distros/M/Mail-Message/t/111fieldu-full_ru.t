#!/usr/bin/env perl
#
# Test processing of full fields with russian chars in utf-8.
#

use strict;
use warnings;
use utf8;

use Mail::Message::Test;
use Mail::Message::Field::Structured;

use Test::More tests => 3;

my $mmfs = 'Mail::Message::Field::Structured';

my $r = $mmfs->new('r', '');
isa_ok($r, $mmfs);

my $text_ru =
  "Раньше длинные multibyte-последовательности кодировались неправильно, теперь должно работать.";
is($r->decode($r->encode($text_ru, charset => 'utf-8', encoding => 'q')),
    $text_ru, 'encode/decode to/from QP');
is($r->decode($r->encode($text_ru, charset => 'utf-8', encoding => 'b')),
    $text_ru, 'encode/decode to/from Base64');
