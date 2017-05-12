use v5.12.1;
use strict;
use warnings;
use utf8;

use Test::More tests => 8;

BEGIN { use_ok('Lingua::Deva') };

my $d = Lingua::Deva->new();

# Example string contains invalid characters
my $text = "Āśvalāyana 0\x{0301}q\tr\x{0304}\x{0323} Gṛhyasūtraṃ\n";

my $tokens = $d->l_to_tokens($text);
ok( @$tokens, 'basic string tokenization' );

my $aksaras = $d->l_to_aksaras($tokens);
ok( @$aksaras, 'basic aksarization of an array of tokens' );

is_deeply( $aksaras, $d->l_to_aksaras($text),
    'equivalent aksarization of string and token array' );

my $deva = $d->to_deva($aksaras);
ok( length $deva, 'basic translation to Devanagari' );

$text = "आश्वलायन 0\x{0301}q\tॠ गृह्यसूत्रं\n";

$aksaras = $d->d_to_aksaras($text);
ok( @$aksaras, 'basic aksarization of a Devanagari string' );

my $latin = $d->to_latin($aksaras);
ok( length $latin, 'basic Latin transliteration' );

my %c = %Lingua::Deva::Maps::Consonants;
$c{"c\x{0327}"} = delete $c{"s\x{0301}"}; # custom map
$d = Lingua::Deva->new( C => \%c );
is( $d->to_deva('paçyema'), 'पश्येम', 'translation to Devanagari, custom map' );
