=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Lv - Package for language Latvian

=cut

package Locale::CLDR::Locales::Lv;
# This file auto generated from Data\common\main\lv.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mīnus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulle),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komats →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(viena),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(divas),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trīs),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četras),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(piecas),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sešas),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(septiņas),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(astoņas),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(deviņas),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-prefixed←desmit[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(simt[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-prefixed←simt[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tūkstoš[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-prefixed←tūkstoš[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← tūkstoši[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(viens miljons[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miljoni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(viens miljards[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miljardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(viens biljons[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biljoni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(viens biljards[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biljardi[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mīnus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulle),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komats →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(viens),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(divi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trīs),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četri),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pieci),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seši),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(septiņi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(astoņi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(deviņi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(desmit),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→%%spellout-prefixed→padsmit),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%spellout-prefixed←desmit[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(simt[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%%spellout-prefixed←simt[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tūkstoš[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-prefixed←tūkstoš[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← tūkstoši[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(viens miljons[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miljoni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(viens miljards[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miljardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(viens biljons[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biljoni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(viens biljards[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biljardi[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
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
		'spellout-prefixed' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ERROR),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(vien),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(div),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trīs),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četr),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(piec),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seš),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(septiņ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(astoņ),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(deviņ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ERROR),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ERROR),
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
				'aa' => 'afāru',
 				'ab' => 'abhāzu',
 				'ace' => 'ačinu',
 				'ach' => 'ačolu',
 				'ada' => 'adangmu',
 				'ady' => 'adigu',
 				'ae' => 'avesta',
 				'af' => 'afrikandu',
 				'afh' => 'afrihili',
 				'agq' => 'aghemu',
 				'ain' => 'ainu',
 				'ak' => 'akanu',
 				'akk' => 'akadiešu',
 				'ale' => 'aleutu',
 				'alt' => 'dienvidaltajiešu',
 				'am' => 'amharu',
 				'an' => 'aragoniešu',
 				'ang' => 'senangļu',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arābu',
 				'ar_001' => 'mūsdienu standarta arābu',
 				'arc' => 'aramiešu',
 				'arn' => 'araukāņu',
 				'arp' => 'arapahu',
 				'ars' => 'ņedžu arābu',
 				'arw' => 'aravaku',
 				'as' => 'asamiešu',
 				'asa' => 'asu',
 				'ast' => 'astūriešu',
 				'atj' => 'atikameku',
 				'av' => 'avāru',
 				'awa' => 'avadhu',
 				'ay' => 'aimaru',
 				'az' => 'azerbaidžāņu',
 				'az_Arab' => 'dienvidazerbaidžāņu',
 				'ba' => 'baškīru',
 				'bal' => 'beludžu',
 				'ban' => 'baliešu',
 				'bas' => 'basu',
 				'bax' => 'bamumu',
 				'bbj' => 'gomalu',
 				'be' => 'baltkrievu',
 				'bej' => 'bedžu',
 				'bem' => 'bembu',
 				'bez' => 'bena',
 				'bfd' => 'bafutu',
 				'bg' => 'bulgāru',
 				'bgc' => 'harjanvi',
 				'bgn' => 'rietumbeludžu',
 				'bho' => 'bhodžpūru',
 				'bi' => 'bišlamā',
 				'bik' => 'bikolu',
 				'bin' => 'binu',
 				'bkm' => 'komu',
 				'bla' => 'siksiku',
 				'bm' => 'bambaru',
 				'bn' => 'bengāļu',
 				'bo' => 'tibetiešu',
 				'br' => 'bretoņu',
 				'bra' => 'bradžiešu',
 				'brx' => 'bodo',
 				'bs' => 'bosniešu',
 				'bss' => 'nkosi',
 				'bua' => 'burjatu',
 				'bug' => 'bugu',
 				'bum' => 'bulu',
 				'byn' => 'bilinu',
 				'byv' => 'medumbu',
 				'ca' => 'katalāņu',
 				'cad' => 'kadu',
 				'car' => 'karību',
 				'cay' => 'kajuga',
 				'cch' => 'atsamu',
 				'ccp' => 'čakmu',
 				'ce' => 'čečenu',
 				'ceb' => 'sebuāņu',
 				'cgg' => 'kiga',
 				'ch' => 'čamorru',
 				'chb' => 'čibču',
 				'chg' => 'džagatajs',
 				'chk' => 'čūku',
 				'chm' => 'mariešu',
 				'chn' => 'činuku žargons',
 				'cho' => 'čoktavu',
 				'chp' => 'čipevaianu',
 				'chr' => 'čiroku',
 				'chy' => 'šejenu',
 				'ckb' => 'centrālkurdu',
 				'ckb@alt=variant' => 'sorani kurdu',
 				'clc' => 'čilkotīnu',
 				'co' => 'korsikāņu',
 				'cop' => 'koptu',
 				'cr' => 'krī',
 				'crg' => 'mičifu',
 				'crh' => 'Krimas tatāru',
 				'crj' => 'dienvidaustrumu krī',
 				'crk' => 'līdzenumu krī',
 				'crl' => 'ziemeļaustrumu krī',
 				'crm' => 'mūsu krī',
 				'crr' => 'Karolīnas algonkinu',
 				'crs' => 'franciskā kreoliskā valoda (Seišelu salas)',
 				'cs' => 'čehu',
 				'csb' => 'kašubu',
 				'csw' => 'purvu krī',
 				'cu' => 'baznīcslāvu',
 				'cv' => 'čuvašu',
 				'cy' => 'velsiešu',
 				'da' => 'dāņu',
 				'dak' => 'dakotu',
 				'dar' => 'dargu',
 				'dav' => 'taitu',
 				'de' => 'vācu',
 				'de_CH' => 'augšvācu (Šveice)',
 				'del' => 'delavēru',
 				'den' => 'sleivu',
 				'dgr' => 'dogribu',
 				'din' => 'dinku',
 				'dje' => 'zarmu',
 				'doi' => 'dogru',
 				'dsb' => 'lejassorbu',
 				'dua' => 'dualu',
 				'dum' => 'vidusholandiešu',
 				'dv' => 'maldīviešu',
 				'dyo' => 'diola-fonjī',
 				'dyu' => 'diūlu',
 				'dz' => 'dzongke',
 				'dzg' => 'dazu',
 				'ebu' => 'kjembu',
 				'ee' => 'evu',
 				'efi' => 'efiku',
 				'egy' => 'ēģiptiešu',
 				'eka' => 'ekadžuku',
 				'el' => 'grieķu',
 				'elx' => 'elamiešu',
 				'en' => 'angļu',
 				'en_GB' => 'angļu (Lielbritānija)',
 				'enm' => 'vidusangļu',
 				'eo' => 'esperanto',
 				'es' => 'spāņu',
 				'et' => 'igauņu',
 				'eu' => 'basku',
 				'ewo' => 'evondu',
 				'fa' => 'persiešu',
 				'fa_AF' => 'darī',
 				'fan' => 'fangu',
 				'fat' => 'fantu',
 				'ff' => 'fulu',
 				'fi' => 'somu',
 				'fil' => 'filipīniešu',
 				'fj' => 'fidžiešu',
 				'fo' => 'fēru',
 				'fon' => 'fonu',
 				'fr' => 'franču',
 				'frc' => 'kadžūnu franču',
 				'frm' => 'vidusfranču',
 				'fro' => 'senfranču',
 				'frr' => 'ziemeļfrīzu',
 				'frs' => 'austrumfrīzu',
 				'fur' => 'friūlu',
 				'fy' => 'rietumfrīzu',
 				'ga' => 'īru',
 				'gaa' => 'ga',
 				'gag' => 'gagauzu',
 				'gay' => 'gajo',
 				'gba' => 'gbaju',
 				'gd' => 'skotu gēlu',
 				'gez' => 'gēzu',
 				'gil' => 'kiribatiešu',
 				'gl' => 'galisiešu',
 				'gmh' => 'vidusaugšvācu',
 				'gn' => 'gvaranu',
 				'goh' => 'senaugšvācu',
 				'gon' => 'gondu valodas',
 				'gor' => 'gorontalu',
 				'got' => 'gotu',
 				'grb' => 'grebo',
 				'grc' => 'sengrieķu',
 				'gsw' => 'Šveices vācu',
 				'gu' => 'gudžaratu',
 				'guz' => 'gusii',
 				'gv' => 'meniešu',
 				'gwi' => 'kučinu',
 				'ha' => 'hausu',
 				'hai' => 'haidu',
 				'haw' => 'havajiešu',
 				'hax' => 'dienvidhaidu',
 				'he' => 'ivrits',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglišs',
 				'hil' => 'hiligainonu',
 				'hit' => 'hetu',
 				'hmn' => 'hmongu',
 				'ho' => 'hirimotu',
 				'hr' => 'horvātu',
 				'hsb' => 'augšsorbu',
 				'ht' => 'haitiešu',
 				'hu' => 'ungāru',
 				'hup' => 'hupu',
 				'hur' => 'halkomelenu',
 				'hy' => 'armēņu',
 				'hz' => 'hereru',
 				'ia' => 'interlingva',
 				'iba' => 'ibanu',
 				'ibb' => 'ibibio',
 				'id' => 'indonēziešu',
 				'ie' => 'interlingve',
 				'ig' => 'igbo',
 				'ii' => 'Sičuaņas ji',
 				'ik' => 'inupiaku',
 				'ikt' => 'Rietumkanādas inuītu',
 				'ilo' => 'iloku',
 				'inh' => 'ingušu',
 				'io' => 'ido',
 				'is' => 'islandiešu',
 				'it' => 'itāļu',
 				'iu' => 'inuītu',
 				'ja' => 'japāņu',
 				'jbo' => 'ložbans',
 				'jgo' => 'ngomba',
 				'jmc' => 'mačamu',
 				'jpr' => 'jūdpersiešu',
 				'jrb' => 'jūdarābu',
 				'jv' => 'javiešu',
 				'ka' => 'gruzīnu',
 				'kaa' => 'karakalpaku',
 				'kab' => 'kabilu',
 				'kac' => 'kačinu',
 				'kaj' => 'kadži',
 				'kam' => 'kambu',
 				'kaw' => 'kāvi',
 				'kbd' => 'kabardiešu',
 				'kbl' => 'kaņembu',
 				'kcg' => 'katabu',
 				'kde' => 'makonde',
 				'kea' => 'kaboverdiešu',
 				'kfo' => 'koru',
 				'kg' => 'kongu',
 				'kgp' => 'kaingangs',
 				'kha' => 'khasu',
 				'kho' => 'hotaniešu',
 				'khq' => 'koiračiinī',
 				'ki' => 'kikuju',
 				'kj' => 'kvaņamu',
 				'kk' => 'kazahu',
 				'kkj' => 'kako',
 				'kl' => 'grenlandiešu',
 				'kln' => 'kalendžīnu',
 				'km' => 'khmeru',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannadu',
 				'ko' => 'korejiešu',
 				'koi' => 'komiešu-permiešu',
 				'kok' => 'konkanu',
 				'kos' => 'kosrājiešu',
 				'kpe' => 'kpellu',
 				'kr' => 'kanuru',
 				'krc' => 'karačaju un balkāru',
 				'krl' => 'karēļu',
 				'kru' => 'kuruhu',
 				'ks' => 'kašmiriešu',
 				'ksb' => 'šambalu',
 				'ksf' => 'bafiju',
 				'ksh' => 'Ķelnes vācu',
 				'ku' => 'kurdu',
 				'kum' => 'kumiku',
 				'kut' => 'kutenaju',
 				'kv' => 'komiešu',
 				'kw' => 'korniešu',
 				'kwk' => 'kvakvala',
 				'ky' => 'kirgīzu',
 				'la' => 'latīņu',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'landu',
 				'lam' => 'lambu',
 				'lb' => 'luksemburgiešu',
 				'lez' => 'lezgīnu',
 				'lg' => 'gandu',
 				'li' => 'limburgiešu',
 				'lil' => 'lilluetu',
 				'lkt' => 'lakotu',
 				'ln' => 'lingala',
 				'lo' => 'laosiešu',
 				'lol' => 'mongu',
 				'lou' => 'Luiziānas kreolu',
 				'loz' => 'lozu',
 				'lrc' => 'ziemeļluru',
 				'lsm' => 'sāmia',
 				'lt' => 'lietuviešu',
 				'lu' => 'lubakatanga',
 				'lua' => 'lubalulva',
 				'lui' => 'luisenu',
 				'lun' => 'lundu',
 				'luo' => 'luo',
 				'lus' => 'lušeju',
 				'luy' => 'luhju',
 				'lv' => 'latviešu',
 				'mad' => 'maduriešu',
 				'maf' => 'mafu',
 				'mag' => 'magahiešu',
 				'mai' => 'maithili',
 				'mak' => 'makasaru',
 				'man' => 'mandingu',
 				'mas' => 'masaju',
 				'mde' => 'mabu',
 				'mdf' => 'mokšu',
 				'mdr' => 'mandaru',
 				'men' => 'mendu',
 				'mer' => 'meru',
 				'mfe' => 'Maurīcijas kreolu',
 				'mg' => 'malagasu',
 				'mga' => 'vidusīru',
 				'mgh' => 'makua',
 				'mgo' => 'metu',
 				'mh' => 'māršaliešu',
 				'mi' => 'maoru',
 				'mic' => 'mikmaku',
 				'min' => 'minangkabavu',
 				'mk' => 'maķedoniešu',
 				'ml' => 'malajalu',
 				'mn' => 'mongoļu',
 				'mnc' => 'mandžūru',
 				'mni' => 'manipūru',
 				'moe' => 'motanju',
 				'moh' => 'mohauku',
 				'mos' => 'mosu',
 				'mr' => 'marathu',
 				'ms' => 'malajiešu',
 				'mt' => 'maltiešu',
 				'mua' => 'mundangu',
 				'mul' => 'vairākas valodas',
 				'mus' => 'krīku',
 				'mwl' => 'mirandiešu',
 				'mwr' => 'marvaru',
 				'my' => 'birmiešu',
 				'mye' => 'mjenu',
 				'myv' => 'erzju',
 				'mzn' => 'mazanderāņu',
 				'na' => 'nauruiešu',
 				'nap' => 'neapoliešu',
 				'naq' => 'nama',
 				'nb' => 'norvēģu bukmols',
 				'nd' => 'ziemeļndebelu',
 				'nds' => 'lejasvācu',
 				'nds_NL' => 'lejassakšu',
 				'ne' => 'nepāliešu',
 				'new' => 'nevaru',
 				'ng' => 'ndongu',
 				'nia' => 'njasu',
 				'niu' => 'niuāņu',
 				'nl' => 'holandiešu',
 				'nl_BE' => 'flāmu',
 				'nmg' => 'kvasio',
 				'nn' => 'jaunnorvēģu',
 				'nnh' => 'ngjembūnu',
 				'no' => 'norvēģu',
 				'nog' => 'nogaju',
 				'non' => 'sennorvēģu',
 				'nqo' => 'nko',
 				'nr' => 'dienvidndebelu',
 				'nso' => 'ziemeļsotu',
 				'nus' => 'nueru',
 				'nv' => 'navahu',
 				'nwc' => 'klasiskā nevaru',
 				'ny' => 'čičeva',
 				'nym' => 'ņamvezu',
 				'nyn' => 'ņankolu',
 				'nyo' => 'ņoru',
 				'nzi' => 'nzemu',
 				'oc' => 'oksitāņu',
 				'oj' => 'odžibvu',
 				'ojb' => 'ziemeļrietumu odžibvu',
 				'ojc' => 'centrālā odžibvu',
 				'ojs' => 'odži-krī',
 				'ojw' => 'rietumodžibvu',
 				'oka' => 'okanaganu',
 				'om' => 'oromu',
 				'or' => 'oriju',
 				'os' => 'osetīnu',
 				'osa' => 'važāžu',
 				'ota' => 'turku osmaņu',
 				'pa' => 'pandžabu',
 				'pag' => 'pangasinanu',
 				'pal' => 'pehlevi',
 				'pam' => 'pampanganu',
 				'pap' => 'papjamento',
 				'pau' => 'palaviešu',
 				'pcm' => 'Nigērijas pidžinvaloda',
 				'peo' => 'senpersu',
 				'phn' => 'feniķiešu',
 				'pi' => 'pāli',
 				'pis' => 'pidžinvaloda',
 				'pl' => 'poļu',
 				'pon' => 'ponapiešu',
 				'pqm' => 'malisetu-pasamakvodi',
 				'prg' => 'prūšu',
 				'pro' => 'senprovansiešu',
 				'ps' => 'puštu',
 				'pt' => 'portugāļu',
 				'qu' => 'kečvu',
 				'quc' => 'kiče',
 				'raj' => 'radžastāņu',
 				'rap' => 'rapanuju',
 				'rar' => 'rarotongiešu',
 				'rhg' => 'rohindžu',
 				'rm' => 'retoromāņu',
 				'rn' => 'rundu',
 				'ro' => 'rumāņu',
 				'ro_MD' => 'moldāvu',
 				'rof' => 'rombo',
 				'rom' => 'čigānu',
 				'ru' => 'krievu',
 				'rup' => 'aromūnu',
 				'rw' => 'kiņaruanda',
 				'rwk' => 'ruanda',
 				'sa' => 'sanskrits',
 				'sad' => 'sandavu',
 				'sah' => 'jakutu',
 				'sam' => 'Samārijas aramiešu',
 				'saq' => 'samburu',
 				'sas' => 'sasaku',
 				'sat' => 'santalu',
 				'sba' => 'ngambeju',
 				'sbp' => 'sangu',
 				'sc' => 'sardīniešu',
 				'scn' => 'sicīliešu',
 				'sco' => 'skotu',
 				'sd' => 'sindhu',
 				'sdh' => 'dienvidkurdu',
 				'se' => 'ziemeļsāmu',
 				'see' => 'seneku',
 				'seh' => 'senu',
 				'sel' => 'selkupu',
 				'ses' => 'koiraboro senni',
 				'sg' => 'sango',
 				'sga' => 'senīru',
 				'sh' => 'serbu–horvātu',
 				'shi' => 'šilhu',
 				'shn' => 'šanu',
 				'shu' => 'Čadas arābu',
 				'si' => 'singāļu',
 				'sid' => 'sidamu',
 				'sk' => 'slovāku',
 				'sl' => 'slovēņu',
 				'slh' => 'dienvidlušucīdu',
 				'sm' => 'samoāņu',
 				'sma' => 'dienvidsāmu',
 				'smj' => 'Luleo sāmu',
 				'smn' => 'Inari sāmu',
 				'sms' => 'skoltsāmu',
 				'sn' => 'šonu',
 				'snk' => 'soninku',
 				'so' => 'somāļu',
 				'sog' => 'sogdiešu',
 				'sq' => 'albāņu',
 				'sr' => 'serbu',
 				'srn' => 'sranantogo',
 				'srr' => 'serēru',
 				'ss' => 'svatu',
 				'ssy' => 'saho',
 				'st' => 'dienvidsotu',
 				'str' => 'šauruma sališu',
 				'su' => 'zundu',
 				'suk' => 'sukumu',
 				'sus' => 'susu',
 				'sux' => 'šumeru',
 				'sv' => 'zviedru',
 				'sw' => 'svahili',
 				'sw_CD' => 'svahili (Kongo)',
 				'swb' => 'komoru',
 				'syc' => 'klasiskā sīriešu',
 				'syr' => 'sīriešu',
 				'ta' => 'tamilu',
 				'tce' => 'dienvidtutčonu',
 				'te' => 'telugu',
 				'tem' => 'temnu',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetumu',
 				'tg' => 'tadžiku',
 				'tgx' => 'tagišu',
 				'th' => 'taju',
 				'tht' => 'tahltanu',
 				'ti' => 'tigrinja',
 				'tig' => 'tigru',
 				'tiv' => 'tivu',
 				'tk' => 'turkmēņu',
 				'tkl' => 'tokelaviešu',
 				'tl' => 'tagalu',
 				'tlh' => 'klingoņu',
 				'tli' => 'tlinkitu',
 				'tmh' => 'tuaregu',
 				'tn' => 'cvanu',
 				'to' => 'tongiešu',
 				'tog' => 'Njasas tongu',
 				'tok' => 'tokiponu',
 				'tpi' => 'tokpisins',
 				'tr' => 'turku',
 				'trv' => 'taroko',
 				'ts' => 'congu',
 				'tsi' => 'cimšiāņu',
 				'tt' => 'tatāru',
 				'ttm' => 'ziemeļu tučonu',
 				'tum' => 'tumbuku',
 				'tvl' => 'tuvaliešu',
 				'tw' => 'tvī',
 				'twq' => 'tasavaku',
 				'ty' => 'taitiešu',
 				'tyv' => 'tuviešu',
 				'tzm' => 'Centrālmarokas tamazīts',
 				'udm' => 'udmurtu',
 				'ug' => 'uiguru',
 				'uga' => 'ugaritiešu',
 				'uk' => 'ukraiņu',
 				'umb' => 'umbundu',
 				'und' => 'nezināma valoda',
 				'ur' => 'urdu',
 				'uz' => 'uzbeku',
 				'vai' => 'vaju',
 				've' => 'vendu',
 				'vi' => 'vjetnamiešu',
 				'vo' => 'volapiks',
 				'vot' => 'votu',
 				'vun' => 'vundžo',
 				'wa' => 'valoņu',
 				'wae' => 'Vallisas vācu',
 				'wal' => 'valamu',
 				'war' => 'varaju',
 				'was' => 'vašo',
 				'wbp' => 'varlpirī',
 				'wo' => 'volofu',
 				'wuu' => 'vu ķīniešu',
 				'xal' => 'kalmiku',
 				'xh' => 'khosu',
 				'xog' => 'sogu',
 				'yao' => 'jao',
 				'yap' => 'japiešu',
 				'yav' => 'janbaņu',
 				'ybb' => 'jembu',
 				'yi' => 'jidišs',
 				'yo' => 'jorubu',
 				'yrl' => 'njengatu',
 				'yue' => 'kantoniešu',
 				'yue@alt=menu' => 'ķīniešu (kantoniešu)',
 				'za' => 'džuanu',
 				'zap' => 'sapoteku',
 				'zbl' => 'blissimbolika',
 				'zen' => 'zenagu',
 				'zgh' => 'standarta tamazigtu (Maroka)',
 				'zh' => 'ķīniešu',
 				'zh@alt=menu' => 'ķīniešu (mandarīnu)',
 				'zh_Hans' => 'ķīniešu vienkāršotā',
 				'zh_Hans@alt=long' => 'ķīniešu vienkāršotā (mandarīnu)',
 				'zh_Hant' => 'ķīniešu tradicionālā',
 				'zh_Hant@alt=long' => 'ķīniešu tradicionālā (mandarīnu)',
 				'zu' => 'zulu',
 				'zun' => 'zunju',
 				'zxx' => 'bez lingvistiska satura',
 				'zza' => 'zazaki',

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
			'Adlm' => 'adlama',
 			'Arab' => 'arābu',
 			'Arab@alt=variant' => 'persiešu-arābu',
 			'Aran' => 'nastaliku',
 			'Armi' => 'aramiešu',
 			'Armn' => 'armēņu',
 			'Bali' => 'baliešu',
 			'Beng' => 'bengāļu',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'Braila raksts',
 			'Cakm' => 'čakmu',
 			'Cans' => 'vienotā Kanādas aborigēnu zilbju rakstība',
 			'Cher' => 'irokēzu',
 			'Copt' => 'koptu',
 			'Cyrl' => 'kirilica',
 			'Cyrs' => 'senslāvu',
 			'Deva' => 'dēvanāgari',
 			'Egyd' => 'demotiskais raksts',
 			'Egyh' => 'hierātiskais raksts',
 			'Egyp' => 'ēģiptiešu hieroglifi',
 			'Ethi' => 'etiopiešu',
 			'Geor' => 'gruzīnu',
 			'Goth' => 'gotu',
 			'Grek' => 'grieķu',
 			'Gujr' => 'gudžaratu',
 			'Guru' => 'pandžabu',
 			'Hanb' => 'haņu ar bopomofo',
 			'Hang' => 'hangils',
 			'Hani' => 'haņu',
 			'Hans' => 'vienkāršotā',
 			'Hans@alt=stand-alone' => 'haņu vienkāršotā',
 			'Hant' => 'tradicionālā',
 			'Hant@alt=stand-alone' => 'haņu tradicionālā',
 			'Hebr' => 'ivrits',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japāņu zilbju alfabēts',
 			'Hung' => 'senungāru',
 			'Ital' => 'vecitāļu',
 			'Jamo' => 'jamo',
 			'Java' => 'javiešu',
 			'Jpan' => 'japāņu',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmeru',
 			'Knda' => 'kannadu',
 			'Kore' => 'korejiešu',
 			'Laoo' => 'laosiešu',
 			'Latn' => 'latīņu',
 			'Lina' => 'lineārā A',
 			'Linb' => 'lineārā B',
 			'Lydi' => 'līdiešu',
 			'Maya' => 'maiju',
 			'Mlym' => 'malajalu',
 			'Mong' => 'mongoļu',
 			'Moon' => 'Mūna raksts',
 			'Mtei' => 'meitei-majeku',
 			'Mymr' => 'birmiešu',
 			'Nkoo' => 'nko',
 			'Ogam' => 'ogamiskais raksts',
 			'Olck' => 'olčiki',
 			'Orya' => 'oriju',
 			'Osma' => 'osmaņu turku',
 			'Phnx' => 'feniķiešu',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'rūnu raksts',
 			'Samr' => 'samariešu',
 			'Sinh' => 'singāļu',
 			'Sund' => 'zundu',
 			'Syrc' => 'sīriešu',
 			'Syrj' => 'rietumsīriešu',
 			'Syrn' => 'austrumsīriešu',
 			'Taml' => 'tamilu',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinagu',
 			'Tglg' => 'tagalu',
 			'Thaa' => 'tāna',
 			'Thai' => 'taju',
 			'Tibt' => 'tibetiešu',
 			'Vaii' => 'vaju',
 			'Xpeo' => 'senperiešu',
 			'Xsux' => 'šumeru-akadiešu ķīļraksts',
 			'Yiii' => 'ji',
 			'Zinh' => 'mantotā',
 			'Zmth' => 'matemātiskais pieraksts',
 			'Zsye' => 'emocijzīmes',
 			'Zsym' => 'simboli',
 			'Zxxx' => 'bez rakstības',
 			'Zyyy' => 'vispārējā',
 			'Zzzz' => 'nezināma rakstība',

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
			'001' => 'pasaule',
 			'002' => 'Āfrika',
 			'003' => 'Ziemeļamerika',
 			'005' => 'Dienvidamerika',
 			'009' => 'Okeānija',
 			'011' => 'Rietumāfrika',
 			'013' => 'Centrālamerika',
 			'014' => 'Austrumāfrika',
 			'015' => 'Ziemeļāfrika',
 			'017' => 'Vidusāfrika',
 			'018' => 'Dienvidāfrika',
 			'019' => 'Amerika',
 			'021' => 'Amerikas ziemeļu daļa',
 			'029' => 'Karību jūras reģions',
 			'030' => 'Austrumāzija',
 			'034' => 'Dienvidāzija',
 			'035' => 'Centrālaustrumāzija',
 			'039' => 'Dienvideiropa',
 			'053' => 'Austrālāzija',
 			'054' => 'Melanēzija',
 			'057' => 'Mikronēzijas reģions',
 			'061' => 'Polinēzija',
 			'142' => 'Āzija',
 			'143' => 'Centrālāzija',
 			'145' => 'Rietumāzija',
 			'150' => 'Eiropa',
 			'151' => 'Austrumeiropa',
 			'154' => 'Ziemeļeiropa',
 			'155' => 'Rietumeiropa',
 			'202' => 'Subsahāras Āfrika',
 			'419' => 'Latīņamerika',
 			'AC' => 'Debesbraukšanas sala',
 			'AD' => 'Andora',
 			'AE' => 'Apvienotie Arābu Emirāti',
 			'AF' => 'Afganistāna',
 			'AG' => 'Antigva un Barbuda',
 			'AI' => 'Angilja',
 			'AL' => 'Albānija',
 			'AM' => 'Armēnija',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentīna',
 			'AS' => 'ASV Samoa',
 			'AT' => 'Austrija',
 			'AU' => 'Austrālija',
 			'AW' => 'Aruba',
 			'AX' => 'Olandes salas',
 			'AZ' => 'Azerbaidžāna',
 			'BA' => 'Bosnija un Hercegovina',
 			'BB' => 'Barbadosa',
 			'BD' => 'Bangladeša',
 			'BE' => 'Beļģija',
 			'BF' => 'Burkinafaso',
 			'BG' => 'Bulgārija',
 			'BH' => 'Bahreina',
 			'BI' => 'Burundija',
 			'BJ' => 'Benina',
 			'BL' => 'Senbartelmī',
 			'BM' => 'Bermudu salas',
 			'BN' => 'Bruneja',
 			'BO' => 'Bolīvija',
 			'BQ' => 'Nīderlandes Karību salas',
 			'BR' => 'Brazīlija',
 			'BS' => 'Bahamu salas',
 			'BT' => 'Butāna',
 			'BV' => 'Buvē sala',
 			'BW' => 'Botsvāna',
 			'BY' => 'Baltkrievija',
 			'BZ' => 'Beliza',
 			'CA' => 'Kanāda',
 			'CC' => 'Kokosu (Kīlinga) salas',
 			'CD' => 'Kongo (Kinšasa)',
 			'CD@alt=variant' => 'Kongo Demokrātiskā Republika',
 			'CF' => 'Centrālāfrikas Republika',
 			'CG' => 'Kongo (Brazavila)',
 			'CG@alt=variant' => 'Kongo (Republika)',
 			'CH' => 'Šveice',
 			'CI' => 'Kotdivuāra',
 			'CI@alt=variant' => 'Ziloņkaula krasts',
 			'CK' => 'Kuka salas',
 			'CL' => 'Čīle',
 			'CM' => 'Kamerūna',
 			'CN' => 'Ķīna',
 			'CO' => 'Kolumbija',
 			'CP' => 'Klipertona sala',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kaboverde',
 			'CW' => 'Kirasao',
 			'CX' => 'Ziemsvētku sala',
 			'CY' => 'Kipra',
 			'CZ' => 'Čehija',
 			'CZ@alt=variant' => 'Čehijas Republika',
 			'DE' => 'Vācija',
 			'DG' => 'Djego Garsijas atols',
 			'DJ' => 'Džibutija',
 			'DK' => 'Dānija',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikāna',
 			'DZ' => 'Alžīrija',
 			'EA' => 'Seūta un Melilja',
 			'EC' => 'Ekvadora',
 			'EE' => 'Igaunija',
 			'EG' => 'Ēģipte',
 			'EH' => 'Rietumsahāra',
 			'ER' => 'Eritreja',
 			'ES' => 'Spānija',
 			'ET' => 'Etiopija',
 			'EU' => 'Eiropas Savienība',
 			'EZ' => 'Eirozona',
 			'FI' => 'Somija',
 			'FJ' => 'Fidži',
 			'FK' => 'Folklenda salas',
 			'FK@alt=variant' => 'Folklenda (Malvinu) salas',
 			'FM' => 'Mikronēzija',
 			'FO' => 'Fēru salas',
 			'FR' => 'Francija',
 			'GA' => 'Gabona',
 			'GB' => 'Apvienotā Karaliste',
 			'GD' => 'Grenāda',
 			'GE' => 'Gruzija',
 			'GF' => 'Francijas Gviāna',
 			'GG' => 'Gērnsija',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltārs',
 			'GL' => 'Grenlande',
 			'GM' => 'Gambija',
 			'GN' => 'Gvineja',
 			'GP' => 'Gvadelupa',
 			'GQ' => 'Ekvatoriālā Gvineja',
 			'GR' => 'Grieķija',
 			'GS' => 'Dienviddžordžija un Dienvidsendviču salas',
 			'GT' => 'Gvatemala',
 			'GU' => 'Guama',
 			'GW' => 'Gvineja-Bisava',
 			'GY' => 'Gajāna',
 			'HK' => 'Ķīnas īpašās pārvaldes apgabals Honkonga',
 			'HK@alt=short' => 'Honkonga',
 			'HM' => 'Hērda sala un Makdonalda salas',
 			'HN' => 'Hondurasa',
 			'HR' => 'Horvātija',
 			'HT' => 'Haiti',
 			'HU' => 'Ungārija',
 			'IC' => 'Kanāriju salas',
 			'ID' => 'Indonēzija',
 			'IE' => 'Īrija',
 			'IL' => 'Izraēla',
 			'IM' => 'Menas sala',
 			'IN' => 'Indija',
 			'IO' => 'Indijas okeāna Britu teritorija',
 			'IO@alt=chagos' => 'Čagosu arhipelāgs',
 			'IQ' => 'Irāka',
 			'IR' => 'Irāna',
 			'IS' => 'Islande',
 			'IT' => 'Itālija',
 			'JE' => 'Džērsija',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordānija',
 			'JP' => 'Japāna',
 			'KE' => 'Kenija',
 			'KG' => 'Kirgizstāna',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoru salas',
 			'KN' => 'Sentkitsa un Nevisa',
 			'KP' => 'Ziemeļkoreja',
 			'KR' => 'Dienvidkoreja',
 			'KW' => 'Kuveita',
 			'KY' => 'Kaimanu salas',
 			'KZ' => 'Kazahstāna',
 			'LA' => 'Laosa',
 			'LB' => 'Libāna',
 			'LC' => 'Sentlūsija',
 			'LI' => 'Lihtenšteina',
 			'LK' => 'Šrilanka',
 			'LR' => 'Libērija',
 			'LS' => 'Lesoto',
 			'LT' => 'Lietuva',
 			'LU' => 'Luksemburga',
 			'LV' => 'Latvija',
 			'LY' => 'Lībija',
 			'MA' => 'Maroka',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Melnkalne',
 			'MF' => 'Senmartēna',
 			'MG' => 'Madagaskara',
 			'MH' => 'Māršala salas',
 			'MK' => 'Ziemeļmaķedonija',
 			'ML' => 'Mali',
 			'MM' => 'Mjanma (Birma)',
 			'MN' => 'Mongolija',
 			'MO' => 'ĶTR īpašais administratīvais reģions Makao',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Ziemeļu Marianas salas',
 			'MQ' => 'Martinika',
 			'MR' => 'Mauritānija',
 			'MS' => 'Montserrata',
 			'MT' => 'Malta',
 			'MU' => 'Maurīcija',
 			'MV' => 'Maldīvija',
 			'MW' => 'Malāvija',
 			'MX' => 'Meksika',
 			'MY' => 'Malaizija',
 			'MZ' => 'Mozambika',
 			'NA' => 'Namībija',
 			'NC' => 'Jaunkaledonija',
 			'NE' => 'Nigēra',
 			'NF' => 'Norfolkas sala',
 			'NG' => 'Nigērija',
 			'NI' => 'Nikaragva',
 			'NL' => 'Nīderlande',
 			'NO' => 'Norvēģija',
 			'NP' => 'Nepāla',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Jaunzēlande',
 			'OM' => 'Omāna',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francijas Polinēzija',
 			'PG' => 'Papua-Jaungvineja',
 			'PH' => 'Filipīnas',
 			'PK' => 'Pakistāna',
 			'PL' => 'Polija',
 			'PM' => 'Senpjēra un Mikelona',
 			'PN' => 'Pitkērnas salas',
 			'PR' => 'Puertoriko',
 			'PS' => 'Palestīnas teritorijas',
 			'PS@alt=short' => 'Palestīna',
 			'PT' => 'Portugāle',
 			'PW' => 'Palau',
 			'PY' => 'Paragvaja',
 			'QA' => 'Katara',
 			'QO' => 'Okeānijas attālās salas',
 			'RE' => 'Reinjona',
 			'RO' => 'Rumānija',
 			'RS' => 'Serbija',
 			'RU' => 'Krievija',
 			'RW' => 'Ruanda',
 			'SA' => 'Saūda Arābija',
 			'SB' => 'Zālamana salas',
 			'SC' => 'Seišelu salas',
 			'SD' => 'Sudāna',
 			'SE' => 'Zviedrija',
 			'SG' => 'Singapūra',
 			'SH' => 'Sv.Helēnas sala',
 			'SI' => 'Slovēnija',
 			'SJ' => 'Svalbāra un Jana Majena sala',
 			'SK' => 'Slovākija',
 			'SL' => 'Sjerraleone',
 			'SM' => 'Sanmarīno',
 			'SN' => 'Senegāla',
 			'SO' => 'Somālija',
 			'SR' => 'Surinama',
 			'SS' => 'Dienvidsudāna',
 			'ST' => 'Santome un Prinsipi',
 			'SV' => 'Salvadora',
 			'SX' => 'Sintmārtena',
 			'SY' => 'Sīrija',
 			'SZ' => 'Svatini',
 			'SZ@alt=variant' => 'Svazilenda',
 			'TA' => 'Tristana da Kuņjas salu teritorijas',
 			'TC' => 'Tērksas un Kaikosas salas',
 			'TD' => 'Čada',
 			'TF' => 'Francijas Dienvidjūru teritorija',
 			'TG' => 'Togo',
 			'TH' => 'Taizeme',
 			'TJ' => 'Tadžikistāna',
 			'TK' => 'Tokelau',
 			'TL' => 'Austrumtimora',
 			'TM' => 'Turkmenistāna',
 			'TN' => 'Tunisija',
 			'TO' => 'Tonga',
 			'TR' => 'Turcija',
 			'TT' => 'Trinidāda un Tobāgo',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taivāna',
 			'TZ' => 'Tanzānija',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'ASV Mazās Aizjūras salas',
 			'UN' => 'Apvienoto Nāciju Organizācija',
 			'UN@alt=short' => 'ANO',
 			'US' => 'Amerikas Savienotās Valstis',
 			'US@alt=short' => 'ASV',
 			'UY' => 'Urugvaja',
 			'UZ' => 'Uzbekistāna',
 			'VA' => 'Vatikāns',
 			'VC' => 'Sentvinsenta un Grenadīnas',
 			'VE' => 'Venecuēla',
 			'VG' => 'Britu Virdžīnas',
 			'VI' => 'ASV Virdžīnas',
 			'VN' => 'Vjetnama',
 			'VU' => 'Vanuatu',
 			'WF' => 'Volisa un Futunas salas',
 			'WS' => 'Samoa',
 			'XA' => 'pseidoakcenti',
 			'XB' => 'pseidodivvirzienu',
 			'XK' => 'Kosova',
 			'YE' => 'Jemena',
 			'YT' => 'Majota',
 			'ZA' => 'Dienvidāfrikas Republika',
 			'ZM' => 'Zambija',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'nezināms reģions',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'tradicionālā vācu ortogrāfija',
 			'1996' => 'vācu ortogrāfija no 1996. gada',
 			'1959ACAD' => 'akadēmiskā',
 			'AREVELA' => 'austrumarmēņu',
 			'AREVMDA' => 'rietumarmēņu',
 			'FONIPA' => 'Starptautiskais fonētiskais alfabēts',
 			'FONUPA' => 'UPA fonētika',
 			'KKCOR' => 'tradicionālā ortogrāfija',
 			'MONOTON' => 'monotons',
 			'NEDIS' => 'Natisona dialekts',
 			'PINYIN' => 'piņjiņa romanizācija',
 			'POLYTON' => 'politons',
 			'POSIX' => 'datoru',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'Skotijas angļu',
 			'TARASK' => 'Taraškeviča ortogrāfija',
 			'UCCOR' => 'vienotā ortogrāfija',
 			'VALENCIA' => 'valensiešu',
 			'WADEGILE' => 'Veida-Džailza romanizācija',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalendārs',
 			'cf' => 'valūtas formāts',
 			'colalternate' => 'kārtošana, ignorējot simbolus',
 			'colbackwards' => 'akcentēto burtu kārtošana apgrieztā secībā',
 			'colcasefirst' => 'kārtošana pēc lielajiem/mazajiem burtiem',
 			'colcaselevel' => 'reģistrjutīga kārtošana',
 			'collation' => 'kārtošanas secība',
 			'colnormalization' => 'normalizēta kārtošana',
 			'colnumeric' => 'kārtošana skaitliskā secībā',
 			'colstrength' => 'kārtošanas pakāpe',
 			'currency' => 'valūta',
 			'hc' => 'Stundu formāts (12 vai 24)',
 			'lb' => 'Rindiņas pārtraukuma stils',
 			'ms' => 'mērvienību sistēma',
 			'numbers' => 'Cipari',
 			'timezone' => 'laika josla',
 			'va' => 'lokalizācijas variants',
 			'x' => 'personīgai lietošanai',

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
 				'buddhist' => q{budistu kalendārs},
 				'chinese' => q{ķīniešu kalendārs},
 				'coptic' => q{Koptu kalendārs},
 				'dangi' => q{dangi kalendārs},
 				'ethiopic' => q{etiopiešu kalendārs},
 				'ethiopic-amete-alem' => q{etiopiešu Amete Alem kalendārs},
 				'gregorian' => q{Gregora kalendārs},
 				'hebrew' => q{ebreju kalendārs},
 				'indian' => q{Indijas nacionālais kalendārs},
 				'islamic' => q{Hidžrī kalendārs},
 				'islamic-civil' => q{Hidžrī kalendārs (pilsoņu)},
 				'islamic-umalqura' => q{Hidžrī kalendārs (Umm al-kura)},
 				'iso8601' => q{ISO 8601 kalendārs},
 				'japanese' => q{japāņu kalendārs},
 				'persian' => q{persiešu kalendārs},
 				'roc' => q{Ķīnas Republikas kalendārs},
 			},
 			'cf' => {
 				'account' => q{uzskaites valūtas formāts},
 				'standard' => q{standarta valūtas formāts},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Kārtot simbolus},
 				'shifted' => q{Kārtot, ignorējot simbolus},
 			},
 			'colbackwards' => {
 				'no' => q{Kārtot diakritiskās zīmes parastā secībā},
 				'yes' => q{Kārtot diakritiskās zīmes apgrieztā secībā},
 			},
 			'colcasefirst' => {
 				'lower' => q{Kārtot pēc pirmā mazā burta},
 				'no' => q{Kārtot burtu reģistra parastā secībā},
 				'upper' => q{Kārtot pēc pirmā lielā burta},
 			},
 			'colcaselevel' => {
 				'no' => q{Kārtot reģistrnejutīgas rakstzīmes},
 				'yes' => q{Kārtot reģistrjutīgās rakstzīmes},
 			},
 			'collation' => {
 				'big5han' => q{tradicionālās ķīniešu valodas kārtošanas secība - Big5},
 				'compat' => q{saderīgā kārtošanas secība},
 				'dictionary' => q{Vārdnīcas kārtošanas secība},
 				'ducet' => q{noklusējuma unikoda kārtošanas secība},
 				'eor' => q{Eiropas rakstību kārtošanas secīa},
 				'gb2312han' => q{vienkāršotās ķīniešu valodas kārtošanas secība - GB2312},
 				'phonebook' => q{tālruņu grāmatas kārtošanas secība},
 				'phonetic' => q{Fonētiskā kārtošanas secība},
 				'pinyin' => q{piņjiņa kārtošanas secība},
 				'reformed' => q{Reformētā kārtošanas secība},
 				'search' => q{vispārīga meklēšana},
 				'searchjl' => q{Meklēt pēc Hangul sākuma līdzskaņa},
 				'standard' => q{standarta kārtošanas secība},
 				'stroke' => q{Stroke kārtošanas secība},
 				'traditional' => q{tradicionālā kārtošanas secība},
 				'unihan' => q{Radikālā kārtošanas secība pēc vilkumu skaita},
 			},
 			'colnormalization' => {
 				'no' => q{Kārtot bez normalizēšanas},
 				'yes' => q{Kārtot unikodu normalizējot},
 			},
 			'colnumeric' => {
 				'no' => q{Kārtot ciparus atsevišķi},
 				'yes' => q{Kārtot ciparus skaitliskā secībā},
 			},
 			'colstrength' => {
 				'identical' => q{Kārtot visus},
 				'primary' => q{Kārtot tikai pamata burtus},
 				'quaternary' => q{Kārtot diakritiskās zīmes/reģistrjutīgās rakstzīmes/rakstzīmes pēc platuma/Kana rakstzīmes},
 				'secondary' => q{Kārtot diakritiskās zīmes},
 				'tertiary' => q{Kārtot diakritiskās zīmes/reģistrjutīgās rakstzīmes/rakstzīmes pēc platuma},
 			},
 			'd0' => {
 				'fwidth' => q{Pilna platuma},
 				'hwidth' => q{Pusplatuma},
 				'npinyin' => q{Ciparu},
 			},
 			'hc' => {
 				'h11' => q{12 stundu sistēma (0–11)},
 				'h12' => q{12 stundu sistēma (1–12)},
 				'h23' => q{24 stundu sistēma (0–23)},
 				'h24' => q{24 stundu sistēma (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Brīvais rindiņas pārtraukuma stils},
 				'normal' => q{Parastais rindiņas pārtraukuma stils},
 				'strict' => q{Stingrais rindiņas pārtraukuma stils},
 			},
 			'm0' => {
 				'bgn' => q{transliterācijas sistēma US BGN},
 				'ungegn' => q{transliterācijas sistēma UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{metriskā sistēma},
 				'uksystem' => q{britu mērvienību sistēma},
 				'ussystem' => q{amerikāņu mērvienību sistēma},
 			},
 			'numbers' => {
 				'arab' => q{Arābu-indiešu cipari},
 				'arabext' => q{Izvērstie arābu-indiešu cipari},
 				'armn' => q{Armēņu cipari},
 				'armnlow' => q{Mazie armēņu cipari},
 				'beng' => q{Bengāļu cipari},
 				'cakm' => q{Čakmas cipari},
 				'deva' => q{Devanāgarī cipari},
 				'ethi' => q{Etiopiešu cipari},
 				'finance' => q{Finanšu cipari},
 				'fullwide' => q{Pilna platuma cipari},
 				'geor' => q{Gruzīnu cipari},
 				'grek' => q{Grieķu cipari},
 				'greklow' => q{Mazie grieķu cipari},
 				'gujr' => q{Gudžaratu cipari},
 				'guru' => q{Gurmuki cipari},
 				'hanidec' => q{Ķīniešu decimāldaļskaitļi},
 				'hans' => q{Vienkāršotie ķīniešu cipari},
 				'hansfin' => q{Vienkāršotie ķīniešu cipari finanšu dokumentiem},
 				'hant' => q{Tradicionālie ķīniešu cipari},
 				'hantfin' => q{Tradicionālie ķīniešu cipari finanšu dokumentiem},
 				'hebr' => q{Ivrita cipari},
 				'java' => q{Javas cipari},
 				'jpan' => q{Japāņu cipari},
 				'jpanfin' => q{Japāņu cipari finanšu dokumentiem},
 				'khmr' => q{Khmeru cipari},
 				'knda' => q{Kannadu cipari},
 				'laoo' => q{Laosiešu cipari},
 				'latn' => q{Arābu cipari},
 				'mlym' => q{Malajalu cipari},
 				'mong' => q{Mongoļu cipari},
 				'mtei' => q{Mītei majek cipari},
 				'mymr' => q{Birmiešu cipari},
 				'native' => q{Vietējie cipari},
 				'olck' => q{Olčiki cipari},
 				'orya' => q{Oriju cipari},
 				'roman' => q{Romiešu cipari},
 				'romanlow' => q{Mazie romiešu cipari},
 				'taml' => q{Tamilu tradicionālie cipari},
 				'tamldec' => q{Tamilu cipari},
 				'telu' => q{Telugu cipari},
 				'thai' => q{Tajiešu cipari},
 				'tibt' => q{Tibetiešu cipari},
 				'traditional' => q{Tradicionālā ciparu sistēma},
 				'vaii' => q{VAI cipari},
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
			'metric' => q{metriskā},
 			'UK' => q{angļu},
 			'US' => q{amerikāņu},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Valoda: {0}',
 			'script' => 'Rakstība: {0}',
 			'region' => 'Reģions: {0}',

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
			auxiliary => qr{[y ō q ŗ w x]},
			index => ['AĀ', 'B', 'C', 'Č', 'D', 'EĒ', 'F', 'G', 'Ģ', 'H', 'IĪY', 'J', 'K', 'Ķ', 'L', 'Ļ', 'M', 'N', 'Ņ', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'UŪ', 'V', 'W', 'X', 'Z', 'Ž'],
			main => qr{[aā b c č d eē f g ģ h iī j k ķ l ļ m n ņ o p r s š t uū v z ž]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’‚ "“”„ ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['AĀ', 'B', 'C', 'Č', 'D', 'EĒ', 'F', 'G', 'Ģ', 'H', 'IĪY', 'J', 'K', 'Ķ', 'L', 'Ļ', 'M', 'N', 'Ņ', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'UŪ', 'V', 'W', 'X', 'Z', 'Ž'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}…{1}',
		};
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
						'1' => q(eksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
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
						'1' => q(jobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(jobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
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
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
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
						'1' => q(jokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(jokto{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
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
					'10p-30' => {
						'1' => q(kvekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kvekto{0}),
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
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
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
						'1' => q(eksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
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
					'10p30' => {
						'1' => q(kveta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kveta{0}),
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
						'1' => q(masculine),
						'one' => q({0} smagumspēks),
						'other' => q({0} smagumspēks),
						'zero' => q({0} smagumspēku),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(masculine),
						'one' => q({0} smagumspēks),
						'other' => q({0} smagumspēks),
						'zero' => q({0} smagumspēku),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'one' => q({0} metrs sekundē kvadrātā),
						'other' => q({0} metri sekundē kvadrātā),
						'zero' => q({0} metru sekundē kvadrātā),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'one' => q({0} metrs sekundē kvadrātā),
						'other' => q({0} metri sekundē kvadrātā),
						'zero' => q({0} metru sekundē kvadrātā),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'one' => q({0} leņķa minūte),
						'other' => q({0} leņķa minūtes),
						'zero' => q({0} leņķa minūšu),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'one' => q({0} leņķa minūte),
						'other' => q({0} leņķa minūtes),
						'zero' => q({0} leņķa minūšu),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'one' => q({0} leņķa sekunde),
						'other' => q({0} leņķa sekundes),
						'zero' => q({0} leņķa sekunžu),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'one' => q({0} leņķa sekunde),
						'other' => q({0} leņķa sekundes),
						'zero' => q({0} leņķa sekunžu),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(masculine),
						'name' => q(grādi),
						'one' => q({0} grāds),
						'other' => q({0} grādi),
						'zero' => q({0} grādu),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(masculine),
						'name' => q(grādi),
						'one' => q({0} grāds),
						'other' => q({0} grādi),
						'zero' => q({0} grādu),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'one' => q({0} radiāns),
						'other' => q({0} radiāni),
						'zero' => q({0} radiānu),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'one' => q({0} radiāns),
						'other' => q({0} radiāni),
						'zero' => q({0} radiānu),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(masculine),
						'name' => q(apgrieziens),
						'one' => q({0} apgrieziens),
						'other' => q({0} apgriezieni),
						'zero' => q({0} apgriezienu),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(masculine),
						'name' => q(apgrieziens),
						'one' => q({0} apgrieziens),
						'other' => q({0} apgriezieni),
						'zero' => q({0} apgriezienu),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} akrs),
						'other' => q({0} akri),
						'zero' => q({0} akru),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} akrs),
						'other' => q({0} akri),
						'zero' => q({0} akru),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'name' => q(hektāri),
						'one' => q({0} hektārs),
						'other' => q({0} hektāri),
						'zero' => q({0} hektāru),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'name' => q(hektāri),
						'one' => q({0} hektārs),
						'other' => q({0} hektāri),
						'zero' => q({0} hektāru),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(kvadrātcentimetri),
						'one' => q({0} kvadrātcentimetrs),
						'other' => q({0} kvadrātcentimetri),
						'per' => q({0} uz kvadrātcentimetru),
						'zero' => q({0} kvadrātcentimetru),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(kvadrātcentimetri),
						'one' => q({0} kvadrātcentimetrs),
						'other' => q({0} kvadrātcentimetri),
						'per' => q({0} uz kvadrātcentimetru),
						'zero' => q({0} kvadrātcentimetru),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadrātpēdas),
						'one' => q({0} kvadrātpēda),
						'other' => q({0} kvadrātpēdas),
						'zero' => q({0} kvadrātpēdu),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadrātpēdas),
						'one' => q({0} kvadrātpēda),
						'other' => q({0} kvadrātpēdas),
						'zero' => q({0} kvadrātpēdu),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrātcollas),
						'one' => q({0} kvadrātcolla),
						'other' => q({0} kvadrātcollas),
						'per' => q({0} uz kvadrātcollu),
						'zero' => q({0} kvadrātcollu),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrātcollas),
						'one' => q({0} kvadrātcolla),
						'other' => q({0} kvadrātcollas),
						'per' => q({0} uz kvadrātcollu),
						'zero' => q({0} kvadrātcollu),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kvadrātkilometri),
						'one' => q({0} kvadrātkilometrs),
						'other' => q({0} kvadrātkilometri),
						'per' => q({0} uz kvadrātkilometru),
						'zero' => q({0} kvadrātkilometru),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kvadrātkilometri),
						'one' => q({0} kvadrātkilometrs),
						'other' => q({0} kvadrātkilometri),
						'per' => q({0} uz kvadrātkilometru),
						'zero' => q({0} kvadrātkilometru),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(kvadrātmetri),
						'one' => q({0} kvadrātmetrs),
						'other' => q({0} kvadrātmetri),
						'per' => q({0} uz kvadrātmetru),
						'zero' => q({0} kvadrātmetru),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(kvadrātmetri),
						'one' => q({0} kvadrātmetrs),
						'other' => q({0} kvadrātmetri),
						'per' => q({0} uz kvadrātmetru),
						'zero' => q({0} kvadrātmetru),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kvadrātjūdzes),
						'one' => q({0} kvadrātjūdze),
						'other' => q({0} kvadrātjūdzes),
						'per' => q({0} uz kvadrātjūdzi),
						'zero' => q({0} kvadrātjūdžu),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kvadrātjūdzes),
						'one' => q({0} kvadrātjūdze),
						'other' => q({0} kvadrātjūdzes),
						'per' => q({0} uz kvadrātjūdzi),
						'zero' => q({0} kvadrātjūdžu),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(kvadrātjardi),
						'one' => q({0} kvadrātjards),
						'other' => q({0} kvadrātjardi),
						'zero' => q({0} kvadrātjardu),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(kvadrātjardi),
						'one' => q({0} kvadrātjards),
						'other' => q({0} kvadrātjardi),
						'zero' => q({0} kvadrātjardu),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'name' => q(vienumi),
						'one' => q({0} vienums),
						'other' => q({0} vienumi),
						'zero' => q({0} vienumu),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'name' => q(vienumi),
						'one' => q({0} vienums),
						'other' => q({0} vienumi),
						'zero' => q({0} vienumu),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'name' => q(karāti),
						'one' => q({0} karāts),
						'other' => q({0} karāti),
						'zero' => q({0} karātu),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'name' => q(karāti),
						'one' => q({0} karāts),
						'other' => q({0} karāti),
						'zero' => q({0} karātu),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligrami uz decilitru),
						'one' => q({0} miligrams uz decilitru),
						'other' => q({0} miligrami uz decilitru),
						'zero' => q({0} miligramu uz decilitru),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligrami uz decilitru),
						'one' => q({0} miligrams uz decilitru),
						'other' => q({0} miligrami uz decilitru),
						'zero' => q({0} miligramu uz decilitru),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(milimoli uz litru),
						'one' => q({0} milimols uz litru),
						'other' => q({0} milimoli uz litru),
						'zero' => q({0} milimolu uz litru),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(milimoli uz litru),
						'one' => q({0} milimols uz litru),
						'other' => q({0} milimoli uz litru),
						'zero' => q({0} milimolu uz litru),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(masculine),
						'name' => q(moli),
						'one' => q({0} mols),
						'other' => q({0} moli),
						'zero' => q({0} molu),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(masculine),
						'name' => q(moli),
						'one' => q({0} mols),
						'other' => q({0} moli),
						'zero' => q({0} molu),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'one' => q({0} procents),
						'other' => q({0} procenti),
						'zero' => q({0} procentu),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'one' => q({0} procents),
						'other' => q({0} procenti),
						'zero' => q({0} procentu),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(feminine),
						'one' => q({0} promile),
						'other' => q({0} promiles),
						'zero' => q({0} promiļu),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(feminine),
						'one' => q({0} promile),
						'other' => q({0} promiles),
						'zero' => q({0} promiļu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'one' => q({0} miljonā daļa),
						'other' => q({0} miljonās daļas),
						'zero' => q({0} miljono daļu),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'one' => q({0} miljonā daļa),
						'other' => q({0} miljonās daļas),
						'zero' => q({0} miljono daļu),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(feminine),
						'one' => q({0} promiriāde),
						'other' => q({0} promiriādes),
						'zero' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(feminine),
						'one' => q({0} promiriāde),
						'other' => q({0} promiriādes),
						'zero' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri uz 100 kilometriem),
						'one' => q({0} litrs uz 100 kilometriem),
						'other' => q({0} litri uz 100 kilometriem),
						'zero' => q({0} litru uz 100 kilometriem),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri uz 100 kilometriem),
						'one' => q({0} litrs uz 100 kilometriem),
						'other' => q({0} litri uz 100 kilometriem),
						'zero' => q({0} litru uz 100 kilometriem),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri uz kilometru),
						'one' => q({0} litrs uz kilometru),
						'other' => q({0} litri uz kilometru),
						'zero' => q({0} litru uz kilometru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri uz kilometru),
						'one' => q({0} litrs uz kilometru),
						'other' => q({0} litri uz kilometru),
						'zero' => q({0} litru uz kilometru),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0} jūdze uz galonu),
						'other' => q({0} jūdzes uz galonu),
						'zero' => q({0} jūdžu uz galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0} jūdze uz galonu),
						'other' => q({0} jūdzes uz galonu),
						'zero' => q({0} jūdžu uz galonu),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(jūdzes uz britu galonu),
						'one' => q({0} jūdze uz britu galonu),
						'other' => q({0} jūdzes uz britu galonu),
						'zero' => q({0} jūdžu uz britu galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(jūdzes uz britu galonu),
						'one' => q({0} jūdze uz britu galonu),
						'other' => q({0} jūdzes uz britu galonu),
						'zero' => q({0} jūdžu uz britu galonu),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'name' => q(biti),
						'one' => q({0} bits),
						'other' => q({0} biti),
						'zero' => q({0} bitu),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'name' => q(biti),
						'one' => q({0} bits),
						'other' => q({0} biti),
						'zero' => q({0} bitu),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
						'name' => q(baiti),
						'one' => q({0} baits),
						'other' => q({0} baiti),
						'zero' => q({0} baitu),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
						'name' => q(baiti),
						'one' => q({0} baits),
						'other' => q({0} baiti),
						'zero' => q({0} baitu),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabiti),
						'one' => q({0} gigabits),
						'other' => q({0} gigabiti),
						'zero' => q({0} gigabitu),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabiti),
						'one' => q({0} gigabits),
						'other' => q({0} gigabiti),
						'zero' => q({0} gigabitu),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigabaiti),
						'one' => q({0} gigabaits),
						'other' => q({0} gigabaiti),
						'zero' => q({0} gigabaitu),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigabaiti),
						'one' => q({0} gigabaits),
						'other' => q({0} gigabaiti),
						'zero' => q({0} gigabaitu),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobiti),
						'one' => q({0} kilobits),
						'other' => q({0} kilobiti),
						'zero' => q({0} kilobitu),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobiti),
						'one' => q({0} kilobits),
						'other' => q({0} kilobiti),
						'zero' => q({0} kilobitu),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilobaiti),
						'one' => q({0} kilobaits),
						'other' => q({0} kilobaiti),
						'zero' => q({0} kilobaitu),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilobaiti),
						'one' => q({0} kilobaits),
						'other' => q({0} kilobaiti),
						'zero' => q({0} kilobaitu),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'name' => q(megabiti),
						'one' => q({0} megabits),
						'other' => q({0} megabiti),
						'zero' => q({0} megabitu),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'name' => q(megabiti),
						'one' => q({0} megabits),
						'other' => q({0} megabiti),
						'zero' => q({0} megabitu),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'name' => q(megabaiti),
						'one' => q({0} megabaits),
						'other' => q({0} megabaits),
						'zero' => q({0} megabaitu),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'name' => q(megabaiti),
						'one' => q({0} megabaits),
						'other' => q({0} megabaits),
						'zero' => q({0} megabaitu),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(masculine),
						'name' => q(petabaiti),
						'one' => q({0} petabaits),
						'other' => q({0} petabaiti),
						'zero' => q({0} petabaitu),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
						'name' => q(petabaiti),
						'one' => q({0} petabaits),
						'other' => q({0} petabaiti),
						'zero' => q({0} petabaitu),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'name' => q(terabiti),
						'one' => q({0} terabits),
						'other' => q({0} terabiti),
						'zero' => q({0} terabitu),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
						'name' => q(terabiti),
						'one' => q({0} terabits),
						'other' => q({0} terabiti),
						'zero' => q({0} terabitu),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
						'name' => q(terabaiti),
						'one' => q({0} terabaits),
						'other' => q({0} terabaiti),
						'zero' => q({0} terabaitu),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
						'name' => q(terabaiti),
						'one' => q({0} terabaits),
						'other' => q({0} terabaiti),
						'zero' => q({0} terabaitu),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(masculine),
						'name' => q(gadsimti),
						'one' => q({0} gadsimts),
						'other' => q({0} gadsimti),
						'zero' => q({0} gadsimtu),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
						'name' => q(gadsimti),
						'one' => q({0} gadsimts),
						'other' => q({0} gadsimti),
						'zero' => q({0} gadsimtu),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(feminine),
						'name' => q(dienas),
						'one' => q({0} diena),
						'other' => q({0} dienas),
						'per' => q({0} dienā),
						'zero' => q({0} dienu),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(feminine),
						'name' => q(dienas),
						'one' => q({0} diena),
						'other' => q({0} dienas),
						'per' => q({0} dienā),
						'zero' => q({0} dienu),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(feminine),
						'name' => q(dekādes),
						'one' => q({0} dekāde),
						'other' => q({0} dekādes),
						'zero' => q({0} dekāžu),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'name' => q(dekādes),
						'one' => q({0} dekāde),
						'other' => q({0} dekādes),
						'zero' => q({0} dekāžu),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'name' => q(stundas),
						'one' => q({0} stunda),
						'other' => q({0} stundas),
						'per' => q({0} stundā),
						'zero' => q({0} stundu),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'name' => q(stundas),
						'one' => q({0} stunda),
						'other' => q({0} stundas),
						'per' => q({0} stundā),
						'zero' => q({0} stundu),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'name' => q(mikrosekundes),
						'one' => q({0} mikrosekunde),
						'other' => q({0} mikrosekundes),
						'zero' => q({0} mikrosekunžu),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'name' => q(mikrosekundes),
						'one' => q({0} mikrosekunde),
						'other' => q({0} mikrosekundes),
						'zero' => q({0} mikrosekunžu),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'name' => q(milisekundes),
						'one' => q({0} milisekunde),
						'other' => q({0} milisekundes),
						'zero' => q({0} milisekunžu),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'name' => q(milisekundes),
						'one' => q({0} milisekunde),
						'other' => q({0} milisekundes),
						'zero' => q({0} milisekunžu),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'name' => q(minūtes),
						'one' => q({0} minūte),
						'other' => q({0} minūtes),
						'per' => q({0} minūtē),
						'zero' => q({0} minūšu),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'name' => q(minūtes),
						'one' => q({0} minūte),
						'other' => q({0} minūtes),
						'per' => q({0} minūtē),
						'zero' => q({0} minūšu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'one' => q({0} mēnesis),
						'other' => q({0} mēneši),
						'per' => q({0} mēnesī),
						'zero' => q({0} mēnešu),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'one' => q({0} mēnesis),
						'other' => q({0} mēneši),
						'per' => q({0} mēnesī),
						'zero' => q({0} mēnešu),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'name' => q(nanosekundes),
						'one' => q({0} nanosekunde),
						'other' => q({0} nanosekundes),
						'zero' => q({0} nanosekunžu),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'name' => q(nanosekundes),
						'one' => q({0} nanosekunde),
						'other' => q({0} nanosekundes),
						'zero' => q({0} nanosekunžu),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'name' => q(ceturkšņi),
						'one' => q({0} ceturksnis),
						'other' => q({0} ceturkšņi),
						'zero' => q({0} cet.),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'name' => q(ceturkšņi),
						'one' => q({0} ceturksnis),
						'other' => q({0} ceturkšņi),
						'zero' => q({0} cet.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'name' => q(sekundes),
						'one' => q({0} sekunde),
						'other' => q({0} sekundes),
						'per' => q({0} sekundē),
						'zero' => q({0} sekunžu),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'name' => q(sekundes),
						'one' => q({0} sekunde),
						'other' => q({0} sekundes),
						'per' => q({0} sekundē),
						'zero' => q({0} sekunžu),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'name' => q(nedēļas),
						'one' => q({0} nedēļa),
						'other' => q({0} nedēļas),
						'per' => q({0} nedēļā),
						'zero' => q({0} nedēļu),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'name' => q(nedēļas),
						'one' => q({0} nedēļa),
						'other' => q({0} nedēļas),
						'per' => q({0} nedēļā),
						'zero' => q({0} nedēļu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'name' => q(gadi),
						'one' => q({0} gads),
						'other' => q({0} gadi),
						'per' => q({0} gadā),
						'zero' => q({0} gadu),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'name' => q(gadi),
						'one' => q({0} gads),
						'other' => q({0} gadi),
						'per' => q({0} gadā),
						'zero' => q({0} gadu),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'name' => q(ampēri),
						'one' => q({0} ampērs),
						'other' => q({0} ampēri),
						'zero' => q({0} ampēru),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'name' => q(ampēri),
						'one' => q({0} ampērs),
						'other' => q({0} ampēri),
						'zero' => q({0} ampēru),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'name' => q(miliampēri),
						'one' => q({0} miliampērs),
						'other' => q({0} miliampēri),
						'zero' => q({0} miliampēru),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'name' => q(miliampēri),
						'one' => q({0} miliampērs),
						'other' => q({0} miliampēri),
						'zero' => q({0} miliampēru),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'one' => q({0} oms),
						'other' => q({0} omi),
						'zero' => q({0} omu),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'one' => q({0} oms),
						'other' => q({0} omi),
						'zero' => q({0} omu),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'one' => q({0} volts),
						'other' => q({0} volti),
						'zero' => q({0} voltu),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'one' => q({0} volts),
						'other' => q({0} volti),
						'zero' => q({0} voltu),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(britu termiskās mērvienības),
						'one' => q({0} britu termiskā mērvienība),
						'other' => q({0} britu termiskās mērvienības),
						'zero' => q({0} britu termisko mērvienību),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(britu termiskās mērvienības),
						'one' => q({0} britu termiskā mērvienība),
						'other' => q({0} britu termiskās mērvienības),
						'zero' => q({0} britu termisko mērvienību),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(kalorijas),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijas),
						'zero' => q({0} kaloriju),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(kalorijas),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijas),
						'zero' => q({0} kaloriju),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolti),
						'one' => q({0} elektronvolts),
						'other' => q({0} elektronvolti),
						'zero' => q({0} elektronvoltu),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolti),
						'one' => q({0} elektronvolts),
						'other' => q({0} elektronvolti),
						'zero' => q({0} elektronvoltu),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kalorijas),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijas),
						'zero' => q({0} kaloriju),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kalorijas),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijas),
						'zero' => q({0} kaloriju),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'one' => q({0} džouls),
						'other' => q({0} džouli),
						'zero' => q({0} džoulu),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'one' => q({0} džouls),
						'other' => q({0} džouli),
						'zero' => q({0} džoulu),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalorijas),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijas),
						'zero' => q({0} kilokaloriju),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalorijas),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijas),
						'zero' => q({0} kilokaloriju),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'name' => q(kilodžouli),
						'one' => q({0} kilodžouls),
						'other' => q({0} kilodžouli),
						'zero' => q({0} kilodžoulu),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'name' => q(kilodžouli),
						'one' => q({0} kilodžouls),
						'other' => q({0} kilodžouli),
						'zero' => q({0} kilodžoulu),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(feminine),
						'name' => q(kilovatstundas),
						'one' => q({0} kilovatstunda),
						'other' => q({0} kilovatstundas),
						'zero' => q({0} kilovatstundu),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(feminine),
						'name' => q(kilovatstundas),
						'one' => q({0} kilovatstunda),
						'other' => q({0} kilovatstundas),
						'zero' => q({0} kilovatstundu),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ASV termiskās vienības),
						'one' => q({0} ASV termiskā vienība),
						'other' => q({0} ASV termiskās vienības),
						'zero' => q({0} ASV termisko vienību),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ASV termiskās vienības),
						'one' => q({0} ASV termiskā vienība),
						'other' => q({0} ASV termiskās vienības),
						'zero' => q({0} ASV termisko vienību),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'name' => q(kilovatstunda uz 100 kilometriem),
						'one' => q({0} kilovatstunda uz 100 kilometriem),
						'other' => q({0} kilovatstundas uz 100 kilometriem),
						'zero' => q({0} kilovatstundu uz 100 kilometriem),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'name' => q(kilovatstunda uz 100 kilometriem),
						'one' => q({0} kilovatstunda uz 100 kilometriem),
						'other' => q({0} kilovatstundas uz 100 kilometriem),
						'zero' => q({0} kilovatstundu uz 100 kilometriem),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'name' => q(ņūtoni),
						'one' => q({0} ņūtons),
						'other' => q({0} ņūtoni),
						'zero' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'name' => q(ņūtoni),
						'one' => q({0} ņūtons),
						'other' => q({0} ņūtoni),
						'zero' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(jaudas māciņas),
						'one' => q({0} jaudas mārciņa),
						'other' => q({0} jaudas mārciņas),
						'zero' => q({0} jaudas mārciņu),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(jaudas māciņas),
						'one' => q({0} jaudas mārciņa),
						'other' => q({0} jaudas mārciņas),
						'zero' => q({0} jaudas mārciņu),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigaherci),
						'one' => q({0} gigahercs),
						'other' => q({0} gigaherci),
						'zero' => q({0} gigahercu),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigaherci),
						'one' => q({0} gigahercs),
						'other' => q({0} gigaherci),
						'zero' => q({0} gigahercu),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'name' => q(herci),
						'one' => q({0} hercs),
						'other' => q({0} herci),
						'zero' => q({0} hercu),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'name' => q(herci),
						'one' => q({0} hercs),
						'other' => q({0} herci),
						'zero' => q({0} hercu),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'name' => q(kiloherci),
						'one' => q({0} kilohercs),
						'other' => q({0} kiloherci),
						'zero' => q({0} kilohercu),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'name' => q(kiloherci),
						'one' => q({0} kilohercs),
						'other' => q({0} kiloherci),
						'zero' => q({0} kilohercu),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'name' => q(megaherci),
						'one' => q({0} megahercs),
						'other' => q({0} megaherci),
						'zero' => q({0} megahercu),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'name' => q(megaherci),
						'one' => q({0} megahercs),
						'other' => q({0} megaherci),
						'zero' => q({0} megahercu),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(punkti centimetrā),
						'one' => q({0} punkts centimetrā),
						'other' => q({0} punkti centimetrā),
						'zero' => q({0} dpc),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punkti centimetrā),
						'one' => q({0} punkts centimetrā),
						'other' => q({0} punkti centimetrā),
						'zero' => q({0} dpc),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(punkti collā),
						'one' => q({0} punkts collā),
						'other' => q({0} punkti collā),
						'zero' => q({0} ppi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punkti collā),
						'one' => q({0} punkts collā),
						'other' => q({0} punkti collā),
						'zero' => q({0} ppi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapikselis),
						'other' => q({0} megapikseļi),
						'zero' => q({0} MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapikselis),
						'other' => q({0} megapikseļi),
						'zero' => q({0} MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'one' => q({0} pikselis),
						'other' => q({0} pikseļi),
						'zero' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'one' => q({0} pikselis),
						'other' => q({0} pikseļi),
						'zero' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pikseļi centimetrā),
						'one' => q({0} pikselis centimetrā),
						'other' => q({0} pikseļi centimetrā),
						'zero' => q({0} ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pikseļi centimetrā),
						'one' => q({0} pikselis centimetrā),
						'other' => q({0} pikseļi centimetrā),
						'zero' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pikseļi collā),
						'one' => q({0} pikselis collā),
						'other' => q({0} pikseļi collā),
						'zero' => q({0} ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pikseļi collā),
						'one' => q({0} pikselis collā),
						'other' => q({0} pikseļi collā),
						'zero' => q({0} ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiskās vienības),
						'one' => q({0} astronomiskā vienība),
						'other' => q({0} astronomiskās vienības),
						'zero' => q({0} astronomisko vienību),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiskās vienības),
						'one' => q({0} astronomiskā vienība),
						'other' => q({0} astronomiskās vienības),
						'zero' => q({0} astronomisko vienību),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri),
						'one' => q({0} centimetrs),
						'other' => q({0} centimetri),
						'per' => q({0} centimetrā),
						'zero' => q({0} centimetru),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri),
						'one' => q({0} centimetrs),
						'other' => q({0} centimetri),
						'per' => q({0} centimetrā),
						'zero' => q({0} centimetru),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(decimetri),
						'one' => q({0} decimetrs),
						'other' => q({0} decimetri),
						'zero' => q({0} decimetru),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(decimetri),
						'one' => q({0} decimetrs),
						'other' => q({0} decimetri),
						'zero' => q({0} decimetru),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Zemes rādiuss),
						'one' => q({0} Zemes rādiuss),
						'other' => q({0} Zemes rādiuss),
						'zero' => q({0} R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Zemes rādiuss),
						'one' => q({0} Zemes rādiuss),
						'other' => q({0} Zemes rādiuss),
						'zero' => q({0} R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fatoms),
						'other' => q({0} fatomi),
						'zero' => q({0} fatomu),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fatoms),
						'other' => q({0} fatomi),
						'zero' => q({0} fatomu),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} pēda),
						'other' => q({0} pēdas),
						'per' => q({0} pēdā),
						'zero' => q({0} pēdu),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} pēda),
						'other' => q({0} pēdas),
						'per' => q({0} pēdā),
						'zero' => q({0} pēdu),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} colla),
						'other' => q({0} collas),
						'per' => q({0} collā),
						'zero' => q({0} collu),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} colla),
						'other' => q({0} collas),
						'per' => q({0} collā),
						'zero' => q({0} collu),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilometri),
						'one' => q({0} kilometrs),
						'other' => q({0} kilometri),
						'per' => q({0} kilometrā),
						'zero' => q({0} kilometru),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(kilometri),
						'one' => q({0} kilometrs),
						'other' => q({0} kilometri),
						'per' => q({0} kilometrā),
						'zero' => q({0} kilometru),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(gaismas gadi),
						'one' => q({0} gaismas gads),
						'other' => q({0} gaismas gadi),
						'zero' => q({0} gaismas gadu),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(gaismas gadi),
						'one' => q({0} gaismas gads),
						'other' => q({0} gaismas gadi),
						'zero' => q({0} gaismas gadu),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'name' => q(metri),
						'one' => q({0} metrs),
						'other' => q({0} metri),
						'per' => q({0} metrā),
						'zero' => q({0} metru),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'name' => q(metri),
						'one' => q({0} metrs),
						'other' => q({0} metri),
						'per' => q({0} metrā),
						'zero' => q({0} metru),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(mikrometri),
						'one' => q({0} mikrometrs),
						'other' => q({0} mikrometri),
						'zero' => q({0} mikrometru),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(mikrometri),
						'one' => q({0} mikrometrs),
						'other' => q({0} mikrometri),
						'zero' => q({0} mikrometru),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} jūdze),
						'other' => q({0} jūdzes),
						'zero' => q({0} jūdžu),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} jūdze),
						'other' => q({0} jūdzes),
						'zero' => q({0} jūdžu),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'one' => q({0} skandināvu jūdze),
						'other' => q({0} skandināvu jūdzes),
						'zero' => q({0} skandināvu jūdžu),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'one' => q({0} skandināvu jūdze),
						'other' => q({0} skandināvu jūdzes),
						'zero' => q({0} skandināvu jūdžu),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(milimetri),
						'one' => q({0} milimetrs),
						'other' => q({0} milimetri),
						'zero' => q({0} milimetru),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(milimetri),
						'one' => q({0} milimetrs),
						'other' => q({0} milimetri),
						'zero' => q({0} milimetru),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(nanometri),
						'one' => q({0} nanometrs),
						'other' => q({0} nanometri),
						'zero' => q({0} nanometru),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanometri),
						'one' => q({0} nanometrs),
						'other' => q({0} nanometri),
						'zero' => q({0} nanometru),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(jūras jūdzes),
						'one' => q({0} jūras jūdze),
						'other' => q({0} jūras jūdzes),
						'zero' => q({0} jūras jūdžu),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(jūras jūdzes),
						'one' => q({0} jūras jūdze),
						'other' => q({0} jūras jūdzes),
						'zero' => q({0} jūras jūdžu),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parseks),
						'other' => q({0} parseki),
						'zero' => q({0} parseku),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parseks),
						'other' => q({0} parseki),
						'zero' => q({0} parseku),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(pikometri),
						'one' => q({0} pikometrs),
						'other' => q({0} pikometri),
						'zero' => q({0} pikometru),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(pikometri),
						'one' => q({0} pikometrs),
						'other' => q({0} pikometri),
						'zero' => q({0} pikometru),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} punkts),
						'other' => q({0} punkti),
						'zero' => q({0} punktu),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} punkts),
						'other' => q({0} punkti),
						'zero' => q({0} punktu),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} Saules rādiuss),
						'other' => q({0} Saules rādiusi),
						'zero' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} Saules rādiuss),
						'other' => q({0} Saules rādiusi),
						'zero' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} jards),
						'other' => q({0} jardi),
						'zero' => q({0} jardu),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} jards),
						'other' => q({0} jardi),
						'zero' => q({0} jardu),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'one' => q({0} kandela),
						'other' => q({0} kandelas),
						'zero' => q({0} kandelu),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'one' => q({0} kandela),
						'other' => q({0} kandelas),
						'zero' => q({0} kandelu),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'one' => q({0} lūmens),
						'other' => q({0} lūmeni),
						'zero' => q({0} lūmenu),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'one' => q({0} lūmens),
						'other' => q({0} lūmeni),
						'zero' => q({0} lūmenu),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'one' => q({0} lukss),
						'other' => q({0} luksi),
						'zero' => q({0} luksu),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'one' => q({0} lukss),
						'other' => q({0} luksi),
						'zero' => q({0} luksu),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} Saules starjauda),
						'other' => q({0} Saules starjaudas),
						'zero' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} Saules starjauda),
						'other' => q({0} Saules starjaudas),
						'zero' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'one' => q({0} karāts),
						'other' => q({0} karāti),
						'zero' => q({0} karātu),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'one' => q({0} karāts),
						'other' => q({0} karāti),
						'zero' => q({0} karātu),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} daltons),
						'other' => q({0} daltoni),
						'zero' => q({0} Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} daltons),
						'other' => q({0} daltoni),
						'zero' => q({0} Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} Zemes masa),
						'other' => q({0} Zemes masas),
						'zero' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} Zemes masa),
						'other' => q({0} Zemes masas),
						'zero' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grans),
						'one' => q({0} grans),
						'other' => q({0} grana),
						'zero' => q({0} granu),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grans),
						'one' => q({0} grans),
						'other' => q({0} grana),
						'zero' => q({0} granu),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'one' => q({0} grams),
						'other' => q({0} grami),
						'per' => q({0} uz gramu),
						'zero' => q({0} gramu),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'one' => q({0} grams),
						'other' => q({0} grami),
						'per' => q({0} uz gramu),
						'zero' => q({0} gramu),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'name' => q(kilogrami),
						'one' => q({0} kilograms),
						'other' => q({0} kilogrami),
						'per' => q({0} uz kilogramu),
						'zero' => q({0} kilogramu),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'name' => q(kilogrami),
						'one' => q({0} kilograms),
						'other' => q({0} kilogrami),
						'per' => q({0} uz kilogramu),
						'zero' => q({0} kilogramu),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'name' => q(mikrogrami),
						'one' => q({0} mikrograms),
						'other' => q({0} mikrogrami),
						'zero' => q({0} mikrogramu),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'name' => q(mikrogrami),
						'one' => q({0} mikrograms),
						'other' => q({0} mikrogrami),
						'zero' => q({0} mikrogramu),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'name' => q(miligrami),
						'one' => q({0} miligrams),
						'other' => q({0} miligrami),
						'zero' => q({0} miligramu),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'name' => q(miligrami),
						'one' => q({0} miligrams),
						'other' => q({0} miligrami),
						'zero' => q({0} miligramu),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} unce),
						'other' => q({0} unces),
						'per' => q({0} uz unci),
						'zero' => q({0} unču),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} unce),
						'other' => q({0} unces),
						'per' => q({0} uz unci),
						'zero' => q({0} unču),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} Trojas unce),
						'other' => q({0} Trojas unces),
						'zero' => q({0} Trojas unču),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} Trojas unce),
						'other' => q({0} Trojas unces),
						'zero' => q({0} Trojas unču),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} mārciņa),
						'other' => q({0} mārciņas),
						'per' => q({0} uz mārciņu),
						'zero' => q({0} mārciņu),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} mārciņa),
						'other' => q({0} mārciņas),
						'per' => q({0} uz mārciņu),
						'zero' => q({0} mārciņu),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} Saules masa),
						'other' => q({0} Saules masas),
						'zero' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} Saules masa),
						'other' => q({0} Saules masas),
						'zero' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stouns),
						'other' => q({0} stouni),
						'zero' => q({0} stounu),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stouns),
						'other' => q({0} stouni),
						'zero' => q({0} stounu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tonna),
						'other' => q({0} tonnas),
						'zero' => q({0} tonnu),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tonna),
						'other' => q({0} tonnas),
						'zero' => q({0} tonnu),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'name' => q(metriskās tonnas),
						'one' => q({0} metriskā tonna),
						'other' => q({0} metriskās tonnas),
						'zero' => q({0} metrisko tonnu),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'name' => q(metriskās tonnas),
						'one' => q({0} metriskā tonna),
						'other' => q({0} metriskās tonnas),
						'zero' => q({0} metrisko tonnu),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigavati),
						'one' => q({0} gigavats),
						'other' => q({0} gigavati),
						'zero' => q({0} gigavatu),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigavati),
						'one' => q({0} gigavats),
						'other' => q({0} gigavati),
						'zero' => q({0} gigavatu),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(zirgspēki),
						'one' => q({0} zirgspēks),
						'other' => q({0} zirgspēki),
						'zero' => q({0} zirgspēku),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(zirgspēki),
						'one' => q({0} zirgspēks),
						'other' => q({0} zirgspēki),
						'zero' => q({0} zirgspēku),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilovati),
						'one' => q({0} kilovats),
						'other' => q({0} kilovati),
						'zero' => q({0} kilovatu),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilovati),
						'one' => q({0} kilovats),
						'other' => q({0} kilovati),
						'zero' => q({0} kilovatu),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'name' => q(megavati),
						'one' => q({0} megavats),
						'other' => q({0} megavati),
						'zero' => q({0} megavatu),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'name' => q(megavati),
						'one' => q({0} megavats),
						'other' => q({0} megavati),
						'zero' => q({0} megavatu),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
						'name' => q(milivati),
						'one' => q({0} milivats),
						'other' => q({0} milivati),
						'zero' => q({0} milivatu),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'name' => q(milivati),
						'one' => q({0} milivats),
						'other' => q({0} milivati),
						'zero' => q({0} milivatu),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'one' => q({0} vats),
						'other' => q({0} vati),
						'zero' => q({0} vatu),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'one' => q({0} vats),
						'other' => q({0} vati),
						'zero' => q({0} vatu),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(kvadrāt{0}),
						'other' => q(kvadrāt{0}),
						'zero' => q(kvadrāt{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(kvadrāt{0}),
						'other' => q(kvadrāt{0}),
						'zero' => q(kvadrāt{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(kubik{0}),
						'other' => q(kubik{0}),
						'zero' => q(kubik{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(kubik{0}),
						'other' => q(kubik{0}),
						'zero' => q(kubik{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosfēras),
						'one' => q({0} atmosfēra),
						'other' => q({0} atmosfēras),
						'zero' => q({0} atmosfēras),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosfēras),
						'one' => q({0} atmosfēra),
						'other' => q({0} atmosfēras),
						'zero' => q({0} atmosfēras),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
						'name' => q(bāri),
						'one' => q({0} bārs),
						'other' => q({0} bāri),
						'zero' => q({0} bāru),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
						'name' => q(bāri),
						'one' => q({0} bārs),
						'other' => q({0} bāri),
						'zero' => q({0} bāru),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(masculine),
						'name' => q(hektopaskāli),
						'one' => q({0} hektopaskāls),
						'other' => q({0} hektopaskāli),
						'zero' => q({0} hektopaskālu),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'name' => q(hektopaskāli),
						'one' => q({0} hektopaskāls),
						'other' => q({0} hektopaskāli),
						'zero' => q({0} hektopaskālu),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(dzīvsudraba stabiņa collas),
						'one' => q({0} dzīvsudraba stabiņa colla),
						'other' => q({0} dzīvsudraba stabiņa collas),
						'zero' => q({0} dzīvsudraba stabiņa collu),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(dzīvsudraba stabiņa collas),
						'one' => q({0} dzīvsudraba stabiņa colla),
						'other' => q({0} dzīvsudraba stabiņa collas),
						'zero' => q({0} dzīvsudraba stabiņa collu),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopaskāli),
						'one' => q({0} kilopaskāls),
						'other' => q({0} kilopaskāli),
						'zero' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopaskāli),
						'one' => q({0} kilopaskāls),
						'other' => q({0} kilopaskāli),
						'zero' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'name' => q(megapaskāli),
						'one' => q({0} megapaskāls),
						'other' => q({0} megapaskāli),
						'zero' => q({0} megapaskālu),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'name' => q(megapaskāli),
						'one' => q({0} megapaskāls),
						'other' => q({0} megapaskāli),
						'zero' => q({0} megapaskālu),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'name' => q(milibāri),
						'one' => q({0} milibārs),
						'other' => q({0} milibāri),
						'zero' => q({0} milibāru),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'name' => q(milibāri),
						'one' => q({0} milibārs),
						'other' => q({0} milibāri),
						'zero' => q({0} milibāru),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(dzīvsudraba stabiņa milimetri),
						'one' => q({0} dzīvsudraba stabiņa milimetrs),
						'other' => q({0} dzīvsudraba stabiņa milimetri),
						'zero' => q({0} dzīvsudraba stabiņa milimetru),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(dzīvsudraba stabiņa milimetri),
						'one' => q({0} dzīvsudraba stabiņa milimetrs),
						'other' => q({0} dzīvsudraba stabiņa milimetri),
						'zero' => q({0} dzīvsudraba stabiņa milimetru),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'name' => q(paskāli),
						'one' => q({0} paskāls),
						'other' => q({0} paskāli),
						'zero' => q({0} paskālu),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'name' => q(paskāli),
						'one' => q({0} paskāls),
						'other' => q({0} paskāli),
						'zero' => q({0} paskālu),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(mārciņas uz kvadrātcollu),
						'one' => q({0} mārciņa uz kvadrātcollu),
						'other' => q({0} mārciņas uz kvadrātcollu),
						'zero' => q({0} mārciņu uz kvadrātcollu),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(mārciņas uz kvadrātcollu),
						'one' => q({0} mārciņa uz kvadrātcollu),
						'other' => q({0} mārciņas uz kvadrātcollu),
						'zero' => q({0} mārciņu uz kvadrātcollu),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Boforta),
						'one' => q({0} balle pēc Boforta skalas),
						'other' => q({0} balles pēc Boforta skalas),
						'zero' => q({0} baļļu pēc Boforta skalas),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Boforta),
						'one' => q({0} balle pēc Boforta skalas),
						'other' => q({0} balles pēc Boforta skalas),
						'zero' => q({0} baļļu pēc Boforta skalas),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilometri stundā),
						'one' => q({0} kilometrs stundā),
						'other' => q({0} kilometri stundā),
						'zero' => q({0} kilometru stundā),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilometri stundā),
						'one' => q({0} kilometrs stundā),
						'other' => q({0} kilometri stundā),
						'zero' => q({0} kilometru stundā),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0} mezgls),
						'other' => q({0} mezgli),
						'zero' => q({0} mezglu),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0} mezgls),
						'other' => q({0} mezgli),
						'zero' => q({0} mezglu),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metri sekundē),
						'one' => q({0} metrs sekundē),
						'other' => q({0} metri sekundē),
						'zero' => q({0} metru sekundē),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metri sekundē),
						'one' => q({0} metrs sekundē),
						'other' => q({0} metri sekundē),
						'zero' => q({0} metru sekundē),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(jūdzes stundā),
						'one' => q({0} jūdze stundā),
						'other' => q({0} jūdzes stundā),
						'zero' => q({0} jūdžu stundā),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(jūdzes stundā),
						'one' => q({0} jūdze stundā),
						'other' => q({0} jūdzes stundā),
						'zero' => q({0} jūdžu stundā),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(masculine),
						'name' => q(Celsija grādi),
						'one' => q({0} Celsija grāds),
						'other' => q({0} Celsija grādi),
						'zero' => q({0} Celsija grādu),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(masculine),
						'name' => q(Celsija grādi),
						'one' => q({0} Celsija grāds),
						'other' => q({0} Celsija grādi),
						'zero' => q({0} Celsija grādu),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Fārenheita grādi),
						'one' => q({0} Fārenheita grāds),
						'other' => q({0} Fārenheita grādi),
						'zero' => q({0} Fārenheita grādu),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Fārenheita grādi),
						'one' => q({0} Fārenheita grāds),
						'other' => q({0} Fārenheita grādi),
						'zero' => q({0} Fārenheita grādu),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
						'one' => q({0} grāds),
						'other' => q({0} grādi),
						'zero' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
						'one' => q({0} grāds),
						'other' => q({0} grādi),
						'zero' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvini),
						'one' => q({0} kelvins),
						'other' => q({0} kelvini),
						'zero' => q({0} kelvinu),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvini),
						'one' => q({0} kelvins),
						'other' => q({0} kelvini),
						'zero' => q({0} kelvinu),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(ņūtonmetri),
						'one' => q({0} ņūtonmetrs),
						'other' => q({0} ņūtonmetri),
						'zero' => q({0} ņūtonmetru),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(ņūtonmetri),
						'one' => q({0} ņūtonmetrs),
						'other' => q({0} ņūtonmetri),
						'zero' => q({0} ņūtonmetru),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0} mārciņpēda),
						'other' => q({0} mārciņpēdas),
						'zero' => q({0} mārciņpēdu),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0} mārciņpēda),
						'other' => q({0} mārciņpēdas),
						'zero' => q({0} mārciņpēdu),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akrpēda),
						'one' => q({0} akrpēda),
						'other' => q({0} akrpēdas),
						'zero' => q({0} akrpēdu),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akrpēda),
						'one' => q({0} akrpēda),
						'other' => q({0} akrpēdas),
						'zero' => q({0} akrpēdu),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bareli),
						'one' => q({0} barels),
						'other' => q({0} bareli),
						'zero' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bareli),
						'one' => q({0} barels),
						'other' => q({0} bareli),
						'zero' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bušelis),
						'one' => q({0} bušelis),
						'other' => q({0} bušeļi),
						'zero' => q({0} bušeļu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bušelis),
						'one' => q({0} bušelis),
						'other' => q({0} bušeļi),
						'zero' => q({0} bušeļu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitri),
						'one' => q({0} centilitrs),
						'other' => q({0} centilitri),
						'zero' => q({0} centilitru),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitri),
						'one' => q({0} centilitrs),
						'other' => q({0} centilitri),
						'zero' => q({0} centilitru),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(kubikcentimetri),
						'one' => q({0} kubikcentimetrs),
						'other' => q({0} kubikcentimetri),
						'per' => q({0} uz kubikcentimetru),
						'zero' => q({0} kubikcentimetru),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(kubikcentimetri),
						'one' => q({0} kubikcentimetrs),
						'other' => q({0} kubikcentimetri),
						'per' => q({0} uz kubikcentimetru),
						'zero' => q({0} kubikcentimetru),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kubikpēdas),
						'one' => q({0} kubikpēda),
						'other' => q({0} kubikpēdas),
						'zero' => q({0} kubikpēdu),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kubikpēdas),
						'one' => q({0} kubikpēda),
						'other' => q({0} kubikpēdas),
						'zero' => q({0} kubikpēdu),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubikcollas),
						'one' => q({0} kubikcolla),
						'other' => q({0} kubikcollas),
						'zero' => q({0} kubikcollu),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubikcollas),
						'one' => q({0} kubikcolla),
						'other' => q({0} kubikcollas),
						'zero' => q({0} kubikcollu),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kubikkilometri),
						'one' => q({0} kubikkilometrs),
						'other' => q({0} kubikkilometri),
						'zero' => q({0} kubikkilometru),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kubikkilometri),
						'one' => q({0} kubikkilometrs),
						'other' => q({0} kubikkilometri),
						'zero' => q({0} kubikkilometru),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(kubikmetri),
						'one' => q({0} kubikmetrs),
						'other' => q({0} kubikmetri),
						'per' => q({0} uz kubikmetru),
						'zero' => q({0} kubikmetru),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(kubikmetri),
						'one' => q({0} kubikmetrs),
						'other' => q({0} kubikmetri),
						'per' => q({0} uz kubikmetru),
						'zero' => q({0} kubikmetru),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kubikjūdzes),
						'one' => q({0} kubikjūdze),
						'other' => q({0} kubikjūdzes),
						'zero' => q({0} kubikjūdžu),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kubikjūdzes),
						'one' => q({0} kubikjūdze),
						'other' => q({0} kubikjūdzes),
						'zero' => q({0} kubikjūdžu),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubikjardi),
						'one' => q({0} kubikjards),
						'other' => q({0} kubikjardi),
						'zero' => q({0} kubikjardu),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubikjardi),
						'one' => q({0} kubikjards),
						'other' => q({0} kubikjardi),
						'zero' => q({0} kubikjardu),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} glāze),
						'other' => q({0} glāzes),
						'zero' => q({0} glāžu),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} glāze),
						'other' => q({0} glāzes),
						'zero' => q({0} glāžu),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(metriskā glāze),
						'one' => q({0} metriskā glāze),
						'other' => q({0} metriskās glāzes),
						'zero' => q({0} metrisko glāžu),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(metriskā glāze),
						'one' => q({0} metriskā glāze),
						'other' => q({0} metriskās glāzes),
						'zero' => q({0} metrisko glāžu),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitri),
						'one' => q({0} decilitrs),
						'other' => q({0} decilitri),
						'zero' => q({0} decilitru),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitri),
						'one' => q({0} decilitrs),
						'other' => q({0} decilitri),
						'zero' => q({0} decilitru),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(deserta karote),
						'one' => q({0} deserta karote),
						'other' => q({0} deserta karotes),
						'zero' => q({0} deserta karošu),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(deserta karote),
						'one' => q({0} deserta karote),
						'other' => q({0} deserta karotes),
						'zero' => q({0} deserta karošu),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(britu deserta karote),
						'one' => q({0} britu deserta karote),
						'other' => q({0} britu deserta karotes),
						'zero' => q({0} britu deserta karošu),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(britu deserta karote),
						'one' => q({0} britu deserta karote),
						'other' => q({0} britu deserta karotes),
						'zero' => q({0} britu deserta karošu),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0} šķidruma drahma),
						'other' => q({0} šķidruma drahmas),
						'zero' => q({0} šķidruma drahmu),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0} šķidruma drahma),
						'other' => q({0} šķidruma drahmas),
						'zero' => q({0} šķidruma drahmu),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(piliens),
						'one' => q({0} piliens),
						'other' => q({0} pilieni),
						'zero' => q({0} pilienu),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(piliens),
						'one' => q({0} piliens),
						'other' => q({0} pilieni),
						'zero' => q({0} pilienu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(šķidruma unces),
						'one' => q({0} šķidruma unce),
						'other' => q({0} šķidruma unces),
						'zero' => q({0} šķidruma unču),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(šķidruma unces),
						'one' => q({0} šķidruma unce),
						'other' => q({0} šķidruma unces),
						'zero' => q({0} šķidruma unču),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(britu šķidruma unces),
						'one' => q({0} britu šķidruma unce),
						'other' => q({0} britu šķidruma unces),
						'zero' => q({0} britu šķidruma unču),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(britu šķidruma unces),
						'one' => q({0} britu šķidruma unce),
						'other' => q({0} britu šķidruma unces),
						'zero' => q({0} britu šķidruma unču),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galoni),
						'one' => q({0} galons),
						'other' => q({0} galoni),
						'per' => q({0} uz galonu),
						'zero' => q({0} galonu),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galoni),
						'one' => q({0} galons),
						'other' => q({0} galoni),
						'per' => q({0} uz galonu),
						'zero' => q({0} galonu),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(britu galoni),
						'per' => q({0} uz britu galonu),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(britu galoni),
						'per' => q({0} uz britu galonu),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(hektolitri),
						'one' => q({0} hektolitrs),
						'other' => q({0} hektolitri),
						'zero' => q({0} hektolitru),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(hektolitri),
						'one' => q({0} hektolitrs),
						'other' => q({0} hektolitri),
						'zero' => q({0} hektolitru),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0} mērglāzīte),
						'other' => q({0} mērglāzītes),
						'zero' => q({0} mērglāzīšu),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0} mērglāzīte),
						'other' => q({0} mērglāzītes),
						'zero' => q({0} mērglāzīšu),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'name' => q(litri),
						'one' => q({0} litrs),
						'other' => q({0} litri),
						'per' => q({0} uz litru),
						'zero' => q({0} litru),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'name' => q(litri),
						'one' => q({0} litrs),
						'other' => q({0} litri),
						'per' => q({0} uz litru),
						'zero' => q({0} litru),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitri),
						'one' => q({0} megalitrs),
						'other' => q({0} megalitri),
						'zero' => q({0} megalitru),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitri),
						'one' => q({0} megalitrs),
						'other' => q({0} megalitri),
						'zero' => q({0} megalitru),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(mililitri),
						'one' => q({0} mililitrs),
						'other' => q({0} mililitri),
						'zero' => q({0} mililitru),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(mililitri),
						'one' => q({0} mililitrs),
						'other' => q({0} mililitri),
						'zero' => q({0} mililitru),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(šķipsniņa),
						'one' => q({0} šķipsniņa),
						'other' => q({0} šķipsniņas),
						'zero' => q({0} šķipsniņu),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(šķipsniņa),
						'one' => q({0} šķipsniņa),
						'other' => q({0} šķipsniņas),
						'zero' => q({0} šķipsniņu),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} pinte),
						'other' => q({0} pintes),
						'zero' => q({0} pinšu),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} pinte),
						'other' => q({0} pintes),
						'zero' => q({0} pinšu),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'name' => q(metriskās pintes),
						'one' => q({0} metriskā pinte),
						'other' => q({0} metriskās pintes),
						'zero' => q({0} metrisko pinšu),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'name' => q(metriskās pintes),
						'one' => q({0} metriskā pinte),
						'other' => q({0} metriskās pintes),
						'zero' => q({0} metrisko pinšu),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kvartas),
						'one' => q({0} kvarta),
						'other' => q({0} kvartas),
						'zero' => q({0} kvartu),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kvartas),
						'one' => q({0} kvarta),
						'other' => q({0} kvartas),
						'zero' => q({0} kvartu),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(britu kvarta),
						'one' => q({0} britu kvarta),
						'other' => q({0} britu kvartas),
						'zero' => q({0} britu kvartu),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(britu kvarta),
						'one' => q({0} britu kvarta),
						'other' => q({0} britu kvartas),
						'zero' => q({0} britu kvartu),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ēdamkarotes),
						'one' => q({0} ēdamkarote),
						'other' => q({0} ēdamkarotes),
						'zero' => q({0} ēdamkarošu),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ēdamkarotes),
						'one' => q({0} ēdamkarote),
						'other' => q({0} ēdamkarotes),
						'zero' => q({0} ēdamkarošu),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tējkarotes),
						'one' => q({0} tējkarote),
						'other' => q({0} tējkarotes),
						'zero' => q({0} tējkarošu),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tējkarotes),
						'one' => q({0} tējkarote),
						'other' => q({0} tējkarotes),
						'zero' => q({0} tējkarošu),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Brīvās krišanas paātrinājums:),
						'one' => q({0}G),
						'other' => q({0}G),
						'zero' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Brīvās krišanas paātrinājums:),
						'one' => q({0}G),
						'other' => q({0}G),
						'zero' => q({0}G),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akrs),
						'one' => q({0}ac),
						'other' => q({0}ac),
						'zero' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akrs),
						'one' => q({0}ac),
						'other' => q({0}ac),
						'zero' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'zero' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'zero' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'zero' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'zero' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'zero' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'zero' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'zero' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'zero' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'zero' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'zero' => q({0}mi²),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'zero' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'zero' => q({0} h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mēn.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
						'zero' => q({0} m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mēn.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
						'zero' => q({0} m.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0} c.),
						'other' => q({0} c.),
						'zero' => q({0} cet.),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0} c.),
						'other' => q({0} c.),
						'zero' => q({0} cet.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
						'zero' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
						'zero' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(n.),
						'one' => q({0} n.),
						'other' => q({0} n.),
						'per' => q({0}/n.),
						'zero' => q({0} n.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(n.),
						'one' => q({0} n.),
						'other' => q({0} n.),
						'per' => q({0}/n.),
						'zero' => q({0} n.),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0} cm),
						'zero' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0} cm),
						'zero' => q({0} cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
						'per' => q({0}/pēda),
						'zero' => q({0}ft),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
						'per' => q({0}/pēda),
						'zero' => q({0}ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furl.),
						'other' => q({0} furl.),
						'zero' => q({0} furl.),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furl.),
						'other' => q({0} furl.),
						'zero' => q({0} furl.),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(colla),
						'one' => q({0}in),
						'other' => q({0}in),
						'per' => q({0}/colla),
						'zero' => q({0}in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(colla),
						'one' => q({0}in),
						'other' => q({0}in),
						'per' => q({0}/colla),
						'zero' => q({0}in),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}g.g.),
						'other' => q({0}g.g.),
						'zero' => q({0}g.g.),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}g.g.),
						'other' => q({0}g.g.),
						'zero' => q({0}g.g.),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
						'zero' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
						'zero' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sk.j.),
						'one' => q({0} sk.j.),
						'other' => q({0} sk.j.),
						'zero' => q({0} sk.j.),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sk.j.),
						'one' => q({0} sk.j.),
						'other' => q({0} sk.j.),
						'zero' => q({0} sk.j.),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0} mm),
						'zero' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0} mm),
						'zero' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(j.j.),
						'one' => q({0} j.j.),
						'other' => q({0} j.j.),
						'zero' => q({0} j.j.),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(j.j.),
						'one' => q({0} j.j.),
						'other' => q({0} j.j.),
						'zero' => q({0} j.j.),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pars.),
						'one' => q({0} pars.),
						'other' => q({0} pars.),
						'zero' => q({0} pars.),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pars.),
						'one' => q({0} pars.),
						'other' => q({0} pars.),
						'zero' => q({0} pars.),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'zero' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'zero' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pk.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pk.),
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
					'length-yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
						'zero' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
						'zero' => q({0}yd),
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
					'mass-carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
						'zero' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
						'zero' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grams),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grams),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
						'zero' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
						'zero' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(mārc.),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'per' => q({0}/mārc.),
						'zero' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(mārc.),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'per' => q({0}/mārc.),
						'zero' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
						'zero' => q({0} st.),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
						'zero' => q({0} st.),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'zero' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'zero' => q({0}kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'zero' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'zero' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'zero' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'zero' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
						'zero' => q({0}inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
						'zero' => q({0}inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'zero' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'zero' => q({0}mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'zero' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'zero' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0} mezgls),
						'other' => q({0} mezgli),
						'zero' => q({0} mezgli),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0} mezgls),
						'other' => q({0} mezgli),
						'zero' => q({0} mezgli),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'zero' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'zero' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(jūdzes/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
						'zero' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(jūdzes/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
						'zero' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(mārc. pēda),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(mārc. pēda),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'zero' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'zero' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
						'zero' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
						'zero' => q({0}mi³),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(debespuse),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(debespuse),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(j{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(j{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(smagumspēks),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(smagumspēks),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metri sekundē kvadrātā),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metri sekundē kvadrātā),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(leņķa minūtes),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(leņķa minūtes),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(leņķa sekundes),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(leņķa sekundes),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiāni),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiāni),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(apgr.),
						'one' => q({0} apgr.),
						'other' => q({0} apgr.),
						'zero' => q({0} apgr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(apgr.),
						'one' => q({0} apgr.),
						'other' => q({0} apgr.),
						'zero' => q({0} apgr.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akri),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akri),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunami),
						'one' => q({0} dunams),
						'other' => q({0} dunami),
						'zero' => q({0} dunamu),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunami),
						'one' => q({0} dunams),
						'other' => q({0} dunami),
						'zero' => q({0} dunamu),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(vienums),
						'one' => q({0} vienums),
						'other' => q({0} vienumi),
						'zero' => q({0} vienuma),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(vienums),
						'one' => q({0} vienums),
						'other' => q({0} vienumi),
						'zero' => q({0} vienuma),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'zero' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'zero' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'zero' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'zero' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mols),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mols),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(procents),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(procents),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promile),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promile),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(miljonās daļas),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(miljonās daļas),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(promiriāde),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(promiriāde),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
						'zero' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
						'zero' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'zero' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'zero' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(jūdzes uz galonu),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'zero' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(jūdzes uz galonu),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'zero' => q({0} mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}A),
						'north' => q({0}Z),
						'south' => q({0}D),
						'west' => q({0}R),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}A),
						'north' => q({0}Z),
						'south' => q({0}D),
						'west' => q({0}R),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
						'zero' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
						'zero' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
						'zero' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
						'zero' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(gs.),
						'one' => q({0} gs.),
						'other' => q({0} gs.),
						'zero' => q({0} gs.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(gs.),
						'one' => q({0} gs.),
						'other' => q({0} gs.),
						'zero' => q({0} gs.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
						'zero' => q({0} d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
						'zero' => q({0} d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
						'zero' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
						'zero' => q({0} dek),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
						'zero' => q({0} st.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(st.),
						'one' => q({0} st.),
						'other' => q({0} st.),
						'zero' => q({0} st.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mēneši),
						'one' => q({0} mēn.),
						'other' => q({0} mēn.),
						'per' => q({0}/mēn.),
						'zero' => q({0} mēn.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mēneši),
						'one' => q({0} mēn.),
						'other' => q({0} mēn.),
						'per' => q({0}/mēn.),
						'zero' => q({0} mēn.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(cet.),
						'one' => q({0} cet.),
						'other' => q({0} cet.),
						'per' => q({0}/c.),
						'zero' => q({0} cet.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(cet.),
						'one' => q({0} cet.),
						'other' => q({0} cet.),
						'per' => q({0}/c.),
						'zero' => q({0} cet.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
						'zero' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
						'zero' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ned.),
						'one' => q({0} ned.),
						'other' => q({0} ned.),
						'per' => q({0}/ned.),
						'zero' => q({0} ned.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ned.),
						'one' => q({0} ned.),
						'other' => q({0} ned.),
						'per' => q({0}/ned.),
						'zero' => q({0} ned.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(g.),
						'one' => q({0} g.),
						'other' => q({0} g.),
						'per' => q({0}/g.),
						'zero' => q({0} g.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(g.),
						'one' => q({0} g.),
						'other' => q({0} g.),
						'per' => q({0}/g.),
						'zero' => q({0} g.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(omi),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(omi),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volti),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volti),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolts),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolts),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'zero' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
						'zero' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(džouli),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(džouli),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ņūtons),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ņūtons),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(jaudas mārciņa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(jaudas mārciņa),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punkts),
						'one' => q({0} p.),
						'other' => q({0} p.),
						'zero' => q({0} px),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punkts),
						'one' => q({0} p.),
						'other' => q({0} p.),
						'zero' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpc),
						'one' => q({0} dpc),
						'other' => q({0} dpc),
						'zero' => q({0} dpc),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpc),
						'one' => q({0} dpc),
						'other' => q({0} dpc),
						'zero' => q({0} dpc),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikseļi),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikseļi),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikseļi),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikseļi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(a.v.),
						'one' => q({0} a.v.),
						'other' => q({0} a.v.),
						'zero' => q({0} a.v.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(a.v.),
						'one' => q({0} a.v.),
						'other' => q({0} a.v.),
						'zero' => q({0} a.v.),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatomi),
						'one' => q({0} fatoms),
						'other' => q({0} fatomi),
						'zero' => q({0} fatomu),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatomi),
						'one' => q({0} fatoms),
						'other' => q({0} fatomi),
						'zero' => q({0} fatomu),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pēdas),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pēdas),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongi),
						'one' => q({0} furlongs),
						'other' => q({0} furlongi),
						'zero' => q({0} furlongu),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongi),
						'one' => q({0} furlongs),
						'other' => q({0} furlongi),
						'zero' => q({0} furlongu),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(collas),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(collas),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(g.g.),
						'one' => q({0} g.g.),
						'other' => q({0} g.g.),
						'zero' => q({0} g.g.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(g.g.),
						'one' => q({0} g.g.),
						'other' => q({0} g.g.),
						'zero' => q({0} g.g.),
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
						'name' => q(jūdzes),
						'one' => q({0} jūdze),
						'other' => q({0} jūdzes),
						'zero' => q({0} jūdzes),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(jūdzes),
						'one' => q({0} jūdze),
						'other' => q({0} jūdzes),
						'zero' => q({0} jūdzes),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(skandināvu jūdze),
						'one' => q({0} skandināvu jūdze),
						'other' => q({0} skandināvu jūdzes),
						'zero' => q({0} skandināvu jūdzes),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(skandināvu jūdze),
						'one' => q({0} skandināvu jūdze),
						'other' => q({0} skandināvu jūdzes),
						'zero' => q({0} skandināvu jūdzes),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parseki),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parseki),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punkti),
						'one' => q({0} pk.),
						'other' => q({0} pk.),
						'zero' => q({0} pk.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punkti),
						'one' => q({0} pk.),
						'other' => q({0} pk.),
						'zero' => q({0} pk.),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Saules rādiusi),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Saules rādiusi),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardi),
						'one' => q({0} jards),
						'other' => q({0} jardi),
						'zero' => q({0} jardi),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardi),
						'one' => q({0} jards),
						'other' => q({0} jardi),
						'zero' => q({0} jardi),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lūmens),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lūmens),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lukss),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lukss),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(Saules starjauda),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Saules starjauda),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karāti),
						'one' => q({0} ct),
						'other' => q({0} ct),
						'zero' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karāti),
						'one' => q({0} ct),
						'other' => q({0} ct),
						'zero' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltoni),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltoni),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Zemes masas),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Zemes masas),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr.),
						'one' => q({0} gr.),
						'other' => q({0} gr.),
						'zero' => q({0} gr.),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr.),
						'one' => q({0} gr.),
						'other' => q({0} gr.),
						'zero' => q({0} gr.),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grami),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grami),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unces),
						'one' => q({0} unce),
						'other' => q({0} unces),
						'per' => q({0}/unce),
						'zero' => q({0} unču),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unces),
						'one' => q({0} unce),
						'other' => q({0} unces),
						'per' => q({0}/unce),
						'zero' => q({0} unču),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(Trojas unces),
						'one' => q({0} Trojas unce),
						'other' => q({0} Trojas unces),
						'zero' => q({0} Trojas unces),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(Trojas unces),
						'one' => q({0} Trojas unce),
						'other' => q({0} Trojas unces),
						'zero' => q({0} Trojas unces),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(mārciņas),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(mārciņas),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(Saules masas),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(Saules masas),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stouni),
						'one' => q({0} stouns),
						'other' => q({0} stouni),
						'zero' => q({0} stounu),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stouni),
						'one' => q({0} stouns),
						'other' => q({0} stouni),
						'zero' => q({0} stounu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonnas),
						'one' => q({0} tonna),
						'other' => q({0} tonnas),
						'zero' => q({0} tonnas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonnas),
						'one' => q({0} tonna),
						'other' => q({0} tonnas),
						'zero' => q({0} tonnas),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ZS),
						'one' => q({0} ZS),
						'other' => q({0} ZS),
						'zero' => q({0} ZS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ZS),
						'one' => q({0} ZS),
						'other' => q({0} ZS),
						'zero' => q({0} ZS),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vati),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vati),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'zero' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'zero' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/st.),
						'one' => q({0} km/st.),
						'other' => q({0} km/st.),
						'zero' => q({0} km/st.),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/st.),
						'one' => q({0} km/st.),
						'other' => q({0} km/st.),
						'zero' => q({0} km/st.),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(mezgls),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(mezgls),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
						'zero' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
						'zero' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
						'zero' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
						'zero' => q({0} °F),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(mārciņpēda),
						'one' => q({0} mārc. pēda),
						'other' => q({0} mārc. pēdas),
						'zero' => q({0} mārc. pēdu),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(mārciņpēda),
						'one' => q({0} mārc. pēda),
						'other' => q({0} mārc. pēdas),
						'zero' => q({0} mārc. pēdu),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barels),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'zero' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'zero' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(glāzes),
						'one' => q({0} gl.),
						'other' => q({0} gl.),
						'zero' => q({0} gl.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(glāzes),
						'one' => q({0} gl.),
						'other' => q({0} gl.),
						'zero' => q({0} gl.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metr. gl.),
						'one' => q({0} metr. gl.),
						'other' => q({0} metr. gl.),
						'zero' => q({0} metr. gl.),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metr. gl.),
						'one' => q({0} metr. gl.),
						'other' => q({0} metr. gl.),
						'zero' => q({0} metr. gl.),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'zero' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'zero' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(des. kar.),
						'one' => q({0} des. kar.),
						'other' => q({0} des. kar.),
						'zero' => q({0} des. kar.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(des. kar.),
						'one' => q({0} des. kar.),
						'other' => q({0} des. kar.),
						'zero' => q({0} des. kar.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(britu des. kar.),
						'one' => q({0} britu des. kar.),
						'other' => q({0} britu des. kar.),
						'zero' => q({0} britu des. kar.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(britu des. kar.),
						'one' => q({0} britu des. kar.),
						'other' => q({0} britu des. kar.),
						'zero' => q({0} britu des. kar.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(šķidruma drahma),
						'one' => q({0} šķ. drahma),
						'other' => q({0} šķ. drahmas),
						'zero' => q({0} šķi. drahmu),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(šķidruma drahma),
						'one' => q({0} šķ. drahma),
						'other' => q({0} šķ. drahmas),
						'zero' => q({0} šķi. drahmu),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(pil.),
						'one' => q({0} pil.),
						'other' => q({0} pil.),
						'zero' => q({0} pil.),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(pil.),
						'one' => q({0} pil.),
						'other' => q({0} pil.),
						'zero' => q({0} pil.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'zero' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'zero' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(britu šķidr. unces),
						'one' => q({0} britu šķidr. unce),
						'other' => q({0} britu šķidr. unces),
						'zero' => q({0} britu šķidr. unču),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(britu šķidr. unces),
						'one' => q({0} britu šķidr. unce),
						'other' => q({0} britu šķidr. unces),
						'zero' => q({0} britu šķidr. unču),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal.),
						'zero' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal.),
						'zero' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(britu galons),
						'one' => q({0} britu galons),
						'other' => q({0} britu galoni),
						'per' => q({0}/britu galonu),
						'zero' => q({0} britu galonu),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(britu galons),
						'one' => q({0} britu galons),
						'other' => q({0} britu galoni),
						'per' => q({0}/britu galonu),
						'zero' => q({0} britu galonu),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'zero' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'zero' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(mērglāzīte),
						'one' => q({0} mērgl.),
						'other' => q({0} mērgl.),
						'zero' => q({0} mērgl.),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(mērglāzīte),
						'one' => q({0} mērgl.),
						'other' => q({0} mērgl.),
						'zero' => q({0} mērgl.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'zero' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'zero' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(šķipsn.),
						'one' => q({0} šķipsn.),
						'other' => q({0} šķipsn.),
						'zero' => q({0} šķipsn.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(šķipsn.),
						'one' => q({0} šķipsn.),
						'other' => q({0} šķipsn.),
						'zero' => q({0} šķipsn.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintes),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintes),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(IQT),
						'one' => q({0} IQT),
						'other' => q({0} IQT),
						'zero' => q({0} IQT),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(IQT),
						'one' => q({0} IQT),
						'other' => q({0} IQT),
						'zero' => q({0} IQT),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ĒK),
						'one' => q({0} ĒK),
						'other' => q({0} ĒK),
						'zero' => q({0} ĒK),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ĒK),
						'one' => q({0} ĒK),
						'other' => q({0} ĒK),
						'zero' => q({0} ĒK),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(TK),
						'one' => q({0} TK),
						'other' => q({0} TK),
						'zero' => q({0} TK),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(TK),
						'one' => q({0} TK),
						'other' => q({0} TK),
						'zero' => q({0} TK),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jā|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nē|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} un {1}),
				2 => q({0} un {1}),
		} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 2,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'nan' => q(NS),
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
					'one' => '0 tūkstotis',
					'other' => '0 tūkstoši',
					'zero' => '0 tūkstošu',
				},
				'10000' => {
					'one' => '00 tūkstotis',
					'other' => '00 tūkstoši',
					'zero' => '00 tūkstoši',
				},
				'100000' => {
					'one' => '000 tūkstotis',
					'other' => '000 tūkstoši',
					'zero' => '000 tūkstoši',
				},
				'1000000' => {
					'one' => '0 miljons',
					'other' => '0 miljoni',
					'zero' => '0 miljonu',
				},
				'10000000' => {
					'one' => '00 miljons',
					'other' => '00 miljoni',
					'zero' => '00 miljoni',
				},
				'100000000' => {
					'one' => '000 miljons',
					'other' => '000 miljoni',
					'zero' => '000 miljoni',
				},
				'1000000000' => {
					'one' => '0 miljards',
					'other' => '0 miljardi',
					'zero' => '0 miljardu',
				},
				'10000000000' => {
					'one' => '00 miljards',
					'other' => '00 miljardi',
					'zero' => '00 miljardi',
				},
				'100000000000' => {
					'one' => '000 miljards',
					'other' => '000 miljardi',
					'zero' => '000 miljardi',
				},
				'1000000000000' => {
					'one' => '0 triljons',
					'other' => '0 triljoni',
					'zero' => '0 triljonu',
				},
				'10000000000000' => {
					'one' => '00 triljons',
					'other' => '00 triljoni',
					'zero' => '00 triljoni',
				},
				'100000000000000' => {
					'one' => '000 triljons',
					'other' => '000 triljoni',
					'zero' => '000 triljoni',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tūkst'.'',
					'other' => '0 tūkst'.'',
				},
				'10000' => {
					'one' => '00 tūkst'.'',
					'other' => '00 tūkst'.'',
				},
				'100000' => {
					'one' => '000 tūkst'.'',
					'other' => '000 tūkst'.'',
				},
				'1000000' => {
					'one' => '0 milj'.'',
					'other' => '0 milj'.'',
				},
				'10000000' => {
					'one' => '00 milj'.'',
					'other' => '00 milj'.'',
				},
				'100000000' => {
					'one' => '000 milj'.'',
					'other' => '000 milj'.'',
				},
				'1000000000' => {
					'one' => '0 mljrd'.'',
					'other' => '0 mljrd'.'',
				},
				'10000000000' => {
					'one' => '00 mljrd'.'',
					'other' => '00 mljrd'.'',
				},
				'100000000000' => {
					'one' => '000 mljrd'.'',
					'other' => '000 mljrd'.'',
				},
				'1000000000000' => {
					'one' => '0 trilj'.'',
					'other' => '0 trilj'.'',
				},
				'10000000000000' => {
					'one' => '00 trilj'.'',
					'other' => '00 trilj'.'',
				},
				'100000000000000' => {
					'one' => '000 trilj'.'',
					'other' => '000 trilj'.'',
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
				'currency' => q(Apvienoto Arābu Emirātu dirhēms),
				'one' => q(AAE dirhēms),
				'other' => q(AAE dirhēmi),
				'zero' => q(AAE dirhēmi),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afganistānas afgāns),
				'one' => q(Afganistānas afgāns),
				'other' => q(Afganistānas afgāni),
				'zero' => q(Afganistānas afgāni),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albānijas leks),
				'one' => q(Albānijas leks),
				'other' => q(Albānijas leki),
				'zero' => q(Albānijas leki),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armēnijas drams),
				'one' => q(Armēnijas drams),
				'other' => q(Armēnijas drami),
				'zero' => q(Armēnijas drami),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Nīderlandes Antiļu guldenis),
				'one' => q(Nīderlandes Antiļu guldenis),
				'other' => q(Nīderlandes Antiļu guldeņi),
				'zero' => q(Nīderlandes Antiļu guldeņi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolas kvanza),
				'one' => q(Angolas kvanza),
				'other' => q(Angolas kvanzas),
				'zero' => q(Angolas kvanzas),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentīnas peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Austrijas šiliņš),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Austrālijas dolārs),
				'one' => q(Austrālijas dolārs),
				'other' => q(Austrālijas dolāri),
				'zero' => q(Austrālijas dolāri),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Arubas guldenis),
				'one' => q(Arubas guldenis),
				'other' => q(Arubas guldeņi),
				'zero' => q(Arubas guldeņi),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbaidžānas manats \(1993–2006\)),
				'one' => q(Azerbaidžānas manats \(1993–2006\)),
				'other' => q(Azerbaidžānas manati \(1993–2006\)),
				'zero' => q(Azerbaidžānas manati \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaidžānas manats),
				'one' => q(Azerbaidžānas manats),
				'other' => q(Azerbaidžānas manati),
				'zero' => q(Azerbaidžānas manati),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnijas un Hercogovinas konvertējamā marka),
				'one' => q(Bosnijas un Hercogovinas konvertējamā marka),
				'other' => q(Bosnijas un Hercogovinas konvertējamās markas),
				'zero' => q(Bosnijas un Hercogovinas konvertējamās markas),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadosas dolārs),
				'one' => q(Barbadosas dolārs),
				'other' => q(Barbadosas dolāri),
				'zero' => q(Barbadosas dolāri),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladešas taka),
				'one' => q(Bangladešas taka),
				'other' => q(Bangladešas takas),
				'zero' => q(Bangladešas takas),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Beļģijas franks),
				'one' => q(Beļģijas franks),
				'other' => q(Beļģijas franki),
				'zero' => q(Beļģijas franki),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgārijas leva),
				'one' => q(Bulgārijas leva),
				'other' => q(Bulgārijas levas),
				'zero' => q(Bulgārijas levas),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreinas dinārs),
				'one' => q(Bahreinas dinārs),
				'other' => q(Bahreinas dināri),
				'zero' => q(Bahreinas dināri),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi franks),
				'one' => q(Burundi franks),
				'other' => q(Burundi franki),
				'zero' => q(Burundi franki),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudu dolārs),
				'one' => q(Bermudu dolārs),
				'other' => q(Bermudu dolāri),
				'zero' => q(Bermudu dolāri),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunejas dolārs),
				'one' => q(Brunejas dolārs),
				'other' => q(Brunejas dolāri),
				'zero' => q(Brunejas dolāri),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolīvijas boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazīlijas reāls),
				'one' => q(Brazīlijas reāls),
				'other' => q(Brazīlijas reāli),
				'zero' => q(Brazīlijas reāli),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamu dolārs),
				'one' => q(Bahamu dolārs),
				'other' => q(Bahamu dolāri),
				'zero' => q(Bahamu dolāri),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butānas ngultrums),
				'one' => q(Butānas ngultrums),
				'other' => q(Butānas ngultrumi),
				'zero' => q(Butānas ngultrumi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botsvanas pula),
				'one' => q(Botsvanas pula),
				'other' => q(Botsvanas pulas),
				'zero' => q(Botsvanas pulas),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Baltkrievijas rubelis),
				'one' => q(Baltkrievijas rubelis),
				'other' => q(Baltkrievijas rubeļi),
				'zero' => q(Baltkrievijas rubeļi),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Baltkrievijas rubelis \(2000–2016\)),
				'one' => q(Baltkrievijas rubelis \(2000–2016\)),
				'other' => q(Baltkrievijas rubeļi \(2000–2016\)),
				'zero' => q(Baltkrievijas rubeļi \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belizas dolārs),
				'one' => q(Belizas dolārs),
				'other' => q(Belizas dolāri),
				'zero' => q(Belizas dolāri),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanādas dolārs),
				'one' => q(Kanādas dolārs),
				'other' => q(Kanādas dolāri),
				'zero' => q(Kanādas dolāri),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(KDR franks),
				'one' => q(KDR franks),
				'other' => q(KDR franki),
				'zero' => q(KDR franki),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Šveices franks),
				'one' => q(Šveices franks),
				'other' => q(Šveices franki),
				'zero' => q(Šveices franki),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Čīles peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Ķīnas juaņa \(ofšors\)),
				'one' => q(Ķīnas juaņa \(ofšors\)),
				'other' => q(Ķīnas juaņas \(ofšors\)),
				'zero' => q(Ķīnas juaņa \(ofšors\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Ķīnas juaņs),
				'one' => q(Ķīnas juaņs),
				'other' => q(Ķīnas juaņi),
				'zero' => q(Ķīnas juaņi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbijas peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Kolumbijas reāls),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kostarikas kolons),
				'one' => q(Kostarikas kolons),
				'other' => q(Kostarikas koloni),
				'zero' => q(Kostarikas koloni),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kubas konvertējamais peso),
				'one' => q(Kubas konvertējamais peso),
				'other' => q(Kubas konvertējamie peso),
				'zero' => q(Kubas konvertējamie peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubas peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kaboverdes eskudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kipras mārciņa),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Čehijas krona),
				'one' => q(Čehijas krona),
				'other' => q(Čehijas kronas),
				'zero' => q(Čehijas kronas),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Vācijas marka),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Džibutijas franks),
				'one' => q(Džibutijas franks),
				'other' => q(Džibutijas franki),
				'zero' => q(Džibutijas franki),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Dānijas krona),
				'one' => q(Dānijas krona),
				'other' => q(Dānijas kronas),
				'zero' => q(Dānijas kronas),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikānas peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Alžīrijas dinārs),
				'one' => q(Alžīrijas dinārs),
				'other' => q(Alžīrijas dināri),
				'zero' => q(Alžīrijas dināri),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Igaunijas krona),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ēģiptes mārciņa),
				'one' => q(Ēģiptes mārciņa),
				'other' => q(Ēģiptes mārciņas),
				'zero' => q(Ēģiptes mārciņas),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrejas nakfa),
				'one' => q(Eritrejas nakfa),
				'other' => q(Eritrejas nakfas),
				'zero' => q(Eritrejas nakfas),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spānijas peseta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etiopijas birs),
				'one' => q(Etiopijas birs),
				'other' => q(Etiopijas biri),
				'zero' => q(Etiopijas biri),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(eiro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Somijas marka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidži dolārs),
				'one' => q(Fidži dolārs),
				'other' => q(Fidži dolāri),
				'zero' => q(Fidži dolāri),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Folklenda Salu mārciņa),
				'one' => q(Folklenda Salu mārciņa),
				'other' => q(Folklenda Salu mārciņas),
				'zero' => q(Folklenda Salu mārciņas),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Francijas franks),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Lielbritānijas mārciņa),
				'one' => q(Lielbritānijas mārciņa),
				'other' => q(Lielbritānijas mārciņas),
				'zero' => q(Lielbritānijas mārciņas),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Gruzijas lari),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ganas sedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltāra mārciņa),
				'one' => q(Gibraltāra mārciņa),
				'other' => q(Gibraltāra mārciņas),
				'zero' => q(Gibraltāra mārciņas),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambijas dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Gvinejas franks),
				'one' => q(Gvinejas franks),
				'other' => q(Gvinejas franki),
				'zero' => q(Gvinejas franki),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Grieķijas drahma),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Gvatemalas ketsals),
				'one' => q(Gvatemalas ketsals),
				'other' => q(Gvatemalas ketsali),
				'zero' => q(Gvatemalas ketsali),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Gajānas dolārs),
				'one' => q(Gajānas dolārs),
				'other' => q(Gajānas dolāri),
				'zero' => q(Gajānas dolāri),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Honkongas dolārs),
				'one' => q(Honkongas dolārs),
				'other' => q(Honkongas dolāri),
				'zero' => q(Honkongas dolāri),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hondurasas lempīra),
				'one' => q(Hondurasas lempīra),
				'other' => q(Hondurasas lempīras),
				'zero' => q(Hondurasas lempīras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Horvātijas kuna),
				'one' => q(Horvātijas kuna),
				'other' => q(Horvātijas kunas),
				'zero' => q(Horvātijas kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti gurds),
				'one' => q(Haiti gurds),
				'other' => q(Haiti gurdi),
				'zero' => q(Haiti gurdi),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ungārijas forints),
				'one' => q(Ungārijas forints),
				'other' => q(Ungārijas forinti),
				'zero' => q(Ungārijas forinti),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonēzijas rūpija),
				'one' => q(Indonēzijas rūpija),
				'other' => q(Indonēzijas rūpijas),
				'zero' => q(Indonēzijas rūpijas),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Īrijas mārciņa),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Izraēlas šekelis),
				'one' => q(Izraēlas šekelis),
				'other' => q(Izraēlas šekeļi),
				'zero' => q(Izraēlas šekeļi),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indijas rūpija),
				'one' => q(Indijas rūpija),
				'other' => q(Indijas rūpijas),
				'zero' => q(Indijas rūpijas),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irākas dinārs),
				'one' => q(Irākas dinārs),
				'other' => q(Irākas dināri),
				'zero' => q(Irākas dināri),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Irānas riāls),
				'one' => q(Irānas riāls),
				'other' => q(Irānas riāli),
				'zero' => q(Irānas riāli),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Islandes krona),
				'one' => q(Islandes krona),
				'other' => q(Islandes kronas),
				'zero' => q(Islandes kronas),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Itālijas lira),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaikas dolārs),
				'one' => q(Jamaikas dolārs),
				'other' => q(Jamaikas dolāri),
				'zero' => q(Jamaikas dolāri),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordānas dinārs),
				'one' => q(Jordānas dinārs),
				'other' => q(Jordānas dināri),
				'zero' => q(Jordānas dināri),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japānas jena),
				'one' => q(Japānas jena),
				'other' => q(Japānas jenas),
				'zero' => q(Japānas jenas),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenijas šiliņš),
				'one' => q(Kenijas šiliņš),
				'other' => q(Kenijas šiliņi),
				'zero' => q(Kenijas šiliņi),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgizstānas soms),
				'one' => q(Kirgizstānas soms),
				'other' => q(Kirgizstānas somi),
				'zero' => q(Kirgizstānas somi),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodžas riels),
				'one' => q(Kambodžas riels),
				'other' => q(Kambodžas rieli),
				'zero' => q(Kambodžas rieli),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komoru franks),
				'one' => q(Komoru franks),
				'other' => q(Komoru franki),
				'zero' => q(Komoru franki),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Ziemeļkorejas vona),
				'one' => q(Ziemeļkorejas vona),
				'other' => q(Ziemeļkorejas vonas),
				'zero' => q(Ziemeļkorejas vonas),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Dienvidkorejas vona),
				'one' => q(Dienvidkorejas vona),
				'other' => q(Dienvidkorejas vonas),
				'zero' => q(Dienvidkorejas vonas),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuveitas dinārs),
				'one' => q(Kuveitas dinārs),
				'other' => q(Kuveitas dināri),
				'zero' => q(Kuveitas dināri),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaimanu salu dolārs),
				'one' => q(Kaimanu salu dolārs),
				'other' => q(Kaimanu salu dolāri),
				'zero' => q(Kaimanu salu dolāri),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazahstānas tenge),
				'one' => q(Kazahstānas tenge),
				'other' => q(Kazahstānas tenges),
				'zero' => q(Kazahstānas tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laosas kips),
				'one' => q(Laosas kips),
				'other' => q(Laosas kipi),
				'zero' => q(Laosas kipi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libānas mārciņa),
				'one' => q(Libānas mārciņa),
				'other' => q(Libānas mārciņas),
				'zero' => q(Libānas mārciņas),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Šrilankas rūpija),
				'one' => q(Šrilankas rūpija),
				'other' => q(Šrilankas rūpijas),
				'zero' => q(Šrilankas rūpijas),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Libērijas dolārs),
				'one' => q(Libērijas dolārs),
				'other' => q(Libērijas dolāri),
				'zero' => q(Libērijas dolāri),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Lietuvas lits),
				'one' => q(Lietuvas lits),
				'other' => q(Lietuvas liti),
				'zero' => q(Lietuvas liti),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luksemburgas franks),
			},
		},
		'LVL' => {
			symbol => 'Ls',
			display_name => {
				'currency' => q(Latvijas lats),
				'one' => q(Latvijas lats),
				'other' => q(Latvijas lati),
				'zero' => q(Latvijas lati),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvijas rublis),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Lībijas dinārs),
				'one' => q(Lībijas dinārs),
				'other' => q(Lībijas dināri),
				'zero' => q(Lībijas dināri),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokas dirhēms),
				'one' => q(Marokas dirhēms),
				'other' => q(Marokas dirhēmi),
				'zero' => q(Marokas dirhēmi),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldovas leja),
				'one' => q(Moldovas leja),
				'other' => q(Moldovas lejas),
				'zero' => q(Moldovas lejas),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskaras ariari),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Maķedonijas denārs),
				'one' => q(Maķedonijas denārs),
				'other' => q(Maķedonijas denāri),
				'zero' => q(Maķedonijas denāri),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(CFA \(Āfrikas\) franks),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Mjanmas kjats),
				'one' => q(Mjanmas kjats),
				'other' => q(Mjanmas kjati),
				'zero' => q(Mjanmas kjati),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolijas tugriks),
				'one' => q(Mongolijas tugriks),
				'other' => q(Mongolijas tugriki),
				'zero' => q(Mongolijas tugriki),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makao pataka),
				'one' => q(Makao pataka),
				'other' => q(Makao patakas),
				'zero' => q(Makao patakas),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritānijas ugija \(1973–2017\)),
				'one' => q(Mauritānijas ugija \(1973–2017\)),
				'other' => q(Mauritānijas ugijas \(1973–2017\)),
				'zero' => q(Mauritānijas ugijas \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritānijas ugija),
				'one' => q(Mauritānijas ugija),
				'other' => q(Mauritānijas ugijas),
				'zero' => q(Mauritānijas ugijas),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltas lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltas mārciņa),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Maurīcijas rūpija),
				'one' => q(Maurīcijas rūpija),
				'other' => q(Maurīcijas rūpijas),
				'zero' => q(Maurīcijas rūpijas),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldīvijas rūfija),
				'one' => q(Maldīvijas rūfija),
				'other' => q(Maldīvijas rūfijas),
				'zero' => q(Maldīvijas rūfijas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malāvijas kvača),
				'one' => q(Malāvijas kvača),
				'other' => q(Malāvijas kvačas),
				'zero' => q(Malāvijas kvačas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksikas peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaizijas ringits),
				'one' => q(Malaizijas ringits),
				'other' => q(Malaizijas ringiti),
				'zero' => q(Malaizijas ringiti),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambikas eskudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambikas vecais metikals),
				'one' => q(Mozambikas vecais metikals),
				'other' => q(Mozambikas vecie metikali),
				'zero' => q(Mozambikas vecie metikali),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambikas metikals),
				'one' => q(Mozambikas metikals),
				'other' => q(Mozambikas metikali),
				'zero' => q(Mozambikas metikali),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namībijas dolārs),
				'one' => q(Namībijas dolārs),
				'other' => q(Namībijas dolāri),
				'zero' => q(Namībijas dolāri),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigērijas naira),
				'one' => q(Nigērijas naira),
				'other' => q(Nigērijas nairas),
				'zero' => q(Nigērijas nairas),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragvas kordoba),
				'one' => q(Nikaragvas kordoba),
				'other' => q(Nikaragvas kordobas),
				'zero' => q(Nikaragvas kordobas),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Nīderlandes guldenis),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norvēģijas krona),
				'one' => q(Norvēģijas krona),
				'other' => q(Norvēģijas kronas),
				'zero' => q(Norvēģijas kronas),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepālas rūpija),
				'one' => q(Nepālas rūpija),
				'other' => q(Nepālas rūpijas),
				'zero' => q(Nepālas rūpijas),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Jaunzēlandes dolārs),
				'one' => q(Jaunzēlandes dolārs),
				'other' => q(Jaunzēlandes dolāri),
				'zero' => q(Jaunzēlandes dolāri),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omānas riāls),
				'one' => q(Omānas riāls),
				'other' => q(Omānas riāli),
				'zero' => q(Omānas riāli),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamas balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru sols),
				'one' => q(Peru sols),
				'other' => q(Peru soli),
				'zero' => q(Peru soli),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua-Jaungvinejas kina),
				'one' => q(Papua-Jaungvinejas kina),
				'other' => q(Papua-Jaungvinejas kinas),
				'zero' => q(Papua-Jaungvinejas kinas),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipīnu peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistānas rūpija),
				'one' => q(Pakistānas rūpija),
				'other' => q(Pakistānas rūpijas),
				'zero' => q(Pakistānas rūpijas),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polijas zlots),
				'one' => q(Polijas zlots),
				'other' => q(Polijas zloti),
				'zero' => q(Polijas zloti),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugāles eskudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paragvajas guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Kataras riāls),
				'one' => q(Kataras riāls),
				'other' => q(Kataras riāli),
				'zero' => q(Kataras riāli),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumānijas vecā leja),
				'one' => q(Rumānijas vecā leva),
				'other' => q(Rumānijas vecās levas),
				'zero' => q(Rumānijas vecās levas),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumānijas leja),
				'one' => q(Rumānijas leja),
				'other' => q(Rumānijas lejas),
				'zero' => q(Rumānijas lejas),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbijas dinārs),
				'one' => q(Serbijas dinārs),
				'other' => q(Serbijas dināri),
				'zero' => q(Serbijas dināri),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Krievijas rublis),
				'one' => q(Krievijas rublis),
				'other' => q(Krievijas rubļi),
				'zero' => q(Krievijas rubļi),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruandas franks),
				'one' => q(Ruandas franks),
				'other' => q(Ruandas franki),
				'zero' => q(Ruandas franki),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saūda Arābijas riāls),
				'one' => q(Saūda riāls),
				'other' => q(Saūda riāli),
				'zero' => q(Saūda riāli),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Zālamana Salu dolārs),
				'one' => q(Zālamana Salu dolārs),
				'other' => q(Zālamana Salu dolāri),
				'zero' => q(Zālamana Salu dolāri),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seišelu salu rūpija),
				'one' => q(Seišelu salu rūpija),
				'other' => q(Seišelu salu rūpijas),
				'zero' => q(Seišelu salu rūpijas),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudānas mārciņa),
				'one' => q(Sudānas mārciņa),
				'other' => q(Sudānas mārciņas),
				'zero' => q(Sudānas mārciņas),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Zviedrijas krona),
				'one' => q(Zviedrijas krona),
				'other' => q(Zviedrijas kronas),
				'zero' => q(Zviedrijas kronas),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapūras dolārs),
				'one' => q(Singapūras dolārs),
				'other' => q(Singapūras dolāri),
				'zero' => q(Singapūras dolāri),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Sv.Helēnas salas mārciņa),
				'one' => q(Sv.Helēnas salas mārciņa),
				'other' => q(Sv.Helēnas salas mārciņas),
				'zero' => q(Sv.Helēnas salas mārciņas),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovēnijas tolars),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovakijas krona),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sjerraleones leone),
				'one' => q(Sjerraleones leone),
				'other' => q(Sjerraleones leones),
				'zero' => q(Sjerraleones leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sjerraleones leone \(1964—2022\)),
				'one' => q(Sjerraleones leone \(1964—2022\)),
				'other' => q(Sjerraleones leones \(1964—2022\)),
				'zero' => q(Sjerraleones leones \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somālijas šiliņš),
				'one' => q(Somālijas šiliņš),
				'other' => q(Somālijas šiliņi),
				'zero' => q(Somālijas šiliņi),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinamas dolārs),
				'one' => q(Surinamas dolārs),
				'other' => q(Surinamas dolāri),
				'zero' => q(Surinamas dolāri),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamas guldenis),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Dienvidsudānas mārciņa),
				'one' => q(Dienvidsudānas mārciņa),
				'other' => q(Dienvidsudānas mārciņas),
				'zero' => q(Dienvidsudānas mārciņas),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Santome un Prinsipi dobra \(1977–2017\)),
				'one' => q(Santome un Prinsipi dobra \(1977–2017\)),
				'other' => q(Santome un Prinsipi dobras \(1977–2017\)),
				'zero' => q(Santome un Prinsipi dobras \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Santome un Prinsipi dobra),
				'one' => q(Santome un Prinsipi dobra),
				'other' => q(Santome un Prinsipi dobras),
				'zero' => q(Santome un Prinsipi dobras),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadoras kolons),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Sīrijas mārciņa),
				'one' => q(Sīrijas mārciņa),
				'other' => q(Sīrijas mārciņas),
				'zero' => q(Sīrijas mārciņas),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Svazilendas lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Taizemes bāts),
				'one' => q(Taizemes bāts),
				'other' => q(Taizemes bāti),
				'zero' => q(Taizemes bāti),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadžikistānas somons),
				'one' => q(Tadžikistānas somons),
				'other' => q(Tadžikistānas somoni),
				'zero' => q(Tadžikistānas somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistānas manats \(1993–2009\)),
				'one' => q(Turkmenistānas manats \(1993–2009\)),
				'other' => q(Turkmenistānas manati \(1993–2009\)),
				'zero' => q(Turkmenistānas manati \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistānas manats),
				'one' => q(Turkmenistānas manats),
				'other' => q(Turkmenistānas manati),
				'zero' => q(Turkmenistānas manati),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisijas dinārs),
				'one' => q(Tunisijas dinārs),
				'other' => q(Tunisijas dināri),
				'zero' => q(Tunisijas dināri),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongas paanga),
				'one' => q(Tongas paanga),
				'other' => q(Tongas paangas),
				'zero' => q(Tongas paangas),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turcijas lira \(1922–2005\)),
				'one' => q(Turcijas lira \(1922–2005\)),
				'other' => q(Turcijas liras \(1922–2005\)),
				'zero' => q(Turcijas liras \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turcijas lira),
				'one' => q(Turcijas lira),
				'other' => q(Turcijas liras),
				'zero' => q(Turcijas liras),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidādas un Tobāgo dolārs),
				'one' => q(Trinidādas un Tobāgo dolārs),
				'other' => q(Trinidādas un Tobāgo dolāri),
				'zero' => q(Trinidādas un Tobāgo dolāri),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Taivānas jaunais dolārs),
				'one' => q(Taivānas jaunais dolārs),
				'other' => q(Taivānas jaunie dolāri),
				'zero' => q(Taivānas jaunie dolāri),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzānijas šiliņš),
				'one' => q(Tanzānijas šiliņš),
				'other' => q(Tanzānijas šiliņi),
				'zero' => q(Tanzānijas šiliņi),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrainas grivna),
				'one' => q(Ukrainas grivna),
				'other' => q(Ukrainas grivnas),
				'zero' => q(Ukrainas grivnas),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandas šiliņš),
				'one' => q(Ugandas šiliņš),
				'other' => q(Ugandas šiliņi),
				'zero' => q(Ugandas šiliņi),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ASV dolārs),
				'one' => q(ASV dolārs),
				'other' => q(ASV dolāri),
				'zero' => q(ASV dolāri),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Urugvajas peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Uzbekistānas sums),
				'one' => q(Uzbekistānas sums),
				'other' => q(Uzbekistānas sumi),
				'zero' => q(Uzbekistānas sumi),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venecuēlas bolivārs \(1871–2008\)),
				'one' => q(Venecuēlas bolivārs \(1871–2008\)),
				'other' => q(Venecuēlas bolivāri \(1871–2008\)),
				'zero' => q(Venecuēlas bolivāri \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venecuēlas bolivārs \(2008–2018\)),
				'one' => q(Venecuēlas bolivārs \(2008–2018\)),
				'other' => q(Venecuēlas bolivāri \(2008–2018\)),
				'zero' => q(Venecuēlas bolivāri \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venecuēlas bolivārs),
				'one' => q(Venecuēlas bolivārs),
				'other' => q(Venecuēlas bolivāri),
				'zero' => q(Venecuēlas bolivāri),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vjetnamas dongi),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa tala),
				'one' => q(Samoa tala),
				'other' => q(Samoa talas),
				'zero' => q(Samoa talas),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Centrālāfrikas CFA franks),
				'one' => q(Centrālāfrikas CFA franks),
				'other' => q(Centrālāfrikas CFA franki),
				'zero' => q(Centrālāfrikas CFA franki),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(sudrabs),
				'one' => q(unces sudrabs),
				'other' => q(unces sudrabs),
				'zero' => q(unces sudrabs),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(zelts),
				'one' => q(unces zelts),
				'other' => q(unces zelts),
				'zero' => q(unces zelts),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Eiropas norēķinu vienība EURCO),
				'one' => q(Eiropas norēķinu vienība EURCO),
				'other' => q(Eiropas norēķinu vienības EURCO),
				'zero' => q(Eiropas norēķinu vienības EURCO),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Eiropas naudas vienība),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Eiropas norēķinu vienība \(XBC\)),
				'one' => q(Eiropas norēķinu vienība \(XBC\)),
				'other' => q(Eiropas norēķinu vienības \(XBC\)),
				'zero' => q(Eiropas norēķinu vienības \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Eiropas norēķinu vienība \(XBD\)),
				'one' => q(Eiropas norēķinu vienība \(XBD\)),
				'other' => q(Eiropas norēķinu vienības \(XBD\)),
				'zero' => q(Eiropas norēķinu vienības \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Austrumkarību dolārs),
				'one' => q(Austrumkarību dolārs),
				'other' => q(Austrumkarību dolāri),
				'zero' => q(Austrumkarību dolāri),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Speciālās aizņēmuma tiesības),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Eiropas norēķinu vienība),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Francijas zelta franks),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Francijas UIC franks),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Rietumāfrikas CFA franks),
				'one' => q(Rietumāfrikas CFA franks),
				'other' => q(Rietumāfrikas CFA franki),
				'zero' => q(Rietumāfrikas CFA franki),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(pallādijs),
				'one' => q(unces pallādijs),
				'other' => q(unces pallādijs),
				'zero' => q(unces pallādijs),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP franks),
				'one' => q(CFP franks),
				'other' => q(CFP franki),
				'zero' => q(CFP franki),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platīns),
				'one' => q(unces platīns),
				'other' => q(unces platīns),
				'zero' => q(unces platīns),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Testa valūtas kods),
				'one' => q(testa valūtas kods),
				'other' => q(testa valūtas kods),
				'zero' => q(testa valūtas kods),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nezināma valūta),
				'one' => q(\(nezināma valūta\)),
				'other' => q(\(nezināma valūta\)),
				'zero' => q(\(nezināma valūta\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemenas riāls),
				'one' => q(Jemenas riāls),
				'other' => q(Jemenas riāli),
				'zero' => q(Jemenas riāli),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Dienvidāfrikas rends),
				'one' => q(Dienvidāfrikas rends),
				'other' => q(Dienvidāfrikas rendi),
				'zero' => q(Dienvidāfrikas rendi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambijas kvača \(1968–2012\)),
				'one' => q(Zambijas kvača \(1968–2012\)),
				'other' => q(Zambijas kvačas \(1968–2012\)),
				'zero' => q(Zambijas kvačas \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambijas kvača),
				'one' => q(Zambijas kvača),
				'other' => q(Zambijas kvačas),
				'zero' => q(Zambijas kvačas),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabves dolārs),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabves dolārs \(2009\)),
				'one' => q(Zimbabves dollārs \(2009\)),
				'other' => q(Zimbabves dollāri \(2009\)),
				'zero' => q(Zimbabves dollāri \(2009\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'tots',
							'baba',
							'haturs',
							'kihaks',
							'tuba',
							'amšīrs',
							'baramhats',
							'barmuda',
							'bašnass',
							'bauna',
							'abibs',
							'misra',
							'nasī'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					wide => {
						nonleap => [
							'meskerems',
							'tekemts',
							'hedars',
							'tahsass',
							'ters',
							'jakatīts',
							'magabits',
							'miāzija',
							'genbots',
							'senē',
							'hamlē',
							'nahasē',
							'epagomens'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'janv.',
							'febr.',
							'marts',
							'apr.',
							'maijs',
							'jūn.',
							'jūl.',
							'aug.',
							'sept.',
							'okt.',
							'nov.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'janvāris',
							'februāris',
							'marts',
							'aprīlis',
							'maijs',
							'jūnijs',
							'jūlijs',
							'augusts',
							'septembris',
							'oktobris',
							'novembris',
							'decembris'
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
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'tišri',
							'hešvans',
							'kisļevs',
							'tevets',
							'ševats',
							'1. adars',
							'adars',
							'nisans',
							'ijars',
							'sivans',
							'tamuzs',
							'avs',
							'eluls'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					wide => {
						nonleap => [
							'Čaitra',
							'Vaišākha',
							'Džjēštha',
							'Āšādha',
							'Šrāvana',
							'Bhadrapāda',
							'Āšvina',
							'Kārtika',
							'Mārgašīrša',
							'Pauša',
							'Māgha',
							'Phālguna'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					wide => {
						nonleap => [
							'muharams',
							'safars',
							'1. rabī',
							'2. rabī',
							'1. džumādā',
							'2. džumādā',
							'radžabs',
							'šabans',
							'ramadāns',
							'šauvals',
							'du al-kidā',
							'du al-hidžā'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					wide => {
						nonleap => [
							'farvardīns',
							'ordibehešts',
							'hordāds',
							'tīrs',
							'mordāds',
							'šahrivērs',
							'mehrs',
							'abans',
							'azers',
							'dejs',
							'bahmans',
							'esfands'
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
						mon => 'pirmd.',
						tue => 'otrd.',
						wed => 'trešd.',
						thu => 'ceturtd.',
						fri => 'piektd.',
						sat => 'sestd.',
						sun => 'svētd.'
					},
					short => {
						mon => 'Pr',
						tue => 'Ot',
						wed => 'Tr',
						thu => 'Ce',
						fri => 'Pk',
						sat => 'Se',
						sun => 'Sv'
					},
					wide => {
						mon => 'pirmdiena',
						tue => 'otrdiena',
						wed => 'trešdiena',
						thu => 'ceturtdiena',
						fri => 'piektdiena',
						sat => 'sestdiena',
						sun => 'svētdiena'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Pirmd.',
						tue => 'Otrd.',
						wed => 'Trešd.',
						thu => 'Ceturtd.',
						fri => 'Piektd.',
						sat => 'Sestd.',
						sun => 'Svētd.'
					},
					narrow => {
						mon => 'P',
						tue => 'O',
						wed => 'T',
						thu => 'C',
						fri => 'P',
						sat => 'S',
						sun => 'S'
					},
					wide => {
						mon => 'Pirmdiena',
						tue => 'Otrdiena',
						wed => 'Trešdiena',
						thu => 'Ceturtdiena',
						fri => 'Piektdiena',
						sat => 'Sestdiena',
						sun => 'Svētdiena'
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
					abbreviated => {0 => '1. cet.',
						1 => '2. cet.',
						2 => '3. cet.',
						3 => '4. cet.'
					},
					wide => {0 => '1. ceturksnis',
						1 => '2. ceturksnis',
						2 => '3. ceturksnis',
						3 => '4. ceturksnis'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2300;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2300;
					return 'night1' if $time < 600;
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
					'afternoon1' => q{pēcpusd.},
					'am' => q{priekšp.},
					'evening1' => q{vakarā},
					'midnight' => q{pusnaktī},
					'morning1' => q{no rīta},
					'night1' => q{naktī},
					'noon' => q{pusd.},
					'pm' => q{pēcp.},
				},
				'wide' => {
					'afternoon1' => q{pēcpusdienā},
					'am' => q{priekšpusdienā},
					'evening1' => q{vakarā},
					'midnight' => q{pusnaktī},
					'morning1' => q{no rīta},
					'night1' => q{naktī},
					'noon' => q{pusdienlaikā},
					'pm' => q{pēcpusdienā},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pēcpusd.},
					'am' => q{priekšp.},
					'evening1' => q{vakars},
					'midnight' => q{pusnakts},
					'morning1' => q{rīts},
					'night1' => q{nakts},
					'pm' => q{pēcpusd.},
				},
				'wide' => {
					'afternoon1' => q{pēcpusdiena},
					'am' => q{priekšpusdiena},
					'evening1' => q{vakars},
					'morning1' => q{rīts},
					'night1' => q{nakts},
					'noon' => q{pusdienlaiks},
					'pm' => q{pēcpusdiena},
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
		'buddhist' => {
			abbreviated => {
				'0' => 'B.E.'
			},
			wide => {
				'0' => 'budistu ēra'
			},
		},
		'coptic' => {
			abbreviated => {
				'0' => 'pirms Diokl.',
				'1' => 'pēc Diokl.'
			},
			wide => {
				'0' => 'pirms Diokletiāna',
				'1' => 'pēc Diokletiāna'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'pirms Kristus',
				'1' => 'pēc Kristus'
			},
			wide => {
				'0' => 'pirms Kristus iemiesošanās',
				'1' => 'pēc Kristus iemiesošanās'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'p.m.ē.',
				'1' => 'm.ē.'
			},
			wide => {
				'0' => 'pirms mūsu ēras',
				'1' => 'mūsu ērā'
			},
		},
		'hebrew' => {
			wide => {
				'0' => 'kopš pasaules radīšanas'
			},
		},
		'indian' => {
		},
		'islamic' => {
			wide => {
				'0' => 'pēc hidžras'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'pers. gads'
			},
			wide => {
				'0' => 'persiešu gads'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'pirms republikas',
				'1' => 'Miņgo'
			},
			narrow => {
				'0' => 'pirms rep.'
			},
			wide => {
				'0' => 'pirms Ķīnas Republikas dibināšanas'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, y. 'gada' d. MMMM G},
			'long' => q{y. 'gada' d. MMMM G},
			'medium' => q{y. 'gada' d. MMM G},
			'short' => q{dd.MM.y. GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, y. 'gada' d. MMMM},
			'long' => q{y. 'gada' d. MMMM},
			'medium' => q{y. 'gada' d. MMM},
			'short' => q{dd.MM.yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y. 'g'. G},
			GyMMM => q{y. 'g'. MMM G},
			GyMMMEd => q{E, y. 'g'. d. MMM G},
			GyMMMd => q{y. 'g'. d. MMM G},
			GyMd => q{dd-MM-y GGGGG},
			MEd => q{E, dd.MM.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y. 'g'. G},
			yyyy => q{y. 'g'. G},
			yyyyM => q{MM.y. G},
			yyyyMEd => q{E, d.M.y. G},
			yyyyMMM => q{y. 'g'. MMM G},
			yyyyMMMEd => q{E, y. 'g'. d. MMM G},
			yyyyMMMM => q{y. 'g'. MMMM G},
			yyyyMMMd => q{y. 'g'. d. MMM G},
			yyyyMd => q{d.MM.y. G},
			yyyyQQQ => q{y. 'g'. QQQ G},
			yyyyQQQQ => q{y. 'gada' QQQQ G},
		},
		'gregorian' => {
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{G y. 'g'.},
			GyMMM => q{G y. 'g'. MMM},
			GyMMMEd => q{E, G y. 'g'. d. MMM},
			GyMMMd => q{G y. 'g'. d. MMM},
			GyMd => q{GGGGG dd-MM-y},
			MEd => q{E, dd.MM.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{MMMM, W. 'nedēļa'},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			y => q{y. 'g'.},
			yM => q{MM.y.},
			yMEd => q{E, d.MM.y.},
			yMMM => q{y. 'g'. MMM},
			yMMMEd => q{E, y. 'g'. d. MMM},
			yMMMM => q{y. 'g'. MMMM},
			yMMMd => q{y. 'g'. d. MMM},
			yMd => q{d.MM.y.},
			yQQQ => q{y. 'g'. QQQ},
			yQQQQ => q{y. 'g'. QQQQ},
			yw => q{Y. 'g'. w. 'nedēļa'},
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
			GyMMM => {
				G => q{G y. 'gada' MMM – G y 'gada' MMM},
				M => q{G y. 'gada' MMM–MMM},
				y => q{G y. 'gada' MMM – y. 'gada' MMM},
			},
			GyMMMEd => {
				G => q{G y. 'gada' d. MMM, E – G y. 'gada' d. MMM, E},
				M => q{G y. 'gada' d. MMM, E – d. MMM, E},
				d => q{G y. 'gada' d. MMM, E – d. MMM, E},
				y => q{G y. 'gada' d. MMM, E – y. 'gada' d. MMM, E},
			},
			GyMMMd => {
				G => q{G y. 'gada' d. MMM – G y. 'gada' d. MMM},
				M => q{G y. 'gada' d. MMM – d. MMM},
				d => q{G y. 'gada' d.–d. MMM},
				y => q{G y. 'gada' d. MMM – y. 'gada' d. MMM},
			},
			MEd => {
				M => q{E, dd.MM.–E, dd.MM.},
				d => q{E, dd.MM.–E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM–E, d. MMM},
				d => q{E, d. MMM–E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM.–dd.MM.},
				d => q{dd.MM.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}–{1}',
			y => {
				y => q{y.–y. G},
			},
			yM => {
				M => q{MM.y.–MM.y. GGGGG},
				y => q{MM.y.–MM.y. GGGGG},
			},
			yMEd => {
				M => q{E, dd.MM.y.–E, dd.MM.y. GGGGG},
				d => q{E, dd.MM.y.–E, dd.MM.y. GGGGG},
				y => q{E, dd.MM.y.–E, dd.MM.y. GGGGG},
			},
			yMMM => {
				M => q{y. 'gada' MMM–MMM G},
				y => q{y. 'gada' MMM–y. 'gada' MMM G},
			},
			yMMMEd => {
				M => q{E, y. 'gada' d. MMM–E, y. 'gada' d. MMM G},
				d => q{E, y. 'gada' d. MMM–E, y. 'gada' d. MMM G},
				y => q{E, y. 'gada' d. MMM–E, y. 'gada' d. MMM G},
			},
			yMMMM => {
				M => q{y. 'gada' MMMM–MMMM G},
				y => q{y. 'gada' MMMM–y. 'gada' MMMM G},
			},
			yMMMd => {
				M => q{y. 'gada' d. MMM–d. MMM G},
				d => q{y. 'gada' d.–d. MMM G},
				y => q{y. 'gada' d. MMM–y. 'gada' d. MMM G},
			},
			yMd => {
				M => q{dd.MM.y.–dd.MM.y. GGGGG},
				d => q{dd.MM.y.–dd.MM.y. GGGGG},
				y => q{dd.MM.y.–dd.MM.y. GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{G y. – G y.},
				y => q{G y.–y.},
			},
			GyM => {
				G => q{GGGGG MM-y. – GGGGG MM-y.},
				M => q{GGGGG MM-y. – MM-y.},
				y => q{GGGGG MM-y. – MM-y.},
			},
			GyMEd => {
				G => q{GGGGG dd-MM-y., E – GGGGG dd-MM-y., E},
				M => q{GGGGG dd-MM-y., E – dd-MM-y., E},
				d => q{GGGGG dd-MM-y., E – dd-MM-y., E},
				y => q{GGGGG dd-MM-y., E – dd-MM-y., E},
			},
			GyMMM => {
				G => q{G y. 'gada' MMM – G y. 'gada' MMM},
				M => q{G y. 'gada' MMM–MMM},
				y => q{G y. 'gada' MMM – y. 'gada' MMM},
			},
			GyMMMEd => {
				G => q{G y. 'gada' d. MMM, E – G y. 'gada' d. MMM, E},
				M => q{G y. 'gada' d. MMM, E – d. MMM, E},
				d => q{G y. 'gada' d. MMM, E – d. MMM, E},
				y => q{G y. 'gada' d. MMM, E – y. 'gada' d. MMM, E},
			},
			GyMMMd => {
				G => q{G y. 'gada' d. MMM – G y. 'gada' d. MMM},
				M => q{G y. 'gada' d. MMM – d. MMM},
				d => q{G y. 'gada' d.–d. MMM},
				y => q{G y. 'gada' d. MMM – y. 'gada' d. MMM},
			},
			GyMd => {
				G => q{GGGGG dd-MM-y. – GGGGG dd-MM-y.},
				M => q{GGGGG dd-MM-y. – dd-MM-y.},
				d => q{GGGGG dd-MM-y. – dd-MM-y.},
				y => q{GGGGG dd-MM-y. – dd-MM-y.},
			},
			M => {
				M => q{MM.–MM.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM.–dd.MM.},
				d => q{dd.MM.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
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
				m => q{h:mm–h:mm a, v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y.–y.},
			},
			yM => {
				M => q{MM.y.–MM.y.},
				y => q{MM.y.–MM.y.},
			},
			yMEd => {
				M => q{E, dd.MM.y. – E, dd.MM.y.},
				d => q{E, dd.MM.y. – E, dd.MM.y.},
				y => q{E, dd.MM.y. – E, dd.MM.y.},
			},
			yMMM => {
				M => q{y. 'gada' MMM–MMM},
				y => q{y. 'gada' MMM – y. 'gada' MMM},
			},
			yMMMEd => {
				M => q{E, y. 'gada' d. MMM – E, y. 'gada' d. MMM},
				d => q{E, y. 'gada' d. MMM – E, y. 'gada' d. MMM},
				y => q{E, y. 'gada' d. MMM – E, y. 'gada' d. MMM},
			},
			yMMMM => {
				M => q{y. 'gada' MMMM – MMMM},
				y => q{y. 'gada' MMMM – y. 'gada' MMMM},
			},
			yMMMd => {
				M => q{y. 'gada' d. MMM – d. MMM},
				d => q{y. 'gada' d.–d. MMM},
				y => q{y. 'gada' d. MMM – y. 'gada' d. MMM},
			},
			yMd => {
				M => q{dd.MM.y.–dd.MM.y.},
				d => q{dd.MM.y.–dd.MM.y.},
				y => q{dd.MM.y.–dd.MM.y.},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Laika josla: {0}),
		regionFormat => q({0}: vasaras laiks),
		regionFormat => q({0}: standarta laiks),
		fallbackFormat => q({0} ({1})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistānas laiks#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidžana#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adisabeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžīra#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bandžula#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisava#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantaira#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazavila#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bužumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kaira#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakara#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dāresalāma#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibutija#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Ajūna#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Frītauna#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburga#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Džūba#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Hartūma#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinšasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagosa#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevila#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaši#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputu#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadīšo#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovija#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndžamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niameja#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakšota#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Vagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Portonovo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Santome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripole#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunisa#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vindhuka#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Centrālāfrikas laiks#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Austrumāfrikas laiks#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Dienvidāfrikas ziemas laiks#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Rietumāfrikas vasaras laiks#,
				'generic' => q#Rietumāfrikas laiks#,
				'standard' => q#Rietumāfrikas ziemas laiks#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aļaskas vasaras laiks#,
				'generic' => q#Aļaskas laiks#,
				'standard' => q#Aļaskas ziemas laiks#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazones vasaras laiks#,
				'generic' => q#Amazones laiks#,
				'standard' => q#Amazones ziemas laiks#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adaka#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankurāža#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angilja#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigva#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Aragvaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Larjoha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Riogaljegosa#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Sanhuana#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Sanluisa#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukumana#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ušuaja#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsjona#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baija#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bajabanderasa#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbadosa#,
		},
		'America/Belem' => {
			exemplarCity => q#Belena#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliza#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blansablona#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boavista#,
		},
		'America/Boise' => {
			exemplarCity => q#Boisisitija#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenosairesa#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembridžbeja#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampugrandi#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankuna#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakasa#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kajenna#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimanu salas#,
		},
		'America/Chicago' => {
			exemplarCity => q#Čikāga#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Čivava#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Huaresa#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokana#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordova#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Creston' => {
			exemplarCity => q#Krestona#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kujaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kirasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Denmārkšavna#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dousona#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dousonkrīka#,
		},
		'America/Denver' => {
			exemplarCity => q#Denvera#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroita#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmontona#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvadora#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fortnelsona#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Gleisbeja#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nūka#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gūsbeja#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grandtkērka#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenāda#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gvadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Gvajakila#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gajāna#,
		},
		'America/Halifax' => {
			exemplarCity => q#Helifeksa#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Ermosiljo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Noksa, Indiāna#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiāna#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pītersbērga, Indiāna#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Telsitija, Indiāna#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vīveja, Indiāna#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsensa, Indiāna#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Vinamaka, Indiāna#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolisa#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvika#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluita#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Huhuja#,
		},
		'America/Juneau' => {
			exemplarCity => q#Džuno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montičelo, Kentuki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Krālendeika#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Lapasa#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Losandželosa#,
		},
		'America/Louisville' => {
			exemplarCity => q#Lūivila#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Louerprinseskvotera#,
		},
		'America/Maceio' => {
			exemplarCity => q#Masejo#,
		},
		'America/Managua' => {
			exemplarCity => q#Managva#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manausa#,
		},
		'America/Marigot' => {
			exemplarCity => q#Merigota#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamorosa#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Masatlana#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominī#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mehiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelona#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monktona#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterreja#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrata#,
		},
		'America/Nassau' => {
			exemplarCity => q#Naso#,
		},
		'America/New_York' => {
			exemplarCity => q#Ņujorka#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigona#,
		},
		'America/Nome' => {
			exemplarCity => q#Noma#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noroņa#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Bjula, Ziemeļdakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sentera, Ziemeļdakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Ņūseilema, Ziemeļdakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ohinaga#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pannirtuna#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Fīniksa#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Portoprensa#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Portofspeina#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Portuveļu#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puertoriko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Puntaarenasa#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reinirivera#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankininleta#,
		},
		'America/Recife' => {
			exemplarCity => q#Resifi#,
		},
		'America/Regina' => {
			exemplarCity => q#Ridžaina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rezolūta#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riobranko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santaisabela#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarena#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santjago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santodomingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sanpaulu#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itokortormita#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Senbartelmī#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sentdžonsa#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sentkitsa#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sentlūsija#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sentomasa#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sentvinsenta#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Sviftkarenta#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tanderbeja#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tihuana#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankūvera#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Vaithorsa#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vinipega#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Jakutata#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Jelounaifa#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Centrālais vasaras laiks#,
				'generic' => q#Centrālais laiks#,
				'standard' => q#Centrālais ziemas laiks#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Austrumu vasaras laiks#,
				'generic' => q#Austrumu laiks#,
				'standard' => q#Austrumu ziemas laiks#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Kalnu vasaras laiks#,
				'generic' => q#Kalnu laiks#,
				'standard' => q#Kalnu ziemas laiks#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Klusā okeāna vasaras laiks#,
				'generic' => q#Klusā okeāna laiks#,
				'standard' => q#Klusā okeāna ziemas laiks#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadiras vasaras laiks#,
				'generic' => q#Anadiras laiks#,
				'standard' => q#Anadiras ziemas laiks#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keisi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Deivisa#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dimondirvila#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makvori#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mosona#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Makmerdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Pālmera#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Šova#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Trolla#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostoka#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apijas vasaras laiks#,
				'generic' => q#Apijas laiks#,
				'standard' => q#Apijas ziemas laiks#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arābijas pussalas vasaras laiks#,
				'generic' => q#Arābijas pussalas laiks#,
				'standard' => q#Arābijas pussalas ziemas laiks#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longjērbīene#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentīnas vasaras laiks#,
				'generic' => q#Argentīnas laiks#,
				'standard' => q#Argentīnas ziemas laiks#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Rietumargentīnas vasaras laiks#,
				'generic' => q#Rietumargentīnas laiks#,
				'standard' => q#Rietumargentīnas ziemas laiks#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armēnijas vasaras laiks#,
				'generic' => q#Armēnijas laiks#,
				'standard' => q#Armēnijas ziemas laiks#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adena#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammāna#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadira#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktebe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ašgabata#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdāde#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahreina#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkoka#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaula#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirūta#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškeka#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruneja#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkāta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Čoibalsana#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaska#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaija#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrona#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Honkonga#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovda#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutska#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Džakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Džajapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzaleme#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabula#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karāči#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarska#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kualalumpura#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kučina#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuveita#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadana#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasara#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskata#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosija#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuzņecka#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirska#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omska#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Orala#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnompeņa#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianaka#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Phenjana#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katara#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaja#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ranguna#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijāda#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hošimina#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalīna#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seula#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šanhaja#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapūra#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Sredņekolimska#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taibei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškenta#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherāna#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokija#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomska#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbatora#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ustjņera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vjenčana#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostoka#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutska#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburga#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevāna#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantijas vasaras laiks#,
				'generic' => q#Atlantijas laiks#,
				'standard' => q#Atlantijas ziemas laiks#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoru salas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanāriju salas#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kaboverde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Fēru salas#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reikjavika#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Dienviddžordžija#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sv.Helēnas sala#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbena#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Brokenhila#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kari#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Dārvina#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Jukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobārta#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindemana#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lordhava#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburna#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pērta#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidneja#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Austrālijas centrālais vasaras laiks#,
				'generic' => q#Austrālijas centrālais laiks#,
				'standard' => q#Austrālijas centrālais ziemas laiks#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Austrālijas centrālais rietumu vasaras laiks#,
				'generic' => q#Austrālijas centrālais rietumu laiks#,
				'standard' => q#Austrālijas centrālais rietumu ziemas laiks#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Austrālijas austrumu vasaras laiks#,
				'generic' => q#Austrālijas austrumu laiks#,
				'standard' => q#Austrālijas austrumu ziemas laiks#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Austrālijas rietumu vasaras laiks#,
				'generic' => q#Austrālijas rietumu laiks#,
				'standard' => q#Austrālijas rietumu ziemas laiks#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaidžānas vasaras laiks#,
				'generic' => q#Azerbaidžānas laiks#,
				'standard' => q#Azerbaidžānas ziemas laiks#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoru salu vasaras laiks#,
				'generic' => q#Azoru salu laiks#,
				'standard' => q#Azoru salu ziemas laiks#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladešas vasaras laiks#,
				'generic' => q#Bangladešas laiks#,
				'standard' => q#Bangladešas ziemas laiks#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butānas laiks#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolīvijas laiks#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brazīlijas vasaras laiks#,
				'generic' => q#Brazīlijas laiks#,
				'standard' => q#Brazīlijas ziemas laiks#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunejas Darusalamas laiks#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kaboverdes vasaras laiks#,
				'generic' => q#Kaboverdes laiks#,
				'standard' => q#Kaboverdes ziemas laiks#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Čamorra ziemas laiks#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Četemas vasaras laiks#,
				'generic' => q#Četemas laiks#,
				'standard' => q#Četemas ziemas laiks#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Čīles vasaras laiks#,
				'generic' => q#Čīles laiks#,
				'standard' => q#Čīles ziemas laiks#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ķīnas vasaras laiks#,
				'generic' => q#Ķīnas laiks#,
				'standard' => q#Ķīnas ziemas laiks#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Čoibalsanas vasaras laiks#,
				'generic' => q#Čoibalsanas laiks#,
				'standard' => q#Čoibalsanas ziemas laiks#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ziemsvētku salas laiks#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokosu (Kīlinga) salu laiks#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbijas vasaras laiks#,
				'generic' => q#Kolumbijas laiks#,
				'standard' => q#Kolumbijas ziemas laiks#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kuka salu vasaras laiks#,
				'generic' => q#Kuka salu laiks#,
				'standard' => q#Kuka salu ziemas laiks#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubas vasaras laiks#,
				'generic' => q#Kubas laiks#,
				'standard' => q#Kubas ziemas laiks#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Deivisas laiks#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dimondirvilas laiks#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Austrumtimoras laiks#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Lieldienu salas vasaras laiks#,
				'generic' => q#Lieldienu salas laiks#,
				'standard' => q#Lieldienu salas ziemas laiks#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvadoras laiks#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Universālais koordinētais laiks#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#nezināma pilsēta#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdama#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahaņa#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atēnas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrada#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlīne#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brisele#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukareste#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapešta#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Bīzingene#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišiņeva#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhāgena#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublina#,
			long => {
				'daylight' => q#Īrijas ziemas laiks#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltārs#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gērnsija#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Menas sala#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Stambula#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Džērsija#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaļiņingrada#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijeva#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirova#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ļubļana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londona#,
			long => {
				'daylight' => q#Lielbritānijas vasaras laiks#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburga#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madride#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamna#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minska#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Maskava#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parīze#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prāga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Rīga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Sanmarīno#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajeva#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratova#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopole#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholma#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallina#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirāna#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uļjanovska#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užhoroda#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduca#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikāns#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vīne#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Viļņa#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograda#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreba#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporožje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Cīrihe#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Centrāleiropas vasaras laiks#,
				'generic' => q#Centrāleiropas laiks#,
				'standard' => q#Centrāleiropas ziemas laiks#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Austrumeiropas vasaras laiks#,
				'generic' => q#Austrumeiropas laiks#,
				'standard' => q#Austrumeiropas ziemas laiks#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Austrumeiropas laika josla (FET)#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Rietumeiropas vasaras laiks#,
				'generic' => q#Rietumeiropas laiks#,
				'standard' => q#Rietumeiropas ziemas laiks#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklenda (Malvinu) salu vasaras laiks#,
				'generic' => q#Folklenda (Malvinu) salu laiks#,
				'standard' => q#Folklenda (Malvinu) salu ziemas laiks#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidži vasaras laiks#,
				'generic' => q#Fidži laiks#,
				'standard' => q#Fidži ziemas laiks#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francijas Gviānas laiks#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Francijas Dienvidjūru un Antarktikas teritorijas laiks#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Griničas laiks#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagu laiks#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambjē salu laiks#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzijas vasaras laiks#,
				'generic' => q#Gruzijas laiks#,
				'standard' => q#Gruzijas ziemas laiks#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilberta salu laiks#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Austrumgrenlandes vasaras laiks#,
				'generic' => q#Austrumgrenlandes laiks#,
				'standard' => q#Austrumgrenlandes ziemas laiks#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Rietumgrenlandes vasaras laiks#,
				'generic' => q#Rietumgrenlandes laiks#,
				'standard' => q#Rietumgrenlandes ziemas laiks#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Persijas līča laiks#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gajānas laiks#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havaju–Aleutu vasaras laiks#,
				'generic' => q#Havaju–Aleutu laiks#,
				'standard' => q#Havaju–Aleutu ziemas laiks#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Honkongas vasaras laiks#,
				'generic' => q#Honkongas laiks#,
				'standard' => q#Honkongas ziemas laiks#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovdas vasaras laiks#,
				'generic' => q#Hovdas laiks#,
				'standard' => q#Hovdas ziemas laiks#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indijas ziemas laiks#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivu#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Čagosa#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Ziemsvētku sala#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosu (Kīlinga) sala#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoras#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelēna sala#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mae#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldīvija#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurīcija#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Majota#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reinjona#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indijas okeāna laiks#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indoķīnas laiks#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Centrālindonēzijas laiks#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Austrumindonēzijas laiks#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Rietumindonēzijas laiks#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Irānas vasaras laiks#,
				'generic' => q#Irānas laiks#,
				'standard' => q#Irānas ziemas laiks#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutskas vasaras laiks#,
				'generic' => q#Irkutskas laiks#,
				'standard' => q#Irkutskas ziemas laiks#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izraēlas vasaras laiks#,
				'generic' => q#Izraēlas laiks#,
				'standard' => q#Izraēlas ziemas laiks#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japānas vasaras laiks#,
				'generic' => q#Japānas laiks#,
				'standard' => q#Japānas ziemas laiks#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovskas-Kamčatskas vasaras laiks#,
				'generic' => q#Petropavlovskas-Kamčatskas laiks#,
				'standard' => q#Petropavlovskas-Kamčatskas ziemas laiks#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Austrumkazahstānas laiks#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Rietumkazahstānas laiks#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejas vasaras laiks#,
				'generic' => q#Korejas laiks#,
				'standard' => q#Korejas ziemas laiks#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae laiks#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarskas vasaras laiks#,
				'generic' => q#Krasnojarskas laiks#,
				'standard' => q#Krasnojarskas ziemas laiks#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgizstānas laiks#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Lainas salu laiks#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lorda Hava salas vasaras laiks#,
				'generic' => q#Lorda Hava salas laiks#,
				'standard' => q#Lorda Hava salas ziemas laiks#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Makvorija salas laiks#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadanas vasaras laiks#,
				'generic' => q#Magadanas laiks#,
				'standard' => q#Magadanas ziemas laiks#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaizijas laiks#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldīvijas laiks#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marķīza salu laiks#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Māršala salu laiks#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Maurīcijas vasaras laiks#,
				'generic' => q#Maurīcijas laiks#,
				'standard' => q#Maurīcijas ziemas laiks#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mosonas laiks#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ziemeļrietumu Meksikas vasaras laiks#,
				'generic' => q#Ziemeļrietumu Meksikas laiks#,
				'standard' => q#Ziemeļrietumu Meksikas ziemas laiks#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksikas Klusā okeāna piekrastes vasaras laiks#,
				'generic' => q#Meksikas Klusā okeāna piekrastes laiks#,
				'standard' => q#Meksikas Klusā okeāna piekrastes ziemas laiks#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulanbatoras vasaras laiks#,
				'generic' => q#Ulanbatoras laiks#,
				'standard' => q#Ulanbatoras ziemas laiks#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Maskavas vasaras laiks#,
				'generic' => q#Maskavas laiks#,
				'standard' => q#Maskavas ziemas laiks#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mjanmas laiks#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru laiks#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepālas laiks#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Jaunkaledonijas vasaras laiks#,
				'generic' => q#Jaunkaledonijas laiks#,
				'standard' => q#Jaunkaledonijas ziemas laiks#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Jaunzēlandes vasaras laiks#,
				'generic' => q#Jaunzēlandes laiks#,
				'standard' => q#Jaunzēlandes ziemas laiks#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ņūfaundlendas vasaras laiks#,
				'generic' => q#Ņūfaundlendas laiks#,
				'standard' => q#Ņūfaundlendas ziemas laiks#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niues laiks#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolkas salas vasaras laiks#,
				'generic' => q#Norfolkas salas laiks#,
				'standard' => q#Norfolkas salas ziemas laiks#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernandu di Noroņas vasaras laiks#,
				'generic' => q#Fernandu di Noroņas laiks#,
				'standard' => q#Fernandu di Noroņas ziemas laiks#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirskas vasaras laiks#,
				'generic' => q#Novosibirskas laiks#,
				'standard' => q#Novosibirskas ziemas laiks#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omskas vasaras laiks#,
				'generic' => q#Omskas laiks#,
				'standard' => q#Omskas ziemas laiks#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apija#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Oklenda#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugenvila sala#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Četema#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Lieldienu sala#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderberija#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagu salas#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambjē salas#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Gvadalkanala#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guama#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Džonstona atols#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Kantona#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kirisimasi#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosraja#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kvadžaleina#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Madžuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marķīza salas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvejs#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolka#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pagopago#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkērna#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponpeja#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Portmorsbi#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipana#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarava#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Čūka#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Veika sala#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Volisa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistānas vasaras laiks#,
				'generic' => q#Pakistānas laiks#,
				'standard' => q#Pakistānas ziemas laiks#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau laiks#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Jaungvinejas laiks#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragvajas vasaras laiks#,
				'generic' => q#Paragvajas laiks#,
				'standard' => q#Paragvajas ziemas laiks#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru vasaras laiks#,
				'generic' => q#Peru laiks#,
				'standard' => q#Peru ziemas laiks#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipīnu vasaras laiks#,
				'generic' => q#Filipīnu laiks#,
				'standard' => q#Filipīnu ziemas laiks#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Fēniksa salu laiks#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Senpjēras un Mikelonas vasaras laiks#,
				'generic' => q#Senpjēras un Mikelonas laiks#,
				'standard' => q#Senpjēras un Mikelonas ziemas laiks#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkērnas laiks#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapē laiks#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Phenjanas laiks#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reinjonas laiks#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Roteras laiks#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalīnas vasaras laiks#,
				'generic' => q#Sahalīnas laiks#,
				'standard' => q#Sahalīnas ziemas laiks#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samaras vasaras laiks#,
				'generic' => q#Samaras laiks#,
				'standard' => q#Samaras ziemas laiks#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa vasaras laiks#,
				'generic' => q#Samoa laiks#,
				'standard' => q#Samoa ziemas laiks#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seišeļu salu laiks#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapūras laiks#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Zālamana salu laiks#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Dienviddžordžijas laiks#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamas laiks#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Šovas laiks#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Taiti laiks#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taibei vasaras laiks#,
				'generic' => q#Taibei laiks#,
				'standard' => q#Taibei ziemas laiks#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistānas laiks#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau laiks#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongas vasaras laiks#,
				'generic' => q#Tongas laiks#,
				'standard' => q#Tongas ziemas laiks#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Čūkas laiks#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistānas vasaras laiks#,
				'generic' => q#Turkmenistānas laiks#,
				'standard' => q#Turkmenistānas ziemas laiks#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu laiks#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugvajas vasaras laiks#,
				'generic' => q#Urugvajas laiks#,
				'standard' => q#Urugvajas ziemas laiks#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistānas vasaras laiks#,
				'generic' => q#Uzbekistānas laiks#,
				'standard' => q#Uzbekistānas ziemas laiks#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu vasaras laiks#,
				'generic' => q#Vanuatu laiks#,
				'standard' => q#Vanuatu ziemas laiks#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venecuēlas laiks#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostokas vasaras laiks#,
				'generic' => q#Vladivostokas laiks#,
				'standard' => q#Vladivostokas ziemas laiks#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgogradas vasaras laiks#,
				'generic' => q#Volgogradas laiks#,
				'standard' => q#Volgogradas ziemas laiks#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostokas laiks#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Veika salas laiks#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Volisas un Futunas laiks#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutskas vasaras laiks#,
				'generic' => q#Jakutskas laiks#,
				'standard' => q#Jakutskas ziemas laiks#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgas vasaras laiks#,
				'generic' => q#Jekaterinburgas laiks#,
				'standard' => q#Jekaterinburgas ziemas laiks#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Jukonas laiks#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
