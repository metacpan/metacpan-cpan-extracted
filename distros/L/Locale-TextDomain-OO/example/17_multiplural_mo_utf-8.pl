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
        decode      => 1, # from UTF-8, see header of po/mo file
        data        => [
            # File contains translations with 2 plural forms in 1 phrase.
            # Also there are the 3 plural forms for singular, plural and zero.
            # So it results in 9 msgstr_plural.
            'de:LC_MULTIPLURAL2:' => 'de/LC_MULTIPLURAL2/example_multiplural.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    category => 'LC_MULTIPLURAL2',
    logger   => sub { () = print shift, "\n" },
    plugins  => [ qw( Expand::Gettext ) ],
);

# all unicode chars encode to UTF-8
binmode STDOUT, ':encoding(utf-8)'
    or confess "Binmode STDOUT\n$OS_ERROR";

# run translations
for my $books ( 0 .. 2 ) {
    for my $shelves ( 0 .. 3 ) { ## no critic (MagicNumbers)
        () = print
            $loc->__nx(
                'There is {books :num} book and {shelves :num} shelve.',
                'There are {books :num} books and {shelves :num} shelves.',
                [ $books, $shelves ],
                books   => $books,
                shelves => $shelves,
            ),
            "\n";
    }
}

# $Id: 17_multiplural_mo_utf-8.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

Lexicon "de:LC_MULTIPLURAL2:" loaded from file "LocaleData/de/LC_MULTIPLURAL2/example_multiplural.mo".
Dort ist nichts.
Dort ist 1 Regal.
Dort sind 2 Regale.
Dort sind 3 Regale.
Dort ist 1 Buch.
Dort ist 1 Buch und 1 Regal.
Dort ist 1 Buch und 2 Regale.
Dort ist 1 Buch und 3 Regale.
Dort sind 2 Bücher.
Dort sind 2 Bücher und 1 Regal.
Dort sind 2 Bücher und 2 Regale.
Dort sind 2 Bücher und 3 Regale.
