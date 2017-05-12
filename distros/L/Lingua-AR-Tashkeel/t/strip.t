use Test::More;
use utf8;
use open qw(:std :utf8);
use Unicode::Normalize;

BEGIN {
    use_ok 'Lingua::AR::Tashkeel';
}

my %samples = (
    "مَكَرُونَة" => 'مكرونة',
    "فَتَّة"    => 'فتة',
    "ماحشي"  => 'ماحشي',
    "ألف"    => 'ألف',
);

while (my ($in, $expected) = each %samples) {
    my $transformed = Lingua::AR::Tashkeel::strip($in);
    is NFD($transformed), NFD($expected), "stripping $in";
}
done_testing;
