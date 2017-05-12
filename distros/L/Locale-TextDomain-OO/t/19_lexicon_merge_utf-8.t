#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 9;
use Test::Differences;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::MO');
    require_ok('Locale::TextDomain::OO::Singleton::Lexicon');
}

Locale::TextDomain::OO::Lexicon::File::MO
    ->new(
        logger => sub { note shift },
    )
    ->lexicon_ref({
        search_dirs => [ './t/LocaleData' ],
        decode      => 1,
        data        => [
            '*::'         => 'foo * bar.mo',
            '*::'         => 'foo * bar/baz.mo',
            merge_lexicon => 'de::', 'de-at::' => 'de-at::',
        ],
    });
my $instance = Locale::TextDomain::OO::Singleton::Lexicon->instance;
eq_or_diff
    [ sort keys %{ $instance->data } ],
    [ qw( de-at:: de:: i-default:: ) ],
    'all lexicon names';

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    plugins  => [ qw( Expand::Gettext ) ],
    logger   => sub { note shift },
);
is
    $loc->__('This is a text.'),
    'Das ist ein Text.',
    'de text';
is
    $loc->__('January'),
    'Januar',
    'de January';

$loc->language('de-at');
is
    $loc->__('This is a text.'),
    'Das ist ein Text.',
    'de-at text from de';
is
    $loc->__('January'),
    'Jänner',
    'de-at January';
