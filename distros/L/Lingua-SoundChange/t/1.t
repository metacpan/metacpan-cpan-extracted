# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/1.t'

#########################

use lib qw(t/lib);
use Test::More tests => 49;

BEGIN { use_ok( 'Lingua::SoundChange' ) }

#########################

my($lang, $out);

# Test basic: no change

$lang = Lingua::SoundChange->new( {}, [] );

ok(ref $lang, '$lang is a reference');

$out = $lang->change(['foo']);

ok($out, '$out is true');
ok(ref $out, '$out is a reference');
is(ref $out, 'ARRAY', '$out is an arrayref');
is($out->[0]{word}, 'foo', '$out->[0]{word} is "foo", same as input');


# Test with only variables
$lang = Lingua::SoundChange->new( { A => 'abc', B => 'def' }, [] );
ok(ref $lang, '$lang is a reference (only variables)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'foo', 'No change (only variables)');


# Test with only rules
$lang = Lingua::SoundChange->new( {}, [ 'o/i/_' ] );
ok(ref $lang, '$lang OK (only rules)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'fii', 'foo --> fii');

$lang = Lingua::SoundChange->new( {}, [ 'o/i/f_' ] );
ok(ref $lang, '$lang OK (o/i/f_)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'fio', 'foo --> fio');


# Test with #
$lang = Lingua::SoundChange->new( {}, [ 'o/i/_#' ] );
ok(ref $lang, '$lang OK (o/i/_#)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'foi', 'foo --> foi');

$lang = Lingua::SoundChange->new( {}, [ 'o/i/#_' ] );
ok(ref $lang, '$lang OK (o/i/#_)');
$out = $lang->change(['oofoo']);
is($out->[0]{word}, 'iofoo', 'oofoo --> iofoo');


# Test rules order
$lang = Lingua::SoundChange->new( {}, [ 'fo/fe/_', 'o/i/_' ] );
ok(ref $lang, '$lang OK (two rules #1)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'fei', 'foo --> fei');

$lang = Lingua::SoundChange->new( {}, [ 'o/i/_', 'fo/fe/_' ] );
ok(ref $lang, '$lang OK (two rules #1)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'fii', 'foo --> fii');


# Test rules re-use
$lang = Lingua::SoundChange->new( {}, [ 'o/i/_' ] );
ok(ref $lang, '$lang OK (reuse)');
$out = $lang->change([qw(foo people wonder big fat)]);
is(scalar(@$out), 5, 'five words in return');
is($out->[0]{word}, 'fii', 'foo --> fii');
is($out->[1]{word}, 'peiple', 'people --> peiple');
is($out->[2]{word}, 'winder', 'wonder --> winder');
is($out->[3]{word}, 'big', 'big --> big');
is($out->[4]{word}, 'fat', 'fat --> fat');


# Test variables
$lang = Lingua::SoundChange->new( { V => 'aeiou' }, [ 'V/X/_' ] );
ok(ref $lang, '$lang OK (variables)');
$out = $lang->change(['oiseau', 'fsck']);
is($out->[0]{word}, 'XXsXXX', 'oiseau --> XXsXXX');
is($out->[1]{word}, 'fsck', 'fsck --> fsck');

$lang = Lingua::SoundChange->new( { V => 'aeiou', U => 'bfjpv' },
                                  [ 'V/U/_' ] );
ok(ref $lang, '$lang OK (change set --> set)');
$out = $lang->change(['oiseau', 'fsck']);
is($out->[0]{word}, 'pjsfbv', 'oiseau --> pjsfbv');
is($out->[1]{word}, 'fsck', 'fsck --> fsck');

$lang = Lingua::SoundChange->new( { C => 'ptkbdg' }, [ 'o/i/C_' ] );
ok(ref $lang, '$lang OK (variable in environment)');
$out = $lang->change(['comer', 'komer', 'capor', 'copor', 'tiki']);
is($out->[0]{word}, 'comer', 'comer (no change)');
is($out->[1]{word}, 'kimer', 'komer --> kimer');
is($out->[2]{word}, 'capir', 'capor --> capir');
is($out->[3]{word}, 'copir', 'copor --> copir');
is($out->[4]{word}, 'tiki', 'tiki (no change)');


# The Portuguese test!
$lang = Lingua::SoundChange->new(
    {
        V => 'aeiou',
        C => 'ptcqbdgmnlhrs',
        F => 'ie',
        B => 'ou',
        S => 'ptc',
        Z => 'bdg',
    },
    [
        's//_#',
        'm//_#',
        'e//Vr_#',
        'v//V_V',
        'u/o/_#',
        'gn/nh/_',
        'S/Z/V_V',
        'c/i/F_t',
        'c/u/B_t',
        'p//V_t',
        'ii/i/_',
        'e//C_rV',
    ],
    {
        printRules => 1,
    }
);
ok(ref $lang, '$lang OK (Portuguese example)');
$out = $lang->change([qw(
    lector
    doctor
    focus
    jocus
    districtus
    civitatem
    adoptare
    opera
    secundus
)]);
is($out->[0]{word}, 'leitor',   'lector     --> leitor');
is($out->[1]{word}, 'doutor',   'doctor     --> doutor');
is($out->[2]{word}, 'fogo',     'focus      --> fogo');
is($out->[3]{word}, 'jogo',     'jocus      --> jogo');
is($out->[4]{word}, 'distrito', 'districtus --> distrito');
is($out->[5]{word}, 'cidade',   'civitatem  --> cidade');
is($out->[6]{word}, 'adotar',   'adoptare   --> adotar');
is($out->[7]{word}, 'obra',     'opera      --> obra');
is($out->[8]{word}, 'segundo',  'secundus   --> segundo');
