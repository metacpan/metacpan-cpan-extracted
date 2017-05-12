use Test::More;
use utf8;
use open qw(:std :utf8);

BEGIN {
    use_ok 'Lingua::AR::Tashkeel';
}

my @same =qw(ألف فجأة رأس تسأل مكافأة سأل نشأة مأمن تسائل تنشئين سئلت أئمة جزئية فئة بئر بمبادئك ائتمان خطيئة مئة السماء جزءان عباءة مؤمن مؤول رؤوس لؤلؤة خطؤهم تفاؤل مؤنث لؤي);
my %samples;

for my $word (@same) {
    my $transformed = Lingua::AR::Tashkeel::strip($word);
    is $transformed, $word;
}

while (my ($in, $expected) = each %samples) {
    my $transformed = Lingua::AR::Tashkeel::strip($in);
    is $transformed, $expected, "stripping $in";
}
done_testing;

