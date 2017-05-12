use Test::More tests => 4;

use HTML::Strip;
use FindBin qw/$Bin/;

use Encode qw/decode/;

my @test_strings = (
    [ "<p>\xf8</p>" => "\xf8" ], 
    [ "<p>\xe6</p>" => "\xe6" ],
);
my $hs = HTML::Strip->new(auto_reset => 1);

for my $test (@test_strings) {
    my ($string, $expected) = @$test;
    is( $hs->parse($string), $expected, "parse latin1 string $string" );
    my $decoded = decode('latin1', $string);
    is( $hs->parse($decoded), decode('latin1', $expected), "parse decoded string $decoded" );
}
