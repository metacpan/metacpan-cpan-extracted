#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Maketext::Localize ) ],
);

# run all translations
() = print map {"$_\n"}
    $loc->localize(
        'This is a text.',
    ),
    $loc->localize(
        '[_1] is programming [_2].',
        'Steffen',
        'Perl',
    ),
    $loc->localize(
        '[quant,_1,date,dates]',
        1,
    ),
    $loc->localize(
        '[quant,_1,date,dates]',
        2,
    ),
    $loc->localize_mp(
        'appointment',
        'date',
    ),
    $loc->localize_mp(
        'appointment',
        '[*,_1,date,dates]',
        1,
    ),
    $loc->localize_mp(
        'appointment',
        '[*,_1,date,dates]',
        2,
    ),
    $loc->localize(
        '[*,_1,date,dates,no date]',
        0,
    ),
    $loc->localize(
        '[*,_1,date,dates,no date]',
        1,
    ),
    $loc->localize(
        '[*,_1,date,dates,no date]',
        2,
    );

# $Id: maketext_localize.pl 561 2014-11-11 16:12:48Z steffenw $

__END__

Output:

This is a text.
Steffen is programming Perl.
1 date
2 dates
date
1 date
2 dates
no date
1 date
2 dates
