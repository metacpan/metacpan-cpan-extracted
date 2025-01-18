=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bal::Latn - Package for language Baluchi

=cut

package Locale::CLDR::Locales::Bal::Latn;
# This file auto generated from Data\common\main\bal_Latn.xml
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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Apar',
 				'ab' => 'Abkházi',
 				'af' => 'Aprikái',
 				'agq' => 'Agem',
 				'ak' => 'Akan',
 				'am' => 'Amhari',
 				'an' => 'Aragóni',
 				'ann' => 'Obóló',
 				'apc' => 'Latwiái Arabi',
 				'ar' => 'Arabi',
 				'ar_001' => 'Arabi (Donyá)',
 				'arn' => 'Mapuche',
 				'as' => 'Asámi',
 				'asa' => 'Asu',
 				'ast' => 'Asturiái',
 				'az' => 'Ázerbáijáni',
 				'ba' => 'Bashkar',
 				'bal' => 'Balóchi',
 				'bal_Latn' => 'Balóchi (Látin)',
 				'bas' => 'Basá',
 				'be' => 'Bélárusi',
 				'bem' => 'Bembá',
 				'bew' => 'Betawi',
 				'bez' => 'Bená',
 				'bg' => 'Bolgáriái',
 				'bgc' => 'Haryánui',
 				'bgn' => 'Balóchi (Róbarkati)',
 				'bho' => 'Bójpuri',
 				'blo' => 'Ani',
 				'blt' => 'Tái Dam',
 				'bm' => 'Bambará',
 				'bn' => 'Bangáli',
 				'bo' => 'Tebbati',
 				'br' => 'Brétón',
 				'brx' => 'Bodó',
 				'bs' => 'Busniái',
 				'bss' => 'Akuse',
 				'byn' => 'Blin',
 				'ca' => 'Katálan',
 				'cad' => 'Kaddó-kad',
 				'cch' => 'Atsam',
 				'ccp' => 'Chakmá',
 				'ce' => 'Chechen',
 				'ceb' => 'Chebuánó',
 				'cgg' => 'Chigá',
 				'cho' => 'Choktaw',
 				'chr' => 'Cheruki',
 				'cic' => 'Chekkásaw',
 				'ckb' => 'Myáni Kordi',
 				'ckb@alt=menu' => 'Myáni Kordi- ckb',
 				'ckb@alt=variant' => 'Myáni Kordi-men',
 				'co' => 'Korsiki',
 				'cs' => 'Chek',
 				'csw' => 'Swampi Kri',
 				'cu' => 'Charch Sláwi',
 				'cv' => 'Chuwash',
 				'cy' => 'Wéli',
 				'da' => 'Denmárki',
 				'dav' => 'Táitá',
 				'de' => 'Jarman',
 				'dje' => 'Zarmah',
 				'doi' => 'Dogri',
 				'dsb' => 'Láwar Sorbi',
 				'dua' => 'Duálá',
 				'dv' => 'Diwéhi',
 				'dyo' => 'Jólá-Póni',
 				'dz' => 'Dzongká',
 				'ebu' => 'Embó',
 				'ee' => 'Ewe',
 				'el' => 'Yunáni',
 				'en' => 'Engrézi',
 				'en_CA' => 'Engrézi (Kaynadhá)',
 				'eo' => 'Esperántu',
 				'es' => 'Espini',
 				'es_419' => 'Espini (Látini Amriká)',
 				'es_MX' => 'Espini (Meksikó)',
 				'et' => 'Estóniái',
 				'eu' => 'Bask',
 				'ewo' => 'Ewondó',
 				'fa' => 'Pársi',
 				'fa_AF' => 'Pársi (AF)',
 				'ff' => 'Pulá',
 				'fi' => 'Fenlándi',
 				'fil' => 'Pelpini',
 				'fo' => 'Paróese',
 				'fr' => 'Paránsi',
 				'fr_CA' => 'Paránsi (Kaynadhá)',
 				'frc' => 'Kájon Pránsi',
 				'frr' => 'Shemáli Prési',
 				'fur' => 'Priuli',
 				'fy' => 'Ferisi (Róbarkati)',
 				'ga' => 'Áeri',
 				'gaa' => 'Gaa',
 				'gd' => 'Eskáti Géli',
 				'gez' => 'Géz',
 				'gl' => 'Galéki',
 				'gn' => 'Guárián',
 				'gsw' => 'Swiz Jarman',
 				'gu' => 'Gojráti',
 				'guz' => 'Gusi',
 				'gv' => 'Manks',
 				'ha' => 'Hausá',
 				'haw' => 'Hawái',
 				'he' => 'Ebráni',
 				'hi' => 'Hendi',
 				'hi_Latn' => 'Hendi (Látin Engrézi (Látin) Engrézi (Látin, Amrikáay Tepákén Están) syáhag: Látini)',
 				'hnj' => 'Hmang Njuá',
 				'hr' => 'Króshiái',
 				'hsb' => 'Borzi Sorbiái',
 				'hu' => 'Hangári',
 				'hy' => 'Arminiái',
 				'ia' => 'Myánzobáni',
 				'id' => 'Endónési',
 				'ie' => 'Myánzobán',
 				'ig' => 'Igbó',
 				'ii' => 'Sichuái Yi',
 				'io' => 'Idó',
 				'is' => 'Islándi',
 				'it' => 'Itáliái',
 				'iu' => 'Inuktitut',
 				'ja' => 'Jápáni',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngombá',
 				'jmc' => 'Makami',
 				'jv' => 'Jáwáni',
 				'ka' => 'Járjiái',
 				'kaa' => 'Kara-Kalpak',
 				'kab' => 'Kabáile',
 				'kaj' => 'Jju',
 				'kam' => 'Kambá',
 				'kcg' => 'Tyáp',
 				'kde' => 'Makonde',
 				'kea' => 'Kubuwerdiánó',
 				'ken' => 'Kinyang',
 				'kgp' => 'Káingáng',
 				'khq' => 'Koirá Chini',
 				'ki' => 'Kikuyu',
 				'kk' => 'Kázák',
 				'kkj' => 'Kákó',
 				'kl' => 'Kalállisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmér',
 				'kn' => 'Kannadá',
 				'ko' => 'Kuriái',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambalá',
 				'ksf' => 'Bapiá',
 				'ksh' => 'Kologni',
 				'ku' => 'Kordi',
 				'kw' => 'Kornesh',
 				'kxv' => 'Kuwi',
 				'ky' => 'Kirgez',
 				'la' => 'Látini',
 				'lag' => 'Langi',
 				'lb' => 'Logzemborgi',
 				'lg' => 'Gandá',
 				'lij' => 'Liguri',
 				'lkt' => 'Lakótá',
 				'lld' => 'Ladin',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingálá',
 				'lo' => 'Láó',
 				'lou' => 'Luisiáná Krióle',
 				'lrc' => 'Shemáli Lori',
 				'lt' => 'Litwániái',
 				'ltg' => 'Latgali',
 				'lu' => 'Lubá-Katangá',
 				'luo' => 'Luó',
 				'luy' => 'Luiá',
 				'lv' => 'Latwiái',
 				'mai' => 'Maitéli',
 				'mas' => 'Masai',
 				'mdf' => 'Moksha',
 				'mer' => 'Méru',
 				'mfe' => 'Murisén',
 				'mg' => 'Malagase',
 				'mgh' => 'Makuá-Mitó',
 				'mgo' => 'Métá',
 				'mhn' => 'Móchénó',
 				'mi' => 'Muri',
 				'mic' => 'Mikmaw',
 				'mk' => 'Makduni',
 				'ml' => 'Malyálam',
 				'mn' => 'Mangóli',
 				'mni' => 'Manipuri',
 				'moh' => 'Mohawk',
 				'mr' => 'Maráthi',
 				'ms' => 'Malai',
 				'mt' => 'Maltiz',
 				'mua' => 'Mundang',
 				'mul' => 'Báz zobán',
 				'mus' => 'Muskógi',
 				'my' => 'Barmái',
 				'myv' => 'Erziá',
 				'mzn' => 'Mázendaráni',
 				'naq' => 'Nama',
 				'nb' => 'Nárwiji Bokmál',
 				'nd' => 'Shemáli Nedébéle',
 				'nds' => 'Láw Jarman',
 				'nds_NL' => 'Láw Jarman (NL)',
 				'ne' => 'Népáli',
 				'nl' => 'Dacch',
 				'nl_BE' => 'Dacch (Béljiam)',
 				'nmg' => 'Kwásiu',
 				'nn' => 'Nárwiji Nókén',
 				'nnh' => 'Ngembun',
 				'no' => 'Nárwiji',
 				'nqo' => 'Nko',
 				'nr' => 'Zerbári Nedebéli',
 				'nso' => 'Shemáli Sotó',
 				'nus' => 'Nuér',
 				'nv' => 'Nawájó',
 				'ny' => 'Nyanjá',
 				'nyn' => 'Nyankóle',
 				'oc' => 'Ositi',
 				'om' => 'Oromó',
 				'or' => 'Odi',
 				'os' => 'Oséti',
 				'osa' => 'Oságá',
 				'pa' => 'Panjábi',
 				'pap' => 'Pápiámentó',
 				'pcm' => 'Náijiri Pidgin',
 				'pis' => 'Pijen',
 				'pl' => 'Pólayndi',
 				'prg' => 'Prushiái',
 				'ps' => 'Pashtó',
 				'pt' => 'Portagáli',
 				'qu' => 'Kwichu',
 				'quc' => 'Kichi',
 				'raj' => 'Rájestáni',
 				'rhg' => 'Róhengiá',
 				'rif' => 'Ripi',
 				'rm' => 'Rumansh',
 				'rn' => 'Róndi',
 				'ro' => 'Rumániái',
 				'ro_MD' => 'Rumániái (MD)',
 				'rof' => 'Rombó',
 				'ru' => 'Rusi',
 				'rw' => 'Kenyarwandá',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskeret',
 				'sah' => 'Yakut',
 				'saq' => 'Samboró',
 				'sat' => 'Santali',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardéniái',
 				'scn' => 'Sesiliái',
 				'sd' => 'Sendi',
 				'sdh' => 'Zerbári Kordi',
 				'se' => 'Shemáli Sámi',
 				'seh' => 'Sená',
 				'ses' => 'Koryáburó Senni',
 				'sg' => 'Sangó',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Senhálá',
 				'sid' => 'Sidámó',
 				'sk' => 'Solwák',
 				'skr' => 'Saráeki',
 				'sl' => 'Solwiniái',
 				'sma' => 'Zerbári Sámi',
 				'smj' => 'Lule Sámi',
 				'smn' => 'Inári Sámi',
 				'sms' => 'Eskált Sámi',
 				'sn' => 'Shoná',
 				'so' => 'Sómáli',
 				'sq' => 'Albániái',
 				'sr' => 'Sarbiái',
 				'ss' => 'Swáti',
 				'ssy' => 'Sahó',
 				'st' => 'Zerbári Sutó',
 				'su' => 'Sudáni',
 				'sv' => 'Swidi',
 				'sw' => 'Swáhéli',
 				'sw_CD' => 'Swáhéli (CD)',
 				'syr' => 'Siriek',
 				'szl' => 'Selisi',
 				'ta' => 'Támel',
 				'te' => 'Telgó',
 				'teo' => 'Tésó',
 				'tg' => 'Tájek',
 				'th' => 'Tái',
 				'ti' => 'Tigriniá',
 				'tig' => 'Tigré',
 				'tk' => 'Trkm',
 				'tn' => 'Tuswáná',
 				'to' => 'Tongan',
 				'tok' => 'Tóki Póná',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Tork',
 				'trv' => 'Torokó',
 				'trw' => 'Torwáli',
 				'ts' => 'Tesungá',
 				'tt' => 'Tátar',
 				'twq' => 'Tasawak',
 				'tyv' => 'Tuwini',
 				'tzm' => 'Tzm',
 				'ug' => 'Yughor',
 				'uk' => 'Yukrini',
 				'und' => 'Nagisshetagén zobán',
 				'ur' => 'Urdu',
 				'uz' => 'Ozbek',
 				'vai' => 'Wái',
 				've' => 'Wendá',
 				'vec' => 'Weneti',
 				'vi' => 'Wietnámi',
 				'vmw' => 'Makuwá',
 				'vo' => 'Wolápuk',
 				'vun' => 'Wunjó',
 				'wa' => 'Wallun',
 				'wae' => 'Welser',
 				'wal' => 'Wolettá',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolop',
 				'xh' => 'Khushá',
 				'xnr' => 'Kangri',
 				'xog' => 'Sugá',
 				'yav' => 'Yangben',
 				'yi' => 'Yeddi',
 				'yo' => 'Yorobá',
 				'yrl' => 'Ningátu',
 				'yue' => 'Kantóni',
 				'yue@alt=menu' => 'Kantóni-yue',
 				'za' => 'Zhuáng',
 				'zgh' => 'Gisshetqagén Moróki Tamázi',
 				'zh' => 'Chini',
 				'zu' => 'Zulu',
 				'zxx' => 'Hecch zobán',

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
			'Adlm' => 'Adlam',
 			'Aghb' => 'Kákáshi Albáni',
 			'Arab' => 'Arabi',
 			'Aran' => 'Nastalik',
 			'Armi' => 'Shahensháhi Aramái',
 			'Armn' => 'Arman',
 			'Avst' => 'Awestái',
 			'Bali' => 'Báléni',
 			'Bamu' => 'Bámum',
 			'Bass' => 'Bassa Wah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bang',
 			'Bhks' => 'Baykduki',
 			'Bopo' => 'Bópó',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Brái',
 			'Bugi' => 'Bugini',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Kaynadhái Asligén Silábi',
 			'Cari' => 'Charian',
 			'Cher' => 'Cheoki',
 			'Chrs' => 'Chorasmi',
 			'Copt' => 'koptek',
 			'Cpmn' => 'Sáepró-Minói',
 			'Cprt' => 'Sáepriót',
 			'Cyrl' => 'Rusi',
 			'Cyrs' => 'Ahdi Serelek',
 			'Deva' => 'Déwá',
 			'Diak' => 'Diwes Akuru',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duplui Shárthand',
 			'Egyp' => 'Mesri hirógleps',
 			'Elba' => 'Elbási',
 			'Elym' => 'Élimái',
 			'Ethi' => 'Etyupi',
 			'Gara' => 'Garay',
 			'Geor' => 'Járj',
 			'Glag' => 'Galgoliti',
 			'Gong' => 'Gunjála Góndi',
 			'Gonm' => 'Masáram Góndi',
 			'Goth' => 'Góti',
 			'Gran' => 'Grantá',
 			'Grek' => 'Yun',
 			'Gujr' => 'Gojr',
 			'Gukh' => 'Gurong Khémá',
 			'Guru' => 'Gurukuki',
 			'Hanb' => 'Hán gón Bópómópóá',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunu',
 			'Hans' => 'Hán (sádah kortagén)',
 			'Hant' => 'Hán (asligén)',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Ebráni',
 			'Hira' => 'Hirágáná',
 			'Hluw' => 'Anátólyái Hérógleps',
 			'Hmng' => 'Pahaw Hmong',
 			'Hmnp' => 'Niákeng Puáche Hamung',
 			'Hrkt' => 'Jápáni Selibari',
 			'Hung' => 'Ahdi Hangari',
 			'Ital' => 'Ahdi Itáliái',
 			'Jamo' => 'Jamó',
 			'Java' => 'Jáwá',
 			'Jpan' => 'Jápáni',
 			'Kali' => 'Káyah Li',
 			'Kana' => 'Katakaná',
 			'Kawi' => 'Káwi',
 			'Khar' => 'Karóshti',
 			'Khmr' => 'Khmér',
 			'Khoj' => 'Kójki',
 			'Kits' => 'Kitan gwandhén syáhag',
 			'Knda' => 'Kannadá',
 			'Kore' => 'Kóriái',
 			'Krai' => 'Kirat Rai',
 			'Kthi' => 'Kaiti',
 			'Lana' => 'Lanná',
 			'Laoo' => 'Láu',
 			'Latf' => 'Praktur Látin',
 			'Latg' => 'Géli Látin',
 			'Latn' => 'Látin Engrézi (Látin) Engrézi (Látin, Amrikáay Tepákén Están) syáhag: Látini',
 			'Lepc' => 'Lepchá',
 			'Limb' => 'Limbu',
 			'Lina' => 'Layni A',
 			'Linb' => 'Layni B',
 			'Lisu' => 'Prásar',
 			'Lyci' => 'Lisiái',
 			'Lydi' => 'Lidiái',
 			'Mahj' => 'Mahájani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandáin',
 			'Mani' => 'Manichái',
 			'Marc' => 'Marchen',
 			'Medf' => 'Medepáidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Meriuti Karsi',
 			'Mero' => 'Meriuti',
 			'Mlym' => 'Malyálam',
 			'Modi' => 'Módi',
 			'Mong' => 'Mongóli',
 			'Mroo' => 'Mró',
 			'Mtei' => 'Miyeti Máyek',
 			'Mult' => 'Moltáni',
 			'Mymr' => 'Myanmár',
 			'Nagm' => 'Nag Mundari',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Ahdi Shemáli Arabi',
 			'Nbat' => 'Nabatái',
 			'Newa' => 'Newá',
 			'Nkoo' => 'Nekó',
 			'Nshu' => 'Nushu',
 			'Ogam' => 'Oghám',
 			'Olck' => 'Ol cheki',
 			'Onao' => 'Ol Onal',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Ódiá',
 			'Osge' => 'Oséj',
 			'Osma' => 'Osmánia',
 			'Ougr' => 'Ahdi Yógher',
 			'Palm' => 'Palmrén',
 			'Pauc' => 'Páu Chen Háu',
 			'Perm' => 'Ahdi Permi',
 			'Phag' => 'Pags-pa',
 			'Phli' => 'Kondahi Pahlawi',
 			'Phlp' => 'Psáltar Pahlawi',
 			'Phnx' => 'Phónisi',
 			'Plrd' => 'Pólli Tawári',
 			'Prti' => 'Kondahi Párti',
 			'Qaag' => 'Zawgi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanipi',
 			'Runr' => 'Runi',
 			'Samr' => 'Samári',
 			'Sarb' => 'Ahdi Zerbári Arabi',
 			'Saur' => 'Sáuráshtri',
 			'Sgnw' => 'Neshánnebisi',
 			'Shaw' => 'Sháwi',
 			'Shrd' => 'Sharadá',
 			'Sidd' => 'Seddam',
 			'Sind' => 'Kodáwadi',
 			'Sinh' => 'Senhalá',
 			'Sogd' => 'Sógdiái',
 			'Sogo' => 'Ahdi Sógdiái',
 			'Sora' => 'Surá Sompeng',
 			'Soyo' => 'Soyombó',
 			'Sund' => 'Sudáni',
 			'Sunu' => 'Sunuwar',
 			'Sylo' => 'Siluti Nagri',
 			'Syrc' => 'Siriek',
 			'Syre' => 'Estrangló Siriek',
 			'Syrj' => 'Rónendi Siriek',
 			'Syrn' => 'Ródarátki Siriek',
 			'Tagb' => 'Tagbanwá',
 			'Takr' => 'Takri',
 			'Tale' => 'Tái Lé',
 			'Talu' => 'Nókén Tái Lé',
 			'Taml' => 'Támel',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tái Wiet',
 			'Telu' => 'Telegó',
 			'Tfng' => 'Tipinag',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Tána',
 			'Thai' => 'Tái',
 			'Tibt' => 'Tebati',
 			'Tirh' => 'Tirhutá',
 			'Tnsa' => 'Tangsá',
 			'Todr' => 'Tódri',
 			'Toto' => 'Tótó',
 			'Tutg' => 'Tulu-Tigálari',
 			'Ugar' => 'Yugariti',
 			'Vaii' => 'Wái',
 			'Vith' => 'Witkuki',
 			'Wara' => 'Warang Kshiti',
 			'Wcho' => 'Wanchó',
 			'Xpeo' => 'Ahdi Pársi',
 			'Xsux' => 'Sumer-Akádi Kyunipárm',
 			'Yezi' => 'Yezidi',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Zanabazar Eskwáer',
 			'Zinh' => 'Enheri',
 			'Zmth' => 'Hesábi Neshán',
 			'Zsye' => 'Emóji',
 			'Zsym' => 'Neshán',
 			'Zxxx' => 'Nebeshtah nabutagén syáhag',
 			'Zyyy' => 'Hórén',
 			'Zzzz' => 'Kódh nakortagén syáhag',

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
			'001' => 'Donyá',
 			'002' => 'Afriká',
 			'003' => 'Shemáli Amriká',
 			'005' => 'Zerbári Amriká',
 			'009' => 'Ushiáná',
 			'011' => 'Rónendi Apriká',
 			'013' => 'Myáni Amriká',
 			'014' => 'Ródarátki Apriká',
 			'015' => 'Shemáli Apriká',
 			'017' => 'Myáni Apriká',
 			'018' => 'Jonubi Apriká',
 			'019' => 'Amriká',
 			'021' => 'Shemáli Amrika',
 			'029' => 'Kerébian',
 			'030' => 'Ródarátki Ásiá',
 			'034' => 'Zerbári Ásiá',
 			'035' => 'Zerbárródarátki Ásiá',
 			'039' => 'Zerbári Yurop',
 			'053' => 'Ástrálásiá',
 			'054' => 'Melanésiá',
 			'057' => 'Máekrónési Damag',
 			'061' => 'Pólinisiá',
 			'142' => 'Ásiá',
 			'143' => 'Myáni Ásiá',
 			'145' => 'Rónendi Ásiá',
 			'150' => 'Yurop',
 			'151' => 'Ródarátki Yurop',
 			'154' => 'Shemáli Yurop',
 			'155' => 'Rónendi Yurop',
 			'202' => 'Sab-Sahári Apriká',
 			'419' => 'Látini Amriká',
 			'AC' => 'Asenshan Islánd',
 			'AD' => 'Andorrá',
 			'AE' => 'Emárát',
 			'AF' => 'Awghánestán',
 			'AG' => 'Antiga o Barbuda',
 			'AI' => 'Angwila',
 			'AL' => 'Albániá',
 			'AM' => 'Árminiá',
 			'AO' => 'Angólá',
 			'AQ' => 'Antárktiká',
 			'AR' => 'Arjentiná',
 			'AS' => 'Amriki Samóá',
 			'AT' => 'Ástriá',
 			'AU' => 'Ásthréliá',
 			'AW' => 'Aruba',
 			'AX' => 'Áwlánd Islánd',
 			'AZ' => 'Ázerbáiján',
 			'BA' => 'Bósniá',
 			'BB' => 'Barbadós',
 			'BD' => 'Bangaladésh',
 			'BE' => 'Béljiam',
 			'BF' => 'Burkiná Pásó',
 			'BG' => 'Balgáriá',
 			'BH' => 'Bahren',
 			'BI' => 'Borondi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Bartélémi',
 			'BM' => 'Barmudá',
 			'BN' => 'Brunái',
 			'BO' => 'Boliwiá',
 			'BQ' => 'Kerébi Nedarlánd',
 			'BR' => 'Brázil',
 			'BS' => 'Bahamas',
 			'BT' => 'Buthán',
 			'BV' => 'Bówet Islánd',
 			'BW' => 'Bostwáná',
 			'BY' => 'Bélárus',
 			'BZ' => 'Belize',
 			'CA' => 'Kaynadhá',
 			'CC' => 'Kukus Islánd (Kileng)',
 			'CD' => 'Kángó-Kenshásá',
 			'CD@alt=variant' => 'Kángó',
 			'CF' => 'Myáni Apriki Eshtán',
 			'CG' => 'Kángó-Brázáwille',
 			'CG@alt=variant' => 'Kángó (Están)',
 			'CH' => 'Swizarlánd',
 			'CI' => 'Kóté diáwóri',
 			'CI@alt=variant' => 'Áiwari Tyáb',
 			'CK' => 'Kuk Islánd',
 			'CL' => 'Chilay',
 			'CM' => 'Kaymrun',
 			'CN' => 'Chin',
 			'CO' => 'Kólambiá',
 			'CP' => 'Klipperton Islánd',
 			'CQ' => 'Sárk',
 			'CR' => 'Kóstá Riká',
 			'CU' => 'Kyubá',
 			'CV' => 'Kap Wardé',
 			'CW' => 'Churácháó',
 			'CX' => 'Kresmes Islánd',
 			'CY' => 'Sáipras',
 			'CZ' => 'Chéchiá',
 			'CZ@alt=variant' => 'Chek Están',
 			'DE' => 'Jarmani',
 			'DG' => 'Diégó Gárshiá',
 			'DJ' => 'Djebuti',
 			'DK' => 'Denmárk',
 			'DM' => 'Duminiká',
 			'DO' => 'Duminiki Están',
 			'DZ' => 'Aljiriá',
 			'EA' => 'Siótó o Melilá',
 			'EC' => 'Ekwádór',
 			'EE' => 'Estóniá',
 			'EG' => 'Mesr',
 			'EH' => 'Róbarkati Sahárá',
 			'ER' => 'Eritiriá',
 			'ES' => 'Espin',
 			'ET' => 'Etupiá',
 			'EU' => 'Yuropi Yunian',
 			'EZ' => 'Yurop-damag',
 			'FI' => 'Fenlánd',
 			'FJ' => 'Fiji',
 			'FK' => 'Páklánd Islánd',
 			'FK@alt=variant' => 'Páklánd Islánd (Islas Málwinás)',
 			'FM' => 'Mikrónéshiá',
 			'FO' => 'Faróé Islánd',
 			'FR' => 'Paráns',
 			'GA' => 'Gabon',
 			'GB' => 'Bartániá',
 			'GD' => 'Gerená',
 			'GE' => 'Járjiá',
 			'GF' => 'Pránsi Gwiáná',
 			'GG' => 'Gwernsay',
 			'GH' => 'Gáná',
 			'GI' => 'Gibráltar',
 			'GL' => 'Grinlánd',
 			'GM' => 'Gambiá',
 			'GN' => 'Giniá',
 			'GP' => 'Gwádelóp',
 			'GQ' => 'Ekwáturi Giniá',
 			'GR' => 'Yunán',
 			'GS' => 'Zerbári Járjiá',
 			'GT' => 'Gwátémálá',
 			'GU' => 'Guám',
 			'GW' => 'Giniá-Bissáu',
 			'GY' => 'Goyáná',
 			'HK' => 'Háng Káng o SAR Chin',
 			'HK@alt=short' => 'Háng Káng',
 			'HM' => 'Hard o Mekdónald Islánd',
 			'HN' => 'Honduras',
 			'HR' => 'Króshiá',
 			'HT' => 'Hayti',
 			'HU' => 'Hangari',
 			'IC' => 'Kanaray Islánd',
 			'ID' => 'Endhonéshiá',
 			'IE' => 'Áerlánd',
 			'IL' => 'Esráil',
 			'IM' => 'Áisale Mardom',
 			'IN' => 'Hendostán',
 			'IO' => 'Bartáni Hendi Zerdamag',
 			'IO@alt=chagos' => 'Chágós Árkipelágó',
 			'IQ' => 'Erák',
 			'IR' => 'Érán',
 			'IS' => 'Áeslánd',
 			'IT' => 'Itáliá',
 			'JE' => 'Jersé',
 			'JM' => 'Jamáeká',
 			'JO' => 'Ordon',
 			'JP' => 'Jápán',
 			'KE' => 'Kiniá',
 			'KG' => 'Karghazestán',
 			'KH' => 'Kambódhiá',
 			'KI' => 'Kiribáti',
 			'KM' => 'Komórós',
 			'KN' => 'St. Kitts o Newis',
 			'KP' => 'Shamáli Kóriá',
 			'KR' => 'Zerbári Kóriá',
 			'KW' => 'Kwayt',
 			'KY' => 'Kaymi Islánd',
 			'KZ' => 'Kázakhestán',
 			'LA' => 'Láus',
 			'LB' => 'Lebnán',
 			'LC' => 'St. Lusiá',
 			'LI' => 'Lichtenstén',
 			'LK' => 'Sari Lanká',
 			'LR' => 'Láibériá',
 			'LS' => 'Lesótó',
 			'LT' => 'Lituániá',
 			'LU' => 'Loksembórg',
 			'LV' => 'Latwiá',
 			'LY' => 'Libyá',
 			'MA' => 'Morókó',
 			'MC' => 'Monákó',
 			'MD' => 'Moldowá',
 			'ME' => 'Montenegró',
 			'MF' => 'St. Mártin',
 			'MG' => 'Madagáskar',
 			'MH' => 'Marshall Islánd',
 			'MK' => 'Shemáli Makduniá',
 			'ML' => 'Máli',
 			'MM' => 'Myanmár (Barmá)',
 			'MN' => 'Mangóliá',
 			'MO' => 'Makaó SAR Chin',
 			'MO@alt=short' => 'Makaó',
 			'MP' => 'Shemáli Máriáná Islánd',
 			'MQ' => 'Mártinik',
 			'MR' => 'Muritániá',
 			'MS' => 'Montserrat',
 			'MT' => 'Máltá',
 			'MU' => 'Murishias',
 			'MV' => 'Máldip',
 			'MW' => 'Maláwi',
 			'MX' => 'Meksikó',
 			'MY' => 'Maléshiá',
 			'MZ' => 'Mózambik',
 			'NA' => 'Namibiá',
 			'NC' => 'Niu Káledóniá',
 			'NE' => 'Náiger',
 			'NF' => 'Nórfolk Islánd',
 			'NG' => 'Náijériá',
 			'NI' => 'Nekárágóá',
 			'NL' => 'Nedarlánd',
 			'NO' => 'Nárway',
 			'NP' => 'Népál',
 			'NR' => 'Náuru',
 			'NU' => 'Niué',
 			'NZ' => 'Nyu Zilánd',
 			'NZ@alt=variant' => 'Áotéróá Niu Zilánd',
 			'OM' => 'Omán',
 			'PA' => 'Pánámá',
 			'PE' => 'Péru',
 			'PF' => 'Paránsi Pulinishiá',
 			'PG' => 'Pápuá Niu Giniá',
 			'PH' => 'Pelpin',
 			'PK' => 'Pákestán',
 			'PL' => 'Pólánd',
 			'PM' => 'St. Péri o Mikwélin',
 			'PN' => 'Pitkarén Islánd',
 			'PR' => 'Piuró Rikó',
 			'PS' => 'Palastinay Damag',
 			'PS@alt=short' => 'Palastin',
 			'PT' => 'Portogál',
 			'PW' => 'Paláu',
 			'PY' => 'Parágóay',
 			'QA' => 'Gatar',
 			'QO' => 'Tálánén Zerbahrag',
 			'RE' => 'Réyunian',
 			'RO' => 'Rumániá',
 			'RS' => 'Sarbiá',
 			'RU' => 'Rus',
 			'RW' => 'Rwándhá',
 			'SA' => 'Saudi Arab',
 			'SB' => 'Solomán Islánd',
 			'SC' => 'Sécheles',
 			'SD' => 'Sudán',
 			'SE' => 'Swidhan',
 			'SG' => 'Sengápur',
 			'SH' => 'St. Heléná',
 			'SI' => 'Slowiniá',
 			'SJ' => 'Swalbard o Jan Mayén',
 			'SK' => 'Slowákiá',
 			'SL' => 'Sierrá Leóne',
 			'SM' => 'San Mariánó',
 			'SN' => 'Senigál',
 			'SO' => 'Sómáliá',
 			'SR' => 'Surinaym',
 			'SS' => 'Zerbári Sudán',
 			'ST' => 'Sáó Tóme o Prensip',
 			'SV' => 'El Salwadór',
 			'SX' => 'Sint Márten',
 			'SY' => 'Suriá',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swázilánd',
 			'TA' => 'Tristan dá Chonhá',
 			'TC' => 'Tork o Káikói Islánd',
 			'TD' => 'Chád',
 			'TF' => 'Pránsi Zerbári Damag',
 			'TG' => 'Tógó',
 			'TH' => 'Táilánd',
 			'TJ' => 'Tájekestán',
 			'TK' => 'Tokéláu',
 			'TL' => 'Témur-Leste',
 			'TL@alt=variant' => 'Ródarátki Témur',
 			'TM' => 'Torkmenestán',
 			'TN' => 'Tunishiá',
 			'TO' => 'Tongá',
 			'TR' => 'Turkiye',
 			'TR@alt=variant' => 'Torki',
 			'TT' => 'Trinidad o Tobágó',
 			'TV' => 'Tuwalu',
 			'TW' => 'Táiwán',
 			'TZ' => 'Tanzániá',
 			'UA' => 'Yukrén',
 			'UG' => 'Yugandhá',
 			'UM' => 'U.S. Daráén Islánd',
 			'UN' => 'Myánostománi Gal',
 			'US' => 'Amrikáay Tepákén Están',
 			'UY' => 'Yurógóay',
 			'UZ' => 'Ozbekestán',
 			'VA' => 'Wátikán Sethi',
 			'VC' => 'St. Wensent o Grenádin',
 			'VE' => 'Wenezwélá',
 			'VG' => 'Bretáni Ajgén Islánd',
 			'VI' => 'Amriki Ajgén Islánd',
 			'VN' => 'Wietnám',
 			'VU' => 'Wanuátu',
 			'WF' => 'Wális o Futuná',
 			'WS' => 'Samóá',
 			'XA' => 'Kesási-Gálwár',
 			'XB' => 'Kesási- Bidi',
 			'XK' => 'Kósówó',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Zerbári Apriká',
 			'ZM' => 'Zambiá',
 			'ZW' => 'Zembábwé',
 			'ZZ' => 'Nagisshetagén damag',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Rabyati Jarman nebeshtarahband',
 			'1994' => 'Gisshetagén Réshian nebeshtarahband',
 			'1996' => 'Jarman nebeshtarahband',
 			'1606NICT' => 'Randi Myáni Pránsi',
 			'1694ACAD' => 'Mahlahén Nókén Pránsi',
 			'1959ACAD' => 'Akádemi',
 			'ABL1943' => 'Nebeshtarahbnadi Gishwár 1943',
 			'AKUAPEM' => 'AKUÁPÉM',
 			'ALALC97' => 'ALA-LK Látini, 1997',
 			'ALUKU' => 'Aluku gálwár',
 			'ANPEZO' => 'ANPÉZÓ',
 			'AO1990' => 'Portogáli Zobánay Nebeshtarahbanday Mannánk 1990',
 			'ARANES' => 'ARANÉS',
 			'ARKAIKA' => 'ARKÁIKÁ',
 			'ASANTE' => 'ASANTÉ',
 			'AUVERN' => 'AUWERN',
 			'BAKU1926' => 'Hawárén Torki Látini Áb',
 			'BALANKA' => 'Balanká gálwár, Anii',
 			'BARLA' => 'Barlawentó gálwár granch, Kábuwerdiánu',
 			'BASICENG' => 'BASIKENG',
 			'BAUDDHA' => 'BAUDDÁ',
 			'BCIAV' => 'BKIAW',
 			'BCIZBL' => 'BKIZBL',
 			'BISCAYAN' => 'BISKAYAN',
 			'BISKE' => 'San Jiárjó/Bila gálwár',
 			'BLASL' => 'BLÁSL',
 			'BOHORIC' => 'Bohóri áb',
 			'BOONT' => 'Buntleng',
 			'BORNHOLM' => 'BÓRNHOLM',
 			'CISAUP' => 'CISÁUP',
 			'COLB1945' => 'Portagézi-Brázili Nebeshtarahband Diwán 1945',
 			'CORNU' => 'CÓRNU',
 			'CREISS' => 'CRÉISS',
 			'DAJNKO' => 'Dajankó áb',
 			'EKAVSK' => 'Sarbiái gón Ekwái gálwárá',
 			'EMODENG' => 'Mahlahén Nókén Engrézi',
 			'FASCIA' => 'FÁSCIÁ',
 			'FODOM' => 'FODÓM',
 			'FONIPA' => 'IPA Tawári',
 			'FONKIRSH' => 'FÓNKERSH',
 			'FONNAPA' => 'FONNÁPÁ',
 			'FONUPA' => 'UPA Tawári',
 			'FONXSAMP' => 'FONKSAMP',
 			'GALLO' => 'GALLÓ',
 			'GASCON' => 'GASKÓN',
 			'GHERD' => 'GHÉRD',
 			'GRCLASS' => 'GRKLÁSS',
 			'GRITAL' => 'GRITÁL',
 			'GRMISTR' => 'GRMEST',
 			'HEPBURN' => 'Hepburn Látini',
 			'HOGNORSK' => 'HÓGNÓRSK',
 			'HSISTEMO' => 'HSISTEMÓ',
 			'IJEKAVSK' => 'Sarbiái gón Ejekawái gálwárá',
 			'ITIHASA' => 'ITIHÁSÁ',
 			'IVANCHOV' => 'IWANCHÓW',
 			'JAUER' => 'JÁUÉR',
 			'JYUTPING' => 'JYUTPÉNG',
 			'KKCOR' => 'Hawárén Nebeshtarahband',
 			'KOCIEWIE' => 'KÓCIEWIÉ',
 			'KSCOR' => 'Gisshetagén Nebeshtarahband',
 			'LAUKIKA' => 'LÁUKIKÁ',
 			'LEMOSIN' => 'LÉMÓSIN',
 			'LENGADOC' => 'LENGÁDÓK',
 			'LIPAW' => 'Lipówázi gálwár, Réshi',
 			'LTG1929' => 'LTG-1929',
 			'LTG2007' => 'LTG-2007',
 			'LUNA1918' => 'LUNÁ-1918',
 			'METELKO' => 'Metelkó áb',
 			'MONOTON' => 'Mónótáni',
 			'NDYUKA' => 'Ndyuká gálwár',
 			'NEDIS' => 'Natisón gálwár',
 			'NEWFOUND' => 'NEWPOUND',
 			'NICARD' => 'NICÁRD',
 			'NJIVA' => 'Gniwá/Njiwá gálwár',
 			'NULIK' => 'Nókén Wolápuk',
 			'OSOJS' => 'Osiákkó/Osójáné gálwár',
 			'OXENDICT' => 'Ákspórd Engrézi Labzbaladay áp rahband',
 			'PAHAWH2' => 'PAHAWH-2',
 			'PAHAWH3' => 'PAHAWH-3',
 			'PAHAWH4' => 'PAHAWH-4',
 			'PAMAKA' => 'Pamáká gálwár',
 			'PEANO' => 'PEÁNÓ',
 			'PEHOEJI' => 'PEHÓEJI',
 			'PETR1708' => 'PÉTR-1708',
 			'PINYIN' => 'Pinyin Látini',
 			'POLYTON' => 'Pólituni',
 			'POSIX' => 'Kampyutar',
 			'PROVENC' => 'PROWENC',
 			'PUTER' => 'PUTÉR',
 			'REVISED' => 'Nókázén Nebeshtarahband',
 			'RIGIK' => 'Kalásiki Wólápuk',
 			'ROZAJ' => 'Réshi',
 			'RUMGR' => 'RÓMGR',
 			'SAAHO' => 'Sahó',
 			'SCOTLAND' => 'Eskáti Gisshetagén Engrézi',
 			'SCOUSE' => 'Skáuz',
 			'SIMPLE' => 'Sádah',
 			'SOLBA' => 'Stolwizá/Solbiká gálwár',
 			'SOTAV' => 'Sotáwentó gálwár granch, Kabuwerdiánó',
 			'SPANGLIS' => 'SPÁNGLIS',
 			'SURMIRAN' => 'SURMIRÁN',
 			'SURSILV' => 'SURSILW',
 			'SUTSILV' => 'SUTSILW',
 			'SYNNEJYL' => 'SYNNÉJYL',
 			'TAILO' => 'TÁILÓ',
 			'TARASK' => 'Taraskiwiká nebeshtarahband',
 			'TONGYONG' => 'TONGYÓNG',
 			'TUNUMIIT' => 'TUNUMIÉT',
 			'UCCOR' => 'Hamshawrén Nebeshtarahband',
 			'UCRCOR' => 'Hamshawrén Nókázén Nebeshtarahband',
 			'ULSTER' => 'ULSTÉR',
 			'UNIFON' => 'UNIFON-tawári áb',
 			'VAIDIKA' => 'WAIDIKA',
 			'VALBADIA' => 'WALBADIÁ',
 			'VALENCIA' => 'Walensi',
 			'VALLADER' => 'WALLADER',
 			'VECDRUKA' => 'ÓECDRUKÁ',
 			'VIVARAUP' => 'WIWARÁUP',
 			'WADEGILE' => 'Wayd-Gili Látin',
 			'XSISTEMO' => 'KSISTEMO',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Sáldar',
 			'cf' => 'Zarr Káleb',
 			'collation' => 'Red o band',
 			'currency' => 'Zarr',
 			'hc' => 'Sáhatáni chahr (12 o 24)',
 			'lb' => 'Red próshagay dáb',
 			'ms' => 'Kayl kanagy rahband',
 			'numbers' => 'Nambar',

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
 				'buddhist' => q{Buddái sáldar},
 				'chinese' => q{Chini sáldar},
 				'coptic' => q{Kobti sáldar},
 				'dangi' => q{Dángi sáldar},
 				'ethiopic' => q{Etupiái sáldar},
 				'ethiopic-amete-alem' => q{Etupiái Ámet Álem sáldar},
 				'gregorian' => q{Miládi sáldar},
 				'hebrew' => q{Ebráni sáldar},
 				'indian' => q{Hendi Kawmi sáldar},
 				'islamic' => q{Eslámi sáldar},
 				'islamic-civil' => q{Eslámi shahri sáldar},
 				'islamic-rgsa' => q{Eslámi Saudi-Arabi sáldar},
 				'islamic-tbla' => q{Eslámi Nojumi sáldar},
 				'islamic-umalqura' => q{Eslámi Omm al-Korrahi sáldar},
 				'iso8601' => q{ISO-8601 sáldar},
 				'japanese' => q{Jápáni sáldar},
 				'persian' => q{Pársi sáldar},
 				'roc' => q{Mingu-Chini sáldar},
 			},
 			'cf' => {
 				'account' => q{Hesáb, Zarr Káleb},
 				'standard' => q{Zarray anjárén káleb},
 			},
 			'collation' => {
 				'big5han' => q{Chini Rabyati Red o band},
 				'compat' => q{Pésari Red o band, pa hamdapiá},
 				'dictionary' => q{Labzbaladi Red o band},
 				'ducet' => q{Aslén Yunikodi Red o band},
 				'emoji' => q{Emóji Red o band},
 				'eor' => q{Yuropi Red o bandi Rahband},
 				'gb2312han' => q{Sádah kortagén Chini Red o band - GB2312},
 				'phonebook' => q{Pawnbokki Red o band},
 				'pinyin' => q{Pinyi Red o band},
 				'search' => q{Ám Kári Shóház},
 				'searchjl' => q{Hangul Awali Jwánábay sará shóház},
 				'standard' => q{Anjári Red o band},
 				'stroke' => q{Strók Red o band},
 				'traditional' => q{Rabyati Red o band},
 				'unihan' => q{Trondén-stróki Red o band},
 				'zhuyin' => q{Zhuin Red o band},
 			},
 			'hc' => {
 				'h11' => q{12 Sáhati (0–11)},
 				'h12' => q{12 Sáhati (1–12)},
 				'h23' => q{24 Sáhati (0–23)},
 				'h24' => q{14 Sáhati (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Red próshagay sholén dáb},
 				'normal' => q{Red próshagay ámigén dáb},
 				'strict' => q{Red próshagay trondén dáb},
 			},
 			'ms' => {
 				'metric' => q{Mitari},
 				'uksystem' => q{Sháhensháhi Kayl Rahband},
 				'ussystem' => q{Amrikái Kayl Rahband},
 			},
 			'numbers' => {
 				'ahom' => q{Ahom Mórdán},
 				'arab' => q{Arabi-Hendi mórdán},
 				'arabext' => q{Géshén Arabi-Hendi Mórdán},
 				'armn' => q{Ármini Nambar},
 				'armnlow' => q{Árminiái Kasánén Nambar},
 				'bali' => q{Báléni Mórdán},
 				'beng' => q{Bangla Mórdán},
 				'brah' => q{Brahmi Mórdán},
 				'cakm' => q{Chakma Mórdán},
 				'cham' => q{Cham Mórdán},
 				'cyrl' => q{Rusi mórdán},
 				'deva' => q{Dénágari mórdán},
 				'diak' => q{Diwi Akuru Mórdán},
 				'ethi' => q{Etupi Nambar},
 				'fullwide' => q{Srjam-Sháhegánén Mórdán},
 				'gara' => q{Garai Mórdán},
 				'geor' => q{Járjiái Nambar},
 				'gong' => q{Gunjála Góndi mórdán},
 				'gonm' => q{Masaram Góndi mórdán},
 				'grek' => q{Yunáni Nambar},
 				'greklow' => q{Yunáni Kasánén Nambar},
 				'gujr' => q{Gojráti Mórdán},
 				'gukh' => q{Gurong Khémá Mórdán},
 				'guru' => q{Gurmuki Mórdán},
 				'hanidec' => q{Chini Dahi Nambar},
 				'hans' => q{Sáda kortagén Chini Nambar},
 				'hansfin' => q{Sáda kortagén Chini Hesábi Nambar},
 				'hant' => q{Chini Rabyati Nambar},
 				'hantfin' => q{Chini Rabyati Hesáni Nambar},
 				'hebr' => q{Ebráni Nambar},
 				'hmng' => q{Pahaw Hmong Mórdán},
 				'hmnp' => q{Nyákeng Páuchó Hmong Mórdán},
 				'java' => q{Jáwáni Mórdán},
 				'jpan' => q{Jápáni Nambar},
 				'jpanfin' => q{Jápáni Hesábi Nambar},
 				'kali' => q{Káyah Li Mórdán},
 				'kawi' => q{Kawi Mórdán},
 				'khmr' => q{Khmér Mórdán},
 				'knda' => q{Kannadái Mórdán},
 				'krai' => q{Kirat Rai Mórdán},
 				'lana' => q{Tai Tam Hórá Mórdán},
 				'lanatham' => q{Tai Tam Tam Mórdán},
 				'laoo' => q{Láó Mórdán},
 				'latn' => q{Rónendi Mórdán},
 				'lepc' => q{Lepcha Mórdán},
 				'limb' => q{Limbu Mórdán},
 				'mathbold' => q{Hesábi Dhalagén Mórdán},
 				'mathdbl' => q{Hesábi do-likki Mórdán},
 				'mathmono' => q{Hesábi Yakjáhén Mórdán},
 				'mathsanb' => q{Hesábi Sans-Serép Dhalagén Mórdán},
 				'mathsans' => q{Hesábi Sans-Serép Mórdán},
 				'mlym' => q{Malyálam Mórdán},
 				'modi' => q{Módi Mórdán},
 				'mong' => q{Mongóli Mórdán},
 				'mroo' => q{Mró Mórdán},
 				'mtei' => q{Méti Mayék Mórdán},
 				'mymr' => q{Myánmár Mórdán},
 				'mymrepka' => q{Myánmár Ródarátki Pwo Karen Mórdán},
 				'mymrpao' => q{Myánmár Pao Mórdán},
 				'mymrshan' => q{Myánmár Shan Mórdán},
 				'mymrtlng' => q{Myánmár Tai Laing Mórdán},
 				'nagm' => q{Nag Mundari Mórdán},
 				'nkoo' => q{Nkó Mórdán},
 				'olck' => q{Ol Cheki Mórdán},
 				'onao' => q{Ol Onal Mórdán},
 				'orya' => q{Odi Mórdán},
 				'osma' => q{Osmániái Mórdán},
 				'outlined' => q{Darlikki Mórdán},
 				'rohg' => q{Hanipi Róhangiái Mórdán},
 				'roman' => q{Látini Nambar},
 				'romanlow' => q{Látini Kasánén Nambar},
 				'saur' => q{Saurashtri Mórdán},
 				'shrd' => q{Sharadá Mórdán},
 				'sind' => q{Kodáwadi Mórdán},
 				'sinh' => q{Senhálá Lit Mórdán},
 				'sora' => q{Sórá Sompeng Mórdán},
 				'sund' => q{Sudáni Mórdán},
 				'sunu' => q{Sunuwar Mórdán},
 				'takr' => q{Takri Mórdán},
 				'talu' => q{Nókén Tai Lue Mórdán},
 				'taml' => q{Rabyati Támel Nambar},
 				'tamldec' => q{Támel Mórdán},
 				'telu' => q{Telegó Mórdán},
 				'thai' => q{Tái Mórdán},
 				'tibt' => q{Tebbati Mórdán},
 				'tirh' => q{Tirutá Mórdán},
 				'tnsa' => q{Tangsá Mórdán},
 				'vaii' => q{Wái Mórdán},
 				'wara' => q{Warang Siti Mórdán},
 				'wcho' => q{Wanchó Mórdán},
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
			'metric' => q{Mitari},
 			'UK' => q{Bartáni},
 			'US' => q{Amriki},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'zobán: {0}',
 			'script' => 'syáhag: {0}',
 			'region' => 'damag: {0}',

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
			auxiliary => qr{[ń]},
			index => ['Á', 'A', 'B', '{Ch}', 'D', '{Dh}', 'É', 'E', 'F', 'G', '{Gh}', 'H', 'I', 'J', 'K', '{Kh}', 'L', 'M', 'N', 'Ó', 'O', 'P', 'R', '{Rh}', 'S', '{Sh}', 'T', '{Th}', 'U', 'W', 'Y', 'Z', '{Zh}'],
			main => qr{[á a b {ch} d {dh} é e f g {gh} h i j k {kh} l m n ó o p r {rh} s {sh} t {th} u w y z {zh}]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ‘’ “”]},
		};
	},
