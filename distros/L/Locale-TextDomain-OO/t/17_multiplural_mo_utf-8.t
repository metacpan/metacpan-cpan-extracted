#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 12;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::MO');
}

Locale::TextDomain::OO::Lexicon::File::MO
    ->new(
        logger => sub { note shift },
    )
    ->lexicon_ref({
        search_dirs => [ './t/LocaleData' ],
        decode      => 1,
        data        => [
            # File contains translations with 2 plural forms in 1 phrase.
            # Also there are the 3 plural forms for singular, plural and zero.
            # So it results in 9 msgstr_plural.
            'de:LC_MULTIPLURAL2:' => 'de/LC_MULTIPLURAL2/test_multiplural.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    category => 'LC_MULTIPLURAL2',
    plugins  => [ qw( Expand::Gettext ) ],
    logger   => sub { note shift },
);

my @data = (
    0, 0, 'Dort ist nichts.',
    0, 1, 'Dort ist 1 Regal.',
    0, 2, 'Dort sind 2 Regale.',
    1, 0, 'Dort ist 1 Buch.',
    1, 1, 'Dort ist 1 Buch und 1 Regal.',
    1, 2, 'Dort ist 1 Buch und 2 Regale.',
    2, 0, 'Dort sind 2 Bücher.',
    2, 1, 'Dort sind 2 Bücher und 1 Regal.',
    2, 2, 'Dort sind 2 Bücher und 2 Regale.',
);
while ( my ( $books, $shelves, $expected ) = splice @data, 0, 3 ) {
    is
        $loc->__nx(
            'There is {books :num} book and {shelves :num} shelve.',
            'There are {books :num} books and {shelves :num} shelves.',
            [ $books, $shelves ],
            books   => $books,
            shelves => $shelves,
        ),
        $expected,
        "books=$books, shelves=$shelves";
}
