use Test::More;
use utf8;

BEGIN {
    use_ok 'Encode::Arabic::Franco';
}

my %samples = (
    #'alef'       => 'ألف',
    'al2efk'     => 'الإفك',
    'al2ethm'    => 'الإثم',
);

while (my ($franco, $arabic) = each %samples) {
    my $translit = decode 'franco-arabic', $franco;
    is $translit, $arabic, "decoding $franco";
}
done_testing;


