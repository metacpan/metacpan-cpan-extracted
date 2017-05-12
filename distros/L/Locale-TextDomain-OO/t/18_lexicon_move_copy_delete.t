#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
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
            '*::'          => 'foo * bar.mo',
            '*::'          => 'foo * bar/baz.mo',
            move_lexicon   => 'i-default::' => 'i-default:LC_MESSAGES:domain',
            delete_lexicon => 'de-at::',
        ],
    });
my $instance = Locale::TextDomain::OO::Singleton::Lexicon->instance;
eq_or_diff
    [ sort keys %{ $instance->data } ],
    [ qw( de:: i-default:LC_MESSAGES:domain ) ],
    'all lexicon names';

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    plugins  => [ qw( Expand::Gettext ) ],
    logger   => sub { note shift },
);
is
    $loc->__('This is a text.'),
    'Das ist ein Text.',
    'text';
is
    $loc->__('January'),
    'Januar',
    'January';
