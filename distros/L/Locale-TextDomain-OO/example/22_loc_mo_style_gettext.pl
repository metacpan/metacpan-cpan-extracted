#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;
use Locale::TextDomain::OO::Lexicon::File::MO;

our $VERSION = 0;

Locale::TextDomain::OO::Lexicon::File::MO
    ->new(
        logger => sub { () = print shift, "\n" },
    )
    ->lexicon_ref({
        search_dirs         => [ './LocaleData' ],
        gettext_to_maketext => 1,
        data                => [
            '*:LC_MESSAGES:example_maketext_style_gettext' => '*/LC_MESSAGES/example_maketext_style_gettext.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    category => 'LC_MESSAGES',
    domain   => 'example_maketext_style_gettext',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Maketext::Loc ) ],
);

# run all translations
() = print map {"$_\n"}
    $loc->loc(
        'This is a text.',
    ),
    $loc->loc(
        '§ book',
    ),
    $loc->loc(
        '[_1] is programming [_2].',
        'Steffen',
        'Perl',
    ),
    $loc->loc(
        '[quant,_1,shelf,shelves]',
        1,
    ),
    $loc->loc(
        '[quant,_1,shelf,shelves]',
        2,
    ),
    $loc->loc_mp(
        'maskulin',
        'Dear',
    ),
    $loc->loc_mp(
        'maskulin',
        'Dear [_1]',
        'Steffen Winkler',
    ),
    $loc->loc_mp(
        'appointment',
        'This is/are [*,_1,date,dates].',
        1,
    ),
    $loc->loc_mp(
        'appointment',
        'This is/are [*,_1,date,dates].',
        2,
    ),
    $loc->loc(
        '[*,_1,shelf,shelves,no shelf]',
        0,
    ),
    $loc->loc(
        '[*,_1,shelf,shelves,no shelf]',
        1,
    ),
    $loc->loc(
        '[*,_1,shelf,shelves,no shelf]',
        2,
    ),
    $loc->Nloc(
        'book',
    ),
    $loc->Nloc_mp(
        'appointment',
        'date',
    );


# $Id: 22_loc_mo_style_gettext.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

Lexicon "de:LC_MESSAGES:example_maketext_style_gettext" loaded from file "LocaleData/de/LC_MESSAGES\example_maketext_style_gettext.mo".
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
