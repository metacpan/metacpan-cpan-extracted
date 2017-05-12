use v5.12.1;
use strict;
use warnings;
use utf8;

use Test::More tests => 9;

BEGIN { use_ok('Lingua::Deva') };
BEGIN { use_ok('Lingua::Deva::Aksara') };

my $d = Lingua::Deva->new();
my $text = 'ghrāṃ';
my $a = $d->l_to_aksaras($text)->[0];

ok( @{$a->onset()} && $a->vowel() && $a->final(), 'complete aksara' );

ok( $a->is_valid(), 'valid aksara');

is_deeply( $a->get_rhyme(), ["a\x{0304}", "m\x{0323}"],
           'rhyme of complete aksara' );

$text = 'dhvī';
$a = $d->l_to_aksaras($text)->[0];

ok( ! defined $a->final(), 'aksara with undefined fields' );

$text = 'str';
$a = $d->l_to_aksaras($text)->[0];

ok( ! defined $a->get_rhyme(), 'aksara with undefined rhyme' );

$a = Lingua::Deva::Aksara->new(
    onset => [ "c\x{0327}" ],
    vowel => "a",
    final => "m\x{0323}",
);

ok( ! $a->is_valid(), 'invalid aksara' );

# Check aksara with custom maps
my %c = %Lingua::Deva::Maps::Consonants;
$d = Lingua::Deva->new(
    C => do { $c{"c\x{0327}"} = delete $c{"s\x{0301}"}; \%c },
);

ok( $a->is_valid($d), 'aksara valid with customized maps' );
