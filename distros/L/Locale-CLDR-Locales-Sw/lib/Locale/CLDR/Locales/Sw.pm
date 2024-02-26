=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sw - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw;
# This file auto generated from Data\common\main\sw.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(kasoro →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sifuri),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← nukta →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(moja),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(mbili),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tatu),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(nne),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(tano),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sita),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(saba),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(nane),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(tisa),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(kumi[ na →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(ishirini[ na →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(thelathini[ na →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(arobaini[ na →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(hamsini[ na →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sitini[ na →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sabini[ na →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(themanini[ na →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(tisini[ na →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(mia ←←[ na →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(elfu ←←[, →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(milioni ←←[, →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(bilioni ←←[, →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(trilioni ←←[, →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(kvadrilioni ←←[, →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(usio),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(si nambari),
				},
				'max' => {
					divisor => q(1),
					rule => q(si nambari),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(wa kasoro →%spellout-cardinal→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(wa sifuri),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(kwanza),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(pili),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(wa =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(wa =%spellout-cardinal=),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Kiafar',
 				'ab' => 'Kiabkhazi',
 				'ace' => 'Kiacheni',
 				'ach' => 'Kiakoli',
 				'ada' => 'Kiadangme',
 				'ady' => 'Kiadyghe',
 				'af' => 'Kiafrikana',
 				'agq' => 'Kiaghem',
 				'ain' => 'Kiainu',
 				'ak' => 'Kiakani',
 				'ale' => 'Kialeut',
 				'alt' => 'Kialtai',
 				'am' => 'Kiamhari',
 				'an' => 'Kiaragoni',
 				'ang' => 'Kiingereza cha Kale',
 				'ann' => 'Kiobolo',
 				'anp' => 'Kiangika',
 				'ar' => 'Kiarabu',
 				'ar_001' => 'Kiarabu sanifu',
 				'arc' => 'Kiaramu',
 				'arn' => 'Kimapuche',
 				'arp' => 'Kiarapaho',
 				'arq' => 'Kiarabu cha Algeria',
 				'ars' => 'Kiarabu cha Najdi',
 				'arz' => 'Kiarabu cha Misri',
 				'as' => 'Kiassam',
 				'asa' => 'Kiasu',
 				'ast' => 'Kiasturia',
 				'atj' => 'Kiatikamekw',
 				'av' => 'Kiavari',
 				'awa' => 'Kiawadhi',
 				'ay' => 'Kiaymara',
 				'az' => 'Kiazerbaijani',
 				'az@alt=short' => 'Kiazeri',
 				'ba' => 'Kibashkiri',
 				'ban' => 'Kibali',
 				'bas' => 'Kibasaa',
 				'bax' => 'Kibamun',
 				'bbj' => 'Kighomala',
 				'be' => 'Kibelarusi',
 				'bej' => 'Kibeja',
 				'bem' => 'Kibemba',
 				'bez' => 'Kibena',
 				'bfd' => 'Kibafut',
 				'bg' => 'Kibulgaria',
 				'bgc' => 'Kiharyanvi',
 				'bgn' => 'Kibalochi cha Magharibi',
 				'bho' => 'Kibhojpuri',
 				'bi' => 'Kibislama',
 				'bin' => 'Kibini',
 				'bkm' => 'Kikom',
 				'bla' => 'Kisiksika',
 				'bm' => 'Kibambara',
 				'bn' => 'Kibengali',
 				'bo' => 'Kitibeti',
 				'br' => 'Kibretoni',
 				'brx' => 'Kibodo',
 				'bs' => 'Kibosnia',
 				'bug' => 'Kibugini',
 				'bum' => 'Kibulu',
 				'byn' => 'Kiblin',
 				'byv' => 'Kimedumba',
 				'ca' => 'Kikatalani',
 				'cay' => 'Kikayuga',
 				'ccp' => 'Kichakma',
 				'ce' => 'Kichechenia',
 				'ceb' => 'Kichebuano',
 				'cgg' => 'Kichiga',
 				'ch' => 'Kichamorro',
 				'chk' => 'Kichukisi',
 				'chm' => 'Kimari',
 				'cho' => 'Kichoktao',
 				'chp' => 'Kichipewyani',
 				'chr' => 'Kicherokee',
 				'chy' => 'Kicheyeni',
 				'ckb' => 'Kikurdi cha Sorani',
 				'clc' => 'Kichikotini',
 				'co' => 'Kikosikani',
 				'cop' => 'Kikhufti',
 				'crg' => 'Kimichifu',
 				'crj' => 'Kikrii cha Kusini Mashariki',
 				'crk' => 'Kikri (Maeneo Tambarare)',
 				'crl' => 'Kikrii cha Kaskazini Mashariki',
 				'crm' => 'Kikrii cha Moose',
 				'crr' => 'Kipamliko cha Carolina',
 				'crs' => 'Krioli ya Shelisheli',
 				'cs' => 'Kicheki',
 				'csw' => 'Kiomushkego',
 				'cu' => 'Kislovakia cha Kanisa',
 				'cv' => 'Kichuvash',
 				'cy' => 'Kiwelisi',
 				'da' => 'Kidenmaki',
 				'dak' => 'Kidakota',
 				'dar' => 'Kidaragwa',
 				'dav' => 'Kitaita',
 				'de' => 'Kijerumani',
 				'dgr' => 'Kidogrib',
 				'dje' => 'Kizarma',
 				'doi' => 'Kidogri',
 				'dsb' => 'Kisobia cha Chini',
 				'dua' => 'Kiduala',
 				'dv' => 'Kidivehi',
 				'dyo' => 'Kijola-Fonyi',
 				'dyu' => 'Kijula',
 				'dz' => 'Kizongkha',
 				'dzg' => 'Kidazaga',
 				'ebu' => 'Kiembu',
 				'ee' => 'Kiewe',
 				'efi' => 'Kiefik',
 				'egy' => 'Kimisri',
 				'eka' => 'Kiekajuk',
 				'el' => 'Kigiriki',
 				'en' => 'Kiingereza',
 				'en_CA' => 'Kiingereza (Canada)',
 				'en_GB' => 'Kiingereza (Uingereza)',
 				'en_GB@alt=short' => 'Kiingereza (UK)',
 				'eo' => 'Kiesperanto',
 				'es' => 'Kihispania',
 				'es_419' => 'Kihispania (Amerika ya Latini)',
 				'es_ES' => 'Kihispania (Ulaya)',
 				'et' => 'Kiestonia',
 				'eu' => 'Kibaski',
 				'ewo' => 'Kiewondo',
 				'fa' => 'Kiajemi',
 				'fa_AF' => 'Kiajemi (Afganistani)',
 				'ff' => 'Kifulani',
 				'fi' => 'Kifini',
 				'fil' => 'Kifilipino',
 				'fj' => 'Kifiji',
 				'fo' => 'Kifaroe',
 				'fon' => 'Kifon',
 				'fr' => 'Kifaransa',
 				'fr_CA' => 'Kifaransa (Canada)',
 				'frc' => 'Kifaransa cha Kajuni',
 				'fro' => 'Kifaransa cha Kale',
 				'frr' => 'Kifrisia cha Kaskazini',
 				'frs' => 'Kifrisia cha Mashariki',
 				'fur' => 'Kifriulian',
 				'fy' => 'Kifrisia cha Magharibi',
 				'ga' => 'Kiayalandi',
 				'gaa' => 'Ga',
 				'gag' => 'Kigagauz',
 				'gba' => 'Kigbaya',
 				'gd' => 'Kigaeli cha Uskoti',
 				'gez' => 'Kige’ez',
 				'gil' => 'Kikiribati',
 				'gl' => 'Kigalisi',
 				'gn' => 'Kiguarani',
 				'gor' => 'Kigorontalo',
 				'grc' => 'Kiyunani',
 				'gsw' => 'Kijerumani cha Uswisi',
 				'gu' => 'Kigujarati',
 				'guz' => 'Kikisii',
 				'gv' => 'Kimanx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Kihausa',
 				'hai' => 'Kihaida',
 				'haw' => 'Kihawai',
 				'hax' => 'Kihaida cha Kusini',
 				'he' => 'Kiebrania',
 				'hi' => 'Kihindi',
 				'hi_Latn@alt=variant' => 'Kihindi chenye Kiingereza',
 				'hil' => 'Kihiligaynon',
 				'hit' => 'Kihiti',
 				'hmn' => 'Kihmong',
 				'hr' => 'Kikorasia',
 				'hsb' => 'Kisobia cha Ukanda wa Juu',
 				'ht' => 'Kihaiti',
 				'hu' => 'Kihungaria',
 				'hup' => 'Hupa',
 				'hur' => 'Kihalkomelemi',
 				'hy' => 'Kiarmenia',
 				'hz' => 'Kiherero',
 				'ia' => 'Kiintalingua',
 				'iba' => 'Kiiban',
 				'ibb' => 'Kiibibio',
 				'id' => 'Kiindonesia',
 				'ie' => 'lugha ya kisayansi',
 				'ig' => 'Kiigbo',
 				'ii' => 'Kiyi cha Sichuan',
 				'ikt' => 'Kiinuktituti cha Kanada Magharibi',
 				'ilo' => 'Kiilocano',
 				'inh' => 'Kiingush',
 				'io' => 'Kiido',
 				'is' => 'Kiisilandi',
 				'it' => 'Kiitaliano',
 				'iu' => 'Kiinuktituti',
 				'ja' => 'Kijapani',
 				'jbo' => 'Lojban',
 				'jgo' => 'Kingomba',
 				'jmc' => 'Kimachame',
 				'jv' => 'Kijava',
 				'ka' => 'Kijojia',
 				'kab' => 'Kikabylia',
 				'kac' => 'Kachin',
 				'kaj' => 'Kijju',
 				'kam' => 'Kikamba',
 				'kbd' => 'Kikabardian',
 				'kbl' => 'Kikanembu',
 				'kcg' => 'Kityap',
 				'kde' => 'Kimakonde',
 				'kea' => 'Kikabuverdianu',
 				'kfo' => 'Kikoro',
 				'kg' => 'Kikongo',
 				'kgp' => 'Kikaingang',
 				'kha' => 'Kikhasi',
 				'khq' => 'Kikoyra Chiini',
 				'ki' => 'Kikikuyu',
 				'kj' => 'Kikwanyama',
 				'kk' => 'Kikazakh',
 				'kkj' => 'Lugha ya Kako',
 				'kl' => 'Kikalaallisut',
 				'kln' => 'Kikalenjin',
 				'km' => 'Kikambodia',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kikannada',
 				'ko' => 'Kikorea',
 				'koi' => 'Kikomi-Permyak',
 				'kok' => 'Kikonkani',
 				'kpe' => 'Kikpelle',
 				'kr' => 'Kikanuri',
 				'krc' => 'Kikarachay-Balkar',
 				'krl' => 'Karjala',
 				'kru' => 'Kurukh',
 				'ks' => 'Kikashmiri',
 				'ksb' => 'Kisambaa',
 				'ksf' => 'Kibafia',
 				'ksh' => 'Kicologne',
 				'ku' => 'Kikurdi',
 				'kum' => 'Kumyk',
 				'kv' => 'Kikomi',
 				'kw' => 'Kikorni',
 				'kwk' => 'Kikwakʼwala',
 				'ky' => 'Kikyrgyz',
 				'la' => 'Kilatini',
 				'lad' => 'Kiladino',
 				'lag' => 'Kirangi',
 				'lam' => 'Lamba',
 				'lb' => 'Kilasembagi',
 				'lez' => 'Kilezighian',
 				'lg' => 'Kiganda',
 				'li' => 'Limburgish',
 				'lil' => 'Kilillooet',
 				'lkt' => 'Kilakota',
 				'ln' => 'Kilingala',
 				'lo' => 'Kilaosi',
 				'lol' => 'Kimongo',
 				'lou' => 'Kikrioli cha Louisiana',
 				'loz' => 'Kilozi',
 				'lrc' => 'Kiluri cha Kaskazini',
 				'lsm' => 'Kisaamia',
 				'lt' => 'Kilithuania',
 				'lu' => 'Kiluba-Katanga',
 				'lua' => 'Kiluba-Lulua',
 				'lun' => 'Kilunda',
 				'luo' => 'Kijaluo',
 				'lus' => 'Kimizo',
 				'luy' => 'Kiluhya',
 				'lv' => 'Kilatvia',
 				'mad' => 'Kimadura',
 				'maf' => 'Kimafa',
 				'mag' => 'Kimagahi',
 				'mai' => 'Kimaithili',
 				'mak' => 'Kimakasar',
 				'mas' => 'Kimaasai',
 				'mde' => 'Kimaba',
 				'mdf' => 'Lugha ya Moksha',
 				'men' => 'Kimende',
 				'mer' => 'Kimeru',
 				'mfe' => 'Kimoriseni',
 				'mg' => 'Kimalagasi',
 				'mgh' => 'Kimakhuwa-Meetto',
 				'mgo' => 'Kimeta',
 				'mh' => 'Kimashale',
 				'mi' => 'Kimaori',
 				'mic' => 'Mi’kmaq',
 				'min' => 'Kiminangkabau',
 				'mk' => 'Kimacedonia',
 				'ml' => 'Kimalayalamu',
 				'mn' => 'Kimongolia',
 				'mni' => 'Kimanipuri',
 				'moe' => 'Kiinnu-aimun',
 				'moh' => 'Lugha ya Mohawk',
 				'mos' => 'Kimoore',
 				'mr' => 'Kimarathi',
 				'ms' => 'Kimalei',
 				'mt' => 'Kimalta',
 				'mua' => 'Kimundang',
 				'mul' => 'Lugha nyingi',
 				'mus' => 'Kikriki',
 				'mwl' => 'Kimirandi',
 				'my' => 'Kiburma',
 				'myv' => 'Kierzya',
 				'mzn' => 'Kimazanderani',
 				'na' => 'Kinauru',
 				'nap' => 'Kinapoli',
 				'naq' => 'Kinama',
 				'nb' => 'Kinorwe cha Bokmal',
 				'nd' => 'Kindebele cha Kaskazini',
 				'nds' => 'Kisaksoni',
 				'ne' => 'Kinepali',
 				'new' => 'Kinewari',
 				'ng' => 'Kindonga',
 				'nia' => 'Kiniasi',
 				'niu' => 'Kiniuea',
 				'nl' => 'Kiholanzi',
 				'nl_BE' => 'Kiflemi',
 				'nmg' => 'Kikwasio',
 				'nn' => 'Kinorwe cha Nynorsk',
 				'nnh' => 'Lugha ya Ngiemboon',
 				'no' => 'Kinorwe',
 				'nog' => 'Kinogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'Kindebele',
 				'nso' => 'Kisotho cha Kaskazini',
 				'nus' => 'Kinuer',
 				'nv' => 'Kinavajo',
 				'nwc' => 'Kinewari cha kale',
 				'ny' => 'Kinyanja',
 				'nym' => 'Kinyamwezi',
 				'nyn' => 'Kinyankole',
 				'nyo' => 'Kinyoro',
 				'nzi' => 'Kinzema',
 				'oc' => 'Kiokitani',
 				'ojb' => 'Kiojibwa cha Kaskazini Magharibi',
 				'ojc' => 'Kiojibwa cha kati',
 				'ojs' => 'Kikrii cha Oji',
 				'ojw' => 'Kiojibwa cha Magharibi',
 				'oka' => 'Kiokanagani',
 				'om' => 'Kioromo',
 				'or' => 'Kioriya',
 				'os' => 'Kiosetia',
 				'pa' => 'Kipunjabi',
 				'pag' => 'Kipangasinan',
 				'pam' => 'Kipampanga',
 				'pap' => 'Kipapiamento',
 				'pau' => 'Kipalau',
 				'pcm' => 'Pijini ya Nigeria',
 				'peo' => 'Kiajemi cha Kale',
 				'pis' => 'Kipijini',
 				'pl' => 'Kipolandi',
 				'pqm' => 'Kimaliseet-Passamaquoddy',
 				'prg' => 'Kiprussia',
 				'ps' => 'Kipashto',
 				'ps@alt=variant' => 'Kipushto',
 				'pt' => 'Kireno',
 				'pt_BR' => 'Kireno (Brazili)',
 				'pt_PT' => 'Kireno (Ulaya)',
 				'qu' => 'Kikechua',
 				'quc' => 'Kʼicheʼ',
 				'raj' => 'Kirajasthani',
 				'rap' => 'Kirapanui',
 				'rar' => 'Kirarotonga',
 				'rhg' => 'Kirohingya',
 				'rm' => 'Kiromanshi',
 				'rn' => 'Kirundi',
 				'ro' => 'Kiromania',
 				'ro_MD' => 'Kimoldova cha Romania',
 				'rof' => 'Kirombo',
 				'ru' => 'Kirusi',
 				'rup' => 'Kiaromania',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Lugha ya Rwa',
 				'sa' => 'Kisanskriti',
 				'sad' => 'Kisandawe',
 				'sah' => 'Kisakha',
 				'sam' => 'Kiaramu cha Wasamaria',
 				'saq' => 'Kisamburu',
 				'sat' => 'Kisantali',
 				'sba' => 'Kingambay',
 				'sbp' => 'Kisangu',
 				'sc' => 'Kisardinia',
 				'scn' => 'Kisicilia',
 				'sco' => 'Kiskoti',
 				'sd' => 'Kisindhi',
 				'sdh' => 'Kikurdi cha Kusini',
 				'se' => 'Kisami cha Kaskazini',
 				'seh' => 'Kisena',
 				'ses' => 'Kikoyraboro Senni',
 				'sg' => 'Kisango',
 				'sh' => 'Kiserbia-kroeshia',
 				'shi' => 'Kitachelhit',
 				'shn' => 'Kishan',
 				'shu' => 'Kiarabu cha Chad',
 				'si' => 'Kisinhala',
 				'sk' => 'Kislovakia',
 				'sl' => 'Kislovenia',
 				'slh' => 'Lugha ya Lushootseed ya Kusini',
 				'sm' => 'Kisamoa',
 				'sma' => 'Kisami cha Kusini',
 				'smj' => 'Kisami cha Lule',
 				'smn' => 'Kisami cha Inari',
 				'sms' => 'Kisami cha Skolt',
 				'sn' => 'Kishona',
 				'snk' => 'Kisoninke',
 				'so' => 'Kisomali',
 				'sq' => 'Kialbania',
 				'sr' => 'Kiserbia',
 				'srn' => 'Lugha ya Sranan Tongo',
 				'ss' => 'Kiswati',
 				'ssy' => 'Kisaho',
 				'st' => 'Kisotho',
 				'str' => 'Kisalishi cha Straiti',
 				'su' => 'Kisunda',
 				'suk' => 'Kisukuma',
 				'sus' => 'Kisusu',
 				'sv' => 'Kiswidi',
 				'sw' => 'Kiswahili',
 				'swb' => 'Shikomor',
 				'syr' => 'Lugha ya Syriac',
 				'ta' => 'Kitamili',
 				'tce' => 'Kitutchone cha Kusini',
 				'te' => 'Kitelugu',
 				'tem' => 'Kitemne',
 				'teo' => 'Kiteso',
 				'tet' => 'Kitetum',
 				'tg' => 'Kitajiki',
 				'tgx' => 'Kitagishi',
 				'th' => 'Kithai',
 				'tht' => 'Kitahltani',
 				'ti' => 'Kitigrinya',
 				'tig' => 'Kitigre',
 				'tk' => 'Kiturukimeni',
 				'tlh' => 'Kiklingoni',
 				'tli' => 'Kitlingiti',
 				'tn' => 'Kitswana',
 				'to' => 'Kitonga',
 				'tok' => 'Kitoki Pona',
 				'tpi' => 'Kitokpisin',
 				'tr' => 'Kituruki',
 				'trv' => 'Kitaroko',
 				'ts' => 'Kitsonga',
 				'tt' => 'Kitatari',
 				'ttm' => 'Kitutchone cha Kaskazini',
 				'tum' => 'Kitumbuka',
 				'tvl' => 'Kituvalu',
 				'tw' => 'Twi',
 				'twq' => 'Kitasawak',
 				'ty' => 'Kitahiti',
 				'tyv' => 'Kituva',
 				'tzm' => 'Kitamazighati cha Atlasi ya Kati',
 				'udm' => 'Kiudmurt',
 				'ug' => 'Kiuyghur',
 				'uk' => 'Kiukraini',
 				'umb' => 'Umbundu',
 				'und' => 'Lugha isiyojulikana',
 				'ur' => 'Kiurdu',
 				'uz' => 'Kiuzbeki',
 				'vai' => 'Kivai',
 				've' => 'Kivenda',
 				'vi' => 'Kivietinamu',
 				'vo' => 'Kivolapuk',
 				'vun' => 'Kivunjo',
 				'wa' => 'Kiwaloon',
 				'wae' => 'Kiwalser',
 				'wal' => 'Kiwolaytta',
 				'war' => 'Kiwaray',
 				'wbp' => 'Kiwarlpiri',
 				'wo' => 'Kiwolofu',
 				'wuu' => 'Kichina cha Wu',
 				'xal' => 'Kikalmyk',
 				'xh' => 'Kixhosa',
 				'xog' => 'Kisoga',
 				'yao' => 'Kiyao',
 				'yav' => 'Kiyangben',
 				'ybb' => 'Kiyemba',
 				'yi' => 'Kiyiddi',
 				'yo' => 'Kiyoruba',
 				'yrl' => 'Kinheengatu',
 				'yue' => 'Kikantoni',
 				'yue@alt=menu' => 'Kichina, Kikantoni',
 				'zgh' => 'Kiberber Sanifu cha Moroko',
 				'zh' => 'Kichina',
 				'zh@alt=menu' => 'Kichina sanifu',
 				'zh_Hans' => 'Kichina (Kilichorahisishwa)',
 				'zh_Hant' => 'Kichina cha Jadi',
 				'zh_Hant@alt=long' => 'Kichina (cha jadi)',
 				'zu' => 'Kizulu',
 				'zun' => 'Kizuni',
 				'zxx' => 'Hakuna maudhui ya lugha',
 				'zza' => 'Kizaza',

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
			'Adlm' => 'Kiadlamu',
 			'Arab' => 'Kiarabu',
 			'Arab@alt=variant' => 'Kiajemi/Kiarabu',
 			'Aran' => 'Kinastaliki',
 			'Armn' => 'Kiarmenia',
 			'Beng' => 'Kibengali',
 			'Bopo' => 'Kibopomofo',
 			'Brai' => 'Nukta nundu',
 			'Cakm' => 'Kichakma',
 			'Cans' => 'Silabi Zilizounganishwa za Wakazi Asili wa Kanada',
 			'Cher' => 'Kicherokee',
 			'Cyrl' => 'Kisiriliki',
 			'Deva' => 'Kidevanagari',
 			'Ethi' => 'Kiethiopia',
 			'Geor' => 'Kijojia',
 			'Grek' => 'Kigiriki',
 			'Gujr' => 'Kigujarati',
 			'Guru' => 'Kigurmukhi',
 			'Hanb' => 'Kihan chenye Bopomofo',
 			'Hang' => 'Kihangul',
 			'Hani' => 'Kihan',
 			'Hans' => 'Rahisi',
 			'Hans@alt=stand-alone' => 'Kihan Rahisi',
 			'Hant' => 'Cha jadi',
 			'Hant@alt=stand-alone' => 'Kihan cha Jadi',
 			'Hebr' => 'Kiebrania',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Hati za Kijapani',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Kijapani',
 			'Kana' => 'Kikatakana',
 			'Khmr' => 'Kikambodia',
 			'Knda' => 'Kikannada',
 			'Kore' => 'Kikorea',
 			'Laoo' => 'Kilaosi',
 			'Latn' => 'Kilatini',
 			'Mlym' => 'Kimalayalam',
 			'Mong' => 'Kimongolia',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Myama',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Kiol Chiki',
 			'Orya' => 'Kioriya',
 			'Rohg' => 'Kihanifi',
 			'Sinh' => 'Kisinhala',
 			'Sund' => 'Kisunda',
 			'Syrc' => 'Kisiriaki',
 			'Taml' => 'Kitamil',
 			'Telu' => 'Kitelugu',
 			'Tfng' => 'Kitifinagh',
 			'Thaa' => 'Kithaana',
 			'Thai' => 'Kithai',
 			'Tibt' => 'Kitibeti',
 			'Vaii' => 'Kivai',
 			'Yiii' => 'Kiyii',
 			'Zmth' => 'Hati za kihisabati',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Alama',
 			'Zxxx' => 'Haijaandikwa',
 			'Zyyy' => 'Kawaida',
 			'Zzzz' => 'Hati isiyojulikana',

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
			'001' => 'Dunia',
 			'002' => 'Afrika',
 			'003' => 'Amerika Kaskazini',
 			'005' => 'Amerika Kusini',
 			'009' => 'Oceania',
 			'011' => 'Afrika ya Magharibi',
 			'013' => 'Amerika ya Kati',
 			'014' => 'Afrika ya Mashariki',
 			'015' => 'Afrika ya Kaskazini',
 			'017' => 'Afrika ya Kati',
 			'018' => 'Afrika ya Kusini',
 			'019' => 'Amerika',
 			'021' => 'Amerika ya Kaskazini',
 			'029' => 'Karibiani',
 			'030' => 'Asia ya Mashariki',
 			'034' => 'Asia ya Kusini',
 			'035' => 'Asia ya Kusini Mashariki',
 			'039' => 'Ulaya ya Kusini',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Eneo la Mikronesia',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Asia ya Kati',
 			'145' => 'Asia ya Magharibi',
 			'150' => 'Ulaya',
 			'151' => 'Ulaya ya Mashariki',
 			'154' => 'Ulaya ya Kaskazini',
 			'155' => 'Ulaya ya Magharibi',
 			'202' => 'Afrika ya Kusini mwa Jangwa la Sahara',
 			'419' => 'Amerika ya Kilatini',
 			'AC' => 'Kisiwa cha Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Falme za Kiarabu',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua na Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antaktiki',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoa ya Marekani',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Visiwa vya Aland',
 			'AZ' => 'Azerbaijani',
 			'BA' => 'Bosnia na Hezegovina',
 			'BB' => 'Babadosi',
 			'BD' => 'Bangladeshi',
 			'BE' => 'Ubelgiji',
 			'BF' => 'Bukinafaso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahareni',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthelemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Uholanzi ya Karibiani',
 			'BR' => 'Brazil',
 			'BS' => 'Bahama',
 			'BT' => 'Bhutan',
 			'BV' => 'Kisiwa cha Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Visiwa vya Cocos (Keeling)',
 			'CD' => 'Jamhuri ya Kidemokrasia ya Kongo',
 			'CD@alt=variant' => 'Kongo (DRC)',
 			'CF' => 'Jamhuri ya Afrika ya Kati',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Jamhuri ya Kongo',
 			'CH' => 'Uswisi',
 			'CI' => 'Cote d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Visiwa vya Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameruni',
 			'CN' => 'Uchina',
 			'CO' => 'Kolombia',
 			'CP' => 'Kisiwa cha Clipperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curacao',
 			'CX' => 'Kisiwa cha Krismasi',
 			'CY' => 'Saiprasi',
 			'CZ' => 'Chechia',
 			'CZ@alt=variant' => 'Jamhuri ya Cheki',
 			'DE' => 'Ujerumani',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denmaki',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuri ya Dominika',
 			'DZ' => 'Aljeria',
 			'EA' => 'Ceuta na Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Misri',
 			'EH' => 'Sahara Magharibi',
 			'ER' => 'Eritrea',
 			'ES' => 'Uhispania',
 			'ET' => 'Ethiopia',
 			'EU' => 'Umoja wa Ulaya',
 			'EZ' => 'Jumuiya ya Ulaya',
 			'FI' => 'Ufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Visiwa vya Falkland',
 			'FK@alt=variant' => 'Visiwa vya Falkland (Islas Malvinas)',
 			'FM' => 'Mikronesia',
 			'FO' => 'Visiwa vya Faroe',
 			'FR' => 'Ufaransa',
 			'GA' => 'Gabon',
 			'GB' => 'Ufalme wa Muungano',
 			'GD' => 'Grenada',
 			'GE' => 'Jojia',
 			'GF' => 'Guiana ya Ufaransa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Gine',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea ya Ikweta',
 			'GR' => 'Ugiriki',
 			'GS' => 'Visiwa vya Georgia Kusini na Sandwich Kusini',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Ginebisau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Kisiwa cha Heard na Visiwa vya McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Visiwa vya Kanari',
 			'ID' => 'Indonesia',
 			'IE' => 'Ayalandi',
 			'IL' => 'Israeli',
 			'IM' => 'Kisiwa cha Man',
 			'IN' => 'India',
 			'IO' => 'Eneo la Uingereza katika Bahari Hindi',
 			'IQ' => 'Iraki',
 			'IR' => 'Iran',
 			'IS' => 'Aisilandi',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordan',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizistani',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'St. Kitts na Nevis',
 			'KP' => 'Korea Kaskazini',
 			'KR' => 'Korea Kusini',
 			'KW' => 'Kuwait',
 			'KY' => 'Visiwa vya Cayman',
 			'KZ' => 'Kazakistani',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaska',
 			'MH' => 'Visiwa vya Marshall',
 			'MK' => 'Masedonia ya Kaskazini',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Makau SAR China',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Visiwa vya Mariana vya Kaskazini',
 			'MQ' => 'Martinique',
 			'MR' => 'Moritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Morisi',
 			'MV' => 'Maldivi',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesia',
 			'MZ' => 'Msumbiji',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Kisiwa cha Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Uholanzi',
 			'NO' => 'Norway',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nyuzilandi',
 			'NZ@alt=variant' => 'Aotearoa Nyuzilandi',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polynesia ya Ufaransa',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Ufilipino',
 			'PK' => 'Pakistani',
 			'PL' => 'Poland',
 			'PM' => 'Santapierre na Miquelon',
 			'PN' => 'Visiwa vya Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Maeneo ya Palestina',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Ureno',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceania ya Nje',
 			'RE' => 'Reunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Urusi',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudia',
 			'SB' => 'Visiwa vya Solomon',
 			'SC' => 'Ushelisheli',
 			'SD' => 'Sudan',
 			'SE' => 'Uswidi',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard na Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Siera Leoni',
 			'SM' => 'San Marino',
 			'SN' => 'Senegali',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Kusini',
 			'ST' => 'Sao Tome na Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Uswazi',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Visiwa vya Turks na Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Himaya za Kusini za Kifaranza',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Tajikistani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor ya Mashariki',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Uturuki',
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Visiwa Vidogo vya Nje vya Marekani',
 			'UN' => 'Umoja wa Mataifa',
 			'US' => 'Marekani',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzibekistani',
 			'VA' => 'Mji wa Vatican',
 			'VC' => 'St. Vincent na Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Visiwa vya Virgin, Uingereza',
 			'VI' => 'Visiwa vya Virgin, Marekani',
 			'VN' => 'Vietnamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis na Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Lafudhi Bandia',
 			'XB' => 'Lafudhi Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Kusini',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Eneo lisilojulikana',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalenda',
 			'cf' => 'Mpangilio wa Sarafu',
 			'colalternate' => 'Puuza Upangaji Alama',
 			'colbackwards' => 'Upangaji Uliogeuzwa wa Kiinitoni',
 			'colcasefirst' => 'Upangaji wa Herufi kubwa/Herufi ndogo',
 			'colcaselevel' => 'Upangaji Kulingana na Ukubwa wa Herufi',
 			'collation' => 'Mpangilio',
 			'colnormalization' => 'Upangaji wa Kawaida',
 			'colnumeric' => 'Upangaji kwa Nambari',
 			'colstrength' => 'Nguvu ya Upangaji',
 			'currency' => 'Sarafu',
 			'hc' => 'Kipindi cha saa (12 au 24)',
 			'lb' => 'Mtindo wa Kukata Mstari',
 			'ms' => 'Mfumo wa Vipimo',
 			'numbers' => 'Nambari',
 			'timezone' => 'Saa za Eneo',
 			'va' => 'Lahaja za Lugha',
 			'x' => 'Matumizi ya Kibinafsi',

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
 				'buddhist' => q{Kalenda ya Kibuddha},
 				'chinese' => q{Kalenda ya Kichina},
 				'coptic' => q{Kalenda ya Koptiki},
 				'dangi' => q{Kalenda ya Dangi},
 				'ethiopic' => q{Kalenda ya Kiethiopia},
 				'ethiopic-amete-alem' => q{Kalenda ya Kiethiopia ya Amete Alem},
 				'gregorian' => q{Kalenda ya Kigregori},
 				'hebrew' => q{Kalenda ya Kiebrania},
 				'indian' => q{Kalenda ya Taifa ya India},
 				'islamic' => q{Kalenda ya Hijra},
 				'islamic-civil' => q{Kalenda ya Hijra (inayoanza usiku wa manane)},
 				'islamic-umalqura' => q{Kalenda ya Hijra (Umm ul-Qura)},
 				'iso8601' => q{Kalenda ya ISO-8601},
 				'japanese' => q{Kalenda ya Kijapani},
 				'persian' => q{Kalenda ya Kiajemi},
 				'roc' => q{Kalenda ya Jamhuri ya Uchina},
 			},
 			'cf' => {
 				'account' => q{Mpangilio wa Kihasibu wa Sarafu},
 				'standard' => q{Mpangilio wa Kawaida wa Sarafu},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Panga Alama},
 				'shifted' => q{Panga Alama za Kupuuza},
 			},
 			'colbackwards' => {
 				'no' => q{Panga Viinitoni kwa Kawaida},
 				'yes' => q{Panga Viinitoni Kumegeuzwa},
 			},
 			'colcasefirst' => {
 				'lower' => q{Panga Herufi ndogo Kwanza},
 				'no' => q{Panga Utaratibu wa Herufi ya Kawaida},
 				'upper' => q{Panga Herufi kubwa Kwanza},
 			},
 			'colcaselevel' => {
 				'no' => q{Panga Isiyoathiriwa na Herufi},
 				'yes' => q{Panga kwa Inayoathiriwa na Herufi},
 			},
 			'collation' => {
 				'big5han' => q{Mpangilio wa Kichina cha Jadi - Big5},
 				'dictionary' => q{Mpangilio wa Kamusi},
 				'ducet' => q{Mpangilio Chaguo-Msingi wa Unicode},
 				'gb2312han' => q{Mpangilio wa Kichina Rahisi - GB2312},
 				'phonebook' => q{Mpangilio wa Orodha za Nambari za Simu},
 				'phonetic' => q{Utaratibu wa Kupanga Fonetiki},
 				'pinyin' => q{Mpangilio wa Kipinyin},
 				'reformed' => q{Mpangilio Uliorekebishwa},
 				'search' => q{Utafutaji wa Kijumla},
 				'searchjl' => q{Tafuta kwa Konsonanti Halisi ya Hangul},
 				'standard' => q{Mpangilio wa Kawaida},
 				'stroke' => q{Mpangilio wa Mikwaju},
 				'traditional' => q{Mpangilio wa Kawaida},
 				'unihan' => q{Mpangilio wa Mikwaju ya Shina},
 			},
 			'colnormalization' => {
 				'no' => q{Panga Bila Ukawaida},
 				'yes' => q{Upangaji Msimbosare Umekawaidishwa},
 			},
 			'colnumeric' => {
 				'no' => q{Panga Tarakimu Kivyake},
 				'yes' => q{Panga Dijiti kwa Namba},
 			},
 			'colstrength' => {
 				'identical' => q{Panga Zote},
 				'primary' => q{Panga Herufi Msingi Tu},
 				'quaternary' => q{Panga Viinitoni/Herufi/Upana/Kana},
 				'secondary' => q{Panga Viinitoni},
 				'tertiary' => q{Panga Viinitoni/Herufi/Upana},
 			},
 			'd0' => {
 				'fwidth' => q{Upana kamili},
 				'hwidth' => q{Nusu upana},
 				'npinyin' => q{Ya Nambari},
 			},
 			'hc' => {
 				'h11' => q{Kipindi cha saa 12 (0–11)},
 				'h12' => q{Kipindi cha saa 12 (1–12)},
 				'h23' => q{Kipindi cha saa 24 (0–23)},
 				'h24' => q{Kipindi cha saa 24 (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Mtindo Pana wa Kukata Mstari},
 				'normal' => q{Mtindo wa Kawaida wa Kukata Mstari},
 				'strict' => q{Mtindo Finyu wa Kukata Mstari},
 			},
 			'm0' => {
 				'bgn' => q{Mtindo wa kunukuu wa US BGN},
 				'ungegn' => q{Mtindo wa kunukuu wa UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{Mfumo wa Metriki},
 				'uksystem' => q{Mfumo wa Vipimo wa Uingereza},
 				'ussystem' => q{Mfumo wa Vipimo wa Marekani},
 			},
 			'numbers' => {
 				'arab' => q{Nambari za Kiarabu/Kihindi},
 				'arabext' => q{Nambari za Kiarabu/Kihindi Zilizopanuliwa},
 				'armn' => q{Nambari za Kiarmenia},
 				'armnlow' => q{Nambari Ndogo za Kiarmenia},
 				'beng' => q{Nambari za Kibengali},
 				'cakm' => q{Nambari za Kichakma},
 				'cham' => q{Nambari za Kichami},
 				'deva' => q{Nambari za Kidevanagari},
 				'ethi' => q{Nambari za Kiethiopia},
 				'finance' => q{Tarakimu za Kifedha},
 				'fullwide' => q{Nambari za Upana Kamili},
 				'geor' => q{Nambari za Kigeorgia},
 				'grek' => q{Nambari za Kigiriki},
 				'greklow' => q{Nambari Ndogo za Kigiriki},
 				'gujr' => q{Nambari za Kigujarati},
 				'guru' => q{Nambari za Kigurmukhi},
 				'hanidec' => q{Nambari za Desimali za Kichina},
 				'hans' => q{Nambari za Kichina Rahisi},
 				'hansfin' => q{Nambari za Kifedha za Kichina Rahisi},
 				'hant' => q{Nambari za Kichina cha Jadi},
 				'hantfin' => q{Nambari za Kifedha za Kichina cha Jadi},
 				'hebr' => q{Nambari za Kiebrania},
 				'java' => q{Nambari za Kijava},
 				'jpan' => q{Nambari za Kijapani},
 				'jpanfin' => q{Nambari za Kifedha za Kijapani},
 				'khmr' => q{Nambari za Kikambodia},
 				'knda' => q{Nambari za Kikannada},
 				'laoo' => q{Nambari za Kilao},
 				'latn' => q{Nambari za Nchi za Magharibi},
 				'limb' => q{Nambari za Kilimbu},
 				'mlym' => q{Nambari za Malayalam},
 				'mong' => q{Nambari za Kimongolia},
 				'mtei' => q{Nambari za Meetei Mayek},
 				'mymr' => q{Nambari za Myanmar},
 				'native' => q{Nambari Asili},
 				'olck' => q{Nambari za Kiol Chiki},
 				'orya' => q{Nambari za Kioriya},
 				'roman' => q{Nambari za Kirumi},
 				'romanlow' => q{Nambari Ndogo za Kirumi},
 				'takr' => q{Nambari za Kitakri},
 				'taml' => q{Nambari za Kitamil cha Jadi},
 				'tamldec' => q{Nambari za Kitamil},
 				'telu' => q{Nambari za Kitelugu},
 				'thai' => q{Nambari za Kithai},
 				'tibt' => q{Nambari za Kitibeti},
 				'traditional' => q{Tarakimu za Jadi},
 				'vaii' => q{Nambari za Kivai},
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
			'metric' => q{Mfumo wa Mita},
 			'UK' => q{Uingereza},
 			'US' => q{Marekani},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lugha: {0}',
 			'script' => 'Hati: {0}',
 			'region' => 'Eneo: {0}',

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
			auxiliary => qr{[c q x]},
			index => ['A', 'B', '{CH}', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b {ch} d e f g h i j k l m n o p r s t u v w y z]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ' " ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{CH}', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
						'name' => q(sehemu kuu za dira),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(sehemu kuu za dira),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q(mvuto wa graviti {0}),
						'other' => q(mvuto wa graviti {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q(mvuto wa graviti {0}),
						'other' => q(mvuto wa graviti {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q(mita {0} kwa kila sekunde mraba),
						'other' => q(mita {0} kwa kila sekunde mraba),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q(mita {0} kwa kila sekunde mraba),
						'other' => q(mita {0} kwa kila sekunde mraba),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q(mzunguko {0}),
						'other' => q(mizunguko {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q(mzunguko {0}),
						'other' => q(mizunguko {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q(sentimita {0} ya mraba),
						'other' => q(sentimita {0} za mraba),
						'per' => q({0} kwa kila sentimita ya mraba),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q(sentimita {0} ya mraba),
						'other' => q(sentimita {0} za mraba),
						'per' => q({0} kwa kila sentimita ya mraba),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q(futi {0} ya mraba),
						'other' => q(futi {0} za mraba),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q(futi {0} ya mraba),
						'other' => q(futi {0} za mraba),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q(inchi {0} ya mraba),
						'other' => q(inchi {0} za mraba),
						'per' => q({0} kwa kila inchi mraba),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q(inchi {0} ya mraba),
						'other' => q(inchi {0} za mraba),
						'per' => q({0} kwa kila inchi mraba),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q(kilomita {0} ya mraba),
						'other' => q(kilomita {0} za mraba),
						'per' => q({0} kwa kila kilomita mraba),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q(kilomita {0} ya mraba),
						'other' => q(kilomita {0} za mraba),
						'per' => q({0} kwa kila kilomita mraba),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q(mita {0} ya mraba),
						'other' => q(mita {0} za mraba),
						'per' => q({0} kwa kila mita ya mraba),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q(mita {0} ya mraba),
						'other' => q(mita {0} za mraba),
						'per' => q({0} kwa kila mita ya mraba),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q(maili {0} ya mraba),
						'other' => q(maili {0} za mraba),
						'per' => q({0} kwa kila maili ya mraba),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q(maili {0} ya mraba),
						'other' => q(maili {0} za mraba),
						'per' => q({0} kwa kila maili ya mraba),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q(yadi {0} ya mraba),
						'other' => q(yadi {0} za mraba),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q(yadi {0} ya mraba),
						'other' => q(yadi {0} za mraba),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramu kwa kila desilita),
						'one' => q(miligramu {0} kwa kila desilita),
						'other' => q(miligramu {0} kwa kila desilita),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramu kwa kila desilita),
						'one' => q(miligramu {0} kwa kila desilita),
						'other' => q(miligramu {0} kwa kila desilita),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q(milimoli {0} kwa kila lita),
						'other' => q(milimoli {0} kwa kila lita),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q(milimoli {0} kwa kila lita),
						'other' => q(milimoli {0} kwa kila lita),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} kwa kila elfu),
						'other' => q({0} kwa kila elfu),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} kwa kila elfu),
						'other' => q({0} kwa kila elfu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q(sehemu {0} kwa kila milioni),
						'other' => q(sehemu {0} kwa kila milioni),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q(sehemu {0} kwa kila milioni),
						'other' => q(sehemu {0} kwa kila milioni),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(permyriadi {0}),
						'other' => q(permyriadi {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(permyriadi {0}),
						'other' => q(permyriadi {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q(lita {0} kwa kilomita 100),
						'other' => q(lita {0} kwa kilomita 100),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q(lita {0} kwa kilomita 100),
						'other' => q(lita {0} kwa kilomita 100),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q(maili {0} kwa kila galoni),
						'other' => q(maili {0} kwa kila galoni),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q(maili {0} kwa kila galoni),
						'other' => q(maili {0} kwa kila galoni),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(maili kwa kila galoni la Uingereza),
						'one' => q(maili {0} kwa kila galoni la Uingereza),
						'other' => q(maili {0} kwa kila galoni la Uingereza),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(maili kwa kila galoni la Uingereza),
						'one' => q(maili {0} kwa kila galoni la Uingereza),
						'other' => q(maili {0} kwa kila galoni la Uingereza),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabaiti),
						'one' => q(gigabaiti {0}),
						'other' => q(gigabaiti {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabaiti),
						'one' => q(gigabaiti {0}),
						'other' => q(gigabaiti {0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabiti),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabiti),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabaiti),
						'one' => q(megabaiti {0}),
						'other' => q(megabaiti {0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabaiti),
						'one' => q(megabaiti {0}),
						'other' => q(megabaiti {0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q(petabaiti {0}),
						'other' => q(petabaiti {0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q(petabaiti {0}),
						'other' => q(petabaiti {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q(millisekunde {0}),
						'other' => q(millisekunde {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q(millisekunde {0}),
						'other' => q(millisekunde {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q(miliampea {0}),
						'other' => q(miliampea {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q(miliampea {0}),
						'other' => q(miliampea {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(vipimo vya joto vya Uingereza),
						'one' => q(kipimo {0} cha joto cha Uingereza),
						'other' => q(vipimo {0} vya joto vya Uingereza),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(vipimo vya joto vya Uingereza),
						'one' => q(kipimo {0} cha joto cha Uingereza),
						'other' => q(vipimo {0} vya joto vya Uingereza),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q(elektrovolti {0}),
						'other' => q(elektrovolti {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q(elektrovolti {0}),
						'other' => q(elektrovolti {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q(kilowati {0} kwa saa),
						'other' => q(kilowati {0} kwa saa),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q(kilowati {0} kwa saa),
						'other' => q(kilowati {0} kwa saa),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(vipimo vya gesi, Marekani),
						'one' => q(kipimo {0} cha gesi, Marekani),
						'other' => q(vipimo {0} vya gesi, Marekani),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(vipimo vya gesi, Marekani),
						'one' => q(kipimo {0} cha gesi, Marekani),
						'other' => q(vipimo {0} vya gesi, Marekani),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowati saa kwa kilomita 100),
						'one' => q(kilowati saa {0} kwa kilomita 100),
						'other' => q(kilowati saa {0} kwa kilomita 100),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowati saa kwa kilomita 100),
						'one' => q(kilowati saa {0} kwa kilomita 100),
						'other' => q(kilowati saa {0} kwa kilomita 100),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q(newtoni {0}),
						'other' => q(newtoni {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q(newtoni {0}),
						'other' => q(newtoni {0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pauni za kani),
						'one' => q(pauni {0} ya kani),
						'other' => q(pauni {0} za kani),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pauni za kani),
						'one' => q(pauni {0} ya kani),
						'other' => q(pauni {0} za kani),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(vitone kwa kila sentimita),
						'one' => q(kitone {0} kwa kila sentimita),
						'other' => q(vitone {0} kwa kila sentimita),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(vitone kwa kila sentimita),
						'one' => q(kitone {0} kwa kila sentimita),
						'other' => q(vitone {0} kwa kila sentimita),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(vitone kwa kila inchi),
						'one' => q(kitone {0} kwa kila inchi),
						'other' => q(vitone {0} kwa kila inchi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(vitone kwa kila inchi),
						'one' => q(kitone {0} kwa kila inchi),
						'other' => q(vitone {0} kwa kila inchi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em ya kupiga chapa),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em ya kupiga chapa),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikseli),
						'one' => q(megapikseli {0}),
						'other' => q(megapikseli {0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikseli),
						'one' => q(megapikseli {0}),
						'other' => q(megapikseli {0}),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q(pikseli {0}),
						'other' => q(pikseli {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q(pikseli {0}),
						'other' => q(pikseli {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pikseli kwa kila sentimita),
						'one' => q(pikseli {0} kwa kila sentimita),
						'other' => q(pikseli {0} kwa kila sentimita),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pikseli kwa kila sentimita),
						'one' => q(pikseli {0} kwa kila sentimita),
						'other' => q(pikseli {0} kwa kila sentimita),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pikseli kwa kila inchi),
						'one' => q(pikseli {0} kwa kila inchi),
						'other' => q(pikseli {0} kwa kila inchi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pikseli kwa kila inchi),
						'one' => q(pikseli {0} kwa kila inchi),
						'other' => q(pikseli {0} kwa kila inchi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q(kipimo {0} cha astronomia),
						'other' => q(vipimo {0} vya astronomia),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q(kipimo {0} cha astronomia),
						'other' => q(vipimo {0} vya astronomia),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(nusu kipenyo cha dunia),
						'one' => q(nusu kipenyo cha dunia {0}),
						'other' => q(nusu kipenyo cha dunia {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(nusu kipenyo cha dunia),
						'one' => q(nusu kipenyo cha dunia {0}),
						'other' => q(nusu kipenyo cha dunia {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q(fathom {0}),
						'other' => q(fathom {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q(fathom {0}),
						'other' => q(fathom {0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q(furlong {0}),
						'other' => q(furlong {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q(furlong {0}),
						'other' => q(furlong {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q(kilomita {0}),
						'other' => q(kilomita {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q(kilomita {0}),
						'other' => q(kilomita {0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q(miaka ya mwanga {0}),
						'other' => q(miaka ya mwanga {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q(miaka ya mwanga {0}),
						'other' => q(miaka ya mwanga {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(maili ya skandinavia),
						'one' => q(maili {0} ya skandinavia),
						'other' => q(maili {0} za skandinavia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(maili ya skandinavia),
						'one' => q(maili {0} ya skandinavia),
						'other' => q(maili {0} za skandinavia),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} kila sekunde),
						'other' => q({0} kila sekunde),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} kila sekunde),
						'other' => q({0} kila sekunde),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q(nusu kipenyo cha jua {0}),
						'other' => q(nusu vipenyo vya jua {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q(nusu kipenyo cha jua {0}),
						'other' => q(nusu vipenyo vya jua {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q(kandela {0}),
						'other' => q(kandela {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q(kandela {0}),
						'other' => q(kandela {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumeni),
						'one' => q(lumeni {0}),
						'other' => q(lumeni {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumeni),
						'one' => q(lumeni {0}),
						'other' => q(lumeni {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q(lux {0}),
						'other' => q(lux {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q(lux {0}),
						'other' => q(lux {0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q(ung'avu wa jua {0}),
						'other' => q(ung'avu wa jua {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q(ung'avu wa jua {0}),
						'other' => q(ung'avu wa jua {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q(daltoni {0}),
						'other' => q(daltoni {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q(daltoni {0}),
						'other' => q(daltoni {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q(uzito wa dunia {0}),
						'other' => q(uzito wa dunia {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q(uzito wa dunia {0}),
						'other' => q(uzito wa dunia {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q(kilogramu {0}),
						'other' => q(kilogramu {0}),
						'per' => q({0} kwa kila kilogramu),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q(kilogramu {0}),
						'other' => q(kilogramu {0}),
						'per' => q({0} kwa kila kilogramu),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q(miligramu {0}),
						'other' => q(miligramu {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q(miligramu {0}),
						'other' => q(miligramu {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'per' => q({0} kwa kila aunsi),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q({0} kwa kila aunsi),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} kwa kila ratili),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} kwa kila ratili),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q(uzito wa jua {0}),
						'other' => q(uzito wa jua {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q(uzito wa jua {0}),
						'other' => q(uzito wa jua {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q(jiwe {0}),
						'other' => q(mawe {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q(jiwe {0}),
						'other' => q(mawe {0}),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} kwa kila {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} kwa kila {1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q(kipimo cha hospawa {0}),
						'other' => q(kipimo cha hospawa {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q(kipimo cha hospawa {0}),
						'other' => q(kipimo cha hospawa {0}),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} mraba),
						'one' => q({0} mraba),
						'other' => q({0} mraba),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} mraba),
						'one' => q({0} mraba),
						'other' => q({0} mraba),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} mchemraba),
						'one' => q({0} mchemraba),
						'other' => q({0} mchemraba),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} mchemraba),
						'one' => q({0} mchemraba),
						'other' => q({0} mchemraba),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(kanieneo ya hewa),
						'one' => q(kanieneo {0}),
						'other' => q(kanieneo {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(kanieneo ya hewa),
						'one' => q(kanieneo {0}),
						'other' => q(kanieneo {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q(hektopaskali {0}),
						'other' => q(hektopaskali {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q(hektopaskali {0}),
						'other' => q(hektopaskali {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q(inchi {0} ya zebaki),
						'other' => q(inchi {0} za zebaki),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q(inchi {0} ya zebaki),
						'other' => q(inchi {0} za zebaki),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskali),
						'one' => q(kilopaskali {0}),
						'other' => q(kilopaskali {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskali),
						'one' => q(kilopaskali {0}),
						'other' => q(kilopaskali {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskali),
						'one' => q(megapaskali {0}),
						'other' => q(megapaskali {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskali),
						'one' => q(megapaskali {0}),
						'other' => q(megapaskali {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q(kipimo cha milibari {0}),
						'other' => q(kipimo cha milibari {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q(kipimo cha milibari {0}),
						'other' => q(kipimo cha milibari {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(milimita {0} ya zebaki),
						'other' => q(milimita {0} za zebaki),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(milimita {0} ya zebaki),
						'other' => q(milimita {0} za zebaki),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskali),
						'one' => q(paskali {0}),
						'other' => q(paskali {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskali),
						'one' => q(paskali {0}),
						'other' => q(paskali {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q(pauni {0} kwa kila inchi mraba),
						'other' => q(pauni {0} kwa kila inchi mraba),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q(pauni {0} kwa kila inchi mraba),
						'other' => q(pauni {0} kwa kila inchi mraba),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q(kilomita {0} kwa saa),
						'other' => q(kilomita {0} kwa saa),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q(kilomita {0} kwa saa),
						'other' => q(kilomita {0} kwa saa),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q(mita {0} kwa sekunde),
						'other' => q(mita {0} kwa sekunde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q(mita {0} kwa sekunde),
						'other' => q(mita {0} kwa sekunde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q(maili {0} kwa saa),
						'other' => q(maili {0} kwa saa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q(maili {0} kwa saa),
						'other' => q(maili {0} kwa saa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q(nyuzi {0}),
						'other' => q(nyuzi {0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q(nyuzi {0}),
						'other' => q(nyuzi {0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q(nyuzi za farenheiti {0}),
						'other' => q(nyuzi za farenheiti {0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q(nyuzi za farenheiti {0}),
						'other' => q(nyuzi za farenheiti {0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvini),
						'one' => q(kelvini {0}),
						'other' => q(kelvini {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvini),
						'one' => q(kelvini {0}),
						'other' => q(kelvini {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newtonimita),
						'one' => q(newtonimita {0}),
						'other' => q(newtonimita {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newtonimita),
						'one' => q(newtonimita {0}),
						'other' => q(newtonimita {0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(paunifuti),
						'one' => q(paunifuti {0}),
						'other' => q(paunifuti {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(paunifuti),
						'one' => q(paunifuti {0}),
						'other' => q(paunifuti {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(mapipa),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(mapipa),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q(busheli {0}),
						'other' => q(busheli {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q(busheli {0}),
						'other' => q(busheli {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q(sentimita {0} ya ujazo),
						'other' => q(sentimita {0} za ujazo),
						'per' => q({0} kwa kila sentimita ya ujazo),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q(sentimita {0} ya ujazo),
						'other' => q(sentimita {0} za ujazo),
						'per' => q({0} kwa kila sentimita ya ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q(futi {0} ya ujazo),
						'other' => q(futi {0} za ujazo),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q(futi {0} ya ujazo),
						'other' => q(futi {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q(inchi {0} ya ujazo),
						'other' => q(inchi {0} za ujazo),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q(inchi {0} ya ujazo),
						'other' => q(inchi {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q(kilomita {0} ya ujazo),
						'other' => q(kilomita {0} za ujazo),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q(kilomita {0} ya ujazo),
						'other' => q(kilomita {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q(mita {0} ya ujazo),
						'other' => q(mita {0} za ujazo),
						'per' => q({0} kwa kila mita ya ujazo),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q(mita {0} ya ujazo),
						'other' => q(mita {0} za ujazo),
						'per' => q({0} kwa kila mita ya ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q(maili {0} ya ujazo),
						'other' => q(maili {0} za ujazo),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q(maili {0} ya ujazo),
						'other' => q(maili {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q(yadi {0} ya ujazo),
						'other' => q(yadi {0} za ujazo),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q(yadi {0} ya ujazo),
						'other' => q(yadi {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q(kikombe {0} cha mizani),
						'other' => q(vikombe {0} vya mizani),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q(kikombe {0} cha mizani),
						'other' => q(vikombe {0} vya mizani),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(kijiko cha kitindamlo),
						'one' => q(kijiko {0} cha kitindamlo),
						'other' => q(vijiko {0} vya kitindamlo),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(kijiko cha kitindamlo),
						'one' => q(kijiko {0} cha kitindamlo),
						'other' => q(vijiko {0} vya kitindamlo),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Kijiko cha kitindamlo cha Uingireza),
						'one' => q(kijiko {0} cha kitindamlo cha Uingereza),
						'other' => q(vijiko {0} vya kitindamlo vya Uingereza),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Kijiko cha kitindamlo cha Uingireza),
						'one' => q(kijiko {0} cha kitindamlo cha Uingereza),
						'other' => q(vijiko {0} vya kitindamlo vya Uingereza),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dramu),
						'one' => q(dramu {0}),
						'other' => q(dramu {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dramu),
						'one' => q(dramu {0}),
						'other' => q(dramu {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q(aunsi {0} ya ujazo),
						'other' => q(aunsi {0} za ujazo),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q(aunsi {0} ya ujazo),
						'other' => q(aunsi {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(aunsi za ujazo za Uingereza),
						'one' => q(aunsi {0} ya ujazo ya Uingereza),
						'other' => q(aunsi {0} za ujazo za Uingereza),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(aunsi za ujazo za Uingereza),
						'one' => q(aunsi {0} ya ujazo ya Uingereza),
						'other' => q(aunsi {0} za ujazo za Uingereza),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} kwa kila galoni),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} kwa kila galoni),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q(painti {0} ya mizani),
						'other' => q(painti {0} za mizani),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q(painti {0} ya mizani),
						'other' => q(painti {0} za mizani),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kwati ya Uingereza),
						'one' => q(kwati {0} ya Uingereza),
						'other' => q(kwati {0} za Uingereza),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kwati ya Uingereza),
						'one' => q(kwati {0} ya Uingereza),
						'other' => q(kwati {0} za Uingereza),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q(kijiko {0} kikubwa),
						'other' => q(vijiko {0} vikubwa),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q(kijiko {0} kikubwa),
						'other' => q(vijiko {0} vikubwa),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q(kijiko {0} kidogo),
						'other' => q(vijiko {0} vidogo),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q(kijiko {0} kidogo),
						'other' => q(vijiko {0} vidogo),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q(Ekari {0}),
						'other' => q(Ekari {0}),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q(Ekari {0}),
						'other' => q(Ekari {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q(ha {0}),
						'other' => q(ha {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q(ha {0}),
						'other' => q(ha {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q(mi² {0}),
						'other' => q(mi² {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q(mi² {0}),
						'other' => q(mi² {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q(mmol {0}/L),
						'other' => q(mmol {0}/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q(mmol {0}/L),
						'other' => q(mmol {0}/L),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q(L/100km {0}),
						'other' => q(L/100km {0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q(L/100km {0}),
						'other' => q(L/100km {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q(dak {0}),
						'other' => q(dak {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q(dak {0}),
						'other' => q(dak {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mwezi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mwezi),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q(sek {0}),
						'other' => q(sek {0}),
						'per' => q({0} kwa kila sek),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q(sek {0}),
						'other' => q(sek {0}),
						'per' => q({0} kwa kila sek),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(mwaka),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(mwaka),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh {0} kwa km 100),
						'other' => q(kWh {0} kwa km 100),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh {0} kwa km 100),
						'other' => q(kWh {0} kwa km 100),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q(cm {0}),
						'other' => q(cm {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q(cm {0}),
						'other' => q(cm {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm {0}),
						'other' => q(mm {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm {0}),
						'other' => q(mm {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q(Aunsi {0}),
						'other' => q(Aunsi {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q(Aunsi {0}),
						'other' => q(Aunsi {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q(Ratili {0}),
						'other' => q(Ratili {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q(Ratili {0}),
						'other' => q(Ratili {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q(Wati {0}),
						'other' => q(Wati {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q(Wati {0}),
						'other' => q(Wati {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q(m {0}/s),
						'other' => q(m {0}/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q(m {0}/s),
						'other' => q(m {0}/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q(mi {0}/saa),
						'other' => q(mi {0}/saa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q(mi {0}/saa),
						'other' => q(mi {0}/saa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(mwelekeo),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(mwelekeo),
					},
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
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(eksibi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksibi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(de{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(de{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hekta{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekta{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(mvuto wa graviti),
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(mvuto wa graviti),
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mita kwa kila sekunde mraba),
						'one' => q(m {0}/s²),
						'other' => q(m {0}/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mita kwa kila sekunde mraba),
						'one' => q(m {0}/s²),
						'other' => q(m {0}/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiani),
						'one' => q(radiani {0}),
						'other' => q(radiani {0}),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiani),
						'one' => q(radiani {0}),
						'other' => q(radiani {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(mzunguko),
						'one' => q(raundi {0}),
						'other' => q(raundi {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(mzunguko),
						'one' => q(raundi {0}),
						'other' => q(raundi {0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ekari),
						'one' => q(ekari {0}),
						'other' => q(ekari {0}),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekari),
						'one' => q(ekari {0}),
						'other' => q(ekari {0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunamu),
						'one' => q(dunamu {0}),
						'other' => q(dunamu {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunamu),
						'one' => q(dunamu {0}),
						'other' => q(dunamu {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hekta),
						'one' => q(hekta {0}),
						'other' => q(hekta {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hekta),
						'one' => q(hekta {0}),
						'other' => q(hekta {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimita za mraba),
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimita za mraba),
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(futi za mraba),
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(futi za mraba),
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inchi za mraba),
						'one' => q(in² {0}),
						'other' => q(in² {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inchi za mraba),
						'one' => q(in² {0}),
						'other' => q(in² {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilomita za mraba),
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilomita za mraba),
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mita za mraba),
						'one' => q(m² {0}),
						'other' => q(m² {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mita za mraba),
						'one' => q(m² {0}),
						'other' => q(m² {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(maili za mraba),
						'one' => q(sq mi {0}),
						'other' => q(sq mi {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(maili za mraba),
						'one' => q(sq mi {0}),
						'other' => q(sq mi {0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yadi za mraba),
						'one' => q(yd² {0}),
						'other' => q(yd² {0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yadi za mraba),
						'one' => q(yd² {0}),
						'other' => q(yd² {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(kipengee),
						'one' => q(kipengee {0}),
						'other' => q(vipengee {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(kipengee),
						'one' => q(kipengee {0}),
						'other' => q(vipengee {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimoli kwa kila lita),
						'one' => q(mmol {0}/lita),
						'other' => q(mmol {0}/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimoli kwa kila lita),
						'one' => q(mmol {0}/lita),
						'other' => q(mmol {0}/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moli),
						'one' => q(moli {0}),
						'other' => q(moli {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moli),
						'one' => q(moli {0}),
						'other' => q(moli {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(asilimia),
						'one' => q(asilimia {0}),
						'other' => q(asilimia {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(asilimia),
						'one' => q(asilimia {0}),
						'other' => q(asilimia {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(kwa elfu),
						'one' => q({0} kwa elfu),
						'other' => q({0} kwa elfu),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(kwa elfu),
						'one' => q({0} kwa elfu),
						'other' => q({0} kwa elfu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(sehemu kwa kila milioni),
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(sehemu kwa kila milioni),
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriadi),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriadi),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q(lita {0}/km 100),
						'other' => q(lita {0}/km 100),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q(lita {0}/km 100),
						'other' => q(lita {0}/km 100),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lita kwa kila kilomita),
						'one' => q(lita {0} kwa kilomita),
						'other' => q(lita {0} kwa kilomita),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lita kwa kila kilomita),
						'one' => q(lita {0} kwa kilomita),
						'other' => q(lita {0} kwa kilomita),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(maili kwa kila galoni),
						'one' => q(mpg {0}),
						'other' => q(mpg {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(maili kwa kila galoni),
						'one' => q(mpg {0}),
						'other' => q(mpg {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q(mpg Imp. {0}),
						'other' => q(mpg Imp. {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q(mpg Imp. {0}),
						'other' => q(mpg Imp. {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Mashariki),
						'north' => q({0} Kaskazini),
						'south' => q({0} Kusini),
						'west' => q({0} Magharibi),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Mashariki),
						'north' => q({0} Kaskazini),
						'south' => q({0} Kusini),
						'west' => q({0} Magharibi),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(biti),
						'one' => q(biti {0}),
						'other' => q(biti {0}),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(biti),
						'one' => q(biti {0}),
						'other' => q(biti {0}),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(baiti),
						'one' => q(baiti {0}),
						'other' => q(baiti {0}),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(baiti),
						'one' => q(baiti {0}),
						'other' => q(baiti {0}),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabiti),
						'one' => q(gigabiti {0}),
						'other' => q(gigabiti {0}),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabiti),
						'one' => q(gigabiti {0}),
						'other' => q(gigabiti {0}),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q(GB {0}),
						'other' => q(GB {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q(GB {0}),
						'other' => q(GB {0}),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobiti),
						'one' => q(kilobiti {0}),
						'other' => q(kilobiti {0}),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobiti),
						'one' => q(kilobiti {0}),
						'other' => q(kilobiti {0}),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobaiti),
						'one' => q(kilobaiti {0}),
						'other' => q(kilobaiti {0}),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobaiti),
						'one' => q(kilobaiti {0}),
						'other' => q(kilobaiti {0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q(megabiti {0}),
						'other' => q(megabiti {0}),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q(megabiti {0}),
						'other' => q(megabiti {0}),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q(MB {0}),
						'other' => q(MB {0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q(MB {0}),
						'other' => q(MB {0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabaiti),
						'one' => q(PB {0}),
						'other' => q(PB {0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabaiti),
						'one' => q(PB {0}),
						'other' => q(PB {0}),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabiti),
						'one' => q(terabiti {0}),
						'other' => q(terabiti {0}),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabiti),
						'one' => q(terabiti {0}),
						'other' => q(terabiti {0}),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabaiti),
						'one' => q(terabaiti {0}),
						'other' => q(terabaiti {0}),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabaiti),
						'one' => q(terabaiti {0}),
						'other' => q(terabaiti {0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(karne),
						'one' => q(karne {0}),
						'other' => q(karne {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(karne),
						'one' => q(karne {0}),
						'other' => q(karne {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
						'per' => q({0} kwa siku),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
						'per' => q({0} kwa siku),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(miongo),
						'one' => q(mwongo {0}),
						'other' => q(miongo {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(miongo),
						'one' => q(mwongo {0}),
						'other' => q(miongo {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
						'per' => q({0} kwa saa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
						'per' => q({0} kwa saa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekunde),
						'one' => q(mikrosekunde {0}),
						'other' => q(mikrosekunde {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekunde),
						'one' => q(mikrosekunde {0}),
						'other' => q(mikrosekunde {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekunde),
						'one' => q(ms {0}),
						'other' => q(ms {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(ms {0}),
						'other' => q(ms {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
						'per' => q({0} kwa kila dakika),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
						'per' => q({0} kwa kila dakika),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(miezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
						'per' => q({0} kwa mwezi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(miezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
						'per' => q({0} kwa mwezi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekunde),
						'one' => q(nanosekunde {0}),
						'other' => q(nanosekunde {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekunde),
						'one' => q(nanosekunde {0}),
						'other' => q(nanosekunde {0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(robo),
						'one' => q(robo {0}),
						'other' => q(robo {0}),
						'per' => q({0} kwa robo),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(robo),
						'one' => q(robo {0}),
						'other' => q(robo {0}),
						'per' => q({0} kwa robo),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
						'per' => q({0} kwa kila sekunde),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
						'per' => q({0} kwa kila sekunde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
						'per' => q({0} kwa wiki),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
						'per' => q({0} kwa wiki),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(miaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
						'per' => q({0} kwa mwaka),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(miaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
						'per' => q({0} kwa mwaka),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampea),
						'one' => q(ampea {0}),
						'other' => q(ampea {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampea),
						'one' => q(ampea {0}),
						'other' => q(ampea {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampea),
						'one' => q(mA {0}),
						'other' => q(mA {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampea),
						'one' => q(mA {0}),
						'other' => q(mA {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volti),
						'one' => q(volti {0}),
						'other' => q(volti {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volti),
						'one' => q(volti {0}),
						'other' => q(volti {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q(Btu {0}),
						'other' => q(Btu {0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q(Btu {0}),
						'other' => q(Btu {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektrovolti),
						'one' => q(eV {0}),
						'other' => q(eV {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektrovolti),
						'one' => q(eV {0}),
						'other' => q(eV {0}),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jouli),
						'one' => q(jouli {0}),
						'other' => q(jouli {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jouli),
						'one' => q(jouli {0}),
						'other' => q(jouli {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q(kilokalori {0}),
						'other' => q(kilokalori {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q(kilokalori {0}),
						'other' => q(kilokalori {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojuli),
						'one' => q(kilojuli {0}),
						'other' => q(kilojuli {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojuli),
						'one' => q(kilojuli {0}),
						'other' => q(kilojuli {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowati kwa saa),
						'one' => q(kWh {0}),
						'other' => q(kWh {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowati kwa saa),
						'one' => q(kWh {0}),
						'other' => q(kWh {0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(kipimo cha gesi, Marekani),
						'one' => q(kipimo {0} cha gesi, US),
						'other' => q(vipimo {0} vya gesi, US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(kipimo cha gesi, Marekani),
						'one' => q(kipimo {0} cha gesi, US),
						'other' => q(vipimo {0} vya gesi, US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/km 100),
						'one' => q(kWh {0} /km 100),
						'other' => q(kWh {0} /km 100),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/km 100),
						'one' => q(kWh {0} /km 100),
						'other' => q(kWh {0} /km 100),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtoni),
						'one' => q(N {0}),
						'other' => q(N {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtoni),
						'one' => q(N {0}),
						'other' => q(N {0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(paunikani),
						'one' => q(lbf {0}),
						'other' => q(lbf {0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(paunikani),
						'one' => q(lbf {0}),
						'other' => q(lbf {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahezi),
						'one' => q(gigahezi {0}),
						'other' => q(gigahezi {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahezi),
						'one' => q(gigahezi {0}),
						'other' => q(gigahezi {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hezi),
						'one' => q(hezi {0}),
						'other' => q(hezi {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hezi),
						'one' => q(hezi {0}),
						'other' => q(hezi {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohezi),
						'one' => q(kilohezi {0}),
						'other' => q(kilohezi {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohezi),
						'one' => q(kilohezi {0}),
						'other' => q(kilohezi {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahezi),
						'one' => q(megahezi {0}),
						'other' => q(megahezi {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahezi),
						'one' => q(megahezi {0}),
						'other' => q(megahezi {0}),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(kitone),
						'one' => q(kitone {0}),
						'other' => q(vitone {0}),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(kitone),
						'one' => q(kitone {0}),
						'other' => q(vitone {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q(dpcm {0}),
						'other' => q(dpcm {0}),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q(dpcm {0}),
						'other' => q(dpcm {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q(dpi {0}),
						'other' => q(dpi {0}),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q(dpi {0}),
						'other' => q(dpi {0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q(em {0}),
						'other' => q(em {0}),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q(em {0}),
						'other' => q(em {0}),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q(MP {0}),
						'other' => q(MP {0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q(MP {0}),
						'other' => q(MP {0}),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikseli),
						'one' => q(px {0}),
						'other' => q(px {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikseli),
						'one' => q(px {0}),
						'other' => q(px {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q(ppcm {0}),
						'other' => q(ppcm {0}),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q(ppcm {0}),
						'other' => q(ppcm {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q(ppi {0}),
						'other' => q(ppi {0}),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q(ppi {0}),
						'other' => q(ppi {0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(vipimo vya astronomia),
						'one' => q(au {0}),
						'other' => q(au {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(vipimo vya astronomia),
						'one' => q(au {0}),
						'other' => q(au {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimita),
						'one' => q(sentimita {0}),
						'other' => q(sentimita {0}),
						'per' => q({0} kwa kila sentimita),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q(sentimita {0}),
						'other' => q(sentimita {0}),
						'per' => q({0} kwa kila sentimita),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimita),
						'one' => q(desimita {0}),
						'other' => q(desimita {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimita),
						'one' => q(desimita {0}),
						'other' => q(desimita {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q(R⊕ {0}),
						'other' => q(R⊕ {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q(R⊕ {0}),
						'other' => q(R⊕ {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
						'one' => q(fth {0}),
						'other' => q(fth {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
						'one' => q(fth {0}),
						'other' => q(fth {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(futi),
						'one' => q(futi {0}),
						'other' => q(futi {0}),
						'per' => q({0} kwa kila futi),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(futi),
						'one' => q(futi {0}),
						'other' => q(futi {0}),
						'per' => q({0} kwa kila futi),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q(fur {0}),
						'other' => q(fur {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q(fur {0}),
						'other' => q(fur {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inchi),
						'one' => q(inchi {0}),
						'other' => q(inchi {0}),
						'per' => q({0} kwa kila inchi),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inchi),
						'one' => q(inchi {0}),
						'other' => q(inchi {0}),
						'per' => q({0} kwa kila inchi),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomita),
						'one' => q(km {0}),
						'other' => q(km {0}),
						'per' => q({0} kwa kila kilomita),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomita),
						'one' => q(km {0}),
						'other' => q(km {0}),
						'per' => q({0} kwa kila kilomita),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(miaka ya mwanga),
						'one' => q(ly {0}),
						'other' => q(ly {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(miaka ya mwanga),
						'one' => q(ly {0}),
						'other' => q(ly {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q({0} kwa kila mita),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q({0} kwa kila mita),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(maili),
						'one' => q(maili {0}),
						'other' => q(maili {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(maili),
						'one' => q(maili {0}),
						'other' => q(maili {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q(smi {0}),
						'other' => q(smi {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q(smi {0}),
						'other' => q(smi {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(maili za kibaharia),
						'one' => q(maili {0} ya kibaharia),
						'other' => q(maili {0} za kibaharia),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(maili za kibaharia),
						'one' => q(maili {0} ya kibaharia),
						'other' => q(maili {0} za kibaharia),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(kila sekunde),
						'one' => q(pc {0}),
						'other' => q(pc {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(kila sekunde),
						'one' => q(pc {0}),
						'other' => q(pc {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pointi),
						'one' => q(pointi {0}),
						'other' => q(pointi {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pointi),
						'one' => q(pointi {0}),
						'other' => q(pointi {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(nusu vipenyo vya jua),
						'one' => q(R☉ {0}),
						'other' => q(R☉ {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(nusu vipenyo vya jua),
						'one' => q(R☉ {0}),
						'other' => q(R☉ {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yadi),
						'one' => q(yadi {0}),
						'other' => q(yadi {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yadi),
						'one' => q(yadi {0}),
						'other' => q(yadi {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q(cd {0}),
						'other' => q(cd {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q(cd {0}),
						'other' => q(cd {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q(lm {0}),
						'other' => q(lm {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q(lm {0}),
						'other' => q(lm {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q(lx {0}),
						'other' => q(lx {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q(lx {0}),
						'other' => q(lx {0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(ung’avu wa jua),
						'one' => q(L☉ {0}),
						'other' => q(L☉ {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(ung’avu wa jua),
						'one' => q(L☉ {0}),
						'other' => q(L☉ {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltoni),
						'one' => q(Da {0}),
						'other' => q(Da {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltoni),
						'one' => q(Da {0}),
						'other' => q(Da {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(uzito wa dunia),
						'one' => q(M⊕ {0}),
						'other' => q(M⊕ {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(uzito wa dunia),
						'one' => q(M⊕ {0}),
						'other' => q(M⊕ {0}),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(nafaka),
						'one' => q(nafaka {0}),
						'other' => q(nafaka {0}),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(nafaka),
						'one' => q(nafaka {0}),
						'other' => q(nafaka {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
						'per' => q({0} kwa kila gramu),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
						'per' => q({0} kwa kila gramu),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kg {0}),
						'other' => q(kg {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kg {0}),
						'other' => q(kg {0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogramu),
						'one' => q(mikrogramu {0}),
						'other' => q(mikrogramu {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogramu),
						'one' => q(mikrogramu {0}),
						'other' => q(mikrogramu {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligramu),
						'one' => q(mg {0}),
						'other' => q(mg {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligramu),
						'one' => q(mg {0}),
						'other' => q(mg {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(aunsi),
						'one' => q(aunsi {0}),
						'other' => q(aunsi {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(aunsi),
						'one' => q(aunsi {0}),
						'other' => q(aunsi {0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(tola aunsi),
						'one' => q(tola aunsi {0}),
						'other' => q(tola aunsi {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(tola aunsi),
						'one' => q(tola aunsi {0}),
						'other' => q(tola aunsi {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ratili),
						'one' => q(ratili {0}),
						'other' => q(ratili {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ratili),
						'one' => q(ratili {0}),
						'other' => q(ratili {0}),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(uzito wa jua),
						'one' => q(M☉ {0}),
						'other' => q(M☉ {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(uzito wa jua),
						'one' => q(M☉ {0}),
						'other' => q(M☉ {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(mawe),
						'one' => q(st {0}),
						'other' => q(st {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(mawe),
						'one' => q(st {0}),
						'other' => q(st {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tani fupi),
						'one' => q(tani fupi {0}),
						'other' => q(tani fupi {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tani fupi),
						'one' => q(tani fupi {0}),
						'other' => q(tani fupi {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tani mita),
						'one' => q(tani mita {0}),
						'other' => q(tani mita {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tani mita),
						'one' => q(tani mita {0}),
						'other' => q(tani mita {0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawati),
						'one' => q(gigawati {0}),
						'other' => q(gigawati {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawati),
						'one' => q(gigawati {0}),
						'other' => q(gigawati {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kipimo cha hospawa),
						'one' => q(hp {0}),
						'other' => q(hp {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kipimo cha hospawa),
						'one' => q(hp {0}),
						'other' => q(hp {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowati),
						'one' => q(kilowati {0}),
						'other' => q(kilowati {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowati),
						'one' => q(kilowati {0}),
						'other' => q(kilowati {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawati),
						'one' => q(megawati {0}),
						'other' => q(megawati {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawati),
						'one' => q(megawati {0}),
						'other' => q(megawati {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwati),
						'one' => q(miliwati {0}),
						'other' => q(miliwati {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwati),
						'one' => q(miliwati {0}),
						'other' => q(miliwati {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(wati),
						'one' => q(wati {0}),
						'other' => q(wati {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(wati),
						'one' => q(wati {0}),
						'other' => q(wati {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q(atm {0}),
						'other' => q(atm {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q(atm {0}),
						'other' => q(atm {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bari),
						'one' => q(bari {0}),
						'other' => q(bari {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bari),
						'one' => q(bari {0}),
						'other' => q(bari {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskali),
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskali),
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inchi za zebaki),
						'one' => q(inHg {0}),
						'other' => q(inHg {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inchi za zebaki),
						'one' => q(inHg {0}),
						'other' => q(inHg {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q(kPa {0}),
						'other' => q(kPa {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q(kPa {0}),
						'other' => q(kPa {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q(MPa {0}),
						'other' => q(MPa {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q(MPa {0}),
						'other' => q(MPa {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(kipimo cha milibari),
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(kipimo cha milibari),
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimita za zebaki),
						'one' => q(mmHg {0}),
						'other' => q(mmHg {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimita za zebaki),
						'one' => q(mmHg {0}),
						'other' => q(mmHg {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pauni kwa kila inchi mraba),
						'one' => q(psi {0}),
						'other' => q(psi {0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pauni kwa kila inchi mraba),
						'one' => q(psi {0}),
						'other' => q(psi {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(km {0}/saa),
						'other' => q(km {0}/saa),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(km {0}/saa),
						'other' => q(km {0}/saa),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(noti),
						'one' => q(noti {0}),
						'other' => q(noti {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(noti),
						'one' => q(noti {0}),
						'other' => q(noti {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mita kwa kila sekunde),
						'one' => q(m/s {0}),
						'other' => q(m/s {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mita kwa kila sekunde),
						'one' => q(m/s {0}),
						'other' => q(m/s {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(maili kwa kila saa),
						'one' => q(mph {0}),
						'other' => q(mph {0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(maili kwa kila saa),
						'one' => q(mph {0}),
						'other' => q(mph {0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(nyuzi),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(nyuzi),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(nyuzi za farenheiti),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(nyuzi za farenheiti),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q(N⋅m {0}),
						'other' => q(N⋅m {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q(N⋅m {0}),
						'other' => q(N⋅m {0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q(lbf⋅ft {0}),
						'other' => q(lbf⋅ft {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q(lbf⋅ft {0}),
						'other' => q(lbf⋅ft {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ekari futi),
						'one' => q(ekari futi {0}),
						'other' => q(ekari futi {0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ekari futi),
						'one' => q(ekari futi {0}),
						'other' => q(ekari futi {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(pipa),
						'one' => q(pipa {0}),
						'other' => q(mapipa {0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(pipa),
						'one' => q(pipa {0}),
						'other' => q(mapipa {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(busheli),
						'one' => q(bu {0}),
						'other' => q(bu {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(busheli),
						'one' => q(bu {0}),
						'other' => q(bu {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentilita),
						'one' => q(sentilita {0}),
						'other' => q(sentilita {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentilita),
						'one' => q(sentilita {0}),
						'other' => q(sentilita {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sentimita za ujazo),
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentimita za ujazo),
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(futi za ujazo),
						'one' => q(ft³ {0}),
						'other' => q(ft³ {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(futi za ujazo),
						'one' => q(ft³ {0}),
						'other' => q(ft³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inchi za ujazo),
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inchi za ujazo),
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilomita za ujazo),
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilomita za ujazo),
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mita za ujazo),
						'one' => q(m³ {0}),
						'other' => q(mita {0} za ujazo),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mita za ujazo),
						'one' => q(m³ {0}),
						'other' => q(mita {0} za ujazo),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(maili za ujazo),
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(maili za ujazo),
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yadi za ujazo),
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yadi za ujazo),
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(vikombe),
						'one' => q(kikombe {0}),
						'other' => q(vikombe {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(vikombe),
						'one' => q(kikombe {0}),
						'other' => q(vikombe {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(vikombe vya mizani),
						'one' => q(mc {0}),
						'other' => q(vikombe {0} vya mizani),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(vikombe vya mizani),
						'one' => q(mc {0}),
						'other' => q(vikombe {0} vya mizani),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilita),
						'one' => q(desilita {0}),
						'other' => q(desilita {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilita),
						'one' => q(desilita {0}),
						'other' => q(desilita {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q(dstspn {0}),
						'other' => q(dstspn {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q(dstspn {0}),
						'other' => q(dstspn {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q(dstspn Imp {0}),
						'other' => q(dstspn Imp {0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q(dstspn Imp {0}),
						'other' => q(dstspn Imp {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ujazo wa dramu),
						'one' => q(ujazo wa dramu {0}),
						'other' => q(ujazo wa dramu {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ujazo wa dramu),
						'one' => q(ujazo wa dramu {0}),
						'other' => q(ujazo wa dramu {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tone),
						'one' => q(tone {0}),
						'other' => q(matone {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tone),
						'one' => q(tone {0}),
						'other' => q(matone {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(aunsi za ujazo),
						'one' => q(fl oz {0}),
						'other' => q(fl oz {0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(aunsi za ujazo),
						'one' => q(fl oz {0}),
						'other' => q(fl oz {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q(fl oz Imp. {0}),
						'other' => q(fl oz Imp. {0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q(fl oz Imp. {0}),
						'other' => q(fl oz Imp. {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galoni),
						'one' => q(galoni {0}),
						'other' => q(galoni {0}),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galoni),
						'one' => q(galoni {0}),
						'other' => q(galoni {0}),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q(gal Imp. {0}),
						'other' => q(gal Imp. {0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q(gal Imp. {0}),
						'other' => q(gal Imp. {0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolita),
						'one' => q(hektolita {0}),
						'other' => q(hektolita {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolita),
						'one' => q(hektolita {0}),
						'other' => q(hektolita {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(toti),
						'one' => q(toti {0}),
						'other' => q(toti {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(toti),
						'one' => q(toti {0}),
						'other' => q(toti {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
						'per' => q({0} kwa kila lita),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
						'per' => q({0} kwa kila lita),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalita),
						'one' => q(megalita {0}),
						'other' => q(megalita {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalita),
						'one' => q(megalita {0}),
						'other' => q(megalita {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililita),
						'one' => q(mililita {0}),
						'other' => q(mililita {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililita),
						'one' => q(mililita {0}),
						'other' => q(mililita {0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(mfinyo kwa vidole),
						'one' => q(mfinyo {0} kwa vidole),
						'other' => q(mifinyo {0} kwa vidole),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(mfinyo kwa vidole),
						'one' => q(mfinyo {0} kwa vidole),
						'other' => q(mifinyo {0} kwa vidole),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(painti),
						'one' => q(painti {0}),
						'other' => q(painti {0}),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(painti),
						'one' => q(painti {0}),
						'other' => q(painti {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(painti za mizani),
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(painti za mizani),
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kwati),
						'one' => q(kwati {0}),
						'other' => q(kwati {0}),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kwati),
						'one' => q(kwati {0}),
						'other' => q(kwati {0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q(qt Imp. {0}),
						'other' => q(qt Imp. {0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q(qt Imp. {0}),
						'other' => q(qt Imp. {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(vijiko vikubwa),
						'one' => q(tbsp {0}),
						'other' => q(tbsp {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(vijiko vikubwa),
						'one' => q(tbsp {0}),
						'other' => q(tbsp {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(vijiko vidogo),
						'one' => q(tsp {0}),
						'other' => q(tsp {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(vijiko vidogo),
						'one' => q(tsp {0}),
						'other' => q(tsp {0}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ndiyo|N|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hapana|H)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} na {1}),
				2 => q({0} na {1}),
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
					'one' => 'elfu 0;elfu -0',
					'other' => 'elfu 0;elfu -0',
				},
				'10000' => {
					'one' => 'elfu 00;elfu -00',
					'other' => 'elfu 00;elfu -00',
				},
				'100000' => {
					'one' => 'elfu 000;elfu -000',
					'other' => 'elfu 000;elfu -000',
				},
				'1000000' => {
					'one' => 'milioni 0;milioni -0',
					'other' => 'milioni 0;milioni -0',
				},
				'10000000' => {
					'one' => 'milioni 00;milioni -00',
					'other' => 'milioni 00;milioni -00',
				},
				'100000000' => {
					'one' => 'milioni 000;milioni -000',
					'other' => 'milioni 000;milioni -000',
				},
				'1000000000' => {
					'one' => 'bilioni 0;bilioni -0',
					'other' => 'bilioni 0;bilioni -0',
				},
				'10000000000' => {
					'one' => 'bilioni 00;bilioni -00',
					'other' => 'bilioni 00;bilioni -00',
				},
				'100000000000' => {
					'one' => 'bilioni 000;bilioni -000',
					'other' => 'bilioni 000;bilioni -000',
				},
				'1000000000000' => {
					'one' => 'trilioni 0;trilioni -0',
					'other' => 'trilioni 0;trilioni -0',
				},
				'10000000000000' => {
					'one' => 'trilioni 00;trilioni -00',
					'other' => 'trilioni 00;trilioni -00',
				},
				'100000000000000' => {
					'one' => 'trilioni 000;trilioni -000',
					'other' => 'trilioni 000;trilioni -000',
				},
			},
			'short' => {
				'1000' => {
					'one' => 'elfu 0;elfu -0',
					'other' => 'elfu 0;elfu -0',
				},
				'10000' => {
					'one' => 'elfu 00;elfu -00',
					'other' => 'elfu 00;elfu -00',
				},
				'100000' => {
					'one' => 'elfu 000;elfu -000',
					'other' => 'elfu 000;elfu -000',
				},
				'1000000' => {
					'one' => '0M;-0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M;-00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M;-000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0B;-0B',
					'other' => '0B;-0B',
				},
				'10000000000' => {
					'one' => '00B;-00B',
					'other' => '00B;-00B',
				},
				'100000000000' => {
					'one' => '000B;-000B',
					'other' => '000B;-000B',
				},
				'1000000000000' => {
					'one' => '0T;-0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T;-00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T;-000T',
					'other' => '000T',
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
				'currency' => q(Dirham ya Falme za Kiarabu),
				'one' => q(dirham ya Falme za Kiarabu),
				'other' => q(dirham za Falme za Kiarabu),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani ya Afghanistan),
				'one' => q(afghani ya Afghanistan),
				'other' => q(afghani za Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek ya Albania),
				'one' => q(lek ya Albania),
				'other' => q(lek za Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram ya Armenia),
				'one' => q(dram ya Armenia),
				'other' => q(dram za Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder ya Antili za Kiholanzi),
				'one' => q(guilder ya Antili za Kiholanzi),
				'other' => q(guilder za Antili za Kiholanzi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza ya Angola),
				'one' => q(kwanza ya Angola),
				'other' => q(kwanza za Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso ya Ajentina),
				'one' => q(peso ya Ajentina),
				'other' => q(peso za Ajentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dola ya Australia),
				'one' => q(dola ya Australia),
				'other' => q(dola za Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin ya Aruba),
				'one' => q(florin ya Aruba),
				'other' => q(florin za Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat ya Azerbaijan),
				'one' => q(manat ya Azerbaijan),
				'other' => q(manat za Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Convertible Mark ya Bosnia na Hezegovina),
				'one' => q(convertible mark ya Bosnia na Hezegovina),
				'other' => q(convertible mark za Bosnia na Hezegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dola ya Barbados),
				'one' => q(dola ya Barbados),
				'other' => q(dola za Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka ya Bangladesh),
				'one' => q(taka ya Bangladesh),
				'other' => q(taka za Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev ya Bulgaria),
				'one' => q(lev ya Bulgaria),
				'other' => q(lev za Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinari ya Bahareni),
				'one' => q(dinari ya Bahareni),
				'other' => q(dinari za Bahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faranga ya Burundi),
				'one' => q(faranga ya Burundi),
				'other' => q(faranga za Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dola ya Bermuda),
				'one' => q(dola ya Bermuda),
				'other' => q(dola za Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dola ya Brunei),
				'one' => q(dola ya Brunei),
				'other' => q(dola za Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano ya Bolivia),
				'one' => q(Boliviano ya Bolivia),
				'other' => q(Boliviano za Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real ya Brazil),
				'one' => q(Real ya Brazil),
				'other' => q(Real za Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dola ya Bahamas),
				'one' => q(dola ya Bahamas),
				'other' => q(dola za Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum ya Bhutan),
				'one' => q(ngultrum ya Bhutan),
				'other' => q(ngultrum za Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ya Botswana),
				'one' => q(pula ya Botswana),
				'other' => q(pula za Botswana),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Ruble ya Belarus),
				'one' => q(ruble ya Belarus),
				'other' => q(ruble za Belarus),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Ruble ya Belarusi \(2000–2016\)),
				'one' => q(Ruble ya Belarusi \(2000–2016\)),
				'other' => q(Ruble za Belarusi \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dola ya Belize),
				'one' => q(dola ya Belize),
				'other' => q(dola za Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola ya Canada),
				'one' => q(dola ya Canada),
				'other' => q(dola za Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranga ya Kongo),
				'one' => q(faranga ya Kongo),
				'other' => q(faranga za Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranga ya Uswisi),
				'one' => q(faranga ya Uswisi),
				'other' => q(faranga za Uswisi),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso ya Chile),
				'one' => q(Peso ya Chile),
				'other' => q(Peso za Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan ya Uchina \(huru\)),
				'one' => q(yuan ya Uchina \(huru\)),
				'other' => q(yuan za Uchina \(huru\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan ya Uchina),
				'one' => q(yuan ya Uchina),
				'other' => q(yuan za Uchina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso ya Kolombia),
				'one' => q(peso ya Kolombia),
				'other' => q(peso za Kolombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon ya Kostarika),
				'one' => q(colon ya Kostarika),
				'other' => q(colon za Kostarika),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso ya Kuba Inayoweza Kubadilishwa),
				'one' => q(peso ya Kuba inayoweza kubadilishwa),
				'other' => q(peso za Kuba zinazoweza kubadilishwa),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso ya Kuba),
				'one' => q(peso ya Kuba),
				'other' => q(peso za Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Eskudo ya Cape Verde),
				'one' => q(eskudo ya Cape Verde),
				'other' => q(eskudo za Cape Verde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna ya Jamhuri ya Czech),
				'one' => q(koruna ya Jamhuri ya Czech),
				'other' => q(koruna za Jamhuri ya Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faranga ya Jibuti),
				'one' => q(faranga ya Jibuti),
				'other' => q(faranga za Jibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone ya Denmark),
				'one' => q(krone ya Denmark),
				'other' => q(krone za Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso ya Dominika),
				'one' => q(peso ya Dominika),
				'other' => q(peso za Dominika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar ya Aljeria),
				'one' => q(dinar ya Aljeria),
				'other' => q(dinar za Aljeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pauni ya Misri),
				'one' => q(pauni ya Misri),
				'other' => q(pauni za Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa ya Eritrea),
				'one' => q(nakfa ya Eritrea),
				'other' => q(nakfa za Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr ya Uhabeshi),
				'one' => q(birr ya Uhabeshi),
				'other' => q(birr za Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
				'one' => q(yuro),
				'other' => q(yuro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dola ya Fiji),
				'one' => q(dola ya Fiji),
				'other' => q(dola za Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pauni ya Visiwa vya Falkland),
				'one' => q(Pauni ya Visiwa vya Falkland),
				'other' => q(Pauni za Visiwa vya Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pauni ya Uingereza),
				'one' => q(pauni ya Uingereza),
				'other' => q(pauni za Uingereza),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari ya Jojia),
				'one' => q(lari ya Jojia),
				'other' => q(lari za Jojia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Ghana),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi ya Ghana),
				'one' => q(cedi ya Ghana),
				'other' => q(cedi za Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pauni ya Gibraltar),
				'one' => q(pauni ya Gibraltar),
				'other' => q(pauni za Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ya Gambia),
				'one' => q(dalasi ya Gambia),
				'other' => q(dalasi za Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Faranga ya Guinea),
				'one' => q(faranga ya Guinea),
				'other' => q(faranga za Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ya Gine),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal ya Guatemala),
				'one' => q(quetzal ya Guatemala),
				'other' => q(quetzal za Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dola ya Guyana),
				'one' => q(dola ya Guyana),
				'other' => q(dola za Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dola ya Hong Kong),
				'one' => q(dola ya Hong Kong),
				'other' => q(dola za Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira ya Hondurasi),
				'one' => q(lempira ya Hondurasi),
				'other' => q(lempira za Hondurasi),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna ya Korasia),
				'one' => q(kuna ya Korasia),
				'other' => q(kuna za Korasia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde ya Haiti),
				'one' => q(gourde ya Haiti),
				'other' => q(gourde za Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint ya Hungaria),
				'one' => q(forint ya Hungaria),
				'other' => q(forint za Hungaria),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah ya Indonesia),
				'one' => q(rupiah ya Indonesia),
				'other' => q(rupiah za Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Shekeli Mpya ya Israel),
				'one' => q(shekeli mpya ya Israel),
				'other' => q(shekeli mpya za Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia ya India),
				'one' => q(rupia ya India),
				'other' => q(rupia za India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinari ya Iraki),
				'one' => q(dinari ya Iraki),
				'other' => q(dinari za Iraki),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial ya Iran),
				'one' => q(rial ya Iran),
				'other' => q(rial za Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Krona ya Aisilandi),
				'one' => q(krona ya Aisilandi),
				'other' => q(krona za Aisilandi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dola ya Jamaika),
				'one' => q(dola ya Jamaika),
				'other' => q(dola za Jamaika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinari ya Jordan),
				'one' => q(dinari ya Jordan),
				'other' => q(dinari za Jordan),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen ya Japani),
				'one' => q(yen ya Japani),
				'other' => q(yen za Japani),
			},
		},
		'KES' => {
			symbol => 'Ksh',
			display_name => {
				'currency' => q(Shilingi ya Kenya),
				'one' => q(shilingi ya Kenya),
				'other' => q(shilingi za Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som ya Kyrgystan),
				'one' => q(som ya Kyrgystan),
				'other' => q(som za Kyrgystan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel ya Kambodia),
				'one' => q(riel ya Kambodia),
				'other' => q(riel za Kambodia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranga ya Komoro),
				'one' => q(faranga ya Komoro),
				'other' => q(faranga za Komoro),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won ya Korea Kaskazini),
				'one' => q(won ya Korea Kaskazini),
				'other' => q(won za Korea Kaskazini),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won ya Korea Kusini),
				'one' => q(won ya Korea Kusini),
				'other' => q(won za Korea Kusini),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinari ya Kuwait),
				'one' => q(dinari ya Kuwait),
				'other' => q(dinari za Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dola ya Visiwa vya Cayman),
				'one' => q(dola ya Visiwa vya Cayman),
				'other' => q(dola za Visiwa vya Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge ya Kazakhstan),
				'one' => q(tenge ya Kazakhstan),
				'other' => q(tenge za Kazakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip ya Laosi),
				'one' => q(kip ya Laosi),
				'other' => q(kip za Laosi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pauni ya Lebanon),
				'one' => q(pauni ya Lebanon),
				'other' => q(pauni za Lebanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupia ya Sri Lanka),
				'one' => q(rupia ya Sri Lanka),
				'other' => q(rupia za Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola ya Liberia),
				'one' => q(dola ya Liberia),
				'other' => q(dola za Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesoto),
				'one' => q(Loti za Lesoto),
				'other' => q(Loti za Lesoto),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas ya Lithuania),
				'one' => q(Litas ya Lithuania),
				'other' => q(Litas za Lithuania),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats ya Lativia),
				'one' => q(Lats ya Lativia),
				'other' => q(Lats za Lativia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinari ya Libya),
				'one' => q(dinari ya Libya),
				'other' => q(dinari za Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham ya Moroko),
				'one' => q(dirham ya Moroko),
				'other' => q(dirham za Moroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu ya Moldova),
				'one' => q(leu ya Moldova),
				'other' => q(leu za Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariari ya Madagaska),
				'one' => q(ariari ya Madagaska),
				'other' => q(ariari za Madagaska),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar ya Masedonia),
				'one' => q(denar ya Masedonia),
				'other' => q(denar za Masedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat ya Myanmar),
				'one' => q(kyat ya Myanmar),
				'other' => q(kyat za Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik ya Mongolia),
				'one' => q(tugrik ya Mongolia),
				'other' => q(tugrik za Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca ya Macau),
				'one' => q(pataca ya Macau),
				'other' => q(pataca za Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya ya Mauritania \(1973–2017\)),
				'one' => q(ouguiya ya Mauritania \(1973–2017\)),
				'other' => q(ouguiya za Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya ya Moritania),
				'one' => q(ouguiya ya Moritania),
				'other' => q(ouguiya za Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia ya Morisi),
				'one' => q(rupia ya Morisi),
				'other' => q(rupia za Morisi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa ya Maldives),
				'one' => q(rufiyaa ya Maldives),
				'other' => q(rufiyaa za Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha ya Malawi),
				'one' => q(kwacha ya Malawi),
				'other' => q(kwacha za Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso ya Meksiko),
				'one' => q(peso ya Meksiko),
				'other' => q(peso za Meksiko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit ya Malaysia),
				'one' => q(ringgit ya Malaysia),
				'other' => q(ringgit za Malaysia),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali ya Msumbiji \(1980–2006\)),
				'one' => q(metikali ya Msumbiji \(1980–2006\)),
				'other' => q(metikali ya Msumbiji \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metikali ya Msumbiji),
				'one' => q(metikali ya Msumbiji),
				'other' => q(metikali za Msumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dola ya Namibia),
				'one' => q(dola ya Namibia),
				'other' => q(dola za Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Nigeria),
				'one' => q(naira ya Nigeria),
				'other' => q(naira za Nigeria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba ya Nikaragwa),
				'one' => q(cordoba ya Nikaragwa),
				'other' => q(cordoba za Nikaragwa),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone ya Norwe),
				'one' => q(krone ya Norwe),
				'other' => q(krone za Norwe),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupia ya Nepal),
				'one' => q(rupia ya Nepal),
				'other' => q(rupia za Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dola ya Nyuzilandi),
				'one' => q(dola ya Nyuzilandi),
				'other' => q(dola za Nyuzilandi),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial ya Omani),
				'one' => q(rial ya Omani),
				'other' => q(rial za Omani),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa ya Panama),
				'one' => q(balboa ya Panama),
				'other' => q(balboa ya Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol ya Peru),
				'one' => q(sol ya Peru),
				'other' => q(sol za Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina ya Papua New Guinea),
				'one' => q(kina ya Papua New Guinea),
				'other' => q(kina za Papua New Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso ya Ufilipino),
				'one' => q(peso ya Ufilipino),
				'other' => q(peso za Ufilipino),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupia ya Pakistan),
				'one' => q(rupia ya Pakistan),
				'other' => q(rupia za Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty ya Poland),
				'one' => q(zloty ya Poland),
				'other' => q(zloty za Poland),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani ya Paragwai),
				'one' => q(guarani ya Paragwai),
				'other' => q(guarani za Paragwai),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial ya Qatar),
				'one' => q(rial ya Qatar),
				'other' => q(rial ya Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu ya Romania),
				'one' => q(leu ya Romania),
				'other' => q(leu za Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar ya Serbia),
				'one' => q(dinar ya Serbia),
				'other' => q(dinar za Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruble ya Urusi),
				'one' => q(ruble ya Urusi),
				'other' => q(ruble za Urusi),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faranga ya Rwanda),
				'one' => q(faranga ya Rwanda),
				'other' => q(faranga za Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal ya Saudia),
				'one' => q(riyal ya Saudia),
				'other' => q(riyal za Saudia),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dola ya Visiwa vya Solomon),
				'one' => q(dola ya Visiwa vya Solomon),
				'other' => q(dola za Visiwa vya Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia ya Ushelisheli),
				'one' => q(rupia ya Ushelisheli),
				'other' => q(rupia za Ushelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pauni ya Sudan),
				'one' => q(pauni ya Sudan),
				'other' => q(pauni za Sudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pauni ya Sudani \(1957–1998\)),
				'one' => q(pauni ya Sudani \(1957–1998\)),
				'other' => q(pauni za Sudani \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona ya Uswidi),
				'one' => q(krona ya Uswidi),
				'other' => q(krona za Uswidi),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dola ya Singapore),
				'one' => q(dola ya Singapore),
				'other' => q(dola za Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pauni ya St. Helena),
				'one' => q(pauni ya St. Helena),
				'other' => q(pauni za St. Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone ya Siera Leoni),
				'one' => q(leone ya Siera Leoni),
				'other' => q(leone za Siera Leoni),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone ya Siera Leoni \(1964—2022\)),
				'one' => q(leone ya Siera Leoni \(1964—2022\)),
				'other' => q(leone za Siera Leoni \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilingi ya Somalia),
				'one' => q(shilingi ya Somalia),
				'other' => q(shilingi za Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dola ya Suriname),
				'one' => q(dola ya Suriname),
				'other' => q(dola za Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pauni ya Sudan Kusini),
				'one' => q(pauni ya Sudan Kusini),
				'other' => q(pauni za Sudan Kusini),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe \(1977–2017\)),
				'one' => q(dobra ya Sao Tome na Principe \(1977–2017\)),
				'other' => q(dobra za Sao Tome na Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe),
				'one' => q(dobra ya Sao Tome na Principe),
				'other' => q(dobra za Sao Tome na Principe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pauni ya Syria),
				'one' => q(pauni ya Syria),
				'other' => q(pauni za Syria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni ya Uswazi),
				'one' => q(lilangeni ya Uswazi),
				'other' => q(emalangeni za Uswazi),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht ya Tailandi),
				'one' => q(baht ya Tailandi),
				'other' => q(baht za Tailandi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni ya Tajikistan),
				'one' => q(somoni ya Tajikistan),
				'other' => q(somoni za Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat ya Turkmenistan),
				'one' => q(manat ya Turkmenistan),
				'other' => q(manat za Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinari ya Tunisia),
				'one' => q(dinari ya Tunisia),
				'other' => q(dinari za Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga ya Tonga),
				'one' => q(paʻanga ya Tonga),
				'other' => q(paʻanga za Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira ya Uturuki),
				'one' => q(lira ya Uturuki),
				'other' => q(lira za Uturuki),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dola ya Trinidad na Tobago),
				'one' => q(Dola ya Trinidad na Tobago),
				'other' => q(Dola za Trinidad na Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dola ya Taiwan),
				'one' => q(dola ya Taiwan),
				'other' => q(dola za Taiwan),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(Shilingi ya Tanzania),
				'one' => q(shilingi ya Tanzania),
				'other' => q(shilingi za Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia ya Ukraine),
				'one' => q(hryvnia ya Ukraine),
				'other' => q(hryvnia za Ukraine),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingi ya Uganda),
				'one' => q(shilingi ya Uganda),
				'other' => q(shilingi za Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dola ya Marekani),
				'one' => q(dola ya Marekani),
				'other' => q(dola za Marekani),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso ya Urugwai),
				'one' => q(peso ya Urugwai),
				'other' => q(peso za Urugwai),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som ya Uzbekistan),
				'one' => q(som ya Uzbekistan),
				'other' => q(som za Uzbekistan),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolivar ya Venezuela \(2008–2018\)),
				'one' => q(Bolivar ya Venezuela \(2008–2018\)),
				'other' => q(Bolivar za Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolivar ya Venezuela),
				'one' => q(bolivar ya Venezuela),
				'other' => q(bolivar za Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong ya Vietnam),
				'one' => q(dong ya Vietnam),
				'other' => q(dong za Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu ya Vanuatu),
				'one' => q(vatu ya Vanuatu),
				'other' => q(vatu za Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala ya Samoa),
				'one' => q(tala ya Samoa),
				'other' => q(tala za Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga ya Afrika ya Kati CFA),
				'one' => q(faranga ya Afrika ya Kati CFA),
				'other' => q(faranga za Afrika ya Kati CFA),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dola ya Karibi Mashariki),
				'one' => q(dola ya Karibi Mashariki),
				'other' => q(dola za Karibi Mashariki),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga ya Afrika Magharibi CFA),
				'one' => q(faranga ya Afrika Magharibi CFA),
				'other' => q(faranga za Afrika Magharibi CFA),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Faranga ya CFP),
				'one' => q(faranga ya CFP),
				'other' => q(faranga za CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Sarafu isiyojulikana),
				'one' => q(\(sarafu isiyojulikana\)),
				'other' => q(\(sarafu isiyojulikana\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial ya Yemen),
				'one' => q(rial ya Yemen),
				'other' => q(rial za Yemen),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi ya Afrika Kusini),
				'one' => q(randi ya Afrika Kusini),
				'other' => q(randi za Afrika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia),
				'one' => q(kwacha ya Zambia),
				'other' => q(kwacha za Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola ya Zimbabwe),
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
							'Feb',
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ago',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Machi',
							'Aprili',
							'Mei',
							'Juni',
							'Julai',
							'Agosti',
							'Septemba',
							'Oktoba',
							'Novemba',
							'Desemba'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
					wide => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
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
					wide => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{adhuhuri},
				},
				'narrow' => {
					'afternoon1' => q{mchana},
					'am' => q{am},
					'evening1' => q{jioni},
					'midnight' => q{usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{mchana},
					'pm' => q{pm},
				},
				'wide' => {
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{alasiri},
					'evening1' => q{jioni},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
				},
				'narrow' => {
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
				},
				'wide' => {
					'afternoon1' => q{mchana},
					'evening1' => q{jioni},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
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
				'0' => 'KK',
				'1' => 'BK'
			},
			wide => {
				'0' => 'Kabla ya Kristo',
				'1' => 'Baada ya Kristo'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, d/M/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'wiki' W 'ya' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQQ => q{QQQQ y},
			yw => q{'wiki' w 'ya' Y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
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
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(GMT {0}),
		regionFormat => q(Saa za {0}),
		regionFormat => q(Saa za Mchana za {0}),
		regionFormat => q(Saa za wastani za {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Saa za Afghanistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Saa za Afrika ya Kati#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Saa za Afrika Mashariki#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Saa za Wastani za Afrika Kusini#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Afrika Magharibi#,
				'generic' => q#Saa za Afrika Magharibi#,
				'standard' => q#Saa za Wastani za Afrika Magharibi#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Saa za Mchana za Alaska#,
				'generic' => q#Saa za Alaska#,
				'standard' => q#Saa za Wastani za Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Amazon#,
				'generic' => q#Saa za Amazon#,
				'standard' => q#Saa za Wastani za Amazon#,
			},
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciudad Juarez#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Jiji la Mexico#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Saa za Mchana za Kati#,
				'generic' => q#Saa za Kati#,
				'standard' => q#Saa za Wastani za Kati#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Saa za Mchana za Mashariki#,
				'generic' => q#Saa za Mashariki#,
				'standard' => q#Saa za Wastani za Mashariki#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Saa za Mchana za Mountain#,
				'generic' => q#Saa za Mountain#,
				'standard' => q#Saa za Wastani za Mountain#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Saa za Mchana za Pasifiki#,
				'generic' => q#Saa za Pasifiki#,
				'standard' => q#Saa za Wastani za Pasifiki#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Saa za Kiangazi za Anadyr#,
				'generic' => q#Saa za Anadyr#,
				'standard' => q#Saa za Wastani za Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Saa za Mchana za Apia#,
				'generic' => q#Saa za Apia#,
				'standard' => q#Saa za Wastani za Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Saa za Mchana za Arabiani#,
				'generic' => q#Saa za Uarabuni#,
				'standard' => q#Saa za Wastani za Uarabuni#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Argentina#,
				'generic' => q#Saa za Argentina#,
				'standard' => q#Saa za Wastani za Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Magharibi mwa Argentina#,
				'generic' => q#Saa za Magharibi mwa Argentina#,
				'standard' => q#Saa za Wastani za Magharibi mwa Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Armenia#,
				'generic' => q#Saa za Armenia#,
				'standard' => q#Saa za Wastani za Armenia#,
			},
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Saa za Mchana za Atlantiki#,
				'generic' => q#Saa za Atlantiki#,
				'standard' => q#Saa za Wastani za Atlantiki#,
			},
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia Kusini#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Saa za Mchana za Australia ya Kati#,
				'generic' => q#Saa za Australia ya Kati#,
				'standard' => q#Saa za Wastani za Australia ya Kati#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Saa za Mchana za Magharibi ya Kati ya Australia#,
				'generic' => q#Saa za Magharibi ya Kati ya Australia#,
				'standard' => q#Saa za Wastani za Magharibi ya Kati ya Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Saa za Mchana za Mashariki mwa Australia#,
				'generic' => q#Saa za Australia Mashariki#,
				'standard' => q#Saa za Wastani za Mashariki mwa Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Saa za Mchana za Australia Magharibi#,
				'generic' => q#Saa za Australia Magharibi#,
				'standard' => q#Saa za Wastani za Australia Magharibi#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Azerbaijan#,
				'generic' => q#Saa za Azerbaijan#,
				'standard' => q#Saa za Wastani za Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Azores#,
				'generic' => q#Saa za Azores#,
				'standard' => q#Saa za Wastani za Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Bangladesh#,
				'generic' => q#Saa za Bangladesh#,
				'standard' => q#Saa za Wastani za Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Saa za Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Saa za Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Brasilia#,
				'generic' => q#Saa za Brasilia#,
				'standard' => q#Saa za Wastani za Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Saa za Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Cape Verde#,
				'generic' => q#Saa za Cape Verde#,
				'standard' => q#Saa za Wastani za Cape Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Saa za Wastani za Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Saa za Mchana za Chatham#,
				'generic' => q#Saa za Chatham#,
				'standard' => q#Saa za Wastani za Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Chile#,
				'generic' => q#Saa za Chile#,
				'standard' => q#Saa za Wastani za Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Saa za Mchana za Uchina#,
				'generic' => q#Saa za Uchina#,
				'standard' => q#Saa za Wastani za Uchina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Choibalsan#,
				'generic' => q#Saa za Choibalsan#,
				'standard' => q#Saa za Wastani za Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Saa za Kisiwa cha Krismasi#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Saa za Visiwa vya Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Kolombia#,
				'generic' => q#Saa za Kolombia#,
				'standard' => q#Saa za Wastani za Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Saa za Majira nusu ya joto za Visiwa Cook#,
				'generic' => q#Saa za Visiwa vya Cook#,
				'standard' => q#Saa za Wastani za Visiwa vya Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Saa za Mchana za Kuba#,
				'generic' => q#Saa za Kuba#,
				'standard' => q#Saa za Wastani ya Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Saa za Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Saa za Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Saa za Timor Mashariki#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Kisiwa cha Easter#,
				'generic' => q#Saa za Kisiwa cha Easter#,
				'standard' => q#Saa za Wastani za Kisiwa cha Easter#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Saa za Ekwado#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Mfumo wa kuratibu saa ulimwenguni#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Jiji Lisilojulikana#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Ayalandi#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Uingereza#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Ulaya ya Kati#,
				'generic' => q#Saa za Ulaya ya Kati#,
				'standard' => q#Saa za Wastani za Ulaya ya Kati#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Mashariki mwa Ulaya#,
				'generic' => q#Saa za Mashariki mwa Ulaya#,
				'standard' => q#Saa za Wastani za Mashariki mwa Ulaya#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Saa za Mashariki zaidi mwa Ulaya#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Magharibi mwa Ulaya#,
				'generic' => q#Saa za Magharibi mwa Ulaya#,
				'standard' => q#Saa za Wastani za Magharibi mwa Ulaya#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Visiwa vya Falkland#,
				'generic' => q#Saa za Visiwa vya Falkland#,
				'standard' => q#Saa za Wastani za Visiwa vya Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Fiji#,
				'generic' => q#Saa za Fiji#,
				'standard' => q#Saa za Wastani za Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Saa za Guiana ya Ufaransa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Saa za Kusini mwa Ufaransa na Antaktiki#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Saa za Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Saa za Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Saa za Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Jojia#,
				'generic' => q#Saa za Jojia#,
				'standard' => q#Saa za Wastani za Jojia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Saa za Visiwa vya Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Greenland Mashariki#,
				'generic' => q#Saa za Greenland Mashariki#,
				'standard' => q#Saa za Wastani za Greenland Mashariki#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Greenland Magharibi#,
				'generic' => q#Saa za Greenland Magharibi#,
				'standard' => q#Saa za Wastani za Greenland Magharibi#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Saa za Wastani za Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Saa za Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Saa za Mchana za Hawaii-Aleutian#,
				'generic' => q#Saa za Hawaii-Aleutian#,
				'standard' => q#Saa za Wastani za Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Hong Kong#,
				'generic' => q#Saa za Hong Kong#,
				'standard' => q#Saa za Wastani za Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Hovd#,
				'generic' => q#Saa za Hovd#,
				'standard' => q#Saa za Wastani za Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Saa za Wastani za India#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Saa za Bahari Hindi#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Saa za Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Saa za Indonesia ya Kati#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Saa za Mashariki mwa Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Saa za Magharibi mwa Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Saa za Mchana za Iran#,
				'generic' => q#Saa za Iran#,
				'standard' => q#Saa za Wastani za Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Irkutsk#,
				'generic' => q#Saa za Irkutsk#,
				'standard' => q#Saa za Wastani za Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Saa za Mchana za Israeli#,
				'generic' => q#Saa za Israeli#,
				'standard' => q#Saa za Wastani za Israeli#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Saa za Mchana za Japan#,
				'generic' => q#Saa za Japan#,
				'standard' => q#Saa za Wastani za Japani#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Saa za Kiangazi za Petropavlovsk-Kamchatski#,
				'generic' => q#Saa za Petropavlovsk-Kamchatski#,
				'standard' => q#Saa za Wastani za Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Saa za Kazakhstan Mashariki#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Saa za Kazakhstan Magharibi#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Saa za Mchana za Korea#,
				'generic' => q#Saa za Korea#,
				'standard' => q#Saa za Wastani za Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Saa za Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Krasnoyarsk#,
				'generic' => q#Saa za Krasnoyarsk#,
				'standard' => q#Saa za Wastani za Krasnoyask#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Saa za Kyrgystan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Saa za Visiwa vya Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Saa za Mchana za Lord Howe#,
				'generic' => q#Saa za Lord Howe#,
				'standard' => q#Saa za Wastani za Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Saa za kisiwa cha Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Magadan#,
				'generic' => q#Saa za Magadan#,
				'standard' => q#Saa za Wastani za Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Saa za Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Saa za Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Saa za Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Saa za Visiwa vya Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Morisi#,
				'generic' => q#Saa za Morisi#,
				'standard' => q#Saa za Wastani za Morisi#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Saa za Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Saa za mchana za Meksiko Kaskazini Magharibi#,
				'generic' => q#Saa za Meksiko Kaskazini Magharibi#,
				'standard' => q#Saa za Wastani za Meksiko Kaskazini Magharibi#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Saa za mchana za pasifiki za Meksiko#,
				'generic' => q#Saa za pasifiki za Meksiko#,
				'standard' => q#Saa za wastani za pasifiki za Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Ulan Bator#,
				'generic' => q#Saa za Ulan Bator#,
				'standard' => q#Saa za Wastani za Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Moscow#,
				'generic' => q#Saa za Moscow#,
				'standard' => q#Saa za Wastani za Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Saa za Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Saa za Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Saa za Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za New Caledonia#,
				'generic' => q#Saa za New Caledonia#,
				'standard' => q#Saa za Wastani za New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Saa za Mchana za New Zealand#,
				'generic' => q#Saa za New Zealand#,
				'standard' => q#Saa za Wastani za New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Saa za Mchana za Newfoundland#,
				'generic' => q#Saa za Newfoundland#,
				'standard' => q#Saa za Wastani za Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Saa za Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Kisiwa cha Norfolk#,
				'generic' => q#Saa za Kisiwa cha Norfolk#,
				'standard' => q#Saa za Wastani za Kisiwa cha Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Fernando de Noronha#,
				'generic' => q#Saa za Fernando de Noronha#,
				'standard' => q#Saa za Wastani za Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Novosibirsk#,
				'generic' => q#Saa za Novosibirsk#,
				'standard' => q#Saa za Wastani za Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Omsk#,
				'generic' => q#Saa za Omsk#,
				'standard' => q#Saa za Wastani za Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Pakistan#,
				'generic' => q#Saa za Pakistan#,
				'standard' => q#Saa za Wastani za Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Saa za Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Saa za Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Paragwai#,
				'generic' => q#Saa za Paragwai#,
				'standard' => q#Saa za Wastani za Paragwai#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Peru#,
				'generic' => q#Saa za Peru#,
				'standard' => q#Saa za Wastani za Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Ufilipino#,
				'generic' => q#Saa za Ufilipino#,
				'standard' => q#Saa za Wastani za Ufilipino#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Saa za Visiwa vya Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saa za Mchana za Saint-Pierre na Miquelon#,
				'generic' => q#Saa za Saint-Pierre na Miquelon#,
				'standard' => q#Saa za Wastani ya Saint-Pierre na Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Saa za Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Saa za Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Saa za Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Saa za Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Saa za Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Sakhalin#,
				'generic' => q#Saa za Sakhalin#,
				'standard' => q#Saa za Wastani za Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Saa za Kiangazi za Samara#,
				'generic' => q#Saa za Samara#,
				'standard' => q#Saa za Wastani za Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Samoa#,
				'generic' => q#Saa za Samoa#,
				'standard' => q#Saa za Wastani za Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Saa za Ushelisheli#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Saa za Wastani za Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Saa za Visiwa vya Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Saa za Georgia Kusini#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Saa za Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Saa za Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Saa za Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Saa za Mchana za Taipei#,
				'generic' => q#Saa za Taipei#,
				'standard' => q#Saa za Wastani za Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Saa za Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Saa za Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Tonga#,
				'generic' => q#Saa za Tonga#,
				'standard' => q#Saa za Wastani za Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Saa za Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Turkmenistan#,
				'generic' => q#Saa za Turkmenistan#,
				'standard' => q#Saa za Wastani za Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Saa za Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Urugwai#,
				'generic' => q#Saa za Urugwai#,
				'standard' => q#Saa za Wastani za Urugwai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Uzbekistan#,
				'generic' => q#Saa za Uzbekistan#,
				'standard' => q#Saa za Wastani za Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Vanuatu#,
				'generic' => q#Saa za Vanuatu#,
				'standard' => q#Saa za Wastani za Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Saa za Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Vladivostok#,
				'generic' => q#Saa za Vladivostok#,
				'standard' => q#Saa za Wastani za Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Volgograd#,
				'generic' => q#Saa za Volgograd#,
				'standard' => q#Saa za Wastani za Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Saa za Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Saa za Kisiwa cha Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Saa za Wallis na Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Yakutsk#,
				'generic' => q#Saa za Yakutsk#,
				'standard' => q#Saa za Wastani za Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Yekaterinburg#,
				'generic' => q#Saa za Yekaterinburg#,
				'standard' => q#Saa za Wastani za Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Saa za Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
