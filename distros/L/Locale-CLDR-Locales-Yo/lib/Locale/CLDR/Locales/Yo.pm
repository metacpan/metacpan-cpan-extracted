=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Yo - Package for language Yoruba

=cut

package Locale::CLDR::Locales::Yo;
# This file auto generated from Data\common\main\yo.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ab' => 'Èdè Abasia',
 				'ace' => 'Èdè Akinisi',
 				'ada' => 'Èdè Adame',
 				'ady' => 'Èdè Adiji',
 				'af' => 'Èdè Afrikani',
 				'agq' => 'Èdè Ágẹ̀ẹ̀mù',
 				'ain' => 'Èdè Ainu',
 				'ak' => 'Èdè Akani',
 				'ale' => 'Èdè Aleti',
 				'alt' => 'Èdè Gusu Ata',
 				'am' => 'Èdè Amariki',
 				'an' => 'Èdè Aragoni',
 				'ann' => 'Èdè Obolo',
 				'anp' => 'Èdè Angika',
 				'ar' => 'Èdè Árábìkì',
 				'arn' => 'Èdè Mapushe',
 				'arp' => 'Èdè Arapaho',
 				'ars' => 'Èdè Arabiki ti Najidi',
 				'as' => 'Èdè Ti Assam',
 				'asa' => 'Èdè Asu',
 				'ast' => 'Èdè Asturian',
 				'atj' => 'Èdè Atikameki',
 				'av' => 'Èdè Afariki',
 				'awa' => 'Èdè Awadi',
 				'ay' => 'Èdè Amara',
 				'az' => 'Èdè Azerbaijani',
 				'ba' => 'Èdè Bashiri',
 				'ban' => 'Èdè Balini',
 				'bas' => 'Èdè Basaa',
 				'be' => 'Èdè Belarusi',
 				'bem' => 'Èdè Béḿbà',
 				'bez' => 'Èdè Bẹ́nà',
 				'bg' => 'Èdè Bugaria',
 				'bgc' => 'Èdè Haryanvi',
 				'bho' => 'Èdè Bojuri',
 				'bi' => 'Èdè Bisilama',
 				'bin' => 'Èdè Bini',
 				'bla' => 'Èdè Sikiska',
 				'bm' => 'Èdè Báḿbàrà',
 				'bn' => 'Èdè Bengali',
 				'bo' => 'Tibetán',
 				'br' => 'Èdè Bretoni',
 				'brx' => 'Èdè Bódò',
 				'bs' => 'Èdè Bosnia',
 				'bug' => 'Èdè Bugini',
 				'byn' => 'Èdè Bilini',
 				'ca' => 'Èdè Catala',
 				'cay' => 'Èdè Kayuga',
 				'ccp' => 'Èdè Chakma',
 				'ce' => 'Èdè Chechen',
 				'ceb' => 'Èdè Cebuano',
 				'cgg' => 'Èdè Chiga',
 				'ch' => 'Èdè S̩amoro',
 				'chk' => 'Èdè Shuki',
 				'chm' => 'Èdè Mari',
 				'cho' => 'Èdè Shokita',
 				'chp' => 'Èdè Shipewa',
 				'chr' => 'Èdè Shẹ́rókiì',
 				'chy' => 'Èdè Sheyeni',
 				'ckb' => 'Ààrin Gbùngbùn Kurdish',
 				'clc' => 'Èdè Shikoti',
 				'co' => 'Èdè Corsican',
 				'crg' => 'Èdè Misifu',
 				'crj' => 'Èdè Gusu Ila-oorun Kri',
 				'crk' => 'Èdè Papa Kri',
 				'crl' => 'Èdè ti Ila oorun Ariwa Kri',
 				'crm' => 'Èdè Moose Kri',
 				'crr' => 'Èdè Alonkuia ti Karolina',
 				'cs' => 'Èdè Seeki',
 				'csw' => 'Èdè Swampi Kri',
 				'cu' => 'Èdè Síláfííkì Ilé Ìjọ́sìn',
 				'cv' => 'Èdè Shufasi',
 				'cy' => 'Èdè Welshi',
 				'da' => 'Èdè Ilẹ̀ Denmark',
 				'dak' => 'Èdè Dakota',
 				'dar' => 'Èdè Dagiwa',
 				'dav' => 'Táítà',
 				'de' => 'Èdè Jámánì',
 				'de_AT' => 'Èdè Jámánì (Ọ́síríà )',
 				'de_CH' => 'Èdè Ilẹ̀ Jámánì (Orílẹ́ède swítsàlandì)',
 				'dgr' => 'Èdè Dogribu',
 				'dje' => 'Ṣárúmà',
 				'doi' => 'Èdè Dogiri',
 				'dsb' => 'Ṣóbíánù Apá Ìṣàlẹ̀',
 				'dua' => 'Èdè Duala',
 				'dv' => 'Èdè Difehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Èdè Dzongkha',
 				'dzg' => 'Èdè Dasaga',
 				'ebu' => 'Èdè Ẹmbù',
 				'ee' => 'Èdè Ewè',
 				'efi' => 'Èdè Efiki',
 				'eka' => 'Èdè Ekaju',
 				'el' => 'Èdè Giriki',
 				'en' => 'Èdè Gẹ̀ẹ́sì',
 				'en_AU' => 'Èdè Gẹ̀ẹ́sì (órílẹ̀-èdè Ọsirélíà)',
 				'en_CA' => 'Èdè Gẹ̀ẹ́sì (Orílẹ̀-èdè Kánádà)',
 				'en_GB' => 'Èdè òyìnbó Gẹ̀ẹ́sì',
 				'en_GB@alt=short' => 'Èdè Gẹ̀ẹ́sì (GB)',
 				'en_US@alt=short' => 'Èdè Gẹ̀ẹ́sì (US)',
 				'eo' => 'Èdè Esperanto',
 				'es' => 'Èdè Sípáníìṣì',
 				'es_419' => 'Èdè Sípáníìṣì (orílẹ̀-èdè Látìn-Amẹ́ríkà)',
 				'es_ES' => 'Èdè Sípáníìṣì (orílẹ̀-èdè Yúróòpù)',
 				'es_MX' => 'Èdè Sípáníìṣì (orílẹ̀-èdè Mẹ́síkò)',
 				'et' => 'Èdè Estonia',
 				'eu' => 'Èdè Baski',
 				'ewo' => 'Èdè Èwóǹdò',
 				'fa' => 'Èdè Pasia',
 				'ff' => 'Èdè Fúlàní',
 				'fi' => 'Èdè Finisi',
 				'fil' => 'Èdè Filipino',
 				'fj' => 'Èdè Fiji',
 				'fo' => 'Èdè Faroesi',
 				'fon' => 'Èdè Fon',
 				'fr' => 'Èdè Faransé',
 				'fr_CA' => 'Èdè Faransé (orílẹ̀-èdè Kánádà)',
 				'fr_CH' => 'Èdè Faranṣé (Súwísàlaǹdì)',
 				'frc' => 'Èdè Faranse ti Kajun',
 				'frr' => 'Èdè Ariwa Frisa',
 				'fur' => 'Firiúlíànì',
 				'fy' => 'Èdè Frisia',
 				'ga' => 'Èdè Ireland',
 				'gaa' => 'Èdè Gaa',
 				'gd' => 'Èdè Gaelik ti Ilu Scotland',
 				'gez' => 'Ede Gẹ́sì',
 				'gil' => 'Èdè Gibaati',
 				'gl' => 'Èdè Galicia',
 				'gn' => 'Èdè Guarani',
 				'gor' => 'Èdè Gorontalo',
 				'gsw' => 'Súwísì ti Jámánì',
 				'gu' => 'Èdè Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Máǹkì',
 				'gwi' => 'Èdè giwisi',
 				'ha' => 'Èdè Hausa',
 				'hai' => 'Èdè Haida',
 				'haw' => 'Hawaiian',
 				'hax' => 'Èdè Gusu Haida',
 				'he' => 'Èdè Heberu',
 				'hi' => 'Èdè Híńdì',
 				'hi_Latn' => 'Èdè Híndì (Látìnì)',
 				'hi_Latn@alt=variant' => 'Èdè Híńgílíṣì',
 				'hil' => 'Èdè Hilgayo',
 				'hmn' => 'Hmong',
 				'hr' => 'Èdè Kroatia',
 				'hsb' => 'Sorbian Apá Òkè',
 				'ht' => 'Haitian Creole',
 				'hu' => 'Èdè Hungaria',
 				'hup' => 'Èdè Hupa',
 				'hur' => 'Èdè Hakomelemi',
 				'hy' => 'Èdè Ile Armenia',
 				'hz' => 'Èdè Herero',
 				'ia' => 'Èdè pipo',
 				'iba' => 'Èdè Iba',
 				'ibb' => 'Èdè Ibibio',
 				'id' => 'Èdè Indonéṣíà',
 				'ie' => 'Iru Èdè',
 				'ig' => 'Èdè Yíbò',
 				'ii' => 'Ṣíkuán Yì',
 				'ikt' => 'Èdè Iwoorun Inutitu ti Kanada',
 				'ilo' => 'Èdè Iloko',
 				'inh' => 'Èdè Ingusi',
 				'io' => 'Èdè Ido',
 				'is' => 'Èdè Icelandic',
 				'it' => 'Èdè Ítálì',
 				'iu' => 'Èdè Inukitu',
 				'ja' => 'Èdè Jàpáànù',
 				'jbo' => 'Èdè Lobani',
 				'jgo' => 'Ńgòmbà',
 				'jmc' => 'Máṣámè',
 				'jv' => 'Èdè Javanasi',
 				'ka' => 'Èdè Georgia',
 				'kab' => 'Kabilè',
 				'kac' => 'Èdè Kashini',
 				'kaj' => 'Èdè Ju',
 				'kam' => 'Káńbà',
 				'kbd' => 'Èdè Kabadia',
 				'kcg' => 'Èdè Tiyapu',
 				'kde' => 'Mákondé',
 				'kea' => 'Kabufadíánù',
 				'kfo' => 'Èdè Koro',
 				'kgp' => 'Èdè Kaigani',
 				'kha' => 'Èdè Kasi',
 				'khq' => 'Koira Ṣíínì',
 				'ki' => 'Kíkúyù',
 				'kj' => 'Èdè Kuayama',
 				'kk' => 'Kaṣakì',
 				'kkj' => 'Kàkó',
 				'kl' => 'Kalaalísùtì',
 				'kln' => 'Kálẹnjín',
 				'km' => 'Èdè kameri',
 				'kmb' => 'Èdè Kimbundu',
 				'kn' => 'Èdè Kannada',
 				'ko' => 'Èdè Kòríà',
 				'kok' => 'Kónkánì',
 				'kpe' => 'Èdè Pele',
 				'kr' => 'Èdè Kanuri',
 				'krc' => 'Èdè Karasha-Baka',
 				'krl' => 'Èdè Karelia',
 				'kru' => 'Èdè Kuruki',
 				'ks' => 'Kaṣímirì',
 				'ksb' => 'Ṣáńbálà',
 				'ksf' => 'Èdè Báfíà',
 				'ksh' => 'Èdè Colognian',
 				'ku' => 'Kọdiṣì',
 				'kum' => 'Èdè Kumiki',
 				'kv' => 'Èdè Komi',
 				'kw' => 'Èdè Kọ́nììṣì',
 				'kwk' => 'Èdè Kwawala',
 				'ky' => 'Kírígíìsì',
 				'la' => 'Èdè Latini',
 				'lad' => 'Èdè Ladino',
 				'lag' => 'Láńgì',
 				'lb' => 'Lùṣẹ́mbọ́ọ̀gì',
 				'lez' => 'Èdè Lesgina',
 				'lg' => 'Ganda',
 				'li' => 'Èdè Limbogishi',
 				'lil' => 'Èdè Liloeti',
 				'lkt' => 'Lákota',
 				'ln' => 'Lìǹgálà',
 				'lo' => 'Láò',
 				'lou' => 'Èdè Kreoli ti Louisiana',
 				'loz' => 'Èdè Lozi',
 				'lrc' => 'Apáàríwá Lúrì',
 				'lsm' => 'Èdè Samia',
 				'lt' => 'Èdè Lithuania',
 				'lu' => 'Lúbà-Katanga',
 				'lua' => 'Èdè Luba Lulua',
 				'lun' => 'Èdè Lunda',
 				'lus' => 'Èdè Miso',
 				'luy' => 'Luyíà',
 				'lv' => 'Èdè Latvianu',
 				'mad' => 'Èdè Maduri',
 				'mag' => 'Èdè Magahi',
 				'mai' => 'Èdè Matihi',
 				'mak' => 'Èdè Makasa',
 				'mas' => 'Másáì',
 				'mdf' => 'Èdè Mokisa',
 				'men' => 'Èdè Mende',
 				'mer' => 'Mérù',
 				'mfe' => 'Morisiyen',
 				'mg' => 'Malagasì',
 				'mgh' => 'Makhuwa-Meeto',
 				'mgo' => 'Métà',
 				'mh' => 'Èdè Mashali',
 				'mi' => 'Màórì',
 				'mic' => 'Èdè Mikmaki',
 				'min' => 'Èdè Minakabau',
 				'mk' => 'Èdè Macedonia',
 				'ml' => 'Málàyálámù',
 				'mn' => 'Mòngólíà',
 				'mni' => 'Èdè Manipuri',
 				'moe' => 'Èdè Inuamu',
 				'moh' => 'Èdè Mohaki',
 				'mos' => 'Èdè Mosi',
 				'mr' => 'Èdè marathi',
 				'ms' => 'Èdè Malaya',
 				'mt' => 'Èdè Malta',
 				'mua' => 'Múndàngì',
 				'mul' => 'Ọlọ́pọ̀ èdè',
 				'mus' => 'Èdè Muskogi',
 				'mwl' => 'Èdè Mirandisi',
 				'my' => 'Èdè Bumiisi',
 				'myv' => 'Èdè Esiya',
 				'mzn' => 'Masanderani',
 				'na' => 'Èdè Nauru',
 				'nap' => 'Èdè Neapolita',
 				'naq' => 'Námà',
 				'nb' => 'Nọ́ọ́wè Bokímàl',
 				'nd' => 'Àríwá Ndebele',
 				'nds' => 'Jámánì ìpìlẹ̀',
 				'ne' => 'Èdè Nepali',
 				'new' => 'Èdè Newari',
 				'ng' => 'Èdè Ndonga',
 				'nia' => 'Èdè Nia',
 				'niu' => 'Èdè Niu',
 				'nl' => 'Èdè Dọ́ọ̀ṣì',
 				'nmg' => 'Kíwáṣíò',
 				'nn' => 'Nọ́ọ́wè Nínọ̀sìkì',
 				'nnh' => 'Ngiembùnù',
 				'no' => 'Èdè Norway',
 				'nog' => 'Èdè Nogai',
 				'nqo' => 'Èdè Nko',
 				'nr' => 'Èdè Gusu Ndebele',
 				'nso' => 'Èdè Ariwa Soto',
 				'nus' => 'Núẹ̀',
 				'nv' => 'Èdè Nafajo',
 				'ny' => 'Ńyájà',
 				'nyn' => 'Ńyákọ́lè',
 				'oc' => 'Èdè Occitani',
 				'ojb' => 'Èdè Ariwa-iwoorun Ojibwa',
 				'ojc' => 'Èdè Ojibwa Aarin',
 				'ojs' => 'Èdè Oji Kri',
 				'ojw' => 'Èdè Iwoorun Ojibwa',
 				'oka' => 'Èdè Okanaga',
 				'om' => 'Òròmọ́',
 				'or' => 'Òdíà',
 				'os' => 'Ọṣẹ́tíìkì',
 				'pa' => 'Èdè Punjabi',
 				'pag' => 'Èdè Pangasina',
 				'pam' => 'Èdè Pampanga',
 				'pap' => 'Èdè Papiamento',
 				'pau' => 'Èdè Pala',
 				'pcm' => 'Èdè Pijini ti Naijiriya',
 				'pis' => 'Èdè Piji',
 				'pl' => 'Èdè Póláǹdì',
 				'pqm' => 'Èdè Maliseti-Pasamkodi',
 				'prg' => 'Púrúṣíànù',
 				'ps' => 'Páshítò',
 				'pt' => 'Èdè Pọtogí',
 				'pt_BR' => 'Èdè Pọtogí (Orilẹ̀-èdè Bràsíl)',
 				'pt_PT' => 'Èdè Pọtogí (orílẹ̀-èdè Yúróòpù)',
 				'qu' => 'Kúẹ́ńjùà',
 				'rap' => 'Èdè Rapanu',
 				'rar' => 'Èdè Rarotonga',
 				'rhg' => 'Èdè Rohinga',
 				'rm' => 'Rómáǹṣì',
 				'rn' => 'Rúńdì',
 				'ro' => 'Èdè Romania',
 				'rof' => 'Róńbò',
 				'ru' => 'Èdè Rọ́ṣíà',
 				'rup' => 'Èdè Aromani',
 				'rw' => 'Èdè Ruwanda',
 				'rwk' => 'Riwa',
 				'sa' => 'Èdè awon ara Indo',
 				'sad' => 'Èdè Sandawe',
 				'sah' => 'Sàkíhà',
 				'saq' => 'Samburu',
 				'sat' => 'Èdè Santali',
 				'sba' => 'Èdè Ngambayi',
 				'sbp' => 'Sangu',
 				'sc' => 'Èdè Sadini',
 				'scn' => 'Èdè Sikila',
 				'sco' => 'Èdè Sikoti',
 				'sd' => 'Èdè Sindhi',
 				'se' => 'Apáàríwá Sami',
 				'seh' => 'Ṣẹnà',
 				'ses' => 'Koiraboro Seni',
 				'sg' => 'Sango',
 				'sh' => 'Èdè Serbo-Croatiani',
 				'shi' => 'Taṣelíìtì',
 				'shn' => 'Èdè Shani',
 				'si' => 'Èdè Sinhalese',
 				'sk' => 'Èdè Slovaki',
 				'sl' => 'Èdè Slovenia',
 				'slh' => 'Èdè Gusu Lushootseed',
 				'sm' => 'Sámóánù',
 				'smn' => 'Inari Sami',
 				'sms' => 'Èdè Sikoti Smi',
 				'sn' => 'Ṣọnà',
 				'snk' => 'Èdè Sonike',
 				'so' => 'Èdè ara Somalia',
 				'sq' => 'Èdè Albania',
 				'sr' => 'Èdè Serbia',
 				'srn' => 'Èdè Sirana Tongo',
 				'ss' => 'Èdè Suwati',
 				'st' => 'Èdè Sesoto',
 				'str' => 'Èdè Sitirati Salisi',
 				'su' => 'Èdè Sudanísì',
 				'suk' => 'Èdè Sukuma',
 				'sv' => 'Èdè Suwidiisi',
 				'sw' => 'Èdè Swahili',
 				'swb' => 'Èdè Komora',
 				'syr' => 'Èdè Siriaki',
 				'ta' => 'Èdè Tamili',
 				'tce' => 'Èdè Gusu Tushoni',
 				'te' => 'Èdè Telugu',
 				'tem' => 'Èdè Timne',
 				'teo' => 'Tẹ́sò',
 				'tet' => 'Èdè Tetum',
 				'tg' => 'Tàjíìkì',
 				'tgx' => 'Èdè Tagisi',
 				'th' => 'Èdè Tai',
 				'tht' => 'Èdè Tajiti',
 				'ti' => 'Èdè Tigrinya',
 				'tig' => 'Èdè Tigre',
 				'tk' => 'Èdè Turkmen',
 				'tlh' => 'Èdè Klingoni',
 				'tli' => 'Èdè Tlingiti',
 				'tn' => 'Èdè Suwana',
 				'to' => 'Tóńgàn',
 				'tok' => 'Èdè Toki Pona',
 				'tpi' => 'Èdè Tok Pisini',
 				'tr' => 'Èdè Tọọkisi',
 				'trv' => 'Èdè Taroko',
 				'ts' => 'Èdè Songa',
 				'tt' => 'Tatarí',
 				'ttm' => 'Èdè Ariwa Tusoni',
 				'tum' => 'Èdè Tumbuka',
 				'tvl' => 'Èdè Tifalu',
 				'twq' => 'Tasawak',
 				'ty' => 'Èdè Tahiti',
 				'tyv' => 'Èdè Tuvini',
 				'tzm' => 'Ààrin Gbùngbùn Atlas Tamazight',
 				'udm' => 'Èdè Udmuti',
 				'ug' => 'Yúgọ̀',
 				'uk' => 'Èdè Ukania',
 				'umb' => 'Èdè Umbundu',
 				'und' => 'Èdè àìmọ̀',
 				'ur' => 'Èdè Udu',
 				'uz' => 'Èdè Uzbek',
 				've' => 'Èdè Fenda',
 				'vi' => 'Èdè Jetinamu',
 				'vo' => 'Fọ́lápùùkù',
 				'vun' => 'Funjo',
 				'wa' => 'Èdè Waluni',
 				'wae' => 'Wọsà',
 				'wal' => 'Èdè Wolata',
 				'war' => 'Èdè Wara',
 				'wo' => 'Wọ́lọ́ọ̀fù',
 				'wuu' => 'Èdè Wu ti Saina',
 				'xal' => 'Èdè Kalimi',
 				'xh' => 'Èdè Xhosa',
 				'xog' => 'Ṣógà',
 				'yav' => 'Yangbẹn',
 				'ybb' => 'Èdè Yemba',
 				'yi' => 'Èdè Yiddishi',
 				'yo' => 'Èdè Yorùbá',
 				'yrl' => 'Èdè Ningatu',
 				'yue' => 'Èdè Cantonese',
 				'zgh' => 'Àfẹnùkò Támásáìtì ti Mòrókò',
 				'zh' => 'Edè Ṣáínà',
 				'zh@alt=menu' => 'Edè Ṣáínà, Mandárínì',
 				'zh_Hans' => 'Ẹdè Ṣáínà Onírọ̀rùn',
 				'zh_Hans@alt=long' => 'Èdè Mandárínì Ṣáínà Onírọ̀rùn',
 				'zh_Hant' => 'Èdè Ṣáínà Ìbílẹ̀',
 				'zh_Hant@alt=long' => 'Èdè Mandárínì Ṣáínà Ìbílẹ̀',
 				'zu' => 'Èdè Ṣulu',
 				'zun' => 'Èdè Suni',
 				'zxx' => 'Kò sí àkóònú elédè',
 				'zza' => 'Èdè Sasa',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Adlm' => 'Èdè Adam',
 			'Arab' => 'èdè Lárúbáwá',
 			'Aran' => 'Èdè Aran',
 			'Armn' => 'Àmẹ́níà',
 			'Beng' => 'Báńgílà',
 			'Bopo' => 'Bopomófò',
 			'Brai' => 'Bíráìlè',
 			'Cakm' => 'Kami',
 			'Cans' => 'Èdè Apapo Onile Onisilebu ti Kanada',
 			'Cher' => 'Èdè Sheroki',
 			'Cyrl' => 'èdè ilẹ̀ Rọ́ṣíà',
 			'Deva' => 'Dẹfanagárì',
 			'Ethi' => 'Ẹtiópíìkì',
 			'Geor' => 'Jọ́jíànù',
 			'Grek' => 'Jọ́jíà',
 			'Gujr' => 'Gujaráti',
 			'Guru' => 'Gurumúkhì',
 			'Hanb' => 'Han pẹ̀lú Bopomófò',
 			'Hang' => 'Háńgùlù',
 			'Hani' => 'Háànù',
 			'Hans' => 'tí wọ́n mú rọrùn.',
 			'Hans@alt=stand-alone' => 'Hans tí wọ́n mú rọrùn.',
 			'Hant' => 'Hans àtọwọ́dọ́wọ́',
 			'Hebr' => 'Hébérù',
 			'Hira' => 'Hiragánà',
 			'Hrkt' => 'ìlànà àfọwọ́kọ ará Jàpánù',
 			'Jpan' => 'èdè jàpáànù',
 			'Kana' => 'Katakánà',
 			'Khmr' => 'Kẹmẹ̀',
 			'Knda' => 'Kanada',
 			'Kore' => 'Kóríà',
 			'Laoo' => 'Láò',
 			'Latn' => 'Èdè Látìn',
 			'Mlym' => 'Málàyálámù',
 			'Mong' => 'Mòngólíà',
 			'Mtei' => 'Èdè Meitei Mayeki',
 			'Mymr' => 'Myánmarà',
 			'Nkoo' => 'Èdè Nkoo',
 			'Olck' => 'Èdè Ol Siki',
 			'Orya' => 'Òdíà',
 			'Rohg' => 'Èdè Hanifi',
 			'Sinh' => 'Sìnhálà',
 			'Sund' => 'Èdè Sundani',
 			'Syrc' => 'Èdè Siriaki',
 			'Taml' => 'Támílì',
 			'Telu' => 'Télúgù',
 			'Tfng' => 'Èdè Tifina',
 			'Thaa' => 'Taana',
 			'Tibt' => 'Tíbétán',
 			'Vaii' => 'Èdè Fai',
 			'Yiii' => 'Èdè Yi',
 			'Zmth' => 'Àmì Ìṣèsìrò',
 			'Zsye' => 'Émójì',
 			'Zsym' => 'Àwọn àmì',
 			'Zxxx' => 'Aikọsilẹ',
 			'Zyyy' => 'Wọ́pọ̀',
 			'Zzzz' => 'Ìṣọwọ́kọ̀wé àìmọ̀',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'Agbáyé',
 			'002' => 'Áfíríkà',
 			'003' => 'Àríwá Amẹ́ríkà',
 			'005' => 'Gúúṣù Amẹ́ríkà',
 			'009' => 'Òsọ́ọ́níà',
 			'011' => 'Ìwọ̀ oorùn Afíríkà',
 			'013' => 'Ààrin Gbùgbùn Àmẹ́ríkà',
 			'014' => 'Ìlà Oorùn Áfíríkà',
 			'015' => 'Àríwá Afíríkà',
 			'017' => 'Ààrín gbùngbùn Afíríkà',
 			'018' => 'Apágúúsù Áfíríkà',
 			'019' => 'Amẹ́ríkà',
 			'021' => 'Apáàríwá Amẹ́ríkà',
 			'029' => 'Káríbíànù',
 			'030' => 'Ìlà Òòrùn Eṣíà',
 			'034' => 'Gúúṣù Eṣíà',
 			'035' => 'Gúúṣù ìlà òòrùn Éṣíà',
 			'039' => 'Gúúṣù Yúróòpù',
 			'053' => 'Ọṣirélaṣíà',
 			'054' => 'Mẹlanéṣíà',
 			'057' => 'Agbègbè Maikironéṣíà',
 			'061' => 'Polineṣíà',
 			'142' => 'Áṣíà',
 			'143' => 'Ààrin Gbùngbùn Éṣíà',
 			'145' => 'Ìwọ̀ Òòrùn Eṣíà',
 			'150' => 'Yúróòpù',
 			'151' => 'Ìlà Òrùn Yúrópù',
 			'154' => 'Àríwá Yúróòpù',
 			'155' => 'Ìwọ̀ Òòrùn Yúrópù',
 			'202' => 'Apá Sàhárà Áfíríkà',
 			'419' => 'Látín Amẹ́ríkà',
 			'AC' => 'Erékùsù Ascension',
 			'AD' => 'Ààndórà',
 			'AE' => 'Ẹmirate ti Awọn Arabu',
 			'AF' => 'Àfùgànístánì',
 			'AG' => 'Ààntígúà àti Báríbúdà',
 			'AI' => 'Ààngúlílà',
 			'AL' => 'Àlùbàníánì',
 			'AM' => 'Améníà',
 			'AO' => 'Ààngólà',
 			'AQ' => 'Antakítíkà',
 			'AR' => 'Agentínà',
 			'AS' => 'Sámóánì ti Orílẹ́ède Àméríkà',
 			'AT' => 'Asítíríà',
 			'AU' => 'Ástràlìá',
 			'AW' => 'Árúbà',
 			'AX' => 'Àwọn Erékùsù ti Åland',
 			'AZ' => 'Asẹ́bájánì',
 			'BA' => 'Bọ̀síníà àti Ẹtisẹgófínà',
 			'BB' => 'Bábádósì',
 			'BD' => 'Bángáládésì',
 			'BE' => 'Bégíọ́mù',
 			'BF' => 'Bùùkíná Fasò',
 			'BG' => 'Bùùgáríà',
 			'BH' => 'Báránì',
 			'BI' => 'Bùùrúndì',
 			'BJ' => 'Bẹ̀nẹ̀',
 			'BL' => 'Ìlú Bátílẹ́mì',
 			'BM' => 'Bémúdà',
 			'BN' => 'Búrúnẹ́lì',
 			'BO' => 'Bọ̀lífíyà',
 			'BQ' => 'Kàríbíánì ti Nẹ́dálándì',
 			'BR' => 'Bàràsílì',
 			'BS' => 'Bàhámásì',
 			'BT' => 'Bútánì',
 			'BV' => 'Erékùsù Bouvet',
 			'BW' => 'Bọ̀tìsúwánà',
 			'BY' => 'Bélárúsì',
 			'BZ' => 'Bèlísẹ̀',
 			'CA' => 'Kánádà',
 			'CC' => 'Erékùsù Cocos (Keeling)',
 			'CD' => 'Kóńgò – Kinshasa',
 			'CD@alt=variant' => 'Kóńgò (Tiwantiwa)',
 			'CF' => 'Àrin gùngun Áfíríkà',
 			'CG' => 'Kóńgò – Brazaville',
 			'CG@alt=variant' => 'Kóńgò (Olómìnira)',
 			'CH' => 'switiṣilandi',
 			'CI' => 'Kóútè forà',
 			'CK' => 'Etíokun Kùúkù',
 			'CL' => 'Ṣílè',
 			'CM' => 'Kamerúúnì',
 			'CN' => 'Ṣáínà',
 			'CO' => 'Kòlómíbìa',
 			'CP' => 'Erékùsù Clipperston',
 			'CR' => 'Kuusita Ríkà',
 			'CU' => 'Kúbà',
 			'CV' => 'Etíokun Kápé féndè',
 			'CW' => 'Curaçao',
 			'CX' => 'Erékùsù Christmas',
 			'CY' => 'Kúrúsì',
 			'CZ' => 'Ṣẹ́ẹ́kì',
 			'DE' => 'Jámánì',
 			'DG' => 'Diego Gaṣia',
 			'DJ' => 'Díbọ́ótì',
 			'DK' => 'Dẹ́mákì',
 			'DM' => 'Dòmíníkà',
 			'DO' => 'Dòmíníkánì',
 			'DZ' => 'Àlùgèríánì',
 			'EA' => 'Seuta àti Melilla',
 			'EC' => 'Ekuádò',
 			'EE' => 'Esitonia',
 			'EG' => 'Égípítì',
 			'EH' => 'Ìwọ̀òòrùn Sàhárà',
 			'ER' => 'Eritira',
 			'ES' => 'Sipani',
 			'ET' => 'Etopia',
 			'EU' => 'Àpapọ̀ Yúróòpù',
 			'EZ' => 'Agbègbè Yúrò',
 			'FI' => 'Filandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Etikun Fakalandi',
 			'FM' => 'Makoronesia',
 			'FO' => 'Àwọn Erékùsù ti Faroe',
 			'FR' => 'Faranse',
 			'GA' => 'Gabon',
 			'GB' => 'Gẹ̀ẹ́sì',
 			'GD' => 'Genada',
 			'GE' => 'Gọgia',
 			'GF' => 'Firenṣi Guana',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibaratara',
 			'GL' => 'Gerelandi',
 			'GM' => 'Gambia',
 			'GN' => 'Gene',
 			'GP' => 'Gadelope',
 			'GQ' => 'Ekutoria Gini',
 			'GR' => 'Geriisi',
 			'GS' => 'Gúúsù Georgia àti Gúúsù Àwọn Erékùsù Sandwich',
 			'GT' => 'Guatemala',
 			'GU' => 'Guamu',
 			'GW' => 'Gene-Busau',
 			'GY' => 'Guyana',
 			'HK' => 'Agbègbè Ìṣàkóso Ìṣúná Hong Kong Tí Ṣánà Ń Darí',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Erékùsù Heard àti Erékùsù McDonald',
 			'HN' => 'Hondurasi',
 			'HR' => 'Kòróátíà',
 			'HT' => 'Haati',
 			'HU' => 'Hungari',
 			'IC' => 'Ẹrékùsù Kánárì',
 			'ID' => 'Indonesia',
 			'IE' => 'Ailandi',
 			'IL' => 'Iserẹli',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Etíkun Índíánì ti Ìlú Bírítísì',
 			'IO@alt=biot' => 'Àlà-ilẹ̀ Bírítéènì ní Etíkun Índíà',
 			'IO@alt=chagos' => 'Àkójọpọ̀ Àwọn Erékùṣù Ṣágòsì',
 			'IQ' => 'Iraki',
 			'IR' => 'Irani',
 			'IS' => 'Aṣilandi',
 			'IT' => 'Itáli',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jọdani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kuriṣisitani',
 			'KH' => 'Kàmùbódíà',
 			'KI' => 'Kiribati',
 			'KM' => 'Kòmòrósì',
 			'KN' => 'Kiiti ati Neefi',
 			'KP' => 'Guusu Kọria',
 			'KR' => 'Ariwa Kọria',
 			'KW' => 'Kuweti',
 			'KY' => 'Etíokun Kámánì',
 			'KZ' => 'Kaṣaṣatani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Luṣia',
 			'LI' => 'Lẹṣitẹnisiteni',
 			'LK' => 'Siri Lanka',
 			'LR' => 'Laberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituania',
 			'LU' => 'Lusemogi',
 			'LV' => 'Latifia',
 			'LY' => 'Libiya',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Modofia',
 			'ME' => 'Montenegro',
 			'MF' => 'Ìlú Màtìnì',
 			'MG' => 'Madasika',
 			'MH' => 'Etikun Máṣali',
 			'MK' => 'Àríwá Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Manamari',
 			'MN' => 'Mogolia',
 			'MO' => 'Agbègbè Ìṣàkóso Pàtàkì Macao',
 			'MO@alt=short' => 'Màkáò',
 			'MP' => 'Etikun Guusu Mariana',
 			'MQ' => 'Matinikuwi',
 			'MR' => 'Maritania',
 			'MS' => 'Motserati',
 			'MT' => 'Malata',
 			'MU' => 'Maritiusi',
 			'MV' => 'Maladifi',
 			'MW' => 'Malawi',
 			'MX' => 'Mesiko',
 			'MY' => 'Malasia',
 			'MZ' => 'Moṣamibiku',
 			'NA' => 'Namibia',
 			'NC' => 'Kaledonia Titun',
 			'NE' => 'Nàìjá',
 			'NF' => 'Etikun Nọ́úfókì',
 			'NG' => 'Nàìjíríà',
 			'NI' => 'Nikaragua',
 			'NL' => 'Nedalandi',
 			'NO' => 'Nọọwii',
 			'NP' => 'Nepa',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Ṣilandi Titun',
 			'NZ@alt=variant' => 'Sílándì Titun ti Atìríà',
 			'OM' => 'Ọọma',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Firenṣi Polinesia',
 			'PG' => 'Paapu ti Giini',
 			'PH' => 'Filipini',
 			'PK' => 'Pakisitan',
 			'PL' => 'Polandi',
 			'PM' => 'Pẹẹri ati mikuloni',
 			'PN' => 'Pikarini',
 			'PR' => 'Pọto Riko',
 			'PS' => 'Agbègbè ara Palẹsítínì',
 			'PS@alt=short' => 'Palẹsítínì',
 			'PT' => 'Pọ́túgà',
 			'PW' => 'Paalu',
 			'PY' => 'Paraguye',
 			'QA' => 'Kota',
 			'QO' => 'Agbègbè Òṣọ́ọ́níà',
 			'RE' => 'Riuniyan',
 			'RO' => 'Romaniya',
 			'RS' => 'Sẹ́bíà',
 			'RU' => 'Rọṣia',
 			'RW' => 'Ruwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Etikun Solomoni',
 			'SC' => 'Ṣeṣẹlẹsi',
 			'SD' => 'Sudani',
 			'SE' => 'Swidini',
 			'SG' => 'Singapo',
 			'SH' => 'Hẹlena',
 			'SI' => 'Silofania',
 			'SJ' => 'Sífábáàdì àti Jánì Máyẹ̀nì',
 			'SK' => 'Silofakia',
 			'SL' => 'Siria looni',
 			'SM' => 'Sani Marino',
 			'SN' => 'Sẹnẹga',
 			'SO' => 'Somalia',
 			'SR' => 'Surinami',
 			'SS' => 'Gúúsù Sudan',
 			'ST' => 'Sao tomi ati piriiṣipi',
 			'SV' => 'Ẹẹsáfádò',
 			'SX' => 'Síntì Mátẹ́ẹ̀nì',
 			'SY' => 'Siria',
 			'SZ' => 'Saṣiland',
 			'SZ@alt=variant' => 'Síwásìlandì',
 			'TA' => 'Tristan da Kunha',
 			'TC' => 'Tọọki ati Etikun Kakọsi',
 			'TD' => 'Ṣààdì',
 			'TF' => 'Agbègbè Gúúsù Faranṣé',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Takisitani',
 			'TK' => 'Tokelau',
 			'TL' => 'ÌlàOòrùn Tímọ̀',
 			'TL@alt=variant' => 'Ìlà Òòrùn Tímọ̀',
 			'TM' => 'Tọọkimenisita',
 			'TN' => 'Tuniṣia',
 			'TO' => 'Tonga',
 			'TR' => 'Tọọki',
 			'TT' => 'Tirinida ati Tobaga',
 			'TV' => 'Tufalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tàǹsáníà',
 			'UA' => 'Ukarini',
 			'UG' => 'Uganda',
 			'UM' => 'Àwọn Erékùsù Kékèké Agbègbè US',
 			'UN' => 'Ìṣọ̀kan àgbáyé',
 			'US' => 'Amẹrikà',
 			'UY' => 'Nruguayi',
 			'UZ' => 'Nṣibẹkisitani',
 			'VA' => 'Ìlú Vatican',
 			'VC' => 'Fisẹnnti ati Genadina',
 			'VE' => 'Fẹnẹṣuẹla',
 			'VG' => 'Etíkun Fágínì ti ìlú Bírítísì',
 			'VI' => 'Etikun Fagini ti Amẹrika',
 			'VN' => 'Fẹtinami',
 			'VU' => 'Faniatu',
 			'WF' => 'Wali ati futuna',
 			'WS' => 'Samọ',
 			'XA' => 'ìsọ̀rọ̀sí irọ́',
 			'XB' => 'ibi irọ́',
 			'XK' => 'Kòsófò',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayote',
 			'ZA' => 'Gúúṣù Áfíríkà',
 			'ZM' => 'Ṣamibia',
 			'ZW' => 'Ṣimibabe',
 			'ZZ' => 'Àgbègbè àìmọ̀',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kàlẹ́ńdà',
 			'cf' => 'Ìgúnrégé Kọ́rẹ́ńsì',
 			'collation' => 'Ètò Ẹlẹ́sẹẹsẹ',
 			'currency' => 'Kọ́rẹ́ńsì',
 			'hc' => 'Òbíríkiti Wákàtí (12 vs 24)',
 			'lb' => 'Àra Ìda Ìlà',
 			'ms' => 'Èto Ìdiwọ̀n',
 			'numbers' => 'Àwọn nọ́ńbà',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'buddhist' => q{Kàlẹ́ńdà Buddhist},
 				'chinese' => q{Kàlẹ́ńdà ti Ṣáìnà},
 				'coptic' => q{Èdè Kopti},
 				'dangi' => q{Kàlẹ́ńdà dangi},
 				'ethiopic' => q{Kàlẹ́ńdà Ẹtíópíìkì},
 				'ethiopic-amete-alem' => q{Èdè Kalenda Alem Amete tio Etiopia},
 				'gregorian' => q{Kàlẹ́ńdà Gregory},
 				'hebrew' => q{Kàlẹ́ńdà Hébérù},
 				'islamic' => q{Kàlẹ́ńdà Lárúbáwá},
 				'islamic-civil' => q{Kàlẹ́ńdà ti Musulumi},
 				'islamic-umalqura' => q{Kàlẹ́ńdà Musulumi},
 				'iso8601' => q{Kàlẹ́ńdà ISO-8601},
 				'japanese' => q{Kàlẹ́ńdà ti Jàpánù},
 				'persian' => q{Kàlẹ́ńdà Pásíànù},
 				'roc' => q{Kàlẹ́ńdà Minguo},
 			},
 			'cf' => {
 				'account' => q{Ìgúnrégé Ìṣirò Owó Kọ́rẹ́ńsì},
 				'standard' => q{Ìgúnrégé Gbèdéke Kọ́rẹ́ńsì},
 			},
 			'collation' => {
 				'ducet' => q{Ètò Ẹlẹ́sẹẹsẹ Àkùàyàn Unicode},
 				'search' => q{Ìṣàwárí Ète-Gbogbogbò},
 				'standard' => q{Ìlànà Onírúurú Ètò},
 			},
 			'hc' => {
 				'h11' => q{Èto Wákàtí 12 (0–11)},
 				'h12' => q{Èto Wákàtí 12 (1–12)},
 				'h23' => q{Èto Wákàtí 24 (0–23)},
 				'h24' => q{Èto Wákàtí 24 (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Àra Ìda Ìlà Títú},
 				'normal' => q{Àra Ìda Ìlà Déédéé},
 				'strict' => q{Àra Ìda Ìlà Mímúná},
 			},
 			'ms' => {
 				'metric' => q{Èto Mẹ́tíríìkì},
 				'uksystem' => q{Èto Ìdiwọ̀n Ọba},
 				'ussystem' => q{Èto Ìdiwọ̀n US},
 			},
 			'numbers' => {
 				'arab' => q{àwọn díjítì Làrubáwá-Índíà},
 				'arabext' => q{Àwọn Díjíìtì Lárúbáwá-Índíà fífẹ̀},
 				'armn' => q{Àwọn nọ́ńbà Àmẹ́níà},
 				'armnlow' => q{Àwọn Nọ́ńbà Kékèké ti Amẹ́ríkà},
 				'beng' => q{Àwọn díjíìtì Báńgílà},
 				'cakm' => q{Àwọn díjíìtì Shakma},
 				'deva' => q{Àwọn díjììtì Defanagárì},
 				'ethi' => q{Àwọn nọ́ńbà Ẹtiópíìkì},
 				'fullwide' => q{Àwọn Díjíìtì Fífẹ̀-Ẹ̀kún},
 				'geor' => q{Àwọn nọ́ńbà Jọ́jíà},
 				'grek' => q{Àwọn nọ́ńbà Gíríìkì},
 				'greklow' => q{Àwọn Nọ́ńbà Gíríìkì Kékèké},
 				'gujr' => q{Àwọn díjíìtì Gùjárátì},
 				'guru' => q{Àwọn Díjíìtì Gurumukì},
 				'hanidec' => q{Àwọn nọ́ńbà Dẹ́símà Ṣáìnà},
 				'hans' => q{Àwọn nọ́ńbà Ìrọ̀rùn ti Ṣáìnà},
 				'hansfin' => q{Àwọn nọ́ńbà Ìṣúná Ìrọ̀rùn Ṣáìnà},
 				'hant' => q{Àwọn nọ́ńbà Ìbílẹ̀ Ṣáìnà},
 				'hantfin' => q{Àwọn nọ́ńbà Ìṣúná Ìbílẹ̀ Ṣáìnà},
 				'hebr' => q{Àwọn nọ́ńbà Hébérù},
 				'java' => q{Àwọn díjíìtì Jafaniisi},
 				'jpan' => q{Àwọn nọ́ńbà Jápànù},
 				'jpanfin' => q{Àwọn nọ́ńbà Ìṣúná Jàpáànù},
 				'khmr' => q{Àwọn díjíìtì Kẹ́mẹ̀},
 				'knda' => q{Àwọn díjíìtì kanada},
 				'laoo' => q{Àwọn díjíìtì Láó},
 				'latn' => q{Díjíítì Ìwọ̀ Oòrùn},
 				'mlym' => q{Àwọn díjíìtì Málàyálámù},
 				'mtei' => q{Àwọn díjíìtì Mete Mayeki},
 				'mymr' => q{Àwọn díjíìtì Myánmarí},
 				'olck' => q{Àwọn díjíìtì Shiki},
 				'orya' => q{Àwọn díjíìtì Òdíà},
 				'roman' => q{Àwọn díjíìtì Rómánù},
 				'romanlow' => q{Àwọn díjíìtì Rómánù Kékeré},
 				'taml' => q{Àwọn díjíìtì Ìbílẹ̀ Támílù},
 				'tamldec' => q{Àwọn díjíìtì Tàmílù},
 				'telu' => q{Àwọn díjíìtì Télúgù},
 				'thai' => q{Àwọn díjíìtì Thai},
 				'tibt' => q{Àwọn díjíìtì Tibetán},
 				'vaii' => q{Àwọn díjíìtì Fai},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{Mẹ́tíríìkì},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Èdè: {0}',
 			'script' => 'Ìṣọwọ́kọ̀wé: {0}',
 			'region' => 'Àgbègbè: {0}',

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[c q v x z]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'],
			main => qr{[aáà b d eéè ẹ{ẹ́}{ẹ̀} f g {gb} h iíì j k l mḿ{m̀}{m̄} nńǹ{n̄} oóò ọ{ọ́}{ọ̀} p r s ṣ t uúù w y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mẹ́bì {0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mẹ́bì {0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gíbí {0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gíbí {0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tẹbi {0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tẹbi {0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pẹbi {0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pẹbi {0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ẹ́síbì {0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ẹ́síbì {0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(sẹ́bì {0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(sẹ́bì {0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yóòbù {0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yóòbù {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(àwọ́n ohun),
						'other' => q({0} àwon ohun),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(àwọ́n ohun),
						'other' => q({0} àwon ohun),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} ìdákan nínú ẹgbẹ̀rún),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} ìdákan nínú ẹgbẹ̀rún),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(àwọ́n bíìtì),
						'other' => q({0} àwọ́n bíìtì),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(àwọ́n bíìtì),
						'other' => q({0} àwọ́n bíìtì),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(àwọ́n báìtì),
						'other' => q({0} àwọ́n báìtì),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(àwọ́n báìtì),
						'other' => q({0} àwọ́n báìtì),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(àwọn gígábíìtì),
						'other' => q({0} àwọn gígábíìtì),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(àwọn gígábíìtì),
						'other' => q({0} àwọn gígábíìtì),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(àwọn gígábáìtì),
						'other' => q({0} àwọn gígábáìtì),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(àwọn gígábáìtì),
						'other' => q({0} àwọn gígábáìtì),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(àwọn kílóbíìtì),
						'other' => q({0} àwọ́n kílóbíìtì),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(àwọn kílóbíìtì),
						'other' => q({0} àwọ́n kílóbíìtì),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(àwọn kílóbáìtì),
						'other' => q({0} àwọn kílóbáìtì),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(àwọn kílóbáìtì),
						'other' => q({0} àwọn kílóbáìtì),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(àwọn mégábíìtì),
						'other' => q({0} àwọn mégábíìtì),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(àwọn mégábíìtì),
						'other' => q({0} àwọn mégábíìtì),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(àwọn mégábáìtì),
						'other' => q({0} àwọn mégábáìtì),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(àwọn mégábáìtì),
						'other' => q({0} àwọn mégábáìtì),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(àwọn pẹ́tábáìtì),
						'other' => q({0} àwọn pẹ́tábáìtì),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(àwọn pẹ́tábáìtì),
						'other' => q({0} àwọn pẹ́tábáìtì),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(àwọn tẹ́rábíìtì),
						'other' => q({0} àwọn tẹ́rábíìtì),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(àwọn tẹ́rábíìtì),
						'other' => q({0} àwọn tẹ́rábíìtì),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(àwọn tẹ́rábáìtì),
						'other' => q({0} àwọn tẹ́rábáìtì),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(àwọn tẹ́rábáìtì),
						'other' => q({0} àwọn tẹ́rábáìtì),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ọ̀rúndún),
						'other' => q(ọ̀rúndún {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ọ̀rúndún),
						'other' => q(ọ̀rúndún {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q(ọj {0}),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q(ọj {0}),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'other' => q(ẹ̀wádùn {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'other' => q(ẹ̀wádùn {0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(iseju aya kekere),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(iseju aya kekere),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(idamerin),
						'other' => q({0} idamerin),
						'per' => q({0}/ida),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(idamerin),
						'other' => q({0} idamerin),
						'per' => q({0}/ida),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0}ìṣ àáy),
						'per' => q({0}/ìṣ àáy),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0}ìṣ àáy),
						'per' => q({0}/ìṣ àáy),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0}/ọṣ),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0}/ọṣ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ọ̀dún),
						'per' => q({0} ọd),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ọ̀dún),
						'per' => q({0} ọd),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(àwọ́n wákàtí kílówáàtì ní kìlómítà ọgọ́rùn),
						'other' => q({0} àwọ́n wákàtí kílówáàtì ní kìlómítà ọgọ́rùn),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(àwọ́n wákàtí kílówáàtì ní kìlómítà ọgọ́rùn),
						'other' => q({0} àwọ́n wákàtí kílówáàtì ní kìlómítà ọgọ́rùn),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ìdinwọ̀n ayé),
						'other' => q({0} ìdinwọ̀n ayé),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ìdinwọ̀n ayé),
						'other' => q({0} ìdinwọ̀n ayé),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fátọ́ọ̀mu),
						'other' => q({0} fátọ́ọ̀mù),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fátọ́ọ̀mu),
						'other' => q({0} fátọ́ọ̀mù),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(àwọn fọ́lọ́ọ̀ngì),
						'other' => q({0} àwọn fọ́lọ́ọ̀ngì),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(àwọn fọ́lọ́ọ̀ngì),
						'other' => q({0} àwọn fọ́lọ́ọ̀ngì),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandẹ́là),
						'other' => q({0} kandẹ́là),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandẹ́là),
						'other' => q({0} kandẹ́là),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumẹ́ẹ̀nì),
						'other' => q({0} lumẹ́ẹ̀nì),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumẹ́ẹ̀nì),
						'other' => q({0} lumẹ́ẹ̀nì),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(giréènì),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(giréènì),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'other' => q({0} àwon okùta),
					},
					# Core Unit Identifier
					'stone' => {
						'other' => q({0} àwon okùta),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} sikuwe),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} sikuwe),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q(kubiki {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q(kubiki {0}),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(búsẹ́ẹ̀li),
						'other' => q({0} búsẹ́ẹ̀li),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(búsẹ́ẹ̀li),
						'other' => q({0} búsẹ́ẹ̀li),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(àmì ṣíbí oúnjẹ́ kékeré),
						'other' => q({0} àmì ṣíbí oúnjẹ́ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(àmì ṣíbí oúnjẹ́ kékeré),
						'other' => q({0} àmì ṣíbí oúnjẹ́ kékeré),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(ṣíbí oúnjẹ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ṣíbí oúnjẹ kékeré),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ìdásímérin),
						'other' => q({0} ìdásímérin),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ìdásímérin),
						'other' => q({0} ìdásímérin),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(àmì Ki {0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(àmì Ki {0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(àmì Pí {0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(àmì Pí {0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(àmì Yí {0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(àmì Yí {0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0}Gs),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0}Gs),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'other' => q({0}rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'other' => q({0}dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'other' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'other' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'other' => q({0}ohun),
					},
					# Core Unit Identifier
					'item' => {
						'other' => q({0}ohun),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'other' => q({0}mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'other' => q({0}mol),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'other' => q({0}L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'other' => q({0}bíìtì),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'other' => q({0}bíìtì),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q(ọj {0}),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q(ọj {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0}/ìṣ),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0}/ìṣ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'other' => q({0} i),
					},
					# Core Unit Identifier
					'quarter' => {
						'other' => q({0} i),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ọṣẹ́),
						'per' => q({0}/ọ̀ṣẹ̀),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ọṣẹ́),
						'per' => q({0}/ọ̀ṣẹ̀),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'other' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'other' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'other' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'other' => q({0}US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'other' => q({0}US therms),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(KWh ní 100km),
						'other' => q({0} kWh ní 100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(KWh ní 100km),
						'other' => q({0} kWh ní 100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0}dpi),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatọ́),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatọ́),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(cd),
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(cd),
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lọ́s),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lọ́s),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'other' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'other' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'other' => q({0}gr),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(okùta),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(okùta),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'other' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q({0}mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0}mph),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'other' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'other' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(búsẹ́li),
						'other' => q({0}búsẹ́ẹ̀li),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(búsẹ́li),
						'other' => q({0}búsẹ́ẹ̀li),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'other' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0}c),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0}c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'other' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'other' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'other' => q({0}dr),
					},
					# Core Unit Identifier
					'drop' => {
						'other' => q({0}dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp gal),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp gal),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'other' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'other' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jìgá),
						'other' => q({0}jìgá),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jìgá),
						'other' => q({0}jìgá),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'other' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'other' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'other' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'other' => q({0}mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pn),
						'other' => q({0}pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pn),
						'other' => q({0}pn),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'other' => q({0}àmì ìdásímérin),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'other' => q({0}àmì ìdásímérin),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'other' => q({0}tsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(àmì Kí {0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(àmì Kí {0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(àmì Mi {0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(àmì Mi {0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(àmì Gi {0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(àmì Gi {0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(àmì Ti {0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(àmì Ti {0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(àmì Pi {0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(àmì Pi {0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(àmì Ei {0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(àmì Ei {0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(àmì Sí {0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(àmì Sí {0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(àmì {0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(àmì {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ohun),
						'other' => q({0} ohun),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ohun),
						'other' => q({0} ohun),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(ìdákan nínú ẹgbẹ̀rún),
						'other' => q({0} pasenti),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(ìdákan nínú ẹgbẹ̀rún),
						'other' => q({0} pasenti),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ara/milíọ̀nù),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ara/milíọ̀nù),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bíìtì),
						'other' => q({0} bíìtì),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bíìtì),
						'other' => q({0} bíìtì),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(báìtì),
						'other' => q({0} báìtì),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(báìtì),
						'other' => q({0} báìtì),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(jíbíìtì),
						'other' => q({0}jíbíìtì),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(jíbíìtì),
						'other' => q({0}jíbíìtì),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(jíbáìtì),
						'other' => q({0} jíbáìtì),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(jíbáìtì),
						'other' => q({0} jíbáìtì),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kébiì),
						'other' => q({0} kébiì),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kébiì),
						'other' => q({0} kébiì),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kébáìtì),
						'other' => q({0} kébáìtì),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kébáìtì),
						'other' => q({0} kébáìtì),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ẹ́mbíìtì),
						'other' => q({0} ẹ́mbiì),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ẹ́mbíìtì),
						'other' => q({0} ẹ́mbiì),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ẹ́mbáìtì),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ẹ́mbáìtì),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Píbáìtì),
						'other' => q({0} Píbáìtì),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Píbáìtì),
						'other' => q({0} Píbáìtì),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(Tíbáìtì),
						'other' => q({0} Tíbáìtì),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(Tíbáìtì),
						'other' => q({0} Tíbáìtì),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ọjọ́),
						'other' => q({0} ọj),
						'per' => q({0}/ọj),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ọjọ́),
						'other' => q({0} ọj),
						'per' => q({0}/ọj),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ẹ̀wádùn),
						'other' => q(ẹ̀wádún {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ẹ̀wádùn),
						'other' => q(ẹ̀wádún {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(wkt),
						'other' => q({0} wkt),
						'per' => q({0}/wkt),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(wkt),
						'other' => q({0} wkt),
						'per' => q({0}/wkt),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ìṣ),
						'other' => q({0} ìṣ),
						'per' => q({0}/ìṣ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ìṣ),
						'other' => q({0} ìṣ),
						'per' => q({0}/ìṣ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(oṣù),
						'other' => q({0} oṣù),
						'per' => q({0}/oṣù),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(oṣù),
						'other' => q({0} oṣù),
						'per' => q({0}/oṣù),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(idame),
						'other' => q({0} idame),
						'per' => q({0}/id),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(idame),
						'other' => q({0} idame),
						'per' => q({0}/id),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ìṣ àáy),
						'other' => q({0} ìṣ àáy),
						'per' => q({0} ìṣ àáy),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ìṣ àáy),
						'other' => q({0} ìṣ àáy),
						'per' => q({0} ìṣ àáy),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ọṣ),
						'other' => q({0} ọṣ),
						'per' => q({0}/ọṣẹ̀),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ọṣ),
						'other' => q({0} ọṣ),
						'per' => q({0}/ọṣẹ̀),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ọd),
						'other' => q({0} ọd),
						'per' => q({0}/ọd),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ọd),
						'other' => q({0} ọd),
						'per' => q({0}/ọd),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(KWh lọ́rí 100km),
						'other' => q({0} KWh lọ́rí 100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(KWh lọ́rí 100km),
						'other' => q({0} KWh lọ́rí 100km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dọ́ọ̀tì),
						'other' => q({0} dọ́ọ̀tì),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dọ́ọ̀tì),
						'other' => q({0} dọ́ọ̀tì),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(àmì ìdínwọ̀n ayé),
						'other' => q({0} àmì ìdínwọ̀n ayé),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(àmì ìdínwọ̀n ayé),
						'other' => q({0} àmì ìdínwọ̀n ayé),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fátọ́mù),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fátọ́mù),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fọ́lọ́ọ̀ngì),
						'other' => q({0} fọ́),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fọ́lọ́ọ̀ngì),
						'other' => q({0} fọ́),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(sídiì),
						'other' => q({0} sídiì),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(sídiì),
						'other' => q({0} sídiì),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(àmì lumẹ́ẹ̀nì),
						'other' => q({0} Lúmẹ́nì),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(àmì lumẹ́ẹ̀nì),
						'other' => q({0} Lúmẹ́nì),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gíréènì),
						'other' => q({0} gíréènì),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gíréènì),
						'other' => q({0} gíréènì),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(àwon okùta),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(àwon okùta),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(Búsẹ́ẹ̀li),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(Búsẹ́ẹ̀li),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ṣíbí oúnjẹ́ kékeré),
						'other' => q({0} ṣíbí oúnjẹ́ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ṣíbí oúnjẹ́ kékeré),
						'other' => q({0} ṣíbí oúnjẹ́ kékeré),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(àmì oúnjẹ kékeré),
						'other' => q({0} àmì oúnjẹ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(àmì oúnjẹ kékeré),
						'other' => q({0} àmì oúnjẹ kékeré),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(omi dírámù),
						'other' => q({0} àmì omi dírámù),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(omi dírámù),
						'other' => q({0} àmì omi dírámù),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dírọ́pù),
						'other' => q({0} dírọ́pù),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dírọ́pù),
						'other' => q({0} dírọ́pù),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jígà),
						'other' => q({0} jígà),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jígà),
						'other' => q({0} jígà),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(píńṣì),
						'other' => q({0} píńṣì),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(píńṣì),
						'other' => q({0} píńṣì),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(àmì ìdásímérin),
						'other' => q({0} àmì ìdásímérin),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(àmì ìdásímérin),
						'other' => q({0} àmì ìdásímérin),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Bẹ́ẹ̀ni |N|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Bẹ́ẹ̀kọ́|K)$' }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'other' => '0 ẹgbẹ̀rún',
				},
				'10000' => {
					'other' => '00 ẹgbẹ̀rún',
				},
				'100000' => {
					'other' => '000 ẹgbẹ̀rún',
				},
				'1000000' => {
					'other' => '0 mílíọ̀nù',
				},
				'10000000' => {
					'other' => '00 mílíọ̀nù',
				},
				'100000000' => {
					'other' => '000 mílíọ̀nù',
				},
				'1000000000' => {
					'other' => '0 bilíọ̀nù',
				},
				'10000000000' => {
					'other' => '00 bilíọ̀nù',
				},
				'100000000000' => {
					'other' => '000 bilíọ̀nù',
				},
				'1000000000000' => {
					'other' => '0 tiriliọ̀nù',
				},
				'10000000000000' => {
					'other' => '00 tiriliọ̀nù',
				},
				'100000000000000' => {
					'other' => '000 tiriliọ̀nù',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(Diami ti Awon Orílẹ́ède Arabu),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afugánì Afuganísítàànì),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lẹ́ẹ̀kì Àlìbáníà),
				'other' => q(lẹ́kè Àlìbéníà),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dírààmù Àmẹ́níà),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Gílídà Netherlands Antillean),
				'other' => q(àwọn gílídà Netherlands Antillean),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kíwánsà Angola),
				'other' => q(àwọn kíwánsà Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Pẹ́sò Agẹntínà),
				'other' => q(àwọn pẹ́sò Agẹntínà),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Ástràlìá),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Fuloríìnì Àrúbà),
				'other' => q(àwọn fuloríìnì Àrúbà),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Mánààtì Àsàbáíjáì),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Àmi Yíyípadà Bosnia-Herzegovina),
				'other' => q(àwọn àmi Yíyípadà Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dọ́là Bábádọ̀ọ̀sì),
				'other' => q(àwọn dọ́là Bábádọ̀ọ̀sì),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Tákà Báńgíládẹ̀ẹ̀ṣì),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Owó Lẹ́fì Bọ̀lìgéríà),
				'other' => q(Lẹ́fà Bọ̀lìgéríà),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Báránì),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faransi Bùùrúndì),
				'other' => q(àwọn faransi Bùùrúndì),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dọ́là Bẹ̀múdà),
				'other' => q(àwọ́n dọ́là Bẹ̀múdà),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dọ́là Bùrùnéì),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bọlifiánò Bọ̀lífíà),
				'other' => q(àwọn bọlifiánò Bọ̀lífíà),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Owó ti Orílẹ̀-èdè Brazil),
				'other' => q(Awon owó ti Orílẹ̀-èdè Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dọ́là Bàhámà),
				'other' => q(àwọn dọ́là Bàhámà),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ìngọ́tírọ̀mù Bútàànì),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Bọ̀tìsúwánà),
				'other' => q(àwọn pula Bọ̀tìsúwánà),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rọ́bù Bẹ̀lárùùsì),
				'other' => q(àwọn rọ́bù Bẹ̀lárùùsì),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dọ́là Bẹ̀lísè),
				'other' => q(àwọn Dọ́là Bẹ́lìsè),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dọ́là Kánádà),
				'other' => q(àwọn dọ́là Kánádà),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Firanki Kongo),
				'other' => q(àwọn firanki Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faransí Síwíìsì),
				'other' => q(Faransi Siwisi),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Pẹ́sò Ṣílè),
				'other' => q(àwọn pẹ́sò Ṣílè),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yúànì Sháínà),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Reminibi ti Orílẹ́ède ṣáínà),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Pẹ́sò Kòlóḿbíà),
				'other' => q(àwọn pẹ́sò Kòlóḿbíà),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kólọ́ọ̀nì Kosita Ríkà),
				'other' => q(àwọ́n kólọ́ọ̀nì Kosita Ríkà),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Pẹ́sò Yíyípadà Kúbà),
				'other' => q(àwọn pẹ́sò yíyípadà Kúbà),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Pẹ́sò Kúbà),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Èsìkúdò Kapú Faadì),
				'other' => q(àwọn èsìkúdò Kapú Faadì),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Ṣẹ́ẹ̀kì),
				'other' => q(àwọn koruna Ṣẹ́ẹ̀kì),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faransi Dibouti),
				'other' => q(àwọn faransi Dibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kírónì Dáníṣì),
				'other' => q(Kírònà Dáníìṣì),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Pẹ́sò Dòníníkà),
				'other' => q(àwọn pẹ́sò Dòníníkà),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dina ti Orílẹ́ède Àlùgèríánì),
				'other' => q(àwọn dínà Àlùgèríánì),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(pọọn ti Orílẹ́ède Egipiti),
				'other' => q(àwọn pọ́n-ún Ejipítì),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakifasì Eritira),
				'other' => q(àwọn nakifasì Eritira),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Báà Etópíà),
				'other' => q(àwọn báà Etópíà),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(owó Yúrò),
				'other' => q(Awon owó Yúrò),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dọ́là Fíjì),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pọ́n-ùn Erékùsù Falkland),
				'other' => q(àwọn Pọ́n-ùn Erékùsù Falkland [ Pɔ́n-ùn Erékùsù Falkland ] 1.23 Pọ́n-ùn Erékùsù Falkland 0.00 pọ́n-ùn Erékùsù Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pọ́n-ùn ti Orilẹ̀-èdè Gẹ̀ẹ́sì),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lárì Jọ́jíà),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ṣidi ti Orílẹ́ède Gana),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(sídì Gana),
				'other' => q(àwọn sídì Gana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pọ́n-ùn Gibúrátà),
				'other' => q(àwọn pọ́n-ùn Gibúrátà),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gamibia),
				'other' => q(àwọn dalasi Gamibia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Fírànkì Gínì),
				'other' => q(àwọn fírànkì Gínì),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faransi ti Orílẹ́ède Gini),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Kúẹ́tísààlì Guatimílà),
				'other' => q(àwọn kúẹ́tísààlì Guatimílà),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dọ́là Gùyánà),
				'other' => q(àwọn dọ́là Gùyánà),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dọ́là Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lẹmipírà Ọ́ńdúrà),
				'other' => q(àwọn Lẹmipírà Ọ́ńdúrà),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kúnà Kúróṣíà),
				'other' => q(àwọn kúnà Kúróṣíà),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gọ́dì Àítì),
				'other' => q(àwọn gọ́dì Àítì),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Fọ́ríǹtì Họ̀ngérí),
				'other' => q(àwọn fọ́ríǹtì Họ̀ngérí),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rúpìyá Indonésíà),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Ṣékélì Tuntun Ísírẹ̀ẹ̀lì),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi ti Orílẹ́ède Indina),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dínárì Ìráákì),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iranian),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Kòrónà Icelandic),
				'other' => q(kórónọ̀ Áílándíìkì),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dọ́là Jàmáíkà),
				'other' => q(àwọn dọ́là Jàmáíkà),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dínárì Jọ́dàànì),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ti Orílẹ́ède Japani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Ṣiili Kenya),
				'other' => q(àwọ́n ṣiili Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Sómú Kirijísítàànì),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Ráyò Kàm̀bọ́díà),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faransi Komori),
				'other' => q(àwọn faransi Komori),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Wọ́ọ̀nù Àríwá Kòríà),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Wọ́ọ̀nù Gúúsù Kòríà),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dínárì Kuwaiti),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dọ́là Erékùsù Cayman),
				'other' => q(àwọn dọ́là Erékùsù Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tẹngé Kasakísítàànì),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kíììpù Làótì),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pọ́n-ùn Lebanese),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rúpìì Siri Láńkà),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dọla Liberia),
				'other' => q(àwọn dọla Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ti Orílẹ́ède Lesoto),
				'other' => q(Lótì ti Lẹ̀sótò),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dínà Líbíyà),
				'other' => q(àwọn dínà Líbíyà),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dírámì Morokò),
				'other' => q(àwọn dírámì Morokò),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Owó Léhù Moldovan),
				'other' => q(Léhì Moldovan),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Faransi Malagasi),
				'other' => q(àwọn faransi Malagasi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dẹ́nà Masidóníà),
				'other' => q(dẹ́nàrì Masidóníà),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kíyàtì Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Túgúrììkì Mòǹgólíà),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pàtákà Màkáò),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya ti Orílẹ́ède Maritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya ti Orílẹ́ède Maritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupi Maritusi),
				'other' => q(àwọn rupi Maritusi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rúfìyá Mọ̀lìdífà),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kásà Màláwì),
				'other' => q(àwọn kásà Màláwì),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pẹ́sò Mẹ́síkò),
				'other' => q(àwọn pẹ́sò Mẹ́síkò),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ríngìtì Màléṣíà),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metika ti Orílẹ́ède Mosamibiki),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mẹ́tíkààlì Mòsáḿbíìkì),
				'other' => q(àwọn mẹ́tíkààlì Mòsáḿbíìkì),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dọla Namibíà),
				'other' => q(àwọn dọla Namibíà),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Náírà Nàìjíríà),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Kọ̀dóbà Naikarágúà),
				'other' => q(àwọn kọ̀dóbà Naikarágúà),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(kórónì Nọ́wè),
				'other' => q(kórónà Nọ́wè),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rúpìì Nẹ̵́pààlì),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dọ́là New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Ráyò Omani),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Bálíbóà Pànámà),
				'other' => q(àwọn bálíbóà Pànámà),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sólì Pèrúù),
				'other' => q(àwọn sólì Pèrúù),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kínà Papua Guinea Tuntun),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Písò Fílípìnì),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rúpìì Pakisitánì),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Sílọ̀tì Pọ́líṣì),
				'other' => q(àwọn sílọ̀tì Pọ́líṣì),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Gúáránì Párágúwè),
				'other' => q(àwọn gúáránì Párágúwè),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Ráyò Kàtárì),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Léhù Ròméníà),
				'other' => q(Léhì Ròméníà),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dínárì Sàbíà),
				'other' => q(àwọn dínárì Sàbíà),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(Owó ruble ti ilẹ̀ Rọ́ṣíà),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faransi Ruwanda),
				'other' => q(àwọn faransi Ruwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riya ti Orílẹ́ède Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dọ́là Erékùsù Sọ́lómọ́nì),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rúpì Sayiselesi),
				'other' => q(àwọ́n rúpì Sayiselesi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pọ́n-ùn Sùdáànì),
				'other' => q(àwọn pọ́n-ùn Sùdáànì),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pọọun ti Orílẹ́ède Sudani),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Kòrónà Súwídìn),
				'other' => q(Kòrónọ̀ Súwídìn),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dọ́là Síngápọ̀),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pọ́n-un Elena),
				'other' => q(àwọn pọ́n-un Elena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Líónì Sira Líonì),
				'other' => q(àwọn líónì Sira Líonì),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Líónì Sira Líonì \(1964—2022\)),
				'other' => q(àwọn líónì Sira Líonì \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Ṣílè Somali),
				'other' => q(àwọ́n ṣílè Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dọ́là Súrínámì),
				'other' => q(àwọn Dọ́là Súrínámì),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pọ́n-un Gúúsù Sùdáànì),
				'other' => q(àwọn pọ́n-un Gúúsù Sùdáànì),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobira ti Orílẹ́ède Sao tome Ati Pirisipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dọbíra Sao tome àti Pirisipi),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pọ́n-ùn Sírìà),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Suwasi),
				'other' => q(emalangeni Suwasi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Báàtì Tháì),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Sómónì Tajikístàànì),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Mánààtì Tọkimẹnístàànì),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dínà Tuniṣíà),
				'other' => q(àwọn dínà Tuniṣíà),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Pàángà Tóńgà),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lírà Tọ́kì),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dọ́là Trinidad & Tobago),
				'other' => q(àwọn dọ́là Trinidad àti Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dọ́là Tàìwánì Tuntun),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Sile Tansania),
				'other' => q(àwọn ṣile Tansania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ọrifiníyà Yukiréníà),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ṣile Uganda),
				'other' => q(àwọn ṣile Uganda),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dọ́là),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Pẹ́sò Úrúgúwè),
				'other' => q(àwọn pẹ́sò Úrúgúwè),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sómú Usibẹkísítàànì),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bọ̀lífà Fẹnẹsuẹ́là),
				'other' => q(àwọn bọ̀lífà Fẹnẹsuẹ́là),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dáhùn Vietnamese),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Fátù Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tálà Sàmóà),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Firanki àárín Afíríkà),
				'other' => q(àwọn firanki àárín Afíríkà),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dọ́là Ilà Oòrùn Karíbíà),
				'other' => q(àwọn dọ́là Ilà Oòrùn Karíbíà),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faransì ìwọ̀-oorùn Afíríkà),
				'other' => q(àwọn faransì ìwọ̀-oorùn Afíríkà),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Fírànkì CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(owóníná àìmọ̀),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Ráyò Yẹ́mẹ̀nì),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rándì Gúúsù Afíríkà),
				'other' => q(rándì Gúúsù Afíríkà),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kawaṣa ti Orílẹ́ède Saabia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kàwasà Sámbíà),
				'other' => q(àwọn kàwasà Sámbíà),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dọla ti Orílẹ́ède Siibabuwe),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Ṣẹ́r',
							'Èrèl',
							'Ẹrẹ̀n',
							'Ìgb',
							'Ẹ̀bi',
							'Òkú',
							'Agẹ',
							'Ògú',
							'Owe',
							'Ọ̀wà',
							'Bél',
							'Ọ̀pẹ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Oṣù Ṣẹ́rẹ́',
							'Oṣù Èrèlè',
							'Oṣù Ẹrẹ̀nà',
							'Oṣù Ìgbé',
							'Oṣù Ẹ̀bibi',
							'Oṣù Òkúdu',
							'Oṣù Agẹmọ',
							'Oṣù Ògún',
							'Oṣù Owewe',
							'Oṣù Ọ̀wàrà',
							'Oṣù Bélú',
							'Oṣù Ọ̀pẹ̀'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ṣẹ́',
							'Èr',
							'Ẹr',
							'Ìg',
							'Ẹ̀b',
							'Òk',
							'Ag',
							'Òg',
							'Ow',
							'Ọ̀w',
							'Bé',
							'Ọ̀p'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'S',
							'È',
							'Ẹ',
							'Ì',
							'Ẹ̀',
							'Ò',
							'A',
							'Ò',
							'O',
							'Ọ̀',
							'B',
							'Ọ̀'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ṣẹ́rẹ́',
							'Èrèlè',
							'Ẹrẹ̀nà',
							'Ìgbé',
							'Ẹ̀bibi',
							'Òkúdu',
							'Agẹmọ',
							'Ògún',
							'Owewe',
							'Ọ̀wàrà',
							'Bélú',
							'Ọ̀pẹ̀'
						],
						leap => [
							
						],
					},
				},
			},
	} },
);

