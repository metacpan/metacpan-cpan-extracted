=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sw - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw;
# This file auto generated from Data\common\main\sw.xml
#	on Fri 13 Oct  9:42:48 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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

# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

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
 				'anp' => 'Kiangika',
 				'ar' => 'Kiarabu',
 				'ar_001' => 'Kiarabu sanifu',
 				'arc' => 'Kiaramu',
 				'arn' => 'Kimapuche',
 				'arp' => 'Kiarapaho',
 				'arq' => 'Kiarabu cha Algeria',
 				'arz' => 'Kiarabu cha Misri',
 				'as' => 'Kiassam',
 				'asa' => 'Kiasu',
 				'ast' => 'Kiasturia',
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
 				'ce' => 'Kichechenia',
 				'ceb' => 'Kichebuano',
 				'cgg' => 'Kichiga',
 				'ch' => 'Kichamorro',
 				'chk' => 'Kichukisi',
 				'chm' => 'Kimari',
 				'cho' => 'Kichoktao',
 				'chr' => 'Kicherokee',
 				'chy' => 'Kicheyeni',
 				'ckb' => 'Kikurdi cha Sorani',
 				'co' => 'Kikosikani',
 				'cop' => 'Kikhufti',
 				'crs' => 'Krioli ya Shelisheli',
 				'cs' => 'Kicheki',
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
 				'en_US@alt=short' => 'Kiingereza (US)',
 				'eo' => 'Kiesperanto',
 				'es' => 'Kihispania',
 				'es_419' => 'Kihispania (Amerika ya Latini)',
 				'es_ES' => 'Kihispania (Ulaya)',
 				'et' => 'Kiestonia',
 				'eu' => 'Kibaski',
 				'ewo' => 'Kiewondo',
 				'fa' => 'Kiajemi',
 				'ff' => 'Kifulani',
 				'fi' => 'Kifini',
 				'fil' => 'Kifilipino',
 				'fj' => 'Kifiji',
 				'fo' => 'Kifaroe',
 				'fon' => 'Kifon',
 				'fr' => 'Kifaransa',
 				'fr_CA' => 'Kifaransa (Canada)',
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
 				'haw' => 'Kihawai',
 				'he' => 'Kiebrania',
 				'hi' => 'Kihindi',
 				'hil' => 'Kihiligaynon',
 				'hit' => 'Kihiti',
 				'hmn' => 'Kihmong',
 				'hr' => 'Kikroeshia',
 				'hsb' => 'Kisobia cha Ukanda wa Juu',
 				'ht' => 'Kihaiti',
 				'hu' => 'Kihungaria',
 				'hup' => 'Hupa',
 				'hy' => 'Kiarmenia',
 				'hz' => 'Kiherero',
 				'ia' => 'Kiintalingua',
 				'iba' => 'Kiiban',
 				'ibb' => 'Kiibibio',
 				'id' => 'Kiindonesia',
 				'ie' => 'lugha ya kisayansi',
 				'ig' => 'Kiigbo',
 				'ii' => 'Kiyi cha Sichuan',
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
 				'kha' => 'Kikhasi',
 				'khq' => 'Koyra Chiini',
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
 				'ky' => 'Kikyrgyz',
 				'la' => 'Kilatini',
 				'lad' => 'Kiladino',
 				'lag' => 'Kirangi',
 				'lam' => 'Lamba',
 				'lb' => 'Kilasembagi',
 				'lez' => 'Kilezighian',
 				'lg' => 'Kiganda',
 				'li' => 'Limburgish',
 				'lkt' => 'Kilakota',
 				'ln' => 'Kilingala',
 				'lo' => 'Kilaosi',
 				'lol' => 'Kimongo',
 				'loz' => 'Kilozi',
 				'lrc' => 'Kiluri cha Kaskazini',
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
 				'moh' => 'Lugha ya Mohawk',
 				'mos' => 'Kimoore',
 				'mr' => 'Kimarathi',
 				'ms' => 'Kimalei',
 				'mt' => 'Kimalta',
 				'mua' => 'Kimundang',
 				'mul' => 'Lugha Nyingi',
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
 				'pl' => 'Kipolandi',
 				'prg' => 'Kiprussia',
 				'ps' => 'Kipashto',
 				'ps@alt=variant' => 'Kipushto',
 				'pt' => 'Kireno',
 				'pt_PT' => 'Kireno (Ulaya)',
 				'qu' => 'Kikechua',
 				'quc' => 'Kʼicheʼ',
 				'rap' => 'Kirapanui',
 				'rar' => 'Kirarotonga',
 				'rm' => 'Kiromanshi',
 				'rn' => 'Kirundi',
 				'ro' => 'Kiromania',
 				'ro_MD' => 'Kimoldova cha Romania',
 				'rof' => 'Kirombo',
 				'root' => 'Kiroot',
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
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Kisango',
 				'sh' => 'Kiserbia-kroeshia',
 				'shi' => 'Kitachelhit',
 				'shn' => 'Kishan',
 				'shu' => 'Kiarabu cha Chad',
 				'si' => 'Kisinhala',
 				'sk' => 'Kislovakia',
 				'sl' => 'Kislovenia',
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
 				'su' => 'Kisunda',
 				'suk' => 'Kisukuma',
 				'sus' => 'Kisusu',
 				'sv' => 'Kiswidi',
 				'sw' => 'Kiswahili',
 				'swb' => 'Shikomor',
 				'syr' => 'Lugha ya Syriac',
 				'ta' => 'Kitamili',
 				'te' => 'Kitelugu',
 				'tem' => 'Kitemne',
 				'teo' => 'Kiteso',
 				'tet' => 'Kitetum',
 				'tg' => 'Kitajiki',
 				'th' => 'Kithai',
 				'ti' => 'Kitigrinya',
 				'tig' => 'Kitigre',
 				'tk' => 'Kiturukimeni',
 				'tlh' => 'Kiklingoni',
 				'tn' => 'Kitswana',
 				'to' => 'Kitonga',
 				'tpi' => 'Kitokpisin',
 				'tr' => 'Kituruki',
 				'trv' => 'Kitaroko',
 				'ts' => 'Kitsonga',
 				'tt' => 'Kitatari',
 				'tum' => 'Kitumbuka',
 				'tvl' => 'Kituvalu',
 				'tw' => 'Twi',
 				'twq' => 'Kitasawaq',
 				'ty' => 'Kitahiti',
 				'tyv' => 'Kituva',
 				'tzm' => 'Kitamazighati cha Atlasi ya Kati',
 				'udm' => 'Kiudmurt',
 				'ug' => 'Kiuyghur',
 				'uk' => 'Kiukraini',
 				'umb' => 'Umbundu',
 				'und' => 'Lugha Isiyojulikana',
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
 				'xal' => 'Kikalmyk',
 				'xh' => 'Kixhosa',
 				'xog' => 'Kisoga',
 				'yao' => 'Kiyao',
 				'yav' => 'Kiyangben',
 				'ybb' => 'Kiyemba',
 				'yi' => 'Kiyiddi',
 				'yo' => 'Kiyoruba',
 				'yue' => 'Kikantoni',
 				'zgh' => 'Kiberber Sanifu cha Moroko',
 				'zh' => 'Kichina',
 				'zh_Hans' => 'Kichina (Kilichorahisishwa)',
 				'zh_Hant' => 'Kichina cha Jadi',
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
			'Arab' => 'Kiarabu',
 			'Arab@alt=variant' => 'Kiajemi/Kiarabu',
 			'Armn' => 'Kiarmenia',
 			'Beng' => 'Kibengali',
 			'Bopo' => 'Kibopomofo',
 			'Brai' => 'Braille',
 			'Cyrl' => 'Kisiriliki',
 			'Deva' => 'Kidevanagari',
 			'Ethi' => 'Kiethiopia',
 			'Geor' => 'Kijojia',
 			'Grek' => 'Kigiriki',
 			'Gujr' => 'Kigujarati',
 			'Guru' => 'Kigurmukhi',
 			'Hanb' => 'Hanb',
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
 			'Mymr' => 'Myama',
 			'Orya' => 'Kioriya',
 			'Sinh' => 'Kisinhala',
 			'Taml' => 'Kitamil',
 			'Telu' => 'Kitelugu',
 			'Thaa' => 'Kithaana',
 			'Thai' => 'Kithai',
 			'Tibt' => 'Kitibeti',
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
 			'202' => 'Afrika Kusine mwa Jangwa la Sahara',
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
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curacao',
 			'CX' => 'Kisiwa cha Krismasi',
 			'CY' => 'Cyprus',
 			'CZ' => 'Chechia',
 			'CZ@alt=variant' => 'Jamhuri ya Cheki',
 			'DE' => 'Ujerumani',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denmark',
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
 			'EZ' => 'EZ',
 			'FI' => 'Ufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Visiwa vya Falkland',
 			'FK@alt=variant' => 'Visiwa vya Falkland (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Visiwa vya Faroe',
 			'FR' => 'Ufaransa',
 			'GA' => 'Gabon',
 			'GB' => 'Ufalme wa Muungano',
 			'GB@alt=short' => 'Ufalme wa Muungano',
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
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau SAR China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Visiwa vya Mariana vya Kaskazini',
 			'MQ' => 'Martinique',
 			'MR' => 'Moritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Morisi',
 			'MV' => 'Maldives',
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
 			'ST' => 'São Tomé na Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Uswazi',
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
 			'UN@alt=short' => 'Umoja wa Mataifa',
 			'US' => 'Marekani',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzibekistani',
 			'VA' => 'Mji wa Vatican',
 			'VC' => 'St. Vincent na Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Visiwa vya Virgin, Uingereza',
 			'VI' => 'Visiwa vya Virgin, Marekani',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis na Futuna',
 			'WS' => 'Samoa',
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
 			'colcaselevel' => 'Upangaji Unaoathiriwa na Herufi',
 			'collation' => 'Mpangilio',
 			'colnormalization' => 'Upangaji wa Kawaida',
 			'colnumeric' => 'Upangaji wa Namba',
 			'colstrength' => 'Nguvu ya Upangaji',
 			'currency' => 'Sarafu',
 			'hc' => 'Kipindi cha saa (12 au 24)',
 			'lb' => 'Mtindo wa Kukata Mstari',
 			'ms' => 'Mfumo wa Vipimo',
 			'numbers' => 'Nambari',
 			'timezone' => 'Ukanda Saa',
 			'va' => 'Tofauti ya Mandhari',
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
 				'islamic' => q{Kalenda ya Kiislamu},
 				'islamic-civil' => q{Kalenda ya Kiislamu/Rasmi},
 				'iso8601' => q{Kalenda ya ISO-8601},
 				'japanese' => q{Kalenda ya Kijapani},
 				'persian' => q{Kalenda ya Kiajemi},
 				'roc' => q{Kalenda ya Minguo},
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
 				'uksystem' => q{Mfumo wa UK},
 				'ussystem' => q{Mfumo wa US},
 			},
 			'numbers' => {
 				'arab' => q{Nambari za Kiarabu/Kihindi},
 				'arabext' => q{Nambari za Kiarabu/Kihindi Zilizopanuliwa},
 				'armn' => q{Nambari za Kiarmenia},
 				'armnlow' => q{Nambari Ndogo za Kiarmenia},
 				'beng' => q{Nambari za Kibengali},
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
 				'khmr' => q{Nambari za Kikhmer},
 				'knda' => q{Nambari za Kikannada},
 				'laoo' => q{Nambari za Kilao},
 				'latn' => q{Nambari za Magharibi},
 				'limb' => q{Nambari za Kilimbu},
 				'mlym' => q{Nambari za Malayalam},
 				'mong' => q{Nambari za Kimongolia},
 				'mymr' => q{Nambari za Myanmar},
 				'native' => q{Digiti Asili},
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
 				'vaii' => q{Dijiti za Vai},
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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b {ch} d e f g h i j k l m n o p r s t u v w y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- , ; \: ! ? . ' " ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'' => {
						'name' => q(sehemu kuu za dira),
					},
					'acre' => {
						'name' => q(ekari),
						'one' => q(ekari {0}),
						'other' => q(ekari {0}),
					},
					'acre-foot' => {
						'name' => q(ekari futi),
						'one' => q(ekari futi {0}),
						'other' => q(ekari futi {0}),
					},
					'ampere' => {
						'name' => q(ampea),
						'one' => q(ampea {0}),
						'other' => q(ampea {0}),
					},
					'arc-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					'arc-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					'astronomical-unit' => {
						'name' => q(vipimo vya astronomia),
						'one' => q(kipimo {0} cha astronomia),
						'other' => q(vipimo {0} vya astronomia),
					},
					'atmosphere' => {
						'name' => q(kanieneo ya hewa),
						'one' => q(kanieneo {0}),
						'other' => q(kanieneo {0}),
					},
					'bit' => {
						'name' => q(biti),
						'one' => q(biti {0}),
						'other' => q(biti {0}),
					},
					'byte' => {
						'name' => q(baiti),
						'one' => q(baiti {0}),
						'other' => q(baiti {0}),
					},
					'calorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'carat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'celsius' => {
						'name' => q(nyuzi),
						'one' => q(nyuzi {0}),
						'other' => q(nyuzi {0}),
					},
					'centiliter' => {
						'name' => q(sentilita),
						'one' => q(sentilita {0}),
						'other' => q(sentilita {0}),
					},
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q(sentimita {0}),
						'other' => q(sentimita {0}),
						'per' => q({0} kwa kila sentimita),
					},
					'century' => {
						'name' => q(karne),
						'one' => q(karne {0}),
						'other' => q(karne {0}),
					},
					'coordinate' => {
						'east' => q({0} Mashariki),
						'north' => q({0} Kaskazini),
						'south' => q({0} Kusini),
						'west' => q({0} Magharibi),
					},
					'cubic-centimeter' => {
						'name' => q(sentimita za ujazo),
						'one' => q(sentimita {0} ya ujazo),
						'other' => q(sentimita {0} za ujazo),
						'per' => q({0} kwa kila sentimita ya ujazo),
					},
					'cubic-foot' => {
						'name' => q(futi za ujazo),
						'one' => q(futi {0} ya ujazo),
						'other' => q(futi {0} za ujazo),
					},
					'cubic-inch' => {
						'name' => q(inchi za ujazo),
						'one' => q(inchi {0} ya ujazo),
						'other' => q(inchi {0} za ujazo),
					},
					'cubic-kilometer' => {
						'name' => q(kilomita za ujazo),
						'one' => q(kilomita {0} ya ujazo),
						'other' => q(kilomita {0} za ujazo),
					},
					'cubic-meter' => {
						'name' => q(mita za ujazo),
						'one' => q(mita {0} ya ujazo),
						'other' => q(mita {0} za ujazo),
						'per' => q({0} kwa kila mita ya ujazo),
					},
					'cubic-mile' => {
						'name' => q(maili za ujazo),
						'one' => q(maili {0} ya ujazo),
						'other' => q(maili {0} za ujazo),
					},
					'cubic-yard' => {
						'name' => q(yadi za ujazo),
						'one' => q(yadi {0} ya ujazo),
						'other' => q(yadi {0} za ujazo),
					},
					'cup' => {
						'name' => q(vikombe),
						'one' => q(kikombe {0}),
						'other' => q(vikombe {0}),
					},
					'cup-metric' => {
						'name' => q(vikombe vya mizani),
						'one' => q(kikombe {0} cha mizani),
						'other' => q(vikombe {0} vya mizani),
					},
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
						'per' => q({0} kwa siku),
					},
					'deciliter' => {
						'name' => q(desilita),
						'one' => q(desilita {0}),
						'other' => q(desilita {0}),
					},
					'decimeter' => {
						'name' => q(desimita),
						'one' => q(desimita {0}),
						'other' => q(desimita {0}),
					},
					'degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					'fahrenheit' => {
						'name' => q(nyuzi za farenheiti),
						'one' => q(nyuzi za farenheiti {0}),
						'other' => q(nyuzi za farenheiti {0}),
					},
					'fluid-ounce' => {
						'name' => q(aunsi za ujazo),
						'one' => q(aunsi {0} ya ujazo),
						'other' => q(aunsi {0} za ujazo),
					},
					'foodcalorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'foot' => {
						'name' => q(futi),
						'one' => q(futi {0}),
						'other' => q(futi {0}),
						'per' => q({0} kwa kila futi),
					},
					'g-force' => {
						'name' => q(mvuto wa graviti),
						'one' => q(mvuto wa graviti {0}),
						'other' => q(mvuto wa graviti {0}),
					},
					'gallon' => {
						'name' => q(galoni),
						'one' => q(galoni {0}),
						'other' => q(galoni {0}),
						'per' => q({0} kwa kila galoni),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabiti),
						'one' => q(gigabiti {0}),
						'other' => q(gigabiti {0}),
					},
					'gigabyte' => {
						'name' => q(gigabaiti),
						'one' => q(gigabaiti {0}),
						'other' => q(gigabaiti {0}),
					},
					'gigahertz' => {
						'name' => q(gigahezi),
						'one' => q(gigahezi {0}),
						'other' => q(gigahezi {0}),
					},
					'gigawatt' => {
						'name' => q(gigawati),
						'one' => q(gigawati {0}),
						'other' => q(gigawati {0}),
					},
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
						'per' => q({0} kwa kila gramu),
					},
					'hectare' => {
						'name' => q(hekta),
						'one' => q(hekta {0}),
						'other' => q(hekta {0}),
					},
					'hectoliter' => {
						'name' => q(hektolita),
						'one' => q(hektolita {0}),
						'other' => q(hektolita {0}),
					},
					'hectopascal' => {
						'name' => q(hektopaskali),
						'one' => q(hektopaskali {0}),
						'other' => q(hektopaskali {0}),
					},
					'hertz' => {
						'name' => q(hezi),
						'one' => q(hezi {0}),
						'other' => q(hezi {0}),
					},
					'horsepower' => {
						'name' => q(kipimo cha hospawa),
						'one' => q(kipimo cha hospawa {0}),
						'other' => q(kipimo cha hospawa {0}),
					},
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
						'per' => q({0} kwa saa),
					},
					'inch' => {
						'name' => q(inchi),
						'one' => q(inchi {0}),
						'other' => q(inchi {0}),
						'per' => q({0} kwa kila inchi),
					},
					'inch-hg' => {
						'name' => q(inchi za zebaki),
						'one' => q(inchi {0} ya zebaki),
						'other' => q(inchi {0} za zebaki),
					},
					'joule' => {
						'name' => q(jouli),
						'one' => q(jouli {0}),
						'other' => q(jouli {0}),
					},
					'karat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'kelvin' => {
						'name' => q(kelvini),
						'one' => q(kelvini {0}),
						'other' => q(kelvini {0}),
					},
					'kilobit' => {
						'name' => q(kilobiti),
						'one' => q(kilobiti {0}),
						'other' => q(kilobiti {0}),
					},
					'kilobyte' => {
						'name' => q(kilobaiti),
						'one' => q(kilobaiti {0}),
						'other' => q(kilobaiti {0}),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q(kilokalori {0}),
						'other' => q(kilokalori {0}),
					},
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kilogramu {0}),
						'other' => q(kilogramu {0}),
						'per' => q({0} kwa kila kilogramu),
					},
					'kilohertz' => {
						'name' => q(kilohezi),
						'one' => q(kilohezi {0}),
						'other' => q(kilohezi {0}),
					},
					'kilojoule' => {
						'name' => q(kilojuli),
						'one' => q(kilojuli {0}),
						'other' => q(kilojuli {0}),
					},
					'kilometer' => {
						'name' => q(kilomita),
						'one' => q(kilomita {0}),
						'other' => q(kilomita {0}),
						'per' => q({0} kwa kila kilomita),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(kilomita {0} kwa saa),
						'other' => q(kilomita {0} kwa saa),
					},
					'kilowatt' => {
						'name' => q(kilowati),
						'one' => q(kilowati {0}),
						'other' => q(kilowati {0}),
					},
					'kilowatt-hour' => {
						'name' => q(kilowati kwa saa),
						'one' => q(kilowati {0} kwa saa),
						'other' => q(kilowati {0} kwa saa),
					},
					'knot' => {
						'name' => q(noti),
						'one' => q(noti {0}),
						'other' => q(noti {0}),
					},
					'light-year' => {
						'name' => q(miaka ya mwanga),
						'one' => q(miaka ya mwanga {0}),
						'other' => q(miaka ya mwanga {0}),
					},
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
						'per' => q({0} kwa kila lita),
					},
					'liter-per-100kilometers' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q(lita {0} kwa kilomita 100),
						'other' => q(lita {0} kwa kilomita 100),
					},
					'liter-per-kilometer' => {
						'name' => q(lita kwa kila kilomita),
						'one' => q(lita {0} kwa kilomita),
						'other' => q(lita {0} kwa kilomita),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q(lux {0}),
						'other' => q(lux {0}),
					},
					'megabit' => {
						'name' => q(megabiti),
						'one' => q(megabiti {0}),
						'other' => q(megabiti {0}),
					},
					'megabyte' => {
						'name' => q(megabaiti),
						'one' => q(megabaiti {0}),
						'other' => q(megabaiti {0}),
					},
					'megahertz' => {
						'name' => q(megahezi),
						'one' => q(megahezi {0}),
						'other' => q(megahezi {0}),
					},
					'megaliter' => {
						'name' => q(megalita),
						'one' => q(megalita {0}),
						'other' => q(megalita {0}),
					},
					'megawatt' => {
						'name' => q(megawati),
						'one' => q(megawati {0}),
						'other' => q(megawati {0}),
					},
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q({0} kwa kila mita),
					},
					'meter-per-second' => {
						'name' => q(mita kwa kila sekunde),
						'one' => q(mita {0} kwa sekunde),
						'other' => q(mita {0} kwa sekunde),
					},
					'meter-per-second-squared' => {
						'name' => q(mita kwa kila sekunde mraba),
						'one' => q(mita {0} kwa kila sekunde mraba),
						'other' => q(mita {0} kwa kila sekunde mraba),
					},
					'metric-ton' => {
						'name' => q(tani mita),
						'one' => q(tani mita {0}),
						'other' => q(tani mita {0}),
					},
					'microgram' => {
						'name' => q(mikrogramu),
						'one' => q(mikrogramu {0}),
						'other' => q(mikrogramu {0}),
					},
					'micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					'microsecond' => {
						'name' => q(mikrosekunde),
						'one' => q(mikrosekunde {0}),
						'other' => q(mikrosekunde {0}),
					},
					'mile' => {
						'name' => q(maili),
						'one' => q(maili {0}),
						'other' => q(maili {0}),
					},
					'mile-per-gallon' => {
						'name' => q(maili kwa kila galoni),
						'one' => q(maili {0} kwa kila galoni),
						'other' => q(maili {0} kwa kila galoni),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(maili kwa kila galoni la Uingereza),
						'one' => q(maili {0} kwa kila galoni la Uingereza),
						'other' => q(maili {0} kwa kila galoni la Uingereza),
					},
					'mile-per-hour' => {
						'name' => q(maili kwa kila saa),
						'one' => q(maili {0} kwa saa),
						'other' => q(maili {0} kwa saa),
					},
					'mile-scandinavian' => {
						'name' => q(maili ya skandinavia),
						'one' => q(maili ya skandinavia),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliampea),
						'one' => q(miliampea {0}),
						'other' => q(miliampea {0}),
					},
					'millibar' => {
						'name' => q(kipimo cha milibari),
						'one' => q(kipimo cha milibari {0}),
						'other' => q(kipimo cha milibari {0}),
					},
					'milligram' => {
						'name' => q(miligramu),
						'one' => q(miligramu {0}),
						'other' => q(miligramu {0}),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligramu kwa kila desilita),
						'one' => q(miligramu kwa kila desilita),
						'other' => q(miligramu {0} kwa kila desilita),
					},
					'milliliter' => {
						'name' => q(mililita),
						'one' => q(mililita {0}),
						'other' => q(mililita {0}),
					},
					'millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimita za zebaki),
						'one' => q(milimita {0} ya zebaki),
						'other' => q(milimita {0} za zebaki),
					},
					'millimole-per-liter' => {
						'name' => q(milimoli kwa kila lita),
						'one' => q(milimoli {0} kwa kila lita),
						'other' => q(milimoli {0} kwa kila lita),
					},
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(millisekunde {0}),
						'other' => q(millisekunde {0}),
					},
					'milliwatt' => {
						'name' => q(miliwati),
						'one' => q(miliwati {0}),
						'other' => q(miliwati {0}),
					},
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
						'per' => q({0} kwa kila dakika),
					},
					'month' => {
						'name' => q(miezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
						'per' => q({0} kwa mwezi),
					},
					'nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					'nanosecond' => {
						'name' => q(nanosekunde),
						'one' => q(nanosekunde {0}),
						'other' => q(nanosekunde {0}),
					},
					'nautical-mile' => {
						'name' => q(maili za kibaharia),
						'one' => q(maili {0} ya kibaharia),
						'other' => q(maili {0} za kibaharia),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(aunsi),
						'one' => q(aunsi {0}),
						'other' => q(aunsi {0}),
						'per' => q({0} kwa kila aunsi),
					},
					'ounce-troy' => {
						'name' => q(tola aunsi),
						'one' => q(tola aunsi {0}),
						'other' => q(tola aunsi {0}),
					},
					'parsec' => {
						'name' => q(kila sekunde),
						'one' => q({0} kila sekunde),
						'other' => q({0} kila sekunde),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
					},
					'per' => {
						'1' => q({0} kwa kila {1}),
					},
					'percent' => {
						'name' => q(asilimia),
						'one' => q(asilimia {0}),
						'other' => q(asilimia {0}),
					},
					'permille' => {
						'name' => q(kwa elfu),
						'one' => q({0} kwa kila elfu),
						'other' => q({0} kwa kila elfu),
					},
					'petabyte' => {
						'name' => q(petabaiti),
						'one' => q(petabaiti {0}),
						'other' => q(petabaiti {0}),
					},
					'picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					'pint' => {
						'name' => q(painti),
						'one' => q(painti {0}),
						'other' => q(painti {0}),
					},
					'pint-metric' => {
						'name' => q(painti za mizani),
						'one' => q(painti {0} ya mizani),
						'other' => q(painti {0} za mizani),
					},
					'point' => {
						'name' => q(pointi),
						'one' => q(pointi {0}),
						'other' => q(pointi {0}),
					},
					'pound' => {
						'name' => q(ratili),
						'one' => q(ratili {0}),
						'other' => q(ratili {0}),
						'per' => q({0} kwa kila ratili),
					},
					'pound-per-square-inch' => {
						'name' => q(pauni kwa kila inchi mraba),
						'one' => q(pauni {0} kwa kila inchi mraba),
						'other' => q(pauni {0} kwa kila inchi mraba),
					},
					'quart' => {
						'name' => q(kwati),
						'one' => q(kwati {0}),
						'other' => q(kwati {0}),
					},
					'radian' => {
						'name' => q(radiani),
						'one' => q(radiani {0}),
						'other' => q(radiani {0}),
					},
					'revolution' => {
						'name' => q(mzunguko),
						'one' => q(mzunguko {0}),
						'other' => q(mizunguko {0}),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
						'per' => q({0} kwa kila sekunde),
					},
					'square-centimeter' => {
						'name' => q(sentimita mraba),
						'one' => q(sentimita mraba {0}),
						'other' => q(sentimita mraba {0}),
						'per' => q({0} kwa kila sentimita mraba),
					},
					'square-foot' => {
						'name' => q(futi za mraba),
						'one' => q(futi {0} ya mraba),
						'other' => q(futi {0} za mraba),
					},
					'square-inch' => {
						'name' => q(inchi za mraba),
						'one' => q(inchi {0} ya mraba),
						'other' => q(inchi {0} za mraba),
						'per' => q({0} kwa kila inchi mraba),
					},
					'square-kilometer' => {
						'name' => q(kilomita za mraba),
						'one' => q(kilomita {0} ya mraba),
						'other' => q(kilomita {0} za mraba),
						'per' => q({0} kwa kila kilomita mraba),
					},
					'square-meter' => {
						'name' => q(mita za mraba),
						'one' => q(mita {0} ya mraba),
						'other' => q(mita {0} za mraba),
						'per' => q({0} kwa kila mita mraba),
					},
					'square-mile' => {
						'name' => q(maili za mraba),
						'one' => q(maili {0} ya mraba),
						'other' => q(maili {0} za mraba),
						'per' => q({0} kwa kila maili mraba),
					},
					'square-yard' => {
						'name' => q(yadi za mraba),
						'one' => q(yadi {0} ya mraba),
						'other' => q(yadi {0} za mraba),
					},
					'tablespoon' => {
						'name' => q(vijiko vikubwa),
						'one' => q(kijiko {0} kikubwa),
						'other' => q(vijiko {0} vikubwa),
					},
					'teaspoon' => {
						'name' => q(vijiko vidogo),
						'one' => q(kijiko {0} kidogo),
						'other' => q(vijiko {0} vidogo),
					},
					'terabit' => {
						'name' => q(terabiti),
						'one' => q(terabiti {0}),
						'other' => q(terabiti {0}),
					},
					'terabyte' => {
						'name' => q(terabaiti),
						'one' => q(terabaiti {0}),
						'other' => q(terabaiti {0}),
					},
					'ton' => {
						'name' => q(tani),
						'one' => q(tani {0}),
						'other' => q(tani {0}),
					},
					'volt' => {
						'name' => q(volti),
						'one' => q(volti {0}),
						'other' => q(volti {0}),
					},
					'watt' => {
						'name' => q(wati),
						'one' => q(wati {0}),
						'other' => q(wati {0}),
					},
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
						'per' => q({0} kwa wiki),
					},
					'yard' => {
						'name' => q(yadi),
						'one' => q(yadi {0}),
						'other' => q(yadi {0}),
					},
					'year' => {
						'name' => q(miaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
						'per' => q({0} kwa mwaka),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(mwelekeo),
					},
					'acre' => {
						'one' => q(Ekari {0}),
						'other' => q(Ekari {0}),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0} Mashariki),
						'north' => q({0} Kaskazini),
						'south' => q({0} Kusini),
						'west' => q({0} Magharibi),
					},
					'cubic-kilometer' => {
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					'cubic-mile' => {
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'one' => q(Futi {0}),
						'other' => q(Futi {0}),
					},
					'g-force' => {
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
					},
					'hectare' => {
						'one' => q(ha {0}),
						'other' => q(ha {0}),
					},
					'hectopascal' => {
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					'horsepower' => {
						'one' => q(hp {0}),
						'other' => q(hp {0}),
					},
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
					},
					'inch' => {
						'name' => q(Inchi),
						'one' => q(Inchi {0}),
						'other' => q(Inchi {0}),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kg {0}),
						'other' => q(kg {0}),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q(km {0}),
						'other' => q(km {0}),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(km {0}/saa),
						'other' => q(km {0}/saa),
					},
					'kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
					},
					'light-year' => {
						'one' => q(ly {0}),
						'other' => q(ly {0}),
					},
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
					},
					'liter-per-100kilometers' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
					},
					'meter-per-second' => {
						'one' => q(m {0}/s),
						'other' => q(m {0}/s),
					},
					'mile' => {
						'one' => q(Maili {0}),
						'other' => q(Maili {0}),
					},
					'mile-per-hour' => {
						'one' => q(mi {0}/saa),
						'other' => q(mi {0}/saa),
					},
					'millibar' => {
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					'millimeter' => {
						'name' => q(milimita),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(ms {0}),
						'other' => q(ms {0}),
					},
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					'month' => {
						'name' => q(mwezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
					},
					'ounce' => {
						'one' => q(Aunsi {0}),
						'other' => q(Aunsi {0}),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(asilimia),
						'one' => q(asilimia {0}),
						'other' => q(asilimia {0}),
					},
					'picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
					},
					'pound' => {
						'one' => q(Ratili {0}),
						'other' => q(Ratili {0}),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					'square-foot' => {
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
					},
					'square-kilometer' => {
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					'square-meter' => {
						'one' => q(m² {0}),
						'other' => q(m² {0}),
					},
					'square-mile' => {
						'one' => q(mi² {0}),
						'other' => q(mi² {0}),
					},
					'volt' => {
						'name' => q(volti),
					},
					'watt' => {
						'name' => q(wati),
						'one' => q(Wati {0}),
						'other' => q(Wati {0}),
					},
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
					},
					'yard' => {
						'one' => q(Yadi {0}),
						'other' => q(Yadi {0}),
					},
					'year' => {
						'name' => q(mwaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
					},
				},
				'short' => {
					'' => {
						'name' => q(mwelekeo),
					},
					'acre' => {
						'name' => q(ekari),
						'one' => q(ekari {0}),
						'other' => q(ekari {0}),
					},
					'acre-foot' => {
						'name' => q(ekari futi),
						'one' => q(ekari futi {0}),
						'other' => q(ekari futi {0}),
					},
					'ampere' => {
						'name' => q(ampea),
						'one' => q(ampea {0}),
						'other' => q(ampea {0}),
					},
					'arc-minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
					},
					'arc-second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
					},
					'astronomical-unit' => {
						'name' => q(vipimo vya astronomia),
						'one' => q(au {0}),
						'other' => q(au {0}),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q(atm {0}),
						'other' => q(atm {0}),
					},
					'bit' => {
						'name' => q(biti),
						'one' => q(biti {0}),
						'other' => q(biti {0}),
					},
					'byte' => {
						'name' => q(baiti),
						'one' => q(baiti {0}),
						'other' => q(baiti {0}),
					},
					'calorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'carat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'celsius' => {
						'name' => q(nyuzi),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(sentilita),
						'one' => q(sentilita {0}),
						'other' => q(sentilita {0}),
					},
					'centimeter' => {
						'name' => q(sentimita),
						'one' => q(sentimita {0}),
						'other' => q(sentimita {0}),
						'per' => q({0} kwa kila sentimita),
					},
					'century' => {
						'name' => q(karne),
						'one' => q(karne {0}),
						'other' => q(karne {0}),
					},
					'coordinate' => {
						'east' => q({0} Mashariki),
						'north' => q({0} Kaskazini),
						'south' => q({0} Kusini),
						'west' => q({0} Magharibi),
					},
					'cubic-centimeter' => {
						'name' => q(sentimita za ujazo),
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(futi za ujazo),
						'one' => q(ft³ {0}),
						'other' => q(ft³ {0}),
					},
					'cubic-inch' => {
						'name' => q(inchi za ujazo),
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
					},
					'cubic-kilometer' => {
						'name' => q(kilomita za ujazo),
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					'cubic-meter' => {
						'name' => q(mita za ujazo),
						'one' => q(m³ {0}),
						'other' => q(mita {0} za ujazo),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(maili za ujazo),
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					'cubic-yard' => {
						'name' => q(yadi za ujazo),
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
					},
					'cup' => {
						'name' => q(vikombe),
						'one' => q(kikombe {0}),
						'other' => q(vikombe {0}),
					},
					'cup-metric' => {
						'name' => q(vikombe vya mizani),
						'one' => q(mc {0}),
						'other' => q(vikombe {0} vya mizani),
					},
					'day' => {
						'name' => q(siku),
						'one' => q(siku {0}),
						'other' => q(siku {0}),
						'per' => q({0} kwa siku),
					},
					'deciliter' => {
						'name' => q(desilita),
						'one' => q(desilita {0}),
						'other' => q(desilita {0}),
					},
					'decimeter' => {
						'name' => q(desimita),
						'one' => q(desimita {0}),
						'other' => q(desimita {0}),
					},
					'degree' => {
						'name' => q(digrii),
						'one' => q(digrii {0}),
						'other' => q(digrii {0}),
					},
					'fahrenheit' => {
						'name' => q(nyuzi za farenheiti),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(aunsi za ujazo),
						'one' => q(fl oz {0}),
						'other' => q(fl oz {0}),
					},
					'foodcalorie' => {
						'name' => q(kalori),
						'one' => q(kalori {0}),
						'other' => q(kalori {0}),
					},
					'foot' => {
						'name' => q(futi),
						'one' => q(futi {0}),
						'other' => q(futi {0}),
						'per' => q({0} kwa kila futi),
					},
					'g-force' => {
						'name' => q(mvuto wa graviti),
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					'gallon' => {
						'name' => q(galoni),
						'one' => q(galoni {0}),
						'other' => q(galoni {0}),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabiti),
						'one' => q(gigabiti {0}),
						'other' => q(gigabiti {0}),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q(GB {0}),
						'other' => q(GB {0}),
					},
					'gigahertz' => {
						'name' => q(gigahezi),
						'one' => q(gigahezi {0}),
						'other' => q(gigahezi {0}),
					},
					'gigawatt' => {
						'name' => q(gigawati),
						'one' => q(gigawati {0}),
						'other' => q(gigawati {0}),
					},
					'gram' => {
						'name' => q(gramu),
						'one' => q(gramu {0}),
						'other' => q(gramu {0}),
						'per' => q({0} kwa kila gramu),
					},
					'hectare' => {
						'name' => q(hekta),
						'one' => q(hekta {0}),
						'other' => q(hekta {0}),
					},
					'hectoliter' => {
						'name' => q(hektolita),
						'one' => q(hektolita {0}),
						'other' => q(hektolita {0}),
					},
					'hectopascal' => {
						'name' => q(hektopaskali),
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					'hertz' => {
						'name' => q(hezi),
						'one' => q(hezi {0}),
						'other' => q(hezi {0}),
					},
					'horsepower' => {
						'name' => q(kipimo cha hospawa),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(saa),
						'one' => q(saa {0}),
						'other' => q(saa {0}),
						'per' => q({0} kwa saa),
					},
					'inch' => {
						'name' => q(inchi),
						'one' => q(inchi {0}),
						'other' => q(inchi {0}),
						'per' => q({0} kwa kila inchi),
					},
					'inch-hg' => {
						'name' => q(inchi za zebaki),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(jouli),
						'one' => q(jouli {0}),
						'other' => q(jouli {0}),
					},
					'karat' => {
						'name' => q(karati),
						'one' => q(karati {0}),
						'other' => q(karati {0}),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kilobiti),
						'one' => q(kilobiti {0}),
						'other' => q(kilobiti {0}),
					},
					'kilobyte' => {
						'name' => q(kilobaiti),
						'one' => q(kilobaiti {0}),
						'other' => q(kilobaiti {0}),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q(kilokalori {0}),
						'other' => q(kilokalori {0}),
					},
					'kilogram' => {
						'name' => q(kilogramu),
						'one' => q(kg {0}),
						'other' => q(kg {0}),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kilohezi),
						'one' => q(kilohezi {0}),
						'other' => q(kilohezi {0}),
					},
					'kilojoule' => {
						'name' => q(kilojuli),
						'one' => q(kilojuli {0}),
						'other' => q(kilojuli {0}),
					},
					'kilometer' => {
						'name' => q(kilomita),
						'one' => q(km {0}),
						'other' => q(km {0}),
						'per' => q({0} kwa kila kilomita),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomita kwa saa),
						'one' => q(km {0}/saa),
						'other' => q(km {0}/saa),
					},
					'kilowatt' => {
						'name' => q(kilowati),
						'one' => q(kilowati {0}),
						'other' => q(kilowati {0}),
					},
					'kilowatt-hour' => {
						'name' => q(kilowati kwa saa),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(noti),
						'one' => q(noti {0}),
						'other' => q(noti {0}),
					},
					'light-year' => {
						'name' => q(miaka ya mwanga),
						'one' => q(ly {0}),
						'other' => q(ly {0}),
					},
					'liter' => {
						'name' => q(lita),
						'one' => q(lita {0}),
						'other' => q(lita {0}),
						'per' => q({0} kwa kila lita),
					},
					'liter-per-100kilometers' => {
						'name' => q(lita kwa kilomita 100),
						'one' => q(lita {0} kwa kilomita 100),
						'other' => q(lita {0}/km100),
					},
					'liter-per-kilometer' => {
						'name' => q(lita kwa kila kilomita),
						'one' => q(lita {0} kwa kilomita),
						'other' => q(lita {0} kwa kilomita),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q(lx {0}),
						'other' => q(lx {0}),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q(megabiti {0}),
						'other' => q(megabiti {0}),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q(MB {0}),
						'other' => q(MB {0}),
					},
					'megahertz' => {
						'name' => q(megahezi),
						'one' => q(megahezi {0}),
						'other' => q(megahezi {0}),
					},
					'megaliter' => {
						'name' => q(megalita),
						'one' => q(megalita {0}),
						'other' => q(megalita {0}),
					},
					'megawatt' => {
						'name' => q(megawati),
						'one' => q(megawati {0}),
						'other' => q(megawati {0}),
					},
					'meter' => {
						'name' => q(mita),
						'one' => q(mita {0}),
						'other' => q(mita {0}),
						'per' => q({0} kwa kila mita),
					},
					'meter-per-second' => {
						'name' => q(mita kwa kila sekunde),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(mita kwa kila sekunde mraba),
						'one' => q(m {0}/s²),
						'other' => q(m {0}/s²),
					},
					'metric-ton' => {
						'name' => q(tani mita),
						'one' => q(tani mita {0}),
						'other' => q(tani mita {0}),
					},
					'microgram' => {
						'name' => q(mikrogramu),
						'one' => q(mikrogramu {0}),
						'other' => q(mikrogramu {0}),
					},
					'micrometer' => {
						'name' => q(mikromita),
						'one' => q(mikromita {0}),
						'other' => q(mikromita {0}),
					},
					'microsecond' => {
						'name' => q(mikrosekunde),
						'one' => q(mikrosekunde {0}),
						'other' => q(mikrosekunde {0}),
					},
					'mile' => {
						'name' => q(maili),
						'one' => q(maili {0}),
						'other' => q(maili {0}),
					},
					'mile-per-gallon' => {
						'name' => q(maili kwa kila galoni),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(maili kwa kila saa),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliampea),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(kipimo cha milibari),
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					'milligram' => {
						'name' => q(miligramu),
						'one' => q(mg {0}),
						'other' => q(mg {0}),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mililita),
						'one' => q(mililita {0}),
						'other' => q(mililita {0}),
					},
					'millimeter' => {
						'name' => q(milimita),
						'one' => q(milimita {0}),
						'other' => q(milimita {0}),
					},
					'millimeter-of-mercury' => {
						'name' => q(milimita za zebaki),
						'one' => q(milimita {0} ya zebaki),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(milimoli kwa kila lita),
						'one' => q(mmol {0}/lita),
						'other' => q(mmol {0}/L),
					},
					'millisecond' => {
						'name' => q(millisekunde),
						'one' => q(millisekunde {0}),
						'other' => q(millisekunde {0}),
					},
					'milliwatt' => {
						'name' => q(miliwati),
						'one' => q(miliwati {0}),
						'other' => q(miliwati {0}),
					},
					'minute' => {
						'name' => q(dakika),
						'one' => q(dakika {0}),
						'other' => q(dakika {0}),
						'per' => q({0} kwa kila dakika),
					},
					'month' => {
						'name' => q(miezi),
						'one' => q(mwezi {0}),
						'other' => q(miezi {0}),
						'per' => q({0} kwa mwezi),
					},
					'nanometer' => {
						'name' => q(nanomita),
						'one' => q(nanomita {0}),
						'other' => q(nanomita {0}),
					},
					'nanosecond' => {
						'name' => q(nanosekunde),
						'one' => q(nanosekunde {0}),
						'other' => q(nanosekunde {0}),
					},
					'nautical-mile' => {
						'name' => q(maili za kibaharia),
						'one' => q(maili {0} ya kibaharia),
						'other' => q(maili {0} za kibaharia),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(aunsi),
						'one' => q(aunsi {0}),
						'other' => q(aunsi {0}),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(tola aunsi),
						'one' => q(tola aunsi {0}),
						'other' => q(tola aunsi {0}),
					},
					'parsec' => {
						'name' => q(kila sekunde),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(asilimia),
						'one' => q(asilimia {0}),
						'other' => q(asilimia {0}),
					},
					'permille' => {
						'name' => q(kwa elfu),
						'one' => q({0} kwa elfu),
						'other' => q({0} kwa elfu),
					},
					'petabyte' => {
						'name' => q(petabaiti),
						'one' => q(PB {0}),
						'other' => q(PB {0}),
					},
					'picometer' => {
						'name' => q(pikomita),
						'one' => q(pikomita {0}),
						'other' => q(pikomita {0}),
					},
					'pint' => {
						'name' => q(painti),
						'one' => q(painti {0}),
						'other' => q(painti {0}),
					},
					'pint-metric' => {
						'name' => q(painti za mizani),
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
					},
					'point' => {
						'name' => q(pointi),
						'one' => q(pointi {0}),
						'other' => q(pointi {0}),
					},
					'pound' => {
						'name' => q(ratili),
						'one' => q(ratili {0}),
						'other' => q(ratili {0}),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(pauni kwa kila inchi mraba),
						'one' => q(psi {0}),
						'other' => q(psi {0}),
					},
					'quart' => {
						'name' => q(kwati),
						'one' => q(kwati {0}),
						'other' => q(kwati {0}),
					},
					'radian' => {
						'name' => q(radiani),
						'one' => q(radiani {0}),
						'other' => q(radiani {0}),
					},
					'revolution' => {
						'name' => q(mzunguko),
						'one' => q(mzunguko {0}),
						'other' => q(mizunguko {0}),
					},
					'second' => {
						'name' => q(sekunde),
						'one' => q(sekunde {0}),
						'other' => q(sekunde {0}),
						'per' => q({0} kwa kila sekunde),
					},
					'square-centimeter' => {
						'name' => q(sentimita mraba),
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(futi za mraba),
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
					},
					'square-inch' => {
						'name' => q(inchi za mraba),
						'one' => q(in² {0}),
						'other' => q(in² {0}),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(kilomita za mraba),
						'one' => q(km² {0}),
						'other' => q(km² {0}),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(mita za mraba),
						'one' => q(mita {0} ya mraba),
						'other' => q(m² {0}),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(maili za mraba),
						'one' => q(maili {0} ya mraba),
						'other' => q(maili {0} za mraba),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yadi za mraba),
						'one' => q(yadi {0} ya mraba),
						'other' => q(yadi {0} za mraba),
					},
					'tablespoon' => {
						'name' => q(vijiko vikubwa),
						'one' => q(kijiko {0} kikubwa),
						'other' => q(vijiko {0} vikubwa),
					},
					'teaspoon' => {
						'name' => q(vijiko vidogo),
						'one' => q(kijiko {0} kidogo),
						'other' => q(vijiko {0} vidogo),
					},
					'terabit' => {
						'name' => q(terabiti),
						'one' => q(terabiti {0}),
						'other' => q(terabiti {0}),
					},
					'terabyte' => {
						'name' => q(terabaiti),
						'one' => q(terabaiti {0}),
						'other' => q(terabaiti {0}),
					},
					'ton' => {
						'name' => q(tani),
						'one' => q(tani {0}),
						'other' => q(tani {0}),
					},
					'volt' => {
						'name' => q(volti),
						'one' => q(volti {0}),
						'other' => q(volti {0}),
					},
					'watt' => {
						'name' => q(wati),
						'one' => q(wati {0}),
						'other' => q(wati {0}),
					},
					'week' => {
						'name' => q(wiki),
						'one' => q(wiki {0}),
						'other' => q(wiki {0}),
						'per' => q({0} kwa wiki),
					},
					'yard' => {
						'name' => q(yadi),
						'one' => q(yadi {0}),
						'other' => q(yadi {0}),
					},
					'year' => {
						'name' => q(miaka),
						'one' => q(mwaka {0}),
						'other' => q(miaka {0}),
						'per' => q({0} kwa mwaka),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} na {1}),
				2 => q({0} na {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirham ya Falme za Kiarabu),
				'one' => q(dirham ya Falme za Kiarabu),
				'other' => q(dirham za Falme za Kiarabu),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghani ya Afghanistan),
				'one' => q(afghani ya Afghanistan),
				'other' => q(afghani za Afghanistan),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek ya Albania),
				'one' => q(lek ya Albania),
				'other' => q(lek za Albania),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram ya Armenia),
				'one' => q(dram ya Armenia),
				'other' => q(dram za Armenia),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Guilder ya Antili za Kiholanzi),
				'one' => q(guilder ya Antili za Kiholanzi),
				'other' => q(guilder za Antili za Kiholanzi),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza ya Angola),
				'one' => q(kwanza ya Angola),
				'other' => q(kwanza za Angola),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Peso ya Argentina),
				'one' => q(Peso ya Argentina),
				'other' => q(Peso za Argentina),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dola ya Australia),
				'one' => q(dola ya Australia),
				'other' => q(dola za Australia),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florin ya Aruba),
				'one' => q(florin ya Aruba),
				'other' => q(florin za Aruba),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat ya Azerbaijan),
				'one' => q(manat ya Azerbaijan),
				'other' => q(manat za Azerbaijan),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Convertible Mark ya Bosnia na Hezegovina),
				'one' => q(convertible mark ya Bosnia na Hezegovina),
				'other' => q(convertible mark za Bosnia na Hezegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dola ya Barbados),
				'one' => q(dola ya Barbados),
				'other' => q(dola za Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka ya Bangladesh),
				'one' => q(taka ya Bangladesh),
				'other' => q(taka za Bangladesh),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev ya Bulgaria),
				'one' => q(lev ya Bulgaria),
				'other' => q(lev za Bulgaria),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar ya Bahrain),
				'one' => q(dinar ya Bahrain),
				'other' => q(dinar za Bahrain),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Faranga ya Burundi),
				'one' => q(faranga ya Burundi),
				'other' => q(faranga za Burundi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dola ya Bermuda),
				'one' => q(dola ya Bermuda),
				'other' => q(dola za Bermuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dola ya Brunei),
				'one' => q(dola ya Brunei),
				'other' => q(dola za Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano ya Bolivia),
				'one' => q(Boliviano ya Bolivia),
				'other' => q(Boliviano za Bolivia),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Real ya Brazil),
				'one' => q(Real ya Brazil),
				'other' => q(Real za Brazil),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dola ya Bahamas),
				'one' => q(dola ya Bahamas),
				'other' => q(dola za Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum ya Bhutan),
				'one' => q(ngultrum ya Bhutan),
				'other' => q(ngultrum za Bhutan),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula ya Botswana),
				'one' => q(pula ya Botswana),
				'other' => q(pula za Botswana),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Ruble ya Belarus),
				'one' => q(ruble ya Belarus),
				'other' => q(ruble za Belarus),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Ruble ya Belarusi \(2000–2016\)),
				'one' => q(Ruble ya Belarusi \(2000–2016\)),
				'other' => q(Ruble za Belarusi \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dola ya Belize),
				'one' => q(dola ya Belize),
				'other' => q(dola za Belize),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dola ya Canada),
				'one' => q(dola ya Canada),
				'other' => q(dola za Canada),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Faranga ya Kongo),
				'one' => q(faranga ya Kongo),
				'other' => q(faranga za Kongo),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Faranga ya Uswisi),
				'one' => q(faranga ya Uswisi),
				'other' => q(faranga za Uswisi),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso ya Chile),
				'one' => q(Peso ya Chile),
				'other' => q(Peso za Chile),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Yuan ya Uchina \(huru\)),
				'one' => q(yuan ya Uchina \(huru\)),
				'other' => q(yuan ya Uchina \(huru\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan ya Uchina),
				'one' => q(yuan ya Uchina),
				'other' => q(yuan za Uchina),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Peso ya Colombia),
				'one' => q(Peso ya Colombia),
				'other' => q(Peso za Colombia),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colon ya Costa Rica),
				'one' => q(colon ya Costa Rica),
				'other' => q(colon za Costa Rica),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso ya Cuba Inayoweza Kubadilishwa),
				'one' => q(Peso ya Cuba Inayoweza Kubadilishwa),
				'other' => q(Peso za Cuba Zinazoweza Kubadilishwa),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso ya Cuba),
				'one' => q(Peso ya Cuba),
				'other' => q(Peso za Cuba),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Eskudo ya Cape Verde),
				'one' => q(eskudo ya Cape Verde),
				'other' => q(eskudo za Cape Verde),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(CZK),
				'one' => q(koruna ya Jamhuri ya Czech),
				'other' => q(koruna za Jamhuri ya Czech),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Faranga ya Djibouti),
				'one' => q(faranga ya Djibouti),
				'other' => q(faranga za Djibouti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Krone ya Denmark),
				'one' => q(krone ya Denmark),
				'other' => q(krone za Denmark),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso ya Dominica),
				'one' => q(peso ya Dominica),
				'other' => q(peso za Dominica),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Dinar ya Aljeria),
				'one' => q(dinar ya Aljeria),
				'other' => q(dinar za Aljeria),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Pauni ya Misri),
				'one' => q(pauni ya Misri),
				'other' => q(pauni za Misri),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa ya Eritrea),
				'one' => q(nakfa ya Eritrea),
				'other' => q(nakfa za Eritrea),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr ya Uhabeshi),
				'one' => q(birr ya Uhabeshi),
				'other' => q(birr za Uhabeshi),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Yuro),
				'one' => q(yuro),
				'other' => q(yuro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dola ya Fiji),
				'one' => q(dola ya Fiji),
				'other' => q(dola za Fiji),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Pauni ya Visiwa vya Falkland),
				'one' => q(Pauni ya Visiwa vya Falkland),
				'other' => q(Pauni za Visiwa vya Falkland),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Pauni ya Uingereza),
				'one' => q(pauni ya Uingereza),
				'other' => q(pauni za Uingereza),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari ya Georgia),
				'one' => q(lari ya Georgia),
				'other' => q(lari za Georgia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Ghana),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi ya Ghana),
				'one' => q(cedi ya Ghana),
				'other' => q(cedi za Ghana),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Pauni ya Gibraltar),
				'one' => q(pauni ya Gibraltar),
				'other' => q(pauni za Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi ya Gambia),
				'one' => q(dalasi ya Gambia),
				'other' => q(dalasi za Gambia),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal ya Guatemala),
				'one' => q(quetzal ya Guatemala),
				'other' => q(quetzal za Guatemala),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dola ya Guyana),
				'one' => q(Dola ya Guyana),
				'other' => q(Dola za Guyana),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dola ya Hong Kong),
				'one' => q(dola ya Hong Kong),
				'other' => q(dola za Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira ya Hondurasi),
				'one' => q(lempira ya Hondurasi),
				'other' => q(lempira za Hondurasi),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna ya Croatia),
				'one' => q(kuna ya Croatia),
				'other' => q(kuna za Croatia),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde ya Haiti),
				'one' => q(gourde ya Haiti),
				'other' => q(gourde za Haiti),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forint ya Hungaria),
				'one' => q(forint ya Hungaria),
				'other' => q(forint za Hungaria),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Rupiah ya Indonesia),
				'one' => q(rupiah ya Indonesia),
				'other' => q(rupiah za Indonesia),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Shekeli Mpya ya Israel),
				'one' => q(shekeli mpya ya Israel),
				'other' => q(shekeli mpya za Israel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia ya India),
				'one' => q(rupia ya India),
				'other' => q(rupia za India),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar ya Iraq),
				'one' => q(dinar ya Iraq),
				'other' => q(dinar za Iraq),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial ya Iran),
				'one' => q(rial ya Iran),
				'other' => q(rial za Iran),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Krona ya Aisilandi),
				'one' => q(krona ya Aisilandi),
				'other' => q(krona za Aisilandi),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dola ya Jamaica),
				'one' => q(dola ya Jamaica),
				'other' => q(dola za Jamaica),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar ya Jordan),
				'one' => q(dinar ya Jordan),
				'other' => q(dinar za Jordan),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yen ya Ujapani),
				'one' => q(yen ya Ujapani),
				'other' => q(yen za Ujapani),
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
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som ya Kyrgystan),
				'one' => q(som ya Kyrgystan),
				'other' => q(som za Kyrgystan),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel ya Cambodia),
				'one' => q(riel ya Cambodia),
				'other' => q(riel za Cambodia),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Faranga ya Comoros),
				'one' => q(faranga ya Comoros),
				'other' => q(faranga za Comoros),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won ya Korea Kaskazini),
				'one' => q(won ya Korea Kaskazini),
				'other' => q(won za Korea Kaskazini),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won ya Korea Kusini),
				'one' => q(won ya Korea Kusini),
				'other' => q(won za Korea Kusini),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar ya Kuwait),
				'one' => q(dinar ya Kuwait),
				'other' => q(dinar za Kuwait),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dola ya Visiwa vya Cayman),
				'one' => q(dola ya Visiwa vya Cayman),
				'other' => q(Dola ya Visiwa vya Cayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge ya Kazakhstan),
				'one' => q(tenge ya Kazakhstan),
				'other' => q(tenge za Kazakhstan),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip ya Laosi),
				'one' => q(kip ya Laosi),
				'other' => q(kip za Laosi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Pauni ya Lebanon),
				'one' => q(pauni ya Lebanon),
				'other' => q(pauni za Lebanon),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia ya Sri Lanka),
				'one' => q(rupia ya Sri Lanka),
				'other' => q(rupia za Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dola ya Liberia),
				'one' => q(dola ya Liberia),
				'other' => q(dola za Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesoto),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas ya Lithuania),
				'one' => q(Litas ya Lithuania),
				'other' => q(Litas za Lithuania),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lats ya Lativia),
				'one' => q(Lats ya Lativia),
				'other' => q(Lats za Lativia),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinari ya Libya),
				'one' => q(dinari ya Libya),
				'other' => q(dinari za Libya),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Dirham ya Morocco),
				'one' => q(dirham ya Morocco),
				'other' => q(dirham za Morocco),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu ya Moldova),
				'one' => q(leu ya Moldova),
				'other' => q(leu za Moldova),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariari ya Madagascar),
				'one' => q(ariari ya Madagascar),
				'other' => q(ariari za Madagascar),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denar ya Macedonia),
				'one' => q(denar ya Macedonia),
				'other' => q(denar za Macedonia),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat ya Myanmar),
				'one' => q(kyat ya Myanmar),
				'other' => q(kyat za Myanmar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik ya Mongolia),
				'one' => q(tugrik ya Mongolia),
				'other' => q(tugrik za Mongolia),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca ya Macau),
				'one' => q(pataca ya Macau),
				'other' => q(pataca za Macau),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Ouguiya ya Mauritania \(1973–2017\)),
				'one' => q(ouguiya ya Mauritania \(1973–2017\)),
				'other' => q(ouguiya za Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Ouguiya ya Mauritania),
				'one' => q(ouguiya ya Mauritania),
				'other' => q(ouguiya za Mauritania),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia ya Mauritius),
				'one' => q(rupia ya Mauritius),
				'other' => q(rupia za Mauritius),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiyaa ya Maldives),
				'one' => q(rufiyaa ya Maldives),
				'other' => q(rufiyaa za Maldives),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha ya Malawi),
				'one' => q(kwacha ya Malawi),
				'other' => q(kwacha za Malawi),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Peso ya Mexico),
				'one' => q(peso ya Mexico),
				'other' => q(peso za Mexico),
			},
		},
		'MYR' => {
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metikali ya Msumbiji),
				'one' => q(Metikali ya Msumbiji),
				'other' => q(Metikali za Msumbiji),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dola ya Namibia),
				'one' => q(dola ya Namibia),
				'other' => q(dola za Namibia),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Naira ya Nigeria),
				'one' => q(naira ya Nigeria),
				'other' => q(naira za Nigeria),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Cordoba ya Nicaragua),
				'one' => q(cordoba ya Nicaragua),
				'other' => q(cordoba za Nicaragua),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Krone ya Norway),
				'one' => q(krone ya Norway),
				'other' => q(krone za Norway),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia ya Nepal),
				'one' => q(rupia ya Nepal),
				'other' => q(rupia za Nepal),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dola ya New Zealand),
				'one' => q(dola ya New Zealand),
				'other' => q(dola za New Zealand),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial ya Omani),
				'one' => q(rial ya Omani),
				'other' => q(rial za Omani),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa ya Panama),
				'one' => q(balboa ya Panama),
				'other' => q(balboa ya Panama),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol ya Peru),
				'one' => q(Sol ya Peru),
				'other' => q(Sol za Peru),
			},
		},
		'PGK' => {
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia ya Pakistan),
				'one' => q(rupia ya Pakistan),
				'other' => q(rupia za Pakistan),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty ya Poland),
				'one' => q(zloty ya Poland),
				'other' => q(zloty za Poland),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani ya Paraguay),
				'one' => q(Guarani ya Paraguay),
				'other' => q(Guarani za Paraguay),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Rial ya Qatar),
				'one' => q(rial ya Qatar),
				'other' => q(rial ya Qatar),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu ya Romania),
				'one' => q(leu ya Romania),
				'other' => q(leu za Romania),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar ya Serbia),
				'one' => q(dinar ya Serbia),
				'other' => q(dinar za Serbia),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Ruble ya Urusi),
				'one' => q(ruble ya Urusi),
				'other' => q(ruble za Urusi),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Faranga ya Rwanda),
				'one' => q(faranga ya Rwanda),
				'other' => q(faranga za Rwanda),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal ya Saudia),
				'one' => q(riyal ya Saudia),
				'other' => q(riyal za Saudia),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dola ya Visiwa vya Solomon),
				'one' => q(dola ya Visiwa vya Solomon),
				'other' => q(dola za Visiwa vya Solomon),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia ya Ushelisheli),
				'one' => q(rupia ya Ushelisheli),
				'other' => q(rupia za Ushelisheli),
			},
		},
		'SDG' => {
			symbol => 'SDG',
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
			symbol => 'SEK',
			display_name => {
				'currency' => q(Krona ya Uswidi),
				'one' => q(krona ya Uswidi),
				'other' => q(krona za Uswidi),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dola ya Singapore),
				'one' => q(dola ya Singapore),
				'other' => q(dola za Singapore),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Pauni ya St. Helena),
				'one' => q(pauni ya St. Helena),
				'other' => q(pauni za St. Helena),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone),
				'one' => q(leone),
				'other' => q(leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Shilingi ya Somalia),
				'one' => q(shilingi ya Somalia),
				'other' => q(shilingi za Somalia),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Dola ya Suriname),
				'one' => q(Dola ya Suriname),
				'other' => q(Dola za Suriname),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Pauni ya Sudan Kusini),
				'one' => q(pauni ya Sudan Kusini),
				'other' => q(pauni za Sudan Kusini),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe \(1977–2017\)),
				'one' => q(dobra ya Sao Tome na Principe \(1977–2017\)),
				'other' => q(dobra za Sao Tome na Principe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe),
				'one' => q(dobra ya Sao Tome na Principe),
				'other' => q(dobra za Sao Tome na Principe),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Pauni ya Syria),
				'one' => q(pauni ya Syria),
				'other' => q(pauni za Syria),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni),
				'one' => q(lilangeni),
				'other' => q(lilangeni),
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
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni ya Tajikistan),
				'one' => q(somoni ya Tajikistan),
				'other' => q(somoni za Tajikistan),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat ya Turkmenistan),
				'one' => q(manat ya Turkmenistan),
				'other' => q(manat za Turkmenistan),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinari ya Tunisia),
				'one' => q(dinari ya Tunisia),
				'other' => q(dinari za Tunisia),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Paʻanga ya Tonga),
				'one' => q(paʻanga ya Tonga),
				'other' => q(paʻanga za Tonga),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira ya Uturuki),
				'one' => q(lira ya Uturuki),
				'other' => q(lira za Uturuki),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'UAH',
			display_name => {
				'currency' => q(Hryvnia ya Ukraine),
				'one' => q(hryvnia ya Ukraine),
				'other' => q(hryvnia za Ukraine),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilingi ya Uganda),
				'one' => q(shilingi ya Uganda),
				'other' => q(shilingi za Uganda),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Dola ya Marekani),
				'one' => q(dola ya Marekani),
				'other' => q(dola za Marekani),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso ya Uruguay),
				'one' => q(Peso ya Uruguay),
				'other' => q(Peso za Uruguay),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som ya Uzbekistan),
				'one' => q(som ya Uzbekistan),
				'other' => q(som za Uzbekistan),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolivar ya Venezuela \(2008–2018\)),
				'one' => q(Bolivar ya Venezuela \(2008–2018\)),
				'other' => q(Bolivar za Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Bolivar ya Venezuela),
				'one' => q(Bolivar ya Venezuela),
				'other' => q(Bolivar za Venezuela),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong ya Vietnam),
				'one' => q(dong ya Vietnam),
				'other' => q(dong za Vietnam),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu ya Vanuatu),
				'one' => q(vatu ya Vanuatu),
				'other' => q(vatu za Vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala ya Samoa),
				'one' => q(tala ya Samoa),
				'other' => q(tala za Samoa),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Faranga ya Afrika ya Kati CFA),
				'one' => q(faranga ya Afrika ya Kati CFA),
				'other' => q(faranga za Afrika ya Kati CFA),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Dola ya Caribbean Mashariki),
				'one' => q(Dola ya Caribbean Mashariki),
				'other' => q(Dola za Caribbean Mashariki),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Faranga ya Afrika Magharibi CFA),
				'one' => q(faranga ya Afrika Magharibi CFA),
				'other' => q(faranga za Afrika Magharibi CFA),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
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
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial ya Yemen),
				'one' => q(rial ya Yemen),
				'other' => q(rial za Yemen),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
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
			symbol => 'ZMW',
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
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
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
				'stand-alone' => {
					abbreviated => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
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
					abbreviated => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Robo ya 1',
						1 => 'Robo ya 2',
						2 => 'Robo ya 3',
						3 => 'Robo ya 4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
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
					'am' => q{AM},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
					'pm' => q{PM},
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
					'am' => q{AM},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{alasiri},
					'am' => q{AM},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{mchana},
					'am' => q{AM},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{mchana},
					'am' => q{AM},
					'evening1' => q{jioni},
					'midnight' => q{saa sita za usiku},
					'morning1' => q{alfajiri},
					'morning2' => q{asubuhi},
					'night1' => q{usiku},
					'noon' => q{saa sita za mchana},
					'pm' => q{PM},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'wiki' W 'ya' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{y QQQ},
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
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d– E, MMM d y},
				d => q{E, MMM d – E, MMM d y},
				y => q{E, MMM d y – E, MMM d y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – d, y},
				d => q{MMM d – d, y},
				y => q{MMM d y – MMM d y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT {0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q(Saa za {0}),
		regionFormat => q(Saa za Mchana za {0}),
		regionFormat => q(Saa za wastani za {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Saa za Afghanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algiers#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadishu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Jiji la Mexico#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
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
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damascus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapore#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Saa za Mchana za Atlantiki#,
				'generic' => q#Saa za Atlantiki#,
				'standard' => q#Saa za Wastani za Atlantiki#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia Kusini#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
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
				'standard' => q#Saa za Kisiwa cha Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Saa za Visiwa vya Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Colombia#,
				'generic' => q#Saa za Colombia#,
				'standard' => q#Saa za Wastani za Colombia#,
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
				'daylight' => q#Saa za Mchana za Cuba#,
				'generic' => q#Saa za Cuba#,
				'standard' => q#Saa za Wastani ya Cuba#,
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
				'standard' => q#Saa za Ecuador#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucharest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Saa za Majira ya Joto za Ayalandi#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Saa za Majira ya Joto za Uingereza#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembourg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscow#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prague#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rome#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Saa za Majira ya joto za Ulaya ya Kati#,
				'generic' => q#Saa za Ulaya ya Kati#,
				'standard' => q#Saa za Wastani za Ulaya ya kati#,
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
				'daylight' => q#Saa za Majira ya joto za Georgia#,
				'generic' => q#Saa za Georgia#,
				'standard' => q#Saa za Wastani za Georgia#,
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
				'standard' => q#Saa Wastani za India#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
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
				'standard' => q#Saa Wastani za Japan#,
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
				'daylight' => q#Saa za Majira ya joto za Mauritius#,
				'generic' => q#Saa za Mauritius#,
				'standard' => q#Saa za Wastani za Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Saa za Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Saa za mchana za Mexico Kaskazini Magharibi#,
				'generic' => q#Saa za Mexico Kaskazini Magharibi#,
				'standard' => q#Saa za Wastani za Mexico Kaskazini Magharibi#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Saa za mchana za pasifiki za Mexico#,
				'generic' => q#Saa za pasifiki za Mexico#,
				'standard' => q#Saa za wastani za pasifiki za Mexico#,
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
				'standard' => q#Saa za Kisiwa cha Norfolk#,
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
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
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
				'daylight' => q#Saa za Majira ya joto za Paraguay#,
				'generic' => q#Saa za Paraguay#,
				'standard' => q#Saa za Wastani za Paraguay#,
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
				'daylight' => q#Saa za Majira ya joto za Uruguay#,
				'generic' => q#Saa za Uruguay#,
				'standard' => q#Saa za Wastani za Uruguay#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
