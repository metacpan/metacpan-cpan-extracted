#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    language => 'i-default',
    plugins  => [ qw( Expand::Gettext ) ],
);

# Put all data for the translation into a structure
# and do not run the translation.
# That allows the extractor to find all the phrases.
my @extractable_data = (
    __ => [
        $loc->N__(
            'This is a text.',
        )
    ],
    __x => [
        $loc->N__x(
            '{name} is programming {language}.',
            name     => 'Steffen',
            language => 'Perl',
        )
    ],
    __n => [
        $loc->N__n(
            'Singular',
            'Plural',
            1,
        )
    ],
    __nx => [
        $loc->N__nx(
            '{num} shelf',
            '{num} shelves',
            1,
            num => 1,
        )
    ],
    __p => [
        $loc->N__p(
            'maskulin',
            'Dear',
        )
    ],
    __px => [
        $loc->N__px(
            'maskulin',
            'Dear {full name}',
            'full name' => 'Steffen Winkler',
        )
    ],
    __np => [
        $loc->N__np(
            'appointment',
            'date',
            'dates',
            1,
        )
    ],
    __npx => [
        $loc->N__npx(
            'appointment',
            '{num} date',
            '{num} dates',
            1,
            num => 1,
        )
    ],
);

# Do any complex things and run the translations later.
while ( my ($method_name, $array_ref) = splice @extractable_data, 0, 2 ) {
    () = print
        $method_name,
        ': ',
        $loc->$method_name( @{$array_ref} ),
        "\n";
}

# $Id: 15_gettext_N__.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

__: This is a text.
__x: Steffen is programming Perl.
__n: Singular
__nx: 1 shelf
__p: Dear
__px: Dear Steffen Winkler
__np: date
__npx: 1 date
