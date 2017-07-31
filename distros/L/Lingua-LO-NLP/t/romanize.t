#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use charnames qw/ :full lao /;
use open qw/ :encoding(UTF-8) :std /;
BEGIN { use lib -d 't' ? "t/lib" : "lib"; }
use Test::More;
use Test::Fatal;
use Lingua::LO::NLP::Romanize;

like(
    exception { Lingua::LO::NLP::Romanize->new(hyphen => 1) },
    qr/`variant' argument missing or undefined/,
    'Dies w/o "variant" arg'
);

# Broken plugin
like(
    exception { Lingua::LO::NLP::Romanize->new(variant => 'Faulty')->romanize('ຟູ') },
    ## no critic (RegularExpressions::ProhibitComplexRegexes) (this is not actually complex)
    qr/Lingua::LO::NLP::Romanize::Faulty must implement romanize_syllable\(\)/,
    'romanize_syllable is virtual'
);

# romanize_syllable as class method
like(
    exception { Lingua::LO::NLP::Romanize->romanize_syllable('ຟູ') },
    qr/romanize_syllable is not a class method/,
    'romanize_syllable enforces object method call'
);


my $r = Lingua::LO::NLP::Romanize->new(variant => 'PCGN');
isa_ok($r, 'Lingua::LO::NLP::Romanize::PCGN', 'PCGN subclass created');
is($r->romanize('ຫົກສິບ'), 'hôk sip', 'OK without hyphenation');
$r->hyphen(1);
is($r->romanize('ຫົກສິບ'), 'hôk-sip', 'OK with ASCII hyphen');
$r->hyphen('‐');
is($r->romanize('ຫົກສິບ'), 'hôk‐sip', 'OK with Unicode hyphen');
$r->hyphen(0);
is($r->romanize('ຫົກສິບ'), 'hôk sip', 'Hyphenation off again');
done_testing;
