use Test::More;
use utf8;

BEGIN {
    use_ok 'Encode::Arabic::Franco';
}

my %samples = (
    "alsma" => 'السما',
    "el5r6om" => 'الخرطوم',
    "3'rna6ah" => 'غرناطة',
    "3een" => 'عين',
    "2essrar" => 'إصرار',
    #"2owla" => 'أولى',
    "shawrmah" => 'شاورمة',
);

while (my ($franco, $arabic) = each %samples) {
    my $translit = decode 'franco-arabic', $franco;
    is $translit, $arabic, "decoding $franco";
}
done_testing;
