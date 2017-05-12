use v5.12.1;
use strict;
use warnings;
use utf8;
use Unicode::Normalize qw( NFD );

use Test::More tests => 7;

BEGIN { use_ok('Lingua::Deva') };
BEGIN { use_ok('Lingua::Deva::Maps::ITRANS') };

my $d = Lingua::Deva->new(map => 'ISO15919');
is( $d->to_latin('कृणोमि'), 'kr̥ṇōmi', 'use alternative transliteration scheme');

my %v = %Lingua::Deva::Maps::ITRANS::Vowels;
my %d = %Lingua::Deva::Maps::ITRANS::Diacritics;
$d = Lingua::Deva->new(map => 'HK', V => \%v, D => \%d);
is( $d->to_deva('zuudra'), 'शूद्र', 'use alternative scheme with customizations' );

$d = Lingua::Deva->new(map => 'IAST', casesensitive => 1);
is( $d->to_deva('Śiva'), NFD('Śइव'), 'override default map case-sensitivity' );

{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    my %df = reverse %Lingua::Deva::Maps::ITRANS::Finals;
    $d = Lingua::Deva->new(
        map => 'BOGUS',
        DF   => do { $df{"\x{0902}"} = "MM"; \%df },
    );

    is( $warnings, 1, 'emit warning for invalid scheme' );

    is( $d->to_latin('वृत्रं'), 'vṛtraMM', 'fall back on default map for invalid scheme' );
}
