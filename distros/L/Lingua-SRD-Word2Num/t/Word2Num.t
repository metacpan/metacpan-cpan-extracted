#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SRD::Word2Num');
    $tests++;
}

use Lingua::SRD::Word2Num qw(w2n);

# --- Basic numbers ---
is(w2n('chimbe'),    5,   'chimbe => 5');       $tests++;
is(w2n('zeru'),      0,   'zeru => 0');         $tests++;
is(w2n('deghe'),     10,  'deghe => 10');       $tests++;
is(w2n('undighi'),   11,  'undighi => 11');     $tests++;
is(w2n('bindighi'),  15,  'bindighi => 15');    $tests++;
is(w2n('deghesete'), 17,  'deghesete => 17');   $tests++;
is(w2n('deghenoe'),  19,  'deghenoe => 19');    $tests++;

# --- Tens ---
is(w2n('binti'),     20,  'binti => 20');       $tests++;
is(w2n('trinta'),    30,  'trinta => 30');      $tests++;
is(w2n('nonanta'),   90,  'nonanta => 90');     $tests++;

# --- Compound tens ---
is(w2n('bintunu'),      21,  'bintunu => 21');      $tests++;
is(w2n('bintitres'),    23,  'bintitres => 23');     $tests++;
is(w2n('barantaduos'),  42,  'barantaduos => 42');   $tests++;

# --- Hundreds ---
is(w2n('chentu'),       100, 'chentu => 100');       $tests++;
is(w2n('duchentos'),    200, 'duchentos => 200');     $tests++;
is(w2n('trechentos'),   300, 'trechentos => 300');    $tests++;

# --- Compound hundreds ---
is(w2n('chentu bintitres'),     123, 'chentu bintitres => 123');    $tests++;
is(w2n('duchentos chinbanta'),  250, 'duchentos chinbanta => 250'); $tests++;

# --- Thousands ---
is(w2n('milli'),        1000,  'milli => 1000');      $tests++;
is(w2n('milli chentu'), 1100,  'milli chentu => 1100'); $tests++;

# --- undef input ---
my $result = w2n(undef);
ok(!defined $result, 'undef input');  $tests++;

done_testing($tests);
