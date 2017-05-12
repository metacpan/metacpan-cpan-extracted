#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;
use Carp qw(confess);
use English qw(-no_match_vars $OS_ERROR);
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::File::MO;

our $VERSION = 0;

Locale::TextDomain::OO::Lexicon::File::MO
    ->new(
        logger => sub { () = print shift, "\n" },
    )
    ->lexicon_ref({
        search_dirs => [ './LocaleData' ],
        decode      => 1, # from ISO-8859-1, see header of po/mo file
        data        => [
            # map category and domain to q{}
            '*::' => '*/LC_MESSAGES/example_maketext.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Maketext ) ],
);

# all unicode chars encode to UTF-8
binmode STDOUT, ':encoding(utf-8)'
    or confess "Binmode STDOUT\n$OS_ERROR";

# run all translations
() = print map {"$_\n"}
    $loc->maketext(
        'This is a text.',
    ),
    $loc->maketext(
        '§ book',
    ),
    $loc->maketext(
        '[_1] is programming [_2].',
        'Steffen',
        'Perl',
    ),
    $loc->maketext(
        '[quant,_1,shelf,shelves]',
        1,
    ),
    $loc->maketext(
        '[quant,_1,shelf,shelves]',
        2,
    ),
    $loc->maketext_p(
        'maskulin',
        'Dear',
    ),
    $loc->maketext_p(
        'maskulin',
        'Dear [_1]',
        'Steffen Winkler',
    ),
    $loc->maketext_p(
        'appointment',
        'This is/are [*,_1,date,dates].',
        1,
    ),
    $loc->maketext_p(
        'appointment',
        'This is/are [*,_1,date,dates].',
        2,
    ),
    $loc->maketext(
        '[*,_1,shelf,shelves,no shelf]',
        0,
    ),
    $loc->maketext(
        '[*,_1,shelf,shelves,no shelf]',
        1,
    ),
    $loc->maketext(
        '[*,_1,shelf,shelves,no shelf]',
        2,
    ),
    $loc->Nmaketext(
        'book',
    ),
    $loc->Nmaketext_p(
        'appointment',
        'date',
    );


# $Id: 21_maketext_mo_utf-8.pl 460 2014-01-06 22:09:01Z steffenw $

__END__

Output:

Lexicon "de::" loaded from file "LocaleData/de/LC_MESSAGES/example_maketext.mo".
Das ist ein Text.
§ Buch
Steffen programmiert Perl.
1 Regal
2 Regale
Sehr geehrter
Sehr geehrter Steffen Winkler
Das ist/sind 1 Date.
Das ist/sind 2 Dates.
kein Regal
1 Regal
2 Regale
book
appointment
date
