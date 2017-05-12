#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    language => 'i-default',
    plugins  => [ qw( Expand::Gettext::Loc ) ],
);

# Put all data for the translation into a structure
# and do not run the translation.
# That allows the extractor to find all the phrases.
my @extractable_data = (
    loc_ => [
        $loc->Nloc_(
            'This is a text.',
        )
    ],
    loc_x => [
        $loc->Nloc_x(
            '{name} is programming {language}.',
            name     => 'Steffen',
            language => 'Perl',
        )
    ],
    loc_n => [
        $loc->Nloc_n(
            'Singular',
            'Plural',
            1,
        )
    ],
    loc_nx => [
        $loc->Nloc_nx(
            '{num} shelf',
            '{num} shelves',
            1,
            num => 1,
        )
    ],
    loc_p => [
        $loc->Nloc_p(
            'maskulin',
            'Dear',
        )
    ],
    loc_px => [
        $loc->Nloc_px(
            'maskulin',
            'Dear {full name}',
            'full name' => 'Steffen Winkler',
        )
    ],
    loc_np => [
        $loc->Nloc_np(
            'appointment',
            'date',
            'dates',
            1,
        )
    ],
    loc_npx => [
        $loc->Nloc_npx(
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

# $Id: 15_gettext_Nloc_.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

loc_: This is a text.
loc_x: Steffen is programming Perl.
loc_n: Singular
loc_nx: 1 shelf
loc_p: Dear
loc_px: Dear Steffen Winkler
loc_np: date
loc_npx: 1 date
