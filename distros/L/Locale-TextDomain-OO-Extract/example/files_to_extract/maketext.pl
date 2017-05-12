#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Maketext ) ],
);

# run all translations
() = print map {"$_\n"}
    $loc->maketext(
        'This is a text.',
    ),
    $loc->maketext(
        '[_1] is programming [_2].',
        'Steffen',
        'Perl',
    ),
    $loc->maketext(
        '[quant,_1,date,dates]',
        1,
    ),
    $loc->maketext(
        '[quant,_1,date,dates]',
        2,
    ),
    $loc->maketext_p(
        'appointment',
        'date',
    ),
    $loc->maketext_p(
        'appointment',
        '[*,_1,date,dates]',
        1,
    ),
    $loc->maketext_p(
        'appointment',
        '[*,_1,date,dates]',
        2,
    ),
    $loc->maketext(
        '[*,_1,date,dates,no date]',
        0,
    ),
    $loc->maketext(
        '[*,_1,date,dates,no date]',
        1,
    ),
    $loc->maketext(
        '[*,_1,date,dates,no date]',
        2,
    );

# $Id: $

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
