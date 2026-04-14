use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Locale;

subtest 'english locales' => sub {
	is(EN_US, 'en_US', 'EN_US');
	is(EN_GB, 'en_GB', 'EN_GB');
	is(EN_AU, 'en_AU', 'EN_AU');
	is(EN_CA, 'en_CA', 'EN_CA');
	is(EN_IN, 'en_IN', 'EN_IN');
};

subtest 'western european locales' => sub {
	is(FR,    'fr',    'FR');
	is(FR_FR, 'fr_FR', 'FR_FR');
	is(DE,    'de',    'DE');
	is(DE_DE, 'de_DE', 'DE_DE');
	is(ES,    'es',    'ES');
	is(ES_ES, 'es_ES', 'ES_ES');
	is(ES_MX, 'es_MX', 'ES_MX');
	is(PT_BR, 'pt_BR', 'PT_BR');
	is(IT_IT, 'it_IT', 'IT_IT');
	is(NL_NL, 'nl_NL', 'NL_NL');
};

subtest 'nordic locales' => sub {
	is(SV_SE, 'sv_SE', 'SV_SE');
	is(DA_DK, 'da_DK', 'DA_DK');
	is(NO,    'no',    'NO');
	is(NB_NO, 'nb_NO', 'NB_NO');
	is(FI_FI, 'fi_FI', 'FI_FI');
	is(IS,    'is',    'IS');
	is(IS_IS, 'is_IS', 'IS_IS');
};

subtest 'eastern european locales' => sub {
	is(PL_PL, 'pl_PL', 'PL_PL');
	is(CS_CZ, 'cs_CZ', 'CS_CZ');
	is(RU_RU, 'ru_RU', 'RU_RU');
	is(UK_UA, 'uk_UA', 'UK_UA');
};

subtest 'east asian locales' => sub {
	is(ZH,    'zh',    'ZH');
	is(ZH_CN, 'zh_CN', 'ZH_CN');
	is(ZH_TW, 'zh_TW', 'ZH_TW');
	is(JA,    'ja',    'JA');
	is(JA_JP, 'ja_JP', 'JA_JP');
	is(KO,    'ko',    'KO');
	is(KO_KR, 'ko_KR', 'KO_KR');
};

subtest 'south asian locales' => sub {
	is(HI,    'hi',    'HI');
	is(HI_IN, 'hi_IN', 'HI_IN');
	is(BN,    'bn',    'BN');
	is(TA_IN, 'ta_IN', 'TA_IN');
	is(UR_PK, 'ur_PK', 'UR_PK');
};

subtest 'middle east locales' => sub {
	is(AR,    'ar',    'AR');
	is(AR_SA, 'ar_SA', 'AR_SA');
	is(FA_IR, 'fa_IR', 'FA_IR');
	is(HE_IL, 'he_IL', 'HE_IL');
};

subtest 'african locales' => sub {
	is(SW,    'sw',    'SW');
	is(SW_KE, 'sw_KE', 'SW_KE');
	is(AM_ET, 'am_ET', 'AM_ET');
	is(AF_ZA, 'af_ZA', 'AF_ZA');
};

subtest 'meta accessor' => sub {
	my $meta = Lang();
	ok($meta->count >= 150, 'at least 150 locale tags');
	ok($meta->valid('en_US'), 'en_US is valid');
	ok($meta->valid('ja_JP'), 'ja_JP is valid');
	ok(!$meta->valid('xx_XX'), 'xx_XX is not valid');
	is($meta->name('en_US'), 'EN_US', 'name of en_US is EN_US');
};

done_testing;
