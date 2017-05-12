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
    plugins  => [ qw( Expand::Gettext::DomainAndCategory ) ],
    language => 'de',
    # category empty, set later using __begin_c
    domain   => 'test',
    logger   => sub { note shift },
);

$ltdoo->__begin_c('LC_MESSAGES');
is
    $ltdoo->__(
        'This is a text.',
    ),
    'Das ist ein Text.',
    '__';
is
    $ltdoo->__p(
        'maskulin',
        'Dear',
    ),
    'Sehr geehrter',
    '__p';

$ltdoo->__end_c;
is
    $ltdoo->category,
    q{},
    'restored category';
