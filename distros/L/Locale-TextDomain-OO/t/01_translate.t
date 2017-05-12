#!perl -T

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
}

my $loc = Locale::TextDomain::OO->new;
is
    $loc->translate,
    undef,
    'translate empty';
is
    $loc->translate(undef, 'dummy'),
    'dummy',
    'translate';
is
    $loc->translate('context', 'dummy'),
    'dummy',
    'translate context';
is
    $loc->translate(undef, 'dummy', 'dummys', 1, 'is_n'),
    'dummy',
    'translate singular';
is
    $loc->translate(undef, 'dummy', 'dummies', 0, 'is_n'),
    'dummies',
    'translate plural';
is
    $loc->translate('context', 'dummy', 'dummys', 1, 'is_n'),
    'dummy',
    'translate context singular';
is
    $loc->translate('context', 'dummy', 'dummies', 2, 'is_n'),
    'dummies',
    'translate context plural';
