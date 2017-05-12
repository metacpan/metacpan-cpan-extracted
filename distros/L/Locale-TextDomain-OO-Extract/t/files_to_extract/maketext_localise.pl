#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Maketext::Localise ) ],
);

# run all translations
() = print map {"$_\n"}
    $loc->localise(
        'This is a text.',
    ),
    $loc->localise(
        '[_1] is programming [_2].',
        'Steffen',
        'Perl',
    ),
    $loc->localise(
        '[quant,_1,date,dates]',
        1,
    ),
    $loc->localise(
        '[quant,_1,date,dates]',
        2,
    ),
    $loc->localise_mp(
        'appointment',
        'date',
    ),
    $loc->localise_mp(
        'appointment',
        '[*,_1,date,dates]',
        1,
    ),
    $loc->localise_mp(
        'appointment',
        '[*,_1,date,dates]',
        2,
    ),
    $loc->localise(
        '[*,_1,date,dates,no date]',
        0,
    ),
    $loc->localise(
        '[*,_1,date,dates,no date]',
        1,
    ),
    $loc->localise(
        '[*,_1,date,dates,no date]',
        2,
    );

# $Id: maketext_localise.pl 561 2014-11-11 16:12:48Z steffenw $

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
