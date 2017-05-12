use Test::More;
use utf8;

BEGIN {
    use_ok 'Encode::Arabic::Franco';
}

my %samples = (
#    'wlqd zkrtk wlrma7 nwahl mny' => 'ولقد ذكرتك والرماح نواهل مني',
    'wsyf elhnd tq6r mn dmy' => 'وسيف الهند تقطر من دمي',
    'fwddt tqbyl elsyof le2anha' => 'فوددت تقبيل السيوف لأنها',
#    'lm3t kbarq th3\'rk elmotbsm' => 'لمعت كبارق ثغرك المتبسم',

#    'wlaqad zakrtok walrema7 nwahel meny' => 'ولقد ذكرتك والرماح نواهل مني',
#    'wasayf elhend taq6or men damy' => 'وسيف الهند تقطر من دمي',
#    'fawadadot taqbyl elsyoof l2nha' => 'فوددت تقبيل السيوف لأنها',
#    'lam3at kabareq tha3\'rek elmotabasem' => 'لمعت كبارق ثغرك المتبسم',
);

while (my ($franco, $arabic) = each %samples) {
    my $translit = decode 'franco-arabic', $franco;
    is $translit, $arabic, "decoding $franco";
}
done_testing;
