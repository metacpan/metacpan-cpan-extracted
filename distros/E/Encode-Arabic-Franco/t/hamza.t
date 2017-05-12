use Test::More;
use utf8;

BEGIN {
    use_ok 'Encode::Arabic::Franco';
}

my %samples = (
    '2alah'      => 'آلة',
    '2lef'       => 'ألف',
    'alef'       => 'ألف',
    'al2ethm'    => 'الإثم',
    'alf'        => 'ألف',
    'fg2ah'      => 'فجأة',
    'ra2eq'      => 'رائق',
    'ra2s'       => 'رأس',
    'ts2al'      => 'تسأل',
    'mkaf2ah'    => 'مكافأة',
    's2al'       => 'سأل',
    'nsh2ah'     => 'نشأة',
    'l2eem'      => 'لئيم',
    #'m2mn'      => 'مأمن',
    #'ma2mn'      => 'مأمن',
    #'tsa2l'      => 'تسائل',
    'tsa2al'     => 'تسائل',
    'tnshe2een'  => 'تنشئين',
    #'s2lt'       => 'سئلت',
    '22emah'     => 'أئمة',
    #'goz2yah'    => 'جزئية',
    #'gz2yah'    => 'جزئية',
    'fe2ah'      => 'فئة',
    'be2r'       => 'بئر',
    #'bembade2ek' => 'بمبادئك',
    #'2e2tman'    => 'ائتمان',
    #'5a6y2ah'    => 'خطيئة',
    '56y2ah'    => 'خطيئة',
    'me2ah'      => 'مئة',
    'alsma2'     => 'السماء',
    'gz2'        => 'جزء',
    #'goz2an'     => 'جزءان',
    #'3ba2ah'     => 'عباءة',
    'mo2men'     => 'مؤمن',
    #'ma2ool'     => 'مؤول',
    'm2ool'      => 'مؤول',
    'ro2oos'     => 'رؤوس',
    #'sba2'       => 'رؤوس',
    'lo2lo2ah'   => 'لؤلؤة',
    '562ohm'    => 'خطؤهم',
    #'5a62ohom'   => 'خطؤهم',
    'tfa2ol'     => 'تفاؤل',
    'mo2nth'     => 'مؤنث',
    'lo2y'       => 'لؤي',
    #'lo2ay'      => 'لؤي',
    'shy2'       => 'شيء',
    'b62'        => 'بطء',   
);

while (my ($franco, $arabic) = each %samples) {
    my $translit = decode 'franco-arabic', $franco;
    is $translit, $arabic, "decoding $franco";
}
done_testing;

