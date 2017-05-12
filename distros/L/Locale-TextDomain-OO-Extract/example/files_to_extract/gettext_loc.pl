#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Gettext ) ],
);

# run all translations
() = print map {"$_\n"}
    $loc->loc_(
        'This is a text.',
    ),
    $loc->loc_x(
        '{name} is programming {language}.',
        name     => 'Steffen',
        language => 'Perl',
    ),
    $loc->loc_n(
        'Singular',
        'Plural',
        1,
    ),
    $loc->loc_n(
        'Singular',
        'Plural',
        2,
    ),
    $loc->loc_nx(
        '{num} date',
        '{num} dates',
        1,
        num => 1,
    ),
    $loc->loc_nx(
        '{num} date',
        '{num} dates',
        2,
        num => 2,
    ),
    $loc->loc_p(
        'appointment',
        'date',
    ),
    $loc->loc_px(
        'appointment',
        '{num} date',
        num => 1,
    ),
    $loc->loc_np(
        'appointment',
        'date',
        'dates',
        1,
    ),
    $loc->loc_np(
        'appointment',
        'date',
        'dates',
        2,
    ),
    $loc->loc_npx(
        'appointment',
        '{num} date',
        '{num} dates',
        1,
        num => 1,
    ),
    $loc->loc_npx(
        'appointment',
        '{num} date',
        '{num} dates',
        2,
        num => 2,
    );

# Extract special stuff only
$loc->Nloc_(
    '\' quoted text with \\.',
);
$loc->Nloc_(
    q{q\{ quoted text with {placeholders\}}.},
);
$loc->Nloc_(
    q{quoted text.},
);

# with domain and/or category
$loc->loc_d('domain d', 'text d');
$loc->loc_dp('domain d', 'context dp', 'text dp');
$loc->loc_dn('domain d', 'singular dn', 'plural dn', 0);
$loc->loc_dnp('domain d', 'context dnp', 'singular dnp', 'plural dnp', 0);
$loc->loc_c('text c', 'category c');
$loc->loc_cn('singular cn', 'plural cn', 0, 'category c');
$loc->loc_cp('context cp', 'text cp', 'category c');
$loc->loc_cnp('context cnp', 'singular cnp', 'plural cnp', 0, 'category c');
$loc->loc_dc('domain d', 'text dc', 'category c');
$loc->loc_dcn('domain d', 'singular dcn', 'plural dcn', 0, 'category c');
$loc->loc_dcp('domain d', 'context dcp', 'text dcp', 'category c');
$loc->loc_dcnp('domain d', 'context dcnp', 'singular dcnp', 'plural dcnp', 0, 'category c');

# preselect/unselect domain and/or category
$loc->loc_('text of no domain and no category');
$loc->loc_begin_d('domain d');
$loc->loc_('text of domain d and no category');
$loc->loc_begin_c('category c');
$loc->loc_('text of domain d and category c');
$loc->loc_end_d;
$loc->loc_('text of no domain and category c');
$loc->loc_end_c;
$loc->loc_('text of no domain and no category');
$loc->loc_begin_dc('domain d', 'category c');
$loc->loc_('text of domain d and category c');
$loc->loc_end_dc;
$loc->loc_('text of no domain and no category');

# $Id: gettext_loc.pl 561 2014-11-11 16:12:48Z steffenw $

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
