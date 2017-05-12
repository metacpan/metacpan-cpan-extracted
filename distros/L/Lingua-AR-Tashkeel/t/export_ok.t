use Test::More;
use utf8;
use open qw(:std :utf8);
use Unicode::Normalize;

use Lingua::AR::Tashkeel qw(strip prune fix);

my %samples = (
    "ألف"    => 'ألف',
);

while (my ($in, $expected) = each %samples) {
    is NFD(strip $in), NFD($expected), "stripping $in";
    is NFD(prune $in), NFD($expected), "stripping $in";
    is NFD(fix   $in), NFD($expected), "stripping $in";
}
done_testing;

