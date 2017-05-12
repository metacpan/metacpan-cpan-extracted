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
    plugins  => [ qw( Expand::Gettext::Loc::DomainAndCategory ) ],
    language => 'de',
    # domain empty, set later using loc_begin_d
    # category empty, set later using loc_begin_c
    logger   => sub { note shift },
);

$ltdoo->loc_begin_dc('test', 'LC_MESSAGES');
is
    $ltdoo->loc_(
        'This is a text.',
    ),
    'Das ist ein Text.',
    'loc_';
is
    $ltdoo->loc_p(
        'maskulin',
        'Dear',
    ),
    'Sehr geehrter',
    'loc_p';

$ltdoo->loc_end_dc;
is
    $ltdoo->domain,
    q{},
    'restored domain';
is
    $ltdoo->category,
    q{},
    'restored category';
