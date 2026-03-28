#!/usr/bin/perl
# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-
#
# Copyright (c) PetaMem, s.r.o. 2009-present
#

# {{{ use block

use strict;
use warnings;
use utf8;
use 5.10.0;

use Test::More;

# }}}
# {{{ variable declarations

my $tests;

# }}}
# {{{ basic tests

BEGIN {
   use_ok('Lingua::Word2Num');
}

$tests++;

use Lingua::Word2Num     qw(:ALL);

# }}}
# {{{ preprocess_code

my $got      = Lingua::Word2Num::preprocess_code();
my $expected = undef;
is($got, $expected, 'preprocess_code: undef args');
$tests++;

$got      = Lingua::Word2Num::preprocess_code(undef, 'xx'),
$expected = undef;
is($got, $expected, 'preprocess_code: nonexisting language');
$tests++;

# }}}
# {{{ cardinal

$got      = cardinal(undef, 'five');
$expected = q{};
is($got, $expected, 'cardinal: undef language');
$tests++;

$got      = cardinal();
$expected = q{};
is($got, $expected, 'cardinal: undef args');
$tests++;

$got      = cardinal('de', 'zweiundvierzig');
is($got, 42, 'cardinal: de zweiundvierzig');
$tests++;

$got      = cardinal('*', 'zweiundvierzig');
is($got, 42, 'cardinal: wildcard detection');
$tests++;

# }}}
# {{{ cardinal_detect

my ($val, $lang) = cardinal_detect('zweiundvierzig');
is($val,  42,    'cardinal_detect: value');
is($lang, 'deu', 'cardinal_detect: lang');
$tests += 2;

$val = cardinal_detect('nonexistent_word_xyz');
ok(!defined $val, 'cardinal_detect: unknown word');
$tests++;

# }}}
# {{{ new — object construction

my $obj = Lingua::Word2Num->new("zwanzig");
isa_ok($obj, 'Lingua::Word2Num', 'new from text');
$tests++;

is($obj->value, 20,    'new from text: value');
is($obj->lang,  'deu', 'new from text: lang');
$tests += 2;

my $num_obj = Lingua::Word2Num->new(42);
is($num_obj->value, 42,    'new from number: value');
ok(!defined $num_obj->lang, 'new from number: no lang');
$tests += 2;

# }}}
# {{{ arithmetic

my $a = Lingua::Word2Num->new(20);
my $b = Lingua::Word2Num->new(16);

my $sum = $a + $b;
isa_ok($sum, 'Lingua::Word2Num', 'addition returns object');
is($sum->value, 36, 'addition: 20 + 16 = 36');
$tests += 2;

my $diff = $a - $b;
is($diff->value, 4, 'subtraction: 20 - 16 = 4');
$tests++;

my $prod = $a * $b;
is($prod->value, 320, 'multiplication: 20 * 16 = 320');
$tests++;

my $div = $a / $b;
is($div->value, 1, 'integer division: 20 / 16 = 1');
$tests++;

my $mod = $a % $b;
is($mod->value, 4, 'modulo: 20 % 16 = 4');
$tests++;

# increment/decrement
my $inc = Lingua::Word2Num->new(41);
$inc++;
is($inc->value, 42, 'increment: 41++ = 42');
$tests++;

$inc--;
is($inc->value, 41, 'decrement: 42-- = 41');
$tests++;

# numification
is(0 + $a, 20, 'numification');
$tests++;

# }}}
# {{{ as — word rendering

my $c = Lingua::Word2Num->new(42);

# ISO 639-1 codes
my $de = $c->as('de');
ok(defined $de && length $de > 0, 'as(de) — ISO 639-1');
$tests++;

my $fr = $c->as('fr');
ok(defined $fr && length $fr > 0, 'as(fr) — ISO 639-1');
$tests++;

# ISO 639-3 codes
my $deu = $c->as('deu');
ok(defined $deu && length $deu > 0, 'as(deu) — ISO 639-3');
$tests++;

is($de, $deu, 'as(de) eq as(deu) — same result for 639-1 and 639-3');
$tests++;

# invalid language code
my $xx = $c->as('xx');
ok(!defined $xx || $xx eq '', 'as(xx) — invalid code returns empty/undef');
$tests++;

my $zzz = $c->as('zzz');
ok(!defined $zzz || $zzz eq '', 'as(zzz) — invalid 639-3 returns empty/undef');
$tests++;

# undef language
my $und = $c->as(undef);
ok(!defined $und, 'as(undef) — returns undef');
$tests++;

# as() with no arg on object without detected lang
my $plain = Lingua::Word2Num->new(42);
my $noarg = $plain->as();
ok(!defined $noarg, 'as() no arg, no detected lang — returns undef');
$tests++;

# as() with no arg on object WITH detected lang
my $detected = Lingua::Word2Num->new("zwanzig");
my $auto = $detected->as();
ok(defined $auto && length $auto > 0, 'as() no arg, detected deu — returns German text');
$tests++;

# }}}
# {{{ edge cases for new()

my $undef_obj = Lingua::Word2Num->new(undef);
is($undef_obj->value, 0, 'new(undef) — value is 0');
$tests++;

my $zero_obj = Lingua::Word2Num->new(0);
is($zero_obj->value, 0, 'new(0) — value is 0');
$tests++;

my $neg_obj = Lingua::Word2Num->new(-42);
is($neg_obj->value, -42, 'new(-42) — negative number accepted');
$tests++;

# }}}
# {{{ cross-language arithmetic

my $german  = Lingua::Word2Num->new("zwanzig");
my $czech   = Lingua::Word2Num->new(16);
my $result  = $german + $czech;

is($result->value, 36, 'cross-language: value');
$tests++;

my $as_de = $result->as('de');
ok(defined $as_de && length $as_de > 0, 'cross-language: as(de)');
$tests++;

# }}}

done_testing($tests);

__END__
