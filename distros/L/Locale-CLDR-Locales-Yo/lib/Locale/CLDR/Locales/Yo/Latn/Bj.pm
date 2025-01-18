=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Yo::Latn::Bj - Package for language Yoruba

=cut

package Locale::CLDR::Locales::Yo::Latn::Bj;
# This file auto generated from Data\common\main\yo_BJ.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Yo::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'agq' => 'Èdè Ágɛ̀ɛ̀mù',
 				'bez' => 'Èdè Bɛ́nà',
 				'chr' => 'Èdè Shɛ́rókiì',
 				'cu' => 'Èdè Síláfííkì Ilé Ìjɔ́sìn',
 				'cv' => 'Èdè Shufasi',
 				'de_AT' => 'Èdè Jámánì (Ɔ́síríà )',
 				'de_CH' => 'Èdè Ilɛ̀ Jámánì (Orílɛ́ède swítsàlandì)',
 				'dje' => 'Shárúmà',
 				'dsb' => 'Shóbíánù Apá Ìshàlɛ̀',
 				'ebu' => 'Èdè Ɛmbù',
 				'en' => 'Èdè Gɛ̀ɛ́sì',
 				'en_AU' => 'Èdè Gɛ̀ɛ́sì (órílɛ̀-èdè Ɔsirélíà)',
 				'en_CA' => 'Èdè Gɛ̀ɛ́sì (Orílɛ̀-èdè Kánádà)',
 				'en_GB' => 'Èdè òyìnbó Gɛ̀ɛ́sì',
 				'en_GB@alt=short' => 'Èdè Gɛ̀ɛ́sì (GB)',
 				'en_US@alt=short' => 'Èdè Gɛ̀ɛ́sì (US)',
 				'es' => 'Èdè Sípáníìshì',
 				'es_419' => 'Èdè Sípáníìshì (orílɛ̀-èdè Látìn-Amɛ́ríkà)',
 				'es_ES' => 'Èdè Sípáníìshì (orílɛ̀-èdè Yúróòpù)',
 				'es_MX' => 'Èdè Sípáníìshì (orílɛ̀-èdè Mɛ́síkò)',
 				'fr_CA' => 'Èdè Faransé (orílɛ̀-èdè Kánádà)',
 				'fr_CH' => 'Èdè Faranshé (Súwísàlaǹdì)',
 				'gez' => 'Ede Gɛ́sì',
 				'hi_Latn@alt=variant' => 'Èdè Híńgílíshì',
 				'id' => 'Èdè Indonéshíà',
 				'ie' => 'Èdè àtɔwɔ́dá',
 				'ii' => 'Shíkuán Yì',
 				'jmc' => 'Máshámè',
 				'khq' => 'Koira Shíínì',
 				'kk' => 'Kashakì',
 				'kln' => 'Kálɛnjín',
 				'ks' => 'Kashímirì',
 				'ksb' => 'Sháńbálà',
 				'ku' => 'Kɔdishì',
 				'kw' => 'Èdè Kɔ́nììshì',
 				'lb' => 'Lùshɛ́mbɔ́ɔ̀gì',
 				'mul' => 'Ɔlɔ́pɔ̀ èdè',
 				'nb' => 'Nɔ́ɔ́wè Bokímàl',
 				'nds' => 'Jámánì ìpìlɛ̀',
 				'nl' => 'Èdè Dɔ́ɔ̀shì',
 				'nl_BE' => 'Èdè Flemishi',
 				'nmg' => 'Kíwáshíò',
 				'nn' => 'Nɔ́ɔ́wè Nínɔ̀sìkì',
 				'nus' => 'Núɛ̀',
 				'nyn' => 'Ńyákɔ́lè',
 				'oc' => 'Èdè Ɔ̀kísítáànì',
 				'om' => 'Òròmɔ́',
 				'os' => 'Ɔshɛ́tíìkì',
 				'prg' => 'Púrúshíànù',
 				'pt' => 'Èdè Pɔtogí',
 				'pt_BR' => 'Èdè Pɔtogí (Orilɛ̀-èdè Bràsíl)',
 				'pt_PT' => 'Èdè Pɔtogí (orílɛ̀-èdè Yúróòpù)',
 				'qu' => 'Kúɛ́ńjùà',
 				'rm' => 'Rómáǹshì',
 				'ru' => 'Èdè Rɔ́shíà',
 				'seh' => 'Shɛnà',
 				'shi' => 'Tashelíìtì',
 				'sn' => 'Shɔnà',
 				'szl' => 'Silìshíànì',
 				'teo' => 'Tɛ́sò',
 				'tr' => 'Èdè Tɔɔkisi',
 				'ug' => 'Yúgɔ̀',
 				'und' => 'Èdè àìmɔ̀',
 				'vec' => 'Fènéshìànì',
 				'vo' => 'Fɔ́lápùùkù',
 				'wae' => 'Wɔsà',
 				'wo' => 'Wɔ́lɔ́ɔ̀fù',
 				'xog' => 'Shógà',
 				'yav' => 'Yangbɛn',
 				'za' => 'Shúwáànù',
 				'zgh' => 'Àfɛnùkò Támásáìtì ti Mòrókò',
 				'zh' => 'Edè Sháínà',
 				'zh@alt=menu' => 'Edè Sháínà, Mandárínì',
 				'zh_Hans' => 'Ɛdè Sháínà Onírɔ̀rùn',
 				'zh_Hans@alt=long' => 'Èdè Mandárínì Sháínà Onírɔ̀rùn',
 				'zh_Hant' => 'Èdè Sháínà Ìbílɛ̀',
 				'zh_Hant@alt=long' => 'Èdè Mandárínì Sháínà Ìbílɛ̀',
 				'zu' => 'Èdè Shulu',

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
			'Armn' => 'Àmɛ́níà',
 			'Cyrl' => 'èdè ilɛ̀ Rɔ́shíà',
 			'Deva' => 'Dɛfanagárì',
 			'Ethi' => 'Ɛtiópíìkì',
 			'Geor' => 'Jɔ́jíànù',
 			'Hanb' => 'Han pɛ̀lú Bopomófò',
 			'Hans' => 'tí wɔ́n mú rɔrùn.',
 			'Hans@alt=stand-alone' => 'Hans tí wɔ́n mú rɔrùn.',
 			'Hrkt' => 'ìlànà àfɔwɔ́kɔ ará Jàpánù',
 			'Khmr' => 'Kɛmɛ̀',
 			'Plrd' => 'Fonɛtiiki Polaadi',
 			'Zmth' => 'Àmì Ìshèsìrò',
 			'Zsym' => 'Àwɔn àmì',
 			'Zxxx' => 'Aikɔsilɛ',
 			'Zyyy' => 'Wɔ́pɔ̀',
 			'Zzzz' => 'Ìshɔwɔ́kɔ̀wé àìmɔ̀',

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
			'003' => 'Àríwá Amɛ́ríkà',
 			'005' => 'Gúúshù Amɛ́ríkà',
 			'009' => 'Òsɔ́ɔ́níà',
 			'011' => 'Ìwɔ̀ oorùn Afíríkà',
 			'013' => 'Ààrin Gbùgbùn Àmɛ́ríkà',
 			'019' => 'Amɛ́ríkà',
 			'021' => 'Apáàríwá Amɛ́ríkà',
 			'030' => 'Ìlà Òòrùn Eshíà',
 			'034' => 'Gúúshù Eshíà',
 			'035' => 'Gúúshù ìlà òòrùn Éshíà',
 			'039' => 'Gúúshù Yúróòpù',
 			'053' => 'Ɔshirélashíà',
 			'054' => 'Mɛlanéshíà',
 			'057' => 'Agbègbè Maikironéshíà',
 			'061' => 'Polineshíà',
 			'142' => 'Áshíà',
 			'143' => 'Ààrin Gbùngbùn Éshíà',
 			'145' => 'Ìwɔ̀ Òòrùn Eshíà',
 			'155' => 'Ìwɔ̀ Òòrùn Yúrópù',
 			'419' => 'Látín Amɛ́ríkà',
 			'AE' => 'Ɛmirate ti Awɔn Arabu',
 			'AS' => 'Sámóánì ti Orílɛ́ède Àméríkà',
 			'AX' => 'Àwɔn Erékùsù ti Aland',
 			'AZ' => 'Asɛ́bájánì',
 			'BA' => 'Bɔ̀síníà àti Ɛtisɛgófínà',
 			'BE' => 'Bégíɔ́mù',
 			'BJ' => 'Bɛ̀nɛ̀',
 			'BL' => 'Ìlú Bátílɛ́mì',
 			'BN' => 'Búrúnɛ́lì',
 			'BO' => 'Bɔ̀lífíyà',
 			'BQ' => 'Kàríbíánì ti Nɛ́dálándì',
 			'BW' => 'Bɔ̀tìsúwánà',
 			'BZ' => 'Bèlísɛ̀',
 			'CH' => 'switishilandi',
 			'CL' => 'Shílè',
 			'CN' => 'Sháínà',
 			'CZ' => 'Shɛ́ɛ́kì',
 			'CZ@alt=variant' => 'Shɛ́ɛ́kì Olómìnira',
 			'DG' => 'Diego Gashia',
 			'DJ' => 'Díbɔ́ótì',
 			'DK' => 'Dɛ́mákì',
 			'EH' => 'Ìwɔ̀òòrùn Sàhárà',
 			'EU' => 'Àpapɔ̀ Yúróòpù',
 			'FO' => 'Àwɔn Erékùsù ti Faroe',
 			'GB' => 'Gɛ̀ɛ́sì',
 			'GE' => 'Gɔgia',
 			'GF' => 'Firenshi Guana',
 			'GS' => 'Gúúsù Georgia àti Gúúsù Àwɔn Erékùsù Sandwich',
 			'HK' => 'Agbègbè Ìshàkóso Ìshúná Hong Kong Tí Shánà Ń Darí',
 			'IC' => 'Ɛrékùsù Kánárì',
 			'ID' => 'Indonéshíà',
 			'IL' => 'Iserɛli',
 			'IM' => 'Erékùshù ilɛ̀ Man',
 			'IO@alt=biot' => 'Àlà-ilɛ̀ Bírítéènì ní Etíkun Índíà',
 			'IO@alt=chagos' => 'Àkójɔpɔ̀ Àwɔn Erékùshù Shágòsì',
 			'IS' => 'Ashilandi',
 			'JE' => 'Jɛsì',
 			'JO' => 'Jɔdani',
 			'KG' => 'Kurishisitani',
 			'KP' => 'Guusu Kɔria',
 			'KR' => 'Ariwa Kɔria',
 			'KZ' => 'Kashashatani',
 			'LC' => 'Lushia',
 			'LI' => 'Lɛshitɛnisiteni',
 			'MH' => 'Etikun Máshali',
 			'MO' => 'Agbègbè Ìshàkóso Pàtàkì Macao',
 			'MZ' => 'Moshamibiku',
 			'NF' => 'Erékùsù Nɔ́úfókì',
 			'NO' => 'Nɔɔwii',
 			'NZ' => 'Shilandi Titun',
 			'OM' => 'Ɔɔma',
 			'PF' => 'Firenshi Polinesia',
 			'PM' => 'Pɛɛri ati mikuloni',
 			'PR' => 'Pɔto Riko',
 			'PS' => 'Agbègbè ara Palɛsítínì',
 			'PS@alt=short' => 'Palɛsítínì',
 			'PT' => 'Pɔ́túgà',
 			'QO' => 'Agbègbè Òshɔ́ɔ́níà',
 			'RS' => 'Sɛ́bíà',
 			'RU' => 'Rɔshia',
 			'SC' => 'Sheshɛlɛsi',
 			'SH' => 'Hɛlena',
 			'SJ' => 'Sífábáàdì àti Jánì Máyɛ̀nì',
 			'SN' => 'Sɛnɛga',
 			'ST' => 'Sao tomi ati piriishipi',
 			'SV' => 'Ɛɛsáfádò',
 			'SX' => 'Síntì Mátɛ́ɛ̀nì',
 			'SZ' => 'Sashiland',
 			'TC' => 'Tɔɔki ati Etikun Kakɔsi',
 			'TD' => 'Shààdì',
 			'TF' => 'Agbègbè Gúúsù Faranshé',
 			'TL' => 'Tímɔ̀ Lɛsiti',
 			'TL@alt=variant' => 'Ìlà Òòrùn Tímɔ̀',
 			'TM' => 'Tɔ́kìmɛ́nísítànì',
 			'TN' => 'Tunishia',
 			'TR' => 'Tɔɔki',
 			'TR@alt=variant' => 'Tɔ́kì',
 			'UM' => 'Àwɔn Erékùsù Kékèké Agbègbè US',
 			'UN' => 'Ìshɔ̀kan àgbáyé',
 			'US' => 'Amɛrikà',
 			'UZ' => 'Nshibɛkisitani',
 			'VC' => 'Fisɛnnti ati Genadina',
 			'VE' => 'Fɛnɛshuɛla',
 			'VI' => 'Etikun Fagini ti Amɛrika',
 			'VN' => 'Fɛtinami',
 			'WS' => 'Samɔ',
 			'XA' => 'ìsɔ̀rɔ̀sí irɔ́',
 			'XB' => 'Agbègbè irɔ́',
 			'ZA' => 'Gúúshù Áfíríkà',
 			'ZM' => 'Shamibia',
 			'ZW' => 'Shimibabe',
 			'ZZ' => 'Àgbègbè àìmɔ̀',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kàlɛ́ńdà',
 			'cf' => 'Ònà Ìgbekalɛ̀ owó',
 			'collation' => 'Ètò Ɛlɛ́sɛɛsɛ',
 			'ms' => 'Èto Ìdiwɔ̀n',
 			'numbers' => 'Àwɔn nɔ́ńbà',

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
 				'buddhist' => q{Kàlɛ́ńdà Buddhist},
 				'chinese' => q{Kàlɛ́ńdà ti Sháìnà},
 				'dangi' => q{Kàlɛ́ńdà dangi},
 				'ethiopic' => q{Kàlɛ́ńdà Ɛtíópíìkì},
 				'gregorian' => q{Kàlɛ́ńdà Gregory},
 				'hebrew' => q{Kàlɛ́ńdà Hébérù},
 				'islamic' => q{Kàlɛ́ńdà Lárúbáwá},
 				'islamic-civil' => q{Kàlɛ́ńdà ti Musulumi},
 				'islamic-umalqura' => q{Kàlɛ́ńdà Musulumi},
 				'iso8601' => q{Kàlɛ́ńdà ISO-8601},
 				'japanese' => q{Kàlɛ́ńdà ti Jàpánù},
 				'persian' => q{Kàlɛ́ńdà Pásíànù},
 				'roc' => q{Kàlɛ́ńdà Minguo},
 			},
 			'cf' => {
 				'account' => q{Ìgúnrégé Ìshirò Owó Kɔ́rɛ́ńsì},
 				'standard' => q{Ònà ìgbekalɛ̀ owó tó jɛ́ àjùmɔ̀lò},
 			},
 			'collation' => {
 				'ducet' => q{Ètò Ɛlɛ́sɛɛsɛ Àkùàyàn Unicode},
 				'search' => q{Ìshàwárí Ète-Gbogbogbò},
 			},
 			'ms' => {
 				'metric' => q{Èto Mɛ́tíríìkì},
 				'uksystem' => q{Èto Ìdiwɔ̀n Ɔba},
 				'ussystem' => q{Èto Ìdiwɔ̀n US},
 			},
 			'numbers' => {
 				'arab' => q{àwɔn díjítì Làrubáwá-Índíà},
 				'arabext' => q{Àwɔn Díjíìtì Lárúbáwá-Índíà fífɛ̀},
 				'armn' => q{Àwɔn nɔ́ńbà Àmɛ́níà},
 				'armnlow' => q{Àwɔn Nɔ́ńbà Kékèké ti Amɛ́ríkà},
 				'beng' => q{Àwɔn díjíìtì Báńgílà},
 				'cakm' => q{Àwɔn díjíìtì Shakma},
 				'deva' => q{Àwɔn díjììtì Defanagárì},
 				'ethi' => q{Àwɔn nɔ́ńbà Ɛtiópíìkì},
 				'fullwide' => q{Àwɔn Díjíìtì Fífɛ̀-Ɛ̀kún},
 				'geor' => q{Àwɔn nɔ́ńbà Jɔ́jíà},
 				'grek' => q{Àwɔn nɔ́ńbà Gíríìkì},
 				'greklow' => q{Àwɔn Nɔ́ńbà Gíríìkì Kékèké},
 				'gujr' => q{Àwɔn díjíìtì Gùjárátì},
 				'guru' => q{Àwɔn Díjíìtì Gurumukì},
 				'hanidec' => q{Àwɔn nɔ́ńbà Dɛ́símà Sháìnà},
 				'hans' => q{Àwɔn nɔ́ńbà Ìrɔ̀rùn ti Sháìnà},
 				'hansfin' => q{Àwɔn nɔ́ńbà Ìshúná Ìrɔ̀rùn Sháìnà},
 				'hant' => q{Àwɔn nɔ́ńbà Ìbílɛ̀ Sháìnà},
 				'hantfin' => q{Àwɔn nɔ́ńbà Ìshúná Ìbílɛ̀ Sháìnà},
 				'hebr' => q{Àwɔn nɔ́ńbà Hébérù},
 				'java' => q{Àwɔn díjíìtì Jafaniisi},
 				'jpan' => q{Àwɔn nɔ́ńbà Jápànù},
 				'jpanfin' => q{Àwɔn nɔ́ńbà Ìshúná Jàpáànù},
 				'khmr' => q{Àwɔn díjíìtì Kɛ́mɛ̀},
 				'knda' => q{Àwɔn díjíìtì kanada},
 				'laoo' => q{Àwɔn díjíìtì Láó},
 				'latn' => q{Díjíítì Ìwɔ̀ Oòrùn},
 				'mlym' => q{Àwɔn díjíìtì Málàyálámù},
 				'mtei' => q{Àwɔn díjíìtì Mete Mayeki},
 				'mymr' => q{Àwɔn díjíìtì Myánmarí},
 				'olck' => q{Àwɔn díjíìtì Shiki},
 				'orya' => q{Àwɔn díjíìtì Òdíà},
 				'roman' => q{Àwɔn díjíìtì Rómánù},
 				'romanlow' => q{Àwɔn díjíìtì Rómánù Kékeré},
 				'taml' => q{Àwɔn díjíìtì Ìbílɛ̀ Támílù},
 				'tamldec' => q{Àwɔn díjíìtì Tàmílù},
 				'telu' => q{Àwɔn díjíìtì Télúgù},
 				'thai' => q{Àwɔn díjíìtì Thai},
 				'tibt' => q{Àwɔn díjíìtì Tibetán},
 				'vaii' => q{Àwɔn díjíìtì Fai},
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
			'metric' => q{Mɛ́tíríìkì},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'script' => 'Ìshɔwɔ́kɔ̀wé: {0}',

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
			main => qr{[aáà b d eéè ɛ{ɛ́}{ɛ̀} f g {gb} h iíì j k l m n oóò ɔ{ɔ́}{ɔ̀} p r s {sh} t uúù w y]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mɛ́bì {0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mɛ́bì {0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tɛbi {0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tɛbi {0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pɛbi {0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pɛbi {0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ɛ́síbì {0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ɛ́síbì {0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(sɛ́bì {0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(sɛ́bì {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(àwɔ́n ohun),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(àwɔ́n ohun),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} ìdákan nínú ɛgbɛ̀rún),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} ìdákan nínú ɛgbɛ̀rún),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(ɛ̀yà nínú ìdá blíɔ̀nù),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(ɛ̀yà nínú ìdá blíɔ̀nù),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(maili ninu ami galɔɔnu kan),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(maili ninu ami galɔɔnu kan),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(àwɔ́n bíìtì),
						'other' => q({0} àwɔ́n bíìtì),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(àwɔ́n bíìtì),
						'other' => q({0} àwɔ́n bíìtì),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(àwɔ́n báìtì),
						'other' => q({0} àwɔ́n báìtì),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(àwɔ́n báìtì),
						'other' => q({0} àwɔ́n báìtì),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(àwɔn gígábíìtì),
						'other' => q({0} àwɔn gígábíìtì),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(àwɔn gígábíìtì),
						'other' => q({0} àwɔn gígábíìtì),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(àwɔn gígábáìtì),
						'other' => q({0} àwɔn gígábáìtì),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(àwɔn gígábáìtì),
						'other' => q({0} àwɔn gígábáìtì),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(àwɔn kílóbíìtì),
						'other' => q({0} àwɔ́n kílóbíìtì),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(àwɔn kílóbíìtì),
						'other' => q({0} àwɔ́n kílóbíìtì),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(àwɔn kílóbáìtì),
						'other' => q({0} àwɔn kílóbáìtì),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(àwɔn kílóbáìtì),
						'other' => q({0} àwɔn kílóbáìtì),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(àwɔn mégábíìtì),
						'other' => q({0} àwɔn mégábíìtì),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(àwɔn mégábíìtì),
						'other' => q({0} àwɔn mégábíìtì),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(àwɔn mégábáìtì),
						'other' => q({0} àwɔn mégábáìtì),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(àwɔn mégábáìtì),
						'other' => q({0} àwɔn mégábáìtì),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(àwɔn pɛ́tábáìtì),
						'other' => q({0} àwɔn pɛ́tábáìtì),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(àwɔn pɛ́tábáìtì),
						'other' => q({0} àwɔn pɛ́tábáìtì),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(àwɔn tɛ́rábíìtì),
						'other' => q({0} àwɔn tɛ́rábíìtì),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(àwɔn tɛ́rábíìtì),
						'other' => q({0} àwɔn tɛ́rábíìtì),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(àwɔn tɛ́rábáìtì),
						'other' => q({0} àwɔn tɛ́rábáìtì),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(àwɔn tɛ́rábáìtì),
						'other' => q({0} àwɔn tɛ́rábáìtì),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ɔ̀rúndún),
						'other' => q(ɔ̀rúndún {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ɔ̀rúndún),
						'other' => q(ɔ̀rúndún {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q(ɔj {0}),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q(ɔj {0}),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'other' => q(ɛ̀wádùn {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'other' => q(ɛ̀wádùn {0}),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(àwɔn alɛ́),
						'other' => q(àwɔn alɛ́ {0}),
						'per' => q({0}/alɛ́),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(àwɔn alɛ́),
						'other' => q(àwɔn alɛ́ {0}),
						'per' => q({0}/alɛ́),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0}ìsh àáy),
						'per' => q({0}/ìsh àáy),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0}ìsh àáy),
						'per' => q({0}/ìsh àáy),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0}/ɔsh),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0}/ɔsh),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ɔ̀dún),
						'per' => q({0} ɔd),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ɔ̀dún),
						'per' => q({0} ɔd),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(àwɔ́n wákàtí kílówáàtì ní kìlómítà ɔgɔ́rùn),
						'other' => q({0} àwɔ́n wákàtí kílówáàtì ní kìlómítà ɔgɔ́rùn),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(àwɔ́n wákàtí kílówáàtì ní kìlómítà ɔgɔ́rùn),
						'other' => q({0} àwɔ́n wákàtí kílówáàtì ní kìlómítà ɔgɔ́rùn),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ìdinwɔ̀n ayé),
						'other' => q({0} ìdinwɔ̀n ayé),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ìdinwɔ̀n ayé),
						'other' => q({0} ìdinwɔ̀n ayé),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fátɔ́ɔ̀mu),
						'other' => q({0} fátɔ́ɔ̀mù),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fátɔ́ɔ̀mu),
						'other' => q({0} fátɔ́ɔ̀mù),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(àwɔn fɔ́lɔ́ɔ̀ngì),
						'other' => q({0} àwɔn fɔ́lɔ́ɔ̀ngì),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(àwɔn fɔ́lɔ́ɔ̀ngì),
						'other' => q({0} àwɔn fɔ́lɔ́ɔ̀ngì),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandɛ́là),
						'other' => q({0} kandɛ́là),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandɛ́là),
						'other' => q({0} kandɛ́là),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumɛ́ɛ̀nì),
						'other' => q({0} lumɛ́ɛ̀nì),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumɛ́ɛ̀nì),
						'other' => q({0} lumɛ́ɛ̀nì),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(mɛtiriki tɔɔnu),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(mɛtiriki tɔɔnu),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ìmɔ́lɛ̀),
						'other' => q({0} ìmɔ́lɛ̀),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ìmɔ́lɛ̀),
						'other' => q({0} ìmɔ́lɛ̀),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(búsɛ́ɛ̀li),
						'other' => q({0} búsɛ́ɛ̀li),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(búsɛ́ɛ̀li),
						'other' => q({0} búsɛ́ɛ̀li),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(àwɔn ife),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(àwɔn ife),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(àwɔn shíbí oúnjɛ́ kékeré),
						'other' => q(àwɔn {0} àmì shíbí oúnjɛ́ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(àwɔn shíbí oúnjɛ́ kékeré),
						'other' => q(àwɔn {0} àmì shíbí oúnjɛ́ kékeré),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(shíbí oúnjɛ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(shíbí oúnjɛ kékeré),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-day' => {
						'other' => q(ɔj {0}),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q(ɔj {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0}/ìsh),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0}/ìsh),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(àwɔn alɛ́),
						'other' => q(àwɔn alɛ́{0}),
						'per' => q({0}/alɛ́),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(àwɔn alɛ́),
						'other' => q(àwɔn alɛ́{0}),
						'per' => q({0}/alɛ́),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ɔshɛ́),
						'per' => q({0}/ɔ̀shɛ̀),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ɔshɛ́),
						'per' => q({0}/ɔ̀shɛ̀),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatɔ́),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatɔ́),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lɔ́s),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lɔ́s),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ìmɔ́lɛ̀),
						'other' => q({0}ìmɔ́lɛ̀),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ìmɔ́lɛ̀),
						'other' => q({0}ìmɔ́lɛ̀),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(búsɛ́li),
						'other' => q({0}búsɛ́ɛ̀li),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(búsɛ́li),
						'other' => q({0}búsɛ́ɛ̀li),
					},
				},
				'short' => {
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(ìdákan nínú ɛgbɛ̀rún),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(ìdákan nínú ɛgbɛ̀rún),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ara/milíɔ̀nù),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ara/milíɔ̀nù),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ɛ́mbíìtì),
						'other' => q({0} ɛ́mbiì),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ɛ́mbíìtì),
						'other' => q({0} ɛ́mbiì),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ɛ́mbáìtì),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ɛ́mbáìtì),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ɔjɔ́),
						'other' => q({0} ɔj),
						'per' => q({0}/ɔj),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ɔjɔ́),
						'other' => q({0} ɔj),
						'per' => q({0}/ɔj),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ɛ̀wádùn),
						'other' => q(ɛ̀wádún {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ɛ̀wádùn),
						'other' => q(ɛ̀wádún {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ìsh),
						'other' => q({0} ìsh),
						'per' => q({0}/ìsh),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ìsh),
						'other' => q({0} ìsh),
						'per' => q({0}/ìsh),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(oshù),
						'other' => q({0} oshù),
						'per' => q({0}/oshù),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(oshù),
						'other' => q({0} oshù),
						'per' => q({0}/oshù),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(àwɔn alɛ́),
						'other' => q(àwɔn alɛ́ {0}),
						'per' => q({0}/alɛ́),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(àwɔn alɛ́),
						'other' => q(àwɔn alɛ́ {0}),
						'per' => q({0}/alɛ́),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ìsh àáy),
						'other' => q({0} ìsh àáy),
						'per' => q({0} ìsh àáy),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ìsh àáy),
						'other' => q({0} ìsh àáy),
						'per' => q({0} ìsh àáy),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ɔsh),
						'other' => q({0} ɔsh),
						'per' => q({0}/ɔshɛ̀),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ɔsh),
						'other' => q({0} ɔsh),
						'per' => q({0}/ɔshɛ̀),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ɔd),
						'other' => q({0} ɔd),
						'per' => q({0}/ɔd),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ɔd),
						'other' => q({0} ɔd),
						'per' => q({0}/ɔd),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(KWh lɔ́rí 100km),
						'other' => q({0} KWh lɔ́rí 100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(KWh lɔ́rí 100km),
						'other' => q({0} KWh lɔ́rí 100km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dɔ́ɔ̀tì),
						'other' => q({0} dɔ́ɔ̀tì),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dɔ́ɔ̀tì),
						'other' => q({0} dɔ́ɔ̀tì),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(àmì ìdínwɔ̀n ayé),
						'other' => q({0} àmì ìdínwɔ̀n ayé),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(àmì ìdínwɔ̀n ayé),
						'other' => q({0} àmì ìdínwɔ̀n ayé),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fátɔ́mù),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fátɔ́mù),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fɔ́lɔ́ɔ̀ngì),
						'other' => q({0} fɔ́),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fɔ́lɔ́ɔ̀ngì),
						'other' => q({0} fɔ́),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandɛ́là),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandɛ́là),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(àmì lumɛ́ɛ̀nì),
						'other' => q({0} Lúmɛ́nì),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(àmì lumɛ́ɛ̀nì),
						'other' => q({0} Lúmɛ́nì),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ìmɔ́lɛ̀),
						'other' => q({0} ìmɔ́lɛ̀),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ìmɔ́lɛ̀),
						'other' => q({0} ìmɔ́lɛ̀),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(Búsɛ́ɛ̀li),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(Búsɛ́ɛ̀li),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(shíbí oúnjɛ́ kékeré),
						'other' => q({0} shíbí oúnjɛ́ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(shíbí oúnjɛ́ kékeré),
						'other' => q({0} shíbí oúnjɛ́ kékeré),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(àmì oúnjɛ kékeré),
						'other' => q({0} àmì oúnjɛ kékeré),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(àmì oúnjɛ kékeré),
						'other' => q({0} àmì oúnjɛ kékeré),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dírɔ́pù),
						'other' => q({0} dírɔ́pù),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dírɔ́pù),
						'other' => q({0} dírɔ́pù),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(píńshì),
						'other' => q({0} píńshì),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(píńshì),
						'other' => q({0} píńshì),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Bɛ́ɛ̀ni |N|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Bɛ́ɛ̀kɔ́|K)$' }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'other' => '0 ɛgbɛ̀rún',
				},
				'10000' => {
					'other' => '00 ɛgbɛ̀rún',
				},
				'100000' => {
					'other' => '000 ɛgbɛ̀rún',
				},
				'1000000' => {
					'other' => '0 mílíɔ̀nù',
				},
				'10000000' => {
					'other' => '00 mílíɔ̀nù',
				},
				'100000000' => {
					'other' => '000 mílíɔ̀nù',
				},
				'1000000000' => {
					'other' => '0 bilíɔ̀nù',
				},
				'10000000000' => {
					'other' => '00 bilíɔ̀nù',
				},
				'100000000000' => {
					'other' => '000 bilíɔ̀nù',
				},
				'1000000000000' => {
					'other' => '0 tiriliɔ̀nù',
				},
				'10000000000000' => {
					'other' => '00 tiriliɔ̀nù',
				},
				'100000000000000' => {
					'other' => '000 tiriliɔ̀nù',
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
				'currency' => q(Diami ti Awon Orílɛ́ède Arabu),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lɛ́ɛ̀kì Àlìbáníà),
				'other' => q(lɛ́kè Àlìbéníà),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dírààmù Àmɛ́níà),
			},
		},
		'ANG' => {
			display_name => {
				'other' => q(àwɔn gílídà Netherlands Antillean),
			},
		},
		'AOA' => {
			display_name => {
				'other' => q(àwɔn kíwánsà Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Pɛ́sò Agɛntínà),
				'other' => q(àwɔn pɛ́sò Agɛntínà),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dɔla ti Orílɛ́ède Ástràlìá),
			},
		},
		'AWG' => {
			display_name => {
				'other' => q(àwɔn fuloríìnì Àrúbà),
			},
		},
		'BAM' => {
			display_name => {
				'other' => q(àwɔn àmi Yíyípadà Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dɔ́là Bábádɔ̀ɔ̀sì),
				'other' => q(àwɔn dɔ́là Bábádɔ̀ɔ̀sì),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Tákà Báńgíládɛ̀ɛ̀shì),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Owó Lɛ́fì Bɔ̀lìgéríà),
				'other' => q(Lɛ́fà Bɔ̀lìgéríà),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dina ti Orílɛ́ède Báránì),
			},
		},
		'BIF' => {
			display_name => {
				'other' => q(àwɔn faransi Bùùrúndì),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dɔ́là Bɛ̀múdà),
				'other' => q(àwɔ́n dɔ́là Bɛ̀múdà),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dɔ́là Bùrùnéì),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bɔlifiánò Bɔ̀lífíà),
				'other' => q(àwɔn bɔlifiánò Bɔ̀lífíà),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Owó ti Orílɛ̀-èdè Brazil),
				'other' => q(Awon owó ti Orílɛ̀-èdè Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dɔ́là Bàhámà),
				'other' => q(àwɔn dɔ́là Bàhámà),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ìngɔ́tírɔ̀mù Bútàànì),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Bɔ̀tìsúwánà),
				'other' => q(àwɔn pula Bɔ̀tìsúwánà),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rɔ́bù Bɛ̀lárùùsì),
				'other' => q(àwɔn rɔ́bù Bɛ̀lárùùsì),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dɔ́là Bɛ̀lísè),
				'other' => q(àwɔn Dɔ́là Bɛ́lìsè),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dɔ́là Kánádà),
				'other' => q(àwɔn dɔ́là Kánádà),
			},
		},
		'CDF' => {
			display_name => {
				'other' => q(àwɔn firanki Kongo),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Pɛ́sò Shílè),
				'other' => q(àwɔn pɛ́sò Shílè),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Reminibi ti Orílɛ́ède sháínà),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Pɛ́sò Kòlóḿbíà),
				'other' => q(àwɔn pɛ́sò Kòlóḿbíà),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kólɔ́ɔ̀nì Kosita Ríkà),
				'other' => q(àwɔ́n kólɔ́ɔ̀nì Kosita Ríkà),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Pɛ́sò Yíyípadà Kúbà),
				'other' => q(àwɔn pɛ́sò yíyípadà Kúbà),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Pɛ́sò Kúbà),
			},
		},
		'CVE' => {
			display_name => {
				'other' => q(àwɔn èsìkúdò Kapú Faadì),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Shɛ́ɛ̀kì),
				'other' => q(àwɔn koruna Shɛ́ɛ̀kì),
			},
		},
		'DJF' => {
			display_name => {
				'other' => q(àwɔn faransi Dibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kírónì Dáníshì),
				'other' => q(Kírònà Dáníìshì),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Pɛ́sò Dòníníkà),
				'other' => q(àwɔn pɛ́sò Dòníníkà),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dina ti Orílɛ́ède Àlùgèríánì),
				'other' => q(àwɔn dínà Àlùgèríánì),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(pɔɔn ti Orílɛ́ède Egipiti),
				'other' => q(àwɔn pɔ́n-ún Ejipítì),
			},
		},
		'ERN' => {
			display_name => {
				'other' => q(àwɔn nakifasì Eritira),
			},
		},
		'ETB' => {
			display_name => {
				'other' => q(àwɔn báà Etópíà),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dɔ́là Fíjì),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pɔ́n-ùn Erékùsù Falkland),
				'other' => q(àwɔn Pɔ́n-ùn Erékùsù Falkland [ Pɔ́n-ùn Erékùsù Falkland ] 1.23 Pɔ́n-ùn Erékùsù Falkland 0.00 pɔ́n-ùn Erékùsù Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pɔ́n-ùn ti Orilɛ̀-èdè Gɛ̀ɛ́sì),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lárì Jɔ́jíà),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(shidi ti Orílɛ́ède Gana),
			},
		},
		'GHS' => {
			display_name => {
				'other' => q(àwɔn sídì Gana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pɔ́n-ùn Gibúrátà),
				'other' => q(àwɔn pɔ́n-ùn Gibúrátà),
			},
		},
		'GMD' => {
			display_name => {
				'other' => q(àwɔn dalasi Gamibia),
			},
		},
		'GNF' => {
			display_name => {
				'other' => q(àwɔn fírànkì Gínì),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faransi ti Orílɛ́ède Gini),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Kúɛ́tísààlì Guatimílà),
				'other' => q(àwɔn kúɛ́tísààlì Guatimílà),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dɔ́là Gùyánà),
				'other' => q(àwɔn dɔ́là Gùyánà),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dɔ́là Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lɛmipírà Ɔ́ńdúrà),
				'other' => q(àwɔn Lɛmipírà Ɔ́ńdúrà),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kúnà Kúróshíà),
				'other' => q(àwɔn kúnà Kúróshíà),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gɔ́dì Àítì),
				'other' => q(àwɔn gɔ́dì Àítì),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Fɔ́ríǹtì Hɔ̀ngérí),
				'other' => q(àwɔn fɔ́ríǹtì Hɔ̀ngérí),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Shékélì Tuntun Ísírɛ̀ɛ̀lì),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi ti Orílɛ́ède Indina),
			},
		},
		'ISK' => {
			display_name => {
				'other' => q(kórónɔ̀ Áílándíìkì),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dɔ́là Jàmáíkà),
				'other' => q(àwɔn dɔ́là Jàmáíkà),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dínárì Jɔ́dàànì),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ti Orílɛ́ède Japani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shiili Kenya),
				'other' => q(àwɔ́n shiili Kenya),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Ráyò Kàm̀bɔ́díà),
			},
		},
		'KMF' => {
			display_name => {
				'other' => q(àwɔn faransi Komori),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Wɔ́ɔ̀nù Àríwá Kòríà),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Wɔ́ɔ̀nù Gúúsù Kòríà),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dɔ́là Erékùsù Cayman),
				'other' => q(àwɔn dɔ́là Erékùsù Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tɛngé Kasakísítàànì),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pɔ́n-ùn Lebanese),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dɔla Liberia),
				'other' => q(àwɔn dɔla Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ti Orílɛ́ède Lesoto),
				'other' => q(Lótì ti Lɛ̀sótò),
			},
		},
		'LYD' => {
			display_name => {
				'other' => q(àwɔn dínà Líbíyà),
			},
		},
		'MAD' => {
			display_name => {
				'other' => q(àwɔn dírámì Morokò),
			},
		},
		'MGA' => {
			display_name => {
				'other' => q(àwɔn faransi Malagasi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dɛ́nà Masidóníà),
				'other' => q(dɛ́nàrì Masidóníà),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya ti Orílɛ́ède Maritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya ti Orílɛ́ède Maritania),
			},
		},
		'MUR' => {
			display_name => {
				'other' => q(àwɔn rupi Maritusi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rúfìyá Mɔ̀lìdífà),
			},
		},
		'MWK' => {
			display_name => {
				'other' => q(àwɔn kásà Màláwì),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pɛ́sò Mɛ́síkò),
				'other' => q(àwɔn pɛ́sò Mɛ́síkò),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ríngìtì Màléshíà),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metika ti Orílɛ́ède Mosamibiki),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mɛ́tíkààlì Mòsáḿbíìkì),
				'other' => q(àwɔn mɛ́tíkààlì Mòsáḿbíìkì),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dɔla Namibíà),
				'other' => q(àwɔn dɔla Namibíà),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Kɔ̀dóbà Naikarágúà),
				'other' => q(àwɔn kɔ̀dóbà Naikarágúà),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(kórónì Nɔ́wè),
				'other' => q(kórónà Nɔ́wè),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rúpìì Nɛ̵́pààlì),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dɔ́là New Zealand),
			},
		},
		'PAB' => {
			display_name => {
				'other' => q(àwɔn bálíbóà Pànámà),
			},
		},
		'PEN' => {
			display_name => {
				'other' => q(àwɔn sólì Pèrúù),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Sílɔ̀tì Pɔ́líshì),
				'other' => q(àwɔn sílɔ̀tì Pɔ́líshì),
			},
		},
		'PYG' => {
			display_name => {
				'other' => q(àwɔn gúáránì Párágúwè),
			},
		},
		'RSD' => {
			display_name => {
				'other' => q(àwɔn dínárì Sàbíà),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Owó ruble ti ilɛ̀ Rɔ́shíà),
			},
		},
		'RWF' => {
			display_name => {
				'other' => q(àwɔn faransi Ruwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riya ti Orílɛ́ède Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dɔ́là Erékùsù Sɔ́lómɔ́nì),
			},
		},
		'SCR' => {
			display_name => {
				'other' => q(àwɔ́n rúpì Sayiselesi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pɔ́n-ùn Sùdáànì),
				'other' => q(àwɔn pɔ́n-ùn Sùdáànì),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pɔɔun ti Orílɛ́ède Sudani),
			},
		},
		'SEK' => {
			display_name => {
				'other' => q(Kòrónɔ̀ Súwídìn),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dɔ́là Síngápɔ̀),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pɔ́n-un Elena),
				'other' => q(àwɔn pɔ́n-un Elena),
			},
		},
		'SLE' => {
			display_name => {
				'other' => q(àwɔn líónì Sira Líonì),
			},
		},
		'SLL' => {
			display_name => {
				'other' => q(àwɔn líónì Sira Líonì \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shílè Somali),
				'other' => q(àwɔ́n shílè Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dɔ́là Súrínámì),
				'other' => q(àwɔn Dɔ́là Súrínámì),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pɔ́n-un Gúúsù Sùdáànì),
				'other' => q(àwɔn pɔ́n-un Gúúsù Sùdáànì),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobira ti Orílɛ́ède Sao tome Ati Pirisipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dɔbíra Sao tome àti Pirisipi),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pɔ́n-ùn Sírìà),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Mánààtì Tɔkimɛnístàànì),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dínà Tunishíà),
				'other' => q(àwɔn dínà Tunishíà),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lírà Tɔ́kì),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dɔ́là Trinidad & Tobago),
				'other' => q(àwɔn dɔ́là Trinidad àti Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dɔ́là Tàìwánì Tuntun),
			},
		},
		'TZS' => {
			display_name => {
				'other' => q(àwɔn shile Tansania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ɔrifiníyà Yukiréníà),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shile Uganda),
				'other' => q(àwɔn shile Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dɔ́là),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Pɛ́sò Úrúgúwè),
				'other' => q(àwɔn pɛ́sò Úrúgúwè),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sómú Usibɛkísítàànì),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bɔ̀lífà Fɛnɛsuɛ́là),
				'other' => q(àwɔn bɔ̀lífà Fɛnɛsuɛ́là),
			},
		},
		'XAF' => {
			display_name => {
				'other' => q(àwɔn firanki àárín Afíríkà),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dɔ́là Ilà Oòrùn Karíbíà),
				'other' => q(àwɔn dɔ́là Ilà Oòrùn Karíbíà),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faransì ìwɔ̀-oorùn Afíríkà),
				'other' => q(àwɔn faransì ìwɔ̀-oorùn Afíríkà),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(owóníná àìmɔ̀),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Ráyò Yɛ́mɛ̀nì),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kawasha ti Orílɛ́ède Saabia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'other' => q(àwɔn kàwasà Sámbíà),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dɔla ti Orílɛ́ède Siibabuwe),
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
					wide => {
						nonleap => [
							'Oshù Shɛ́rɛ́',
							'Oshù Èrèlè',
							'Oshù Ɛrɛ̀nà',
							'Oshù Ìgbé',
							'Oshù Ɛ̀bibi',
							'Oshù Òkúdu',
							'Oshù Agɛmɔ',
							'Oshù Ògún',
							'Oshù Owewe',
							'Oshù Ɔ̀wàrà',
							'Oshù Bélú',
							'Oshù Ɔ̀pɛ̀'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Oshù Shɛ́rɛ́',
							'Oshù Èrèlè',
							'Oshù Ɛrɛ̀nà',
							'Oshù Ìgbé',
							'Oshù Ɛ̀bibi',
							'Oshù Òkúdu',
							'Oshù Agɛmɔ',
							'Oshù Ògún',
							'Oshù Owewe',
							'Oshù Ɔ̀wàrà',
							'Oshù Bélú',
							'Oshù Ɔ̀pɛ̀'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'S',
							'È',
							'Ɛ',
							'Ì',
							'Ɛ̀',
							'Ò',
							'A',
							'Ò',
							'O',
							'Ɔ̀',
							'B',
							'Ɔ̀'
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
						mon => 'Ajé',
						tue => 'Ìsɛ́gun',
						wed => 'Ɔjɔ́rú',
						thu => 'Ɔjɔ́bɔ',
						fri => 'Ɛtì',
						sat => 'Àbámɛ́ta',
						sun => 'Àìkú'
					},
					short => {
						mon => 'Ajé',
						tue => 'Ìsɛ́gun',
						wed => 'Ɔjɔ́rú',
						thu => 'Ɔjɔ́bɔ',
						fri => 'Ɛtì',
						sat => 'Àbámɛ́ta',
						sun => 'Àìkú'
					},
					wide => {
						mon => 'Ɔjɔ́ Ajé',
						tue => 'Ɔjɔ́ Ìsɛ́gun',
						wed => 'Ɔjɔ́rú',
						thu => 'Ɔjɔ́bɔ',
						fri => 'Ɔjɔ́ Ɛtì',
						sat => 'Ɔjɔ́ Àbámɛ́ta',
						sun => 'Ɔjɔ́ Àìkú'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Ajé',
						tue => 'Ìsɛ́gun',
						wed => 'Ɔjɔ́rú',
						thu => 'Ɔjɔ́bɔ',
						fri => 'Ɛtì',
						sat => 'Àbámɛ́ta',
						sun => 'Àìkú'
					},
					narrow => {
						mon => 'A',
						tue => 'Ì',
						wed => 'Ɔ',
						thu => 'Ɔ',
						fri => 'Ɛ',
						sat => 'À',
						sun => 'À'
					},
					short => {
						mon => 'Ajé',
						tue => 'Ìsɛ́gun',
						wed => 'Ɔjɔ́rú',
						thu => 'Ɔjɔ́bɔ',
						fri => 'Ɛtì',
						sat => 'Àbámɛ́ta',
						sun => 'Àìkú'
					},
					wide => {
						mon => 'Ajé',
						tue => 'Ìsɛ́gun',
						wed => 'Ɔjɔ́rú',
						thu => 'Ɔjɔ́bɔ',
						fri => 'Ɛtì',
						sat => 'Àbámɛ́ta',
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
						2 => 'Kɛta',
						3 => 'Kɛin'
					},
					wide => {0 => 'Ìdámɛ́rin kíní',
						1 => 'Ìdámɛ́rin Kejì',
						2 => 'Ìdámɛ́rin Kɛta',
						3 => 'Ìdámɛ́rin Kɛrin'
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
					'am' => q{Àárɔ̀},
					'pm' => q{Ɔ̀sán},
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
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Àkókò ojúmɔmɔ),
		'Africa_Western' => {
			long => {
				'daylight' => q#Àkókò Ìwɔ̀-Oòrùn Ooru Afírikà#,
				'generic' => q#Àkókò Ìwɔ̀-Oòrùn Afírikà#,
				'standard' => q#Àkókò Ìwɔ̀-Oòrùn Àfɛnukò Afírikà#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔ́ Alásíkà#,
				'generic' => q#Àkókò Alásíkà#,
				'standard' => q#Àkókò Àfɛnukò Alásíkà#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Àkókò Oru Amásɔ́nì#,
				'generic' => q#Àkókò Amásɔ́nì#,
				'standard' => q#Àkókò Afɛnukò Amásɔ́nì#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#ìlú Ankɔ́réèjì#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#ìlú Báhì Bándɛ́rásì#,
		},
		'America/Barbados' => {
			exemplarCity => q#ìlú Bábádɔ́ɔ̀sì#,
		},
		'America/Belize' => {
			exemplarCity => q#ìlú Bɛ̀líìsì#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ìlú Blank Sabulɔ́ɔ̀nì#,
		},
		'America/Boise' => {
			exemplarCity => q#ìlú Bɔ́isè#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ìlú Shihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#ìlú àtikɔkàn#,
		},
		'America/Creston' => {
			exemplarCity => q#ìlú Kírɛstɔ́ɔ̀nù#,
		},
		'America/Curacao' => {
			exemplarCity => q#ìlú Kurashao#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#ìlú nɔ́sì#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#ìlú Marɛ́ngo#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#ìlú Montisɛ́lò#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#ìlú Kíralɛ́ndáikì#,
		},
		'America/Marigot' => {
			exemplarCity => q#ìlú Marigɔ́ɔ̀tì#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#ìlú Mɛ́síkò#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ìlú Mikulɔ́nì#,
		},
		'America/St_Johns' => {
			exemplarCity => q#ìlú St Jɔ́ɔ̀nù#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#ìlú St Tɔ́màsì#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ìlú Súfítù Kɔ̀rentì#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Akókò àárín gbùngbùn ojúmɔmɔ#,
				'generic' => q#àkókò àárín gbùngbùn#,
				'standard' => q#àkókò asiko àárín gbùngbùn#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Àkókò ojúmɔmɔ Ìhà Ìlà Oòrun#,
				'generic' => q#Àkókò ìhà ìlà oòrùn#,
				'standard' => q#Akókò Àsikò Ìha Ìla Oòrùn#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Àkókò ojúmɔmɔ Ori-òkè#,
				'generic' => q#Àkókò òkè#,
				'standard' => q#Àkókò asiko òkè#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Àkókò Ìyálɛta Pàsífíìkì#,
				'generic' => q#Àkókò Pàsífíìkì#,
				'standard' => q#Àkókò àsikò Pàsífíìkì#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Apia#,
				'generic' => q#Àkókò Apia#,
				'standard' => q#Àkókò Àfɛnukò Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Arabia#,
				'generic' => q#Àkókò Arabia#,
				'standard' => q#Àkókò Àfɛnukò Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Aago Soma Argentina#,
				'generic' => q#Aago Ajɛntìnà#,
				'standard' => q#Aago àsìkò Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Àkókò Oru Iwɔ́-oòrùn Ajɛ́ntínà#,
				'generic' => q#Àkókò Iwɔ́-oòrùn Ajɛ́ntínà#,
				'standard' => q#Àkókò Iwɔ́-oòrùn Àfɛnukò Ajɛ́ntínà#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Arabia#,
				'generic' => q#Àkókò Armenia#,
				'standard' => q#Àkókò Àfɛnukò Armenia#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Àkókò Ìyálɛta Àtìláńtíìkì#,
				'generic' => q#Àkókò Àtìláńtíìkì#,
				'standard' => q#Àkókò àsikò Àtìláńtíìkì#,
			},
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#ìlú Bɛ̀múdà#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Ààrin Gùngùn Australia#,
				'generic' => q#Àkókò Ààrin Gùngùn Australia#,
				'standard' => q#Àkókò Àfɛnukò Ààrin Gùngùn Australia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Ààrin Gùngùn Ìwɔ̀-Oòrùn Australia#,
				'generic' => q#Àkókò Ààrin Gùngùn Ìwɔ̀-Oòrùn Australia#,
				'standard' => q#Àkókò Àfɛnukò Ààrin Gùngùn Ìwɔ̀-Oòrùn Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Ìlà-Oòrùn Australia#,
				'generic' => q#Àkókò Ìlà-Oòrùn Australia#,
				'standard' => q#Àkókò Àfɛnukò Ìlà-Oòrùn Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Ìwɔ̀-Oòrùn Australia#,
				'generic' => q#Àkókò Ìwɔ̀-Oòrùn Australia#,
				'standard' => q#Àkókò Àfɛnukò Ìwɔ̀-Oòrùn Australia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Azerbaijan#,
				'generic' => q#Àkókò Azerbaijan#,
				'standard' => q#Àkókò Àfɛnukò Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Àkókò Ooru Ásɔ́sì#,
				'generic' => q#Àkókò Ásɔ́sì#,
				'standard' => q#Àkókò Àfɛnukò Ásɔ́sì#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Bangladesh#,
				'generic' => q#Àkókò Bangladesh#,
				'standard' => q#Àkókò Àfɛnukò Bangladesh#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Àkókò Ɛ̀rún Képú Fáàdì#,
				'generic' => q#Àkókò Képú Fáàdì#,
				'standard' => q#Àkókò Àfɛnukò Képú Fáàdì#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Àkókò Àfɛnukò Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Chatam#,
				'generic' => q#Àkókò Chatam#,
				'standard' => q#Àkókò Àfɛnukò Chatam#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Àkókò Oru Shílè#,
				'generic' => q#Àkókò Shílè#,
				'standard' => q#Àkókò Àfɛnukò Shílè#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Sháínà#,
				'generic' => q#Àkókò Sháínà#,
				'standard' => q#Àkókò Ìfɛnukòsí Sháínà#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Àkókò Àwɔn Erékùsù Cocos#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Àkókò Ilaji Sɔma Àwɔn Erekusu Kuuku#,
				'generic' => q#Àkókò Àwɔn Erekusu Kuuku#,
				'standard' => q#Àkókò Àfɛnukò Àwɔn Erekusu Kuuku#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Kúbà#,
				'generic' => q#Àkókò Kúbà#,
				'standard' => q#Àkókò Àfɛnukò Kúbà#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Àpapɔ̀ Àkókò Àgbáyé#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ìlú Àìmɔ̀#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Àkókò Àfɛnukò Airiisi#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Gɛɛsi#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Àkókò Àárin Sɔmà Europe#,
				'generic' => q#Àkókò Àárin Europe#,
				'standard' => q#Àkókò Àárin àsikò Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Ìha Ìlà Oòrùn Europe#,
				'generic' => q#Àkókò Ìhà Ìlà Oòrùn Europe#,
				'standard' => q#Àkókò àsikò Ìhà Ìlà Oòrùn Europe#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Ìhà Ìwɔ Oòrùn Europe#,
				'generic' => q#Àkókò Ìwɔ Oòrùn Europe#,
				'standard' => q#Àkókò àsikò Ìwɔ Oòrùn Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Àkókò Ooru Etíkun Fókílándì#,
				'generic' => q#Àkókò Fókílándì#,
				'standard' => q#Àkókò Àfɛnukò Etíkun Fókílándì#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Àkókò Sɔma Fiji#,
				'generic' => q#Àkókò Fiji#,
				'standard' => q#Àkókò Àfɛnukò Fiji#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Georgia#,
				'generic' => q#Àkókò Georgia#,
				'standard' => q#Àkókò Àfɛnukò Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Àkókò Àwɔn Erekusu Gilibati#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Àkókò ìgbà Ooru Greenland#,
				'generic' => q#Àkókò Ìlà oorùn Greenland#,
				'standard' => q#Àkókò Ìwɔ̀ Ìfɛnukò oorùn Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Àkókò Àfɛnukò Ìgba Oòru Greenland#,
				'generic' => q#Àkókò Ìwɔ̀ oorùn Greenland#,
				'standard' => q#Àkókò Àfɛnukò Ìwɔ̀ Oòrùn Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Àkókò Àfɛnukò Gulf#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Hawaii-Aleutian#,
				'generic' => q#Àkókò Hawaii-Aleutian#,
				'standard' => q#Àkókò Àfɛnukò Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Hong Kong#,
				'generic' => q#Àkókò Hong Kong#,
				'standard' => q#Àkókò Ìfɛnukòsí Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Hofidi#,
				'generic' => q#Àkókò Hofidi#,
				'standard' => q#Àkókò Ìfɛnukòsí Hofidi#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Àkókò Àfɛnukò India#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Àkókò Ìwɔ̀ oorùn Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Irani#,
				'generic' => q#Àkókò Irani#,
				'standard' => q#Àkókò Àfɛnukò Irani#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Íkúsíkì#,
				'generic' => q#Àkókò Íkósíkì#,
				'standard' => q#Àkókò Àfɛnukò Íkósíkì#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Israel#,
				'generic' => q#Àkókò Israel#,
				'standard' => q#Àkókò Àfɛnukò Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Japan#,
				'generic' => q#Àkókò Japan#,
				'standard' => q#Àkókò Ìfɛnukòsí Japan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Àkókò Ìwɔ̀-Oòrùn Kasasitáànì#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Koria#,
				'generic' => q#Àkókò Koria#,
				'standard' => q#Àkókò Ìfɛnukòsí Koria#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Krasinoyasiki#,
				'generic' => q#Àkókò Krasinoyasiki#,
				'standard' => q#Àkókò Àfɛnukò Krasinoyasiki#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Àkókò Àwɔn Erekusu Laini#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Lord Howe#,
				'generic' => q#Àkókò Lord Howe#,
				'standard' => q#Àkókò Àfɛnukò Lord Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Magadani#,
				'generic' => q#Àkókò Magadani#,
				'standard' => q#Àkókò Àfɛnukò Magadani#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Àkókò Àwɔn Erekusu Masaali#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Àkókò Ooru Máríshúshì#,
				'generic' => q#Àkókò Máríshúshì#,
				'standard' => q#Àkókò Àfɛnukò Máríshúshì#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Pásífíìkì Mɛ́síkò#,
				'generic' => q#Àkókò Pásífíìkì Mɛ́shíkò#,
				'standard' => q#Àkókò Àfɛnukò Pásífíìkì Mɛ́síkò#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Ulaanbaatar#,
				'generic' => q#Àkókò Ulaanbaatar#,
				'standard' => q#Àkókò Ìfɛnukòsí Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Mosiko#,
				'generic' => q#Àkókò Mosiko#,
				'standard' => q#Àkókò Àfɛnukò Mosiko#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Àkókò Sɔma Kalidonia Tuntun#,
				'generic' => q#Àkókò Kalidonia Tuntun#,
				'standard' => q#Àkókò Àfɛnukò Kalidonia Tuntun#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ New Zealand#,
				'generic' => q#Àkókò New Zealand#,
				'standard' => q#Àkókò Àfɛnukò New zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Newfoundland#,
				'generic' => q#Àkókò Newfoundland#,
				'standard' => q#Àkókò Àfɛnukò Newfoundland#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Erékùsù Norfolk#,
				'generic' => q#Àkókò Erékùsù Norfolk#,
				'standard' => q#Àkókò Àfɛnukò Erékùsù Norfolk#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Noforibisiki#,
				'generic' => q#Àkókò Nofosibiriski#,
				'standard' => q#Àkókò Àfɛnukò Nofosibiriki#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Omisiki#,
				'generic' => q#Àkókò Omisiki#,
				'standard' => q#Àkókò Àfɛnukò Omisiki#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Pakistani#,
				'generic' => q#Àkókò Pakistani#,
				'standard' => q#Àkókò Àfɛnukò Pakistani#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Àkókò Ooru Párágúwè#,
				'generic' => q#Àkókò Párágúwè#,
				'standard' => q#Àkókò Àfɛnukò Párágúwè#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Àkókò Ooru Pérù#,
				'generic' => q#Àkókò Pérù#,
				'standard' => q#Àkókò Àfɛnukò Pérù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Filipininni#,
				'generic' => q#Àkókò Filipininni#,
				'standard' => q#Àkókò Àfɛnukò Filipininni#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Àkókò Àwɔn Erékùsù Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Pierre & Miquelon#,
				'generic' => q#Àkókò Pierre & Miquelon#,
				'standard' => q#Àkókò Àfɛnukò Pierre & Miquelon#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Àkókò Rɛ́yúníɔ́nì#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Sakhalin#,
				'generic' => q#Àkókò Sakhalin#,
				'standard' => q#Àkókò Àfɛnukò Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Samoa#,
				'generic' => q#Àkókò Samoa#,
				'standard' => q#Àkókò Àfɛnukò Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Àkókò Sèshɛ́ɛ̀lì#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Àkókò Àfɛnukò Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Àkókò Àwɔn Erekusu Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Àkókò Gúsù Jɔ́jíà#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Àkókò Ojúmɔmɔ Taipei#,
				'generic' => q#Àkókò Taipei#,
				'standard' => q#Àkókò Ìfɛnukòsí Taipei#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Tonga#,
				'generic' => q#Àkókò Tonga#,
				'standard' => q#Àkókò Àfɛnukò Tonga#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Turkmenistani#,
				'generic' => q#Àkókò Turkimenistani#,
				'standard' => q#Àkókò Àfɛnukò Turkimenistani#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Aago Soma Uruguay#,
				'generic' => q#Aago Uruguay#,
				'standard' => q#Àkókò Àfɛnukò Úrúgúwè#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Usibekistani#,
				'generic' => q#Àkókò Usibekistani#,
				'standard' => q#Àkókò Àfɛnukò Usibekistani#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Fanuatu#,
				'generic' => q#Àkókò Fanuatu#,
				'standard' => q#Àkókò Àfɛnukò Fanuatu#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Filadifositoki#,
				'generic' => q#Àkókò Filadifositoki#,
				'standard' => q#Àkókò Àfɛnukò Filadifositoki#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Foligogiradi#,
				'generic' => q#Àkókò Foligogiradi#,
				'standard' => q#Àkókò Àfɛnukò Foligogiradi#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Yatutsk#,
				'generic' => q#Àkókò Yatutsk#,
				'standard' => q#Àkókò Àfɛnukò Yatutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Àkókò Sɔmà Yekaterinburg#,
				'generic' => q#Àkókò Yekaterinburg#,
				'standard' => q#Àkókò Àfɛnukò Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Àkókò Yúkɔ́nì#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
