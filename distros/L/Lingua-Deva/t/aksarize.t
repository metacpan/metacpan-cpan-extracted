use v5.12.1;
use strict;
use warnings;
use utf8;
use charnames ':full';

use Test::More tests => 11;

BEGIN { use_ok('Lingua::Deva') };

# Tests for the aksarization methods

my $d = Lingua::Deva->new();
my $text;

# l_to_tokens()

my $tokens;

# String contains invalid tokens and unordered combining diacritics
$text = "Āśvalāyana 0\x{0301}q\tr\x{0304}\x{0323} Gṛhyasūtraṃ\n";
$tokens = $d->l_to_tokens($text);
is_deeply( $tokens,
           [ "A\x{0304}", "s\x{0301}", 'v', 'a', 'l', "a\x{0304}", 'y', 'a',
             'n', 'a', ' ', '0', "\x{0301}", 'q', "\t" , "r\x{0323}\x{0304}",
             ' ', 'G', "r\x{0323}", 'h', 'y', 'a', 's', "u\x{0304}", 't', 'r',
             'a', "m\x{0323}", "\n" ],
           'tokenize mixed string' );

$text = '';
$tokens = $d->l_to_tokens($text);
is( @$tokens, 0, 'tokenize empty string' );

$tokens = $d->l_to_tokens();
ok( !defined $tokens, 'tokenize undefined input' );

# l_to_aksaras()

my $aksaras;

my $input = "Āśvalāyana 0\x{0301}q\tr\x{0304}\x{0323} Gṛhyasūtraṃ\n";
$aksaras = $d->l_to_aksaras($input);
my @a = grep { ref($_) eq 'Lingua::Deva::Aksara' } @$aksaras;
is( @a, 10, 'aksarize mixed string, number of Aksaras' );

my @n = grep { ref($_) eq '' } @$aksaras;
is( @n, 7, 'aksarize mixed string, number of other tokens' );

$input = ['B', 'u', 'd', 'dh', 'a', "h\x{0323}"];
$aksaras = $d->l_to_aksaras($input);
@a = grep { ref($_) eq 'Lingua::Deva::Aksara' } @$aksaras;
is( @a, 2, 'aksarize array of tokens' );

{
    # Catch and count carp warnings emitted in strict mode
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };
    $input = "Āśvalāyana 0\x{0301}q\tr\x{0304}\x{0323} Gṛhyasūtraṃ\n";

    $d = Lingua::Deva->new( strict => 1 );
    $d->l_to_aksaras($input);
    is( $warnings, 3, 'aksarize mixed string in strict mode' );

    $warnings = 0;
    $d = Lingua::Deva->new( strict => 1, allow => ['q', '0'] );
    $d->l_to_aksaras($input);
    is( $warnings, 1, 'aksarize mixed string, strict mode with exceptions' );
}

# d_to_aksaras()

$d = Lingua::Deva->new();
$input = "आश्वलायन 0\x{0301}q\tॠ गृह्यसूत्रं\n";
$aksaras = $d->d_to_aksaras($input);
@a = grep { ref($_) eq 'Lingua::Deva::Aksara' } @$aksaras;
is( @a, 10, 'aksarize Devanagari string' );

{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    $d = Lingua::Deva->new( strict => 1, allow => ['q', '0'] );
    $d->d_to_aksaras($input);
    is( $warnings, 1, 'aksarize Devanagari string in strict mode' );
}
