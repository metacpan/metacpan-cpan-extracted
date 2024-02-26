=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mi - Package for language Māori

=cut

package Locale::CLDR::Locales::Mi;
# This file auto generated from Data\common\main\mi.xml
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
				'ab' => 'Apakāhiana',
 				'ace' => 'Akanīhi',
 				'ada' => 'Atāngami',
 				'ady' => 'Āteke',
 				'af' => 'Awherikāna',
 				'agq' => 'Ākeme',
 				'ain' => 'Ainu',
 				'ak' => 'Ākana',
 				'ale' => 'Ariuta',
 				'alt' => 'Ātai ki te Tonga',
 				'am' => 'Amahereka',
 				'an' => 'Arakonihi',
 				'ann' => 'Ōporo',
 				'anp' => 'Anahika',
 				'ar' => 'Ārapi',
 				'ar_001' => 'Ārapi Moroko',
 				'arn' => 'Mapūte',
 				'arp' => 'Arapaho',
 				'ars' => 'Arapika Nahāri',
 				'as' => 'Āhamēhi',
 				'asa' => 'Ahu',
 				'ast' => 'Ahitūriana',
 				'atj' => 'Atikameke',
 				'av' => 'Āwhāriki',
 				'awa' => 'Awāti',
 				'ay' => 'Aimāra',
 				'az' => 'Atepaihānia',
 				'az@alt=short' => 'Ahēri',
 				'ba' => 'Pākīra',
 				'ban' => 'Pārinīhi',
 				'bas' => 'Pahā',
 				'be' => 'Perarūhiana',
 				'bem' => 'Pema',
 				'bez' => 'Pena',
 				'bg' => 'Purukāriana',
 				'bgc' => 'Herianawhi',
 				'bho' => 'Pōhipuri',
 				'bi' => 'Pihirāma',
 				'bin' => 'Pini',
 				'bla' => 'Hihika',
 				'bm' => 'Pāpara',
 				'bn' => 'Pākara',
 				'bo' => 'Tipete',
 				'br' => 'Peretana',
 				'brx' => 'Pōto',
 				'bs' => 'Pōngiana',
 				'bug' => 'Pukenīhi',
 				'byn' => 'Pirina',
 				'ca' => 'Katarana',
 				'cay' => 'Keiūka',
 				'ccp' => 'Tiakamā',
 				'ce' => 'Tietiene',
 				'ceb' => 'Hepuano',
 				'cgg' => 'Tieka',
 				'ch' => 'Tiamoro',
 				'chk' => 'Tiukīhi',
 				'chm' => 'Mari',
 				'cho' => 'Tiokatō',
 				'chp' => 'Tiepewaiana',
 				'chr' => 'Tierokī',
 				'chy' => 'Haiene',
 				'ckb' => 'Kūrihi Waenga',
 				'ckb@alt=menu' => 'Kūrihi, Waenga',
 				'ckb@alt=variant' => 'Kūrihi, Hōrani',
 				'clc' => 'Tiekautini',
 				'co' => 'Kōhikana',
 				'crg' => 'Mītiwhi',
 				'crj' => 'Kirī Tonga-mā-Rāwhiti',
 				'crk' => 'Pareina Kirī',
 				'crl' => 'Kirī Raki-mā-Rāwhiti',
 				'crm' => 'Mūhi Kirī',
 				'crr' => 'Arakōkiana Kararaina',
 				'cs' => 'Tieke',
 				'csw' => 'Wāpi Kirī',
 				'cv' => 'Tiuwhāhi',
 				'cy' => 'Werehi',
 				'da' => 'Teina',
 				'dak' => 'Takōta',
 				'dar' => 'Tākawa',
 				'dav' => 'Taita',
 				'de' => 'Tiamana',
 				'de_AT' => 'Tiamana Ateriana',
 				'de_CH' => 'Tiamana Ōkawa Huiterangi',
 				'dgr' => 'Tōkiripi',
 				'dje' => 'Tāma',
 				'doi' => 'Tōkiri',
 				'dsb' => 'Hōpiana Hakahaka',
 				'dua' => 'Tuāra',
 				'dv' => 'Tīwhehi',
 				'dyo' => 'Hora-Whōni',
 				'dz' => 'Tonoka',
 				'dzg' => 'Tahāka',
 				'ebu' => 'Emepū',
 				'ee' => 'Ewe',
 				'efi' => 'Ewhiki',
 				'eka' => 'Ekatika',
 				'el' => 'Kariki',
 				'en' => 'Ingarihi',
 				'en_AU' => 'Ingarihi Ahitereiriana',
 				'en_CA' => 'Ingarihi Kānata',
 				'en_GB' => 'Ingarihi Piritene',
 				'en_GB@alt=short' => 'Ingarihi UK',
 				'en_US' => 'Ingarihi Amerikana',
 				'en_US@alt=short' => 'Ingarihi US',
 				'eo' => 'Eheperāto',
 				'es' => 'Pāniora',
 				'es_419' => 'Pāniora Amerikana ki te Tonga',
 				'es_ES' => 'Pāniora Ūropi',
 				'es_MX' => 'Pāniora Mehikana',
 				'et' => 'Etōniana',
 				'eu' => 'Pākihi',
 				'ewo' => 'Ewāto',
 				'fa' => 'Pāhiana',
 				'fa_AF' => 'Tāri',
 				'ff' => 'Whūra',
 				'fi' => 'Whinirānia',
 				'fil' => 'Piripīno',
 				'fj' => 'Whītīana',
 				'fo' => 'Wharoīhi',
 				'fon' => 'Whāna',
 				'fr' => 'Wīwī',
 				'fr_CA' => 'Wīwī Kānata',
 				'fr_CH' => 'Wīwī Huiterangi',
 				'frc' => 'Wīwī Keihana',
 				'frr' => 'Whirīhiana ki te Raki',
 				'fur' => 'Whiriūriana',
 				'fy' => 'Whirīhiana ki te Uru',
 				'ga' => 'Airihi',
 				'gaa' => 'Kā',
 				'gd' => 'Keiriki Kotimana',
 				'gez' => 'Kīhi',
 				'gil' => 'Kiripatīhi',
 				'gl' => 'Karīhia',
 				'gn' => 'Kuaranī',
 				'gor' => 'Korōtaro',
 				'gsw' => 'Tiamana Huiterangi',
 				'gu' => 'Kutarāti',
 				'guz' => 'Kūhī',
 				'gv' => 'Manaki',
 				'gwi' => 'Kuitīna',
 				'ha' => 'Hauha',
 				'hai' => 'Heira',
 				'haw' => 'Wāhu',
 				'hax' => 'Haira ki te Tonga',
 				'he' => 'Hīperu',
 				'hi' => 'Hīni',
 				'hil' => 'Hirikaina',
 				'hmn' => 'Mōnga',
 				'hr' => 'Koroātiana',
 				'hsb' => 'Hōpiana Maunga',
 				'ht' => 'Kereō Haiti',
 				'hu' => 'Hanekari',
 				'hup' => 'Hupa',
 				'hur' => 'Hākomerema',
 				'hy' => 'Āmeniana',
 				'hz' => 'Herero',
 				'ia' => 'Inarīngua',
 				'iba' => 'Īpana',
 				'ibb' => 'Ipīpio',
 				'id' => 'Initonīhiana',
 				'ig' => 'Ikapo',
 				'ii' => 'Hīhuana Eī',
 				'ikt' => 'Inukitetūta Kānata ki te Uru',
 				'ilo' => 'Iroko',
 				'inh' => 'Inguihi',
 				'io' => 'Īto',
 				'is' => 'Tiorangi',
 				'it' => 'Itāriana',
 				'iu' => 'Inukitetūta',
 				'ja' => 'Hapanihi',
 				'jbo' => 'Rōpāna',
 				'jgo' => 'Nakōma',
 				'jmc' => 'Mākame',
 				'jv' => 'Hāwhanihi',
 				'ka' => 'Hōriana',
 				'kab' => 'Kapāiro',
 				'kac' => 'Katīana',
 				'kaj' => 'Heiho',
 				'kam' => 'Kāmapa',
 				'kbd' => 'Kapāriana',
 				'kcg' => 'Tiapa',
 				'kde' => 'Makonote',
 				'kea' => 'Kapuwētianu',
 				'kfo' => 'Koro',
 				'kgp' => 'Keinganga',
 				'kha' => 'Kahi',
 				'khq' => 'Kōira Tīni',
 				'ki' => 'Kikūiu',
 				'kj' => 'Kuoniāma',
 				'kk' => 'Kahāka',
 				'kkj' => 'Kako',
 				'kl' => 'Kararīhutu',
 				'kln' => 'Karenini',
 				'km' => 'Kimēra',
 				'kmb' => 'Kimipunu',
 				'kn' => 'Kanara',
 				'ko' => 'Kōreana',
 				'kok' => 'Kōkani',
 				'kpe' => 'Kepēre',
 				'kr' => 'Kanuri',
 				'krc' => 'Karatai-Pāka',
 				'krl' => 'Kareriana',
 				'kru' => 'Kuruka',
 				'ks' => 'Kahimiri',
 				'ksb' => 'Hapāra',
 				'ksf' => 'Pāwhia',
 				'ksh' => 'Korōniana',
 				'ku' => 'Kūrihi',
 				'kum' => 'Kumiki',
 				'kv' => 'Komi',
 				'kw' => 'Kōnihi',
 				'kwk' => 'Kuakawara',
 				'ky' => 'Kiakihi',
 				'la' => 'Rātini',
 				'lad' => 'Ratino',
 				'lag' => 'Rangi',
 				'lb' => 'Rakapuō',
 				'lez' => 'Rēhiana',
 				'lg' => 'Kānata',
 				'li' => 'Ripūkuihi',
 				'lil' => 'Riruete',
 				'lkt' => 'Rakōta',
 				'ln' => 'Ringāra',
 				'lo' => 'Rao',
 				'lou' => 'Kreōro Ruihiana',
 				'loz' => 'Rohi',
 				'lrc' => 'Ruri ki te Raki',
 				'lsm' => 'Hāmia',
 				'lt' => 'Rituānia',
 				'lu' => 'Rupa Katanga',
 				'lua' => 'Rupa Rurua',
 				'lun' => 'Runa',
 				'luo' => 'Ruo',
 				'lus' => 'Mīho',
 				'luy' => 'Rūia',
 				'lv' => 'Rāwhia',
 				'mad' => 'Maturīhi',
 				'mag' => 'Makāhi',
 				'mai' => 'Maitiri',
 				'mak' => 'Makahā',
 				'mas' => 'Māhai',
 				'mdf' => 'Mōkaha',
 				'men' => 'Menēte',
 				'mer' => 'Meru',
 				'mfe' => 'Morihiene',
 				'mg' => 'Marakāhi',
 				'mgh' => 'Makuwa-Mēto',
 				'mgo' => 'Meta',
 				'mh' => 'Mararīhi',
 				'mi' => 'Māori',
 				'mic' => 'Mīkamā',
 				'min' => 'Minākapao',
 				'mk' => 'Makerōnia',
 				'ml' => 'Mareiārama',
 				'mn' => 'Mongōria',
 				'mni' => 'Manipuri',
 				'moe' => 'Inu-aimuna',
 				'moh' => 'Mauhōka',
 				'mos' => 'Mohi',
 				'mr' => 'Marati',
 				'ms' => 'Marei',
 				'mt' => 'Mārata',
 				'mua' => 'Mūnatanga',
 				'mul' => 'Ngā reo maha',
 				'mus' => 'Mukōki',
 				'mwl' => 'Miranatīhi',
 				'my' => 'Pēmīhi',
 				'myv' => 'Erehīa',
 				'mzn' => 'Mahaterani',
 				'na' => 'Nauru',
 				'nap' => 'Neaporitana',
 				'naq' => 'Nama',
 				'nb' => 'Pakamō Nōwei',
 				'nd' => 'Enetepēra ki te Raki',
 				'nds' => 'Tiamana Hakahaka',
 				'ne' => 'Nepari',
 				'new' => 'Newari',
 				'ng' => 'Natōka',
 				'nia' => 'Niāhi',
 				'niu' => 'Niueana',
 				'nl' => 'Tati',
 				'nl_BE' => 'Tati Whēmirihi',
 				'nmg' => 'Kuahio',
 				'nn' => 'Nīnōka Nōwei',
 				'nnh' => 'Nekiepūna',
 				'no' => 'Nōwei',
 				'nog' => 'Nōkai',
 				'nqo' => 'Unukō',
 				'nr' => 'Enetepēra ki te Tonga',
 				'nso' => 'Hoto ki te Raki',
 				'nus' => 'Nua',
 				'nv' => 'Nawahō',
 				'ny' => 'Niānia',
 				'nyn' => 'Niānakore',
 				'oc' => 'Ōkitana',
 				'ojb' => 'Ōtīpia Raki-mā-Uru',
 				'ojc' => 'Ohīpawe Waenga',
 				'ojs' => 'Ōti-Kirī',
 				'ojw' => 'Ōhīpiwa ki te Uru',
 				'oka' => 'Ōkanakana',
 				'om' => 'Ōromo',
 				'or' => 'Ōtia',
 				'os' => 'Ōtītiki',
 				'pa' => 'Punutapi',
 				'pag' => 'Pāngahina',
 				'pam' => 'Pamapaka',
 				'pap' => 'Papiamēto',
 				'pau' => 'Pārau',
 				'pcm' => 'Ngāitiriana Kōrapurapu',
 				'pis' => 'Pītini',
 				'pl' => 'Pōrihi',
 				'pqm' => 'Marahiti-Pehamakoare',
 				'ps' => 'Pāhitō',
 				'pt' => 'Pōtukīhi',
 				'pt_BR' => 'Pōtukīhi Parahi',
 				'pt_PT' => 'Pōtukīhi Uropi',
 				'qu' => 'Kētua',
 				'raj' => 'Ratiahitani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotonga',
 				'rhg' => 'Rohingia',
 				'rm' => 'Romānihi',
 				'rn' => 'Rūniti',
 				'ro' => 'Romeinia',
 				'rof' => 'Romopo',
 				'ru' => 'Ruhiana',
 				'rup' => 'Aromeiniana',
 				'rw' => 'Kiniawāna',
 				'rwk' => 'Rawa',
 				'sa' => 'Hanahiti',
 				'sad' => 'Hātawe',
 				'sah' => 'Hakūta',
 				'saq' => 'Hāmapuru',
 				'sat' => 'Hatāri',
 				'sba' => 'Nekāpei',
 				'sbp' => 'Hāngu',
 				'sc' => 'Hārinia',
 				'scn' => 'Hihiriana',
 				'sco' => 'Kotimana',
 				'sd' => 'Hiniti',
 				'se' => 'Hami ki te Raki',
 				'seh' => 'Hena',
 				'ses' => 'Kōiraporo Heni',
 				'sg' => 'Hāngo',
 				'shi' => 'Tāhehita',
 				'shn' => 'Hāna',
 				'si' => 'Hinihāra',
 				'sk' => 'Horowākia',
 				'sl' => 'Horowinia',
 				'slh' => 'Ratūti ki te Tonga',
 				'sm' => 'Hāmoa',
 				'smn' => 'Inari Hami',
 				'sms' => 'Hakoto Hāmi',
 				'sn' => 'Hōna',
 				'snk' => 'Honīke',
 				'so' => 'Hamāri',
 				'sq' => 'Arapeiniana',
 				'sr' => 'Hirupia',
 				'srn' => 'Harāna Tongo',
 				'ss' => 'Wāti',
 				'st' => 'Hōto ki te Tonga',
 				'str' => 'Hārihi Kuititanga',
 				'su' => 'Hunanīhi',
 				'suk' => 'Hukuma',
 				'sv' => 'Huitene',
 				'sw' => 'Wāhīri',
 				'swb' => 'Komōriana',
 				'syr' => 'Hīriaka',
 				'ta' => 'Tamira',
 				'tce' => 'Tatōne ki te Tonga',
 				'te' => 'Teruku',
 				'tem' => 'Tīmene',
 				'teo' => 'Teho',
 				'tet' => 'Tetumu',
 				'tg' => 'Tāhiki',
 				'tgx' => 'Tākihi',
 				'th' => 'Tai',
 				'tht' => 'Tātana',
 				'ti' => 'Tekirinia',
 				'tig' => 'Tīkara',
 				'tk' => 'Tākamana',
 				'tlh' => 'Kirīngona',
 				'tli' => 'Tirīkiti',
 				'tn' => 'Hawāna',
 				'to' => 'Tonga',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Toko Pīhini',
 				'tr' => 'Tākei',
 				'trv' => 'Taroko',
 				'ts' => 'Honga',
 				'tt' => 'Tatā',
 				'ttm' => 'Tūtone ki te Raki',
 				'tum' => 'Tumūka',
 				'tvl' => 'Tuwaru',
 				'twq' => 'Tahawaka',
 				'ty' => 'Tahiti',
 				'tyv' => 'Tuwīniana',
 				'tzm' => 'Tamahīta Te Puku o Atarihi',
 				'udm' => 'Ūmutu',
 				'ug' => 'Wīkura',
 				'uk' => 'Ukareinga',
 				'umb' => 'Ūpunu',
 				'und' => 'Reo Tē Mōhiotia',
 				'ur' => 'Ūrutu',
 				'uz' => 'Ūpeke',
 				'vai' => 'Wai',
 				've' => 'Wēnera',
 				'vi' => 'Whitināmu',
 				'vun' => 'Whunio',
 				'wa' => 'Warūna',
 				'wae' => 'Wāhere',
 				'wal' => 'Wareita',
 				'war' => 'Warei',
 				'wo' => 'Warawhe',
 				'wuu' => 'Hainamana Wū',
 				'xal' => 'Karamiki',
 				'xh' => 'Tōha',
 				'xog' => 'Hoka',
 				'yav' => 'Angapene',
 				'ybb' => 'Emapa',
 				'yi' => 'Irihi',
 				'yo' => 'Ōrūpa',
 				'yrl' => 'Nīkātū',
 				'yue' => 'Katonīhi',
 				'yue@alt=menu' => 'Hainamana, Katonīhi',
 				'zgh' => 'Moroko Tamatai',
 				'zh' => 'Hainamana',
 				'zh@alt=menu' => 'Hainamana Manarini',
 				'zh_Hans' => 'Hainamana Māmā',
 				'zh_Hant' => 'Hainamana Tukuiho',
 				'zu' => 'Tūru',
 				'zun' => 'Tuni',
 				'zxx' => 'Wetereo kiko kore',
 				'zza' => 'Tātā',

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
			'Adlm' => 'Atarama',
 			'Arab' => 'Arapika',
 			'Aran' => 'Nātarika',
 			'Armn' => 'Āmeniana',
 			'Beng' => 'Pāngara',
 			'Bopo' => 'Papamawha',
 			'Brai' => 'Tuhi Matapō',
 			'Cakm' => 'Tiakamā',
 			'Cans' => 'Ngā Kūoro o ngā Iwi Taketake o Kānata kua paiheretia',
 			'Cher' => 'Terokī',
 			'Cyrl' => 'Hīririki',
 			'Deva' => 'Tewhangāngari',
 			'Ethi' => 'Etiopika',
 			'Geor' => 'Hōriana',
 			'Grek' => 'Kariki',
 			'Gujr' => 'Kutarāti',
 			'Guru' => 'Kūmuki',
 			'Hanb' => 'Hana me te Papamawha',
 			'Hang' => 'Hāngū',
 			'Hani' => 'Hana',
 			'Hans' => 'Māmā',
 			'Hans@alt=stand-alone' => 'Hana Māmā',
 			'Hant' => 'Tuku iho',
 			'Hant@alt=stand-alone' => 'Hana Tuku iho',
 			'Hebr' => 'Hīperu',
 			'Hira' => 'Hirakana',
 			'Hrkt' => 'Kūoro Hapanihi',
 			'Jamo' => 'Hamo',
 			'Jpan' => 'Hapanihi',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Kimēra',
 			'Knda' => 'Kanāra',
 			'Kore' => 'Kōreana',
 			'Laoo' => 'Rao',
 			'Latn' => 'Rātini',
 			'Mlym' => 'Maraiārama',
 			'Mong' => 'Mongōria',
 			'Mtei' => 'Meitei Maeke',
 			'Mymr' => 'Mienemā',
 			'Nkoo' => 'Unukō',
 			'Olck' => 'Ōtiki',
 			'Orya' => 'Otia',
 			'Rohg' => 'Hāniwhi',
 			'Sinh' => 'Hināra',
 			'Sund' => 'Hunanihi',
 			'Syrc' => 'Hīriaka',
 			'Taml' => 'Tamiera',
 			'Telu' => 'Teruku',
 			'Tfng' => 'Tiwhinā',
 			'Thaa' => 'Tāna',
 			'Thai' => 'Tai',
 			'Tibt' => 'Tipete',
 			'Vaii' => 'Wai',
 			'Yiii' => 'Eī',
 			'Zmth' => 'Reo Tohu Pāngarau',
 			'Zsye' => 'Emohi',
 			'Zsym' => 'Tohu',
 			'Zxxx' => 'Tuhikore',
 			'Zyyy' => 'Komona',
 			'Zzzz' => 'Momotuhi Tē Mōhiotia',

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
			'001' => 'te ao',
 			'002' => 'Āwherika',
 			'003' => 'Amerika ki te Raki',
 			'005' => 'Amerika ki te Tonga',
 			'009' => 'Ngā Moutere-a-Kiwa',
 			'011' => 'Āwherika ki te Uru',
 			'013' => 'Te Puku o Amerika',
 			'014' => 'Āwherika ki te Rāwhiti',
 			'015' => 'Āwherika ki te Raki',
 			'017' => 'Te Pokapū o Āwherika',
 			'018' => 'Āwherika Whakatetonga',
 			'019' => 'Amerika',
 			'021' => 'Te Raki o Amerika',
 			'029' => 'Karapīana',
 			'030' => 'Āhia ki te Rāwhiti',
 			'034' => 'Āhia ki te Tonga',
 			'035' => 'Āhia ki te Tonga-mā-rāwhiti',
 			'039' => 'Ūropi ki te Tonga',
 			'053' => 'Atareiria',
 			'054' => 'Meranīhia',
 			'057' => 'Te Rohe o Mekanēhia',
 			'061' => 'Te Moana-nui-a-Kiwa',
 			'142' => 'Āhia',
 			'143' => 'Te Puku o Āhia',
 			'145' => 'Āhia ki te Uru',
 			'150' => 'Ūropi',
 			'151' => 'Ūropi ki te Rāwhiti',
 			'154' => 'Ūropi ki te Raki',
 			'155' => 'Ūropi ki te Uru',
 			'202' => 'Āwherika ki te Tonga o Te Hahāra',
 			'419' => 'Amerika Rātini',
 			'AC' => 'Te Moutere Aupikinga',
 			'AD' => 'Anatōra',
 			'AE' => 'Kotahitanga o ngā Whenua o Ārapi',
 			'AF' => 'Awhekenetāna',
 			'AG' => 'Motu Nehe me Pāputa',
 			'AI' => 'Anguira',
 			'AL' => 'Arapeinia',
 			'AM' => 'Āmenia',
 			'AO' => 'Anakora',
 			'AQ' => 'Te Kōpakatanga ki te Tonga',
 			'AR' => 'Āketina',
 			'AS' => 'Hāmoa-Amerika',
 			'AT' => 'Ataria',
 			'AU' => 'Ahitereiria',
 			'AW' => 'Arūpa',
 			'AX' => 'Motu Ōrana',
 			'AZ' => 'Atepaihānia',
 			'BA' => 'Pōngia-Herekōwini',
 			'BB' => 'Papatohe',
 			'BD' => 'Pākaratēhi',
 			'BE' => 'Peretiama',
 			'BF' => 'Pākina Wharo',
 			'BG' => 'Purukāria',
 			'BH' => 'Pāreina',
 			'BI' => 'Puruniti',
 			'BJ' => 'Penīna',
 			'BL' => 'Hato Pāteremi',
 			'BM' => 'Pāmura',
 			'BN' => 'Poronai',
 			'BO' => 'Poriwia',
 			'BQ' => 'Karapīana Hōrana',
 			'BR' => 'Parīhi',
 			'BS' => 'Pahama',
 			'BT' => 'Pūtana',
 			'BV' => 'Motu Pūwei',
 			'BW' => 'Poriwana',
 			'BY' => 'Pērara',
 			'BZ' => 'Perīhi',
 			'CA' => 'Kānata',
 			'CC' => 'Ngā Moutere Kokoko (Kirini)',
 			'CD' => 'Kōngo - Kinihāha',
 			'CD@alt=variant' => 'Kōngo',
 			'CF' => 'Te Whenua Tūhake o Āwherika Waenga',
 			'CG' => 'Kōngo - Pārawhe',
 			'CG@alt=variant' => 'Kōngo (Whenua Tūhake)',
 			'CH' => 'Huiterangi',
 			'CI' => 'Te Tai Rei',
 			'CK' => 'Kuki Airani',
 			'CL' => 'Hiri',
 			'CM' => 'Kamarūna',
 			'CN' => 'Haina',
 			'CO' => 'Koromōpia',
 			'CP' => 'Te Moutere Kiripetone',
 			'CR' => 'Koto Rīka',
 			'CU' => 'Kiupa',
 			'CV' => 'Te Kūrae Matomato',
 			'CW' => 'Kurahao',
 			'CX' => 'Te Moutere Kirihimete',
 			'CY' => 'Haipara',
 			'CZ' => 'Tiekia',
 			'CZ@alt=variant' => 'Te Whenua Tūhake o Tieke',
 			'DE' => 'Tiamana',
 			'DG' => 'Tieko Kāhia',
 			'DJ' => 'Tipūti',
 			'DK' => 'Tenemāka',
 			'DM' => 'Tominika',
 			'DO' => 'Te Whenua Tūhake o Tominika',
 			'DZ' => 'Aratiria',
 			'EA' => 'Hūta me Merera',
 			'EC' => 'Ekuatoa',
 			'EE' => 'Etōnia',
 			'EG' => 'Īhipa',
 			'EH' => 'Hahāra ki te Tonga',
 			'ER' => 'Eritēria',
 			'ES' => 'Peina',
 			'ET' => 'Etiopia',
 			'EU' => 'Te Uniana o Ūropi',
 			'EZ' => 'Te Rohe o Ūropi',
 			'FI' => 'Whinarana',
 			'FJ' => 'Whītī',
 			'FK' => 'Motu Whākarangi',
 			'FK@alt=variant' => 'Motu Whākana (Ira Māwina)',
 			'FM' => 'Mekanēhia',
 			'FO' => 'Motu Wharau',
 			'FR' => 'Wīwī',
 			'GA' => 'Kāpona',
 			'GB' => 'Te Hononga o Piritene',
 			'GD' => 'Kerenāta',
 			'GE' => 'Hōria',
 			'GF' => 'Kiāna Wīwī',
 			'GG' => 'Kōnihi',
 			'GH' => 'Kāna',
 			'GI' => 'Kāmaka',
 			'GL' => 'Whenuakāriki',
 			'GM' => 'Kamopia',
 			'GN' => 'Kini',
 			'GP' => 'Kuatarupa',
 			'GQ' => 'Kini Ekuatoria',
 			'GR' => 'Kirihi',
 			'GS' => 'Hōria ki te Tonga me ngā Motu Hanawiti ki te Tonga',
 			'GT' => 'Kuatamāra',
 			'GU' => 'Kuama',
 			'GW' => 'Kini-Pihao',
 			'GY' => 'Kaiana',
 			'HK' => 'Hongipua Haina',
 			'HK@alt=short' => 'Hongipua',
 			'HM' => 'Ngā Moutere Heriti me Makitānara',
 			'HN' => 'Honotura',
 			'HR' => 'Koroātia',
 			'HT' => 'Haiti',
 			'HU' => 'Hanekari',
 			'IC' => 'Motu Kanēre',
 			'ID' => 'Initonīhia',
 			'IE' => 'Airani',
 			'IL' => 'Iharaira',
 			'IM' => 'Te Moutere Mana',
 			'IN' => 'Inia',
 			'IO' => 'Te Rohe o te Moana Īniana Piritihi',
 			'IO@alt=chagos' => 'Te Rohe o te Moana Īnia Piritene',
 			'IQ' => 'Irāka',
 			'IR' => 'Irāna',
 			'IS' => 'Tiorangi',
 			'IT' => 'Itāria',
 			'JE' => 'Tōrehe',
 			'JM' => 'Hemeika',
 			'JO' => 'Hōrano',
 			'JP' => 'Hapani',
 			'KE' => 'Kenia',
 			'KG' => 'Kikitānga',
 			'KH' => 'Kamapōtia',
 			'KI' => 'Kiripati',
 			'KM' => 'Komoro',
 			'KN' => 'Hato Kiti me Newhi',
 			'KP' => 'Kōrea ki te Raki',
 			'KR' => 'Kōrea ki te Tonga',
 			'KW' => 'Kūweiti',
 			'KY' => 'Ngā Motu Keimana',
 			'KZ' => 'Katatānga',
 			'LA' => 'Rāoho',
 			'LB' => 'Repanona',
 			'LC' => 'Hato Ruhia',
 			'LI' => 'Rīkenetaina',
 			'LK' => 'Hiri Rānaka',
 			'LR' => 'Raipiria',
 			'LS' => 'Teroto',
 			'LT' => 'Rituānia',
 			'LU' => 'Rakapuō',
 			'LV' => 'Rāwhia',
 			'LY' => 'Ripia',
 			'MA' => 'Moroko',
 			'MC' => 'Monāko',
 			'MD' => 'Morotawa',
 			'ME' => 'Maungakororiko',
 			'MF' => 'Hato Mātene',
 			'MG' => 'Matakāhika',
 			'MH' => 'Ngā Motu Māhara',
 			'MK' => 'Makerōnia ki te Raki',
 			'ML' => 'Māri',
 			'MM' => 'Pēma',
 			'MN' => 'Mongōria',
 			'MO' => 'Makau Haina',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Ngā Motu Mariana ki te Raki',
 			'MQ' => 'Mātiniki',
 			'MR' => 'Mauritānia',
 			'MS' => 'Monoterā',
 			'MT' => 'Mārata',
 			'MU' => 'Marihi',
 			'MV' => 'Māratiri',
 			'MW' => 'Marāwi',
 			'MX' => 'Mēhiko',
 			'MY' => 'Mareia',
 			'MZ' => 'Mohapiki',
 			'NA' => 'Namipia',
 			'NC' => 'Whenua Kanaki',
 			'NE' => 'Ngāika',
 			'NF' => 'Te Moutere Nōpoke',
 			'NG' => 'Ngāitiria',
 			'NI' => 'Nikarāhua',
 			'NL' => 'Hōrana',
 			'NO' => 'Nōwei',
 			'NP' => 'Nepōra',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Aotearoa',
 			'OM' => 'Ōmana',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Poronēhia Wīwī',
 			'PG' => 'Papua Nūkini',
 			'PH' => 'Piripīni',
 			'PK' => 'Pakitāne',
 			'PL' => 'Pōrana',
 			'PM' => 'Hato Piere & Mikerona',
 			'PN' => 'Pitikeina',
 			'PR' => 'Peta Riko',
 			'PS' => 'Ngā Rohe o Parihitini',
 			'PS@alt=short' => 'Parihitini',
 			'PT' => 'Potukara',
 			'PW' => 'Pārau',
 			'PY' => 'Parakai',
 			'QA' => 'Katā',
 			'QO' => 'Ngā Moutere-a-Kiwa o Waho atu',
 			'RE' => 'Reūnio',
 			'RO' => 'Romeinia',
 			'RS' => 'Hirupia',
 			'RU' => 'Rūhia',
 			'RW' => 'Rāwana',
 			'SA' => 'Hauri Arāpia',
 			'SB' => 'Ngā Motu Horomona',
 			'SC' => 'Heikere',
 			'SD' => 'Hūtāne',
 			'SE' => 'Huitene',
 			'SG' => 'Hingapoa',
 			'SH' => 'Hato Hērena',
 			'SI' => 'Horowinia',
 			'SJ' => 'Heopara me Iana Maiana',
 			'SK' => 'Horowākia',
 			'SL' => 'Te Araone',
 			'SM' => 'Hana Marino',
 			'SN' => 'Henekara',
 			'SO' => 'Hūmārie',
 			'SR' => 'Huriname',
 			'SS' => 'Hūtāne ki te Tonga',
 			'ST' => 'Hato Tomei me Pirinipei',
 			'SV' => 'Whakaora',
 			'SX' => 'Hiti Mātene',
 			'SY' => 'Hiria',
 			'SZ' => 'Ehiwatini',
 			'SZ@alt=variant' => 'Warerangi',
 			'TA' => 'Tiritana da Kunia',
 			'TC' => 'Koru-Kākoa',
 			'TD' => 'Kāta',
 			'TF' => 'Ngā Rohe o Wīwī ki te Tonga',
 			'TG' => 'Toko',
 			'TH' => 'Tairanga',
 			'TJ' => 'Takiritānga',
 			'TK' => 'Tokerau',
 			'TL' => 'Tīmoa ki te Rāwhiti',
 			'TM' => 'Tukumanatānga',
 			'TN' => 'Tūnihia',
 			'TO' => 'Tonga',
 			'TR' => 'Tākei',
 			'TT' => 'Tirinaki Tōpako',
 			'TV' => 'Tūwaru',
 			'TW' => 'Taiwana',
 			'TZ' => 'Tānahia',
 			'UA' => 'Ukareinga',
 			'UG' => 'Ukānga',
 			'UM' => 'Ngā Moutere Amerika o Waho',
 			'UN' => 'Te Rūnanga Whakakotahi i ngā Iwi o te Ao',
 			'US' => 'Hononga o Amerika',
 			'UY' => 'Urukoi',
 			'UZ' => 'Uhipeketāne',
 			'VA' => 'Te Poho-o-Pita',
 			'VC' => 'Hato Wēneti me Keretīni',
 			'VE' => 'Penehūera',
 			'VG' => 'Ngā Moutere Puhi Piritene',
 			'VI' => 'Ngā Moutere Puhi Amerika',
 			'VN' => 'Whitināmu',
 			'VU' => 'Whenuatū',
 			'WF' => 'Warihi me Whutuna',
 			'WS' => 'Hāmoa',
 			'XA' => 'Mita kikoika',
 			'XB' => 'Piri Kikoika',
 			'XK' => 'Kōhoro',
 			'YE' => 'Īmene',
 			'YT' => 'Māiota',
 			'ZA' => 'Āwherika ki te Tonga',
 			'ZM' => 'Tāmipia',
 			'ZW' => 'Timuwawe',
 			'ZZ' => 'Rohe Tē Mōhiotia',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Maramataka',
 			'cf' => 'Hōputu Moni',
 			'collation' => 'Raupapa Kōmaka',
 			'currency' => 'Momo Moni',
 			'hc' => 'Hurihanga Haora (12, 24 rānei)',
 			'lb' => 'Hātuhi Whati Rārangi',
 			'ms' => 'Pūnaha Inenga',
 			'numbers' => 'Tau',

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
 				'buddhist' => q{Maramataka Puta},
 				'chinese' => q{Maramataka Haina},
 				'coptic' => q{Maramataka Kopitika},
 				'dangi' => q{Maramataka Tangi},
 				'ethiopic' => q{Maramataka Etiopia},
 				'ethiopic-amete-alem' => q{Maramataka Etiopia Amete Arema},
 				'gregorian' => q{Maramataka Pākehā},
 				'hebrew' => q{Maramataka Hīperu},
 				'islamic' => q{Maramataka Hitiuri},
 				'islamic-civil' => q{Maramataka Hitiuri (tūtohi, wā o naiānei)},
 				'islamic-umalqura' => q{Maramataka Hitiuri (Uma ara Kura)},
 				'iso8601' => q{Maramataka ISO-8601},
 				'japanese' => q{Maramataka Hapanihi},
 				'persian' => q{Maramataka Pāhia},
 				'roc' => q{Maramataka Minguo},
 			},
 			'cf' => {
 				'account' => q{Hōputu Moni Mahi Kaute},
 				'standard' => q{Hōputu Moni Arowhānui},
 			},
 			'collation' => {
 				'ducet' => q{Raupapa Kōmaka Unicode Taunoa},
 				'search' => q{Rapunga Arowhānui},
 				'standard' => q{Raupapa Kōmaka Arowhānui},
 			},
 			'hc' => {
 				'h11' => q{Pūnaha Haora 12 (0–11)},
 				'h12' => q{Pūnaha Haora 12 (1–12)},
 				'h23' => q{Pūnaha Haora 24 (0–23)},
 				'h24' => q{Pūnaha Haora 24 (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Hātuhi Whati Rārangi Tangatanga},
 				'normal' => q{Hātuhi Whati Rārangi Taunoa},
 				'strict' => q{Hātuhi Whati Rārangi Pākaha},
 			},
 			'ms' => {
 				'metric' => q{Pūnaha Ngahuru},
 				'uksystem' => q{Pūnaha Inenga Emepaea},
 				'ussystem' => q{Pūnenga Inenga Amerika},
 			},
 			'numbers' => {
 				'arab' => q{Mati Arapī-Īnia},
 				'arabext' => q{Mati Arapī-Īnia Whakaroa},
 				'armn' => q{Tohutau Āmenia},
 				'armnlow' => q{Tohutau Āmenia Pūriki},
 				'beng' => q{Mati Pākara},
 				'cakm' => q{Mati Tiakama},
 				'deva' => q{Mati Tewanakari},
 				'ethi' => q{Tohutau Etiopia},
 				'fullwide' => q{Mati Whānui Rawa},
 				'geor' => q{Tohutau Hōriana},
 				'grek' => q{Tohutau Kariki},
 				'greklow' => q{Tohutau Kariki Pūriki},
 				'gujr' => q{Mati Kuharati},
 				'guru' => q{Mati Kuramuki},
 				'hanidec' => q{Tohutau Haina ā-ira},
 				'hans' => q{Tohutau Haina Māmā},
 				'hansfin' => q{Tohutau Ahumoni Haina Māmā},
 				'hant' => q{Tohutau Haina Tukuiho},
 				'hantfin' => q{Tohutau Ahumoni Haina Tukuiho},
 				'hebr' => q{Tohutau Hīperu},
 				'java' => q{Mati Tiawha},
 				'jpan' => q{Tohutau Hapanihi},
 				'jpanfin' => q{Tohutau Ahumoni Hapanihi},
 				'khmr' => q{Mati Kimēra},
 				'knda' => q{Mati Kanāta},
 				'laoo' => q{Mati Rao},
 				'latn' => q{Ngā Mati Pākehā},
 				'mlym' => q{Mati Maraiarama},
 				'mtei' => q{Mati Mētei Maieka},
 				'mymr' => q{Mati Pēma},
 				'olck' => q{Mati Oro Tieki},
 				'orya' => q{Mati Oria},
 				'roman' => q{Tohutau Rōmana},
 				'romanlow' => q{Tohutau Rōmana Pūriki},
 				'taml' => q{Tohutau Tamira Tukuiho},
 				'tamldec' => q{Mati Tamira},
 				'telu' => q{Mati Teruku},
 				'thai' => q{Mati Tai},
 				'tibt' => q{Mati Tīpete},
 				'vaii' => q{Mati Wai},
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
			'metric' => q{Ngahuru},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Reo: {0}',
 			'script' => 'Momotuhi: {0}',
 			'region' => 'Rohe: {0}',

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
			auxiliary => qr{[b c d f g j l q s v x y z]},
			index => ['A', 'E', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'R', 'T', 'U', 'W'],
			main => qr{[aā eē h iī k m n {ng} oō p r t uū w {wh}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'E', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'R', 'T', 'U', 'W'], };
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
						'name' => q(kāpehu maha),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kāpehu maha),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} eka),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} eka),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} heketea),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} heketea),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(mitarau pūrua),
						'other' => q({0} mitarau pūrua),
						'per' => q({0} ki te mitarau pūrua),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(mitarau pūrua),
						'other' => q({0} mitarau pūrua),
						'per' => q({0} ki te mitarau pūrua),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0} pūtu pūrua),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0} pūtu pūrua),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(īnihi pūrua),
						'other' => q({0} īnihi pūrua),
						'per' => q({0} ki te īnihi pūrua),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(īnihi pūrua),
						'other' => q({0} īnihi pūrua),
						'per' => q({0} ki te īnihi pūrua),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(manomita pūrua),
						'other' => q({0} ki te manomita pūrua),
						'per' => q({0} ki te manomita pūrua),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(manomita pūrua),
						'other' => q({0} ki te manomita pūrua),
						'per' => q({0} ki te manomita pūrua),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'other' => q({0} mita pūrua),
						'per' => q({0} ki te mita pūrua),
					},
					# Core Unit Identifier
					'square-meter' => {
						'other' => q({0} mita pūrua),
						'per' => q({0} ki te mita pūrua),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0} māero pūrua),
						'per' => q({0} ki te māero pūrua),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0} māero pūrua),
						'per' => q({0} ki te māero pūrua),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'other' => q({0} iari pūrua),
					},
					# Core Unit Identifier
					'square-yard' => {
						'other' => q({0} iari pūrua),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} rāwhiti),
						'north' => q({0} raki),
						'south' => q({0} tonga),
						'west' => q({0} uru),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} rāwhiti),
						'north' => q({0} raki),
						'south' => q({0} tonga),
						'west' => q({0} uru),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(rautau),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(rautau),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} i te rā),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} i te rā),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ngahurutau),
						'other' => q({0} ngahurutau),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ngahurutau),
						'other' => q({0} ngahurutau),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} haora),
						'per' => q({0} i te haora),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} haora),
						'per' => q({0} i te haora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(hēkonamiriona),
						'other' => q({0} hēkonamiriona),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(hēkonamiriona),
						'other' => q({0} hēkonamiriona),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0} hēkonamano),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0} hēkonamano),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(meneti),
						'other' => q({0} meneti),
						'per' => q({0} i te meneti),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(meneti),
						'other' => q({0} meneti),
						'per' => q({0} i te meneti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} marama),
						'per' => q({0} i te marama),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} marama),
						'per' => q({0} i te marama),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'other' => q({0} nanohēkona),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'other' => q({0} nanohēkona),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(hauwhā),
						'other' => q({0} hauwhā),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(hauwhā),
						'other' => q({0} hauwhā),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(hēkona),
						'other' => q({0} hēkona),
						'per' => q({0} i te hēkona),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(hēkona),
						'other' => q({0} hēkona),
						'per' => q({0} i te hēkona),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} wiki),
						'per' => q({0} i te wiki),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} wiki),
						'per' => q({0} i te wiki),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} i te tau),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} i te tau),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tātai tuhituhi),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tātai tuhituhi),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0} tongiiti),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0} tongiiti),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(tongiiti ki te mitarau),
						'other' => q({0} tongiiti ki te mitarau),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(tongiiti ki te mitarau),
						'other' => q({0} tongiiti ki te mitarau),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(tongiiti ki te īnihi),
						'other' => q({0} tongiiti ki te īnihi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(tongiiti ki te īnihi),
						'other' => q({0} tongiiti ki te īnihi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(waeine mātai arorangi),
						'other' => q({0} waeine mātai arorangi),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(waeine mātai arorangi),
						'other' => q({0} waeine mātai arorangi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(mitarau),
						'other' => q({0} mitarau),
						'per' => q({0} ki te mitarau),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(mitarau),
						'other' => q({0} mitarau),
						'per' => q({0} ki te mitarau),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(mitatekau),
						'other' => q({0} mitatekau),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(mitatekau),
						'other' => q({0} mitatekau),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(pūtoro o te ao),
						'other' => q({0} pūtoro o te ao),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(pūtoro o te ao),
						'other' => q({0} pūtoro o te ao),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0}ki te pūtu),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0}ki te pūtu),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0} īnihi),
						'per' => q({0} ki te īnihi),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0} īnihi),
						'per' => q({0} ki te īnihi),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(manomita),
						'other' => q({0} manomita),
						'per' => q({0} ki te manomita),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(manomita),
						'other' => q({0} manomita),
						'per' => q({0} ki te manomita),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mita),
						'other' => q({0} mita),
						'per' => q({0} ki te mita),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mita),
						'other' => q({0} mita),
						'per' => q({0} ki te mita),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'other' => q({0} mitamiriona),
					},
					# Core Unit Identifier
					'micrometer' => {
						'other' => q({0} mitamiriona),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mitamano),
						'other' => q({0} mitamano),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mitamano),
						'other' => q({0} mitamano),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(mitanano),
						'other' => q({0} mitanano),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(mitanano),
						'other' => q({0} mitanano),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(māero moana),
						'other' => q({0} māero moana),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(māero moana),
						'other' => q({0} māero moana),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(mitapiko),
						'other' => q({0} mitapiko),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(mitapiko),
						'other' => q({0} mitapiko),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ritarau),
						'other' => q({0} ritarau),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ritarau),
						'other' => q({0} ritarau),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(mitarau pūtoru),
						'other' => q({0} mitarau pūtoru),
						'per' => q({0} ki te mitarau pūtoru),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(mitarau pūtoru),
						'other' => q({0} mitarau pūtoru),
						'per' => q({0} ki te mitarau pūtoru),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pūtu pūtoru),
						'other' => q({0} pūtu pūtoru),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pūtu pūtoru),
						'other' => q({0} pūtu pūtoru),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(īnihi pūtoru),
						'other' => q({0} īnihi pūtoru),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(īnihi pūtoru),
						'other' => q({0} īnihi pūtoru),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(manomita pūtoru),
						'other' => q({0} manomita pūtoru),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(manomita pūtoru),
						'other' => q({0} manomita pūtoru),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mita pūtoru),
						'other' => q({0} mita pūtoru),
						'per' => q({0} ki te mita pūtoru),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mita pūtoru),
						'other' => q({0} mita pūtoru),
						'per' => q({0} ki te mita pūtoru),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(māero pūtoru),
						'other' => q({0} māero pūtoru),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(māero pūtoru),
						'other' => q({0} māero pūtoru),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iari pūtoru),
						'other' => q({0} iari pūtoru),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iari pūtoru),
						'other' => q({0} iari pūtoru),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} kapu),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} kapu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(aunihi kūtere),
						'other' => q({0} aunihi kūtere),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(aunihi kūtere),
						'other' => q({0} aunihi kūtere),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(aunihi kūtere emepaea),
						'other' => q({0} aunihi kūtere emepaea),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(aunihi kūtere emepaea),
						'other' => q({0} aunihi kūtere emepaea),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(kārani emepaea),
						'per' => q({0} ki te kārani emepaea),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(kārani emepaea),
						'per' => q({0} ki te kārani emepaea),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q({0} ki te rita),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q({0} ki te rita),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(rita miriona),
						'other' => q({0} rita miriona),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(rita miriona),
						'other' => q({0} rita miriona),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ritamano),
						'other' => q({0} ritamano),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ritamano),
						'other' => q({0} ritamano),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0} paina),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} paina),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kuata),
						'other' => q({0} kuata),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kuata),
						'other' => q({0} kuata),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kuata emepaea),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kuata emepaea),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(hēkm),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(hēkm),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nhēk),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nhēk),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0}/kārani),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0}/kārani),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(kāpehu),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kāpehu),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(eka),
						'other' => q({0} ek),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(eka),
						'other' => q({0} ek),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(heketea),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(heketea),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pūtu pūrua),
						'other' => q({0} pūtu²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pūtu pūrua),
						'other' => q({0} pūtu²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(īnihi²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(īnihi²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mita pūrua),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mita pūrua),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(māero pūrua),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(māero pūrua),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iari pūrua),
						'other' => q({0} iari²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iari pūrua),
						'other' => q({0} iari²),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Rā),
						'north' => q({0} Ra),
						'south' => q({0} T),
						'west' => q({0} U),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Rā),
						'north' => q({0} Ra),
						'south' => q({0} T),
						'west' => q({0} U),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(r),
						'other' => q({0} r),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(r),
						'other' => q({0} r),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(rā),
						'other' => q({0} rā),
						'per' => q({0}/rā),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(rā),
						'other' => q({0} rā),
						'per' => q({0}/rā),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(nga),
						'other' => q({0} nga),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(nga),
						'other' => q({0} nga),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(haora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(haora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μhēk),
						'other' => q({0} μhēk),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μhēk),
						'other' => q({0} μhēk),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(hēkonamano),
						'other' => q({0} hm),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(hēkonamano),
						'other' => q({0} hm),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(men),
						'other' => q({0} men),
						'per' => q({0}/men),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(men),
						'other' => q({0} men),
						'per' => q({0}/men),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(marama),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(marama),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanohēkona),
						'other' => q({0} nhēk),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanohēkona),
						'other' => q({0} nhēk),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(hwh),
						'other' => q({0} hwh),
						'per' => q({0}/hwh),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(hwh),
						'other' => q({0} hwh),
						'per' => q({0}/hwh),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(hēk),
						'other' => q({0} hēk),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(hēk),
						'other' => q({0} hēk),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(wiki),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(wiki),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(tau),
						'other' => q({0} tau),
						'per' => q({0}/t),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(tau),
						'other' => q({0} tau),
						'per' => q({0}/t),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(miriona tongiiti),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(miriona tongiiti),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(tongiiti),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(tongiiti),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(mārō),
						'other' => q({0} mārō),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(mārō),
						'other' => q({0} mārō),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pūtu),
						'other' => q({0} pūtu),
						'per' => q({0}/pūtu),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pūtu),
						'other' => q({0} pūtu),
						'per' => q({0}/pūtu),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(īnihi),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(īnihi),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(tau aho),
						'other' => q({0} tau aho),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(tau aho),
						'other' => q({0} tau aho),
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
					'length-micrometer' => {
						'name' => q(mitamiriona),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mitamiriona),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(māero),
						'other' => q({0} māero),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(māero),
						'other' => q({0} māero),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(pūtoro kōmaru),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(pūtoro kōmaru),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iari),
						'other' => q({0} iari),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iari),
						'other' => q({0} iari),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(kāho),
						'other' => q({0} kāho),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(kāho),
						'other' => q({0} kāho),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pūtu³),
						'other' => q({0} pūtu³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pūtu³),
						'other' => q({0} pūtu³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(īnihi³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(īnihi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iari³),
						'other' => q({0} iari³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iari³),
						'other' => q({0} iari³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kapu),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kapu),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(koko pūrini),
						'other' => q({0} koko pūrini),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(koko pūrini),
						'other' => q({0} koko pūrini),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(pata),
						'other' => q({0} pata),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(pata),
						'other' => q({0} pata),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(kārani),
						'other' => q({0} kārani),
						'per' => q({0} ki te kārani),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(kārani),
						'other' => q({0} kārani),
						'per' => q({0} ki te kārani),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0} kārani emepaea),
						'per' => q({0}/kārani emepaea),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0} kārani emepaea),
						'per' => q({0}/kārani emepaea),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(rita),
						'other' => q({0} rita),
						'per' => q({0}/rita),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(rita),
						'other' => q({0} rita),
						'per' => q({0}/rita),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(kini),
						'other' => q({0} kini),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(kini),
						'other' => q({0} kini),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(paina),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(paina),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'other' => q({0} kuata emepaea),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'other' => q({0} kuata emepaea),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(kokonui),
						'other' => q({0} kokonui),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kokonui),
						'other' => q({0} kokonui),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kokoiti),
						'other' => q({0} kokoiti),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kokoiti),
						'other' => q({0} kokoiti),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:āe|ā|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:kāo|k|no|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(Dirham UAE),
				'other' => q(dirham UAE),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Awhekenetāna),
				'other' => q(afghani Awhekenetāna),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Arapeinia),
				'other' => q(leke Arapeinia),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Āmenia),
				'other' => q(dram Āmenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder Anatiri Hōrana),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Anakora),
				'other' => q(kwanza Anakora),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Āketina),
				'other' => q(peso Āketina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Tāra Ahitereiria),
				'other' => q(tāra Ahitereiria),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Arūpa),
				'other' => q(florin Arūpa),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Atepaihānia),
				'other' => q(manat Atepaihānia),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark Pōngia-Herekōwini takahuri),
				'other' => q(mark Pōngia-Herekōwini takahuri),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Tāra Papatohe),
				'other' => q(tāra Papatohe),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Pākaratēhi),
				'other' => q(taka Pākaratēhi),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Leva Purukāria),
				'other' => q(leva Purukāria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Pāreina),
				'other' => q(dinar Pāreina),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc Puruniti),
				'other' => q(franc Puruniti),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Tāra Pāmura),
				'other' => q(tāra Pāmura),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Tāra Poronai),
				'other' => q(tāra Poronai),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Poriwia),
				'other' => q(boliviano Poriwia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Parahi),
				'other' => q(real Parahi),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Tāra Pahama),
				'other' => q(tāra Pahama),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Pūtana),
				'other' => q(ngultrum Pūtana),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Poriwana),
				'other' => q(pula Poriwana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ruble Pērara),
				'other' => q(ruble Pērara),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Tāra Pērihi),
				'other' => q(tāra Pērihi),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Tāra Kānata),
				'other' => q(tāra Kānata),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Kōngo),
				'other' => q(franc Kōngo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Huiterangi),
				'other' => q(franc Huiterangi),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Hiri),
				'other' => q(peso Hiri),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Haina \(ki waho\)),
				'other' => q(yuan Haina \(ki waho\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Haina),
				'other' => q(yuan Haina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Koromōpia),
				'other' => q(peso Koromōpia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon Koto Rika),
				'other' => q(colon Koto Rika),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Kiupa takahuri),
				'other' => q(peso Kiupa takahuri),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Kiupa),
				'other' => q(peso Kiupa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Kūrae Matomato),
				'other' => q(escudo Kūrae Matomato),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Tieke),
				'other' => q(koruna Tieke),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Tepūti),
				'other' => q(franc Tepūti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kroner Tenemāka),
				'other' => q(kroner Tenemāka),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Tominika),
				'other' => q(peso Tominika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Aratiria),
				'other' => q(dinar Aratiria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pāuna Īhipa),
				'other' => q(pāuna Īhipa),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eriterea),
				'other' => q(nakfa Eriterea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr Etiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Tāra Whītī),
				'other' => q(tāra Whītī),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pāuna Whākana),
				'other' => q(pāuna Whākana),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pāuna Piritene),
				'other' => q(pāuna Piritene),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Hōria),
				'other' => q(lari Hōria),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Kāna),
				'other' => q(cedi Kāna),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pāuna Kāmaka),
				'other' => q(pāuna Kāmaka),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Kamopia),
				'other' => q(dalasi Kamopia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc Kini),
				'other' => q(franc Kini),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Kuatamāra),
				'other' => q(quetzal Kuatamāra),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Tāra Kaiana),
				'other' => q(tāra Kaiana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Tāra Hongipua),
				'other' => q(tāra Hongipua),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Honotura),
				'other' => q(lempira Honotura),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Koroātia),
				'other' => q(kuna Koroātia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
				'other' => q(gourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint Hanekari),
				'other' => q(forint Hanekari),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah Initonīhia),
				'other' => q(rupiah Initonīhia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Shekel Hou Iharaira),
				'other' => q(shekel hou Iharaira),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupī Iniana),
				'other' => q(rupī Iniana),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Irāka),
				'other' => q(dinar Irāka),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Irāna),
				'other' => q(rial Irāna),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Kronur Tiorangi),
				'other' => q(kronur Tiorangi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Tāra Hemeika),
				'other' => q(tāra Hemeika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Hōrano),
				'other' => q(dinar Hōrano),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen Hapanihi),
				'other' => q(yen Hapanihi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Hereni Kenia),
				'other' => q(hereni Kenia),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kikitānga),
				'other' => q(som Kikitānga),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Kamapōtia),
				'other' => q(riel Kamapōtia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Komoro),
				'other' => q(franc Komoro),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Kōrea ki te Raki),
				'other' => q(won Kōrea ki te Raki),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Kōrea ki te Tonga),
				'other' => q(won Kōrea ki te Tonga),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kūweiti),
				'other' => q(dinar Kūweiti),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Tāra Kāmana),
				'other' => q(tāra Kāmana),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Katatānga),
				'other' => q(tenge Katatānga),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip Rāoho),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pāuna Repanona),
				'other' => q(pāuna Repanona),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee Hiri Ranaka),
				'other' => q(rupee Hiri Ranaka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Tāra Raipiria),
				'other' => q(tāra Raipiria),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Teroto),
				'other' => q(loti Teroto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Ripia),
				'other' => q(dinar Ripia),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Moroko),
				'other' => q(dirham Moroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Morotawa),
				'other' => q(lei Morotawa),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Matakāhika),
				'other' => q(ariary Matakāhika),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Makerōnia),
				'other' => q(denari Makerōnia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Pēma),
				'other' => q(kyat Pēma),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik Mongōria),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Makau),
				'other' => q(pataca Makau),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'other' => q(ouguiya Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Marihi),
				'other' => q(rupee Marihi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Māratiri),
				'other' => q(rufiyaa Māratiri),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Marāwi),
				'other' => q(kwacha Marāwi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Mēhiko),
				'other' => q(peso Mēhiko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Mareia),
				'other' => q(ringgit Mareia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mohapiki),
				'other' => q(metical Mohapiki),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Tāra Namipia),
				'other' => q(tāra Namipia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Ngāitīria),
				'other' => q(naira Ngāitīria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba Nikarāhua),
				'other' => q(cordoba Nikarāhua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Kroner Nōwei),
				'other' => q(kroner Nōwei),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Nepōra),
				'other' => q(rupee Nepōra),
			},
		},
		'NZD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Tāra o Aotearoa),
				'other' => q(tāra o Aotearoa),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Ōmana),
				'other' => q(rial Ōmana),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
				'other' => q(balboa Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sole Peru),
				'other' => q(sole Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua Nūkini),
				'other' => q(kina Papua Nūkini),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Peso Piripīni),
				'other' => q(peso Piripīni),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee Pakitāne),
				'other' => q(rupee Pakitāne),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty Pōrana),
				'other' => q(zloty Pōrana),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Parakai),
				'other' => q(guarani Parakai),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riyal Katā),
				'other' => q(riyal Katā),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Romeinia),
				'other' => q(lei Romeinia),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Hirupia),
				'other' => q(dinar Hirupia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rūpera Ruhiana),
				'other' => q(rūpera Ruhiana),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rāwana),
				'other' => q(franc Rāwana),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Hauri),
				'other' => q(riyal Hauri),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Tāra Moutere Horomona),
				'other' => q(tāra Moutere Horomona),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupee Heikere),
				'other' => q(rupee Heikere),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pāuna Hūtāne),
				'other' => q(pāuna Hūtāne),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Kronor Huitene),
				'other' => q(kronor Huitene),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Tāra Hingapoa),
				'other' => q(tāra Hingapoa),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pāuna Hato Herena),
				'other' => q(pāuna Hato Herena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Araone),
				'other' => q(leone Araone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Araon \(1964—2022\)e),
				'other' => q(leone Araone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Hereni Hūmārie),
				'other' => q(hereni Hūmārie),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Tāra Huriname),
				'other' => q(tāra Huriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pāuna Hūtāne Tonga),
				'other' => q(pāuna Hūtāne Tonga),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Hao Tome me Pirinihipi),
				'other' => q(dobra Hao Tome me Pirinihipi),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pāuna Hiria),
				'other' => q(pāuna Hiria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Warerangi),
				'other' => q(emalangeni Warerangi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht Tairanga),
				'other' => q(baht Tairanga),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Takiritānga),
				'other' => q(somoni Takiritānga),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Tukumanatānga),
				'other' => q(manat Tukumanatānga),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tūnihia),
				'other' => q(dinar Tūnihia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Pa’anga Tonga),
				'other' => q(pa’anga Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Tākei),
				'other' => q(lira Tākei),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Tāra Tirinaki Tōpako),
				'other' => q(tāra Tirinaki Tōpako),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Tāra Taiwana Hou),
				'other' => q(tāra Taiwana hou),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Hereni Tānahia),
				'other' => q(hereni Tānahia),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ukareinga),
				'other' => q(hryvnia Ukareinga),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(hereni Ukānga),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Tāra US),
				'other' => q(tāra US),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Urukoi),
				'other' => q(peso Urukoi),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Uhipeketāne),
				'other' => q(som Uhipeketāne),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolivar Penehūera),
				'other' => q(bolivar Penehūera),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Whitināmu),
				'other' => q(dong Whitināmu),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Whenuatū),
				'other' => q(vatu Whenuatū),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Hāmoa),
				'other' => q(tala Hāmoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franc CFA Āwherika Waenga),
				'other' => q(franc CFA Āwherika Waenga),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Tāra Karapīana Rāwhiti),
				'other' => q(tāra Karapīana Rāwhiti),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franc CFA Āwherika ki te Uru),
				'other' => q(franc CFA Āwherika ki te Uru),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
				'other' => q(franc CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Moni Tē Mōhiotia),
				'other' => q(\(moni tē mōhiotia\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Īmene),
				'other' => q(rial Īmene),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Āwherika ki te Tonga),
				'other' => q(rand Āwherika ki te Tonga),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha Tāmipia),
				'other' => q(kwacha Tāmipia),
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
							'Hān',
							'Pēp',
							'Māe',
							'Āpe',
							'Mei',
							'Hun',
							'Hūr',
							'Āku',
							'Hep',
							'Oke',
							'Noe',
							'Tīh'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Hānuere',
							'Pēpuere',
							'Māehe',
							'Āpereira',
							'Mei',
							'Hune',
							'Hūrae',
							'Ākuhata',
							'Hepetema',
							'Oketopa',
							'Noema',
							'Tīhema'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'H',
							'P',
							'M',
							'Ā',
							'M',
							'H',
							'H',
							'Ā',
							'H',
							'O',
							'N',
							'T'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Hānuere',
							'Pēpuere',
							'Māehe',
							'Āperira',
							'Mei',
							'Hune',
							'Hūrae',
							'Ākuhata',
							'Hepetema',
							'Oketopa',
							'Noema',
							'Tīhema'
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
						mon => 'Man',
						tue => 'Tūr',
						wed => 'Wen',
						thu => 'Tāi',
						fri => 'Par',
						sat => 'Rāh',
						sun => 'Rāt'
					},
					short => {
						mon => 'Man',
						tue => 'Tū',
						wed => 'Wen',
						thu => 'Tāi',
						fri => 'Par',
						sat => 'Rāh',
						sun => 'Rāt'
					},
					wide => {
						mon => 'Mane',
						tue => 'Tūrei',
						wed => 'Wenerei',
						thu => 'Tāite',
						fri => 'Paraire',
						sat => 'Rāhoroi',
						sun => 'Rātapu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'P',
						sat => 'Rh',
						sun => 'Rt'
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
					abbreviated => {0 => 'HW1',
						1 => 'HW2',
						2 => 'HW3',
						3 => 'HW4'
					},
					wide => {0 => 'Hauwhā tuatahi',
						1 => 'Hauwhā tuarua',
						2 => 'Hauwhā tuatoru',
						3 => 'Hauwhā tuawhā'
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
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd-MM-y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
		'gregorian' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMM},
			MMMMW => q{'wiki' W 'o' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'wiki' w 'o' Y},
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
			fallback => '{0} ki te {1}',
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			fallback => '{0} ki te {1}',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Wā),
		regionFormat => q({0} Wā Awatea),
		regionFormat => q({0} Wā Arowhānui),
		'Afghanistan' => {
			long => {
				'standard' => q#Wā Awhekenetāna#,
			},
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Ngāiropi#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tiriporī#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tūnīhi#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Wā o Te Puku o Āwherika#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Wā o Āwherika ki te rāwhiti#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Wā Arowhānui o Āwherika ki te tonga#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Wā Raumati o Āwherika ki te uru#,
				'generic' => q#Wā o Āwherika ki te uru#,
				'standard' => q#Wā Arowhānui o Āwerika ki te uru#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Wā Awatea Alaska#,
				'generic' => q#Wā Alaska#,
				'standard' => q#Wā Arowhānui Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Wā Amahona Raumati#,
				'generic' => q#Wā Amahona#,
				'standard' => q#Wā Amahona Arowhānui#,
			},
		},
		'America/Antigua' => {
			exemplarCity => q#Te Motu Nehe#,
		},
		'America/Barbados' => {
			exemplarCity => q#Papatohe#,
		},
		'America/Belize' => {
			exemplarCity => q#Pērihi#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kemureti Pei#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kāmana#,
		},
		'America/Chicago' => {
			exemplarCity => q#Hikāko#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Koto Rika#,
		},
		'America/Dominica' => {
			exemplarCity => q#Tominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Whakaora#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Kuihi Pei#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Tākoru Nui#,
		},
		'America/Grenada' => {
			exemplarCity => q#Kerenata#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Kuatamāra#,
		},
		'America/Havana' => {
			exemplarCity => q#Hawhāna#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Hemeika#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Ngā Anahera#,
		},
		'America/Martinique' => {
			exemplarCity => q#Mātiniki#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mēhiko Tāonenui#,
		},
		'America/New_York' => {
			exemplarCity => q#Te Āporo Nui#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Peta Riko#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Hato Hone#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Hato Ruihia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Hato Tamati#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Hato Wēneti#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Whaitiri Pei#,
		},
		'America/Toronto' => {
			exemplarCity => q#Tāroto#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Te Whanga-a-Kiwa#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Wā Awatea Waenga#,
				'generic' => q#Wā Waenga#,
				'standard' => q#Wā Arowhānui Waenga#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Wā Awatea Rāwhiti#,
				'generic' => q#Wā Rāwhiti#,
				'standard' => q#Wā Arowhānui Rāwhiti#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Wā Awatea Maunga#,
				'generic' => q#Wā Maunga#,
				'standard' => q#Wā Arowhānui Maunga#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Wā Awatea Kiwa#,
				'generic' => q#Wā Kiwa#,
				'standard' => q#Wā Arowhānui Kiwa#,
			},
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Rēweti#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makoare#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Wā Āpia Awatea#,
				'generic' => q#Wā Āpia#,
				'standard' => q#Wā Āpia Arowhānui#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Wā Arāpia Awatea#,
				'generic' => q#Wā Arāpia#,
				'standard' => q#Wā Arāpia Arowhānui#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Wā Āketina Raumati#,
				'generic' => q#Wā Āketina#,
				'standard' => q#Wā Āketina Arowhānui#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Wā Āketina ki te uru Raumati#,
				'generic' => q#Wā Āketina ki te uru#,
				'standard' => q#Wā Āketina ki te uru Arowhānui#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Wā Āmenia Raumati#,
				'generic' => q#Wā Āmenia#,
				'standard' => q#Wā Āmenia Arowhānui#,
			},
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Pākatata#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Pāreina#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Pangakoko#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Poronai#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Tupae#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Kāha#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongipua#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Tiakāta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Hiruhārama#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katamarū#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuara Rūpa#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kūweiti#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manira#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Penoma Pena#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katā#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riata#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Houra#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Hangahai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Hingapoa#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Terāna#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tōkio#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Wā Awatea Ranatiki#,
				'generic' => q#Wā Ranatiki#,
				'standard' => q#Wā Arowhānui Ranatiki#,
			},
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Pāmura#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Te Kūrae Matomato#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Hōria ki Te Tonga#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Hato Hērena#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Atireira#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Piripane#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Tāwini#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hopatāone#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Poipiripi#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pētia#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Poihākena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Wā Ahitereiria Waenga Awatea#,
				'generic' => q#Wā Ahitereiria Waenga#,
				'standard' => q#Wā Ahitereiria Waenga Arowhānui#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Wā Ahitereiria Waenga-Uru Awatea#,
				'generic' => q#Wā Ahitereiria Waenga-Uru#,
				'standard' => q#Wā Ahitereiria Waenga-Uru Arowhānui#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Wā Ahitereiria ki te Rāwhiti Awatea#,
				'generic' => q#Wā Ahitereiria ki te Rāwhiti#,
				'standard' => q#Wā Ahitereiria ki te Rāwhiti Arowhānui#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Wā Ahitereiria ki te Uru Awatea#,
				'generic' => q#Wā Ahitereiria ki te Uru#,
				'standard' => q#Wā Ahitereiria ki te Uru Arowhānui#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Wā Atepaihānia Raumati#,
				'generic' => q#Wā Atepaihānia#,
				'standard' => q#Wā Atepaihānia Arowhānui#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Wā Azores Raumati#,
				'generic' => q#Wā Azores#,
				'standard' => q#Wā Azores Arowhānui#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Wā Pākaratēhi Raumati#,
				'generic' => q#Wā Pākaratēhi#,
				'standard' => q#Wā Pākaratēhi Arowhānui#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Wā Pūtana#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Wā Poriwia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Wā Parīhia Raumati#,
				'generic' => q#Wā Parīhia#,
				'standard' => q#Wā Parīhia Arowhānui#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Wā Poronai Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Wā Raumati o Te Kūrae Matomato#,
				'generic' => q#Wā o Te Kūrae Matomato#,
				'standard' => q#Wā Arowhānui o Te Kūrae Matomato#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Wā Chamorro Arowhānui#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Wā Rēkohu Awatea#,
				'generic' => q#Wā Rēkohu#,
				'standard' => q#Wā Rēkohu Arowhānui#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Wā Hiri Raumati#,
				'generic' => q#Wā Hiri#,
				'standard' => q#Wā Hiri Arowhānui#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Wā Haina Awatea#,
				'generic' => q#Wā Haina#,
				'standard' => q#Wā Haina Arowhānui#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Wā Choibalsan Raumati#,
				'generic' => q#Wā Choibalsan#,
				'standard' => q#Wā Choibalsan Arowhānui#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Wā o Te Moutere Kirihimete#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Wā o Ngā Moutere Kokohi#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Wā Koromōpia Raumati#,
				'generic' => q#Wā Koromōpia#,
				'standard' => q#Wā Koromōpia Arowhānui#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Wā Kuki Airani Raumati Haurua#,
				'generic' => q#Wā Kuki Airani#,
				'standard' => q#Wā Kuki Airani Arowhānui#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Wā Awatea Kiupa#,
				'generic' => q#Wā Kiupa#,
				'standard' => q#Wā Arowhānui Kiupa#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Wā Rēweti#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Wā Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Wā o Timoa ki te Rāwhiti#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Wā ki te Moutere Aranga Raumati#,
				'generic' => q#Wā ki te Moutere o Aranga#,
				'standard' => q#Wā ki te Moutere Aranga Arowhānui#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Wā Ekuatoa#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Wā Aonui Kōtuitui#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Tāone Tē Mōhiotia#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Pāpuniāmita#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Anatōra#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Ātene#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Pearīni#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Paruhi#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Putapēhi#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopeheikana#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Tapurini#,
			long => {
				'daylight' => q#Wā Airihi Arowhānui#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hēriki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Te Moutere Mana#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Itapūru#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Rīpene#,
		},
		'Europe/London' => {
			exemplarCity => q#Rānana#,
			long => {
				'daylight' => q#Wā Piritana Raumati#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Rakapuō#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Mātiri#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Mārata#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monāko#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mohikau#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ōhoro#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parī#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Parāka#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rōma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Hana Marino#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Tokoomo#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Te Poho-o-Pita#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Whiena#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Hūrika#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Wā Raumati Uropi Waenga#,
				'generic' => q#Wā Uropi Waenga#,
				'standard' => q#Wā Arowhānui Uropi Waenga#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Wā Raumati Uropi Rāwhiti#,
				'generic' => q#Wā Uropi Rāwhiti#,
				'standard' => q#Wā Arowhānui Uropi Rāwhiti#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Wā Ūropi ki te rāwhiti rawa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wā Raumati Uropi Uru#,
				'generic' => q#Wā Uropi Uru#,
				'standard' => q#Wā Arowhānui Uropi Uru#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Wā ki Ngā Motu Whākana Raumati#,
				'generic' => q#Wā ki Ngā Motu Whākana#,
				'standard' => q#Wā ki Ngā Motu Whākana Arowhānui#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Wā Whītī Raumati#,
				'generic' => q#Wā Whītī#,
				'standard' => q#Wā Whītī Arowhānui#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Wā Kiāna Wīwī#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Wā Wīwī o Te Tonga me te Kōpakatanga ki te Tonga#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Wā Toharite Kiriwīti#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Wā Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Wā Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Wā Hōria Raumati#,
				'generic' => q#Wā Hōria#,
				'standard' => q#Wā Hōria Arowhānui#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Wā Kiripati#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Wā Raumati o Whenuakāriki ki te rāwhiti#,
				'generic' => q#Wā Whenuakāriki ki te rāwhiti#,
				'standard' => q#Wā Arowhānui o Whenuakāriki ki te rāwhiti#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Wā Raumati o Whenuakāriki ki te uru#,
				'generic' => q#Wā Whenuakāriki ki te uru#,
				'standard' => q#Wā Arowhānui o Whenuakāriki ki te uru#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Wā Whanga Arowhānui#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Wā Kaiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Wā Awatea Hawaii-Aleutian#,
				'generic' => q#Wā Hawaii-Aleutian#,
				'standard' => q#Wā Arowhānui Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Wā Hongipua Raumati#,
				'generic' => q#Wā Hongipua#,
				'standard' => q#Wā Hongipua Arowhānui#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Wā Hovd Raumati#,
				'generic' => q#Wā Hovd#,
				'standard' => q#Wā Hovd Arowhānui#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Wā Īnia#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kirihimete#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokohi#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Māratiri#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Marihi#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Wā o Te Moana Īnia#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Wā Īniahaina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Wā Initonīhia Waenga#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Wā Initonīhia ki te rāwhiti#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Wā Initonīhia ki te uru#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Wā Irāna Awatea#,
				'generic' => q#Wā Irāna#,
				'standard' => q#Wā Irāna Arowhānui#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Wā Irkutsk Raumati#,
				'generic' => q#Wā Irkutsk#,
				'standard' => q#Wā Irkutsk Arowhānui#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Wā Iharaira Awatea#,
				'generic' => q#Wā Iharaira#,
				'standard' => q#Wā Iharaira Arowhānui#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Wā Hapani Awatea#,
				'generic' => q#Wā Hapani#,
				'standard' => q#Wā Hapani Arowhānui#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Wā Katatānga ki te Rāwhiti#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Wā Katatānga ki te Uru#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Wā Kōrea Awatea#,
				'generic' => q#Wā Kōrea#,
				'standard' => q#Wā Kōrea Arowhānui#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Wā Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Wā Krasnoyarsk Raumati#,
				'generic' => q#Wā Krasnoyarsk#,
				'standard' => q#Wā Krasnoyarsk Arowhānui#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Wā Kikitānga#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Wā o Ngā Mouter o Te Raina#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Wā Lord Howe Awatea#,
				'generic' => q#Wā Lord Howe#,
				'standard' => q#Wā Lord Howe Arowhānui#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Wā o Te Moutere Makoare#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Wā Magadan Raumati#,
				'generic' => q#Wā Magadan#,
				'standard' => q#Wā Magadan Arowhānui#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Wā Mareia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Wā Māratiri#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Wā Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Wā o Ngā Motu Māhara#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Wā Marihi Raumati#,
				'generic' => q#Wā Marihi#,
				'standard' => q#Wā Marihi Arowhānui#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Wā Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Wā Awatea o Mēhiko ki te uru-mā-raki#,
				'generic' => q#Wā Mēhiko ki te uru-mā-raki#,
				'standard' => q#Wā Arowhānui o Mēhiko ki te uru-mā-raki#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Wā Awatea Mēhiko Kiwa#,
				'generic' => q#Wā Mēhiko Kiwa#,
				'standard' => q#Wā Arowhānui Mēhiko Kiwa#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Wā Ulaanbaatar Raumati#,
				'generic' => q#Wā Ulaanbaatar#,
				'standard' => q#Wā Ulaanbaatar Arowhānui#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Wā Mohikau Raumati#,
				'generic' => q#Wā Mohikau#,
				'standard' => q#Wā Mohikau Arowhānui#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Wā Pēma#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Wā Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Wā Nepōra#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Wā Whenua Kanaki Raumati#,
				'generic' => q#Wā Whenua Kanaki#,
				'standard' => q#Wā Whenua Kanaki Arowhānui#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Wā Aotearoa Awatea#,
				'generic' => q#Wā Aotearoa#,
				'standard' => q#Wā Aotearoa Arowhānui#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Wā Awatea Newfoundland#,
				'generic' => q#Wā Newfoundland#,
				'standard' => q#Wā Arowhānui Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Wā Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Wā o Te Moutere Nōpoke Awatea#,
				'generic' => q#Wā o Te Moutere Nōpoke#,
				'standard' => q#Wā o Te Moutere Nōpoke Arowhānui#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Wā Fernando de Noronha Raumati#,
				'generic' => q#Wā Fernando de Noronha#,
				'standard' => q#Wā Fernando de Noronha Arowhānui#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Wā Novosibirsk Raumati#,
				'generic' => q#Wā Novosibirsk#,
				'standard' => q#Wā Novosibirsk Arowhānui#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Wā Omsk Raumati#,
				'generic' => q#Wā Omsk#,
				'standard' => q#Wā Omsk Arowhānui#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Āpia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Tāmaki Makaurau#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Rēkohu#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Whītī#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Kuama#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nōpoke#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nūmea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pango Pango#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Pārau#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pota Moahipi#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wārihi#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Wā Pakitāne Raumati#,
				'generic' => q#Wā Pakitāne#,
				'standard' => q#Wā Pakitāne Arowhānui#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Wā Pārau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Wā Papua Nūkini#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Wā Parakai Raumati#,
				'generic' => q#Wā Parakai#,
				'standard' => q#Wā Parakai Arowhānui#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Wā Peru Raumati#,
				'generic' => q#Wā Peru#,
				'standard' => q#Wā Peru Arowhānui#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Wā Piripīni Raumati#,
				'generic' => q#Wā Piripīni#,
				'standard' => q#Wā Piripīni Arowhānui#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Wā o Ngā Moutere Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Wā Awatea o St. Pierre me Miquelon#,
				'generic' => q#Wā St. Pierre me Miquelon#,
				'standard' => q#Wā Arowhānui o St. Pierre me Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Wā Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Wā Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Wā Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Wā Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Wā Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Wā Sakhalin Raumati#,
				'generic' => q#Wā Sakhalin#,
				'standard' => q#Wā Sakhalin Arowhānui#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Wā Hāmoa Awatea#,
				'generic' => q#Wā Hāmoa#,
				'standard' => q#Wā Hāmoa Arowhānui#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Wā Heikere#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Wā Hingapoa Arowhānui#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Wā o Ngā Motu Horomona#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Wā Hōria ki te Tonga#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Wā Huriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Wā Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Wā Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Wā Taipei Awatea#,
				'generic' => q#Wā Taipei#,
				'standard' => q#Wā Taipei Arowhānui#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Wā Takiritānga#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Wā Tokerau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Wā Tonga Raumati#,
				'generic' => q#Wā Tonga#,
				'standard' => q#Wā Tonga Arowhānui#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Wā Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Wā Tukumanatānga Raumati#,
				'generic' => q#Wā Tukumanatānga#,
				'standard' => q#Wā Tukumanatānga Arowhānui#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Wā Tūwaru#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Wā Urukoi Raumati#,
				'generic' => q#Wā Urukoi#,
				'standard' => q#Wā Urukoi Arowhānui#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Wā Uhipeketāne Raumati#,
				'generic' => q#Wā Uhipeketāne#,
				'standard' => q#Wā Uhipeketāne Arowhānui#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Wā Whenuatū Raumati#,
				'generic' => q#Wā Whenuatū#,
				'standard' => q#Wā Whenuatū Arowhānui#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wā Penehūera#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wā Vladivostok Raumati#,
				'generic' => q#Wā Vladivostok#,
				'standard' => q#Wā Vladivostok Arowhānui#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wā Volgograd Raumati#,
				'generic' => q#Wā Volgograd#,
				'standard' => q#Wā Volgograd Arowhānui#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wā Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wā o Te Motu Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wā Wārihi me Whutuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Wā Yakutsk Raumati#,
				'generic' => q#Wā Yakutsk#,
				'standard' => q#Wā Yakutsk Arowhānui#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Wā Yekaterinburg Raumati#,
				'generic' => q#Wā Yekaterinburg#,
				'standard' => q#Wā Yekaterinburg Arowhānui#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Wā Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
