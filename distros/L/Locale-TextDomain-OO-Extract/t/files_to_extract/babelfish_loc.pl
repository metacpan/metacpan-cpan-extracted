#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::BabelFish::Loc ) ],
);

# run all translations
() = print map {"$_\n"}
    $loc->loc_b(
        'This is a text.',
    ),
    $loc->loc_b(
        '#{name} is programming #{language}.',
        name     => 'Steffen',
        language => 'Perl',
    ),
    $loc->loc_b(
        '((Singular|Plural))',
        1,
    ),
    $loc->loc_b(
        '((Singular|Plural))',
        2,
    ),
    $loc->loc_b(
        '#{count :num} ((date|dates))',
        1,
    ),
    $loc->loc_b(
        '#{count :num} ((date|dates))',
        2,
    ),
    $loc->loc_bp(
        'appointment',
        'date',
    ),
    $loc->loc_bp(
        'appointment',
        '#{num} date',
        num => 1,
    ),
    $loc->loc_bp(
        'appointment',
        '((date|dates)):num',
        num => 1,
    ),
    $loc->loc_bp(
        'appointment',
        '((date|dates)):num',
        num => 2,
    ),
    $loc->loc_bp(
        'appointment',
        '#{num} ((date|dates)):num',
        num => 1,
    ),
    $loc->loc_bp(
        'appointment',
        '#{num} ((date|dates)):num',
        num => 2,
    ),
;

# Extract special stuff only
$loc->Nloc_b(
    '\' quoted text with \\.',
);
$loc->Nloc_b(
    q{q\{ quoted text with #{placeholders\}}.},
);
$loc->Nloc_b(
    q{quoted text.},
);

# with domain and/or category
$loc->loc_bd('domain d', 'text d');
$loc->loc_bdp('domain d', 'context dp', 'text dp');
$loc->loc_bd('domain d', '((singular d|plural d))', 0);
$loc->loc_bdp('domain d', 'context dp', '((singular dp|plural dp))', 0);
$loc->loc_bc('text c', 'category c');
$loc->loc_bc('((singular c|plural c))', 'category c', 0);
$loc->loc_bcp('context cp', 'text cp', 'category c');
$loc->loc_bcp('context cp', '((singular cp|plural cp))', 'category c', 0);
$loc->loc_bdc('domain d', 'text dc', 'category c');
$loc->loc_bdc('domain d', '((singular dc|plural dc))', 'category c', 0);
$loc->loc_bdcp('domain d', 'context dcp', 'text dcp', 'category c');
$loc->loc_bdcp('domain d', 'context dcp', '((singular dcp|plural dcp))', 'category c', 0);

# preselect/unselect domain and/or category
$loc->loc_b('text of no domain and no category');
$loc->loc_begin_bd('domain d');
$loc->loc_b('text of domain d and no category');
$loc->loc_begin_bc('category c');
$loc->loc_b('text of domain d and category c');
$loc->loc_end_bd;
$loc->loc_b('text of no domain and category c');
$loc->loc_end_bc;
$loc->loc_b('text of no domain and no category');
$loc->loc_begin_bdc('domain d', 'category c');
$loc->loc_b('text of domain d and category c');
$loc->loc_end_bdc;
$loc->loc_b('text of no domain and no category');

# $Id: gettext_loc.pl 683 2017-08-22 18:41:42Z steffenw $

__END__

Output:

This is a text.
Steffen is programming Perl.
Singular
Plural
1 date
2 dates
date
1 date
date
dates
1 date
2 dates
date
date
