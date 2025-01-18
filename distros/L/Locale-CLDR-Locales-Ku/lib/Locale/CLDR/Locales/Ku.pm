=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ku - Package for language Kurdish

=cut

package Locale::CLDR::Locales::Ku;
# This file auto generated from Data\common\main\ku.xml
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
				'aa' => 'afarî',
 				'ab' => 'abxazî',
 				'ace' => 'açehî',
 				'ada' => 'adangmeyî',
 				'ady' => 'adîgeyî',
 				'af' => 'afrîkansî',
 				'agq' => 'aghemî',
 				'ain' => 'aynuyî',
 				'ak' => 'akanî',
 				'ale' => 'alêwîtî',
 				'alt' => 'altayîya başûrî',
 				'am' => 'amharî',
 				'an' => 'aragonî',
 				'ann' => 'obolo',
 				'anp' => 'angîkayî',
 				'apc' => 'erebîya bakurê şamê',
 				'ar' => 'erebî',
 				'ar_001' => 'erebîya modern a standard',
 				'arn' => 'mapuçî',
 				'arp' => 'arapahoyî',
 				'ars' => 'erebîya necdî',
 				'as' => 'asamî',
 				'asa' => 'asûyî',
 				'ast' => 'astûrî',
 				'atj' => 'atîkamekî',
 				'av' => 'avarî',
 				'awa' => 'awadhî',
 				'ay' => 'aymarayî',
 				'az' => 'azerî',
 				'ba' => 'başkîrî',
 				'bal' => 'belûcî',
 				'ban' => 'balînî',
 				'bas' => 'basayî',
 				'be' => 'belarûsî',
 				'bem' => 'bembayî',
 				'bew' => 'betawî',
 				'bez' => 'benayî',
 				'bg' => 'bulgarî',
 				'bgc' => 'haryanvîyî',
 				'bgn' => 'belucîya rojavayî',
 				'bho' => 'bojpûrî',
 				'bi' => 'bîslamayî',
 				'bin' => 'bînîyî',
 				'bla' => 'blakfotî',
 				'blo' => 'bloyî',
 				'blt' => 'tay dam',
 				'bm' => 'bambarayî',
 				'bn' => 'bengalî',
 				'bo' => 'tîbetî',
 				'br' => 'bretonî',
 				'brx' => 'bodoyî',
 				'bs' => 'bosnî',
 				'bss' => 'akooseyî',
 				'bug' => 'bugî',
 				'byn' => 'blînî',
 				'ca' => 'katalanî',
 				'cad' => 'kadoyî',
 				'cay' => 'kayugayî',
 				'cch' => 'atsamî',
 				'ccp' => 'çakmayî',
 				'ce' => 'çeçenî',
 				'ceb' => 'sebwanoyî',
 				'cgg' => 'kîgayî',
 				'ch' => 'çamoroyî',
 				'chk' => 'çûkî',
 				'chm' => 'marî',
 				'cho' => 'çoktavî',
 				'chp' => 'çîpevyayî',
 				'chr' => 'çerokî',
 				'chy' => 'çeyenî',
 				'cic' => 'çîkasawî',
 				'ckb' => 'kurdî (soranî)',
 				'ckb@alt=menu' => 'kurdî (navîn)',
 				'clc' => 'çilkotînî',
 				'co' => 'korsîkayî',
 				'crg' => 'mîçîfî',
 				'crj' => 'krîya rojhilat ya başûrî',
 				'crk' => 'kriya bejayî',
 				'crl' => 'krîya rojhilat ya bakurî',
 				'crm' => 'krîya mûsî',
 				'crr' => 'zimanê karolina algonquianî',
 				'cs' => 'çekî',
 				'csw' => 'krîya swampî',
 				'cu' => 'slavîya kenîseyî',
 				'cv' => 'çuvaşî',
 				'cy' => 'weylsî',
 				'da' => 'danmarkî',
 				'dak' => 'dakotayî',
 				'dar' => 'dargînî',
 				'dav' => 'tayîtayî',
 				'de' => 'almanî',
 				'dgr' => 'dogrîbî',
 				'dje' => 'zarma',
 				'doi' => 'dogrîyî',
 				'dsb' => 'sorbîya jêrîn',
 				'dua' => 'diwalayî',
 				'dv' => 'divehî',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'conxayî',
 				'dzg' => 'dazagayî',
 				'ebu' => 'embuyî',
 				'ee' => 'eweyî',
 				'efi' => 'efîkî',
 				'eka' => 'ekajukî',
 				'el' => 'yûnanî',
 				'en' => 'îngilîzî',
 				'en_GB' => 'îngilîzî (Qiralîyeta Yekbûyî)',
 				'en_GB@alt=short' => 'îngilîzî (QY)',
 				'eo' => 'esperantoyî',
 				'es' => 'spanî',
 				'es_ES' => 'spanî (Ewropa)',
 				'et' => 'estonî',
 				'eu' => 'baskî',
 				'ewo' => 'ewondoyî',
 				'fa' => 'farisî',
 				'fa_AF' => 'derî',
 				'ff' => 'fulahî',
 				'fi' => 'fînî',
 				'fil' => 'fîlîpînoyî',
 				'fj' => 'fîjî',
 				'fo' => 'ferî',
 				'fon' => 'fonî',
 				'fr' => 'fransizî',
 				'fr_CA' => 'fransizî (Kanada)',
 				'fr_CH' => 'fransizî (Swîsre)',
 				'frc' => 'fransizîya kajûnê',
 				'frr' => 'frîsîya bakur',
 				'fur' => 'frîyolî',
 				'fy' => 'frîsî',
 				'ga' => 'îrlendî',
 				'gaa' => 'gayî',
 				'gd' => 'gaelîka skotî',
 				'gez' => 'geez',
 				'gil' => 'kîrîbatî',
 				'gl' => 'galîsî',
 				'gn' => 'guwaranî',
 				'gor' => 'gorontaloyî',
 				'gsw' => 'elmanîşî',
 				'gu' => 'gujaratî',
 				'guz' => 'gusîî',
 				'gv' => 'manksî',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hawsayî',
 				'hai' => 'haydayî',
 				'haw' => 'hawayî',
 				'hax' => 'haîdaya başûrî',
 				'he' => 'îbranî',
 				'hi' => 'hindî',
 				'hi_Latn@alt=variant' => 'hîngilîzî',
 				'hil' => 'hîlîgaynonî',
 				'hmn' => 'hmongî',
 				'hnj' => 'hmongîya njuayî',
 				'hr' => 'xirwatî',
 				'hsb' => 'sorbîya jorîn',
 				'ht' => 'haîtî',
 				'hu' => 'mecarî',
 				'hup' => 'hupayî',
 				'hur' => 'halkomelemî',
 				'hy' => 'ermenî',
 				'hz' => 'hereroyî',
 				'ia' => 'înterlîngua',
 				'iba' => 'iban',
 				'ibb' => 'îbîbîoyî',
 				'id' => 'endonezyayî',
 				'ie' => 'înterlîngue',
 				'ig' => 'îgboyî',
 				'ii' => 'yîyîya siçuwayî',
 				'ikt' => 'inuvialuktun',
 				'ilo' => 'îlokanoyî',
 				'inh' => 'îngûşî',
 				'io' => 'îdoyî',
 				'is' => 'îzlendî',
 				'it' => 'îtalî',
 				'iu' => 'înuîtî',
 				'ja' => 'japonî',
 				'jbo' => 'lojbanî',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'javayî',
 				'ka' => 'gurcî',
 				'kaa' => 'kara-kalpakî',
 				'kab' => 'kabîlî',
 				'kac' => 'cingphoyî',
 				'kaj' => 'jju',
 				'kam' => 'kambayî',
 				'kbd' => 'kabardî',
 				'kcg' => 'tyap',
 				'kde' => 'makondeyî',
 				'kea' => 'kapverdî',
 				'ken' => 'kenyangî',
 				'kfo' => 'koro',
 				'kgp' => 'kayingangî',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kîkûyûyî',
 				'kj' => 'kwanyamayî',
 				'kk' => 'qazaxî',
 				'kkj' => 'kako',
 				'kl' => 'kalalîsûtî',
 				'kln' => 'kalencînî',
 				'km' => 'ximêrî',
 				'kmb' => 'kîmbunduyî',
 				'kn' => 'kannadayî',
 				'ko' => 'koreyî',
 				'kok' => 'konkanî',
 				'kpe' => 'kpelleyî',
 				'kr' => 'kanurîyî',
 				'krc' => 'karaçay-balkarî',
 				'krl' => 'karelî',
 				'kru' => 'kurukh',
 				'ks' => 'keşmîrî',
 				'ksb' => 'shambala',
 				'ksf' => 'bafyayî',
 				'ksh' => 'rîpwarî',
 				'ku' => 'kurdî (kurmancî)',
 				'kum' => 'kumikî',
 				'kv' => 'komî',
 				'kw' => 'kornî',
 				'kwk' => 'kwak’walayî',
 				'kxv' => 'kuvî',
 				'ky' => 'kirgizî',
 				'la' => 'latînî',
 				'lad' => 'ladînoyî',
 				'lag' => 'langî',
 				'lb' => 'luksembûrgî',
 				'lez' => 'lezgînî',
 				'lg' => 'lugandayî',
 				'li' => 'lîmbûrgî',
 				'lij' => 'lîgûrî',
 				'lil' => 'lillooet',
 				'lkt' => 'lakotayî',
 				'lmo' => 'lombardî',
 				'ln' => 'lingalayî',
 				'lo' => 'lawsî',
 				'lou' => 'kreyolîya louisianayê',
 				'loz' => 'lozî',
 				'lrc' => 'lurîya bakur',
 				'lsm' => 'saamia',
 				'lt' => 'lîtwanî',
 				'ltg' => 'latgalî',
 				'lu' => 'luba-katangayî',
 				'lua' => 'luba-kasayî',
 				'lun' => 'lunda',
 				'luo' => 'luoyî',
 				'lus' => 'mizoyî',
 				'luy' => 'luhyayî',
 				'lv' => 'latvîyayî',
 				'mad' => 'madurayî',
 				'mag' => 'magahî',
 				'mai' => 'maithili',
 				'mak' => 'makasarî',
 				'mas' => 'masayî',
 				'mdf' => 'mokşayî',
 				'men' => 'mende',
 				'mer' => 'meruyî',
 				'mfe' => 'morisyenî',
 				'mg' => 'malagasî',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marşalî',
 				'mi' => 'maorî',
 				'mic' => 'mîkmakî',
 				'min' => 'mînangkabawî',
 				'mk' => 'makedonî',
 				'ml' => 'malayalamî',
 				'mn' => 'moxolî',
 				'mni' => 'manipuri',
 				'moe' => 'înûyîya rojhilatî',
 				'moh' => 'mohawkî',
 				'mos' => 'moreyî',
 				'mr' => 'maratî',
 				'ms' => 'malezî',
 				'mt' => 'maltayî',
 				'mua' => 'mundangî',
 				'mul' => 'pirzimanî',
 				'mus' => 'krîkî',
 				'mwl' => 'mîrandî',
 				'my' => 'burmayî',
 				'myv' => 'erzayî',
 				'mzn' => 'mazenderanî',
 				'na' => 'nawrûyî',
 				'nap' => 'napolîtanî',
 				'naq' => 'namayî',
 				'nb' => 'norwecî (bokmål)',
 				'nd' => 'ndebelîya bakurî',
 				'nds' => 'nedersaksî',
 				'ne' => 'nepalî',
 				'new' => 'newarî',
 				'ng' => 'ndongayî',
 				'nia' => 'nîasî',
 				'niu' => 'nîwî',
 				'nl' => 'holendî',
 				'nl_BE' => 'flamî',
 				'nmg' => 'kwasio',
 				'nn' => 'norwecî (nynorsk)',
 				'nnh' => 'ngiemboon',
 				'no' => 'norwecî',
 				'nog' => 'nogayî',
 				'nqo' => 'n’Ko',
 				'nr' => 'ndebelîya başûrî',
 				'nso' => 'sotoyîya bakur',
 				'nus' => 'nuer',
 				'nv' => 'navajoyî',
 				'ny' => 'çîçewayî',
 				'nyn' => 'nyankole',
 				'oc' => 'oksîtanî',
 				'ojb' => 'ojibweyîya bakurî',
 				'ojc' => 'ojibwayîya navîn',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojîbweyîya rojavayî',
 				'oka' => 'okanagan',
 				'om' => 'oromoyî',
 				'or' => 'oriyayî',
 				'os' => 'osetî',
 				'osa' => 'osageyî',
 				'pa' => 'puncabî',
 				'pag' => 'pangasînanî',
 				'pam' => 'kapampanganî',
 				'pap' => 'papyamentoyî',
 				'pau' => 'palawî',
 				'pcm' => 'pîdgînîya nîjeryayî',
 				'pis' => 'pijînî',
 				'pl' => 'polonî',
 				'pqm' => 'malecite-passamaquoddy',
 				'prg' => 'prûsyayî',
 				'ps' => 'peştûyî',
 				'pt' => 'portugalî',
 				'pt_PT' => 'portugalî (Ewropa)',
 				'qu' => 'keçwayî',
 				'quc' => 'k’iche’',
 				'raj' => 'rajasthanî',
 				'rap' => 'rapanuyî',
 				'rar' => 'rarotongî',
 				'rhg' => 'rohingyayî',
 				'rif' => 'tarifit',
 				'rm' => 'romancî',
 				'rn' => 'rundî',
 				'ro' => 'romanî',
 				'rof' => 'rombo',
 				'ru' => 'rûsî',
 				'rup' => 'aromanî',
 				'rw' => 'kînyariwandayî',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrîtî',
 				'sad' => 'sandawe',
 				'sah' => 'yakutî',
 				'saq' => 'samburuyî',
 				'sat' => 'santalî',
 				'sba' => 'ngambay',
 				'sbp' => 'sanguyî',
 				'sc' => 'sardînî',
 				'scn' => 'sicîlî',
 				'sco' => 'skotî',
 				'sd' => 'sindhî',
 				'sdh' => 'kurdîya başûrî',
 				'se' => 'samîya bakur',
 				'seh' => 'sena',
 				'ses' => 'sonxayî',
 				'sg' => 'sangoyî',
 				'shi' => 'taşelhîtî',
 				'shn' => 'şanî',
 				'si' => 'kîngalî',
 				'sid' => 'sîdamo',
 				'sk' => 'slovakî',
 				'skr' => 'seraîkî',
 				'sl' => 'slovenî',
 				'slh' => 'lushootseeda başûrî',
 				'sm' => 'samoayî',
 				'sma' => 'samîya başûr',
 				'smj' => 'samiya lule',
 				'smn' => 'samîya înarî',
 				'sms' => 'samîya skoltî',
 				'sn' => 'şonayî',
 				'snk' => 'soninke',
 				'so' => 'somalî',
 				'sq' => 'arnawidî',
 				'sr' => 'sirbî',
 				'srn' => 'sirananî',
 				'ss' => 'swazî',
 				'ssy' => 'sahoyî',
 				'st' => 'sotoyîya başûr',
 				'str' => 'saanîçî',
 				'su' => 'sundanî',
 				'suk' => 'sukuma',
 				'sv' => 'swêdî',
 				'sw' => 'swahîlî',
 				'sw_CD' => 'swahîlîya kongoyî',
 				'swb' => 'komorî',
 				'syr' => 'siryanî',
 				'szl' => 'silesî',
 				'ta' => 'tamîlî',
 				'tce' => 'totuçena başûrî',
 				'te' => 'telûgûyî',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'tet' => 'tetûmî',
 				'tg' => 'tacikî',
 				'tgx' => 'tagîşî',
 				'th' => 'tayî',
 				'tht' => 'tahltan',
 				'ti' => 'tigrînî',
 				'tig' => 'tigre',
 				'tk' => 'tirkmenî',
 				'tlh' => 'klîngonî',
 				'tli' => 'tlingit',
 				'tn' => 'tswanayî',
 				'to' => 'tongî',
 				'tok' => 'toki pona',
 				'tpi' => 'tokpisinî',
 				'tr' => 'tirkî',
 				'trv' => 'tarokoyî',
 				'trw' => 'torwalî',
 				'ts' => 'tsongayî',
 				'tt' => 'teterî',
 				'ttm' => 'tutoçenîya bakur',
 				'tum' => 'tumbukayî',
 				'tvl' => 'tuvalûyî',
 				'twq' => 'tasawaq',
 				'ty' => 'tahîtî',
 				'tyv' => 'tuvanî',
 				'tzm' => 'temazîxtî',
 				'udm' => 'udmurtî',
 				'ug' => 'oygurî',
 				'uk' => 'ukraynî',
 				'umb' => 'umbunduyî',
 				'und' => 'zimanê nenas',
 				'ur' => 'urdûyî',
 				'uz' => 'ozbekî',
 				'vec' => 'venîsî',
 				'vi' => 'vîetnamî',
 				'vmw' => 'makhuwayî',
 				'vo' => 'volapûkî',
 				'vun' => 'vunjo',
 				'wa' => 'walonî',
 				'wae' => 'walserî',
 				'wal' => 'wolaytta',
 				'war' => 'warayî',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolofî',
 				'wuu' => 'çînîya wuyî',
 				'xal' => 'kalmîkî',
 				'xh' => 'xosayî',
 				'xnr' => 'kangrî',
 				'xog' => 'sogayî',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yidîşî',
 				'yo' => 'yorubayî',
 				'yrl' => 'nhêngatûyî',
 				'yue' => 'kantonî',
 				'yue@alt=menu' => 'çînî, kantonî',
 				'za' => 'zhuangî',
 				'zgh' => 'amazîxîya fasî',
 				'zh' => 'çînî',
 				'zh@alt=menu' => 'çînî, mandarînî',
 				'zh_Hans' => 'çînîya sadekirî',
 				'zh_Hans@alt=long' => 'çînîya mandarînî ya sadekirî',
 				'zh_Hant' => 'çînîya kevneşopî',
 				'zh_Hant@alt=long' => 'çînîya mandarînî ya kevneşopî',
 				'zu' => 'zuluyî',
 				'zun' => 'zunîyî',
 				'zxx' => 'bê naveroka zimanî',
 				'zza' => 'zazakî (kirdkî, kirmanckî)',

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
			'Arab' => 'erebî',
 			'Aran' => 'nestalîq',
 			'Armn' => 'ermenî',
 			'Beng' => 'bengalî',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Copt' => 'qiptî',
 			'Cprt' => 'qibrisî',
 			'Cyrl' => 'kirîlî',
 			'Deva' => 'devanagarî',
 			'Egyp' => 'hîyeroglîfên misirî',
 			'Ethi' => 'etîyopîk',
 			'Geor' => 'gurcî',
 			'Goth' => 'gotîk',
 			'Grek' => 'yûnanî',
 			'Gujr' => 'gujeratî',
 			'Hanb' => 'hanîya bi bopomofoyê',
 			'Hang' => 'hangulî',
 			'Hani' => 'hanî',
 			'Hans' => 'sadekirî',
 			'Hans@alt=stand-alone' => 'hanîya sadekirî',
 			'Hant' => 'kevneşopî',
 			'Hant@alt=stand-alone' => 'hanîya kevneşopî',
 			'Hebr' => 'îbranî',
 			'Hira' => 'hîraganayî',
 			'Hrkt' => 'nivîsên heceyî yên japonî',
 			'Jamo' => 'jamoyî',
 			'Jpan' => 'japonî',
 			'Kana' => 'katakanayî',
 			'Khmr' => 'ximêrî',
 			'Knda' => 'kannadayî',
 			'Kore' => 'koreyî',
 			'Laoo' => 'laoyî',
 			'Latn' => 'latînî',
 			'Mlym' => 'malayamî',
 			'Mong' => 'moxolî',
 			'Mymr' => 'myanmarî',
 			'Qaag' => 'zawgyi',
 			'Sinh' => 'sînhalayî',
 			'Taml' => 'tamîlî',
 			'Telu' => 'teluguyî',
 			'Thai' => 'tayî',
 			'Tibt' => 'tîbetî',
 			'Yezi' => 'êzidî',
 			'Zmth' => 'nîşandana matematîkî',
 			'Zsye' => 'emojî',
 			'Zsym' => 'sembol',
 			'Zxxx' => 'nenivîskî',
 			'Zyyy' => 'hevpar',
 			'Zzzz' => 'alfabeya nenas',

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
			'001' => 'dinya',
 			'002' => 'Afrîka',
 			'003' => 'Amerîkaya Bakur',
 			'005' => 'Amerîkaya Başûr',
 			'009' => 'Okyanûsya',
 			'011' => 'Rojavayê Afrîkayê',
 			'013' => 'Amerîkaya Navîn',
 			'014' => 'Rojhilatê Afrîkayê',
 			'015' => 'Bakurê Afrîkayê',
 			'017' => 'Afrîkaya Navîn',
 			'018' => 'Başûrê Afrîkayê',
 			'019' => 'Amerîka',
 			'021' => 'Bakurê Amerîkayê',
 			'029' => 'Karayîb',
 			'030' => 'Rojhilatê Asyayê',
 			'034' => 'Başûrê Asyayê',
 			'035' => 'Başûrrojhilatê Asyayê',
 			'039' => 'Başûrê Ewropayê',
 			'053' => 'Awistralasya',
 			'054' => 'Melanezya',
 			'057' => 'Herêma Mîkronezyayê',
 			'061' => 'Polînezya',
 			'142' => 'Asya',
 			'143' => 'Asyaya Navîn',
 			'145' => 'Rojavayê Asyayê',
 			'150' => 'Ewropa',
 			'151' => 'Rojhilatê Ewropayê',
 			'154' => 'Bakurê Ewropayê',
 			'155' => 'Rojavayê Ewropayê',
 			'202' => 'Afrîkaya Jêra Sahrayê',
 			'419' => 'Amerîkaya Latîn',
 			'AC' => 'Girava Ascensionê',
 			'AD' => 'Andorra',
 			'AE' => 'Mîrgehên Erebî yên Yekbûyî',
 			'AF' => 'Efxanistan',
 			'AG' => 'Antîgua û Berbûda',
 			'AI' => 'Anguîla',
 			'AL' => 'Albanya',
 			'AM' => 'Ermenistan',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktîka',
 			'AR' => 'Arjantîn',
 			'AS' => 'Samoaya Amerîkanî',
 			'AT' => 'Awistirya',
 			'AU' => 'Awistralya',
 			'AW' => 'Arûba',
 			'AX' => 'Giravên Alandê',
 			'AZ' => 'Azerbeycan',
 			'BA' => 'Bosna û Hersek',
 			'BB' => 'Barbados',
 			'BD' => 'Bengladeş',
 			'BE' => 'Belçîka',
 			'BF' => 'Burkîna Faso',
 			'BG' => 'Bulgaristan',
 			'BH' => 'Behreyn',
 			'BI' => 'Bûrûndî',
 			'BJ' => 'Bênîn',
 			'BL' => 'Saint Barthelemy',
 			'BM' => 'Bermûda',
 			'BN' => 'Brûney',
 			'BO' => 'Bolîvya',
 			'BQ' => 'Holendaya Karayîbê',
 			'BR' => 'Brezîlya',
 			'BS' => 'Bahama',
 			'BT' => 'Bûtan',
 			'BV' => 'Girava Bouvetê',
 			'BW' => 'Botswana',
 			'BY' => 'Belarûs',
 			'BZ' => 'Belîze',
 			'CA' => 'Kanada',
 			'CC' => 'Giravên Kokosê (Keeling)',
 			'CD' => 'Kongo - Kînşasa',
 			'CD@alt=variant' => 'Kongo (KDK)',
 			'CF' => 'Komara Afrîkaya Navîn',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Komar)',
 			'CH' => 'Swîsre',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Perava Ivoryê',
 			'CK' => 'Giravên Cookê',
 			'CL' => 'Şîle',
 			'CM' => 'Kamerûn',
 			'CN' => 'Çîn',
 			'CO' => 'Kolombîya',
 			'CP' => 'Girava Clippertonê',
 			'CQ' => 'Sark',
 			'CR' => 'Kosta Rîka',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Girava Christmasê',
 			'CY' => 'Qibris',
 			'CZ' => 'Çekya',
 			'DE' => 'Almanya',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Cîbûtî',
 			'DK' => 'Danîmarka',
 			'DM' => 'Domînîka',
 			'DO' => 'Komara Domînîkê',
 			'DZ' => 'Cezayîr',
 			'EA' => 'Ceuta û Melîla',
 			'EC' => 'Ekwador',
 			'EE' => 'Estonya',
 			'EG' => 'Misir',
 			'EH' => 'Sahraya Rojava',
 			'ER' => 'Erître',
 			'ES' => 'Spanya',
 			'ET' => 'Etîyopya',
 			'EU' => 'Yekîtîya Ewropayê',
 			'EZ' => 'Herêma Ewroyê',
 			'FI' => 'Fînlenda',
 			'FJ' => 'Fîjî',
 			'FK' => 'Giravên Falklandê',
 			'FK@alt=variant' => 'Giravên Falklandê (Giravên Malvînê)',
 			'FM' => 'Mîkronezya',
 			'FO' => 'Giravên Faroeyê',
 			'FR' => 'Fransa',
 			'GA' => 'Gabon',
 			'GB' => 'Qiralîyeta Yekbûyî',
 			'GB@alt=short' => 'QY',
 			'GD' => 'Grenada',
 			'GE' => 'Gurcistan',
 			'GF' => 'Guyanaya Fransî',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Cebelîtariq',
 			'GL' => 'Grînlanda',
 			'GM' => 'Gambîya',
 			'GN' => 'Gîne',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Gîneya Ekwadorê',
 			'GR' => 'Yûnanistan',
 			'GS' => 'Giravên Georgîyaya Başûr û Sandwicha Başûr',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gîne-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Konga HîT ya Çînê',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Giravên Heard û MacDonaldê',
 			'HN' => 'Hondûras',
 			'HR' => 'Xirwatistan',
 			'HT' => 'Haîtî',
 			'HU' => 'Macaristan',
 			'IC' => 'Giravên Kanaryayê',
 			'ID' => 'Endonezya',
 			'IE' => 'Îrlanda',
 			'IL' => 'Îsraîl',
 			'IM' => 'Girava Manê',
 			'IN' => 'Hindistan',
 			'IO' => 'Herêma Okyanûsa Hindî ya Brîtanyayê',
 			'IO@alt=chagos' => 'Komgiravên Çagosê',
 			'IQ' => 'Îraq',
 			'IR' => 'Îran',
 			'IS' => 'Îslanda',
 			'IT' => 'Îtalya',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaîka',
 			'JO' => 'Urdun',
 			'JP' => 'Japonya',
 			'KE' => 'Kenya',
 			'KG' => 'Qirgizistan',
 			'KH' => 'Kamboçya',
 			'KI' => 'Kirîbatî',
 			'KM' => 'Komor',
 			'KN' => 'Saint Kitts û Nevîs',
 			'KP' => 'Koreya Bakur',
 			'KR' => 'Koreya Başûr',
 			'KW' => 'Kuweyt',
 			'KY' => 'Giravên Kaymanê',
 			'KZ' => 'Qazaxistan',
 			'LA' => 'Laos',
 			'LB' => 'Libnan',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Srî Lanka',
 			'LR' => 'Lîberya',
 			'LS' => 'Lesoto',
 			'LT' => 'Lîtvanya',
 			'LU' => 'Luksembûrg',
 			'LV' => 'Letonya',
 			'LY' => 'Lîbya',
 			'MA' => 'Fas',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Giravên Marşalê',
 			'MK' => 'Makendonyaya Bakur',
 			'ML' => 'Malî',
 			'MM' => 'Myanmar (Bûrma)',
 			'MN' => 'Moxolistan',
 			'MO' => 'Makaoya Hît ya Çînê',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Giravên Bakurê Marianan',
 			'MQ' => 'Martînîk',
 			'MR' => 'Morîtanya',
 			'MS' => 'Montserat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldîva',
 			'MW' => 'Malawî',
 			'MX' => 'Meksîka',
 			'MY' => 'Malezya',
 			'MZ' => 'Mozambîk',
 			'NA' => 'Namîbya',
 			'NC' => 'Kaledonyaya Nû',
 			'NE' => 'Nîjer',
 			'NF' => 'Girava Norfolkê',
 			'NG' => 'Nîjerya',
 			'NI' => 'Nîkaragua',
 			'NL' => 'Holanda',
 			'NO' => 'Norwêc',
 			'NP' => 'Nepal',
 			'NR' => 'Naûrû',
 			'NU' => 'Niûe',
 			'NZ' => 'Zelandaya Nû',
 			'NZ@alt=variant' => 'Aoteroaya Zelandaya Nû',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perû',
 			'PF' => 'Polînezyaya Fransizî',
 			'PG' => 'Papua Gîneya Nû',
 			'PH' => 'Fîlîpîn',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonya',
 			'PM' => 'Saint-Pierre û Miquelon',
 			'PN' => 'Giravên Pitcairnê',
 			'PR' => 'Porto Rîko',
 			'PS' => 'Herêmên Filîstînî',
 			'PS@alt=short' => 'Filistîn',
 			'PT' => 'Portûgal',
 			'PW' => 'Palau',
 			'PY' => 'Paragûay',
 			'QA' => 'Qeter',
 			'QO' => 'Okyanûsyaya Dûr',
 			'RE' => 'Réunion',
 			'RO' => 'Romanya',
 			'RS' => 'Sirbistan',
 			'RU' => 'Rûsya',
 			'RW' => 'Rwanda',
 			'SA' => 'Erebistana Siûdî',
 			'SB' => 'Giravên Solomonê',
 			'SC' => 'Seyşel',
 			'SD' => 'Sûdan',
 			'SE' => 'Swêd',
 			'SG' => 'Sîngapûr',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenya',
 			'SJ' => 'Svalbard û Jan Mayen',
 			'SK' => 'Slovakya',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marîno',
 			'SN' => 'Senegal',
 			'SO' => 'Somalya',
 			'SR' => 'Surînam',
 			'SS' => 'Sûdana Başûr',
 			'ST' => 'Sao Tome û Prînsîpe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Marteen',
 			'SY' => 'Sûrîye',
 			'SZ' => 'Eswatînî',
 			'SZ@alt=variant' => 'Swazîlenda',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Giravên Turks û Kaîkosê',
 			'TD' => 'Çad',
 			'TF' => 'Herêmên Başûr ên Fransayê',
 			'TG' => 'Togo',
 			'TH' => 'Tayland',
 			'TJ' => 'Tacîkistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Tîmor-Leste',
 			'TL@alt=variant' => 'Tîmora Rojhilat',
 			'TM' => 'Tirkmenistan',
 			'TN' => 'Tûnis',
 			'TO' => 'Tonga',
 			'TR' => 'Tirkîye',
 			'TR@alt=variant' => 'Türkiye',
 			'TT' => 'Trînîdad û Tobago',
 			'TV' => 'Tûvalû',
 			'TW' => 'Taywan',
 			'TZ' => 'Tanzanya',
 			'UA' => 'Ûkrayna',
 			'UG' => 'Ûganda',
 			'UM' => 'Giravên Biçûk ên Derveyî DYAyê',
 			'UN' => 'Miletên Yekbûyî',
 			'US' => 'Dewletên Yekbûyî yên Amerîkayê',
 			'US@alt=short' => 'DYA',
 			'UY' => 'Ûrûguay',
 			'UZ' => 'Ozbekistan',
 			'VA' => 'Vatîkan',
 			'VC' => 'Saint Vincent û Giravên Grenadînê',
 			'VE' => 'Venezuela',
 			'VG' => 'Giravên Vîrjînê yên Brîtanyayê',
 			'VI' => 'Giravên Vîrjînê yên Amerîkayê',
 			'VN' => 'Vîetnam',
 			'VU' => 'Vanûatû',
 			'WF' => 'Wallis û Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Aksanên Psodoyê',
 			'XB' => 'Psodo Bidî',
 			'XK' => 'Kosova',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrîkaya Başûr',
 			'ZM' => 'Zambîya',
 			'ZW' => 'Zîmbabwe',
 			'ZZ' => 'Herêma Nenas',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1959ACAD' => 'Akademîk',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Salname',
 			'collation' => 'Rêzkirin',
 			'currency' => 'diwîz',

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
 				'buddhist' => q{Salnameya Budîst},
 				'chinese' => q{Salnameya Çînî},
 				'coptic' => q{Salnameya Qiptî},
 				'dangi' => q{Salnameya Dangî},
 				'ethiopic' => q{Salnameya Etîyopîk},
 				'ethiopic-amete-alem' => q{Salnameya Amete Alem ya Etîyopîk},
 				'gregorian' => q{Salnameya Mîladî},
 				'hebrew' => q{salnameya îbranî},
 				'indian' => q{Salnameya Milî ya Hindî},
 				'islamic' => q{Salnameya Hicrî},
 				'islamic-civil' => q{Salnameya Hicrî (16ê tîrmeha 622yan)},
 				'islamic-rgsa' => q{Salnameya Hicrî (Siudî)},
 				'islamic-tbla' => q{Salnameya Hicrî (15ê tîrmeha 622yan)},
 				'islamic-umalqura' => q{Salnameya Hicrî (Um el-Qura)},
 				'iso8601' => q{Salnameya ISO-8601ê},
 				'japanese' => q{Salnameya Japonî},
 				'persian' => q{Salnameya Îranî},
 				'roc' => q{Salnameya Komara Çînê},
 			},
 			'collation' => {
 				'standard' => q{Awayê Rêzkirina Standard},
 			},
 			'numbers' => {
 				'arab' => q{Reqemên hindo-erebî},
 				'latn' => q{Reqemên Rojavayî},
 				'roman' => q{Reqemên Romayî},
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
			'metric' => q{metrîk},
 			'UK' => q{îngilîzî},
 			'US' => q{amerîkî},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ziman: {0}',
 			'script' => 'nivîs: {0}',
 			'region' => 'herêm: {0}',

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
			auxiliary => qr{[áàăâåäãā æ èĕëē é ìĭïī í ñ óòŏôøō œ ß ŭū úù ÿ]},
			index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ê', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Û', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c ç d e ê f g h i î j k l m n o p q r s ş t u û v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ê', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Û', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(hêlên sereke),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(hêlên sereke),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(deqîqeya kevanî),
						'one' => q({0} deqîqeya kevanî),
						'other' => q({0} deqîqeyên kevanî),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(deqîqeya kevanî),
						'one' => q({0} deqîqeya kevanî),
						'other' => q({0} deqîqeyên kevanî),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sanîyeya kevanî),
						'one' => q({0} sanîyeya kevanî),
						'other' => q({0} sanîyeyên kevanî),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sanîyeya kevanî),
						'one' => q({0} sanîyeya kevanî),
						'other' => q({0} sanîyeyên kevanî),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} derece),
						'other' => q({0} derece),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} derece),
						'other' => q({0} derece),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radyan),
						'other' => q({0} radyan),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radyan),
						'other' => q({0} radyan),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(dewr),
						'one' => q({0} dewr),
						'other' => q({0} dewr),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(dewr),
						'one' => q({0} dewr),
						'other' => q({0} dewr),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(donim),
						'one' => q({0} donim),
						'other' => q({0} donim),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(donim),
						'one' => q({0} donim),
						'other' => q({0} donim),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(santîmetre kare),
						'one' => q({0} santîmetre kare),
						'other' => q({0} santîmetre kare),
						'per' => q({0} serê santîmetre kareyê),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(santîmetre kare),
						'one' => q({0} santîmetre kare),
						'other' => q({0} santîmetre kare),
						'per' => q({0} serê santîmetre kareyê),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(fît kare),
						'one' => q({0} fît kare),
						'other' => q({0} fît kare),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fît kare),
						'one' => q({0} fît kare),
						'other' => q({0} fît kare),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(înç kare),
						'one' => q({0} înç kare),
						'other' => q({0} înç kare),
						'per' => q({0} serê înç kareyê),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(înç kare),
						'one' => q({0} înç kare),
						'other' => q({0} înç kare),
						'per' => q({0} serê înç kareyê),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kîlometre kare),
						'one' => q({0} kîlometre kare),
						'other' => q({0} kîlometre kare),
						'per' => q({0} serê kîlometre kareyê),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kîlometre kare),
						'one' => q({0} kîlometre kare),
						'other' => q({0} kîlometre kare),
						'per' => q({0} serê kîlometre kareyê),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metre kare),
						'one' => q({0} metre kare),
						'other' => q({0} metre kare),
						'per' => q({0} serê metre kareyê),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metre kare),
						'one' => q({0} metre kare),
						'other' => q({0} metre kare),
						'per' => q({0} serê metre kareyê),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mîl kare),
						'one' => q({0} mîl kare),
						'other' => q({0} mîl kare),
						'per' => q({0} serê mîl kareyê),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mîl kare),
						'one' => q({0} mîl kare),
						'other' => q({0} mîl kare),
						'per' => q({0} serê mîl kareyê),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda kare),
						'one' => q({0} yarda kare),
						'other' => q({0} yarda kare),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda kare),
						'one' => q({0} yarda kare),
						'other' => q({0} yarda kare),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} qerat),
						'other' => q({0} qerat),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} qerat),
						'other' => q({0} qerat),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ji sedî),
						'one' => q(ji sedî {0}),
						'other' => q(ji sedî {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ji sedî),
						'one' => q(ji sedî {0}),
						'other' => q(ji sedî {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} rojhilat),
						'north' => q({0} bakur),
						'south' => q({0} başûr),
						'west' => q({0} rojava),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} rojhilat),
						'north' => q({0} bakur),
						'south' => q({0} başûr),
						'west' => q({0} rojava),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0}/roj),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0}/roj),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dehsal),
						'one' => q({0} dehsal),
						'other' => q({0} dehsal),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dehsal),
						'one' => q({0} dehsal),
						'other' => q({0} dehsal),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} saet),
						'other' => q({0} saet),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} saet),
						'other' => q({0} saet),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(deqîqe),
						'one' => q({0} deqîqe),
						'other' => q({0} deqîqe),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(deqîqe),
						'one' => q({0} deqîqe),
						'other' => q({0} deqîqe),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} meh),
						'other' => q({0} meh),
						'per' => q({0}/meh),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} meh),
						'other' => q({0} meh),
						'per' => q({0}/meh),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(şev),
						'one' => q({0} şev),
						'other' => q({0} şev),
						'per' => q({0}/şev),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(şev),
						'one' => q({0} şev),
						'other' => q({0} şev),
						'per' => q({0}/şev),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çaryek),
						'one' => q({0} çaryek),
						'other' => q({0} çaryek),
						'per' => q({0}/çaryek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çaryek),
						'one' => q({0} çaryek),
						'other' => q({0} çaryek),
						'per' => q({0}/çaryek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sanîye),
						'one' => q({0} sanîye),
						'other' => q({0} saniye),
						'per' => q({0}/sn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sanîye),
						'one' => q({0} sanîye),
						'other' => q({0} saniye),
						'per' => q({0}/sn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hefte),
						'one' => q({0} hefte),
						'other' => q({0} hefte),
						'per' => q({0}/hefte),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hefte),
						'one' => q({0} hefte),
						'other' => q({0} hefte),
						'per' => q({0}/hefte),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(yekeya astronomîk),
						'one' => q({0} yekeya astronomîk),
						'other' => q({0} yekeya astronomîk),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(yekeya astronomîk),
						'one' => q({0} yekeya astronomîk),
						'other' => q({0} yekeya astronomîk),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santîmetre),
						'per' => q({0} serê santîmetreyê),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santîmetre),
						'per' => q({0} serê santîmetreyê),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decîmetre),
						'one' => q({0} decîmetre),
						'other' => q({0} decîmetre),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decîmetre),
						'one' => q({0} decîmetre),
						'other' => q({0} decîmetre),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(nîvçapa dinyayê),
						'one' => q({0} nîvçapa dinyayê),
						'other' => q({0} nîvçapa dinyayê),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(nîvçapa dinyayê),
						'one' => q({0} nîvçapa dinyayê),
						'other' => q({0} nîvçapa dinyayê),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
						'one' => q({0} fathom),
						'other' => q({0} fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
						'one' => q({0} fathom),
						'other' => q({0} fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fît),
						'one' => q({0} fît),
						'other' => q({0} fît),
						'per' => q({0} serê fîtê),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fît),
						'one' => q({0} fît),
						'other' => q({0} fît),
						'per' => q({0} serê fîtê),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(înç),
						'one' => q({0} înç),
						'other' => q({0} înç),
						'per' => q({0} serê înçê),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(înç),
						'one' => q({0} înç),
						'other' => q({0} înç),
						'per' => q({0} serê înçê),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kîlometre),
						'one' => q({0} kîlometre),
						'other' => q({0} kîlometre),
						'per' => q({0} serê kîlometreyê),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kîlometre),
						'one' => q({0} kîlometre),
						'other' => q({0} kîlometre),
						'per' => q({0} serê kîlometreyê),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(sala ronahîyê),
						'one' => q({0} sala ronahîyê),
						'other' => q({0} sala ronahîyê),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(sala ronahîyê),
						'one' => q({0} sala ronahîyê),
						'other' => q({0} sala ronahîyê),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metre),
						'one' => q({0} metre),
						'other' => q({0} metre),
						'per' => q({0} serê metreyê),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metre),
						'one' => q({0} metre),
						'other' => q({0} metre),
						'per' => q({0} serê metreyê),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mîkrometre),
						'one' => q({0} mîkrometre),
						'other' => q({0} mîkrometre),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mîkrometre),
						'one' => q({0} mîkrometre),
						'other' => q({0} mîkrometre),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mîl),
						'one' => q({0} mîl),
						'other' => q({0} mîl),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mîl),
						'one' => q({0} mîl),
						'other' => q({0} mîl),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mîlîmetre),
						'one' => q({0} mîlîmetre),
						'other' => q({0} mîlîmetre),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mîlîmetre),
						'one' => q({0} mîlîmetre),
						'other' => q({0} mîlîmetre),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometre),
						'one' => q({0} nanometre),
						'other' => q({0} nanometre),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometre),
						'one' => q({0} nanometre),
						'other' => q({0} nanometre),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mîla behrê),
						'one' => q({0} mîla behrê),
						'other' => q({0} mîla behrê),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mîla behrê),
						'one' => q({0} mîla behrê),
						'other' => q({0} mîla behrê),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pîkometre),
						'one' => q({0} pîkometre),
						'other' => q({0} pîkometre),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pîkometre),
						'one' => q({0} pîkometre),
						'other' => q({0} pîkometre),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punto),
						'one' => q({0} punto),
						'other' => q({0} punto),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punto),
						'one' => q({0} punto),
						'other' => q({0} punto),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(nîvçapa rojê),
						'one' => q({0} nîvçapa rojê),
						'other' => q({0} nîvçapa rojê),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(nîvçapa rojê),
						'one' => q({0} nîvçapa rojê),
						'other' => q({0} nîvçapa rojê),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kîlogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kîlogram),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kîlometreya serê saetê),
						'one' => q({0} km/st),
						'other' => q({0} km/st),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kîlometreya serê saetê),
						'one' => q({0} km/st),
						'other' => q({0} km/st),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lître),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lître),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(dq. kevanî),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(dq. kevanî),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sn. kevanî),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sn. kevanî),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(donim),
						'one' => q({0} donim),
						'other' => q({0} donim),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(donim),
						'one' => q({0} donim),
						'other' => q({0} donim),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(fît kare),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fît kare),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(înç kare),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(înç kare),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metre kare),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metre kare),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mîl kare),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mîl kare),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda kare),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda kare),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Rh),
						'north' => q({0}Bk),
						'south' => q({0}Bş),
						'west' => q({0}Ra),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Rh),
						'north' => q({0}Bk),
						'south' => q({0}Bş),
						'west' => q({0}Ra),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}r),
						'other' => q({0}r),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}r),
						'other' => q({0}r),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dehsal),
						'one' => q({0} dehsal),
						'other' => q({0} dehsal),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dehsal),
						'one' => q({0} dehsal),
						'other' => q({0} dehsal),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(şev),
						'one' => q({0} şev),
						'other' => q({0} şev),
						'per' => q({0}/şev),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(şev),
						'one' => q({0} şev),
						'other' => q({0} şev),
						'per' => q({0}/şev),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çaryek),
						'one' => q({0} çaryek),
						'other' => q({0} çaryek),
						'per' => q({0}/çaryek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çaryek),
						'one' => q({0} çaryek),
						'other' => q({0} çaryek),
						'per' => q({0}/çaryek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sn),
						'one' => q({0}sn),
						'other' => q({0}sn),
						'per' => q({0}/sn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sn),
						'one' => q({0}sn),
						'other' => q({0}sn),
						'per' => q({0}/sn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0}hf),
						'other' => q({0}hf),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}hf),
						'other' => q({0}hf),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(sl),
						'one' => q({0}sl),
						'other' => q({0}sl),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(sl),
						'one' => q({0}sl),
						'other' => q({0}sl),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(nîvçapa dinyayê),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(nîvçapa dinyayê),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fît),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fît),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(înç),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(înç),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(sala rnh),
						'one' => q({0} sala rnh),
						'other' => q({0} sala rnh),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(sala rnh),
						'one' => q({0} sala rnh),
						'other' => q({0} sala rnh),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mîl),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mîl),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(nîvçapa rojê),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(nîvçapa rojê),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/st),
						'one' => q({0} km/st),
						'other' => q({0} km/st),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/st),
						'one' => q({0} km/st),
						'other' => q({0} km/st),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lître),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lître),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(hêl),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(hêl),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(dq. kevanî),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(dq. kevanî),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sn. kevanî),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sn. kevanî),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derece),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derece),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radyan),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radyan),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(dwr),
						'one' => q({0} dwr),
						'other' => q({0} dwr),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(dwr),
						'one' => q({0} dwr),
						'other' => q({0} dwr),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(donim),
						'one' => q({0} donim),
						'other' => q({0} donim),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(donim),
						'one' => q({0} donim),
						'other' => q({0} donim),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(fît kare),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fît kare),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(înç kare),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(înç kare),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metre kare),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metre kare),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mîl kare),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mîl kare),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda kare),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda kare),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(qerat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(qerat),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Rh),
						'north' => q({0} Bk),
						'south' => q({0} Bş),
						'west' => q({0} Ra),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Rh),
						'north' => q({0} Bk),
						'south' => q({0} Bş),
						'west' => q({0} Ra),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(roj),
						'one' => q({0} roj),
						'other' => q({0} roj),
						'per' => q({0}/r),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(roj),
						'one' => q({0} roj),
						'other' => q({0} roj),
						'per' => q({0}/r),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dehsal),
						'one' => q({0} dehsal),
						'other' => q({0} dehsal),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dehsal),
						'one' => q({0} dehsal),
						'other' => q({0} dehsal),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saet),
						'one' => q({0} st),
						'other' => q({0} st),
						'per' => q({0}/st),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saet),
						'one' => q({0} st),
						'other' => q({0} st),
						'per' => q({0}/st),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meh),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meh),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(şev),
						'one' => q({0} şev),
						'other' => q({0} şev),
						'per' => q({0}/şev),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(şev),
						'one' => q({0} şev),
						'other' => q({0} şev),
						'per' => q({0}/şev),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çaryek),
						'one' => q({0} çaryek),
						'other' => q({0} çaryek),
						'per' => q({0}/çaryek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çaryek),
						'one' => q({0} çaryek),
						'other' => q({0} çaryek),
						'per' => q({0}/çaryek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sn),
						'one' => q({0} sn),
						'other' => q({0} sn),
						'per' => q({0}/sn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sn),
						'one' => q({0} sn),
						'other' => q({0} sn),
						'per' => q({0}/sn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hf),
						'one' => q({0} hf),
						'other' => q({0} hf),
						'per' => q({0}/hf),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hf),
						'one' => q({0} hf),
						'other' => q({0} hf),
						'per' => q({0}/hf),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(sal),
						'one' => q({0} sal),
						'other' => q({0} sal),
						'per' => q({0}/sal),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(sal),
						'one' => q({0} sal),
						'other' => q({0} sal),
						'per' => q({0}/sal),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(nîvçapa dinyayê),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(nîvçapa dinyayê),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fît),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fît),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(înç),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(înç),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(sala rnh),
						'one' => q({0} sala rnh),
						'other' => q({0} sala rnh),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(sala rnh),
						'one' => q({0} sala rnh),
						'other' => q({0} sala rnh),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mîl),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mîl),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(nîvçapa rojê),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(nîvçapa rojê),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/st),
						'one' => q({0} km/st),
						'other' => q({0} km/st),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/st),
						'one' => q({0} km/st),
						'other' => q({0} km/st),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lître),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lître),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:erê|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:na|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} û {1}),
				2 => q({0} û {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => '0 hezar',
					'other' => '0 hezar',
				},
				'10000' => {
					'one' => '00 hezar',
					'other' => '00 hezar',
				},
				'100000' => {
					'one' => '000 hezar',
					'other' => '000 hezar',
				},
				'1000000' => {
					'one' => '0 milyon',
					'other' => '0 milyon',
				},
				'10000000' => {
					'one' => '00 milyon',
					'other' => '00 milyon',
				},
				'100000000' => {
					'one' => '000 milyon',
					'other' => '000 milyon',
				},
				'1000000000' => {
					'one' => '0 milyar',
					'other' => '0 milyar',
				},
				'10000000000' => {
					'one' => '00 milyar',
					'other' => '00 milyar',
				},
				'100000000000' => {
					'one' => '000 milyar',
					'other' => '000 milyar',
				},
				'1000000000000' => {
					'one' => '0 trilyon',
					'other' => '0 trilyon',
				},
				'10000000000000' => {
					'one' => '00 trilyon',
					'other' => '00 trilyon',
				},
				'100000000000000' => {
					'one' => '000 trilyon',
					'other' => '000 trilyon',
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
				'1000000' => {
					'one' => '0MN',
					'other' => '0MN',
				},
				'10000000' => {
					'one' => '00MN',
					'other' => '00MN',
				},
				'100000000' => {
					'one' => '000MN',
					'other' => '000MN',
				},
				'1000000000' => {
					'one' => '0MR',
					'other' => '0MR',
				},
				'10000000000' => {
					'one' => '00MR',
					'other' => '00MR',
				},
				'100000000000' => {
					'one' => '000MR',
					'other' => '000MR',
				},
				'1000000000000' => {
					'one' => '0TN',
					'other' => '0TN',
				},
				'10000000000000' => {
					'one' => '00TN',
					'other' => '00TN',
				},
				'100000000000000' => {
					'one' => '000TN',
					'other' => '000TN',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '%#,##0',
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
						'negative' => '(#,##0.00 ¤)',
						'positive' => '#,##0.00 ¤',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
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
				'currency' => q(dîrhemê mîrgehên erebî yên yekbûyî),
				'one' => q(dîrhemê MEYî),
				'other' => q(dîrhemên MEYî),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(efxanîyê efxanistanî),
				'one' => q(efxanîyê efxanistanî),
				'other' => q(efxanîyên efxanistanî),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lekê arnawidî),
				'one' => q(lekê arnawidî),
				'other' => q(lekên arnawidî),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dramê ermenî),
				'one' => q(dramê ermenî),
				'other' => q(dramên ermenî),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(guldenê antîlê yê holandî),
				'one' => q(guldenê antîlê yê holandî),
				'other' => q(guldenên antîlê yê holandî),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanzayê angolayî),
				'one' => q(kwanzayê angolayî),
				'other' => q(kwanzayên angolayî),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(pesoyê arjantînî),
				'one' => q(pesoyê arjantînî),
				'other' => q(pesoyên arjantînî),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dolarê awistralyayî),
				'one' => q(dolarê awistralyayî),
				'other' => q(dolarên awistralyayî),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florînê arubayî),
				'one' => q(florînê arubayî),
				'other' => q(florînên arubayî),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manatê azerbeycanî),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(markê konvertibl ê bosna hersekî),
				'one' => q(markê konvertibl ê bosna hersekî),
				'other' => q(markên konvertibl ê bosna hersekî),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dolarê barbadosî),
				'one' => q(dolarê barbadosî),
				'other' => q(dolarên barbadosî),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(takayê bengladeşî),
				'one' => q(takayê bengladeşî),
				'other' => q(takayên bengladeşî),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(levê bulgarî),
				'one' => q(levê bulgarî),
				'other' => q(levên bulgarî),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dînarê behreynê),
				'one' => q(dînarê behreynê),
				'other' => q(dînarên behreynê),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(frankê birûndîyî),
				'one' => q(frankê birûndîyî),
				'other' => q(frankên birûndîyî),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dolarê bermûdayî),
				'one' => q(dolarê bermûdayî),
				'other' => q(dolarên bermûdayî),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dolarê brûneyî),
				'one' => q(dolarê brûneyî),
				'other' => q(dolarên brûneyî),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolîvyanoyê bolîvyayî),
				'one' => q(bolîvyanoyê bolîvyayî),
				'other' => q(bolîvyanoyên bolîvyayî),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(realê brezîlyayî),
				'one' => q(realê brezîlyayî),
				'other' => q(realên brezîlyayî),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dolarê bahamayî),
				'one' => q(dolarê bahamayî),
				'other' => q(dolarên bahamayî),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrumê bûtanî),
				'one' => q(ngultrumê bûtanî),
				'other' => q(ngultrumên bûtanî),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pulayê botswanayî),
				'one' => q(pulayê botswanayî),
				'other' => q(pulayên botswanayî),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rûbleyê belarûsî),
				'one' => q(rûbleyê belarûsî),
				'other' => q(rûbleyên belarûsî),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dolarê belîzeyî),
				'one' => q(dolarê belîzeyî),
				'other' => q(dolarên belîzeyî),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dolarê kanadayî),
				'one' => q(dolarê kanadayî),
				'other' => q(dolarên kanadayî),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(frankê kongoyî),
				'one' => q(frankê kongoyî),
				'other' => q(frankên kongoyî),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(frankê swîsrî),
				'one' => q(frankê swîsrî),
				'other' => q(frankên swîsrî),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(pesoyê şîlîyê),
				'one' => q(pesoyê şîlîyê),
				'other' => q(pesoyên şîlîyê),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yûanê çînî \(offshore\)),
				'one' => q(yûanê çînî \(offshore\)),
				'other' => q(yûanên çînî \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yûanê çînî),
				'one' => q(yûanê çînî),
				'other' => q(yûanên çînî),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(pesoyê kolombîyayî),
				'one' => q(pesoyê kolombîyayî),
				'other' => q(pesoyên kolombîyayî),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kolonê kosta rîkayî),
				'one' => q(kolonê kosta rîkayî),
				'other' => q(kolonên kosta rîkayî),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(pesoyên konvertibl ê kubayî),
				'one' => q(pesoyê konvertibl ê kubayî),
				'other' => q(pesoyên konvertibl ê kubayî),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(pesoyê kubayî),
				'one' => q(pesoyê kubayî),
				'other' => q(pesoyên kubayî),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(eskudoyê kape verdeyî),
				'one' => q(eskudoyê kape verdeyî),
				'other' => q(eskudoyên kape verdeyî),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(kronê çekî),
				'one' => q(kronê çekî),
				'other' => q(kronên çekî),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(frankê cîbûtîyî),
				'one' => q(frankê cîbûtîyî),
				'other' => q(frankên cîbûtîyî),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(kronê danîmarkî),
				'one' => q(kronê danîmarkî),
				'other' => q(kronên danîmarkî),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(pesoyê domînîkî),
				'one' => q(pesoyê domînîkî),
				'other' => q(pesoyên domînîkî),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dînarê cezayîrî),
				'one' => q(dînarê cezayîrî),
				'other' => q(dînarên cezayîrî),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(lîreyê misirî),
				'one' => q(lîreyê misirî),
				'other' => q(lîreyên misirî),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfayê erîtreyî),
				'one' => q(nakfayê erîtreyî),
				'other' => q(nakfayên erîtreyî),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(bîrê etyopyayî),
				'one' => q(bîrê etyopyayî),
				'other' => q(bîrên etyopyayî),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ewro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dolarê fîjîyî),
				'one' => q(dolarê fîjîyî),
				'other' => q(dolarên fîjîyî),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(paundê giravên falklandê),
				'one' => q(paundê giravên falklandê),
				'other' => q(paundên giravên falklandê),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(sterlînê brîtanî),
				'one' => q(sterlînê brîtanî),
				'other' => q(sterlînên brîtanî),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(larîyê gurcistanî),
				'one' => q(larîyê gurcistanî),
				'other' => q(larîyên gurcistanî),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedîyê ganayî),
				'one' => q(cedîyê ganayî),
				'other' => q(cedîyên ganayî),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(poundê gîbraltarê),
				'one' => q(poundê gîbraltarê),
				'other' => q(poundên gîbraltarê),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasîyê gambîyayî),
				'one' => q(dalasîyê gambîyayî),
				'other' => q(dalasîyên gambîyayî),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(frankê gîneyî),
				'one' => q(frankê gîneyî),
				'other' => q(frankên gîneyî),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quertzalê guatemalayî),
				'one' => q(quertzalê guatemalayî),
				'other' => q(quertzalên guatemalayî),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dolarê guayanayî),
				'one' => q(dolarê guayanayî),
				'other' => q(dolarên guayanayî),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dolarê hong kongî),
				'one' => q(dolarê hong kongî),
				'other' => q(dolarên hong kongî),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempîrayê hondurasî),
				'one' => q(lempîrayê hondurasî),
				'other' => q(lempîrayên hondurasî),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kûnayê xirwatî),
				'one' => q(kûnayê xirwatî),
				'other' => q(kûnayên xirwatî),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gûrdeyê haîtîyî),
				'one' => q(gûrdeyê haîtîyî),
				'other' => q(gûrdeyên haîtîyî),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forîntê macarî),
				'one' => q(forîntê macarî),
				'other' => q(forîntên macarî),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rûpîyê endonezî),
				'one' => q(rûpîyê endonezî),
				'other' => q(rûpîyên endonezî),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(şekelê nû yê îsraîlî),
				'one' => q(şekelê nû yê îsraîlî),
				'other' => q(şekelên nû yê îsraîlî),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rûpîyê hindistanî),
				'one' => q(rûpîyê hindistanî),
				'other' => q(rûpîyên hindistanî),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dînarê îraqî),
				'one' => q(dînarê îraqî),
				'other' => q(dînarên îraqî),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rîyalê îranî),
				'one' => q(rîyalê îranî),
				'other' => q(rîyalên îranî),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(kronê îslandayî),
				'one' => q(kronê îslandayî),
				'other' => q(kronên îslandayî),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dolarê jamaîkayî),
				'one' => q(dolarê jamaîkayî),
				'other' => q(dolarên jamaîkayî),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dînarê urdunî),
				'one' => q(dînarê urdunî),
				'other' => q(dînarên urdunî),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yenê japonî),
				'one' => q(yenê japonî),
				'other' => q(yenên japonî),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(şîlîngê kenyayî),
				'one' => q(şîlîngê kenyayî),
				'other' => q(şîlîngên kenyayî),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(somê qirxizistanî),
				'one' => q(somê qirxizistanî),
				'other' => q(somên qirxizistanî),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(rîelê kamboçyayî),
				'one' => q(rîelê kamboçyayî),
				'other' => q(rîelên kamboçyayî),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(frankê komoranî),
				'one' => q(frankê komoranî),
				'other' => q(frankên komoranî),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(wonê koreya bakurî),
				'one' => q(wonê koreya bakurî),
				'other' => q(wonên koreya bakurî),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(wonê koreya başûrî),
				'one' => q(wonê koreya başûrî),
				'other' => q(wonên koreya başûrî),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dînarê kuweytî),
				'one' => q(dînarê kuweytî),
				'other' => q(dînarên kuweytî),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dolarê giravên keymanî),
				'one' => q(dolarê giravên keymanî),
				'other' => q(dolarên giravên keymanî),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tengeyê qazaxistanî),
				'one' => q(tengeyê qazaxistanî),
				'other' => q(tengeyên qazaxistanî),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kîpê laosî),
				'one' => q(kîpê laosî),
				'other' => q(kîpên laosî),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(lîreyê libnanî),
				'one' => q(lîreyê libnanî),
				'other' => q(lîreyên libnanî),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rûpîyê srî lankayî),
				'one' => q(rûpîyê srî lankayî),
				'other' => q(rûpîyên srî lankayî),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dolarê lîberyayî),
				'one' => q(dolarê lîberyayî),
				'other' => q(dolarên lîberyayî),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lotîyê lesothoyî),
				'one' => q(lotîyê lesothoyî),
				'other' => q(lotîyên lesothoyî),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dînarê lîbyayî),
				'one' => q(dînarê lîbyayî),
				'other' => q(dînarên lîbyayî),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dîrhemê fasî),
				'one' => q(dîrhemê fasî),
				'other' => q(dîrhemên fasî),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leyê moldovayî),
				'one' => q(leyê moldovayî),
				'other' => q(leyên moldovayî),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(frankê madagaskarî),
				'one' => q(frankê madagaskarî),
				'other' => q(frankên madagaskarî),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dînarê makedonî),
				'one' => q(dînarê makedonî),
				'other' => q(dînarên makedonî),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyatê myanmarî),
				'one' => q(kyatê myanmarî),
				'other' => q(kyatên myanmarî),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(togrokê moxolî),
				'one' => q(togrokê moxolî),
				'other' => q(togrokên moxolî),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(patakayê makaoyî),
				'one' => q(patakayê makaoyî),
				'other' => q(patakaynê makaoyî),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguîayê morîtanyayî),
				'one' => q(ouguîayê morîtanyayî),
				'other' => q(ouguîayên morîtanyayî),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rûpîyê maûrîtîûsê),
				'one' => q(rûpîyê maûrîtîûsê),
				'other' => q(rûpîyên maûrîtîûsê),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rûfîyaayê maldîvayî),
				'one' => q(rûfîyaayê maldîvayî),
				'other' => q(rûfîyaayên maldîvayî),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwaçayê malawîyê),
				'one' => q(kwaçayê malawîyê),
				'other' => q(kwaçayên malawîyê),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(pesoyê meksîkayî),
				'one' => q(pesoyê meksîkayî),
				'other' => q(pesoyên meksîkayî),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgitê malezyayî),
				'one' => q(ringgitê malezyayî),
				'other' => q(ringgitên malezyayî),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(meticalê mozambîkî),
				'one' => q(meticalê mozambîkî),
				'other' => q(meticalên mozambîkî),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dolarê namîbyayî),
				'one' => q(dolarê namîbyayî),
				'other' => q(dolarên namîbyayî),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naîrayê nîjeryayî),
				'one' => q(naîrayê nîjeryayî),
				'other' => q(naîrayên nîjeryayî),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(kordobayê nîkaraguayî),
				'one' => q(kordobayê nîkaraguayî),
				'other' => q(kordobayên nîkaraguayî),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(kronê norweçî),
				'one' => q(kronê norweçî),
				'other' => q(kronên norweçî),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rûpîyê nepalî),
				'one' => q(rûpîyê nepalî),
				'other' => q(rûpîyên nepalî),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dolarê zelandayî),
				'one' => q(dolarê zelandayî),
				'other' => q(dolarên zelandayî),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rîyalê umanî),
				'one' => q(rîyalê umanî),
				'other' => q(rîyalên umanî),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboayê panamayî),
				'one' => q(balboayê panamayî),
				'other' => q(balboayên panamayî),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(solê perûyî),
				'one' => q(solê perûyî),
				'other' => q(solên perûyî),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kînayê gîneya nû ya papûayî),
				'one' => q(kînayê gîneya nû ya papûayî),
				'other' => q(kînayên gîneya nû ya papûayî),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(pesoyê fîlîpînî),
				'one' => q(pesoyê fîlîpînî),
				'other' => q(pesoyên fîlîpînî),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rûpîyê pakistanî),
				'one' => q(rûpîyê pakistanî),
				'other' => q(rûpîyên pakistanî),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zlotîyê polonyayî),
				'one' => q(zlotîyê polonyayî),
				'other' => q(zlotîyên polonyayî),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(gûaranîyê paragûayî),
				'one' => q(gûaranîyê paragûayî),
				'other' => q(gûaranîyên paragûayî),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rîyalê qeterî),
				'one' => q(rîyalê qeterî),
				'other' => q(rîyalên qeterî),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leyê romanyayî),
				'one' => q(leyê romanyayî),
				'other' => q(leyên romanyayî),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dînarê sirbî),
				'one' => q(dînarê sirbî),
				'other' => q(dînarên sirbî),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rubleyê rûsî),
				'one' => q(rubleyê rûsî),
				'other' => q(rubleyên rûsî),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(frankê rwandayî),
				'one' => q(frankê rwandayî),
				'other' => q(frankên rwandayî),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rîyalê siûdî),
				'one' => q(rîyalê siûdî),
				'other' => q(rîyalên siûdî),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dolarê giravên solomonî),
				'one' => q(dolarê giravên solomonî),
				'other' => q(dolarên giravên solomonî),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rûpîyê seyşelerî),
				'one' => q(rûpîyê seyşelerî),
				'other' => q(rûpîyên seyşelerî),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(lîreyê sûdanî),
				'one' => q(lîreyê sûdanî),
				'other' => q(lîreyên sûdanî),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(kronê swêdî),
				'one' => q(kronê swêdî),
				'other' => q(kronên swêdî),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dolarê sîngapurî),
				'one' => q(dolarê sîngapurî),
				'other' => q(dolarên sîngapurî),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(lîreyê saînt helenayî),
				'one' => q(lîreyê saînt helenayî),
				'other' => q(lîreyên saînt helenayî),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leoneyê sîera leoneyî),
				'one' => q(leoneyê sîera leoneyî),
				'other' => q(leoneyên sîera leoneyî),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leoneyê sîera leoneyî \(1964—2022\)),
				'one' => q(leoneyê sîera leoneyî \(1964—2022\)),
				'other' => q(leoneyên sîera leoneyî \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(şîlîngê somalî),
				'one' => q(şîlîngê somalî),
				'other' => q(şîlîngên somalî),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dolarê surînamî),
				'one' => q(dolarê surînamî),
				'other' => q(dolarên surînamî),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(lîreyê sûdana başûrî),
				'one' => q(lîreyê sûdana başûrî),
				'other' => q(lîreyên sûdana başûrî),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobrayê sao tome û principeyî),
				'one' => q(dobrayê sao tome û principeyî),
				'other' => q(dobrayên sao tome û principeyî),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(lîreyê sûrî),
				'one' => q(lîreyê sûrî),
				'other' => q(lîreyên sûrî),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lîlangenîyê swazîlî),
				'one' => q(lîlangenîyê swazîlî),
				'other' => q(lîlangenîyên swazîlî),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(bahtê taylandî),
				'one' => q(bahtê taylandî),
				'other' => q(bahtên taylandî),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somonê tacikistanî),
				'one' => q(somonê tacikistanî),
				'other' => q(somonên tacikistanî),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manatê tirkmenî),
				'one' => q(manatê tirkmenî),
				'other' => q(manatên tirkmenî),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dînarê tûnisî),
				'one' => q(dînarê tûnisî),
				'other' => q(dînarên tûnisî),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻangayê tonganî),
				'one' => q(paʻangayê tonganî),
				'other' => q(paʻangayên tonganî),
			},
		},
		'TRY' => {
			symbol => '₺',
			display_name => {
				'currency' => q(lîreyê tirkî),
				'one' => q(lîreyê tirkî),
				'other' => q(lîreyên tirkî),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dolarê trinidad û tobagoyî),
				'one' => q(dolarê trinidad û tobagoyî),
				'other' => q(dolarên trinidad û tobagoyî),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(dolarê taywanî),
				'one' => q(dolarê taywanî),
				'other' => q(dolarên taywanî),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(şîlîngê tanzanî),
				'one' => q(şîlîngê tanzanî),
				'other' => q(şîlîngên tanzanî),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(grîvnayê ûkraynî),
				'one' => q(grîvnayê ûkraynî),
				'other' => q(grîvnayên ûkraynî),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(şîlîngê ûgandayî),
				'one' => q(şîlîngê ûgandayî),
				'other' => q(şîlîngên ûgandayî),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(dolarê amerîkî),
				'one' => q(dolarê amerîkî),
				'other' => q(dolarên amerîkî),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(pesoyê ûrûgûayî),
				'one' => q(pesoyê ûrûgûayî),
				'other' => q(pesoyên ûrûgûayî),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(somê ozbekî),
				'one' => q(somê ozbekî),
				'other' => q(somên ozbekî),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolîvarê venezuelayî),
				'one' => q(bolîvarê venezuelayî),
				'other' => q(bolîvarên venezuelayî),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dongê vîetnamî),
				'one' => q(dongê vîetnamî),
				'other' => q(dongên vîetnamî),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatûyê vanûatûyî),
				'one' => q(vatûyê vanûatûyî),
				'other' => q(vatûyên vanûatûyî),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(talayê somonî),
				'one' => q(talayê somonî),
				'other' => q(talayên somonî),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(frenkê CFA yê afrîkaya navîn),
				'one' => q(frenkê CFA yê afrîkaya navîn),
				'other' => q(frenkên CFA yê afrîkaya navîn),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dolarê karayîba rojhilatî),
				'one' => q(dolarê karayîba rojhilatî),
				'other' => q(dolarên karayîba rojhilatî),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(frankê CFA yê afrîkaya başûrî),
				'one' => q(frankê CFA yê afrîkaya başûrî),
				'other' => q(frankên CFA yê afrîkaya başûrî),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(frankê CFPî),
				'one' => q(frankê CFPî),
				'other' => q(frankên CFPî),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(\(yekeya pereyî ya nenas\)),
				'one' => q(yekeya pereyî ya nenas),
				'other' => q(\(yekeyên pereyî yên nenas\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rîyalê yemenî),
				'one' => q(rîyalê yemenî),
				'other' => q(rîyalên yemenî),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(randê afrîkaya başûrî),
				'one' => q(randê afrîkaya başûrî),
				'other' => q(randên afrîkaya başûrî),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwaçayê zambîyayî),
				'one' => q(kwaçayê zambîyayî),
				'other' => q(kwaçayên zambîyayî),
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
							'rbn',
							'sbt',
							'adr',
							'nsn',
							'gln',
							'hzr',
							'trm',
							'tbx',
							'îln',
							'cot',
							'mjd',
							'brf'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'rêbendan',
							'sibat',
							'adar',
							'nîsan',
							'gulan',
							'hezîran',
							'tîrmeh',
							'tebax',
							'îlon',
							'cotmeh',
							'mijdar',
							'berfanbar'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'R',
							'S',
							'A',
							'N',
							'G',
							'H',
							'T',
							'T',
							'Î',
							'C',
							'M',
							'B'
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
							'muh.',
							'sef.',
							'reb. Iem',
							'reb. IIyem',
							'cmz. Iem',
							'cmz. IIyem',
							'rcb.',
							'şbn.',
							'rmz.',
							'şwl.',
							'zqd.',
							'zhc.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muherem',
							'sefer',
							'rebîʿulewel',
							'rebîʿulaxer',
							'cemazîyelewel',
							'cemazîyelaxer',
							'receb',
							'şeʿban',
							'remezan',
							'şewal',
							'zîlqeʿde',
							'zilhece'
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
						mon => 'dşm',
						tue => 'sşm',
						wed => 'çşm',
						thu => 'pşm',
						fri => 'înî',
						sat => 'şem',
						sun => 'yşm'
					},
					short => {
						mon => 'dş',
						tue => 'sş',
						wed => 'çş',
						thu => 'pş',
						fri => 'în',
						sat => 'şm',
						sun => 'yş'
					},
					wide => {
						mon => 'duşem',
						tue => 'sêşem',
						wed => 'çarşem',
						thu => 'pêncşem',
						fri => 'înî',
						sat => 'şemî',
						sun => 'yekşem'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'Î',
						sat => 'Ş',
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
					abbreviated => {0 => 'Ç1',
						1 => 'Ç2',
						2 => 'Ç3',
						3 => 'Ç4'
					},
					wide => {0 => 'çaryeka 1em',
						1 => 'çaryeka 2yem',
						2 => 'çaryeka 3yem',
						3 => 'çaryeka 4em'
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
					'am' => q{BN},
					'pm' => q{PN},
				},
				'narrow' => {
					'am' => q{bn},
					'pm' => q{pn},
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
				'0' => 'BZ',
				'1' => 'PZ'
			},
			wide => {
				'0' => 'berî zayînê',
				'1' => 'piştî zayînê'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'Hicrî'
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
			'full' => q{G d'ê' MMMM'a' y'an' EEEE},
			'long' => q{G d'ê' MMMM'a' y'an'},
			'medium' => q{G d'ê' MMM'a' y'an'},
			'short' => q{GGGGG d.MM.y},
		},
		'gregorian' => {
			'full' => q{EEEE, d'ê' MMMM'a' y'an'},
			'long' => q{d'ê' MMMM'a' y'an'},
			'medium' => q{d'ê' MMM'a' y'an'},
			'short' => q{dd.MM.y},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ehm => q{E, h:mm'ê' a},
			Ehms => q{E, h:mm:ss'ê' a},
			GyMMM => q{G MMM'a' y'an'},
			GyMMMEd => q{G d'ê' MMM'a' y'an' E},
			GyMMMd => q{G d'ê' MMM'a' y'an'},
			GyMd => q{d/M/y GGGGG},
			MEd => q{dd/MM, E},
			MMMEd => q{d'ê' MMM'ê', E},
			MMMMd => q{d'ê' MMMM'ê'},
			MMMd => q{d'ê' MMM'ê'},
			Md => q{dd/MM},
			h => q{h'ê' a},
			hm => q{h:mm'ê' a},
			hms => q{h:mm:ss'ê' a},
			yyyyM => q{GGGGG M/y},
			yyyyMEd => q{GGGGG dd.MM.y, E},
			yyyyMMM => q{G MMM'a' y'an'},
			yyyyMMMEd => q{G d'ê' MMM'a' y'an' E},
			yyyyMMMM => q{G MMMM'a' y'an'},
			yyyyMMMd => q{G d'ê' MMM'a' y'an'},
			yyyyMd => q{GGGGG dd.MM.y},
			yyyyQQQ => q{G y/QQQ},
			yyyyQQQQ => q{G y/QQQQ},
		},
		'gregorian' => {
			Bh => q{h'ê' B},
			Bhm => q{h:mm'ê' B},
			Bhms => q{h:mm:ss'ê' B},
			EBhm => q{E, h:mm'ê' B},
			EBhms => q{E, h:mm:ss'ê' B},
			Ed => q{d E},
			Ehm => q{E, h:mm'ê' a},
			Ehms => q{E, h:mm:ss'ê' a},
			GyMMM => q{G MMM'a' y'an'},
			GyMMMEd => q{G d'ê' MMM'a' y'an', E},
			GyMMMd => q{G d'ê' MMM'a' y'an'},
			GyMd => q{GGGGG dd.MM.y},
			Hmsv => q{HH:mm:ss 'bi' 'dema' v('y')'ê'},
			Hmv => q{HH:mm 'bi' 'dema' v('y')'ê'},
			MEd => q{E, dd.MM},
			MMMEd => q{E, d'ê' MMM'ê'},
			MMMMW => q{'hefteya' W'em' 'ya' MMMM'ê'},
			MMMMd => q{d'ê' MMMM'ê'},
			MMMd => q{d'ê' MMM'ê'},
			Md => q{dd.MM},
			h => q{h'ê' a},
			hm => q{h:mm'ê' a},
			hms => q{h:mm:ss'ê' a},
			hmsv => q{h:mm:ss'ê' a 'bi' 'dema' v('y')'ê'},
			hmv => q{h:mm'ê' a 'bi' 'dema' v('y')'ê'},
			yM => q{MM.y},
			yMEd => q{E, dd.MM.y},
			yMMM => q{MMM'a' y'an'},
			yMMMEd => q{E, d'ê' MMM'a' y'an'},
			yMMMM => q{MMMM'a' y'an'},
			yMMMd => q{d'ê' MMM'a' y'an'},
			yMd => q{dd.MM.y},
			yQQQ => q{QQQ'em' 'ya' y'an'},
			yQQQQ => q{QQQQ 'ya' y'an'},
			yw => q{'hefteya' w'em' 'ya' Y'an'},
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
		'generic' => {
			GyM => {
				G => q{GGGGG MM.y – GGGGG MM.y},
				M => q{GGGGG MM.y – MM.y},
				y => q{GGGGG MM.y – MM.y},
			},
			GyMEd => {
				G => q{GGGGG dd.MM.y E – GGGGG dd.MM.y E},
				M => q{GGGGG dd.MM.y E – dd.MM.y E},
				d => q{GGGGG dd.MM.y E – dd.MM.y E},
				y => q{GGGGG dd.MM.y E – dd.MM.y E},
			},
			GyMMM => {
				G => q{G MMM'a' y'an' – G MMM'a' y'an'},
				M => q{G MMM–MMM y},
				y => q{G MMM'a' y'an' – MMM'a' y'an'},
			},
			GyMMMEd => {
				G => q{G d'ê' MMM'a' y'an' E – G d'ê' MMM'a' y'an' E},
				M => q{G d'ê' MMM'ê' E – d'ê' MMM'ê' E y},
				d => q{G d'ê' MMM'ê' E – d'ê' MMM'ê' E y},
				y => q{G d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
			},
			GyMMMd => {
				G => q{G d'ê' MMM'a' y'an' – G d'ê' MMM'a' y'an'},
				M => q{G d'ê' MMM'ê' – d'ê' MMM'ê' y},
				d => q{G d–d'ê' MMM'a' y'an'},
				y => q{G d'ê' MMM'a' y'an' – d'ê' MMM'a' y'an'},
			},
			GyMd => {
				G => q{GGGGG dd.MM.y – GGGGG dd.MM.y},
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{d.M E – d.M E},
				d => q{d.M E – d.M E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d'ê' MMM'ê', E – d'ê' MMM'ê', E},
				d => q{d'ê' MMM'ê', E – d'ê' MMM'ê', E},
			},
			MMMd => {
				M => q{d'ê' MMM'ê' – d'ê' MMM'ê'},
				d => q{d – d'ê' MMM'ê'},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			yM => {
				M => q{GGGGG MM.y – MM.y},
				y => q{GGGGG MM.y – MM.y},
			},
			yMEd => {
				M => q{GGGGG dd.MM.y E – dd.MM.y E},
				d => q{GGGGG dd.MM.y E – dd.MM.y E},
				y => q{GGGGG dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{G MMM–MMM y},
				y => q{G MMM'a' y'an' – MMMa y'an'},
			},
			yMMMEd => {
				M => q{G d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
				d => q{G d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
				y => q{G d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
			},
			yMMMM => {
				M => q{G MMMM – MMMM y},
				y => q{G MMMM'a' y'an' – MMMM'a' y'an'},
			},
			yMMMd => {
				M => q{G d'ê' MMM'ê' – d'ê' MMM'ê' y},
				d => q{G d–d'ê' MMM'a' y'an'},
				y => q{G d'ê' MMM'a' y'an' – d'ê' MMM'a' y'an'},
			},
			yMd => {
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h'ê' B – h'ê' B},
				h => q{h–h'ê' B},
			},
			GyM => {
				G => q{GGGGG MM.y – GGGGG MM.y},
				M => q{GGGGG MM.y – MM.y},
				y => q{GGGGG MM.y – MM.y},
			},
			GyMEd => {
				G => q{GGGGG dd.MM.y E – GGGGG dd.MM.y E},
				M => q{GGGGG dd.MM.y E – dd.MM.y E},
				d => q{GGGGG dd.MM.y E – dd.MM.y E},
				y => q{GGGGG dd.MM.y E – dd.MM.y E},
			},
			GyMMM => {
				G => q{G MMM'a' y'an' – G MMM'a' y'an'},
				M => q{G MMM–MMM y},
				y => q{G MMM'a' y'an' – MMM'a' y'an'},
			},
			GyMMMEd => {
				G => q{G d'ê' MMM'a' y'an' E – G d'ê' MMM'a' y'an' E},
				M => q{G d'ê' MMM'ê' E – d'ê' MMM'ê' E y},
				d => q{G d'ê' MMM'ê' E – d'ê' MMM'ê' E y},
				y => q{G d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
			},
			GyMMMd => {
				G => q{G d'ê' MMM'a' y'an' – G d'ê' MMM'a' y'an'},
				M => q{G d'ê' MMM'ê' – d'ê' MMM'ê' y},
				d => q{G d–d'ê' MMM'a' y'an'},
				y => q{G d'ê' MMM'a' y'an' – d'ê' MMM'a' y'an'},
			},
			GyMd => {
				G => q{GGGGG dd.MM.y – GGGGG dd.MM.y},
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{d.M E – d.M E},
				d => q{d.M E – d.M E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d'ê' MMM'ê', E – d'ê' MMM'ê', E},
				d => q{d'ê' MMM'ê', E – d'ê' MMM'ê', E},
			},
			MMMd => {
				M => q{d'ê' MMM'ê' – d'ê' MMM'ê'},
				d => q{d – d'ê' MMM'ê'},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			h => {
				a => q{h'ê' a – h'ê' a},
				h => q{h–h'ê' a},
			},
			hm => {
				a => q{h:mm'ê' a – h:mm'ê' a},
				h => q{h:mm–h:mm'ê' a},
				m => q{h:mm–h:mm'ê' a},
			},
			hmv => {
				a => q{h:mm'ê' a – h:mm'ê' a v},
				h => q{h:mm'ê'–h:mm'ê' a v},
				m => q{h:mm'ê'–h:mm'ê' a v},
			},
			hv => {
				a => q{h'ê' a – h'ê' a v},
				h => q{h–h'ê' a v},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y E – dd.MM.y E},
				d => q{dd.MM.y E – dd.MM.y E},
				y => q{dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM'a' y'an' – MMM'a' y'an'},
			},
			yMMMEd => {
				M => q{d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
				d => q{d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
				y => q{d'ê' MMM'a' y'an' E – d'ê' MMM'a' y'an' E},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM'a' y'an' – MMMM'a' y'an'},
			},
			yMMMd => {
				M => q{d'ê' MMM'ê' – d'ê' MMM'ê' y},
				d => q{d–d'ê' MMM'a' y'an'},
				y => q{d'ê' MMM'a' y'an' – d'ê' MMM'a' y'an'},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Saeta {0}(y)ê),
		regionFormat => q(Saeta Havînê ya {0}(y)ê),
		regionFormat => q(Saeta Standard a {0}(y)ê),
		'Afghanistan' => {
			long => {
				'standard' => q#Saeta Efxanistanê#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Cezayîr#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Qahîre#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Septe#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakrî#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daruselam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Cibûtî#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Xartûm#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kîgalî#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kînşasa#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Lîbrevîl#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maserû#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadîşû#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Naîrobî#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trablûs#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tûnis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Saeta Afrîkaya Navîn#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Saeta Afrîkaya Rojhilat#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Saeta Standard a Afrîkaya Başûr#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Saeta Havînê ya Afrîkaya Rojava#,
				'generic' => q#Saeta Afrîkaya Rojava#,
				'standard' => q#Saeta Standard a Afrîkaya Rojava#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Saeta Havînê ya Alaskayê#,
				'generic' => q#Saeta Alaskayê#,
				'standard' => q#Saeta Standard a Alaskayê#,
			},
			short => {
				'daylight' => q#SHAK#,
				'generic' => q#SAK#,
				'standard' => q#SSAK#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Saeta Havînê ya Amazonê#,
				'generic' => q#Saeta Amazonê#,
				'standard' => q#Saeta Standard a Amazonê#,
			},
		},
		'America/Aruba' => {
			exemplarCity => q#Arûba#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahîa Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Belîze#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancûn#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciûdad Juarez#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rîka#,
		},
		'America/Dominica' => {
			exemplarCity => q#Domînîka#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaîka#,
		},
		'America/Merida' => {
			exemplarCity => q#Merîda#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beûlah, Dakotaya Bakur#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakotaya Bakur#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakotaya Bakur#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rîko#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthelemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Saeta Havînê ya Navendî ya Amerîkaya Bakur#,
				'generic' => q#Saeta Navendî ya Amerîkaya Bakur#,
				'standard' => q#Saeta Standard a Navendî ya Amerîkaya Bakur#,
			},
			short => {
				'daylight' => q#SHN#,
				'generic' => q#SN#,
				'standard' => q#SSN#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Saeta Havînê ya Rojhilat ya Amerîkaya Bakur#,
				'generic' => q#Saeta Rojhilat a Amerîkaya Bakur#,
				'standard' => q#Saeta Standard a Rojhilat ya Amerîkaya Bakur#,
			},
			short => {
				'daylight' => q#SHR#,
				'generic' => q#SR#,
				'standard' => q#SSR#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Saeta Havînê ya Çîyayî ya Amerîkaya Bakur#,
				'generic' => q#Saeta Çîyayî ya Amerîkaya Bakur#,
				'standard' => q#Saeta Standard a Çîyayî ya Amerîkaya Bakur#,
			},
			short => {
				'daylight' => q#SHÇ#,
				'generic' => q#SÇ#,
				'standard' => q#SSÇ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Saeta Havînê ya Pasîfîkê ya Amerîkaya Bakur#,
				'generic' => q#Saeta Pasîfîkê ya Amerîkaya Bakur#,
				'standard' => q#Saeta Standard a Pasîfîkê ya Amerîkaya Bakur#,
			},
			short => {
				'daylight' => q#SHP#,
				'generic' => q#SP#,
				'standard' => q#SSP#,
			},
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davîs#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Apiayê#,
				'generic' => q#Saeta Apiayê#,
				'standard' => q#Saeta Standard a Apiayê#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Saeta Havînê ya Erebistanê#,
				'generic' => q#Saeta Erebistanê#,
				'standard' => q#Saeta Standard a Erebistanê#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Saeta Havînê ya Arjantînê#,
				'generic' => q#Saeta Arjantînê#,
				'standard' => q#Saeta Standard a Arjantînê#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Saeta Havînê ya Arjantîna Rojava#,
				'generic' => q#Saeta Arjantîna Rojava#,
				'standard' => q#Saeta Standard a Arjantîna Rojava#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ermenistanê#,
				'generic' => q#Saeta Ermenistanê#,
				'standard' => q#Saeta Standard a Ermenistanê#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatî#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Eman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtaw#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Eşqabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atîrav#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bexda#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Behreyn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakû#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrût#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bîşkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brûney#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Çîta#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Şam#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dîlî#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dûbaî#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duşenbe#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Xeze#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Cakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Cayapûra#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Quds#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabûl#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamçatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaçî#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandû#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Xandîga#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kûala Lûmpûr#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kûçîng#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuweyt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manîla#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Lefkoşe#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qeter#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qizilorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Bajarê Ho Chi Minhê#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Saxalîn#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Semerkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seûl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Şanghay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sîngapûr#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taîpeî#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taşkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflîs#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ûlanbatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ûrûmçî#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ûst-Nera#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Rewan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Saeta Havînê ya Atlantîkê#,
				'generic' => q#Saeta Atlantîkê#,
				'standard' => q#Saeta Standard a Atlantîkê#,
			},
			short => {
				'daylight' => q#SHA#,
				'generic' => q#SA#,
				'standard' => q#SSA#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Giravên Azorê#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermûda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Giravên Kanaryayê#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgiaya Başûr#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sîdney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Saeta Havînê ya Awistralyaya Navîn#,
				'generic' => q#Saeta Awistralyaya Navîn#,
				'standard' => q#Saeta Standard a Awistralyaya Navîn#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Saeta Havînê ya Rojavaya Navîn a Awistralyayê#,
				'generic' => q#Saeta Rojavaya Navîn a Awistralyayê#,
				'standard' => q#Saeta Standard a Rojavaya Navîn a Awistralyayê#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Saeta Havînê ya Awistralyaya Rojhilat#,
				'generic' => q#Saeta Awistralyaya Rojhilat#,
				'standard' => q#Saeta Standard a Awistralyaya Rojhilat#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Saeta Havînê ya Awistralyaya Rojava#,
				'generic' => q#Saeta Awistralyaya Rojava#,
				'standard' => q#Saeta Standard a Awistralyaya Rojava#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Saeta Havînê ya Azerbeycanê#,
				'generic' => q#Saeta Azerbeycanê#,
				'standard' => q#Saeta Standard a Azerbeycanê#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Saeta Havînê ya Azoran#,
				'generic' => q#Saeta Azoran#,
				'standard' => q#Saeta Standard a Azoran#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Saeta Havînê ya Bengladeşê#,
				'generic' => q#Saeta Bengladeşê#,
				'standard' => q#Saeta Standard a Bengladeşê#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Saeta Bûtanê#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Saeta Bolîvyayê#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Brasîlyayê#,
				'generic' => q#Saeta Brasîlyayê#,
				'standard' => q#Saeta Standard a Brasîlyayê#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Saeta Brûney Darusselamê#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Saeta Havînê ya Cape Verdeyê#,
				'generic' => q#Saeta Cape Verdeyê#,
				'standard' => q#Saeta Standard a Cape Verdeyê#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Saeta Standard a Chamorroyê#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Saeta Havînê ya Chathamê#,
				'generic' => q#Saeta Chathamê#,
				'standard' => q#Saeta Standard a Chathamê#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Saeta Havînê ya Şîlîyê#,
				'generic' => q#Saeta Şîlîyê#,
				'standard' => q#Saeta Standard a Şîlîyê#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Saeta Havînê ya Çînê#,
				'generic' => q#Saeta Çînê#,
				'standard' => q#Saeta Standard a Çînê#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Saeta Girava Christmasê#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Saeta Giravên Cocosê#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Kolombîyayê#,
				'generic' => q#Saeta Kolombîyayê#,
				'standard' => q#Saeta Standard a Kolombîyayê#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Saeta Nîvhavînê ya Giravên Cookê#,
				'generic' => q#Saeta Giravên Cookê#,
				'standard' => q#Saeta Standard a Giravên Cookê#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Saeta Havînê ya Kubayê#,
				'generic' => q#Saeta Kubayê#,
				'standard' => q#Saeta Standard a Kubayê#,
			},
			short => {
				'daylight' => q#SHK#,
				'generic' => q#SK#,
				'standard' => q#SSK#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Saeta Davîsê#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Saeta Dumont-d’Urvilleyê#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Saeta Tîmûra Rojhilat#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Saeta Havînê ya Girava Paskalyayê#,
				'generic' => q#Saeta Girava Paskalyayê#,
				'standard' => q#Saeta Standard a Girava Paskalyayê#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Saeta Ekwadorê#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Saeta Gerdûnî ya Hevdemî#,
			},
			short => {
				'standard' => q#SGH#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Bajarê Nenas#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astraxan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atîna#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlîn#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruksel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukreş#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Bûdapeşt#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Bûsîngen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kişînew#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhag#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dûblîn#,
			long => {
				'daylight' => q#Saeta Standard a Îrlandayê#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Cebelîtariq#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsînkî#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Girava Manê#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Stenbol#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalînîngrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kîev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kîrov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lîzbon#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#Saeta Havînê ya Brîtanyayê#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksembûrg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrîd#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mînsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskova#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parîs#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorîka#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Rîga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marîno#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Saraybosna#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Uskup#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talîn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tîran#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatîkan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viyana#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vîlnûs#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warşova#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zûrîh#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ewropaya Navîn#,
				'generic' => q#Saeta Ewropaya Navîn#,
				'standard' => q#Saeta Standard a Ewropaya Navîn#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ewropaya Rojhilat#,
				'generic' => q#Saeta Ewropaya Rojhilat#,
				'standard' => q#Saeta Standard a Ewropaya Rojhilat#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Saeta Ewropaya Rojhilat a Pêştir#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ewropaya Rojava#,
				'generic' => q#Saeta Ewropaya Rojava#,
				'standard' => q#Saeta Standard a Ewropaya Rojava#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Saeta Havînê ya Giravên Falklandê#,
				'generic' => q#Saeta Giravên Falklandê#,
				'standard' => q#Saeta Standard a Giravên Falklandê#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Saeta Havînê ya Fîjîyê#,
				'generic' => q#Saeta Fîjîyê#,
				'standard' => q#Saeta Standard a Fîjîyê#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Saeta Guiyanaya Fransî#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Saeta Antarktîka û Başûrê Fransayê#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Saeta Navînî ya Greenwichê#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Saeta Galapagosê#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Saeta Gambierê#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Gurcistanê#,
				'generic' => q#Saeta Gurcistanê#,
				'standard' => q#Saeta Standard a Gurcistanê#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Saeta Giravên Gilbertê#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Saeta Havînê ya Grînlanda Rojhilat#,
				'generic' => q#Saeta Grînlanda Rojhilat#,
				'standard' => q#Saeta Standard a Grînlanda Rojhilat#,
			},
			short => {
				'daylight' => q#SHGR#,
				'generic' => q#SGR#,
				'standard' => q#SSGR#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Saeta Havînê ya Grînlanda Rojava#,
				'generic' => q#Saeta Grînlanda Rojava#,
				'standard' => q#Saeta Standard a Grînlanda Rojava#,
			},
			short => {
				'daylight' => q#SHGRO#,
				'generic' => q#SGRO#,
				'standard' => q#SSGRO#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Saeta Standard a Kendavê#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Saeta Guyanayê#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Saeta Havînê ya Hawaii-Aleutianê#,
				'generic' => q#Saeta Hawaii-Aleutianê#,
				'standard' => q#Saeta Standard a Hawaii-Aleutianê#,
			},
			short => {
				'daylight' => q#SHHA#,
				'generic' => q#SHAL#,
				'standard' => q#SSHA#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Saeta Havînê ya Hong Kongê#,
				'generic' => q#Saeta Hong Kongê#,
				'standard' => q#Saeta Standard a Hong Kongê#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Saeta Havînê ya Hovdê#,
				'generic' => q#Saeta Hovdê#,
				'standard' => q#Saeta Standard a Hovdê#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Saeta Standard a Hindistanê#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komor#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldîv#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Saeta Okyanûsa Hindê#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Saeta Hindiçînê#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Saeta Endonezyaya Navîn#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Saeta Endonezyaya Rojhilat#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Saeta Endonezyaya Rojava#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Saeta Havînê ya Îranê#,
				'generic' => q#Saeta Îranê#,
				'standard' => q#Saeta Standard a Îranê#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Saeta Havînê ya Irkutskê#,
				'generic' => q#Saeta Irkutskê#,
				'standard' => q#Saeta Standard a Irkutskê#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Saeta Havînê ya Îsraîlê#,
				'generic' => q#Saeta Îsraîlê#,
				'standard' => q#Saeta Standard a Îsraîlê#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Saeta Havşnê ya Japonyayê#,
				'generic' => q#Saeta Japonyayê#,
				'standard' => q#Saeta Standard a Japonyayê#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Saeta Qazaxistanê#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Saeta Qazaxistana Rojhilat#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Saeta Qazaxistana Rojava#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Saeta Havînê ya Koreyê#,
				'generic' => q#Saeta Koreyê#,
				'standard' => q#Saeta Standard a Koreyê#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Saeta Kosraeyê#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Saeta Havînê ya Krasnoyarskê#,
				'generic' => q#Saeta Krasnoyarskê#,
				'standard' => q#Saeta Standard a Krasnoyarskê#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Saeta Qirxizistanê#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Saeta Giravên Lîneyê#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Saeta Havînê ya Lord Howeyê#,
				'generic' => q#Saeta Lord Howeyê#,
				'standard' => q#Saeta Standard a Lord Howeyê#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Saeta Havînê ya Magadanê#,
				'generic' => q#Saeta Magadanê#,
				'standard' => q#Saeta Standard a Magadanê#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Saeta Malezyayê#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Saeta Maldîvan#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Saeta Marquesasê#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Saeta Giravên Marşalê#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Saeta Havînê ya Mauritiusê#,
				'generic' => q#Saeta Mauritiusê#,
				'standard' => q#Saeta Standard a Mauritiusê#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Saeta Mawsonê#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Saeta Havînê ya Pasîfîka Meksîkayê#,
				'generic' => q#Saeta Pasîfîka Meksîkayê#,
				'standard' => q#Saeta Standard a Pasîfîka Meksîkayê#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ûlanbatarê#,
				'generic' => q#Saeta Ûlanbatarê#,
				'standard' => q#Saeta Standard a Ûlanbatarê#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Saeta Havînê ya Moskovayê#,
				'generic' => q#Saeta Moskovayê#,
				'standard' => q#Saeta Standard a Moskovayê#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Saeta Myanmarê#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Saeta Naûrûyê#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Saeta Nepalê#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Saeta Havînê ya Kaledonyaya Nû#,
				'generic' => q#Saeta Kaledonyaya Nû#,
				'standard' => q#Saeta Standard a Kaledonyaya Nû#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Saeta Havînê ya Zelandaya Nû#,
				'generic' => q#Saeta Zelandaya Nû#,
				'standard' => q#Saeta Standard a Zelandaya Nû#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Saeta Havînê ya Newfoundlandê#,
				'generic' => q#Saeta Newfoundlandê#,
				'standard' => q#Saeta Standard a Newfoundlandê#,
			},
			short => {
				'daylight' => q#SHNF#,
				'generic' => q#SNF#,
				'standard' => q#SSNF#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Saeta Niueyê#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Saeta Havînê ya Girava Norfolkê#,
				'generic' => q#Saeta Girava Norfolkê#,
				'standard' => q#Saeta Standard a Girava Norfolkê#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Saeta Havînê ya Fernando de Noronhayê#,
				'generic' => q#Saeta Fernando de Noronhayê#,
				'standard' => q#Saeta Standard a Fernando de Noronhayê#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Saeta Havînê ya Novosibirskê#,
				'generic' => q#Saeta Novosibirskê#,
				'standard' => q#Saeta Standard a Novosibirskê#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Saeta Havînê ya Omskê#,
				'generic' => q#Saeta Omskê#,
				'standard' => q#Saeta Standard a Omskê#,
			},
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fîjî#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahîtî#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Saeta Havînê ya Pakistanê#,
				'generic' => q#Saeta Pakistanê#,
				'standard' => q#Saeta Standard a Pakistanê#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Saeta Palauyê#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Saeta Gîneya Nû ya Papûayê#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Saeta Havînê ya Paragûayê#,
				'generic' => q#Saeta Paragûayê#,
				'standard' => q#Saeta Standard a Paragûayê#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Saeta Havînê ya Perûyê#,
				'generic' => q#Saeta Perûyê#,
				'standard' => q#Saeta Standard a Perûyê#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Saeta Havînê ya Fîlîpînê#,
				'generic' => q#Saeta Fîlîpînê#,
				'standard' => q#Saeta Standard a Fîlîpînê#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Saeta Giravên Phoenîks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saeta Havînê ya Saint Pierre û Miquelonê#,
				'generic' => q#Saeta Saint Pierre û Miquelonê#,
				'standard' => q#Saeta Standard a Saint Pierre û Miquelonê#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Saeta Pitcairnê#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Saeta Ponapeyê#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Saeta Pyongyangê#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Saeta Réunionê#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Saeta Rotherayê#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Saeta Havînê ya Saxalînê#,
				'generic' => q#Saeta Saxalînê#,
				'standard' => q#Saeta Standard a Saxalînê#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Saeta Havînê ya Samoayê#,
				'generic' => q#Saeta Samoayê#,
				'standard' => q#Saeta Standard a Samoayê#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Saeta Seyşelerê#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Saeta Standard a Sîngapûrê#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Saeta Giravên Solomonê#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Saeta Georgiaya Başûr#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Saeta Surînamê#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Saeta Syowayê#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Saeta Tahîtîyê#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Saeta Havînê ya Taîpeîyê#,
				'generic' => q#Saeta Taîpeîyê#,
				'standard' => q#Saeta Standard a Taîpeîyê#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Saeta Tacikistanê#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Saeta Tokelauyê#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Saeta Havînê ya Tongayê#,
				'generic' => q#Saeta Tongayê#,
				'standard' => q#Saeta Standard a Tongayê#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Saeta Chuukê#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Saeta Havînê ya Tirkmenistanê#,
				'generic' => q#Saeta Tirkmenistanê#,
				'standard' => q#Saeta Standard a Tirkmenistanê#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Saeta Tûvalûyê#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ûrûgûayê#,
				'generic' => q#Saeta Ûrûgûayê#,
				'standard' => q#Saeta Standard a Ûrûgûayê#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Saeta Havînê ya Ozbekistanê#,
				'generic' => q#Saeta Ozbekistanê#,
				'standard' => q#Saeta Standard a Ozbekistanê#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Saeta Havînê ya Vanûatûyê#,
				'generic' => q#Saeta Vanûatûyê#,
				'standard' => q#Saeta Standard a Vanûatûyê#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Saeta Venezûelayê#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Saeta Havînê ya Vladivostokê#,
				'generic' => q#Saeta Vladivostokê#,
				'standard' => q#Saeta Standard a Vladivostokê#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Saeta Havînê ya Volgogradê#,
				'generic' => q#Saeta Volgogradê#,
				'standard' => q#Saeta Standard a Volgogradê#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Saeta Vostokê#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Saeta Girava Wakeyê#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Saeta Wallis û Futunayê#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Saeta Havînê ya Yakutskê#,
				'generic' => q#Saeta Yakutskê#,
				'standard' => q#Saeta Standard a Yakutskê#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Saeta Havînê ya Yekaterinburgê#,
				'generic' => q#Saeta Yekaterinburgê#,
				'standard' => q#Saeta Standard a Yekaterinburgê#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Saeta Yukonê#,
			},
			short => {
				'standard' => q#SY#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