has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'Aj',
						tue => 'Ìsẹ́g',
						wed => 'Ọjọ́r',
						thu => 'Ọjọ́b',
						fri => 'Ẹt',
						sat => 'Àbám',
						sun => 'Àìk'
					},
					wide => {
						mon => 'Ọjọ́ Ajé',
						tue => 'Ọjọ́ Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ọjọ́ Ẹtì',
						sat => 'Ọjọ́ Àbámẹ́ta',
						sun => 'Ọjọ́ Àìkú'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'A',
						tue => 'Ì',
						wed => 'Ọ',
						thu => 'Ọ',
						fri => 'Ẹ',
						sat => 'À',
						sun => 'À'
					},
					wide => {
						mon => 'Ajé',
						tue => 'Ìsẹ́gun',
						wed => 'Ọjọ́rú',
						thu => 'Ọjọ́bọ',
						fri => 'Ẹtì',
						sat => 'Àbámẹ́ta',
						sun => 'Àìkú'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					narrow => {0 => 'kíní',
						1 => 'Kejì',
						2 => 'Kẹta',
						3 => 'Kẹin'
					},
					wide => {0 => 'Ìdámẹ́rin kíní',
						1 => 'Ìdámẹ́rin Kejì',
						2 => 'Ìdámẹ́rin Kẹta',
						3 => 'Ìdámẹ́rin Kẹrin'
					},
				},
				'stand-alone' => {
					narrow => {0 => 'kí',
						1 => 'Ke',
						2 => 'Kẹt',
						3 => 'Kẹr'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{Àárọ̀},
					'pm' => q{Ọ̀sán},
				},
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'1' => 'AD'
			},
			wide => {
				'0' => 'Saju Kristi',
				'1' => 'Lehin Kristi'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MM y G},
			'long' => q{d MM y G},
			'medium' => q{d MM y G},
			'short' => q{dd/MM/y G},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMM y},
			'long' => q{d MMM y},
			'medium' => q{d MM y},
			'short' => q{d/M/y},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:m:s},
			'short' => q{H:m},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{d MMM, E},
			MMMMEd => q{d, MMMM E},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{d/M/y, E},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM , y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, M/d/y G – E, M/d/y G},
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y G – M/d/y G},
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{MM-y – MM-y},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{E, dd-MM-y – E dd-MM-y, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{MMM d, E – MMM d, E y},
				d => q{MMM d, E – MMM d, E y},
				y => q{y MMM d y, E – MMM d, E y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM – y MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d y},
				d => q{MMM d–d y},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(WAT{0}),
		gmtZeroFormat => q(WAT),
		regionFormat => q(Ìgbà {0}),
		regionFormat => q({0} Àkókò ojúmọmọ),
		regionFormat => q({0} Ìlànà Àkókò),
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanistan Time#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Àkókò Àárín Afírikà#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Àkókò Ìlà-Oòrùn Afírikà#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#South Africa Standard Time#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Àkókò Ìwọ̀-Oòrùn Ooru Afírikà#,
				'generic' => q#Àkókò Ìwọ̀-Oòrùn Afírikà#,
				'standard' => q#Àkókò Ìwọ̀-Oòrùn Àfẹnukò Afírikà#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Àkókò Ìyálẹ̀ta Alásíkà#,
				'generic' => q#Àkókò Alásíkà#,
				'standard' => q#Àkókò Àfẹnukò Alásíkà#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Àkókò Oru Amásọ́nì#,
				'generic' => q#Àkókò Amásọ́nì#,
				'standard' => q#Àkókò Afẹnukò Amásọ́nì#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#ìlú Adákì#,
		},
		'America/Anchorage' => {
			exemplarCity => q#ìlú Ankọ́réèjì#,
		},
		'America/Anguilla' => {
			exemplarCity => q#ìlú Angúílà#,
		},
		'America/Antigua' => {
			exemplarCity => q#ìlú Antígùà#,
		},
		'America/Aruba' => {
			exemplarCity => q#ìlú Arúbá#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#ìlú Báhì Bándẹ́rásì#,
		},
		'America/Barbados' => {
			exemplarCity => q#ìlú Bábádọ́ọ̀sì#,
		},
		'America/Belize' => {
			exemplarCity => q#ìlú Bẹ̀líìsì#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ìlú Blank Sabulọ́ọ̀nì#,
		},
		'America/Boise' => {
			exemplarCity => q#ìlú Bọ́isè#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#ìlú òkun kambíríìjì#,
		},
		'America/Cancun' => {
			exemplarCity => q#ìlú Kancun#,
		},
		'America/Cayman' => {
			exemplarCity => q#ilú Kayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#ìlú Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ìlú Ṣihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#ìlú àtikọkàn#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#ìlú Kosta Ríkà#,
		},
		'America/Creston' => {
			exemplarCity => q#ìlú Kírẹstọ́ọ̀nù#,
		},
		'America/Curacao' => {
			exemplarCity => q#ìlú Kuraṣao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ìlú Banmarkshan#,
		},
		'America/Dawson' => {
			exemplarCity => q#ìlú Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ìlú Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#ìlú Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#ìlú Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#ìlú Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ìlú Edmonton#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ìlú El Savador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#ìlú Fort Nelson#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ìlú omi Glace#,
		},
		'America/Godthab' => {
			exemplarCity => q#ìlú Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#ìlú omi Goosù#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#ìlú Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#ìlú Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ìlú Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ìlú Guatemala#,
		},
		'America/Halifax' => {
			exemplarCity => q#ìlú Halifásì#,
		},
		'America/Havana' => {
			exemplarCity => q#ìlú Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ìlú Hermosilo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#ìlú nọ́sì#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#ìlú Marẹ́ngo#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#ìlú Petersburg#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ìlú Tell City#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ìlú Vevay#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#ìlú Vincennes ní Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ìlú Winamak ní Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#ìlú Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ìlú Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ìlú Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#ìlú Jamaikà#,
		},
		'America/Juneau' => {
			exemplarCity => q#ìlú Junu#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#ìlú Montisẹ́lò#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#ìlú Kíralẹ́ndáikì#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#ìlú Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#ìlú Lúífíìlì#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#ìlú Lower Prince’s Quarter#,
		},
		'America/Managua' => {
			exemplarCity => q#ìlú Managua#,
		},
		'America/Marigot' => {
			exemplarCity => q#ìlú Marigọ́ọ̀tì#,
		},
		'America/Martinique' => {
			exemplarCity => q#ìlú Mátíníkì#,
		},
		'America/Matamoros' => {
			exemplarCity => q#ìlú Matamorosì#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#ìlú Masatiani#,
		},
		'America/Menominee' => {
			exemplarCity => q#ìlú Menominì#,
		},
		'America/Merida' => {
			exemplarCity => q#ìlú Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#ìlú Metilakatila#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#ìlú Mẹ́síkò#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ìlú Mikulọ́nì#,
		},
		'America/Moncton' => {
			exemplarCity => q#ìlú Montoni#,
		},
		'America/Monterrey' => {
			exemplarCity => q#ìlú Monteri#,
		},
		'America/Montserrat' => {
			exemplarCity => q#ìlú Monseratì#,
		},
		'America/Nassau' => {
			exemplarCity => q#ìlú Nasaò#,
		},
		'America/New_York' => {
			exemplarCity => q#ìlú New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#ìlú Nipigoni#,
		},
		'America/Nome' => {
			exemplarCity => q#ìlú Nomi#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#ìlú Beulà ní North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#ìlú Senta North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#ìlú New Salem ni North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ìlú Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#ìlú Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#ìlú Panituni#,
		},
		'America/Phoenix' => {
			exemplarCity => q#ìlú Fínísì#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#ìlú Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#ìlú etí omi Sípéènì#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ìlú Puerto Riko#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#ìlú Raini Rifà#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#ìlú Rankin Inlet#,
		},
		'America/Regina' => {
			exemplarCity => q#ìlú Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#ìlú Resolútì#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#ìlú Santo Domigo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#ìlú Itokotomiti#,
		},
		'America/Sitka' => {
			exemplarCity => q#ìlú Sika#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#ìlú Batilemì#,
		},
		'America/St_Johns' => {
			exemplarCity => q#ìlú St Jọ́ọ̀nù#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#ìlú St kitisì#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#ìlú St Lusia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#ìlú St Tọ́màsì#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#ìlú Finsentì#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ìlú Súfítù Kọ̀rentì#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ìlú Tegusigapà#,
		},
		'America/Thule' => {
			exemplarCity => q#ìlú Tulè#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#ìlú Omi Thunder#,
		},
		'America/Tijuana' => {
			exemplarCity => q#ìlú Tíjúana#,
		},
		'America/Toronto' => {
			exemplarCity => q#ìlú Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#ìlú Totola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#ìlú Vankuva#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#ìlú Whitehosì#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ìlú Winipegì#,
		},
		'America/Yakutat' => {
			exemplarCity => q#ìlú Yakuta#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#ìlú Yelonáfù#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Akókò àárín gbùngbùn ojúmọmọ#,
				'generic' => q#àkókò àárín gbùngbùn#,
				'standard' => q#àkókò asiko àárín gbùngbùn#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Àkókò ojúmọmọ Ìhà Ìlà Oòrun#,
				'generic' => q#Àkókò ìhà ìlà oòrùn#,
				'standard' => q#Akókò Àsikò Ìha Ìla Oòrùn#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Àkókò ojúmọmọ Ori-òkè#,
				'generic' => q#Àkókò òkè#,
				'standard' => q#Àkókò asiko òkè#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Àkókò Ìyálẹta Pàsífíìkì#,
				'generic' => q#Àkókò Pàsífíìkì#,
				'standard' => q#Àkókò àsikò Pàsífíìkì#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Daylight Time#,
				'generic' => q#Apia Time#,
				'standard' => q#Apia Standard Time#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabian Daylight Time#,
				'generic' => q#Arabian Time#,
				'standard' => q#Arabian Standard Time#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Aago Soma Argentina#,
				'generic' => q#Aago Ajẹntìnà#,
				'standard' => q#Aago àsìkò Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Àkókò Oru Iwọ́-oòrùn Ajẹ́ntínà#,
				'generic' => q#Àkókò Iwọ́-oòrùn Ajẹ́ntínà#,
				'standard' => q#Àkókò Iwọ́-oòrùn Àfẹnukò Ajẹ́ntínà#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenia Summer Time#,
				'generic' => q#Armenia Time#,
				'standard' => q#Armenia Standard Time#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Àkókò Ìyálẹta Àtìláńtíìkì#,
				'generic' => q#Àkókò Àtìláńtíìkì#,
				'standard' => q#Àkókò àsikò Àtìláńtíìkì#,
			},
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#ìlú Bẹ̀múdà#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australian Central Daylight Time#,
				'generic' => q#Central Australia Time#,
				'standard' => q#Australian Central Standard Time#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australian Central Western Daylight Time#,
				'generic' => q#Australian Central Western Time#,
				'standard' => q#Australian Central Western Standard Time#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australian Eastern Daylight Time#,
				'generic' => q#Eastern Australia Time#,
				'standard' => q#Australian Eastern Standard Time#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australian Western Daylight Time#,
				'generic' => q#Western Australia Time#,
				'standard' => q#Australian Western Standard Time#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaijan Summer Time#,
				'generic' => q#Azerbaijan Time#,
				'standard' => q#Azerbaijan Standard Time#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Àkókò Ooru Ásọ́sì#,
				'generic' => q#Àkókò Ásọ́sì#,
				'standard' => q#Àkókò Àfẹnukò Ásọ́sì#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesh Summer Time#,
				'generic' => q#Bangladesh Time#,
				'standard' => q#Bangladesh Standard Time#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan Time#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Aago Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Aago Soma Brasilia#,
				'generic' => q#Aago Bùràsílíà#,
				'standard' => q#Aago àsìkò Bùràsílíà#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam Time#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Àkókò Sọ́mà Képú Fáàdì#,
				'generic' => q#Àkókò Képú Fáàdì#,
				'standard' => q#Àkókò Àfẹnukò Képú Fáàdì#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro Standard Time#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham Daylight Time#,
				'generic' => q#Chatham Time#,
				'standard' => q#Chatham Standard Time#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Àkókò Oru Ṣílè#,
				'generic' => q#Àkókò Ṣílè#,
				'standard' => q#Àkókò Àfẹnukò Ṣílè#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Ṣáínà#,
				'generic' => q#Àkókò Ṣáínà#,
				'standard' => q#Àkókò Ìfẹnukòsí Ṣáínà#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan Summer Time#,
				'generic' => q#Choibalsan Time#,
				'standard' => q#Choibalsan Standard Time#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmas Island Time#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos Islands Time#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Aago Soma Colombia#,
				'generic' => q#Aago Kolombia#,
				'standard' => q#Aago àsìkò Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Islands Half Summer Time#,
				'generic' => q#Cook Islands Time#,
				'standard' => q#Cook Islands Standard Time#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Kúbà#,
				'generic' => q#Àkókò Kúbà#,
				'standard' => q#Àkókò Àfẹnukò Kúbà#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis Time#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Time#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Àkókò Ìlà oorùn Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Aago Soma Easter Island#,
				'generic' => q#Aago Ajnde Ibùgbé Omi#,
				'standard' => q#Aago àsìkò Easter Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Aago Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Àpapọ̀ Àkókò Àgbáyé#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ìlú Àìmọ̀#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irish Standard Time#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#British Summer Time#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Àkókò Àárin Sọmà Europe#,
				'generic' => q#Àkókò Àárin Europe#,
				'standard' => q#Àkókò Àárin àsikò Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Àkókò Sọmà Ìha Ìlà Oòrùn Europe#,
				'generic' => q#Àkókò Ìhà Ìlà Oòrùn Europe#,
				'standard' => q#Àkókò àsikò Ìhà Ìlà Oòrùn Europe#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Àkókò Iwájú Ìlà Oòrùn Yúróòpù#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Àkókò Sọmà Ìhà Ìwọ Oòrùn Europe#,
				'generic' => q#Àkókò Ìwọ Oòrùn Europe#,
				'standard' => q#Àkókò àsikò Ìwọ Oòrùn Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Àkókò Ooru Etíkun Fókílándì#,
				'generic' => q#Àkókò Fókílándì#,
				'standard' => q#Àkókò Àfẹnukò Etíkun Fókílándì#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji Summer Time#,
				'generic' => q#Fiji Time#,
				'standard' => q#Fiji Standard Time#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Àkókò Gúyánà Fáránsè#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Àkókò Gúsù Fáransé àti Àntátíìkì#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Aago Galapago#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier Time#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia Summer Time#,
				'generic' => q#Georgia Time#,
				'standard' => q#Georgia Standard Time#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Islands Time#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Àkókò ìgbà Ooru Greenland#,
				'generic' => q#Àkókò Ìlà oorùn Greenland#,
				'standard' => q#Àkókò Ìwọ̀ Ìfẹnukò oorùn Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Àkókò Àfẹnukò Ìgba Oòru Greenland#,
				'generic' => q#Àkókò Ìwọ̀ oorùn Greenland#,
				'standard' => q#Àkókò Àfẹnukò Ìwọ̀ Oòrùn Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gulf Standard Time#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Àkókò Gúyànà#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Hawaii-Aleutian#,
				'generic' => q#Àkókò Hawaii-Aleutian#,
				'standard' => q#Àkókò Àfẹnukò Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong Summer Time#,
				'generic' => q#Hong Kong Time#,
				'standard' => q#Hong Kong Standard Time#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Summer Time#,
				'generic' => q#Hovd Time#,
				'standard' => q#Hovd Standard Time#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India Standard Time#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Àkókò Etíkun Índíà#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Àkókò Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Àkókò Ààrin Gbùngbùn Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Eastern Indonesia Time#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Àkókò Ìwọ̀ oorùn Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran Daylight Time#,
				'generic' => q#Iran Time#,
				'standard' => q#Iran Standard Time#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Àkókò Sọmà Íkúsíkì#,
				'generic' => q#Àkókò Íkósíkì#,
				'standard' => q#Àkókò Àfẹnukò Íkósíkì#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Daylight Time#,
				'generic' => q#Israel Time#,
				'standard' => q#Israel Standard Time#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Daylight Time#,
				'generic' => q#Japan Time#,
				'standard' => q#Japan Standard Time#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#East Kazakhstan Time#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#West Kazakhstan Time#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean Daylight Time#,
				'generic' => q#Korean Time#,
				'standard' => q#Korean Standard Time#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae Time#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk Summer Time#,
				'generic' => q#Krasnoyarsk Time#,
				'standard' => q#Krasnoyarsk Standard Time#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kyrgyzstan Time#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Islands Time#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe Daylight Time#,
				'generic' => q#Lord Howe Time#,
				'standard' => q#Lord Howe Standard Time#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie Island Time#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan Summer Time#,
				'generic' => q#Magadan Time#,
				'standard' => q#Magadan Standard Time#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysia Time#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldives Time#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas Time#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Islands Time#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Àkókò Ooru Máríṣúṣì#,
				'generic' => q#Àkókò Máríṣúṣì#,
				'standard' => q#Àkókò Àfẹnukò Máríṣúṣì#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson Time#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Apá Ìwọ̀ Oorùn Mẹ́ṣíkò#,
				'generic' => q#Àkókò Apá Ìwọ̀ Oorùn Mẹ́ṣíkò#,
				'standard' => q#Àkókò Àfẹnukò Apá Ìwọ̀ Oorùn Mẹ́ṣíkò#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Pásífíìkì Mẹ́síkò#,
				'generic' => q#Àkókò Pásífíìkì Mẹ́ṣíkò#,
				'standard' => q#Àkókò Àfẹnukò Pásífíìkì Mẹ́síkò#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar Summer Time#,
				'generic' => q#Ulaanbaatar Time#,
				'standard' => q#Ulaanbaatar Standard Time#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moscow Summer Time#,
				'generic' => q#Moscow Time#,
				'standard' => q#Moscow Standard Time#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar Time#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Time#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal Time#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#New Caledonia Summer Time#,
				'generic' => q#New Caledonia Time#,
				'standard' => q#New Caledonia Standard Time#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#New Zealand Daylight Time#,
				'generic' => q#New Zealand Time#,
				'standard' => q#New Zealand Standard Time#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Newfoundland#,
				'generic' => q#Àkókò Newfoundland#,
				'standard' => q#Àkókò Àfẹnukò Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Time#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Island Daylight Time#,
				'generic' => q#Norfolk Island Time#,
				'standard' => q#Norfolk Island Standard Time#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Aago Soma Fernando de Noronha#,
				'generic' => q#Aago Fenando de Norona#,
				'standard' => q#Aago àsìkò Fenando de Norona#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk Summer Time#,
				'generic' => q#Novosibirsk Time#,
				'standard' => q#Novosibirsk Standard Time#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Summer Time#,
				'generic' => q#Omsk Time#,
				'standard' => q#Omsk Standard Time#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan Summer Time#,
				'generic' => q#Pakistan Time#,
				'standard' => q#Pakistan Standard Time#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Time#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua New Guinea Time#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Àkókò Ooru Párágúwè#,
				'generic' => q#Àkókò Párágúwè#,
				'standard' => q#Àkókò Àfẹnukò Párágúwè#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Àkókò Ooru Pérù#,
				'generic' => q#Àkókò Pérù#,
				'standard' => q#Àkókò Àfẹnukò Pérù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Philippine Summer Time#,
				'generic' => q#Philippine Time#,
				'standard' => q#Philippine Standard Time#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix Islands Time#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Àkókò Ojúmọmọ Pierre & Miquelon#,
				'generic' => q#Àkókò Pierre & Miquelon#,
				'standard' => q#Àkókò Àfẹnukò Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn Time#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Time#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang Time#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Àkókò Rẹ́yúníọ́nì#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera Time#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin Summer Time#,
				'generic' => q#Sakhalin Time#,
				'standard' => q#Sakhalin Standard Time#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Daylight Time#,
				'generic' => q#Samoa Time#,
				'standard' => q#Samoa Standard Time#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Àkókò Sèṣẹ́ẹ̀lì#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapore Standard Time#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Islands Time#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Àkókò Gúsù Jọ́jíà#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Àkókò Súrínámù#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa Time#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Time#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Daylight Time#,
				'generic' => q#Taipei Time#,
				'standard' => q#Taipei Standard Time#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tajikistan Time#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Time#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga Summer Time#,
				'generic' => q#Tonga Time#,
				'standard' => q#Tonga Standard Time#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk Time#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan Summer Time#,
				'generic' => q#Turkmenistan Time#,
				'standard' => q#Turkmenistan Standard Time#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu Time#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Aago Soma Uruguay#,
				'generic' => q#Aago Uruguay#,
				'standard' => q#Àkókò Àfẹnukò Úrúgúwè#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistan Summer Time#,
				'generic' => q#Uzbekistan Time#,
				'standard' => q#Uzbekistan Standard Time#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu Summer Time#,
				'generic' => q#Vanuatu Time#,
				'standard' => q#Vanuatu Standard Time#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Aago Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Summer Time#,
				'generic' => q#Vladivostok Time#,
				'standard' => q#Vladivostok Standard Time#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd Summer Time#,
				'generic' => q#Volgograd Time#,
				'standard' => q#Volgograd Standard Time#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok Time#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Island Time#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis & Futuna Time#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk Summer Time#,
				'generic' => q#Yakutsk Time#,
				'standard' => q#Yakutsk Standard Time#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg Summer Time#,
				'generic' => q#Yekaterinburg Time#,
				'standard' => q#Yekaterinburg Standard Time#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Àkókò Yúkọ́nì#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
