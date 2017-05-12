use utf8;
use strict;
use warnings;

use Test::Deep;
use Test::More;

use FindBin qw($Bin);

use Test::Builder ();

binmode $_, ':encoding(UTF-8)' for map { Test::Builder->new->$_ } qw(output failure_output);

use_ok( 'Locale::Babelfish' ) or exit 1;

my $l10n = Locale::Babelfish->new({
    dirs           => [ $Bin ],
    default_locale => 'en_US',
});

is(
    $l10n->t( 'test1.developers.some.test' ),
    '[test1.developers.some.test]',
    'not existing key',
);

is(
    $l10n->t( 'test.simple', { dummy => ' test script ' } ),
    'I am ',
    'dummy_parameter',
 );

is(
    $l10n->t( 'test.dummy_key', { who => ' test script ' } ),
    '[test.dummy_key]' ,
    'dummy_key',
 );

is(
    $l10n->t( 'test.simple', { who => 'test script' } ),
    'I am test script',
    'simple_var',
 );

is(
    $l10n->t( 'test.case1.combine', { single => { test => { deep => 'example'} } , count => 10 , test => 2 } ),
    'I have 10 nails for example for 2 tests',
    'check2',
);

is(
    $l10n->t( 'test.plural.case1', { test => 10 } ),
    'I have 10 nails',
    'plural1',
);

is(
    $l10n->t( 'test.plural.case1', { test => 1 } ),
    'I have 1 nail',
    'plural2',
);

is(
    $l10n->t( 'test.plural.case2', { test => 1 } ),
    'I have 1 nail simple using',
    'plural3',
 );

is(
    $l10n->t( 'test.plural.case3', 17 ),
    'I have 17 big nails',
    'plural4',
);

is(
    $l10n->has_any_value( 'test.plural.case1' ),
    1,
    'has_any_value found',
);

is(
    $l10n->has_any_value( 'test.plural.case1123' ),
    0,
    'has_any_value not found',
);

$l10n->locale( 'ru_RU' );

is(
    $l10n->locale,
    'ru_RU',
    'Check current locale',
);

is(
    $l10n->t( 'test.simple.plural.nails4', { test => 1, test2 => 20 } ),
    'Берём 1 гвоздь для 20 досок и вбиваем 1 гвоздь в 20 досок',
    'repeat_twice',
);

is(
    $l10n->t( 'test.simple.plural.nails', { test => 10 } ),
    'У меня 10 гвоздей',
    'RU plural1',
);

is(
    $l10n->t( 'test.simple.plural.nails', { test => 3 } ),
    'У меня 3 гвоздя',
    'RU plural2',
);

is(
    $l10n->t( 'test.simple.plural.nails3', { test => 1 } ),
    '1 у меня гвоздь',
    'RU plural3',
);

done_testing;

