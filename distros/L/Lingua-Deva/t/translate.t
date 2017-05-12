use v5.12.1;
use strict;
use warnings;
use utf8;
use Unicode::Normalize qw( NFD );

use Test::More tests => 4;

BEGIN { use_ok('Lingua::Deva') };

my $d = Lingua::Deva->new();
my ($latin, $deva) = ("Āśvalāyana Gṛhyasūtra\n", "आश्वलायन गृह्यसूत्र\n");

is( $d->to_deva($latin), $deva, 'translate to Devanagari string' );

# equivalent only when lowercasing and decomposing $latin
is( $d->to_latin($deva), NFD(lc $latin), 'convert to Latin transliteration' );

my $aksaras = $d->l_to_aksaras($latin);
is( $d->to_deva($aksaras), $deva, 'convert aksaras to Devanagari string' );
