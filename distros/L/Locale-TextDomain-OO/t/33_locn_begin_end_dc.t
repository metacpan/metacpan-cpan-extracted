#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
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
    # domain empty, set later using loc_begin_d
    # category empty, set later using loc_begin_c
    logger   => sub { note shift },
);

is
    $ltdoo->locn(
        domain   => 'test',
        text     => 'This is a text.',
        category => 'LC_MESSAGES',
    ),
    'Das ist ein Text.',
    'locn domain category';
is
    $ltdoo->locn(
        domain   => 'test',
        context  => 'maskulin',
        text     => 'Dear',
        category => 'LC_MESSAGES',
    ),
    'Sehr geehrter',
    'locn domain context category';

is
    $ltdoo->domain,
    q{},
    'restored domain';
is
    $ltdoo->category,
    q{},
    'restored category';