EOT
: sub {
		return { index => ['Á', 'A', 'B', '{Ch}', 'D', '{Dh}', 'É', 'E', 'F', 'G', '{Gh}', 'H', 'I', 'J', 'K', '{Kh}', 'L', 'M', 'N', 'Ó', 'O', 'P', 'R', '{Rh}', 'S', '{Sh}', 'T', '{Th}', 'U', 'W', 'Y', 'Z', '{Zh}'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(némag),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(némag),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ródarátk),
						'north' => q({0} Shemál),
						'south' => q({0} Zerbár),
						'west' => q({0} Rónend),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ródarátk),
						'north' => q({0} Shemál),
						'south' => q({0} Zerbár),
						'west' => q({0} Rónend),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(karn),
						'one' => q({0} karn),
						'other' => q({0} karn),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(karn),
						'one' => q({0} karn),
						'other' => q({0} karn),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(róch),
						'one' => q({0} róch),
						'other' => q({0} róch),
						'per' => q({0}/róché),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(róch),
						'one' => q({0} róch),
						'other' => q({0} róch),
						'per' => q({0}/róché),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Dahekk),
						'one' => q({0} Dahekk),
						'other' => q({0} Dahekk),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Dahekk),
						'one' => q({0} Dahekk),
						'other' => q({0} Dahekk),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sáhat),
						'one' => q({0} sáhat),
						'other' => q({0} sáhat),
						'per' => q({0}/sáhaté),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sáhat),
						'one' => q({0} sáhat),
						'other' => q({0} sáhat),
						'per' => q({0}/sáhaté),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(máikrósekendh),
						'one' => q({0} máikrósekendh),
						'other' => q({0} máikrósekendh),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(máikrósekendh),
						'one' => q({0} máikrósekendh),
						'other' => q({0} máikrósekendh),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekendh),
						'one' => q({0} milisekendh),
						'other' => q({0} milisekendh),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekendh),
						'one' => q({0} milisekendh),
						'other' => q({0} milisekendh),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(meletth),
						'one' => q({0} meletth),
						'other' => q({0} meletth),
						'per' => q({0}/meletth),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(meletth),
						'one' => q({0} meletth),
						'other' => q({0} meletth),
						'per' => q({0}/meletth),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(máh),
						'one' => q({0} máh),
						'other' => q({0} máh),
						'per' => q({0}/máhé),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(máh),
						'one' => q({0} máh),
						'other' => q({0} máh),
						'per' => q({0}/máhé),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nénósekendh),
						'one' => q({0} nénósekendh),
						'other' => q({0} nénósekendh),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nénósekendh),
						'one' => q({0} nénósekendh),
						'other' => q({0} nénósekendh),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(shap),
						'one' => q({0} shap),
						'other' => q({0} shap),
						'per' => q({0}/shapé),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(shap),
						'one' => q({0} shap),
						'other' => q({0} shap),
						'per' => q({0}/shapé),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(chárek),
						'one' => q({0} chárek),
						'other' => q({0} chárek),
						'per' => q({0}/chárek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(chárek),
						'one' => q({0} chárek),
						'other' => q({0} chárek),
						'per' => q({0}/chárek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekendh),
						'one' => q({0} sekendh),
						'other' => q({0} sekendh),
						'per' => q({0}/sekendhé),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekendh),
						'one' => q({0} sekendh),
						'other' => q({0} sekendh),
						'per' => q({0}/sekendhé),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(haptag),
						'one' => q({0} haptag),
						'other' => q({0} haptag),
						'per' => q({0}/haptagé),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(haptag),
						'one' => q({0} haptag),
						'other' => q({0} haptag),
						'per' => q({0}/haptagé),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(sál),
						'one' => q({0} sál),
						'other' => q({0} sál),
						'per' => q({0}/sálé),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(sál),
						'one' => q({0} sál),
						'other' => q({0} sál),
						'per' => q({0}/sálé),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pks),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pks),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ppsm),
						'one' => q({0} ppsm),
						'other' => q({0} ppsm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ppsm),
						'one' => q({0} ppsm),
						'other' => q({0} ppsm),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santimitar),
						'one' => q({0} santimitar),
						'other' => q({0} santimitar),
						'per' => q({0}/santimitaré),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santimitar),
						'one' => q({0} santimitar),
						'other' => q({0} santimitar),
						'per' => q({0}/santimitaré),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(désimitar),
						'one' => q({0} désimitar),
						'other' => q({0} désimitar),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(désimitar),
						'one' => q({0} désimitar),
						'other' => q({0} désimitar),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilómitar),
						'per' => q({0}/kilómitaré),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilómitar),
						'per' => q({0}/kilómitaré),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mitar),
						'one' => q({0} mitar),
						'other' => q({0} mitar),
						'per' => q({0}/mitaré),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mitar),
						'one' => q({0} mitar),
						'other' => q({0} mitar),
						'per' => q({0}/mitaré),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(máikrómitar),
						'one' => q({0} máikrómitar),
						'other' => q({0} máikrómitar),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(máikrómitar),
						'one' => q({0} máikrómitar),
						'other' => q({0} máikrómitar),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Skándi-mil),
						'one' => q({0} Skándi-mil),
						'other' => q({0} Skándi-mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Skándi-mil),
						'one' => q({0} Skándi-mil),
						'other' => q({0} Skándi-mil),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimitar),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimitar),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nénómitar),
						'one' => q({0} nénómitar),
						'other' => q({0} nénómitar),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nénómitar),
						'one' => q({0} nénómitar),
						'other' => q({0} nénómitar),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikómitar),
						'one' => q({0} pikómitar),
						'other' => q({0} pikómitar),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikómitar),
						'one' => q({0} pikómitar),
						'other' => q({0} pikómitar),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(noktah),
						'one' => q({0} noktah),
						'other' => q({0} noktah),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(noktah),
						'one' => q({0} noktah),
						'other' => q({0} noktah),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(némag),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(némag),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ródarátk),
						'north' => q({0} Shemál),
						'south' => q({0} Zerbár),
						'west' => q({0} Rónend),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ródarátk),
						'north' => q({0} Shemál),
						'south' => q({0} Zerbár),
						'west' => q({0} Rónend),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(k),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(k),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(róch),
						'one' => q({0} róch),
						'other' => q({0} róch),
						'per' => q({0}/róché),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(róch),
						'one' => q({0} róch),
						'other' => q({0} róch),
						'per' => q({0}/róché),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Dah),
						'one' => q({0} Dah),
						'other' => q({0} Dah),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Dah),
						'one' => q({0} Dah),
						'other' => q({0} Dah),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sáhat),
						'one' => q({0} sáhat),
						'other' => q({0} sáhat),
						'per' => q({0}/sáhaté),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sáhat),
						'one' => q({0} sáhat),
						'other' => q({0} sáhat),
						'per' => q({0}/sáhaté),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(máikrósekendh),
						'one' => q({0} máikrósekendh),
						'other' => q({0} máikrósekendh),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(máikrósekendh),
						'one' => q({0} máikrósekendh),
						'other' => q({0} máikrósekendh),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekendh),
						'one' => q({0} milisekendh),
						'other' => q({0} milisekendh),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekendh),
						'one' => q({0} milisekendh),
						'other' => q({0} milisekendh),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(meletth),
						'one' => q({0} meletth),
						'other' => q({0} meletth),
						'per' => q({0}/meletth),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(meletth),
						'one' => q({0} meletth),
						'other' => q({0} meletth),
						'per' => q({0}/meletth),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(máh),
						'one' => q({0} máh),
						'other' => q({0} máh),
						'per' => q({0}/máhé),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(máh),
						'one' => q({0} máh),
						'other' => q({0} máh),
						'per' => q({0}/máhé),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nénósekendh),
						'one' => q({0} nénósekendh),
						'other' => q({0} nénósekendh),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nénósekendh),
						'one' => q({0} nénósekendh),
						'other' => q({0} nénósekendh),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(shap),
						'one' => q({0} shap),
						'other' => q({0} shap),
						'per' => q({0}/shapé),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(shap),
						'one' => q({0} shap),
						'other' => q({0} shap),
						'per' => q({0}/shapé),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(chárek),
						'one' => q({0} chárek),
						'other' => q({0} chárek),
						'per' => q({0}/chárek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(chárek),
						'one' => q({0} chárek),
						'other' => q({0} chárek),
						'per' => q({0}/chárek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekendh),
						'one' => q({0} sekendh),
						'other' => q({0} sekendh),
						'per' => q({0}/sekendhé),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekendh),
						'one' => q({0} sekendh),
						'other' => q({0} sekendh),
						'per' => q({0}/sekendhé),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(haptag),
						'one' => q({0} haptag),
						'other' => q({0} haptag),
						'per' => q({0}/haptagé),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(haptag),
						'one' => q({0} haptag),
						'other' => q({0} haptag),
						'per' => q({0}/haptagé),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(sl),
						'one' => q({0} sál),
						'other' => q({0} sál),
						'per' => q({0}/sál),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(sl),
						'one' => q({0} sál),
						'other' => q({0} sál),
						'per' => q({0}/sál),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pks),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pks),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ppsm),
						'one' => q({0} ppsm),
						'other' => q({0} ppsm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ppsm),
						'one' => q({0} ppsm),
						'other' => q({0} ppsm),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santimitar),
						'one' => q({0} santimitar),
						'other' => q({0} santimitar),
						'per' => q({0}/santimitar),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santimitar),
						'one' => q({0} santimitar),
						'other' => q({0} santimitar),
						'per' => q({0}/santimitar),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0} désimitar),
						'other' => q({0} désimitar),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0} désimitar),
						'other' => q({0} désimitar),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q({0}/kmé),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q({0}/kmé),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mitar),
						'one' => q({0} mitar),
						'other' => q({0} mitar),
						'per' => q({0}/mitaré),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mitar),
						'one' => q({0} mitar),
						'other' => q({0} mitar),
						'per' => q({0}/mitaré),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(máikrómitar),
						'one' => q({0} máikrómitar),
						'other' => q({0} máikrómitar),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(máikrómitar),
						'one' => q({0} máikrómitar),
						'other' => q({0} máikrómitar),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Skándi-mil),
						'one' => q({0} Skándi-mil),
						'other' => q({0} Skándi-mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Skándi-mil),
						'one' => q({0} Skándi-mil),
						'other' => q({0} Skándi-mil),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nénómitar),
						'one' => q({0} nénómitar),
						'other' => q({0} nénómitar),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nénómitar),
						'one' => q({0} nénómitar),
						'other' => q({0} nénómitar),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikómitar),
						'one' => q({0} pikómitar),
						'other' => q({0} pikómitar),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikómitar),
						'one' => q({0} pikómitar),
						'other' => q({0} pikómitar),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(noktah),
						'one' => q({0} noktah),
						'other' => q({0} noktah),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(noktah),
						'one' => q({0} noktah),
						'other' => q({0} noktah),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(némag),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(némag),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ródarátk),
						'north' => q({0} Shemál),
						'south' => q({0} Zerbár),
						'west' => q({0} Rónend),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ródarátk),
						'north' => q({0} Shemál),
						'south' => q({0} Zerbár),
						'west' => q({0} Rónend),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(k),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(k),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(róch),
						'one' => q({0} róch),
						'other' => q({0} róch),
						'per' => q({0}/róché),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(róch),
						'one' => q({0} róch),
						'other' => q({0} róch),
						'per' => q({0}/róché),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Dah),
						'one' => q({0} Dah),
						'other' => q({0} Dah),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Dah),
						'one' => q({0} Dah),
						'other' => q({0} Dah),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(st),
						'one' => q({0} sáhat),
						'other' => q({0} sáhat),
						'per' => q({0}/sáhaté),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(st),
						'one' => q({0} sáhat),
						'other' => q({0} sáhat),
						'per' => q({0}/sáhaté),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0} máikrósekendh),
						'other' => q({0} máikrósekendh),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0} máikrósekendh),
						'other' => q({0} máikrósekendh),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} milisekendh),
						'other' => q({0} milisekendh),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} milisekendh),
						'other' => q({0} milisekendh),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(meletth),
						'one' => q({0} meletth),
						'other' => q({0} meletth),
						'per' => q({0}/meletth),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(meletth),
						'one' => q({0} meletth),
						'other' => q({0} meletth),
						'per' => q({0}/meletth),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(máh),
						'one' => q({0} máh),
						'other' => q({0} máh),
						'per' => q({0}/máhé),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(máh),
						'one' => q({0} máh),
						'other' => q({0} máh),
						'per' => q({0}/máhé),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nénósekendh),
						'one' => q({0} nénósekendh),
						'other' => q({0} nénósekendh),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nénósekendh),
						'one' => q({0} nénósekendh),
						'other' => q({0} nénósekendh),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(shap),
						'one' => q({0} shap),
						'other' => q({0} shap),
						'per' => q({0}/shapé),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(shap),
						'one' => q({0} shap),
						'other' => q({0} shap),
						'per' => q({0}/shapé),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(chárek),
						'one' => q({0} chárek),
						'other' => q({0} chárek),
						'per' => q({0}/chárek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(chárek),
						'one' => q({0} chárek),
						'other' => q({0} chárek),
						'per' => q({0}/chárek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekendh),
						'one' => q({0} sekendh),
						'other' => q({0} sekendh),
						'per' => q({0}/sekendhé),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekendh),
						'one' => q({0} sekendh),
						'other' => q({0} sekendh),
						'per' => q({0}/sekendhé),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(haptag),
						'one' => q({0} haptag),
						'other' => q({0} haptag),
						'per' => q({0}/haptagé),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(haptag),
						'one' => q({0} haptag),
						'other' => q({0} haptag),
						'per' => q({0}/haptagé),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(sál),
						'one' => q({0} sál),
						'other' => q({0} sál),
						'per' => q({0}/sál),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(sál),
						'one' => q({0} sál),
						'other' => q({0} sál),
						'per' => q({0}/sál),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pks),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pks),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ppsm),
						'one' => q({0} ppsm),
						'other' => q({0} ppsm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ppsm),
						'one' => q({0} ppsm),
						'other' => q({0} ppsm),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'one' => q({0} santimitar),
						'other' => q({0} sm),
						'per' => q({0}/smé),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} santimitar),
						'other' => q({0} sm),
						'per' => q({0}/smé),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0} désimitar),
						'other' => q({0} désimitar),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0} désimitar),
						'other' => q({0} désimitar),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q({0}/kmé),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q({0}/kmé),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mitar),
						'one' => q({0} mitar),
						'other' => q({0} mitar),
						'per' => q({0}/mitaré),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mitar),
						'one' => q({0} mitar),
						'other' => q({0} mitar),
						'per' => q({0}/mitaré),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0} Skándi-mil),
						'other' => q({0} Skándi-mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0} Skándi-mil),
						'other' => q({0} Skándi-mil),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pikómitar),
						'other' => q({0} pikómitar),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pikómitar),
						'other' => q({0} pikómitar),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(nk),
						'one' => q({0} nk),
						'other' => q({0} noktah),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(nk),
						'one' => q({0} nk),
						'other' => q({0} noktah),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:haw|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:na|n)$' }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => '0H',
					'other' => '0H',
				},
				'10000' => {
					'one' => '00H',
					'other' => '00H',
				},
				'100000' => {
					'one' => '000H',
					'other' => '000H',
				},
				'1000000000' => {
					'one' => '0Kr',
					'other' => '0Kr',
				},
				'10000000000' => {
					'one' => '00Kr',
					'other' => '00Kr',
				},
				'100000000000' => {
					'one' => '000Kr',
					'other' => '000Kr',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0H',
					'other' => '0H',
				},
				'10000' => {
					'one' => '00H',
					'other' => '00H',
				},
				'100000' => {
					'one' => '000H',
					'other' => '000H',
				},
				'1000000000' => {
					'one' => '0Kr',
					'other' => '0Kr',
				},
				'10000000000' => {
					'one' => '00Kr',
					'other' => '00Kr',
				},
				'100000000000' => {
					'one' => '000Kr',
					'other' => '000Kr',
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
				'currency' => q(Emáráti Darham),
				'one' => q(Emáráti darham),
				'other' => q(Emáráti darham),
			},
		},
		'AFN' => {
			symbol => 'AWGA',
			display_name => {
				'currency' => q(Awgáni Awgáni),
				'one' => q(Awgáni Awgáni),
				'other' => q(Awgáni Awgáni),
			},
		},
		'ALL' => {
			symbol => 'ALBL',
			display_name => {
				'currency' => q(Albániái Lek),
				'one' => q(Albániái lek),
				'other' => q(Albániái lek),
			},
		},
		'AMD' => {
			symbol => 'ARMD',
			display_name => {
				'currency' => q(Árminiái Dram),
				'one' => q(Árminiái dram),
				'other' => q(Árminiái dram),
			},
		},
		'ANG' => {
			symbol => 'NLAG',
			display_name => {
				'currency' => q(Nedarlándi Antilli Gelder),
				'one' => q(Nedarlándi Antilli gelder),
				'other' => q(Nedarlándi Antilli gelder),
			},
		},
		'AOA' => {
			symbol => 'ANGK',
			display_name => {
				'currency' => q(Angólái Kwanzá),
				'one' => q(Angólái kwanzá),
				'other' => q(Angólái kwanzá),
			},
		},
		'ARS' => {
			symbol => 'ARJP',
			display_name => {
				'currency' => q(Arjentinái Paysó),
				'one' => q(Arjentinái paysó),
				'other' => q(Arjentinái paysó),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ástráliái Dhálar),
				'one' => q(Ástráliái dhálar),
				'other' => q(Ástráliái dhálar),
			},
		},
		'AWG' => {
			symbol => 'ARBF',
			display_name => {
				'currency' => q(Arubi Flórin),
				'one' => q(Arubi flórin),
				'other' => q(Arubi flórin),
			},
		},
		'AZN' => {
			symbol => 'AZRM',
			display_name => {
				'currency' => q(Ázerbáijáni Manat),
				'one' => q(Ázerbáijáni manat),
				'other' => q(Ázerbáijáni manat),
			},
		},
		'BAM' => {
			symbol => 'BHBM',
			display_name => {
				'currency' => q(Bósniá-Herzigówinái Badali Mark),
				'one' => q(Bósniá-Herzigówinái badali mark),
				'other' => q(Bósniá-Herzigówinái badali mark),
			},
		},
		'BBD' => {
			symbol => 'BRBD',
			display_name => {
				'currency' => q(Barbadi Dhálar),
				'one' => q(Barbadi dhálar),
				'other' => q(Barbadi dhálar),
			},
		},
		'BDT' => {
			symbol => 'BGDT',
			display_name => {
				'currency' => q(Bangaladéshi Thakká),
				'one' => q(Bangaladéshi thakká),
				'other' => q(Bangaladéshi thakká),
			},
		},
		'BGN' => {
			symbol => 'BLGL',
			display_name => {
				'currency' => q(Bulgáriái Lew),
				'one' => q(Bulgáriái lew),
				'other' => q(Bulgáriái lew),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreni Dinár),
				'one' => q(Bahreni dinár),
				'other' => q(Bahreni dinár),
			},
		},
		'BIF' => {
			symbol => 'BRDF',
			display_name => {
				'currency' => q(Burundi Fránk),
				'one' => q(Burundi fránk),
				'other' => q(Burundi fránk),
			},
		},
		'BMD' => {
			symbol => 'BRMD',
			display_name => {
				'currency' => q(Bermudá Dhálar),
				'one' => q(Bermudá Dhálar),
				'other' => q(Bermudá Dhálar),
			},
		},
		'BND' => {
			symbol => 'BRND',
			display_name => {
				'currency' => q(Brunái Dhálar),
				'one' => q(Brunái dhálar),
				'other' => q(Brunái dhálar),
			},
		},
		'BOB' => {
			symbol => 'BLWB',
			display_name => {
				'currency' => q(Boliwiái Boliwiánó),
				'one' => q(Boliwiái boliwiánó),
				'other' => q(Boliwiái boliwiánó),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brázili riál),
			},
		},
		'BSD' => {
			symbol => 'BHMD',
			display_name => {
				'currency' => q(Bahami Dhálar),
				'one' => q(Bahami dhálar),
				'other' => q(Bahami dhálar),
			},
		},
		'BTN' => {
			symbol => 'BTNN',
			display_name => {
				'currency' => q(Butháni Ngultrum),
				'one' => q(Butháni ngultrum),
				'other' => q(Butháni ngultrum),
			},
		},
		'BWP' => {
			symbol => 'BTSP',
			display_name => {
				'currency' => q(Botswánái Pulá),
				'one' => q(Botswánái pulá),
				'other' => q(Botswánái pulá),
			},
		},
		'BYN' => {
			symbol => 'BLRR',
			display_name => {
				'currency' => q(Bélárusi Rubel),
				'one' => q(Bélárusi rubel),
				'other' => q(Bélárusi rubel),
			},
		},
		'BZD' => {
			symbol => 'BLZD',
			display_name => {
				'currency' => q(Belizé Dhálar),
				'one' => q(Belizé dhálar),
				'other' => q(Belizé dhálar),
			},
		},
		'CAD' => {
			symbol => 'KN$',
			display_name => {
				'currency' => q(Kaynadhái Dhálar),
				'one' => q(Kaynadhái dhálar),
				'other' => q(Kaynadhái dhálar),
			},
		},
		'CDF' => {
			symbol => 'KNGF',
			display_name => {
				'currency' => q(Kángói Fránk),
				'one' => q(Kángói fránk),
				'other' => q(Kángói fránk),
			},
		},
		'CHF' => {
			symbol => 'SWZF',
			display_name => {
				'currency' => q(Swizi Fránk),
				'one' => q(Swizi fránk),
				'other' => q(Swizi fránk),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chilayi Paysó),
				'one' => q(Chilayi paysó),
				'other' => q(Chilayi paysó),
			},
		},
		'CNH' => {
			symbol => 'CNYÁ',
			display_name => {
				'currency' => q(Chini Yuán \(Ápshór\)),
				'one' => q(Chini yuán \(Ápshór\)),
				'other' => q(Chini yuán \(Ápshór\)),
			},
		},
		'CNY' => {
			symbol => 'CHNY',
			display_name => {
				'currency' => q(Chini Yuán),
				'one' => q(Chini yuán),
				'other' => q(Chini yuán),
			},
		},
		'COP' => {
			symbol => 'KLBP',
			display_name => {
				'currency' => q(Kolambiái Paysó),
				'one' => q(Kolambiái paysó),
				'other' => q(Kolambiái paysó),
			},
		},
		'CRC' => {
			symbol => 'KRK',
			display_name => {
				'currency' => q(Kóstá Rikái Kolón),
				'one' => q(Kóstá Rikái Kolón),
				'other' => q(Kóstá Rikái Kolón),
			},
		},
		'CUC' => {
			symbol => 'KBKP',
			display_name => {
				'currency' => q(Kyubái Badali Paysó),
				'one' => q(Kyubái badali paysó),
				'other' => q(Kyubái badali paysó),
			},
		},
		'CUP' => {
			symbol => 'CBAP',
			display_name => {
				'currency' => q(Kyubái Paysó),
				'one' => q(Kyubái paysó),
				'other' => q(Kyubái paysó),
			},
		},
		'CVE' => {
			symbol => 'KWRE',
			display_name => {
				'currency' => q(Kayp Werdi Eskudó),
				'one' => q(Kayp Werdi eskudó),
				'other' => q(Kayp Werdi eskudó),
			},
		},
		'CZK' => {
			symbol => 'CHKK',
			display_name => {
				'currency' => q(Chek Koruná),
				'one' => q(Chek koruná),
				'other' => q(Chek koruná),
			},
		},
		'DJF' => {
			symbol => 'DJBF',
			display_name => {
				'currency' => q(Djebuti Fránk),
				'one' => q(Djebuti fránk),
				'other' => q(Djebuti fránk),
			},
		},
		'DKK' => {
			symbol => 'DNMK',
			display_name => {
				'currency' => q(Danmárki Koron),
				'one' => q(Danmárki koron),
				'other' => q(Danmárki koron),
			},
		},
		'DOP' => {
			symbol => 'DOMP',
			display_name => {
				'currency' => q(Dominiki Paysó),
				'one' => q(Dominiki paysó),
				'other' => q(Dominiki paysó),
			},
		},
		'DZD' => {
			symbol => 'ALJD',
			display_name => {
				'currency' => q(Aljiriái Dinár),
				'one' => q(Aljiriái dinár),
				'other' => q(Aljiriái dinár),
			},
		},
		'EGP' => {
			symbol => 'MSRP',
			display_name => {
				'currency' => q(Mesri Pawndh),
				'one' => q(Mesri pawndh),
				'other' => q(Mesri pawndh),
			},
		},
		'ERN' => {
			symbol => 'ERTN',
			display_name => {
				'currency' => q(Eritiriái Nakfá),
				'one' => q(Eritiriái nakfá),
				'other' => q(Eritiriái nakfá),
			},
		},
		'ETB' => {
			symbol => 'ETPB',
			display_name => {
				'currency' => q(Etiupiái Birr),
				'one' => q(Etiupiái birr),
				'other' => q(Etiupiái birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuró),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fiji Dhálar),
				'one' => q(Fiji dhálar),
				'other' => q(Fiji dhálar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Fálklánd Islándi Pawndh),
				'one' => q(Fálklánd Islándi pawndh),
				'other' => q(Fálklánd Islándi pawndh),
			},
		},
		'GBP' => {
			symbol => 'BRTP',
			display_name => {
				'currency' => q(Bartáni pawndh),
			},
		},
		'GEL' => {
			symbol => 'JRJL',
			display_name => {
				'currency' => q(Járjiái Lari),
				'one' => q(Járjiái lari),
				'other' => q(Járjiái lari),
			},
		},
		'GHS' => {
			symbol => 'GNAS',
			display_name => {
				'currency' => q(Gánái Sédi),
				'one' => q(Gánái sédi),
				'other' => q(Gánái sédi),
			},
		},
		'GIP' => {
			symbol => 'GBRP',
			display_name => {
				'currency' => q(Gibraltar Pawndh),
				'one' => q(Gibraltar pawndh),
				'other' => q(Gibraltar pawndh),
			},
		},
		'GMD' => {
			symbol => 'GMBD',
			display_name => {
				'currency' => q(Gambiái Dalasi),
				'one' => q(Gambiái dalasi),
				'other' => q(Gambiái dalasi),
			},
		},
		'GNF' => {
			symbol => 'GWNF',
			display_name => {
				'currency' => q(Gwiniái Fránk),
				'one' => q(Gwiniái fránk),
				'other' => q(Gwiniái fránk),
			},
		},
		'GTQ' => {
			symbol => 'GTMK',
			display_name => {
				'currency' => q(Gwátemálái Kwetzal),
				'one' => q(Gwátemálái Kwetzal),
				'other' => q(Gwátemálái Kwetzal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Góyánái Dhálar),
				'one' => q(Góyánái dhálar),
				'other' => q(Góyánái dhálar),
			},
		},
		'HKD' => {
			symbol => 'HGKD',
			display_name => {
				'currency' => q(Háng Káng Dhálar),
				'one' => q(Háng Káng dhálar),
				'other' => q(Háng Káng dhálar),
			},
		},
		'HNL' => {
			symbol => 'HNDL',
			display_name => {
				'currency' => q(Hondurái Lempirá),
				'one' => q(Hondurái lempirá),
				'other' => q(Hondurái lempirá),
			},
		},
		'HRK' => {
			symbol => 'KRSK',
			display_name => {
				'currency' => q(Króáshiái Kuná),
				'one' => q(Króáshiái kuná),
				'other' => q(Króáshiái kuná),
			},
		},
		'HTG' => {
			symbol => 'HTNG',
			display_name => {
				'currency' => q(Haiti Gurde),
				'one' => q(Haiti gurde),
				'other' => q(Haiti gurde),
			},
		},
		'HUF' => {
			symbol => 'HGRF',
			display_name => {
				'currency' => q(Hungáriái Forint),
				'one' => q(Hungáriái forint),
				'other' => q(Hungáriái forint),
			},
		},
		'IDR' => {
			symbol => 'ENDR',
			display_name => {
				'currency' => q(Endhónishiái Rupiá),
				'one' => q(Endhónishiái rupiá),
				'other' => q(Endhónishiái rupiá),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Esráili Nókén Shekel),
				'one' => q(Esráili nókén shekel),
				'other' => q(Esráili nókén shekel),
			},
		},
		'INR' => {
			symbol => 'HNDR',
			display_name => {
				'currency' => q(Hendostáni Rupi),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Eráki Dinár),
				'one' => q(Eráki dinár),
				'other' => q(Eráki dinár),
			},
		},
		'IRR' => {
			symbol => 'ERNR',
			display_name => {
				'currency' => q(Éráni Ryál),
			},
		},
		'ISK' => {
			symbol => 'ISLK',
			display_name => {
				'currency' => q(Isláni Króná),
				'one' => q(Isláni króná),
				'other' => q(Isláni króná),
			},
		},
		'JMD' => {
			symbol => 'JMKD',
			display_name => {
				'currency' => q(Jamáiki Dhálar),
				'one' => q(Jamáiki dhálar),
				'other' => q(Jamáiki dhálar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Ordoni Dinár),
				'one' => q(Ordoni dinár),
				'other' => q(Ordoni dinár),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Jápáni Yen),
			},
		},
		'KES' => {
			symbol => 'KINS',
			display_name => {
				'currency' => q(Kinyái Shilling),
				'one' => q(Kinyái shilling),
				'other' => q(Kinyái shilling),
			},
		},
		'KGS' => {
			symbol => 'KGSS',
			display_name => {
				'currency' => q(Kargestáni Som),
				'one' => q(Kargestáni som),
				'other' => q(Kargestáni som),
			},
		},
		'KHR' => {
			symbol => 'KMBR',
			display_name => {
				'currency' => q(Kambódhiái Riél),
				'one' => q(Kambódhiái riél),
				'other' => q(Kambódhiái riél),
			},
		},
		'KMF' => {
			symbol => 'KMRF',
			display_name => {
				'currency' => q(Komóriái Éránk),
				'one' => q(Komóriái fránk),
				'other' => q(Komóriái fránk),
			},
		},
		'KPW' => {
			symbol => 'SHKW',
			display_name => {
				'currency' => q(Shemáli Kóriái Won),
				'one' => q(Shemáli Kóriái won),
				'other' => q(Shemáli Kóriái won),
			},
		},
		'KRW' => {
			symbol => 'ZBKW',
			display_name => {
				'currency' => q(Zerbári Kóriái Won),
				'one' => q(Zerbári Kóriái won),
				'other' => q(Zerbári Kóriái won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kwayti Dinár),
				'one' => q(Kwayti dinár),
				'other' => q(Kwayti dinár),
			},
		},
		'KYD' => {
			symbol => 'KMID',
			display_name => {
				'currency' => q(Kayman Islándi Dhálar),
				'one' => q(Kayman Islándi dhálar),
				'other' => q(Kayman Islándi dhálar),
			},
		},
		'KZT' => {
			symbol => 'KZKT',
			display_name => {
				'currency' => q(Kázakestáni Tengé),
				'one' => q(Kázakestáni tengé),
				'other' => q(Kázakestáni tengé),
			},
		},
		'LAK' => {
			symbol => 'LTKK',
			display_name => {
				'currency' => q(Laótiái Kip),
				'one' => q(Laótiái kip),
				'other' => q(Laótiái kip),
			},
		},
		'LBP' => {
			symbol => 'LBNP',
			display_name => {
				'currency' => q(Lebnáni Pawndh),
				'one' => q(Lebnáni pawndh),
				'other' => q(Lebnáni pawndh),
			},
		},
		'LKR' => {
			symbol => 'SRLR',
			display_name => {
				'currency' => q(Sri Lankái Rupi),
				'one' => q(Sri Lankái rupi),
				'other' => q(Sri Lankái rupi),
			},
		},
		'LRD' => {
			symbol => 'LBRD',
			display_name => {
				'currency' => q(Láibiriái Dhálar),
				'one' => q(Láibiriái dhálar),
				'other' => q(Láibiriái dhálar),
			},
		},
		'LSL' => {
			symbol => 'LSTL',
			display_name => {
				'currency' => q(Lesótó Lóti),
				'one' => q(Lesótó lóti),
				'other' => q(Lesótó lóti),
			},
		},
		'LYD' => {
			symbol => 'LBYD',
			display_name => {
				'currency' => q(Libyái Dinár),
				'one' => q(Libyái dinár),
				'other' => q(Libyái dinár),
			},
		},
		'MAD' => {
			symbol => 'MRKD',
			display_name => {
				'currency' => q(Mórokói Darham),
				'one' => q(Mórokói darham),
				'other' => q(Mórokói darham),
			},
		},
		'MDL' => {
			symbol => 'MLDL',
			display_name => {
				'currency' => q(Moldówi Leu),
				'one' => q(Moldówi leu),
				'other' => q(Moldówi leu),
			},
		},
		'MGA' => {
			symbol => 'MLGA',
			display_name => {
				'currency' => q(Malagasi Ariári),
				'one' => q(Malagasi ariári),
				'other' => q(Malagasi ariári),
			},
		},
		'MKD' => {
			symbol => 'MKDD',
			display_name => {
				'currency' => q(Makduniái Dinár),
				'one' => q(Makduniái dinár),
				'other' => q(Makduniái dinár),
			},
		},
		'MMK' => {
			symbol => 'MNMK',
			display_name => {
				'currency' => q(Myanmár Kyát),
				'one' => q(Myanmár kyát),
				'other' => q(Myanmár kyát),
			},
		},
		'MNT' => {
			symbol => 'MNGT',
			display_name => {
				'currency' => q(Mongóliái Tugrik),
				'one' => q(Mongóliái tugrik),
				'other' => q(Mongóliái tugrik),
			},
		},
		'MOP' => {
			symbol => 'MKNP',
			display_name => {
				'currency' => q(Makani Pataká),
				'one' => q(Makani pataká),
				'other' => q(Makani pataká),
			},
		},
		'MRU' => {
			symbol => 'MRTU',
			display_name => {
				'currency' => q(Mauritániái Ugwiyá),
				'one' => q(Mauritániái ugwiyá),
				'other' => q(Mauritániái ugwiyá),
			},
		},
		'MUR' => {
			symbol => 'MURR',
			display_name => {
				'currency' => q(Muritániái Rupi),
				'one' => q(Muritániái rupi),
				'other' => q(Muritániái rupi),
			},
		},
		'MVR' => {
			symbol => 'MLDR',
			display_name => {
				'currency' => q(Máldipi Rupiyá),
				'one' => q(Máldipi rupiyá),
				'other' => q(Máldipi rupiyá),
			},
		},
		'MWK' => {
			symbol => 'MLWK',
			display_name => {
				'currency' => q(Malawi Kwachá),
				'one' => q(Malawi kwachá),
				'other' => q(Malawi kwachá),
			},
		},
		'MXN' => {
			symbol => 'MKS$',
			display_name => {
				'currency' => q(Meksikói Paysó),
				'one' => q(Meksikói paysó),
				'other' => q(Meksikói paysó),
			},
		},
		'MYR' => {
			symbol => 'MLRG',
			display_name => {
				'currency' => q(Malishiái Ringgit),
				'one' => q(Malishiái ringgit),
				'other' => q(Malishiái ringgit),
			},
		},
		'MZN' => {
			symbol => 'MZBM',
			display_name => {
				'currency' => q(Mózambiki Metikal),
				'one' => q(Mózambiki metikal),
				'other' => q(Mózambiki metikal),
			},
		},
		'NAD' => {
			symbol => 'NMBD',
			display_name => {
				'currency' => q(Namibiái Dhálar),
				'one' => q(Namibiái dhálar),
				'other' => q(Namibiái dhálar),
			},
		},
		'NGN' => {
			symbol => 'NJRN',
			display_name => {
				'currency' => q(Náijiriái Nairá),
				'one' => q(Náijiriái nairá),
				'other' => q(Náijiriái nairá),
			},
		},
		'NIO' => {
			symbol => 'NKGC',
			display_name => {
				'currency' => q(Nikárágóái Kordobá),
				'one' => q(Nikárágóái kordobá),
				'other' => q(Nikárágóái kordobá),
			},
		},
		'NOK' => {
			symbol => 'NRWK',
			display_name => {
				'currency' => q(Nárwéji Koron),
				'one' => q(Nárwéji koron),
				'other' => q(Nárwéji koron),
			},
		},
		'NPR' => {
			symbol => 'NPLR',
			display_name => {
				'currency' => q(Népáli Rupi),
				'one' => q(Népáli rupi),
				'other' => q(Népáli rupi),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Nyu Zilánd Dhálar),
				'one' => q(Nyu Zilánd dhálar),
				'other' => q(Nyu Zilánd dhálar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Ománi Riál),
				'one' => q(Ománi riál),
				'other' => q(Ománi riál),
			},
		},
		'PAB' => {
			symbol => 'PNMB',
			display_name => {
				'currency' => q(Panamániái Balbóá),
				'one' => q(Panamániái balbóá),
				'other' => q(Panamániái balbóá),
			},
		},
		'PEN' => {
			symbol => 'PRSL',
			display_name => {
				'currency' => q(Péruwi Sól),
				'one' => q(Péruwi sól),
				'other' => q(Péruwi sól),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Pápuá Nyu Gwini Kiná),
				'one' => q(Pápuá Nyu Gwini kiná),
				'other' => q(Pápuá Nyu Gwini kiná),
			},
		},
		'PHP' => {
			symbol => 'PLPP',
			display_name => {
				'currency' => q(Pelpini Paysó),
				'one' => q(Pelpini paysó),
				'other' => q(Pelpini paysó),
			},
		},
		'PKR' => {
			symbol => 'PKRS',
			display_name => {
				'currency' => q(Pákestáni Rupi),
			},
		},
		'PLN' => {
			symbol => 'PLNZ',
			display_name => {
				'currency' => q(Pólándi Zlóti),
				'one' => q(Pólándi zlóti),
				'other' => q(Pólándi zlóti),
			},
		},
		'PYG' => {
			symbol => 'PRGG',
			display_name => {
				'currency' => q(Payráguyái Gwarani),
				'one' => q(Payráguyái gwarani),
				'other' => q(Payráguyái gwarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Gatari Riál),
				'one' => q(Gatari riál),
				'other' => q(Gatari riál),
			},
		},
		'RON' => {
			symbol => 'RMNL',
			display_name => {
				'currency' => q(Rumániái Leu),
				'one' => q(Rumániái leu),
				'other' => q(Rumániái leu),
			},
		},
		'RSD' => {
			symbol => 'SRBD',
			display_name => {
				'currency' => q(Sarbiái Dinár),
				'one' => q(Sarbiái dinár),
				'other' => q(Sarbiái dinár),
			},
		},
		'RUB' => {
			symbol => 'RUSR',
			display_name => {
				'currency' => q(Rusi Rubel),
			},
		},
		'RWF' => {
			symbol => 'RWDF',
			display_name => {
				'currency' => q(Rwándái Fránk),
				'one' => q(Rwándái fránk),
				'other' => q(Rwándái fránk),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riál),
				'one' => q(Saudi riál),
				'other' => q(Saudi riál),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomán Islánd Dhálar),
				'one' => q(Solomán Islánd dhálar),
				'other' => q(Solomán Islánd dhálar),
			},
		},
		'SCR' => {
			symbol => 'SCLR',
			display_name => {
				'currency' => q(Seychelli Rupi),
				'one' => q(Seychelli rupi),
				'other' => q(Seychelli rupi),
			},
		},
		'SDG' => {
			symbol => 'SDNP',
			display_name => {
				'currency' => q(Sudáni Pawndh),
				'one' => q(Sudáni pawndh),
				'other' => q(Sudáni pawndh),
			},
		},
		'SEK' => {
			symbol => 'SWDK',
			display_name => {
				'currency' => q(Swidi Koron),
				'one' => q(Swidi koron),
				'other' => q(Swidi koron),
			},
		},
		'SGD' => {
			symbol => 'SGPD',
			display_name => {
				'currency' => q(Singápur Dhálar),
				'one' => q(Singápur dhálar),
				'other' => q(Singápur dhálar),
			},
		},
		'SHP' => {
			symbol => 'SHLP',
			display_name => {
				'currency' => q(St. Helénái Pawndh),
				'one' => q(St. Helénái pawndh),
				'other' => q(St. Helénái pawndh),
			},
		},
		'SLE' => {
			symbol => 'SLNL',
			display_name => {
				'currency' => q(Siérá Leóni León),
				'one' => q(Siérá Leóni león),
				'other' => q(Siérá Leóni león),
			},
		},
		'SLL' => {
			symbol => 'SRLL',
			display_name => {
				'currency' => q(Siérá Leóni León \(1964—2022\)),
				'one' => q(Siérá Leóni león \(1964—2022\)),
				'other' => q(Siérá Leóni león \(1964—2022\)),
			},
		},
		'SOS' => {
			symbol => 'SÓMS',
			display_name => {
				'currency' => q(Sómáli Shilling),
				'one' => q(Sómáli shilling),
				'other' => q(Sómáli shilling),
			},
		},
		'SRD' => {
			symbol => 'SRND',
			display_name => {
				'currency' => q(Surinami Dhálar),
				'one' => q(Surinami dhálar),
				'other' => q(Surinami dhálar),
			},
		},
		'SSP' => {
			symbol => 'ZRSP',
			display_name => {
				'currency' => q(Zerbári Sudáni Pawndh),
				'one' => q(Zerbári Sudáni pawndh),
				'other' => q(Zerbári Sudáni pawndh),
			},
		},
		'STN' => {
			symbol => 'STPD',
			display_name => {
				'currency' => q(Sáó Tómé o Prensip Dobrá),
				'one' => q(Sáó Tómé o Prensip dobrá),
				'other' => q(Sáó Tómé o Prensip dobrá),
			},
		},
		'SYP' => {
			symbol => 'SURP',
			display_name => {
				'currency' => q(Suriái Pawndh),
				'one' => q(Suriái pawndh),
				'other' => q(Suriái pawndh),
			},
		},
		'SZL' => {
			symbol => 'SWZL',
			display_name => {
				'currency' => q(Swázi Lilangeni),
				'one' => q(Swázi lilangeni),
				'other' => q(Swázi lilangeni),
			},
		},
		'THB' => {
			symbol => 'TÁIB',
			display_name => {
				'currency' => q(Tái Baht),
				'one' => q(Tái baht),
				'other' => q(Tái baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tájekestáni Somoni),
				'one' => q(Tájekestáni somoni),
				'other' => q(Tájekestáni somoni),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(TRKM),
				'one' => q(Torkmánestáni manat),
				'other' => q(Torkmánestáni manat),
			},
		},
		'TND' => {
			symbol => 'TNSD',
			display_name => {
				'currency' => q(Tunisi Dinár),
				'one' => q(Tunisi dinár),
				'other' => q(Tunisi dinár),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongan Pángá),
				'one' => q(Tongan pángá),
				'other' => q(Tongan pángá),
			},
		},
		'TRY' => {
			symbol => 'TRKL',
			display_name => {
				'currency' => q(Torki Lirá),
				'one' => q(Torki lirá),
				'other' => q(Torki lirá),
			},
		},
		'TTD' => {
			symbol => 'TDTD',
			display_name => {
				'currency' => q(Trinidadi o Tobagó Dhálar),
				'one' => q(Trinidadi o Tobagó dhálar),
				'other' => q(Trinidadi o Tobagó dhálar),
			},
		},
		'TWD' => {
			symbol => 'NTWD',
			display_name => {
				'currency' => q(Nyu Táiwán Dhálar),
				'one' => q(Nyu Táiwán dhálar),
				'other' => q(Nyu Táiwán dhálar),
			},
		},
		'TZS' => {
			symbol => 'TNZS',
			display_name => {
				'currency' => q(Tanzániái Shilling),
				'one' => q(Tanzániái shilling),
				'other' => q(Tanzániái shilling),
			},
		},
		'UAH' => {
			symbol => 'YKNH',
			display_name => {
				'currency' => q(Yukrayni Hriwniá),
				'one' => q(Yukrayni hriwniá),
				'other' => q(Yukrayni hriwniá),
			},
		},
		'UGX' => {
			symbol => 'YUGS',
			display_name => {
				'currency' => q(Yugandhái Shilling),
				'one' => q(Yugandhái shilling),
				'other' => q(Yugandhái shilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Amriki dhálar),
			},
		},
		'UYU' => {
			symbol => 'YRGP',
			display_name => {
				'currency' => q(Yurógóyái Paysó),
				'one' => q(Yurógóyái paysó),
				'other' => q(Yurógóyái paysó),
			},
		},
		'UZS' => {
			symbol => 'OZBS',
			display_name => {
				'currency' => q(Ozbekestáni Som),
				'one' => q(Ozbekestáni som),
				'other' => q(Ozbekestáni som),
			},
		},
		'VES' => {
			symbol => 'WNZB',
			display_name => {
				'currency' => q(Wénezwélái Boliwar),
				'one' => q(Wénezwélái boliwar),
				'other' => q(Wénezwélái boliwar),
			},
		},
		'VND' => {
			symbol => 'WTND',
			display_name => {
				'currency' => q(Wietnámi Dong),
				'one' => q(Wietnámi dong),
				'other' => q(Wietnámi dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Wanuátu Wátu),
				'one' => q(Wanuátu wátu),
				'other' => q(Wanuátu wátu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samóan Talá),
				'one' => q(Samóan talá),
				'other' => q(Samóan talá),
			},
		},
		'XAF' => {
			symbol => 'DARF',
			display_name => {
				'currency' => q(Delgáhi Aprikái CFA Fránk),
				'one' => q(Delgáhi Aprikái CFA fránk),
				'other' => q(Delgáhi Aprikái CFA fránk),
			},
		},
		'XCD' => {
			symbol => 'RKB$',
			display_name => {
				'currency' => q(Ródarátki Karibiái Dhálar),
				'one' => q(Ródarátki Karibiái dhálar),
				'other' => q(Ródarátki Karibiái dhálar),
			},
		},
		'XOF' => {
			symbol => 'RACF',
			display_name => {
				'currency' => q(Rónendi Aprikái CFA Fránk),
				'one' => q(Rónendi Aprikái CFA fránk),
				'other' => q(Rónendi Aprikái CFA fránk),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Fránk),
				'one' => q(CFP fránk),
				'other' => q(CFP fránk),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Nazántagén Zarr),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yamani Riál),
				'one' => q(Yamani riál),
				'other' => q(Yamani riál),
			},
		},
		'ZAR' => {
			symbol => 'ZAPR',
			display_name => {
				'currency' => q(Zerbári Aprikái Rand),
				'one' => q(Zerbári Aprikái rand),
				'other' => q(Zerbári Aprikái rand),
			},
		},
		'ZMW' => {
			symbol => 'ZMBK',
			display_name => {
				'currency' => q(Zambiái Kwachá),
				'one' => q(Zambiái kwachá),
				'other' => q(Zambiái kwachá),
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
							'Jan',
							'Par',
							'Már',
							'Apr',
							'Mai',
							'Jun',
							'Jól',
							'Aga',
							'Sat',
							'Akt',
							'Naw',
							'Das'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janwari',
							'Parwari',
							'Márch',
							'Aprél',
							'Mai',
							'Jun',
							'Jólái',
							'Agast',
							'Satambar',
							'Aktubar',
							'Nawambar',
							'Dasambar'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Moh.',
							'Sap.',
							'Rab. I',
							'Rab. II',
							'Jam. I',
							'Jam. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Zol-K.',
							'Zol-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Moharram',
							'Sapar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jamádi I',
							'Jamádi II',
							'Rajab',
							'Shábán',
							'Ramezán',
							'Shauwál',
							'Zolkáda',
							'Zolhajj'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Moh.',
							'Sap.',
							'Rab. I',
							'Rab. II',
							'Jam. I',
							'Jam. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Zol-K.',
							'Zol-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Moharram',
							'Sapar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jamádi I',
							'Jamádi II',
							'Rajab',
							'Shábán',
							'Ramezán',
							'Shauwál',
							'Zolkáda',
							'Zolhajj'
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
						mon => 'Do',
						tue => 'Say',
						wed => 'Chá',
						thu => 'Pan',
						fri => 'Jom',
						sat => 'Sha',
						sun => 'Yak'
					},
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ch',
						thu => 'P',
						fri => 'J',
						sat => 'Sh',
						sun => 'Y'
					},
					wide => {
						mon => 'Doshambeh',
						tue => 'Sayshambeh',
						wed => 'Chárshambeh',
						thu => 'Panchshambeh',
						fri => 'Jomah',
						sat => 'Shambeh',
						sun => 'Yakshambeh'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ch',
						thu => 'P',
						fri => 'J',
						sat => 'Sh',
						sun => 'Y'
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
					abbreviated => {0 => '1/4',
						1 => '2/4',
						2 => '3/4',
						3 => '4/4'
					},
					wide => {0 => 'awali chárek',
						1 => 'domi chárek',
						2 => 'sayomi chárek',
						3 => 'cháromi chárek'
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
					'am' => q{am},
					'pm' => q{pm},
				},
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{am},
					'pm' => q{pm},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{am},
					'pm' => q{pm},
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
		'chinese' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'PM',
				'1' => 'AD'
			},
			narrow => {
				'0' => 'PM',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Péshmilád',
				'1' => 'Annó Domini'
			},
		},
		'islamic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'gregorian' => {
			'full' => q{dd,MM,y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/yy},
		},
		'islamic' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'gregorian' => {
			'full' => q{hh:mm:ss a zzzz},
			'long' => q{hh:mm:ss a zzz},
			'medium' => q{hh:mm:ss a},
			'short' => q{hh:mm a},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			hm => q{h:mm},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			yMMMd => q{MM,dd,y},
			yMd => q{d/M/y},
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
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(garmág shoru),
						1 => q(hawray áp),
						2 => q(kerm),
					},
				},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#Awgánestánay wahd#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Ábedján#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkrá#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababá#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmará#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamakó#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantiray#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzawilay#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujombura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Káeró#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanká#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Kyutá#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dár es salám#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djebóti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douálá#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Áiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Peritháón#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaboroné#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Haráré#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesbarg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Jubá#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampála#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kenshása#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagós#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librewilay#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lómé#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luandá#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbáshi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusáká#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malábó#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputó#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maséró#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabané#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mógádéshó#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrówiá#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nérubi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamená#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niaméy#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakshott#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Portó-Nówó#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sáó Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripóli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunes#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Delgáhi Aprikáay wahd#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ródarátki Aprikáay wahd#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ródarátki Aprikáay anjári wahd#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Rónendi Aprikáay garmági wahd#,
				'generic' => q#Rónendi Aprikáay wahd#,
				'standard' => q#Rónendi Aprikáay anjári wahd#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aláskáay garmági wahd#,
				'generic' => q#Aláskáay wahd#,
				'standard' => q#Aláskáay anjári wahd#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amázónay garmági wahd#,
				'generic' => q#Amázónay wahd#,
				'standard' => q#Amázónay anjári wahd#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchoragé#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguillá#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antiguá#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushwáiá#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arubá#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunchión#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderás#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanch-Sablón#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Bóá Wistá#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambrej Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Champo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Chanchun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Charakás#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Chatamarká#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Chayenn#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Shekágó#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahuá#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Chiudad Juárez#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikókan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kortoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kóstá Riká#,
		},
		'America/Creston' => {
			exemplarCity => q#Krestón#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kwaibá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Chorácháó#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshawn#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Krék#,
		},
		'America/Denver' => {
			exemplarCity => q#Denwér#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominiká#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Irunépé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salwadór#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Portalezá#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glays Bay#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenadá#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gwádelóp#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gwátémálá#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Gwáyakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyána#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Hawáná#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knoks, Indiáná#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengó Indiáná#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiáná#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell Sithi, Indiáná#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Weway, Indiáná#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Winsennes, Indiáná#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamak, Indiáná#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indiánápolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuwik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikálwit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamáeká#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jojui#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juniu#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montichelló, Kentuki#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Lá Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Limá#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Lás Enjeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luiswillay#,
		},
		'America/Maceio' => {
			exemplarCity => q#Machió#,
		},
		'America/Martinique' => {
			exemplarCity => q#Matinik#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendozá#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksikó Shahr#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mekwelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterray#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montewidió#,
		},
		'America/New_York' => {
			exemplarCity => q#Nyu Yárk#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronhá#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Nárt Dakótá#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Santhar, Nárt Dakótá#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nyu Salem, Nárt Dakótá#,
		},
		'America/Panama' => {
			exemplarCity => q#Panámá#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribó#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Póeniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Pórt-au-Prens#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Pórt Espin#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Portó welhó#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puertó Rikó#,
		},
		'America/Recife' => {
			exemplarCity => q#Rechipé#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resólut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rió Brankó#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiagó#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santó Domingó#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sáó Pauló#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittokkorturmit#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lusiá#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Tómas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Winsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Karrant#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Teguchigalpá#,
		},
		'America/Thule' => {
			exemplarCity => q#Tulé#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuána#,
		},
		'America/Toronto' => {
			exemplarCity => q#Torontó#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortolá#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Wankuwar#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Delgáhi Amrikáay garmági wahd#,
				'generic' => q#Delgáhi Amrikáay wahd#,
				'standard' => q#Delgáhi Amrikáay anjári wahd#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Amrikáay garmági wahd#,
				'generic' => q#Ródarátki Amrikáay wahd#,
				'standard' => q#Ródarátki Amrikáay anjári wahd#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Kóhestagi Amrikáay garmági wahd#,
				'generic' => q#Kóhestagi Amrikáay wahd#,
				'standard' => q#Kóhestagi Amrikáay anjári wahd#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Árámzeri Amrikáay garmági wahd#,
				'generic' => q#Árámzeri Amrikáay wahd#,
				'standard' => q#Árámzeri Amrikáay anjári wahd#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kásé#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dawis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont Urwila#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makwáer#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syówá#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apiáay róchi wahd#,
				'generic' => q#Apiáay wahd#,
				'standard' => q#Apiáay anjári wahd#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabi róchi wahd#,
				'generic' => q#Arabi wahd#,
				'standard' => q#Arabi anjári wahd#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Arjentináay garmági wahd#,
				'generic' => q#Arjentináay wahd#,
				'standard' => q#Arjentináay anjári wahd#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Rónendi Arjentináay gramági wahd#,
				'generic' => q#Rónendi Arjentináay wahd#,
				'standard' => q#Rónendi Arjentináay anjári wahd#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Árminiáay garmági wahd#,
				'generic' => q#Árminiáay wahd#,
				'standard' => q#Árminiáay anjári wahd#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adan#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktubé#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdád#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahren#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Báku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bengkák#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bérut#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunái#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkata#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kólambó#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damáskas#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dháka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dehli#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dabai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Doshambeh#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Pamagustá#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrón#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Háng Káng#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hówd#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakártá#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jaypur#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Urshalim#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kábol#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karáchi#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandiga#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kwálá Lampur#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kwayt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makáó#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikóshiá#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Orál#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyongyáng#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Gatar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kastanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilordá#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Ryáz#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hó Chi Menn#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seól#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shangái#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sengápur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekólimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Táipi#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Táshkand#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tebilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehrán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimpu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tókyó#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulánbátar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumki#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Wientiáné#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwóstok#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerewán#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantáay róchi wahd#,
				'generic' => q#Atlantáay wahd#,
				'standard' => q#Atlantáay anjári wahd#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azóres#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaray#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Wardé#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjawik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Shemáli Járjiá#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helená#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stánlé#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adiléd#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yuklá#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melborn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sedhni#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Delgáhi Ástréliáay garmági wahd#,
				'generic' => q#Delgáhi Ástréliáay wahd#,
				'standard' => q#Delgáhi Ástréliáay anjári wahd#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Delgáhirónendi Ástréliáay garmági wahd#,
				'generic' => q#Delgáhirónendi Ástréliáay wahd#,
				'standard' => q#Delgáhirónendi Ástréliáay anjári wahd#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Ástréliáay garmági wahd#,
				'generic' => q#Ródarátki Ástréliáay wahd#,
				'standard' => q#Ródarátki Ástréliáay anjári wahd#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Rónendi Ástréliáay garmági wahd#,
				'generic' => q#Rónendi Ástréliáay wahd#,
				'standard' => q#Rónendi Ástréliáay anjári wahd#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ázerbáijánay garmági wahd#,
				'generic' => q#Ázerbáijánay wahd#,
				'standard' => q#Ázerbáijánay anjári wahd#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azóresay garmági wahd#,
				'generic' => q#Azóresay wahd#,
				'standard' => q#Azóresay anjári wahd#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangaladéshay garmági wahd#,
				'generic' => q#Bangaladéshay wahd#,
				'standard' => q#Bangaladéshay anjári wahd#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Buthánay wahd#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliwiáay wahd#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brázilay garmági wahd#,
				'generic' => q#Brázilay wahd#,
				'standard' => q#Brázilay anjári wahd#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunáiay wahd#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kap Wardéay garmági wahd#,
				'generic' => q#Kap Wardéay wahd#,
				'standard' => q#Kap Wardéay anjári wahd#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorróay wahd#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatam róchi wahd#,
				'generic' => q#Chatam wahd#,
				'standard' => q#Chatam anjári wahd#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilayay garmági wahd#,
				'generic' => q#Chilayay wahd#,
				'standard' => q#Chilayay anjári wahd#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chinay róchi wahd#,
				'generic' => q#Chinay wahd#,
				'standard' => q#Chinay anjári wahd#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Kresmes Islánday wahd#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kukus Islánday wahd#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolambiáay garmági wahd#,
				'generic' => q#Kolambiáay wahd#,
				'standard' => q#Kolambiáay anjári wahd#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kuk Islánday ném-garmági wahd#,
				'generic' => q#Kuk Islánday wahd#,
				'standard' => q#Kuk Islánday anjári wahd#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kyubáay róchay wahd#,
				'generic' => q#Kyubáay wahd#,
				'standard' => q#Kyubáay anjári wahd#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Dawisay wahd#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont Urwilay wahd#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ródarátki Timuray wahd#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Isthar Islánday garmági wahd#,
				'generic' => q#Isthar Islánday wahd#,
				'standard' => q#Isthar Islánday anjári wahd#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekwádóray wahd#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Hamdárén Jaháni wahd#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Námálumén shahr#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Áten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrád#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislawá#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukhárest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budápest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhágen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Áeri anjári wahd#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernséy#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Estamból#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jerséy#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirów#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljaná#,
		},
		'Europe/London' => {
			exemplarCity => q#Landan#,
			long => {
				'daylight' => q#Bartániái garmági wahd#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Logzemborg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monákó#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Máskó#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ósló#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Payres#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgoriká#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prág#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rum#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marinó#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajéwó#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratów#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simperópól#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Kopjé#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiá#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Esthákholm#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiráne#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanówsk#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Waduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Watikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wienná#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Wársá#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zyurekh#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Delgáhi Yuropay garmági wahd#,
				'generic' => q#Delgáhi Yuropay wahd#,
				'standard' => q#Delgáhi Yuropay anjári wahd#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Yuropay garmági wahd#,
				'generic' => q#Ródarátki Yuropay wahd#,
				'standard' => q#Ródarátki Yuropay anjári wahd#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Démterén Ródarátki Yuropay anjári wahd#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Rónendi Yuropay garmági wahd#,
				'generic' => q#Rónendi Yuropay wahd#,
				'standard' => q#Rónendi Yuropay anjári wahd#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Palklánd Islánday garmági wahd#,
				'generic' => q#Palklánd Islánday wahd#,
				'standard' => q#Palklánd Islánday anjári wahd#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fijiay garmági wahd#,
				'generic' => q#Fijiay wahd#,
				'standard' => q#Fijiay anjári wahd#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Paránsi Gwináay wahd#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Zerbári Paransi o Antárktikáay wahd#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Grinwech Min Wahd#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagosay wahd#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiray wahd#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Járjiáay garmági wahd#,
				'generic' => q#Járjiáay wahd#,
				'standard' => q#Járjiáay anjári wahd#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gelbart Islánday wahd#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Grinlánday garmági wahd#,
				'generic' => q#Ródarátki Grinlánday wahd#,
				'standard' => q#Ródarátki Grinlánday anjári wahd#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Rónendi Grinlánd Garmági Wahd#,
				'generic' => q#Rónendi Grinlánday wahd#,
				'standard' => q#Rónendi Grinlánday anjári wahd#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Khalijay anjári wahd#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyánáay wahd#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawái/Alushiay garmági wahd#,
				'generic' => q#Hawái/Alushiay wahd#,
				'standard' => q#Hawái/Alushiay anjári wahd#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Háng Kángay garmági wahd#,
				'generic' => q#Háng Kángay wahd#,
				'standard' => q#Háng Kángay anjári wahd#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hówday garmági wahd#,
				'generic' => q#Hówday wahd#,
				'standard' => q#Hówday anjári wahd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Henday anjári wahd#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananariwó#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagós#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kresmes#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kukus#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komóró#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kargwelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Máldip#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Murishas#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayótay#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réyunian#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hendi zeray wahd#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hendóchinay wahd#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Delgáhi Endhonishiáay anjári wahd#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ródarátki Endhonishiáay anjári wahd#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Rónendi Endhonishiáay anjári wahd#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Éránay róchi wahd#,
				'generic' => q#Éránay wahd#,
				'standard' => q#Éránay anjári wahd#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Erkuskay garmági wahd#,
				'generic' => q#Erkuskay wahd#,
				'standard' => q#Erkuskay anjári wahd#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Esráilay róchi wahd#,
				'generic' => q#Esráilay wahd#,
				'standard' => q#Esráilay anjári wahd#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Jápánay róchi wahd#,
				'generic' => q#Jápánay wahd#,
				'standard' => q#Jápánay anjári wahd#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kázakestánay wahd#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ródarátki Kázekestánay anjári wahd#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Rónendi Kázekestánay anjári wahd#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Kóriáay róchi wahd#,
				'generic' => q#Kóriáay wahd#,
				'standard' => q#Kóriáay anjári wahd#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kósraiay wahd#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnóyáskay garmági wahd#,
				'generic' => q#Krasnóyáskay wahd#,
				'standard' => q#Krasnóyáskay anjári wahd#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kargezestánay wahd#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Liné Islánday wahd#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ástréliáay, Ládhaway garmági wahd#,
				'generic' => q#Ástréliáay, Ládhaway wahd#,
				'standard' => q#Ástréliáay, Ládhaway anjári wahd#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Mágadánay garmági wahd#,
				'generic' => q#Mágadánay wahd#,
				'standard' => q#Mágadánay anjári wahd#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malishiáay wahd#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Máldipay wahd#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markésásay wahd#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Márshal Islánday wahd#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Muritániáay garmági wahd#,
				'generic' => q#Muritániáay wahd#,
				'standard' => q#Muritániáay anjári wahd#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsonay wahd#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Árámzeri Meksikóay garmági wahd#,
				'generic' => q#Árámzeri Meksikóay wahd#,
				'standard' => q#Árámzeri Meksikóay anjári wahd#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulánbátaray garmági wahd#,
				'generic' => q#Ulánbátaray wahd#,
				'standard' => q#Ulánbátaray anjári wahd#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Máskóay garmági wahd#,
				'generic' => q#Máskóay wahd#,
				'standard' => q#Máskóay anjári wahd#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmáray wahd#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauruay wahd#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Népálay wahd#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nyu Kaledóniáay garmági wahd#,
				'generic' => q#Nyu Kaledóniáay wahd#,
				'standard' => q#Nyu Kaledóniáay anjári wahd#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Niu Zilánday róchi wahd#,
				'generic' => q#Niu Zilánday wahd#,
				'standard' => q#Niu Zilánday anjári wahd#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nipándlaynday garmági wahd#,
				'generic' => q#Nipándlaynday wahd#,
				'standard' => q#Nipándlaynday anjári wahd#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuay wahd#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Nurpolk Islánday róchi wahd#,
				'generic' => q#Nurpolk Islánday wahd#,
				'standard' => q#Nurpolk Islánday anjári wahd#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Noronáay garmági wahd#,
				'generic' => q#Noronáay wahd#,
				'standard' => q#Noronáay anjári wahd#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nawásibiskay garmági wahd#,
				'generic' => q#Nawásibiskay wahd#,
				'standard' => q#Nawásibiskay anjári wahd#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ómskay garmági wahd#,
				'generic' => q#Ómskay wahd#,
				'standard' => q#Ómskay anjári wahd#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apiá#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Awklánd#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bógáinwilay#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Isthar#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efáti#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaófó#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalkanal#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kósrai#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markesás#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nurpolk#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkarin#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pákestánay garmági wahd#,
				'generic' => q#Pákestánay wahd#,
				'standard' => q#Pákestánay anjári wahd#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Paláuay wahd#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Pápuá Niu Giniáay wahd#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragóayay garmági wahd#,
				'generic' => q#Paragóayay wahd#,
				'standard' => q#Paragóayay anjári wahd#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Péróay garmági wahd#,
				'generic' => q#Péróay wahd#,
				'standard' => q#Péróay anjári wahd#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Pelpinay garmági wahd#,
				'generic' => q#Pelpinay wahd#,
				'standard' => q#Pelpinay anjári wahd#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoeneks Islánday wahd#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Péri o Mikwélin róchi wahd#,
				'generic' => q#St. Péri o Mikwélin wahd#,
				'standard' => q#St. Péri o Mikwélin ajári wahd#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkarénay wahd#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pónpiay wahd#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyángay wahd#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réyunianay wahd#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothéráay wahd#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhálinay garmági wahd#,
				'generic' => q#Sakhálinay wahd#,
				'standard' => q#Sakhálinay anjári wahd#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samóáway róchi wahd#,
				'generic' => q#Samóáway wahd#,
				'standard' => q#Samóáway anjári wahd#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Séchelesay wahd#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Sengápuray anjári wahd#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomán Islánday wahd#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Zerbári Járjiáay wahd#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinaymay wahd#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syówáay wahd#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitiay wahd#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Táipiay róchi wahd#,
				'generic' => q#Táipiay wahd#,
				'standard' => q#Táipiay anjári wahd#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tájekestánay wahd#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokeláuay wahd#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongáay garmági wahd#,
				'generic' => q#Tongáay wahd#,
				'standard' => q#Tongáay anjári wahd#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chukay wahd#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Torkmenestánay garmági wahd#,
				'generic' => q#Torkmenestánay wahd#,
				'standard' => q#Torkmenestánay anjári wahd#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuwáluay wahd#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Yurógóayay garmági wahd#,
				'generic' => q#Yurógóayay wahd#,
				'standard' => q#Yurógóayay anjári wahd#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ozbekestánay garmági wahd#,
				'generic' => q#Ozbekestánay wahd#,
				'standard' => q#Ozbekestánay anjári wahd#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Wánuátuay garmági wahd#,
				'generic' => q#Wánuátuay wahd#,
				'standard' => q#Wánuátuay anjári wahd#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wenezwéláay wahd#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waládiwástókay garmági wahd#,
				'generic' => q#Waládiwástókay wahd#,
				'standard' => q#Waládiwástókay anjári wahd#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograday garmági wahd#,
				'generic' => q#Wolgograday wahd#,
				'standard' => q#Wolgograday anjári wahd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostokay wahd#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wayk Islánday wahd#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis o Futunáay wahd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yákuskay garmági wahd#,
				'generic' => q#Yákuskay wahd#,
				'standard' => q#Yákuskay anjári wahd#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yakátrinborgay garmági wahd#,
				'generic' => q#Yakátrinborgay wahd#,
				'standard' => q#Yakátrinborgay anjári wahd#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukón wahd#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
