#!perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::MO');
}

Locale::TextDomain::OO::Lexicon::File::MO
    ->new
    ->lexicon_ref({
        search_dirs => [ qw( ./t/LocaleData ) ],
        data => [
            '*:LC_MESSAGES:test' => '*/LC_MESSAGES/test.mo',
        ],
        gettext_to_maketext => 1,
        decode              => 1,
    });

my $ltdoo = Locale::TextDomain::OO->new(
    plugins  => [ qw( Expand::Gettext::Named ) ],
    language => 'de',
    # category empty, set later using locn c
    domain   => 'test',
    logger   => sub { note shift },
);

is
    $ltdoo->locn(
        text     => 'This is a text.',
        category => 'LC_MESSAGES',
    ),
    'Das ist ein Text.',
    'locn category';
is
    $ltdoo->locn(
        context  => 'maskulin',
        text     => 'Dear',
        category => 'LC_MESSAGES',
    ),
    'Sehr geehrter',
    'locn context category';

is
    $ltdoo->category,
    q{},
    'restored category';
