=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Is - Package for language Icelandic

=cut

package Locale::CLDR::Locales::Is;
# This file auto generated from Data\common\main\is.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine' ]},
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
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(núll),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ein),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tvær),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(þrjár),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjórar),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tuttugu[ og →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(þrjátíu[ og →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fjörutíu[ og →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fimmtíu[ og →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextíu[ og →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjötíu[ og →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(áttatíu[ og →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(níutíu[ og →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrað[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← þúsund[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ein millión[ og →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milliónur[ og →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ein milliarð[ og →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milliarður[ og →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ein billión[ og →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← billiónur[ og →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ein billiarð[ og →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← billiarður[ og →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(núll),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(einn),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tveir),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(þrír),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjórir),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fimm),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sex),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjó),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(átta),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(níu),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tíu),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ellefu),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tólf),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(þrettán),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjórtán),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(fimmtán),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sextán),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sautján),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(átján),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nítján),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tuttugu[ og →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(þrjátíu[ og →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fjörutíu[ og →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fimmtíu[ og →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextíu[ og →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjötíu[ og →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(áttatíu[ og →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(níutíu[ og →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrað[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← þúsund[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ein millión[ og →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milliónur[ og →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ein milliarð[ og →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milliarður[ og →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ein billión[ og →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← billiónur[ og →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ein billiarð[ og →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← billiarður[ og →→]),
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
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(núll),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eitt),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tvö),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(þrjú),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjögur),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tuttugu[ og →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(þrjátíu[ og →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(fjörutíu[ og →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fimmtíu[ og →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sextíu[ og →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sjötíu[ og →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(áttatíu[ og →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(níutíu[ og →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter←­hundrað[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← þúsund[ og →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(ein millión[ og →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milliónur[ og →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(ein milliarð[ og →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← milliarður[ og →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ein billión[ og →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← billiónur[ og →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(ein billiarð[ og →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← billiarður[ og →→]),
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
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←← hundrað[ og →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
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
				'aa' => 'afár',
 				'ab' => 'abkasíska',
 				'ace' => 'akkíska',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adýge',
 				'ae' => 'avestíska',
 				'af' => 'afríkanska',
 				'afh' => 'afríhílí',
 				'agq' => 'aghem',
 				'ain' => 'aínu (Japan)',
 				'ak' => 'akan',
 				'akk' => 'akkadíska',
 				'ale' => 'aleúska',
 				'alt' => 'suðuraltaíska',
 				'am' => 'amharíska',
 				'an' => 'aragonska',
 				'ang' => 'fornenska',
 				'ann' => 'obolo',
 				'anp' => 'angíka',
 				'ar' => 'arabíska',
 				'ar_001' => 'stöðluð nútímaarabíska',
 				'arc' => 'arameíska',
 				'arn' => 'mapuche',
 				'arp' => 'arapahó',
 				'ars' => 'najdi-arabíska',
 				'arw' => 'aravakska',
 				'as' => 'assamska',
 				'asa' => 'asu',
 				'ast' => 'astúríska',
 				'atj' => 'atikamekw',
 				'av' => 'avaríska',
 				'awa' => 'avadí',
 				'ay' => 'aímara',
 				'az' => 'aserska',
 				'ba' => 'baskír',
 				'bal' => 'balúkí',
 				'ban' => 'balíska',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'be' => 'hvítrússneska',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'búlgarska',
 				'bgc' => 'haryanví',
 				'bgn' => 'vesturbalotsí',
 				'bho' => 'bojpúrí',
 				'bi' => 'bíslama',
 				'bik' => 'bíkol',
 				'bin' => 'bíní',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengalska',
 				'bo' => 'tíbeska',
 				'br' => 'bretónska',
 				'bra' => 'braí',
 				'brx' => 'bódó',
 				'bs' => 'bosníska',
 				'bss' => 'bakossi',
 				'bua' => 'búríat',
 				'bug' => 'búgíska',
 				'byn' => 'blín',
 				'ca' => 'katalónska',
 				'cad' => 'kaddó',
 				'car' => 'karíbamál',
 				'cay' => 'kajúga',
 				'cch' => 'atsam',
 				'ccp' => 'tsjakma',
 				'ce' => 'tsjetsjenska',
 				'ceb' => 'kebúanó',
 				'cgg' => 'kíga',
 				'ch' => 'kamorró',
 				'chb' => 'síbsja',
 				'chg' => 'sjagataí',
 				'chk' => 'sjúkíska',
 				'chm' => 'marí',
 				'chn' => 'sínúk',
 				'cho' => 'sjoktá',
 				'chp' => 'sípevíska',
 				'chr' => 'Cherokee-mál',
 				'chy' => 'sjeyen',
 				'ckb' => 'miðkúrdíska',
 				'clc' => 'chilcotin',
 				'co' => 'korsíska',
 				'cop' => 'koptíska',
 				'cr' => 'krí',
 				'crg' => 'michif',
 				'crh' => 'krímtyrkneska',
 				'crj' => 'suðaustur-cree',
 				'crk' => 'nehiyawak',
 				'crl' => 'norðaustur-cree',
 				'crm' => 'moose cree',
 				'crr' => 'Karólínu-algonkvínska',
 				'crs' => 'seychelles-kreólska',
 				'cs' => 'tékkneska',
 				'csb' => 'kasúbíska',
 				'csw' => 'maskekon',
 				'cu' => 'kirkjuslavneska',
 				'cv' => 'sjúvas',
 				'cy' => 'velska',
 				'da' => 'danska',
 				'dak' => 'dakóta',
 				'dar' => 'dargva',
 				'dav' => 'taíta',
 				'de' => 'þýska',
 				'de_AT' => 'austurrísk þýska',
 				'de_CH' => 'svissnesk háþýska',
 				'del' => 'delaver',
 				'den' => 'slavneska',
 				'dgr' => 'dogríb',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogrí',
 				'dsb' => 'lágsorbneska',
 				'dua' => 'dúala',
 				'dum' => 'miðhollenska',
 				'dv' => 'dívehí',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'djúla',
 				'dz' => 'dsongka',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efík',
 				'egy' => 'fornegypska',
 				'eka' => 'ekajúk',
 				'el' => 'gríska',
 				'elx' => 'elamít',
 				'en' => 'enska',
 				'en_AU' => 'áströlsk enska',
 				'en_CA' => 'kanadísk enska',
 				'en_GB' => 'bresk enska',
 				'en_GB@alt=short' => 'enska (bresk)',
 				'en_US' => 'bandarísk enska',
 				'en_US@alt=short' => 'enska (BNA)',
 				'enm' => 'miðenska',
 				'eo' => 'esperantó',
 				'es' => 'spænska',
 				'es_419' => 'rómönsk-amerísk spænska',
 				'es_ES' => 'evrópsk spænska',
 				'es_MX' => 'mexíkósk spænska',
 				'et' => 'eistneska',
 				'eu' => 'baskneska',
 				'ewo' => 'evondó',
 				'fa' => 'persneska',
 				'fa_AF' => 'darí',
 				'fan' => 'fang',
 				'fat' => 'fantí',
 				'ff' => 'fúla',
 				'fi' => 'finnska',
 				'fil' => 'filippseyska',
 				'fj' => 'fídjeyska',
 				'fo' => 'færeyska',
 				'fon' => 'fón',
 				'fr' => 'franska',
 				'fr_CA' => 'kanadísk franska',
 				'fr_CH' => 'svissnesk franska',
 				'frc' => 'cajun-franska',
 				'frm' => 'miðfranska',
 				'fro' => 'fornfranska',
 				'frr' => 'norðurfrísneska',
 				'frs' => 'austurfrísneska',
 				'fur' => 'fríúlska',
 				'fy' => 'vesturfrísneska',
 				'ga' => 'írska',
 				'gaa' => 'ga',
 				'gag' => 'gagás',
 				'gan' => 'gan',
 				'gay' => 'gajó',
 				'gba' => 'gbaja',
 				'gd' => 'skosk gelíska',
 				'gez' => 'gís',
 				'gil' => 'gilberska',
 				'gl' => 'galisíska',
 				'gmh' => 'miðháþýska',
 				'gn' => 'gvaraní',
 				'goh' => 'fornháþýska',
 				'gon' => 'gondí',
 				'gor' => 'gorontaló',
 				'got' => 'gotneska',
 				'grb' => 'gerbó',
 				'grc' => 'forngríska',
 				'gsw' => 'svissnesk þýska',
 				'gu' => 'gújaratí',
 				'guz' => 'gusii',
 				'gv' => 'manska',
 				'gwi' => 'gvísín',
 				'ha' => 'hása',
 				'hai' => 'haída',
 				'haw' => 'havaíska',
 				'hax' => 'suður-haída',
 				'he' => 'hebreska',
 				'hi' => 'hindí',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'híligaínon',
 				'hit' => 'hettitíska',
 				'hmn' => 'hmong',
 				'ho' => 'hírímótú',
 				'hr' => 'króatíska',
 				'hsb' => 'hásorbneska',
 				'ht' => 'haítíska',
 				'hu' => 'ungverska',
 				'hup' => 'húpa',
 				'hur' => 'halkomelem',
 				'hy' => 'armenska',
 				'hz' => 'hereró',
 				'ia' => 'interlingua',
 				'iba' => 'íban',
 				'ibb' => 'ibibio',
 				'id' => 'indónesíska',
 				'ie' => 'interlingve',
 				'ig' => 'ígbó',
 				'ii' => 'sísúanjí',
 				'ik' => 'ínúpíak',
 				'ikt' => 'vestur-kanadískt inúktitút',
 				'ilo' => 'ílokó',
 				'inh' => 'ingús',
 				'io' => 'ídó',
 				'is' => 'íslenska',
 				'it' => 'ítalska',
 				'iu' => 'inúktitút',
 				'ja' => 'japanska',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'masjáme',
 				'jpr' => 'gyðingapersneska',
 				'jrb' => 'gyðingaarabíska',
 				'jv' => 'javanska',
 				'ka' => 'georgíska',
 				'kaa' => 'karakalpak',
 				'kab' => 'kabíle',
 				'kac' => 'kasín',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kaví',
 				'kbd' => 'kabardíska',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'grænhöfðeyska',
 				'kfo' => 'koro',
 				'kg' => 'kongóska',
 				'kgp' => 'kaingang',
 				'kha' => 'kasí',
 				'kho' => 'kotaska',
 				'khq' => 'koyra chiini',
 				'ki' => 'kíkújú',
 				'kj' => 'kúanjama',
 				'kk' => 'kasakska',
 				'kkj' => 'kako',
 				'kl' => 'grænlenska',
 				'kln' => 'kalenjin',
 				'km' => 'kmer',
 				'kmb' => 'kimbúndú',
 				'kn' => 'kannada',
 				'ko' => 'kóreska',
 				'koi' => 'kómí-permyak',
 				'kok' => 'konkaní',
 				'kos' => 'kosraska',
 				'kpe' => 'kpelle',
 				'kr' => 'kanúrí',
 				'krc' => 'karasaíbalkar',
 				'krl' => 'karélska',
 				'kru' => 'kúrúk',
 				'ks' => 'kasmírska',
 				'ksb' => 'sjambala',
 				'ksf' => 'bafía',
 				'ksh' => 'kölníska',
 				'ku' => 'kúrdíska',
 				'kum' => 'kúmík',
 				'kut' => 'kútenaí',
 				'kv' => 'komíska',
 				'kw' => 'kornbreska',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'kirgiska',
 				'la' => 'latína',
 				'lad' => 'ladínska',
 				'lag' => 'langí',
 				'lah' => 'landa',
 				'lam' => 'lamba',
 				'lb' => 'lúxemborgíska',
 				'lez' => 'lesgíska',
 				'lg' => 'ganda',
 				'li' => 'limbúrgíska',
 				'lil' => 'lillooet',
 				'lkt' => 'lakóta',
 				'ln' => 'lingala',
 				'lo' => 'laó',
 				'lol' => 'mongó',
 				'lou' => 'kreólska (Louisiana)',
 				'loz' => 'lozi',
 				'lrc' => 'norðurlúrí',
 				'lsm' => 'saamia',
 				'lt' => 'litháíska',
 				'lu' => 'lúbakatanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'lúisenó',
 				'lun' => 'lúnda',
 				'luo' => 'lúó',
 				'lus' => 'lúsaí',
 				'luy' => 'luyia',
 				'lv' => 'lettneska',
 				'mad' => 'madúrska',
 				'mag' => 'magahí',
 				'mai' => 'maítílí',
 				'mak' => 'makasar',
 				'man' => 'mandingó',
 				'mas' => 'masaí',
 				'mdf' => 'moksa',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'merú',
 				'mfe' => 'máritíska',
 				'mg' => 'malagasíska',
 				'mga' => 'miðírska',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallska',
 				'mi' => 'maorí',
 				'mic' => 'mikmak',
 				'min' => 'mínangkabá',
 				'mk' => 'makedónska',
 				'ml' => 'malajalam',
 				'mn' => 'mongólska',
 				'mnc' => 'mansjú',
 				'mni' => 'manípúrí',
 				'moe' => 'innu-aimun',
 				'moh' => 'móhíska',
 				'mos' => 'mossí',
 				'mr' => 'maratí',
 				'ms' => 'malaíska',
 				'mt' => 'maltneska',
 				'mua' => 'mundang',
 				'mul' => 'mörg tungumál',
 				'mus' => 'krík',
 				'mwl' => 'mirandesíska',
 				'mwr' => 'marvarí',
 				'my' => 'búrmneska',
 				'myv' => 'ersja',
 				'mzn' => 'masanderaní',
 				'na' => 'nárúska',
 				'nap' => 'napólíska',
 				'naq' => 'nama',
 				'nb' => 'norskt bókmál',
 				'nd' => 'norður-ndebele',
 				'nds' => 'lágþýska; lágsaxneska',
 				'nds_NL' => 'lágsaxneska',
 				'ne' => 'nepalska',
 				'new' => 'nevarí',
 				'ng' => 'ndonga',
 				'nia' => 'nías',
 				'niu' => 'níveska',
 				'nl' => 'hollenska',
 				'nl_BE' => 'flæmska',
 				'nmg' => 'kwasio',
 				'nn' => 'nýnorska',
 				'nnh' => 'ngiemboon',
 				'no' => 'norska',
 				'nog' => 'nógaí',
 				'non' => 'norræna',
 				'nqo' => 'n’ko',
 				'nr' => 'suðurndebele',
 				'nso' => 'norðursótó',
 				'nus' => 'núer',
 				'nv' => 'navahó',
 				'nwc' => 'klassísk nevaríska',
 				'ny' => 'nýanja',
 				'nym' => 'njamvesí',
 				'nyn' => 'nyankole',
 				'nyo' => 'njóró',
 				'nzi' => 'nsíma',
 				'oc' => 'oksítaníska',
 				'oj' => 'ojibva',
 				'ojb' => 'norðvestur-ojibwa',
 				'ojc' => 'ojibwa',
 				'ojs' => 'oji-cree',
 				'ojw' => 'vestur-ojibwa',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'óría',
 				'os' => 'ossetíska',
 				'osa' => 'ósage',
 				'ota' => 'tyrkneska, ottóman',
 				'pa' => 'púnjabí',
 				'pag' => 'pangasínmál',
 				'pal' => 'palaví',
 				'pam' => 'pampanga',
 				'pap' => 'papíamentó',
 				'pau' => 'paláska',
 				'pcm' => 'nígerískt pidgin',
 				'peo' => 'fornpersneska',
 				'phn' => 'fönikíska',
 				'pi' => 'palí',
 				'pis' => 'pijin',
 				'pl' => 'pólska',
 				'pon' => 'ponpeiska',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'prússneska',
 				'pro' => 'fornpróvensalska',
 				'ps' => 'pastú',
 				'pt' => 'portúgalska',
 				'pt_BR' => 'brasílísk portúgalska',
 				'pt_PT' => 'evrópsk portúgalska',
 				'qu' => 'kvesjúa',
 				'quc' => 'kiche',
 				'raj' => 'rajastaní',
 				'rap' => 'rapanúí',
 				'rar' => 'rarótongska',
 				'rhg' => 'rohingja',
 				'rm' => 'rómanska',
 				'rn' => 'rúndí',
 				'ro' => 'rúmenska',
 				'ro_MD' => 'moldóvska',
 				'rof' => 'rombó',
 				'rom' => 'romaní',
 				'ru' => 'rússneska',
 				'rup' => 'arúmenska',
 				'rw' => 'kínjarvanda',
 				'rwk' => 'rúa',
 				'sa' => 'sanskrít',
 				'sad' => 'sandave',
 				'sah' => 'jakút',
 				'sam' => 'samversk arameíska',
 				'saq' => 'sambúrú',
 				'sas' => 'sasak',
 				'sat' => 'santalí',
 				'sba' => 'ngambay',
 				'sbp' => 'sangú',
 				'sc' => 'sardínska',
 				'scn' => 'sikileyska',
 				'sco' => 'skoska',
 				'sd' => 'sindí',
 				'sdh' => 'suðurkúrdíska',
 				'se' => 'norðursamíska',
 				'seh' => 'sena',
 				'sel' => 'selkúp',
 				'ses' => 'koíraboró-senní',
 				'sg' => 'sangó',
 				'sga' => 'fornírska',
 				'sh' => 'serbókróatíska',
 				'shi' => 'tachelhit',
 				'shn' => 'sjan',
 				'si' => 'singalíska',
 				'sid' => 'sídamó',
 				'sk' => 'slóvakíska',
 				'sl' => 'slóvenska',
 				'slh' => 'suður-lushootseed',
 				'sm' => 'samóska',
 				'sma' => 'suðursamíska',
 				'smj' => 'lúlesamíska',
 				'smn' => 'enaresamíska',
 				'sms' => 'skoltesamíska',
 				'sn' => 'shona',
 				'snk' => 'sóninke',
 				'so' => 'sómalska',
 				'sog' => 'sogdíen',
 				'sq' => 'albanska',
 				'sr' => 'serbneska',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'svatí',
 				'ssy' => 'saho',
 				'st' => 'suðursótó',
 				'str' => 'Straits-salisíanska',
 				'su' => 'súndanska',
 				'suk' => 'súkúma',
 				'sus' => 'súsú',
 				'sux' => 'súmerska',
 				'sv' => 'sænska',
 				'sw' => 'svahílí',
 				'sw_CD' => 'kongósvahílí',
 				'swb' => 'shimaoríska',
 				'syc' => 'klassísk sýrlenska',
 				'syr' => 'sýrlenska',
 				'ta' => 'tamílska',
 				'tce' => 'suður-tutchone',
 				'te' => 'telúgú',
 				'tem' => 'tímne',
 				'teo' => 'tesó',
 				'ter' => 'terenó',
 				'tet' => 'tetúm',
 				'tg' => 'tadsjikska',
 				'tgx' => 'tagíska',
 				'th' => 'taílenska',
 				'tht' => 'tahltan',
 				'ti' => 'tígrinja',
 				'tig' => 'tígre',
 				'tiv' => 'tív',
 				'tk' => 'túrkmenska',
 				'tkl' => 'tókeláska',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonska',
 				'tli' => 'tlingit',
 				'tmh' => 'tamasjek',
 				'tn' => 'tsúana',
 				'to' => 'tongverska',
 				'tog' => 'tongverska (nyasa)',
 				'tok' => 'toki pona',
 				'tpi' => 'tokpisin',
 				'tr' => 'tyrkneska',
 				'trv' => 'tarókó',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimsíska',
 				'tt' => 'tatarska',
 				'ttm' => 'norður-tutchone',
 				'tum' => 'túmbúka',
 				'tvl' => 'túvalúska',
 				'tw' => 'tví',
 				'twq' => 'tasawaq',
 				'ty' => 'tahítíska',
 				'tyv' => 'túvínska',
 				'tzm' => 'tamazight',
 				'udm' => 'údmúrt',
 				'ug' => 'úígúr',
 				'uga' => 'úgarítíska',
 				'uk' => 'úkraínska',
 				'umb' => 'úmbúndú',
 				'und' => 'óþekkt tungumál',
 				'ur' => 'úrdú',
 				'uz' => 'úsbekska',
 				'vai' => 'vaí',
 				've' => 'venda',
 				'vi' => 'víetnamska',
 				'vo' => 'volapyk',
 				'vot' => 'votíska',
 				'vun' => 'vunjó',
 				'wa' => 'vallónska',
 				'wae' => 'valser',
 				'wal' => 'volayatta',
 				'war' => 'varaí',
 				'was' => 'vasjó',
 				'wbp' => 'varlpiri',
 				'wo' => 'volof',
 				'wuu' => 'wu-kínverska',
 				'xal' => 'kalmúkska',
 				'xh' => 'sósa',
 				'xog' => 'sóga',
 				'yao' => 'jaó',
 				'yap' => 'japíska',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddíska',
 				'yo' => 'jórúba',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantónska',
 				'yue@alt=menu' => 'kínverska, kantónska',
 				'za' => 'súang',
 				'zap' => 'sapótek',
 				'zbl' => 'blisstákn',
 				'zen' => 'senaga',
 				'zgh' => 'staðlað marokkóskt tamazight',
 				'zh' => 'kínverska',
 				'zh@alt=menu' => 'kínverska, mandarín',
 				'zh_Hans' => 'kínverska (einfölduð)',
 				'zh_Hans@alt=long' => 'mandarín (einfölduð)',
 				'zh_Hant' => 'kínverska (hefðbundin)',
 				'zh_Hant@alt=long' => 'mandarín (hefðbundin)',
 				'zu' => 'súlú',
 				'zun' => 'súní',
 				'zxx' => 'ekkert tungumálaefni',
 				'zza' => 'zázáíska',

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
			'Adlm' => 'adlam',
 			'Arab' => 'arabískt',
 			'Arab@alt=variant' => 'persneskt-arabískt',
 			'Aran' => 'nastaliq',
 			'Armi' => 'impéríska araméíska',
 			'Armn' => 'armenskt',
 			'Avst' => 'avestíska',
 			'Bali' => 'balinesíska',
 			'Bamu' => 'bamun',
 			'Batk' => 'batakíska',
 			'Beng' => 'bengalskt',
 			'Blis' => 'blisstégn',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmíska',
 			'Brai' => 'blindraletur',
 			'Bugi' => 'buginesíska',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'samræmt kanadískt samstöfuletur frumbyggja',
 			'Cari' => 'karíska',
 			'Cham' => 'chamíska',
 			'Cher' => 'cherokí',
 			'Cirt' => 'círth',
 			'Copt' => 'koptíska',
 			'Cprt' => 'kypriotíska',
 			'Cyrl' => 'kyrillískt',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Ethi' => 'eþíópískt',
 			'Geok' => 'georgíska (khutsuri)',
 			'Geor' => 'georgískt',
 			'Grek' => 'grískt',
 			'Gujr' => 'gújaratí',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'kínverskt',
 			'Hans' => 'einfaldað',
 			'Hans@alt=stand-alone' => 'einfaldað han',
 			'Hant' => 'hefðbundið',
 			'Hant@alt=stand-alone' => 'hefðbundið han',
 			'Hebr' => 'hebreskt',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japönsk samstöfuletur',
 			'Jamo' => 'jamo',
 			'Java' => 'javanesíska',
 			'Jpan' => 'japanskt',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khmr' => 'kmer',
 			'Knda' => 'kannada',
 			'Kore' => 'kóreskt',
 			'Kthi' => 'kaithíska',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'frakturlatnéska',
 			'Latg' => 'gaeliklatnéska',
 			'Latn' => 'latneskt',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lisu' => 'Fraser',
 			'Lyci' => 'lykíska',
 			'Lydi' => 'lydíska',
 			'Mand' => 'mandaíska',
 			'Mani' => 'manikeíska',
 			'Mero' => 'meroitíska',
 			'Mlym' => 'malalajam',
 			'Mong' => 'mongólskt',
 			'Moon' => 'moon',
 			'Mtei' => 'meitei mayek',
 			'Mymr' => 'mjanmarskt',
 			'Nkoo' => 'n-kó',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Plrd' => 'Pollard',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'rúntégn',
 			'Samr' => 'samaríska',
 			'Sara' => 'saratí',
 			'Saur' => 'saurashtra',
 			'Shaw' => 'shavíska',
 			'Sinh' => 'sinhala',
 			'Sund' => 'sundanesíska',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syriakíska',
 			'Tale' => 'tai le',
 			'Taml' => 'tamílskt',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telúgú',
 			'Teng' => 'tengvar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'taílenskt',
 			'Tibt' => 'tíbeskt',
 			'Ugar' => 'ugaritíska',
 			'Vaii' => 'vai',
 			'Yiii' => 'yí',
 			'Zinh' => '(erfðir)',
 			'Zmth' => 'stærðfræðitákn',
 			'Zsye' => 'emoji-tákn',
 			'Zsym' => 'tákn',
 			'Zxxx' => 'óskrifað',
 			'Zyyy' => 'almennt',
 			'Zzzz' => 'óþekkt letur',

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
			'001' => 'Heimurinn',
 			'002' => 'Afríka',
 			'003' => 'Norður-Ameríka',
 			'005' => 'Suður-Ameríka',
 			'009' => 'Eyjaálfa',
 			'011' => 'Vestur-Afríka',
 			'013' => 'Mið-Ameríka',
 			'014' => 'Austur-Afríka',
 			'015' => 'Norður-Afríka',
 			'017' => 'Mið-Afríka',
 			'018' => 'Suðurhluti Afríku',
 			'019' => 'Ameríka',
 			'021' => 'Ameríka norðan Mexíkó',
 			'029' => 'Karíbahafið',
 			'030' => 'Austur-Asía',
 			'034' => 'Suður-Asía',
 			'035' => 'Suðaustur-Asía',
 			'039' => 'Suður-Evrópa',
 			'053' => 'Ástralasía',
 			'054' => 'Melanesía',
 			'057' => 'Míkrónesíusvæðið',
 			'061' => 'Pólýnesía',
 			'142' => 'Asía',
 			'143' => 'Mið-Asía',
 			'145' => 'Vestur-Asía',
 			'150' => 'Evrópa',
 			'151' => 'Austur-Evrópa',
 			'154' => 'Norður-Evrópa',
 			'155' => 'Vestur-Evrópa',
 			'202' => 'Afríka sunnan Sahara',
 			'419' => 'Rómanska Ameríka',
 			'AC' => 'Ascension-eyja',
 			'AD' => 'Andorra',
 			'AE' => 'Sameinuðu arabísku furstadæmin',
 			'AF' => 'Afganistan',
 			'AG' => 'Antígva og Barbúda',
 			'AI' => 'Angvilla',
 			'AL' => 'Albanía',
 			'AM' => 'Armenía',
 			'AO' => 'Angóla',
 			'AQ' => 'Suðurskautslandið',
 			'AR' => 'Argentína',
 			'AS' => 'Bandaríska Samóa',
 			'AT' => 'Austurríki',
 			'AU' => 'Ástralía',
 			'AW' => 'Arúba',
 			'AX' => 'Álandseyjar',
 			'AZ' => 'Aserbaídsjan',
 			'BA' => 'Bosnía og Hersegóvína',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladess',
 			'BE' => 'Belgía',
 			'BF' => 'Búrkína Fasó',
 			'BG' => 'Búlgaría',
 			'BH' => 'Barein',
 			'BI' => 'Búrúndí',
 			'BJ' => 'Benín',
 			'BL' => 'Sankti Bartólómeusareyjar',
 			'BM' => 'Bermúdaeyjar',
 			'BN' => 'Brúnei',
 			'BO' => 'Bólivía',
 			'BQ' => 'Karíbahafshluti Hollands',
 			'BR' => 'Brasilía',
 			'BS' => 'Bahamaeyjar',
 			'BT' => 'Bútan',
 			'BV' => 'Bouveteyja',
 			'BW' => 'Botsvana',
 			'BY' => 'Hvíta-Rússland',
 			'BZ' => 'Belís',
 			'CA' => 'Kanada',
 			'CC' => 'Kókoseyjar (Keeling)',
 			'CD' => 'Kongó-Kinshasa',
 			'CD@alt=variant' => 'Kongó (Lýðstjórnarlýðveldið)',
 			'CF' => 'Mið-Afríkulýðveldið',
 			'CG' => 'Kongó-Brazzaville',
 			'CG@alt=variant' => 'Kongó (Lýðveldið)',
 			'CH' => 'Sviss',
 			'CI' => 'Fílabeinsströndin',
 			'CK' => 'Cooks-eyjar',
 			'CL' => 'Síle',
 			'CM' => 'Kamerún',
 			'CN' => 'Kína',
 			'CO' => 'Kólumbía',
 			'CP' => 'Clipperton-eyja',
 			'CR' => 'Kostaríka',
 			'CU' => 'Kúba',
 			'CV' => 'Grænhöfðaeyjar',
 			'CW' => 'Curacao',
 			'CX' => 'Jólaey',
 			'CY' => 'Kýpur',
 			'CZ' => 'Tékkland',
 			'DE' => 'Þýskaland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djíbútí',
 			'DK' => 'Danmörk',
 			'DM' => 'Dóminíka',
 			'DO' => 'Dóminíska lýðveldið',
 			'DZ' => 'Alsír',
 			'EA' => 'Ceuta og Melilla',
 			'EC' => 'Ekvador',
 			'EE' => 'Eistland',
 			'EG' => 'Egyptaland',
 			'EH' => 'Vestur-Sahara',
 			'ER' => 'Erítrea',
 			'ES' => 'Spánn',
 			'ET' => 'Eþíópía',
 			'EU' => 'Evrópusambandið',
 			'EZ' => 'Evrusvæðið',
 			'FI' => 'Finnland',
 			'FJ' => 'Fídjíeyjar',
 			'FK' => 'Falklandseyjar',
 			'FK@alt=variant' => 'Falklandseyjar (Malvinas)',
 			'FM' => 'Míkrónesía',
 			'FO' => 'Færeyjar',
 			'FR' => 'Frakkland',
 			'GA' => 'Gabon',
 			'GB' => 'Bretland',
 			'GD' => 'Grenada',
 			'GE' => 'Georgía',
 			'GF' => 'Franska Gvæjana',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gíbraltar',
 			'GL' => 'Grænland',
 			'GM' => 'Gambía',
 			'GN' => 'Gínea',
 			'GP' => 'Gvadelúpeyjar',
 			'GQ' => 'Miðbaugs-Gínea',
 			'GR' => 'Grikkland',
 			'GS' => 'Suður-Georgía og Suður-Sandvíkureyjar',
 			'GT' => 'Gvatemala',
 			'GU' => 'Gvam',
 			'GW' => 'Gínea-Bissá',
 			'GY' => 'Gvæjana',
 			'HK' => 'sérstjórnarsvæðið Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard og McDonaldseyjar',
 			'HN' => 'Hondúras',
 			'HR' => 'Króatía',
 			'HT' => 'Haítí',
 			'HU' => 'Ungverjaland',
 			'IC' => 'Kanaríeyjar',
 			'ID' => 'Indónesía',
 			'IE' => 'Írland',
 			'IL' => 'Ísrael',
 			'IM' => 'Mön',
 			'IN' => 'Indland',
 			'IO' => 'Bresku Indlandshafseyjar',
 			'IO@alt=chagos' => 'Chagos-eyjaklasinn',
 			'IQ' => 'Írak',
 			'IR' => 'Íran',
 			'IS' => 'Ísland',
 			'IT' => 'Ítalía',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaíka',
 			'JO' => 'Jórdanía',
 			'JP' => 'Japan',
 			'KE' => 'Kenía',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kambódía',
 			'KI' => 'Kíribatí',
 			'KM' => 'Kómoreyjar',
 			'KN' => 'Sankti Kitts og Nevis',
 			'KP' => 'Norður-Kórea',
 			'KR' => 'Suður-Kórea',
 			'KW' => 'Kúveit',
 			'KY' => 'Caymaneyjar',
 			'KZ' => 'Kasakstan',
 			'LA' => 'Laos',
 			'LB' => 'Líbanon',
 			'LC' => 'Sankti Lúsía',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Srí Lanka',
 			'LR' => 'Líbería',
 			'LS' => 'Lesótó',
 			'LT' => 'Litháen',
 			'LU' => 'Lúxemborg',
 			'LV' => 'Lettland',
 			'LY' => 'Líbía',
 			'MA' => 'Marokkó',
 			'MC' => 'Mónakó',
 			'MD' => 'Moldóva',
 			'ME' => 'Svartfjallaland',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalleyjar',
 			'MK' => 'Norður-Makedónía',
 			'ML' => 'Malí',
 			'MM' => 'Mjanmar (Búrma)',
 			'MN' => 'Mongólía',
 			'MO' => 'sérstjórnarsvæðið Makaó',
 			'MO@alt=short' => 'Makaó',
 			'MP' => 'Norður-Maríanaeyjar',
 			'MQ' => 'Martiník',
 			'MR' => 'Máritanía',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Máritíus',
 			'MV' => 'Maldíveyjar',
 			'MW' => 'Malaví',
 			'MX' => 'Mexíkó',
 			'MY' => 'Malasía',
 			'MZ' => 'Mósambík',
 			'NA' => 'Namibía',
 			'NC' => 'Nýja-Kaledónía',
 			'NE' => 'Níger',
 			'NF' => 'Norfolkeyja',
 			'NG' => 'Nígería',
 			'NI' => 'Níkaragva',
 			'NL' => 'Holland',
 			'NO' => 'Noregur',
 			'NP' => 'Nepal',
 			'NR' => 'Nárú',
 			'NU' => 'Niue',
 			'NZ' => 'Nýja-Sjáland',
 			'NZ@alt=variant' => 'Aotearoa, Nýja-Sjáland',
 			'OM' => 'Óman',
 			'PA' => 'Panama',
 			'PE' => 'Perú',
 			'PF' => 'Franska Pólýnesía',
 			'PG' => 'Papúa Nýja-Gínea',
 			'PH' => 'Filippseyjar',
 			'PK' => 'Pakistan',
 			'PL' => 'Pólland',
 			'PM' => 'Sankti Pierre og Miquelon',
 			'PN' => 'Pitcairn-eyjar',
 			'PR' => 'Púertó Ríkó',
 			'PS' => 'Heimastjórnarsvæði Palestínumanna',
 			'PS@alt=short' => 'Palestína',
 			'PT' => 'Portúgal',
 			'PW' => 'Palá',
 			'PY' => 'Paragvæ',
 			'QA' => 'Katar',
 			'QO' => 'Ytri Eyjaálfa',
 			'RE' => 'Réunion',
 			'RO' => 'Rúmenía',
 			'RS' => 'Serbía',
 			'RU' => 'Rússland',
 			'RW' => 'Rúanda',
 			'SA' => 'Sádi-Arabía',
 			'SB' => 'Salómonseyjar',
 			'SC' => 'Seychelles-eyjar',
 			'SD' => 'Súdan',
 			'SE' => 'Svíþjóð',
 			'SG' => 'Singapúr',
 			'SH' => 'Sankti Helena',
 			'SI' => 'Slóvenía',
 			'SJ' => 'Svalbarði og Jan Mayen',
 			'SK' => 'Slóvakía',
 			'SL' => 'Síerra Leóne',
 			'SM' => 'San Marínó',
 			'SN' => 'Senegal',
 			'SO' => 'Sómalía',
 			'SR' => 'Súrínam',
 			'SS' => 'Suður-Súdan',
 			'ST' => 'Saó Tóme og Prinsípe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sýrland',
 			'SZ' => 'Svasíland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicoseyjar',
 			'TD' => 'Tsjad',
 			'TF' => 'Frönsku suðlægu landsvæðin',
 			'TG' => 'Tógó',
 			'TH' => 'Taíland',
 			'TJ' => 'Tadsíkistan',
 			'TK' => 'Tókelá',
 			'TL' => 'Tímor-Leste',
 			'TL@alt=variant' => 'Austur-Tímor',
 			'TM' => 'Túrkmenistan',
 			'TN' => 'Túnis',
 			'TO' => 'Tonga',
 			'TR' => 'Tyrkland',
 			'TT' => 'Trínidad og Tóbagó',
 			'TV' => 'Túvalú',
 			'TW' => 'Taívan',
 			'TZ' => 'Tansanía',
 			'UA' => 'Úkraína',
 			'UG' => 'Úganda',
 			'UM' => 'Smáeyjar Bandaríkjanna',
 			'UN' => 'Sameinuðu þjóðirnar',
 			'UN@alt=short' => 'SÞ',
 			'US' => 'Bandaríkin',
 			'US@alt=short' => 'BNA',
 			'UY' => 'Úrúgvæ',
 			'UZ' => 'Úsbekistan',
 			'VA' => 'Vatíkanið',
 			'VC' => 'Sankti Vinsent og Grenadíneyjar',
 			'VE' => 'Venesúela',
 			'VG' => 'Bresku Jómfrúaeyjar',
 			'VI' => 'Bandarísku Jómfrúaeyjar',
 			'VN' => 'Víetnam',
 			'VU' => 'Vanúatú',
 			'WF' => 'Wallis- og Fútúnaeyjar',
 			'WS' => 'Samóa',
 			'XA' => 'gervihreimur',
 			'XB' => 'gervistaður',
 			'XK' => 'Kósóvó',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Suður-Afríka',
 			'ZM' => 'Sambía',
 			'ZW' => 'Simbabve',
 			'ZZ' => 'Óþekkt svæði',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'MONOTON' => 'monotonísk',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonísk',
 			'WADEGILE' => 'Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Tímatal',
 			'cf' => 'Gjaldmiðilssnið',
 			'colalternate' => 'Röðun óháð táknum',
 			'colbackwards' => 'Röðun með viðsnúnum áherslum',
 			'colcasefirst' => 'Röðun eftir hástöfum/lágstöfum',
 			'colcaselevel' => 'Stafrétt röðun',
 			'collation' => 'Röðun',
 			'colnormalization' => 'Stöðluð röðun',
 			'colnumeric' => 'Talnaröðun',
 			'colstrength' => 'Röðunarstyrkur',
 			'currency' => 'Gjaldmiðill',
 			'hc' => 'Tímakerfi (12 eða 24)',
 			'lb' => 'Línuskipting',
 			'ms' => 'Mælingakerfi',
 			'numbers' => 'Tölur',
 			'timezone' => 'Tímabelti',
 			'va' => 'Landsstaðalsafbrigði',
 			'x' => 'Einkanotkun',

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
 				'buddhist' => q{Búddískt tímatal},
 				'chinese' => q{Kínversk tímatal},
 				'coptic' => q{Koptískt tímatal},
 				'dangi' => q{Dangi tímatal},
 				'ethiopic' => q{Eþíópískt tímatal},
 				'ethiopic-amete-alem' => q{Eþíópískt ‘amete alem’ tímatal},
 				'gregorian' => q{Gregorískt tímatal},
 				'hebrew' => q{Hebreskt tímatal},
 				'indian' => q{indverskt dagatal},
 				'islamic' => q{Íslamskt tímatal},
 				'islamic-civil' => q{Íslamskt borgaradagatal},
 				'islamic-umalqura' => q{Íslamskt dagatal (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 tímatal},
 				'japanese' => q{Japanskt tímatal},
 				'persian' => q{Persneskt tímatal},
 				'roc' => q{Minguo tímatal},
 			},
 			'cf' => {
 				'account' => q{Bókhaldsgjaldmiðill},
 				'standard' => q{Staðlað gjaldmiðilssnið},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Raða táknum},
 				'shifted' => q{Raða óháð táknum},
 			},
 			'colbackwards' => {
 				'no' => q{Raða áherslum eðlilega},
 				'yes' => q{Raða öfugt eftir áherslum},
 			},
 			'colcasefirst' => {
 				'lower' => q{Raða lágstöfum fyrst},
 				'no' => q{Raða eðlilega eftir hástöfum og lágstöfum},
 				'upper' => q{Raða hástöfum fyrst},
 			},
 			'colcaselevel' => {
 				'no' => q{Raða óháð hástöfum og lágstöfum},
 				'yes' => q{Raða stafrétt},
 			},
 			'collation' => {
 				'big5han' => q{hefðbundin kínversk röðun - Big5},
 				'compat' => q{Fyrri röðun, til samræmis},
 				'dictionary' => q{Orðabókarröð},
 				'ducet' => q{Sjálfgefin Unicode-röðun},
 				'eor' => q{Evrópskar reglur um röðun},
 				'gb2312han' => q{einfölduð kínversk röðun - GB2312},
 				'phonebook' => q{Símaskráarröðun},
 				'phonetic' => q{Hljóðfræðileg röð},
 				'pinyin' => q{Pinyin-röðun},
 				'reformed' => q{Endurbætt röð},
 				'search' => q{Almenn leit},
 				'searchjl' => q{Leita eftir upphafssamhljóða í Hangul},
 				'standard' => q{Stöðluð röðun},
 				'stroke' => q{Strikaröðun},
 				'traditional' => q{Hefðbundin},
 				'unihan' => q{Röðun eftir grunnstrikum},
 			},
 			'colnormalization' => {
 				'no' => q{Raða án stöðlunar},
 				'yes' => q{Raða Unicode með stöðluðum hætti},
 			},
 			'colnumeric' => {
 				'no' => q{Raða tölustöfum sér},
 				'yes' => q{Raða tölustöfum tölulega},
 			},
 			'colstrength' => {
 				'identical' => q{Raða öllu},
 				'primary' => q{Raða aðeins grunnstöfum},
 				'quaternary' => q{Raða áherslum/hástaf eða lágstaf/breidd/Kana},
 				'secondary' => q{Raða áherslum},
 				'tertiary' => q{Raða áherslum/hástaf eða lágstaf/breidd},
 			},
 			'd0' => {
 				'fwidth' => q{Full breidd},
 				'hwidth' => q{Hálfbreidd},
 				'npinyin' => q{Tölulegur},
 			},
 			'hc' => {
 				'h11' => q{12 tíma kerfi (0–11)},
 				'h12' => q{12 tíma kerfi (1–12)},
 				'h23' => q{24 tíma kerfi (0–23)},
 				'h24' => q{24 tíma kerfi (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Laus línuskipting},
 				'normal' => q{Venjuleg línuskipting},
 				'strict' => q{Ströng línuskipting},
 			},
 			'm0' => {
 				'bgn' => q{US BGN umritun},
 				'ungegn' => q{UN GEGN umritun},
 			},
 			'ms' => {
 				'metric' => q{Metrakerfi},
 				'uksystem' => q{Breskt mælingakerfi},
 				'ussystem' => q{Bandarískt mælingakerfi},
 			},
 			'numbers' => {
 				'ahom' => q{ahom-tölur},
 				'arab' => q{Arabískar-indverskar tölur},
 				'arabext' => q{Auknar arabískar-indverskar tölur},
 				'armn' => q{Armenskir tölustafir},
 				'armnlow' => q{Armenskar lágstafatölur},
 				'beng' => q{Bengalskar tölur},
 				'cakm' => q{Chakma-tölur},
 				'deva' => q{Devanagari tölur},
 				'ethi' => q{Eþíópískir tölustafir},
 				'finance' => q{Viðskiptafræðileg töluorð},
 				'fullwide' => q{Tölur í fullri breidd},
 				'geor' => q{Georgískir tölustafir},
 				'grek' => q{Grískir tölustafir},
 				'greklow' => q{Grískar lágstafatölur},
 				'gujr' => q{Gujarati-tölur},
 				'guru' => q{Gurmukhi-tölur},
 				'hanidec' => q{Kínverskir tugatölustafir},
 				'hans' => q{Einfaldaðir kínverskir tölustafir},
 				'hansfin' => q{Einfaldaðar kínverskar fjármálatölur},
 				'hant' => q{Hefðbundnir kínverskir tölustafir},
 				'hantfin' => q{Hefðbundnar kínverskar fjármálatölur},
 				'hebr' => q{Hebreskir tölustafir},
 				'java' => q{Javanskar tölur},
 				'jpan' => q{Japanskir tölustafir},
 				'jpanfin' => q{Japanskar fjármálatölur},
 				'khmr' => q{Kmerískar tölur},
 				'knda' => q{Kannada-tölur},
 				'laoo' => q{Lao-tölur},
 				'latn' => q{Vestrænar tölur},
 				'mlym' => q{Malayalam-tölur},
 				'mong' => q{Mongólskar tölur},
 				'mtei' => q{Meetei mayek-tölur},
 				'mymr' => q{Mjanmarskar tölur},
 				'native' => q{Upprunalegir tölustafir},
 				'olck' => q{Ol chiki-tölur},
 				'orya' => q{Odia-tölur},
 				'roman' => q{Rómverskir tölustafir},
 				'romanlow' => q{Rómverskar lágstafatölur},
 				'taml' => q{Hefðbundnir tamílskir tölustafir},
 				'tamldec' => q{Tamílskar tölur},
 				'telu' => q{Telúgú-tölur},
 				'thai' => q{Tælenskar tölur},
 				'tibt' => q{Tíbeskir tölustafir},
 				'traditional' => q{Hefðbundin tölutákn},
 				'vaii' => q{Vai-tölustafir},
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
			'metric' => q{metrakerfi},
 			'UK' => q{breskt},
 			'US' => q{bandarískt},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'tungumál: {0}',
 			'script' => 'leturgerð: {0}',
 			'region' => 'svæði: {0}',

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
			auxiliary => qr{[c q w z]},
			index => ['A', 'Á', 'B', 'C', 'D', 'Ð', 'E', 'É', 'F', 'G', 'H', 'I', 'Í', 'J', 'K', 'L', 'M', 'N', 'O', 'Ó', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ú', 'V', 'W', 'X', 'Y', 'Ý', 'Z', 'Þ', 'Æ', 'Ö'],
			main => qr{[a á b d ð e é f g h i í j k l m n o ó p r s t u ú v x y ý þ æ ö]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Á', 'B', 'C', 'D', 'Ð', 'E', 'É', 'F', 'G', 'H', 'I', 'Í', 'J', 'K', 'L', 'M', 'N', 'O', 'Ó', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ú', 'V', 'W', 'X', 'Y', 'Ý', 'Z', 'Þ', 'Æ', 'Ö'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‚},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(höfuðátt),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(höfuðátt),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kíbí{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kíbí{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebí{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebí{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gíbí{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gíbí{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebí{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebí{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebí{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebí{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbí{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbí{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(sebí{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(sebí{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(jóbe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(jóbe{0}),
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
						'1' => q(píkó{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(píkó{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femtó{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femtó{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(attó{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(attó{0}),
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
						'1' => q(septó{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(septó{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(jóktó{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(jóktó{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(kvektó{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kvektó{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(míkró{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(míkró{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nanó{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nanó{0}),
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
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hektó{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hektó{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(setta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(setta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(jótta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(jótta{0}),
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
					'10p30' => {
						'1' => q(kvetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kvetta{0}),
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
						'1' => q(gíga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(gíga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'1' => q(feminine),
						'name' => q(þyngdarhröðun),
						'one' => q({0} þyngdarhröðun),
						'other' => q({0} þyngdarhröðun),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'name' => q(þyngdarhröðun),
						'one' => q({0} þyngdarhröðun),
						'other' => q({0} þyngdarhröðun),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metrar á sekúndu, á sekúndu),
						'one' => q({0} metri á sekúndu, á sekúndu),
						'other' => q({0} metrar á sekúndu, á sekúndu),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metrar á sekúndu, á sekúndu),
						'one' => q({0} metri á sekúndu, á sekúndu),
						'other' => q({0} metrar á sekúndu, á sekúndu),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'name' => q(bogamínútur),
						'one' => q({0} bogamínúta),
						'other' => q({0} bogamínútur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'name' => q(bogamínútur),
						'one' => q({0} bogamínúta),
						'other' => q({0} bogamínútur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'name' => q(bogasekúndur),
						'one' => q({0} bogasekúnda),
						'other' => q({0} bogasekúndur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'name' => q(bogasekúndur),
						'one' => q({0} bogasekúnda),
						'other' => q({0} bogasekúndur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(feminine),
						'one' => q({0} gráða),
						'other' => q({0} gráður),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(feminine),
						'one' => q({0} gráða),
						'other' => q({0} gráður),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'name' => q(radíanar),
						'one' => q({0} radían),
						'other' => q({0} radíanar),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'name' => q(radíanar),
						'one' => q({0} radían),
						'other' => q({0} radíanar),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(masculine),
						'name' => q(snúningur),
						'one' => q({0} snúningur),
						'other' => q({0} snúningar),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(masculine),
						'name' => q(snúningur),
						'one' => q({0} snúningur),
						'other' => q({0} snúningar),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0} dúnam),
						'other' => q({0} dúnöm),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0} dúnam),
						'other' => q({0} dúnöm),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'one' => q({0} hektari),
						'other' => q({0} hektarar),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'one' => q({0} hektari),
						'other' => q({0} hektarar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(fersentimetrar),
						'one' => q({0} fersentimetri),
						'other' => q({0} fersentimetrar),
						'per' => q({0} á fersentimetra),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(fersentimetrar),
						'one' => q({0} fersentimetri),
						'other' => q({0} fersentimetrar),
						'per' => q({0} á fersentimetra),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(fertommur),
						'one' => q({0} fertomma),
						'other' => q({0} fertommur),
						'per' => q({0} á fertommu),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(fertommur),
						'one' => q({0} fertomma),
						'other' => q({0} fertommur),
						'per' => q({0} á fertommu),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(ferkílómetrar),
						'one' => q({0} ferkílómetri),
						'other' => q({0} ferkílómetrar),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(ferkílómetrar),
						'one' => q({0} ferkílómetri),
						'other' => q({0} ferkílómetrar),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'one' => q({0} fermetri),
						'other' => q({0} fermetrar),
						'per' => q({0} á fermetra),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'one' => q({0} fermetri),
						'other' => q({0} fermetrar),
						'per' => q({0} á fermetra),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(feryardar),
						'one' => q({0} feryard),
						'other' => q({0} feryardar),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(feryardar),
						'one' => q({0} feryard),
						'other' => q({0} feryardar),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(neuter),
						'one' => q({0} atriði),
						'other' => q({0} atriði),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(neuter),
						'one' => q({0} atriði),
						'other' => q({0} atriði),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(neuter),
						'name' => q(karöt),
						'one' => q({0} karat),
						'other' => q({0} karöt),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(neuter),
						'name' => q(karöt),
						'one' => q({0} karat),
						'other' => q({0} karöt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrömm á desílítra),
						'one' => q({0} milligramm á desílítra),
						'other' => q({0} milligrömm á desílítra),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrömm á desílítra),
						'one' => q({0} milligramm á desílítra),
						'other' => q({0} milligrömm á desílítra),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(neuter),
						'name' => q(millimól á lítra),
						'one' => q({0} millimól á lítra),
						'other' => q({0} millimól á lítra),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(neuter),
						'name' => q(millimól á lítra),
						'one' => q({0} millimól á lítra),
						'other' => q({0} millimól á lítra),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(neuter),
						'one' => q({0} mól),
						'other' => q({0} mól),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(neuter),
						'one' => q({0} mól),
						'other' => q({0} mól),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(neuter),
						'one' => q({0} prósent),
						'other' => q({0} prósent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(neuter),
						'one' => q({0} prósent),
						'other' => q({0} prósent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(neuter),
						'one' => q({0} prómill),
						'other' => q({0} prómill),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(neuter),
						'one' => q({0} prómill),
						'other' => q({0} prómill),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(masculine),
						'one' => q({0} milljónarhluti),
						'other' => q({0} milljónarhlutar),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(masculine),
						'one' => q({0} milljónarhluti),
						'other' => q({0} milljónarhlutar),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(neuter),
						'one' => q({0} permyriad),
						'other' => q({0} permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(neuter),
						'one' => q({0} permyriad),
						'other' => q({0} permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(lítrar á 100 kílómetra),
						'one' => q({0} lítri á 100 kílómetra),
						'other' => q({0} lítrar á 100 kílómetra),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(lítrar á 100 kílómetra),
						'one' => q({0} lítri á 100 kílómetra),
						'other' => q({0} lítrar á 100 kílómetra),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(lítrar á kílómetra),
						'one' => q({0} lítri á kílómetra),
						'other' => q({0} lítrar á kílómetra),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(lítrar á kílómetra),
						'one' => q({0} lítri á kílómetra),
						'other' => q({0} lítrar á kílómetra),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mílur á gallon),
						'one' => q({0} míla á gallon),
						'other' => q({0} mílur á gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mílur á gallon),
						'one' => q({0} míla á gallon),
						'other' => q({0} mílur á gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mílur á breskt gallon),
						'one' => q({0} míla á breskt gallon),
						'other' => q({0} mílur á breskt gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mílur á breskt gallon),
						'one' => q({0} míla á breskt gallon),
						'other' => q({0} mílur á breskt gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} austur),
						'north' => q({0} norður),
						'south' => q({0} suður),
						'west' => q({0} vestur),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} austur),
						'north' => q({0} norður),
						'south' => q({0} suður),
						'west' => q({0} vestur),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'name' => q(bitar),
						'one' => q({0} biti),
						'other' => q({0} bitar),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'name' => q(bitar),
						'one' => q({0} biti),
						'other' => q({0} bitar),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(neuter),
						'one' => q({0} bæti),
						'other' => q({0} bæti),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(neuter),
						'one' => q({0} bæti),
						'other' => q({0} bæti),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
						'name' => q(gígabitar),
						'one' => q({0} gígabiti),
						'other' => q({0} gígabitar),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'name' => q(gígabitar),
						'one' => q({0} gígabiti),
						'other' => q({0} gígabitar),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(neuter),
						'name' => q(gígabæti),
						'one' => q({0} gígabæti),
						'other' => q({0} gígabæti),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(neuter),
						'name' => q(gígabæti),
						'one' => q({0} gígabæti),
						'other' => q({0} gígabæti),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'name' => q(kílóbitar),
						'one' => q({0} kílóbiti),
						'other' => q({0} kílóbitar),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'name' => q(kílóbitar),
						'one' => q({0} kílóbiti),
						'other' => q({0} kílóbitar),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(neuter),
						'name' => q(kílóbæti),
						'one' => q({0} kílóbæti),
						'other' => q({0} kílóbæti),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(neuter),
						'name' => q(kílóbæti),
						'one' => q({0} kílóbæti),
						'other' => q({0} kílóbæti),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'name' => q(megabitar),
						'one' => q({0} megabiti),
						'other' => q({0} megabitar),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'name' => q(megabitar),
						'one' => q({0} megabiti),
						'other' => q({0} megabitar),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(neuter),
						'name' => q(megabæti),
						'one' => q({0} megabæti),
						'other' => q({0} megabæti),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(neuter),
						'name' => q(megabæti),
						'one' => q({0} megabæti),
						'other' => q({0} megabæti),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(neuter),
						'name' => q(petabæti),
						'one' => q({0} petabæti),
						'other' => q({0} petabæti),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(neuter),
						'name' => q(petabæti),
						'one' => q({0} petabæti),
						'other' => q({0} petabæti),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'name' => q(terabitar),
						'one' => q({0} terabiti),
						'other' => q({0} terabitar),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
						'name' => q(terabitar),
						'one' => q({0} terabiti),
						'other' => q({0} terabitar),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(neuter),
						'name' => q(terabæti),
						'one' => q({0} terabæti),
						'other' => q({0} terabæti),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(neuter),
						'name' => q(terabæti),
						'one' => q({0} terabæti),
						'other' => q({0} terabæti),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(feminine),
						'name' => q(aldir),
						'one' => q({0} öld),
						'other' => q({0} aldir),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(feminine),
						'name' => q(aldir),
						'one' => q({0} öld),
						'other' => q({0} aldir),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0} á dag),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0} á dag),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(masculine),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(masculine),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(masculine),
						'name' => q(áratugir),
						'one' => q({0} áratugur),
						'other' => q({0} áratugir),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(masculine),
						'name' => q(áratugir),
						'one' => q({0} áratugur),
						'other' => q({0} áratugir),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'one' => q({0} klukkustund),
						'other' => q({0} klukkustundir),
						'per' => q({0} á klst.),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'one' => q({0} klukkustund),
						'other' => q({0} klukkustundir),
						'per' => q({0} á klst.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'name' => q(míkrósekúndur),
						'one' => q({0} míkrósekúnda),
						'other' => q({0} míkrósekúndur),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'name' => q(míkrósekúndur),
						'one' => q({0} míkrósekúnda),
						'other' => q({0} míkrósekúndur),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'name' => q(millisekúndur),
						'one' => q({0} millisekúnda),
						'other' => q({0} millisekúndur),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'name' => q(millisekúndur),
						'one' => q({0} millisekúnda),
						'other' => q({0} millisekúndur),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'name' => q(mínútur),
						'one' => q({0} mínúta),
						'other' => q({0} mínútur),
						'per' => q({0} á mínútu),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'name' => q(mínútur),
						'one' => q({0} mínúta),
						'other' => q({0} mínútur),
						'per' => q({0} á mínútu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'one' => q({0} mánuður),
						'other' => q({0} mánuðir),
						'per' => q({0} á mánuði),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'one' => q({0} mánuður),
						'other' => q({0} mánuðir),
						'per' => q({0} á mánuði),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'name' => q(nanósekúndur),
						'one' => q({0} nanósekúnda),
						'other' => q({0} nanósekúndur),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'name' => q(nanósekúndur),
						'one' => q({0} nanósekúnda),
						'other' => q({0} nanósekúndur),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'name' => q(ársfjórðungar),
						'one' => q({0} ársfjórðungur),
						'other' => q({0} ársfjórðungar),
						'per' => q({0}/ársfjórðung),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'name' => q(ársfjórðungar),
						'one' => q({0} ársfjórðungur),
						'other' => q({0} ársfjórðungar),
						'per' => q({0}/ársfjórðung),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'name' => q(sekúndur),
						'one' => q({0} sekúnda),
						'other' => q({0} sekúndur),
						'per' => q({0} á sekúndu),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'name' => q(sekúndur),
						'one' => q({0} sekúnda),
						'other' => q({0} sekúndur),
						'per' => q({0} á sekúndu),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0} á viku),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0} á viku),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(neuter),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0} á ári),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(neuter),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0} á ári),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(neuter),
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(neuter),
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(neuter),
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(neuter),
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(neuter),
						'one' => q({0} óm),
						'other' => q({0} óm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(neuter),
						'one' => q({0} óm),
						'other' => q({0} óm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(neuter),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(neuter),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Breskar varmaeiningar),
						'one' => q({0} Bresk varmaeining),
						'other' => q({0} Breskar varmaeiningar),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Breskar varmaeiningar),
						'one' => q({0} Bresk varmaeining),
						'other' => q({0} Breskar varmaeiningar),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(kaloríur),
						'one' => q({0} kaloría),
						'other' => q({0} kaloríur),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(kaloríur),
						'one' => q({0} kaloría),
						'other' => q({0} kaloríur),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} rafeindarvolt),
						'other' => q({0} rafeindarvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} rafeindarvolt),
						'other' => q({0} rafeindarvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(hitaeiningar),
						'one' => q({0} hitaeining),
						'other' => q({0} hitaeiningar),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(hitaeiningar),
						'one' => q({0} hitaeining),
						'other' => q({0} hitaeiningar),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(neuter),
						'one' => q({0} júl),
						'other' => q({0} júl),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(neuter),
						'one' => q({0} júl),
						'other' => q({0} júl),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kílókaloríur),
						'one' => q({0} kílókaloría),
						'other' => q({0} kílókaloríur),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kílókaloríur),
						'one' => q({0} kílókaloría),
						'other' => q({0} kílókaloríur),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(neuter),
						'one' => q({0} kílójúl),
						'other' => q({0} kílójúl),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(neuter),
						'one' => q({0} kílójúl),
						'other' => q({0} kílójúl),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(feminine),
						'name' => q(kílóvattstundir),
						'one' => q({0} kílóvattstund),
						'other' => q({0} kílóvattstundir),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(feminine),
						'name' => q(kílóvattstundir),
						'one' => q({0} kílóvattstund),
						'other' => q({0} kílóvattstundir),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(bandarískar varmaeiningar),
						'one' => q({0} bandarísk varmaeining),
						'other' => q({0} bandarískar varmaeiningar),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(bandarískar varmaeiningar),
						'one' => q({0} bandarísk varmaeining),
						'other' => q({0} bandarískar varmaeiningar),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(neuter),
						'one' => q({0} kílóvatt á 100 kílómetra),
						'other' => q({0} kílóvött á 100 kílómetra),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(neuter),
						'one' => q({0} kílóvatt á 100 kílómetra),
						'other' => q({0} kílóvött á 100 kílómetra),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(neuter),
						'one' => q({0} njúton),
						'other' => q({0} njúton),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(neuter),
						'one' => q({0} njúton),
						'other' => q({0} njúton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(kraftar punds),
						'one' => q({0} kraftur punds),
						'other' => q({0} kraftar punds),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(kraftar punds),
						'one' => q({0} kraftur punds),
						'other' => q({0} kraftar punds),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(neuter),
						'name' => q(gígahertz),
						'one' => q({0} gígahertz),
						'other' => q({0} gígahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(neuter),
						'name' => q(gígahertz),
						'one' => q({0} gígahertz),
						'other' => q({0} gígahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(neuter),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(neuter),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(neuter),
						'name' => q(kílóhertz),
						'one' => q({0} kílóhertz),
						'other' => q({0} kílóhertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(neuter),
						'name' => q(kílóhertz),
						'one' => q({0} kílóhertz),
						'other' => q({0} kílóhertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(neuter),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(neuter),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pixlar),
						'one' => q({0} pixill),
						'other' => q({0} pixlar),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pixlar),
						'one' => q({0} pixill),
						'other' => q({0} pixlar),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pixlar á sentimetra),
						'one' => q({0} pixill á sentimetra),
						'other' => q({0} pixlar á sentimetra),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pixlar á sentimetra),
						'one' => q({0} pixill á sentimetra),
						'other' => q({0} pixlar á sentimetra),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pixlar á tommu),
						'one' => q({0} pixill á tommu),
						'other' => q({0} pixlar á tommu),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pixlar á tommu),
						'one' => q({0} pixill á tommu),
						'other' => q({0} pixlar á tommu),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapixill),
						'other' => q({0} megapixlar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapixill),
						'other' => q({0} megapixlar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'one' => q({0} pixill),
						'other' => q({0} pixlar),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'one' => q({0} pixill),
						'other' => q({0} pixlar),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixlar á sentimetra),
						'one' => q({0} pixill á sentimetra),
						'other' => q({0} pixlar á sentimetra),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixlar á sentimetra),
						'one' => q({0} pixill á sentimetra),
						'other' => q({0} pixlar á sentimetra),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixlar á tommu),
						'one' => q({0} pixill á tommu),
						'other' => q({0} pixlar á tommu),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixlar á tommu),
						'one' => q({0} pixill á tommu),
						'other' => q({0} pixlar á tommu),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(stjarnfræðieiningar),
						'one' => q({0} stjarnfræðieining),
						'other' => q({0} stjarnfræðieiningar),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(stjarnfræðieiningar),
						'one' => q({0} stjarnfræðieining),
						'other' => q({0} stjarnfræðieiningar),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(sentimetrar),
						'one' => q({0} sentimetri),
						'other' => q({0} sentimetrar),
						'per' => q({0} á sentimetra),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(sentimetrar),
						'one' => q({0} sentimetri),
						'other' => q({0} sentimetrar),
						'per' => q({0} á sentimetra),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(desimetrar),
						'one' => q({0} desimetri),
						'other' => q({0} desimetrar),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(desimetrar),
						'one' => q({0} desimetri),
						'other' => q({0} desimetrar),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(geisli jarðar),
						'one' => q({0} geisli jarðar),
						'other' => q({0} geisli jarðar),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(geisli jarðar),
						'one' => q({0} geisli jarðar),
						'other' => q({0} geisli jarðar),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} faðmur),
						'other' => q({0} faðmar),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} faðmur),
						'other' => q({0} faðmar),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} á fet),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} á fet),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} tomma),
						'other' => q({0} tommur),
						'per' => q({0} á tommu),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} tomma),
						'other' => q({0} tommur),
						'per' => q({0} á tommu),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(kílómetrar),
						'one' => q({0} kílómetri),
						'other' => q({0} kílómetrar),
						'per' => q({0} á kílómetra),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(kílómetrar),
						'one' => q({0} kílómetri),
						'other' => q({0} kílómetrar),
						'per' => q({0} á kílómetra),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'name' => q(metrar),
						'one' => q({0} metri),
						'other' => q({0} metrar),
						'per' => q({0} á metra),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'name' => q(metrar),
						'one' => q({0} metri),
						'other' => q({0} metrar),
						'per' => q({0} á metra),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(míkrómetrar),
						'one' => q({0} míkrómetri),
						'other' => q({0} míkrómetrar),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(míkrómetrar),
						'one' => q({0} míkrómetri),
						'other' => q({0} míkrómetrar),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} míla),
						'other' => q({0} mílur),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} míla),
						'other' => q({0} mílur),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(sænsk míla),
						'one' => q({0} sænsk míla),
						'other' => q({0} sænskar mílur),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(sænsk míla),
						'one' => q({0} sænsk míla),
						'other' => q({0} sænskar mílur),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(millimetrar),
						'one' => q({0} millimetri),
						'other' => q({0} millimetrar),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(millimetrar),
						'one' => q({0} millimetri),
						'other' => q({0} millimetrar),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(nanómetrar),
						'one' => q({0} nanómetri),
						'other' => q({0} nanómetrar),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanómetrar),
						'one' => q({0} nanómetri),
						'other' => q({0} nanómetrar),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sjómílur),
						'one' => q({0} sjómíla),
						'other' => q({0} sjómílur),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sjómílur),
						'one' => q({0} sjómíla),
						'other' => q({0} sjómílur),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(píkómetrar),
						'one' => q({0} píkómetri),
						'other' => q({0} píkómetrar),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(píkómetrar),
						'one' => q({0} píkómetri),
						'other' => q({0} píkómetrar),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} sólarradíus),
						'other' => q({0} sólarradíusar),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} sólarradíus),
						'other' => q({0} sólarradíusar),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yard),
						'other' => q({0} yardar),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yard),
						'other' => q({0} yardar),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(neuter),
						'one' => q({0} kerti),
						'other' => q({0} kerti),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(neuter),
						'one' => q({0} kerti),
						'other' => q({0} kerti),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(neuter),
						'name' => q(lúmen),
						'one' => q({0} lúmen),
						'other' => q({0} lúmen),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(neuter),
						'name' => q(lúmen),
						'one' => q({0} lúmen),
						'other' => q({0} lúmen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(neuter),
						'one' => q({0} lúx),
						'other' => q({0} lúx),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(neuter),
						'one' => q({0} lúx),
						'other' => q({0} lúx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} ljósafl sólar),
						'other' => q({0} ljósafl sólar),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} ljósafl sólar),
						'other' => q({0} ljósafl sólar),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(neuter),
						'one' => q({0} karat),
						'other' => q({0} karöt),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(neuter),
						'one' => q({0} karat),
						'other' => q({0} karöt),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} jarðmassi),
						'other' => q({0} jarðmassar),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} jarðmassi),
						'other' => q({0} jarðmassar),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(neuter),
						'one' => q({0} gramm),
						'other' => q({0} grömm),
						'per' => q({0} á gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'one' => q({0} gramm),
						'other' => q({0} grömm),
						'per' => q({0} á gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(neuter),
						'name' => q(kílógrömm),
						'one' => q({0} kílógramm),
						'other' => q({0} kílógrömm),
						'per' => q({0} á kílógramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(neuter),
						'name' => q(kílógrömm),
						'one' => q({0} kílógramm),
						'other' => q({0} kílógrömm),
						'per' => q({0} á kílógramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(neuter),
						'name' => q(míkrógrömm),
						'one' => q({0} míkrógramm),
						'other' => q({0} míkrógrömm),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(neuter),
						'name' => q(míkrógrömm),
						'one' => q({0} míkrógramm),
						'other' => q({0} míkrógrömm),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(neuter),
						'name' => q(milligrömm),
						'one' => q({0} milligramm),
						'other' => q({0} milligrömm),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(neuter),
						'name' => q(milligrömm),
						'one' => q({0} milligramm),
						'other' => q({0} milligrömm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(únsur),
						'one' => q({0} únsa),
						'other' => q({0} únsur),
						'per' => q({0} á únsu),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(únsur),
						'one' => q({0} únsa),
						'other' => q({0} únsur),
						'per' => q({0} á únsu),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troyesúnsur),
						'one' => q({0} troyesúnsa),
						'other' => q({0} troyesúnsur),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troyesúnsur),
						'one' => q({0} troyesúnsa),
						'other' => q({0} troyesúnsur),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} á pund),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} á pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} sólmassi),
						'other' => q({0} sólmassar),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} sólmassi),
						'other' => q({0} sólmassar),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(bandarísk tonn),
						'one' => q({0} bandarískt tonn),
						'other' => q({0} bandarísk tonn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(bandarísk tonn),
						'one' => q({0} bandarískt tonn),
						'other' => q({0} bandarísk tonn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(neuter),
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(neuter),
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} á {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} á {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(neuter),
						'name' => q(gígavött),
						'one' => q({0} gígavatt),
						'other' => q({0} gígavött),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(neuter),
						'name' => q(gígavött),
						'one' => q({0} gígavatt),
						'other' => q({0} gígavött),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hestöfl),
						'one' => q({0} hestafl),
						'other' => q({0} hestöfl),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hestöfl),
						'one' => q({0} hestafl),
						'other' => q({0} hestöfl),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(neuter),
						'name' => q(kílóvött),
						'one' => q({0} kílóvatt),
						'other' => q({0} kílóvött),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(neuter),
						'name' => q(kílóvött),
						'one' => q({0} kílóvatt),
						'other' => q({0} kílóvött),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(neuter),
						'name' => q(megavött),
						'one' => q({0} megavatt),
						'other' => q({0} megavött),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(neuter),
						'name' => q(megavött),
						'one' => q({0} megavatt),
						'other' => q({0} megavött),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(neuter),
						'name' => q(millivött),
						'one' => q({0} millivatt),
						'other' => q({0} millivött),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(neuter),
						'name' => q(millivött),
						'one' => q({0} millivatt),
						'other' => q({0} millivött),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(neuter),
						'one' => q({0} vatt),
						'other' => q({0} vött),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(neuter),
						'one' => q({0} vatt),
						'other' => q({0} vött),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(fer{0}),
						'other' => q(fer{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(fer{0}),
						'other' => q(fer{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(rúm{0}),
						'other' => q(rúm{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(rúm{0}),
						'other' => q(rúm{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(loftþyngdir),
						'one' => q({0} loftþyngd),
						'other' => q({0} loftþyngdir),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(loftþyngdir),
						'one' => q({0} loftþyngd),
						'other' => q({0} loftþyngdir),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(neuter),
						'name' => q(bör),
						'one' => q({0} bar),
						'other' => q({0} bör),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(neuter),
						'name' => q(bör),
						'one' => q({0} bar),
						'other' => q({0} bör),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(neuter),
						'name' => q(hektópasköl),
						'one' => q({0} hektópaskal),
						'other' => q({0} hektópasköl),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(neuter),
						'name' => q(hektópasköl),
						'one' => q({0} hektópaskal),
						'other' => q({0} hektópasköl),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tommur af kvikasilfri),
						'one' => q({0} tomma af kvikasilfri),
						'other' => q({0} tommur af kvikasilfri),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tommur af kvikasilfri),
						'one' => q({0} tomma af kvikasilfri),
						'other' => q({0} tommur af kvikasilfri),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(neuter),
						'name' => q(kílópasköl),
						'one' => q({0} kílópaskal),
						'other' => q({0} kílópasköl),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(neuter),
						'name' => q(kílópasköl),
						'one' => q({0} kílópaskal),
						'other' => q({0} kílópasköl),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(neuter),
						'name' => q(megapasköl),
						'one' => q({0} megapaskal),
						'other' => q({0} megapasköl),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(neuter),
						'name' => q(megapasköl),
						'one' => q({0} megapaskal),
						'other' => q({0} megapasköl),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(neuter),
						'name' => q(millibör),
						'one' => q({0} millibar),
						'other' => q({0} millibör),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(neuter),
						'name' => q(millibör),
						'one' => q({0} millibar),
						'other' => q({0} millibör),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimetrar af kvikasilfri),
						'one' => q({0} millimetrar af kvikasilfri),
						'other' => q({0} millimetrar af kvikasilfri),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetrar af kvikasilfri),
						'one' => q({0} millimetrar af kvikasilfri),
						'other' => q({0} millimetrar af kvikasilfri),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(neuter),
						'name' => q(pasköl),
						'one' => q({0} paskal),
						'other' => q({0} pasköl),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(neuter),
						'name' => q(pasköl),
						'one' => q({0} paskal),
						'other' => q({0} pasköl),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pund á fertommu),
						'one' => q({0} pund á fertommu),
						'other' => q({0} pund á fertommu),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pund á fertommu),
						'one' => q({0} pund á fertommu),
						'other' => q({0} pund á fertommu),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q({0} Beaufort),
						'other' => q({0} Beaufort),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q({0} Beaufort),
						'other' => q({0} Beaufort),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'one' => q({0} kílómetri á klukkustund),
						'other' => q({0} kílómetrar á klukkustund),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'one' => q({0} kílómetri á klukkustund),
						'other' => q({0} kílómetrar á klukkustund),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(hnútar),
						'one' => q({0} hnútur),
						'other' => q({0} hnútar),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(hnútar),
						'one' => q({0} hnútur),
						'other' => q({0} hnútar),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metrar á sekúndu),
						'one' => q({0} metri á sekúndu),
						'other' => q({0} metrar á sekúndu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metrar á sekúndu),
						'one' => q({0} metri á sekúndu),
						'other' => q({0} metrar á sekúndu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mílur á klukkustund),
						'one' => q({0} míla á klukkustund),
						'other' => q({0} mílur á klukkustund),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mílur á klukkustund),
						'one' => q({0} míla á klukkustund),
						'other' => q({0} mílur á klukkustund),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(feminine),
						'one' => q({0} gráða á Celsíus),
						'other' => q({0} gráður á Celsíus),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(feminine),
						'one' => q({0} gráða á Celsíus),
						'other' => q({0} gráður á Celsíus),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(gráður á Fahrenheit),
						'one' => q({0} gráða á Fahrenheit),
						'other' => q({0} gráður á Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(gráður á Fahrenheit),
						'one' => q({0} gráða á Fahrenheit),
						'other' => q({0} gráður á Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(feminine),
						'one' => q({0} gráða),
						'other' => q({0} gráður),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(feminine),
						'one' => q({0} gráða),
						'other' => q({0} gráður),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(neuter),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(neuter),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(njútonmetrar),
						'one' => q({0} njútonmetri),
						'other' => q({0} njútonmetrar),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(njútonmetrar),
						'one' => q({0} njútonmetri),
						'other' => q({0} njútonmetrar),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pundfet),
						'one' => q({0} pundfet),
						'other' => q({0} pundfet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pundfet),
						'one' => q({0} pundfet),
						'other' => q({0} pundfet),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(tunnur),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tunnur),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'name' => q(sentilítrar),
						'one' => q({0} sentilítri),
						'other' => q({0} sentilítrar),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(sentilítrar),
						'one' => q({0} sentilítri),
						'other' => q({0} sentilítrar),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(rúmsentimetrar),
						'one' => q({0} rúmsentimetri),
						'other' => q({0} rúmsentimetrar),
						'per' => q({0} á rúmsentimetra),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(rúmsentimetrar),
						'one' => q({0} rúmsentimetri),
						'other' => q({0} rúmsentimetrar),
						'per' => q({0} á rúmsentimetra),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(rúmfet),
						'one' => q({0} rúmfet),
						'other' => q({0} rúmfet),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(rúmfet),
						'one' => q({0} rúmfet),
						'other' => q({0} rúmfet),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(rúmtommur),
						'one' => q({0} rúmtomma),
						'other' => q({0} rúmtommur),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(rúmtommur),
						'one' => q({0} rúmtomma),
						'other' => q({0} rúmtommur),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(rúmkílómetrar),
						'one' => q({0} rúmkílómetri),
						'other' => q({0} rúmkílómetrar),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(rúmkílómetrar),
						'one' => q({0} rúmkílómetri),
						'other' => q({0} rúmkílómetrar),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(rúmmetrar),
						'one' => q({0} rúmmetri),
						'other' => q({0} rúmmetrar),
						'per' => q({0} á rúmmetra),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(rúmmetrar),
						'one' => q({0} rúmmetri),
						'other' => q({0} rúmmetrar),
						'per' => q({0} á rúmmetra),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(rúmmílur),
						'one' => q({0} rúmmíla),
						'other' => q({0} rúmmílur),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(rúmmílur),
						'one' => q({0} rúmmíla),
						'other' => q({0} rúmmílur),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(rúmyardar),
						'one' => q({0} rúmyard),
						'other' => q({0} rúmyardar),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(rúmyardar),
						'one' => q({0} rúmyard),
						'other' => q({0} rúmyardar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(masculine),
						'name' => q(ástralskir bollar),
						'one' => q({0} ástralskur bolli),
						'other' => q({0} ástralskir bollar),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(masculine),
						'name' => q(ástralskir bollar),
						'one' => q({0} ástralskur bolli),
						'other' => q({0} ástralskir bollar),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(desilítrar),
						'one' => q({0} desilítri),
						'other' => q({0} desilítrar),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(desilítrar),
						'one' => q({0} desilítri),
						'other' => q({0} desilítrar),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ábætisskeið),
						'one' => q({0} ábætisskeið),
						'other' => q({0} ábætisskeið),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ábætisskeið),
						'one' => q({0} ábætisskeið),
						'other' => q({0} ábætisskeið),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(bresk ábætisskeið),
						'one' => q({0} bresk ábætisskeið),
						'other' => q({0} bresk ábætisskeið),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(bresk ábætisskeið),
						'one' => q({0} bresk ábætisskeið),
						'other' => q({0} bresk ábætisskeið),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drömm),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drömm),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dropar),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dropar),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(vökvaúnsur),
						'one' => q({0} vökvaúnsa),
						'other' => q({0} vökvaúnsur),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(vökvaúnsur),
						'one' => q({0} vökvaúnsa),
						'other' => q({0} vökvaúnsur),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(breskar vökvaúnsur),
						'one' => q({0} bresk vökvaúnsa),
						'other' => q({0} breskar vökvaúnsur),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(breskar vökvaúnsur),
						'one' => q({0} bresk vökvaúnsa),
						'other' => q({0} breskar vökvaúnsur),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} á gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} á gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Breskt gallon),
						'one' => q({0} breskt gallon),
						'other' => q({0} breskt gallon),
						'per' => q({0}/ á breskt gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Breskt gallon),
						'one' => q({0} breskt gallon),
						'other' => q({0} breskt gallon),
						'per' => q({0}/ á breskt gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(hektólítrar),
						'one' => q({0} hektólítri),
						'other' => q({0} hektólítrar),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(hektólítrar),
						'one' => q({0} hektólítri),
						'other' => q({0} hektólítrar),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(sjússar),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(sjússar),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'one' => q({0} lítri),
						'other' => q({0} lítrar),
						'per' => q({0} á lítra),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'one' => q({0} lítri),
						'other' => q({0} lítrar),
						'per' => q({0} á lítra),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(megalítrar),
						'one' => q({0} megalítri),
						'other' => q({0} megalítrar),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(megalítrar),
						'one' => q({0} megalítri),
						'other' => q({0} megalítrar),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(millilítrar),
						'one' => q({0} millilítri),
						'other' => q({0} millilítrar),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(millilítrar),
						'one' => q({0} millilítri),
						'other' => q({0} millilítrar),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(klípur),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(klípur),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(hálfpottar),
						'one' => q({0} hálfpottur),
						'other' => q({0} hálfpottar),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(hálfpottar),
						'one' => q({0} hálfpottur),
						'other' => q({0} hálfpottar),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kvartar),
						'one' => q({0} kvart),
						'other' => q({0} kvartar),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kvartar),
						'one' => q({0} kvart),
						'other' => q({0} kvartar),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(matskeiðar),
						'one' => q({0} matskeið),
						'other' => q({0} matskeiðar),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(matskeiðar),
						'one' => q({0} matskeið),
						'other' => q({0} matskeiðar),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(teskeiðar),
						'one' => q({0} teskeið),
						'other' => q({0} teskeiðar),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(teskeiðar),
						'one' => q({0} teskeið),
						'other' => q({0} teskeiðar),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(r{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(r{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(R{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
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
					'area-acre' => {
						'name' => q(ekra),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekra),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dúnam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dúnam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektari),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektari),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}mí²),
						'other' => q({0}mí²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}mí²),
						'other' => q({0}mí²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmól/l),
						'one' => q({0}mmól/l),
						'other' => q({0}mmól/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmól/l),
						'one' => q({0}mmól/l),
						'other' => q({0}mmól/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
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
						'east' => q({0}A),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}A),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}árh),
						'other' => q({0}árh),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}árh),
						'other' => q({0}árh),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dagur),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dagur),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(klukkustund),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(klukkustund),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mánuður),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mánuður),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(vika),
						'one' => q({0} v.),
						'other' => q({0} v.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vika),
						'one' => q({0} v.),
						'other' => q({0} v.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}á),
						'other' => q({0}á),
						'per' => q({0}/ár),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}á),
						'other' => q({0}á),
						'per' => q({0}/ár),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punktur),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punktur),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
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
					'length-fathom' => {
						'name' => q(faðmur),
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(faðmur),
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/tom),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/tom),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} lj.),
						'other' => q({0} lj.),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} lj.),
						'other' => q({0} lj.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0} sæ. míl),
						'other' => q({0} sæ. míl),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0} sæ. míl),
						'other' => q({0} sæ. míl),
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
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(únsur),
						'one' => q({0} únsa),
						'other' => q({0} únsur),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(únsur),
						'one' => q({0} únsa),
						'other' => q({0} únsur),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} p.),
						'other' => q({0} p.),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} p.),
						'other' => q({0} p.),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/klst.),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/klst.),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/sek.),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/sek.),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} míla/klst.),
						'other' => q({0} míl./klst.),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} míla/klst.),
						'other' => q({0} míl./klst.),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skeppa),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skeppa),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(bolli),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(bolli),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(áb.skeið),
						'one' => q({0} áb.skeið),
						'other' => q({0} áb.skeið),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(áb.skeið),
						'one' => q({0} áb.skeið),
						'other' => q({0} áb.skeið),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(br. áb.skeið),
						'one' => q({0} br áb.sk),
						'other' => q({0} br áb.sk),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(br. áb.skeið),
						'one' => q({0} br áb.sk),
						'other' => q({0} br áb.sk),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lítri),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lítri),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0} l.mál),
						'other' => q({0} l.mál),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} l.mál),
						'other' => q({0} l.mál),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(átt),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(átt),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(rontó{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(rontó{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(r{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(r{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kíló{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kíló{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(kv{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kv{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-hröðun),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-hröðun),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metrar/sek²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metrar/sek²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bogamín.),
						'one' => q({0} bogamín.),
						'other' => q({0} bogamín.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bogamín.),
						'one' => q({0} bogamín.),
						'other' => q({0} bogamín.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(bogasek.),
						'one' => q({0} bogasek.),
						'other' => q({0} bogasek.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(bogasek.),
						'one' => q({0} bogasek.),
						'other' => q({0} bogasek.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gráður),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gráður),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(sn.),
						'one' => q({0} sn.),
						'other' => q({0} sn.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(sn.),
						'one' => q({0} sn.),
						'other' => q({0} sn.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ekrur),
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekrur),
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dúnöm),
						'one' => q({0} dúnam),
						'other' => q({0} dúnam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dúnöm),
						'one' => q({0} dúnam),
						'other' => q({0} dúnam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektarar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ferfet),
						'one' => q({0} ferfet),
						'other' => q({0} ferfet),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ferfet),
						'one' => q({0} ferfet),
						'other' => q({0} ferfet),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(tommur²),
						'one' => q({0} t²),
						'other' => q({0} t²),
						'per' => q({0}/t²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(tommur²),
						'one' => q({0} t²),
						'other' => q({0} t²),
						'per' => q({0}/t²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(fermetrar),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(fermetrar),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(fermílur),
						'one' => q({0} fermíla),
						'other' => q({0} fermílur),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(fermílur),
						'one' => q({0} fermíla),
						'other' => q({0} fermílur),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yardar²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yardar²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(atriði),
						'one' => q({0} atriði),
						'other' => q({0} atriði),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(atriði),
						'one' => q({0} atriði),
						'other' => q({0} atriði),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimól/lítri),
						'one' => q({0} mmól/l),
						'other' => q({0} mmól/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimól/lítri),
						'one' => q({0} mmól/l),
						'other' => q({0} mmól/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mól),
						'one' => q({0} mól),
						'other' => q({0} mól),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mól),
						'one' => q({0} mól),
						'other' => q({0} mól),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(prósent),
						'one' => q({0}%),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(prósent),
						'one' => q({0}%),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(prómill),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(prómill),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(milljónarhlutar),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(milljónarhlutar),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriad),
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
						'name' => q(lítrar/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lítrar/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mílur/gallon),
						'one' => q({0} mí./gal.),
						'other' => q({0} mí./gal.),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mílur/gallon),
						'one' => q({0} mí./gal.),
						'other' => q({0} mí./gal.),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mílur/breskt gal.),
						'one' => q({0} mí./br.g.),
						'other' => q({0} mí./br.g.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mílur/breskt gal.),
						'one' => q({0} mí./br.g.),
						'other' => q({0} mí./br.g.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} A),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} A),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(biti),
						'one' => q({0} biti),
						'other' => q({0} bitar),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(biti),
						'one' => q({0} biti),
						'other' => q({0} bitar),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bæti),
						'one' => q({0} bæti),
						'other' => q({0} bæti),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bæti),
						'one' => q({0} bæti),
						'other' => q({0} bæti),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Pbæt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Pbæt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(árh),
						'one' => q({0} árh),
						'other' => q({0} árh),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(árh),
						'one' => q({0} árh),
						'other' => q({0} árh),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dagar),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dagar),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(árat.),
						'one' => q({0} árat.),
						'other' => q({0} árat.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(árat.),
						'one' => q({0} árat.),
						'other' => q({0} árat.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(klukkustundir),
						'one' => q({0} klst.),
						'other' => q({0} klst.),
						'per' => q({0}/klst.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(klukkustundir),
						'one' => q({0} klst.),
						'other' => q({0} klst.),
						'per' => q({0}/klst.),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsek.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsek.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisek.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisek.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mín.),
						'one' => q({0} mín.),
						'other' => q({0} mín.),
						'per' => q({0}/mín.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mín.),
						'one' => q({0} mín.),
						'other' => q({0} mín.),
						'per' => q({0}/mín.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mánuðir),
						'one' => q({0} mán.),
						'other' => q({0} mán.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mánuðir),
						'one' => q({0} mán.),
						'other' => q({0} mán.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanósek.),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanósek.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ársfj.),
						'one' => q({0} ársfj.),
						'other' => q({0} ársfj.),
						'per' => q({0}/ársfj.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ársfj.),
						'one' => q({0} ársfj.),
						'other' => q({0} ársfj.),
						'per' => q({0}/ársfj.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(vikur),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0}/v),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(vikur),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0}/v),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0}/ári),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0}/ári),
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
						'name' => q(óm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(óm),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(rafeindarvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(rafeindarvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(júl),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(júl),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kílójúl),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kílójúl),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(bandarísk varmaeining),
						'one' => q({0} bna varmaeining),
						'other' => q({0} bna varmaeiningar),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(bandarísk varmaeining),
						'one' => q({0} bna varmaeining),
						'other' => q({0} bna varmaeiningar),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(njúton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(njúton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(kraftur punds),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(kraftur punds),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punktar),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punktar),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixlar),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixlar),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixlar),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixlar),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(se),
						'one' => q({0} se),
						'other' => q({0} se),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(se),
						'one' => q({0} se),
						'other' => q({0} se),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(faðmar),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(faðmar),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fet),
						'one' => q({0} fet),
						'other' => q({0} fet),
						'per' => q({0}/fet),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fet),
						'one' => q({0} fet),
						'other' => q({0} fet),
						'per' => q({0}/fet),
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
						'name' => q(tommur),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tommur),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
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
						'name' => q(μmetrar),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmetrar),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mílur),
						'one' => q({0} mí),
						'other' => q({0} mí),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mílur),
						'one' => q({0} mí),
						'other' => q({0} mí),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sæ. míl.),
						'one' => q({0} sæ. míl.),
						'other' => q({0} sæ. míl.),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sæ. míl.),
						'one' => q({0} sæ. míl.),
						'other' => q({0} sæ. míl.),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sml),
						'one' => q({0} sml),
						'other' => q({0} sml),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sml),
						'one' => q({0} sml),
						'other' => q({0} sml),
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
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(sólarradíusar),
						'one' => q({0} Rsól),
						'other' => q({0} Rsól),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(sólarradíusar),
						'one' => q({0} Rsól),
						'other' => q({0} Rsól),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yardar),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yardar),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kerti),
						'one' => q({0} kerti),
						'other' => q({0} kerti),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kerti),
						'one' => q({0} kerti),
						'other' => q({0} kerti),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lúx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lúx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(ljósafl sólar),
						'one' => q({0} Lsól),
						'other' => q({0} Lsól),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(ljósafl sólar),
						'one' => q({0} Lsól),
						'other' => q({0} Lsól),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karöt),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karöt),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(jarðmassar),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(jarðmassar),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(ögn),
						'one' => q({0} ögn),
						'other' => q({0} agnir),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(ögn),
						'one' => q({0} ögn),
						'other' => q({0} agnir),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grömm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grömm),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troyesoz),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troyesoz),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(sólmassar),
						'one' => q({0} Msól),
						'other' => q({0} Msól),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(sólmassar),
						'one' => q({0} Msól),
						'other' => q({0} Msól),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(BNA tonn),
						'one' => q({0} BNA tn),
						'other' => q({0} BNA tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(BNA tonn),
						'one' => q({0} BNA tn),
						'other' => q({0} BNA tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hö),
						'one' => q({0} hö),
						'other' => q({0} hö),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hö),
						'one' => q({0} hö),
						'other' => q({0} hö),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vött),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vött),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} bar),
						'other' => q({0} bör),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} bar),
						'other' => q({0} bör),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(to Hg),
						'one' => q({0} to Hg),
						'other' => q({0} to Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(to Hg),
						'one' => q({0} to Hg),
						'other' => q({0} to Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbör),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbör),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kílómetrar á klukkustund),
						'one' => q({0} km/klst.),
						'other' => q({0} km/klst.),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kílómetrar á klukkustund),
						'one' => q({0} km/klst.),
						'other' => q({0} km/klst.),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metrar/sek.),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metrar/sek.),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mílur/klst.),
						'one' => q({0} míla/klst.),
						'other' => q({0} mílur/klst.),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mílur/klst.),
						'one' => q({0} míla/klst.),
						'other' => q({0} mílur/klst.),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gráður á Celsíus),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gráður á Celsíus),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ekrufet),
						'one' => q({0} ekrufet),
						'other' => q({0} ekrufet),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ekrufet),
						'one' => q({0} ekrufet),
						'other' => q({0} ekrufet),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(tunna),
						'one' => q({0} tunna),
						'other' => q({0} tunnur),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(tunna),
						'one' => q({0} tunna),
						'other' => q({0} tunnur),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(skeppur),
						'one' => q({0} skeppa),
						'other' => q({0} skeppur),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(skeppur),
						'one' => q({0} skeppa),
						'other' => q({0} skeppur),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(fet³),
						'one' => q({0} fet³),
						'other' => q({0} fet³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fet³),
						'one' => q({0} fet³),
						'other' => q({0} fet³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(tommur³),
						'one' => q({0} t³),
						'other' => q({0} t³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(tommur³),
						'one' => q({0} t³),
						'other' => q({0} t³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mí³),
						'one' => q({0} mí³),
						'other' => q({0} mí³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mí³),
						'one' => q({0} mí³),
						'other' => q({0} mí³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yardar³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yardar³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(bollar),
						'one' => q({0} bolli),
						'other' => q({0} bollar),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(bollar),
						'one' => q({0} bolli),
						'other' => q({0} bollar),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ástr. bolli),
						'one' => q({0} ástr. bolli),
						'other' => q({0} ástr. bollar),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ástr. bolli),
						'one' => q({0} ástr. bolli),
						'other' => q({0} ástr. bollar),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ábætissk.),
						'one' => q({0} ábætissk.),
						'other' => q({0} ábætissk.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ábætissk.),
						'one' => q({0} ábætissk.),
						'other' => q({0} ábætissk.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(bresk ábætissk.),
						'one' => q({0} bresk ábætissk.),
						'other' => q({0} bresk ábætissk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(bresk ábætissk.),
						'one' => q({0} bresk ábætissk.),
						'other' => q({0} bresk ábætissk.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dramm),
						'one' => q({0} dramm),
						'other' => q({0} drömm),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dramm),
						'one' => q({0} dramm),
						'other' => q({0} drömm),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dropi),
						'one' => q({0} dropi),
						'other' => q({0} dropar),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dropi),
						'one' => q({0} dropi),
						'other' => q({0} dropar),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(breskar fl oz),
						'one' => q({0} bresk fl oz),
						'other' => q({0} breskar fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(breskar fl oz),
						'one' => q({0} bresk fl oz),
						'other' => q({0} breskar fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(breskt gal.),
						'one' => q({0} breskt gal.),
						'other' => q({0} breskt gal.),
						'per' => q({0} breskt gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(breskt gal.),
						'one' => q({0} breskt gal.),
						'other' => q({0} breskt gal.),
						'per' => q({0} breskt gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(sjúss),
						'one' => q({0} sjúss),
						'other' => q({0} sjússar),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(sjúss),
						'one' => q({0} sjúss),
						'other' => q({0} sjússar),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lítrar),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lítrar),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(klípa),
						'one' => q({0} klípa),
						'other' => q({0} klípur),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(klípa),
						'one' => q({0} klípa),
						'other' => q({0} klípur),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(hálfp.),
						'one' => q({0} hálfp.),
						'other' => q({0} hálfp.),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(hálfp.),
						'one' => q({0} hálfp.),
						'other' => q({0} hálfp.),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(lagarmál),
						'one' => q({0} lagarmál),
						'other' => q({0} lagarmál),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(lagarmál),
						'one' => q({0} lagarmál),
						'other' => q({0} lagarmál),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(msk),
						'one' => q({0} msk),
						'other' => q({0} msk),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(msk),
						'one' => q({0} msk),
						'other' => q({0} msk),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:já|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nei|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} og {1}),
				2 => q({0} og {1}),
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
					'one' => '0 þúsund',
					'other' => '0 þúsund',
				},
				'10000' => {
					'one' => '00 þúsund',
					'other' => '00 þúsund',
				},
				'100000' => {
					'one' => '000 þúsund',
					'other' => '000 þúsund',
				},
				'1000000' => {
					'one' => '0 milljón',
					'other' => '0 milljónir',
				},
				'10000000' => {
					'one' => '00 milljón',
					'other' => '00 milljónir',
				},
				'100000000' => {
					'one' => '000 milljón',
					'other' => '000 milljónir',
				},
				'1000000000' => {
					'one' => '0 milljarður',
					'other' => '0 milljarðar',
				},
				'10000000000' => {
					'one' => '00 milljarður',
					'other' => '00 milljarðar',
				},
				'100000000000' => {
					'one' => '000 milljarður',
					'other' => '000 milljarðar',
				},
				'1000000000000' => {
					'one' => '0 billjón',
					'other' => '0 billjónir',
				},
				'10000000000000' => {
					'one' => '00 billjón',
					'other' => '00 billjónir',
				},
				'100000000000000' => {
					'one' => '000 billjón',
					'other' => '000 billjónir',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 þ'.'',
					'other' => '0 þ'.'',
				},
				'10000' => {
					'one' => '00 þ'.'',
					'other' => '00 þ'.'',
				},
				'100000' => {
					'one' => '000 þ'.'',
					'other' => '000 þ'.'',
				},
				'1000000' => {
					'one' => '0 m'.'',
					'other' => '0 m'.'',
				},
				'10000000' => {
					'one' => '00 m'.'',
					'other' => '00 m'.'',
				},
				'100000000' => {
					'one' => '000 m'.'',
					'other' => '000 m'.'',
				},
				'1000000000' => {
					'one' => '0 ma'.'',
					'other' => '0 ma'.'',
				},
				'10000000000' => {
					'one' => '00 ma'.'',
					'other' => '00 ma'.'',
				},
				'100000000000' => {
					'one' => '000 ma'.'',
					'other' => '000 ma'.'',
				},
				'1000000000000' => {
					'one' => '0 bn',
					'other' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 bn',
					'other' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 bn',
					'other' => '000 bn',
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
		'ADP' => {
			display_name => {
				'currency' => q(Andorrskur peseti),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(arabískt dírham),
				'one' => q(arabískt dírham),
				'other' => q(arabísk dírhöm),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani),
				'one' => q(afgani),
				'other' => q(afganar),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albanskt lek),
				'one' => q(albanskt lek),
				'other' => q(albönsk lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armenskt dramm),
				'one' => q(armenskt dramm),
				'other' => q(armensk drömm),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(hollenskt Antillugyllini),
				'one' => q(hollenskt Antillugyllini),
				'other' => q(hollensk Antillugyllini),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angólsk kvansa),
				'one' => q(angólsk kvansa),
				'other' => q(angólskar kvönsur),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentine Austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentískur pesi \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentínskur pesi),
				'one' => q(argentínskur pesi),
				'other' => q(argentínskir pesar),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Austurrískur skildingur),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(ástralskur dalur),
				'one' => q(ástralskur dalur),
				'other' => q(ástralskir dalir),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arúbönsk flórína),
				'one' => q(arúbönsk flórína),
				'other' => q(arúbanskar flórínur),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(aserskt manat),
				'one' => q(aserskt manat),
				'other' => q(asersk manöt),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(skiptanlegt Bosníu og Hersegóvínu-mark),
				'one' => q(skiptanlegt Bosníu og Hersegóvínu-mark),
				'other' => q(skiptanleg Bosníu og Hersegóvínu-mörk),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoskur dalur),
				'one' => q(barbadoskur dalur),
				'other' => q(barbadoskir dalir),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladessk taka),
				'one' => q(bangladessk taka),
				'other' => q(bangladesskar tökur),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgískur franki),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Lef),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(búlgarskt lef),
				'one' => q(búlgarskt lef),
				'other' => q(búlgörsk lef),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bareinskur denari),
				'one' => q(bareinskur denari),
				'other' => q(bareinskir denarar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(búrúndískur franki),
				'one' => q(búrúndískur franki),
				'other' => q(búrúndískir frankar),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermúdadalur),
				'one' => q(Bermúdadalur),
				'other' => q(Bermúdadalir),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brúneiskur dalur),
				'one' => q(brúneiskur dalur),
				'other' => q(brúneiskir dalir),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bólivíani),
				'one' => q(bólivíani),
				'other' => q(bólivíanar),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bólivískur pesi),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivian Mvdol),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brasilískt ríal),
				'one' => q(brasilískt ríal),
				'other' => q(brasilísk ríöl),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamadalur),
				'one' => q(Bahamadalur),
				'other' => q(Bahamadalir),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bútanskt núltrum),
				'one' => q(bútanskt núltrum),
				'other' => q(bútönsk núltrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Búrmverskt kjat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botsvönsk púla),
				'one' => q(botsvönsk púla),
				'other' => q(botsvanskar púlur),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(hvítrússnesk rúbla),
				'one' => q(hvítrússnesk rúbla),
				'other' => q(hvítrússneskar rúblur),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(hvítrússnesk rúbla \(2000–2016\)),
				'one' => q(hvítrússnesk rúbla \(2000–2016\)),
				'other' => q(hvítrússneskar rúblur \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belískur dalur),
				'one' => q(belískur dalur),
				'other' => q(belískir dalir),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Kanadadalur),
				'one' => q(Kanadadalur),
				'other' => q(Kanadadalir),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongóskur franki),
				'one' => q(kongóskur franki),
				'other' => q(kongóskir frankar),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(svissneskur franki),
				'one' => q(svissneskur franki),
				'other' => q(svissneskir frankar),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chilean Unidades de Fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(síleskur pesi),
				'one' => q(síleskur pesi),
				'other' => q(síleskir pesar),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kínverskt júan \(utan heimalands\)),
				'one' => q(kínverskt júan \(utan heimalands\)),
				'other' => q(kínversk júön \(utan heimalands\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kínverskt júan),
				'one' => q(kínverskt júan),
				'other' => q(kínversk júön),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kólumbískur pesi),
				'one' => q(kólumbískur pesi),
				'other' => q(kólumbískir pesar),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostarískt kólon),
				'one' => q(kostarískt kólon),
				'other' => q(kostarísk kólon),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tékknesk króna, eldri),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kúbverskur skiptanlegur pesi),
				'one' => q(kúbverskur skiptanlegur pesi),
				'other' => q(kúbverskir skiptanlegir pesar),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kúbverskur pesi),
				'one' => q(kúbverskur pesi),
				'other' => q(kúbverskir pesar),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(grænhöfðeyskur skúti),
				'one' => q(grænhöfðeyskur skúti),
				'other' => q(grænhöfðeyskir skútar),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kýpverskt pund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tékknesk króna),
				'one' => q(tékknesk króna),
				'other' => q(tékkneskar krónur),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Austurþýskt mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Þýskt mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(djíbútískur franki),
				'one' => q(djíbútískur franki),
				'other' => q(djíbútískir frankar),
			},
		},
		'DKK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(dönsk króna),
				'one' => q(dönsk króna),
				'other' => q(danskar krónur),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dóminískur pesi),
				'one' => q(dóminískur pesi),
				'other' => q(dóminískir pesar),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alsírskur denari),
				'one' => q(alsírskur denari),
				'other' => q(alsírskir denarar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuador Sucre),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Eistnesk króna),
				'one' => q(eistnesk króna),
				'other' => q(eistneskar krónur),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egypskt pund),
				'one' => q(egypskt pund),
				'other' => q(egypsk pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(erítresk nakfa),
				'one' => q(erítresk nakfa),
				'other' => q(erítreskar nökfur),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spænskur peseti),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(eþíópískt birr),
				'one' => q(eþíópískt birr),
				'other' => q(eþíópísk birr),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(evra),
				'one' => q(evra),
				'other' => q(evrur),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finnskt mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fídjískur dalur),
				'one' => q(fídjískur dalur),
				'other' => q(fídjískir dalir),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklenskt pund),
				'one' => q(falklenskt pund),
				'other' => q(falklensk pund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franskur franki),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(sterlingspund),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgískur lari),
				'one' => q(georgískur lari),
				'other' => q(georgískir larar),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ganverskur sedi),
				'one' => q(ganverskur sedi),
				'other' => q(ganverskir sedar),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gíbraltarspund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambískur dalasi),
				'one' => q(gambískur dalasi),
				'other' => q(gambískir dalasar),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Gíneufranki),
				'one' => q(Gíneufranki),
				'other' => q(Gíneufrankar),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drakma),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(gvatemalskt kvesal),
				'one' => q(gvatemalskt kvesal),
				'other' => q(gvatemölsk kvesöl),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portúgalskur, gíneskur skúti),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(gvæjanskur dalur),
				'one' => q(gvæjanskur dalur),
				'other' => q(gvæjanskir dalir),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kong-dalur),
				'one' => q(Hong Kong-dalur),
				'other' => q(Hong Kong-dalir),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(hondúrsk lempíra),
				'one' => q(hondúrsk lempíra),
				'other' => q(hondúrskar lempírur),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(króatísk kúna),
				'one' => q(króatísk kúna),
				'other' => q(króatískar kúnur),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haítískur gúrdi),
				'one' => q(haítískur gúrdi),
				'other' => q(haítískir gúrdar),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ungversk fórinta),
				'one' => q(ungversk fórinta),
				'other' => q(ungverskar fórintur),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indónesísk rúpía),
				'one' => q(indónesísk rúpía),
				'other' => q(indónesískar rúpíur),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Írskt pund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Ísraelskt pund),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nýr ísraelskur sikill),
				'one' => q(nýr ísraelskur sikill),
				'other' => q(nýir ísraelskir siklar),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indversk rúpía),
				'one' => q(indversk rúpía),
				'other' => q(indverskar rúpíur),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(írakskur denari),
				'one' => q(írakskur denari),
				'other' => q(írakskir denarar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(íranskt ríal),
				'one' => q(íranskt ríal),
				'other' => q(írönsk ríöl),
			},
		},
		'ISK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(íslensk króna),
				'one' => q(íslensk króna),
				'other' => q(íslenskar krónur),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Ítölsk líra),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaískur dalur),
				'one' => q(jamaískur dalur),
				'other' => q(jamaískir dalir),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jórdanskur denari),
				'one' => q(jórdanskur denari),
				'other' => q(jórdanskir denarar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japanskt jen),
				'one' => q(japanskt jen),
				'other' => q(japönsk jen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenískur skildingur),
				'one' => q(kenískur skildingur),
				'other' => q(kenískir skildingar),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgiskt som),
				'one' => q(kirgiskt som),
				'other' => q(kirgisk som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambódískt ríal),
				'one' => q(kambódískt ríal),
				'other' => q(kambódísk ríöl),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(kómoreyskur franki),
				'one' => q(kómoreyskur franki),
				'other' => q(kómoreyskir frankar),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(norðurkóreskt vonn),
				'one' => q(norðurkóreskt vonn),
				'other' => q(norðurkóresk vonn),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(suðurkóreskt vonn),
				'one' => q(suðurkóreskt vonn),
				'other' => q(suðurkóresk vonn),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kúveiskur denari),
				'one' => q(kúveiskur denari),
				'other' => q(kúveiskir denarar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(caymaneyskur dalur),
				'one' => q(caymaneyskur dalur),
				'other' => q(caymaneyskir dalir),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kasakst tengi),
				'one' => q(kasakst tengi),
				'other' => q(kasöksk tengi),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoskt kip),
				'one' => q(laoskt kip),
				'other' => q(laosk kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(líbanskt pund),
				'one' => q(líbanskt pund),
				'other' => q(líbönsk pund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srílönsk rúpía),
				'one' => q(srílönsk rúpía),
				'other' => q(srílanskar rúpíur),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(líberískur dalur),
				'one' => q(líberískur dalur),
				'other' => q(líberískir dalir),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesótóskur lóti),
				'one' => q(lesótóskur lóti),
				'other' => q(lesótóskir lótar),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litháískt lít),
				'one' => q(litháískt lít),
				'other' => q(litháísk lít),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Lithuanian Talonas),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Lúxemborgarfranki),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lettneskt lat),
				'one' => q(lettneskt lat),
				'other' => q(lettnesk löt),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lettnesk rúbla),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(líbískur denari),
				'one' => q(líbískur denari),
				'other' => q(líbískir denarar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkóskt dírham),
				'one' => q(marokkóskt dírham),
				'other' => q(marokkósk dírhöm),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkóskur franki),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldavískt lei),
				'one' => q(moldavískt lei),
				'other' => q(moldavísk lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskararjari),
				'one' => q(Madagaskararjari),
				'other' => q(Madagaskararjarar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskur franki),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedónskur denari),
				'one' => q(makedónskur denari),
				'other' => q(makedónskir denarar),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malískur franki),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(mjanmarskt kjat),
				'one' => q(mjanmarskt kjat),
				'other' => q(mjanmörsk kjöt),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongólskur túríkur),
				'one' => q(mongólskur túríkur),
				'other' => q(mongólskir túríkar),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaósk pataka),
				'one' => q(makaósk pataka),
				'other' => q(makaóskar patökur),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(márítönsk úgía \(1973–2017\)),
				'one' => q(máritönsk úgía \(1973–2017\)),
				'other' => q(máritanskar úgíur \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(márítönsk úgía),
				'one' => q(máritönsk úgía),
				'other' => q(máritanskar úgíur),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Meltnesk líra),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltneskt pund),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(máritísk rúpía),
				'one' => q(máritísk rúpía),
				'other' => q(máritískar rúpíur),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldíveysk rúpía),
				'one' => q(maldíveysk rúpía),
				'other' => q(maldíveyskar rúpíur),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malavísk kvaka),
				'one' => q(malavísk kvaka),
				'other' => q(malavískar kvökur),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(mexíkóskur pesi),
				'one' => q(mexíkóskur pesi),
				'other' => q(mexíkóskir pesar),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexíkóskur silfurpesi \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexíkóskur pesi, UDI),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malasískt ringit),
				'one' => q(malasískt ringit),
				'other' => q(malasísk ringit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mósambískur skúti),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mósambískt metikal),
				'one' => q(mósambískt metikal),
				'other' => q(mósambísk metiköl),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibískur dalur),
				'one' => q(namibískur dalur),
				'other' => q(namibískir dalir),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nígerísk næra),
				'one' => q(nígerísk næra),
				'other' => q(nígerískar nærur),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Níkarögsk kordóva \(1988–1991\)),
				'one' => q(Níkarögsk kordóva \(1988–1991\)),
				'other' => q(Níkaragskar kordóvur \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(níkarögsk kordóva),
				'one' => q(níkarögsk kordóva),
				'other' => q(níkaragskar kordóvur),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollenskt gyllini),
			},
		},
		'NOK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(norsk króna),
				'one' => q(norsk króna),
				'other' => q(norskar krónur),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepölsk rúpía),
				'one' => q(nepölsk rúpía),
				'other' => q(nepalskar rúpíur),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(nýsjálenskur dalur),
				'one' => q(nýsjálenskur dalur),
				'other' => q(nýsjálenskir dalir),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ómanskt ríal),
				'one' => q(ómanskt ríal),
				'other' => q(ómönsk ríöl),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balbói),
				'one' => q(balbói),
				'other' => q(balbóar),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(perúskt sól),
				'one' => q(perúskt sól),
				'other' => q(perúsk sól),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papúsk kína),
				'one' => q(papúsk kína),
				'other' => q(papúskar kínur),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filippseyskur pesi),
				'one' => q(filippseyskur pesi),
				'other' => q(filippseyskir pesar),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistönsk rúpía),
				'one' => q(pakistönsk rúpía),
				'other' => q(pakistanskar rúpíur),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(pólskt slot),
				'one' => q(pólskt slot),
				'other' => q(pólsk slot),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Slot),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portúgalskur skúti),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paragvæskt gvaraní),
				'one' => q(paragvæskt gvaraní),
				'other' => q(paragvæsk gvaraní),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarskt ríal),
				'one' => q(katarskt ríal),
				'other' => q(katörsk ríöl),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rúmenskt lei \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rúmenskt lei),
				'one' => q(rúmenskt lei),
				'other' => q(rúmensk lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbneskur denari),
				'one' => q(serbneskur denari),
				'other' => q(serbneskir denarar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rússnesk rúbla),
				'one' => q(rússnesk rúbla),
				'other' => q(rússneskar rúblur),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Rússnesk rúbla \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rúandskur franki),
				'one' => q(rúandskur franki),
				'other' => q(rúandskir frankar),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(sádíarabískt ríal),
				'one' => q(sádiarabískt ríal),
				'other' => q(sádiarabísk ríöl),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salómonseyskur dalur),
				'one' => q(salómonseyskur dalur),
				'other' => q(salómonseyskir dalir),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellesrúpía),
				'one' => q(Seychellesrúpía),
				'other' => q(Seychellesrúpíur),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Súdanskur denari),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(súdanskt pund),
				'one' => q(súdanskt pund),
				'other' => q(súdönsk pund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Súdanskt pund \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'kr.',
			display_name => {
				'currency' => q(sænsk króna),
				'one' => q(sænsk króna),
				'other' => q(sænskar krónur),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapúrskur dalur),
				'one' => q(singapúrskur dalur),
				'other' => q(singapúrskir dalir),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(helenskt pund),
				'one' => q(helenskt pund),
				'other' => q(helensk pund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slóvenskur dalur),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slóvakísk króna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(síerraleónsk ljóna),
				'one' => q(síerraleónsk ljóna),
				'other' => q(síerraleónskar ljónur),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(síerraleónsk ljóna \(1964—2022\)),
				'one' => q(síerraleónsk ljóna \(1964—2022\)),
				'other' => q(síerraleónskar ljónur \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(sómalískur skildingur),
				'one' => q(sómalískur skildingur),
				'other' => q(sómalískir skildingar),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Súrínamdalur),
				'one' => q(Súrínamdalur),
				'other' => q(Súrínamdalir),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Suriname Guilder),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(suðursúdanskt pund),
				'one' => q(suðursúdanskt pund),
				'other' => q(suðursúdönsk pund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Saó Tóme og Prinsípe-dóbra \(1977–2017\)),
				'one' => q(Saó Tóme og Prinsípe-dóbra \(1977–2017\)),
				'other' => q(Saó Tóme og Prinsípe-dóbrur \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Saó Tóme og Prinsípe-dóbra),
				'one' => q(Saó Tóme og Prinsípe-dóbra),
				'other' => q(Saó Tóme og Prinsípe-dóbrur),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Soviet Rouble),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El Salvador Colon),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sýrlenskt pund),
				'one' => q(sýrlenskt pund),
				'other' => q(sýrlensk pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(svasílenskur lílangeni),
				'one' => q(svasílenskur lílangeni),
				'other' => q(svasílenskir lílangenar),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(taílenskt bat),
				'one' => q(taílenskt bat),
				'other' => q(taílensk böt),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadsjiksk rúbla),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadsjikskur sómóni),
				'one' => q(tadsjikskur sómóni),
				'other' => q(tadsjikskir sómónar),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Túrkmenskt manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(túrkmenskt manat),
				'one' => q(túrkmenskt manat),
				'other' => q(túrkmensk manöt),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(túniskur denari),
				'one' => q(túniskur denari),
				'other' => q(túniskir denarar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongapanga),
				'one' => q(Tongapanga),
				'other' => q(Tongapöngur),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Tímorskur skúti),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Tyrknesk líra \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(tyrknesk líra),
				'one' => q(tyrknesk líra),
				'other' => q(tyrkneskar lírur),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trínidad og Tóbagó-dalur),
				'one' => q(Trínidad og Tóbagó-dalur),
				'other' => q(Trínidad og Tóbagó-dalir),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(taívanskur dalur),
				'one' => q(taívanskur dalur),
				'other' => q(taívanskir dalir),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tansanískur skildingur),
				'one' => q(tansanískur skildingur),
				'other' => q(tansanískir skildingar),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(úkraínsk hrinja),
				'one' => q(úkraínsk hrinja),
				'other' => q(úkraínskar hrinjur),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrainian Karbovanetz),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(úgandskur skildingur),
				'one' => q(úgandskur skildingur),
				'other' => q(úgandskir skildingar),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(Bandaríkjadalur),
				'one' => q(Bandaríkjadalur),
				'other' => q(Bandaríkjadalir),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Bandaríkjadalur \(næsta dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Bandaríkjadalur \(sama dag\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(úrúgvæskur pesi),
				'one' => q(úrúgvæskur pesi),
				'other' => q(úrúgvæskir pesar),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(úsbekskt súm),
				'one' => q(úsbekskt súm),
				'other' => q(úsbeksk súm),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolívar í Venesúela \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venesúelskur bólívari \(2008–2018\)),
				'one' => q(venesúelskur bólívari \(2008–2018\)),
				'other' => q(venesúelskir bólívarar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venesúelskur bólívari),
				'one' => q(venesúelskur bólívari),
				'other' => q(venesúelskir bólívarar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(víetnamskt dong),
				'one' => q(víetnamskt dong),
				'other' => q(víetnömsk dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanúatúskt vatú),
				'one' => q(vanúatúskt vatú),
				'other' => q(vanúatúsk vatú),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samóatala),
				'one' => q(Samóatala),
				'other' => q(Samóatölur),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(miðafrískur franki),
				'one' => q(miðafrískur franki),
				'other' => q(miðafrískir frankar),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(unse silfur),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(unse gull),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(austurkarabískur dalur),
				'one' => q(austurkarabískur dalur),
				'other' => q(austurkarabískir dalir),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Sérstök dráttarréttindi),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franskur gullfranki),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franskur franki, UIC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(vesturafrískur franki),
				'one' => q(vesturafrískur franki),
				'other' => q(vesturafrískir frankar),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(unse palladín),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(pólinesískur franki),
				'one' => q(pólinesískur franki),
				'other' => q(pólinesískir frankar),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(unse platína),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(óþekktur gjaldmiðill),
				'one' => q(\(óþekkt mynteining gjaldmiðils\)),
				'other' => q(\(óþekktur gjaldmiðill\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemenskur denari),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenskt ríal),
				'one' => q(jemenskt ríal),
				'other' => q(jemensk ríöl),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Júgóslavneskur denari),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rand \(viðskipta\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(suðurafrískt rand),
				'one' => q(suðurafrískt rand),
				'other' => q(suðurafrísk rönd),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambian Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(sambísk kvaka),
				'one' => q(sambísk kvaka),
				'other' => q(sambískar kvökur),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Simbabveskur dalur),
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
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
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
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
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
							'jan.',
							'feb.',
							'mar.',
							'apr.',
							'maí',
							'jún.',
							'júl.',
							'ágú.',
							'sep.',
							'okt.',
							'nóv.',
							'des.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'janúar',
							'febrúar',
							'mars',
							'apríl',
							'maí',
							'júní',
							'júlí',
							'ágúst',
							'september',
							'október',
							'nóvember',
							'desember'
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
							'Á',
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
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
				'stand-alone' => {
					wide => {
						nonleap => [
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'Nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
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
							'saf.',
							'rab. I',
							'rab. II',
							'jum. I',
							'jum. II',
							'raj.',
							'sha.',
							'ram.',
							'shaw.',
							'dhuʻl-Q.',
							'dhuʻl-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharram',
							'safar',
							'rabiʻ I',
							'rabiʻ II',
							'jumada I',
							'jumada II',
							'rajab',
							'shaʻban',
							'ramadan',
							'shawwal',
							'dhuʻl-Qiʻdah',
							'dhuʻl-Hijjah'
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
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
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
						mon => 'mán.',
						tue => 'þri.',
						wed => 'mið.',
						thu => 'fim.',
						fri => 'fös.',
						sat => 'lau.',
						sun => 'sun.'
					},
					short => {
						mon => 'má.',
						tue => 'þr.',
						wed => 'mi.',
						thu => 'fi.',
						fri => 'fö.',
						sat => 'la.',
						sun => 'su.'
					},
					wide => {
						mon => 'mánudagur',
						tue => 'þriðjudagur',
						wed => 'miðvikudagur',
						thu => 'fimmtudagur',
						fri => 'föstudagur',
						sat => 'laugardagur',
						sun => 'sunnudagur'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'Þ',
						wed => 'M',
						thu => 'F',
						fri => 'F',
						sat => 'L',
						sun => 'S'
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
					abbreviated => {0 => 'F1',
						1 => 'F2',
						2 => 'F3',
						3 => 'F4'
					},
					wide => {0 => '1. fjórðungur',
						1 => '2. fjórðungur',
						2 => '3. fjórðungur',
						3 => '4. fjórðungur'
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					'afternoon1' => q{síðdegis},
					'am' => q{f.h.},
					'evening1' => q{að kvöldi},
					'midnight' => q{miðnætti},
					'morning1' => q{að morgni},
					'night1' => q{að nóttu},
					'noon' => q{hádegi},
					'pm' => q{e.h.},
				},
				'narrow' => {
					'afternoon1' => q{sd.},
					'am' => q{f.},
					'evening1' => q{kv.},
					'midnight' => q{mn.},
					'morning1' => q{mrg.},
					'night1' => q{n.},
					'noon' => q{h.},
					'pm' => q{e.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{síðdegis},
					'evening1' => q{kvöld},
					'morning1' => q{morgunn},
					'night1' => q{nótt},
				},
				'narrow' => {
					'afternoon1' => q{sd.},
					'evening1' => q{kv.},
					'midnight' => q{mn.},
					'morning1' => q{mrg.},
					'night1' => q{n.},
					'noon' => q{hd.},
				},
				'wide' => {
					'afternoon1' => q{eftir hádegi},
					'evening1' => q{kvöld},
					'morning1' => q{morgunn},
					'night1' => q{nótt},
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
				'0' => 'BD'
			},
			wide => {
				'0' => 'búddhadagatal'
			},
		},
		'coptic' => {
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'Tímabil0',
				'1' => 'Tímabil1'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			narrow => {
				'0' => 'f.k.',
				'1' => 'e.k.'
			},
			wide => {
				'0' => 'fyrir Krist',
				'1' => 'eftir Krist'
			},
		},
		'hebrew' => {
			wide => {
				'0' => 'Anno Mundi'
			},
		},
		'indian' => {
		},
		'islamic' => {
			abbreviated => {
				'0' => 'EH'
			},
			wide => {
				'0' => 'eftir Hijra'
			},
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'fyrir lýðv. Kína',
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'fyrir lv.K.'
			},
			wide => {
				'0' => 'fyrir lýðveldi Kína'
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
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{d.M.y},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y G},
			yyyyMEd => q{E, d.M.y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d/M/y GGGGG},
			Hmsv => q{v – HH:mm:ss},
			Hmv => q{v – HH:mm},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{'viku' W 'í' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M. y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'viku' w 'af' Y},
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
		'buddhist' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y – MM.y GGGGG},
				y => q{MM.y – MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y – dd.MM.y GGGGG},
				d => q{dd.MM.y – dd.MM.y GGGGG},
				y => q{dd.MM.y – dd.MM.y GGGGG},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y – MM.y GGGGG},
				y => q{MM.y – MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. MMM – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y – dd.MM.y GGGGG},
				d => q{dd.MM.y – dd.MM.y GGGGG},
				y => q{dd.MM.y – dd.MM.y GGGGG},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.M.–d.M.},
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
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{M.y – M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y},
				d => q{E, d.M.y – E, d.M.y},
				y => q{E, d.M.y – E, d.M.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d.M.y – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} (sumartími)),
		regionFormat => q({0} (staðaltími)),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistantími#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algeirsborg#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissá#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kaíró#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibútí#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Jóhannesarborg#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Saó Tóme#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípólí#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnisborg#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Mið-Afríkutími#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Austur-Afríkutími#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Suður-Afríkutími#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Sumartími í Vestur-Afríku#,
				'generic' => q#Vestur-Afríkutími#,
				'standard' => q#Staðaltími í Vestur-Afríku#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Sumartími í Alaska#,
				'generic' => q#Tími í Alaska#,
				'standard' => q#Staðaltími í Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Sumartími á Amasónsvæðinu#,
				'generic' => q#Amasóntími#,
				'standard' => q#Staðaltími á Amasónsvæðinu#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Angvilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antígva#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arúba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Belís#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankún#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman-eyjar#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostaríka#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dóminíka#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gvadelúp#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gvæjana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaíka#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martiník#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexíkóborg#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Púertó Ríkó#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sankti Bartólómeusareyjar#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sankti Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sankti Lúsía#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sankti Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sankti Vinsent#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortóla#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Sumartími í miðhluta Bandaríkjanna og Kanada#,
				'generic' => q#Tími í miðhluta Bandaríkjanna og Kanada#,
				'standard' => q#Staðaltími í miðhluta Bandaríkjanna og Kanada#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Sumartími í austurhluta Bandaríkjanna og Kanada#,
				'generic' => q#Tími í austurhluta Bandaríkjanna og Kanada#,
				'standard' => q#Staðaltími í austurhluta Bandaríkjanna og Kanada#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Sumartími í Klettafjöllum#,
				'generic' => q#Tími í Klettafjöllum#,
				'standard' => q#Staðaltími í Klettafjöllum#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Sumartími á Kyrrahafssvæðinu#,
				'generic' => q#Tími á Kyrrahafssvæðinu#,
				'standard' => q#Staðaltími á Kyrrahafssvæðinu#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Sumartími í Anadyr#,
				'generic' => q#Tími í Anadyr#,
				'standard' => q#Staðaltími í Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Sumartími í Apía#,
				'generic' => q#Tími í Apía#,
				'standard' => q#Staðaltími í Apía#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Sumartími í Arabíu#,
				'generic' => q#Arabíutími#,
				'standard' => q#Staðaltími í Arabíu#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Sumartími í Argentínu#,
				'generic' => q#Argentínutími#,
				'standard' => q#Staðaltími í Argentínu#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Sumartími í Vestur-Argentínu#,
				'generic' => q#Vestur-Argentínutími#,
				'standard' => q#Staðaltími í Vestur-Argentínu#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Sumartími í Armeníu#,
				'generic' => q#Armeníutími#,
				'standard' => q#Staðaltími í Armeníu#,
			},
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakú#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirút#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brúnei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkútta#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kólombó#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dakka#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Djakarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerúsalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabúl#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kúala Lúmpúr#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kúveit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makaó#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Níkósía#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Ríjad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh-borg#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seúl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Sjanghæ#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapúr#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tókýó#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Úlan Bator#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Sumartími á Atlantshafssvæðinu#,
				'generic' => q#Tími á Atlantshafssvæðinu#,
				'standard' => q#Staðaltími á Atlantshafssvæðinu#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoreyjar#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermúda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaríeyjar#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Grænhöfðaeyjar#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Færeyjar#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Suður-Georgía#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sankti Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Sumartími í Mið-Ástralíu#,
				'generic' => q#Tími í Mið-Ástralíu#,
				'standard' => q#Staðaltími í Mið-Ástralíu#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Sumartími í miðvesturhluta Ástralíu#,
				'generic' => q#Tími í miðvesturhluta Ástralíu#,
				'standard' => q#Staðaltími í miðvesturhluta Ástralíu#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Sumartími í Austur-Ástralíu#,
				'generic' => q#Tími í Austur-Ástralíu#,
				'standard' => q#Staðaltími í Austur-Ástralíu#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Sumartími í Vestur-Ástralíu#,
				'generic' => q#Tími í Vestur-Ástralíu#,
				'standard' => q#Staðaltími í Vestur-Ástralíu#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Sumartími í Aserbaídsjan#,
				'generic' => q#Aserbaídsjantími#,
				'standard' => q#Staðaltími í Aserbaídsjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Sumartími á Asóreyjum#,
				'generic' => q#Asóreyjatími#,
				'standard' => q#Staðaltími á Asóreyjum#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Sumartími í Bangladess#,
				'generic' => q#Bangladess-tími#,
				'standard' => q#Staðaltími í Bangladess#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bútantími#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bólivíutími#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Sumartími í Brasilíu#,
				'generic' => q#Brasilíutími#,
				'standard' => q#Staðaltími í Brasilíu#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brúneitími#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Sumartími á Grænhöfðaeyjum#,
				'generic' => q#Grænhöfðaeyjatími#,
				'standard' => q#Staðaltími á Grænhöfðaeyjum#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-staðaltími#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Sumartími í Chatham#,
				'generic' => q#Chatham-tími#,
				'standard' => q#Staðaltími í Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Sumartími í Síle#,
				'generic' => q#Síletími#,
				'standard' => q#Staðaltími í Síle#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Sumartími í Kína#,
				'generic' => q#Kínatími#,
				'standard' => q#Staðaltími í Kína#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Sumartími í Choibalsan#,
				'generic' => q#Tími í Choibalsan#,
				'standard' => q#Staðaltími í Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Jólaeyjartími#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kókoseyjatími#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Sumartími í Kólumbíu#,
				'generic' => q#Kólumbíutími#,
				'standard' => q#Staðaltími í Kólumbíu#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Hálfsumartími á Cooks-eyjum#,
				'generic' => q#Cooks-eyjatími#,
				'standard' => q#Staðaltími á Cooks-eyjum#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Sumartími á Kúbu#,
				'generic' => q#Kúbutími#,
				'standard' => q#Staðaltími á Kúbu#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis-tími#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Tími á Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Tími á Tímor-Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Sumartími á Páskaeyju#,
				'generic' => q#Páskaeyjutími#,
				'standard' => q#Staðaltími á Páskaeyju#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvadortími#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Samræmdur alþjóðlegur tími#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Óþekkt borg#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aþena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Búkarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Búdapest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kaupmannahöfn#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Sumartími á Írlandi#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gíbraltar#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mön#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbúl#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kænugarður#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			exemplarCity => q#Lundúnir#,
			long => {
				'daylight' => q#Sumartími í Bretlandi#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lúxemborg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madríd#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Maríuhöfn#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mónakó#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Osló#,
		},
		'Europe/Paris' => {
			exemplarCity => q#París#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Róm#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marínó#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevó#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sófía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokkhólmur#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tírana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatíkanið#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vín#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilníus#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsjá#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Sumartími í Mið-Evrópu#,
				'generic' => q#Mið-Evróputími#,
				'standard' => q#Staðaltími í Mið-Evrópu#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Sumartími í Austur-Evrópu#,
				'generic' => q#Austur-Evróputími#,
				'standard' => q#Staðaltími í Austur-Evrópu#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Staðartími Kalíníngrad#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Sumartími í Vestur-Evrópu#,
				'generic' => q#Vestur-Evróputími#,
				'standard' => q#Staðaltími í Vestur-Evrópu#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Sumartími á Falklandseyjum#,
				'generic' => q#Falklandseyjatími#,
				'standard' => q#Staðaltími á Falklandseyjum#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Sumartími á Fídjíeyjum#,
				'generic' => q#Fídjíeyjatími#,
				'standard' => q#Staðaltími á Fídjíeyjum#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Tími í Frönsku Gvæjana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Tími á frönsku suðurhafssvæðum og Suðurskautslandssvæði#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich-staðaltími#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos-tími#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier-tími#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Sumartími í Georgíu#,
				'generic' => q#Georgíutími#,
				'standard' => q#Staðaltími í Georgíu#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Tími á Gilbert-eyjum#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Sumartími á Austur-Grænlandi#,
				'generic' => q#Austur-Grænlandstími#,
				'standard' => q#Staðaltími á Austur-Grænlandi#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Sumartími á Vestur-Grænlandi#,
				'generic' => q#Vestur-Grænlandstími#,
				'standard' => q#Staðaltími á Vestur-Grænlandi#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Staðaltími við Persaflóa#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gvæjanatími#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Sumartími á Havaí og Aleúta#,
				'generic' => q#Tími á Havaí og Aleúta#,
				'standard' => q#Staðaltími á Havaí og Aleúta#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Sumartími í Hong Kong#,
				'generic' => q#Hong Kong-tími#,
				'standard' => q#Staðaltími í Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Sumartími í Hovd#,
				'generic' => q#Hovd-tími#,
				'standard' => q#Staðaltími í Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indlandstími#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Jólaey#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kókoseyjar#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldíveyjar#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Máritíus#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indlandshafstími#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indókínatími#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Mið-Indónesíutími#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Austur-Indónesíutími#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Vestur-Indónesíutími#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Sumartími í Íran#,
				'generic' => q#Íranstími#,
				'standard' => q#Staðaltími í Íran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Sumartími í Irkutsk#,
				'generic' => q#Tími í Irkutsk#,
				'standard' => q#Staðaltími í Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Sumartími í Ísrael#,
				'generic' => q#Ísraelstími#,
				'standard' => q#Staðaltími í Ísrael#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Sumartími í Japan#,
				'generic' => q#Japanstími#,
				'standard' => q#Staðaltími í Japan#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Sumartími í Petropavlovsk-Kamchatski#,
				'generic' => q#Tími í Petropavlovsk-Kamchatski#,
				'standard' => q#Staðaltími í Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Tími í Austur-Kasakstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Tími í Vestur-Kasakstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Sumartími í Kóreu#,
				'generic' => q#Kóreutími#,
				'standard' => q#Staðaltími í Kóreu#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae-tími#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Sumartími í Krasnoyarsk#,
				'generic' => q#Tími í Krasnoyarsk#,
				'standard' => q#Staðaltími í Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistan-tími#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Línueyja-tími#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Sumartími á Lord Howe-eyju#,
				'generic' => q#Tími á Lord Howe-eyju#,
				'standard' => q#Staðaltími á Lord Howe-eyju#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie-eyjartími#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Sumartími í Magadan#,
				'generic' => q#Tími í Magadan#,
				'standard' => q#Staðaltími í Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malasíutími#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldíveyja-tími#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Tími á Markgreifafrúreyjum#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Tími á Marshall-eyjum#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Sumartími á Máritíus#,
				'generic' => q#Máritíustími#,
				'standard' => q#Staðaltími á Máritíus#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson-tími#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Sumartími í Norðvestur-Mexíkó#,
				'generic' => q#Tími í Norðvestur-Mexíkó#,
				'standard' => q#Staðaltími í Norðvestur-Mexíkó#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Sumartími í Mexíkó á Kyrrahafssvæðinu#,
				'generic' => q#Kyrrahafstími í Mexíkó#,
				'standard' => q#Staðaltími í Mexíkó á Kyrrahafssvæðinu#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Sumartími í Úlan Bator#,
				'generic' => q#Tími í Úlan Bator#,
				'standard' => q#Staðaltími í Úlan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Sumartími í Moskvu#,
				'generic' => q#Moskvutími#,
				'standard' => q#Staðaltími í Moskvu#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mjanmar-tími#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nárú-tími#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepaltími#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Sumartími í Nýju-Kaledóníu#,
				'generic' => q#Tími í Nýju-Kaledóníu#,
				'standard' => q#Staðaltími í Nýju-Kaledóníu#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Sumartími á Nýja-Sjálandi#,
				'generic' => q#Tími á Nýja-Sjálandi#,
				'standard' => q#Staðaltími á Nýja-Sjálandi#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Sumartími á Nýfundnalandi#,
				'generic' => q#Tími á Nýfundnalandi#,
				'standard' => q#Staðaltími á Nýfundnalandi#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue-tími#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Sumartími á Norfolk-eyju#,
				'generic' => q#Tími á Norfolk-eyju#,
				'standard' => q#Staðaltími á Norfolk-eyju#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Sumartími í Fernando de Noronha#,
				'generic' => q#Tími í Fernando de Noronha#,
				'standard' => q#Staðaltími í Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Sumartími í Novosibirsk#,
				'generic' => q#Tími í Novosibirsk#,
				'standard' => q#Staðaltími í Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Sumartími í Omsk#,
				'generic' => q#Tími í Omsk#,
				'standard' => q#Staðaltími í Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Páskaeyja#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fídjí#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Gvam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas-eyjar#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nárú#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palá#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahítí#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Sumartími í Pakistan#,
				'generic' => q#Pakistantími#,
				'standard' => q#Staðaltími í Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palátími#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Tími á Papúa Nýju-Gíneu#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Sumartími í Paragvæ#,
				'generic' => q#Paragvætími#,
				'standard' => q#Staðaltími í Paragvæ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Sumartími í Perú#,
				'generic' => q#Perútími#,
				'standard' => q#Staðaltími í Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Sumartími á Filippseyjum#,
				'generic' => q#Filippseyjatími#,
				'standard' => q#Staðaltími á Filippseyjum#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Fönixeyjatími#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sumartími á Sankti Pierre og Miquelon#,
				'generic' => q#Tími á Sankti Pierre og Miquelon#,
				'standard' => q#Staðaltími á Sankti Pierre og Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn-tími#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape-tími#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Tími í Pjongjang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion-tími#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera-tími#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sumartími í Sakhalin#,
				'generic' => q#Tími í Sakhalin#,
				'standard' => q#Staðaltími í Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Sumartími í Samara#,
				'generic' => q#Tími í Samara#,
				'standard' => q#Staðaltími í Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Sumartími á Samóa#,
				'generic' => q#Samóa-tími#,
				'standard' => q#Staðaltími á Samóa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelles-eyjatími#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapúrtími#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salómonseyjatími#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Suður-Georgíutími#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Súrinamtími#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa-tími#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahítí-tími#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Sumartími í Taipei#,
				'generic' => q#Taipei-tími#,
				'standard' => q#Staðaltími í Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadsjíkistan-tími#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tókelá-tími#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Sumartími á Tonga#,
				'generic' => q#Tongatími#,
				'standard' => q#Staðaltími á Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk-tími#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Sumartími í Túrkmenistan#,
				'generic' => q#Túrkmenistan-tími#,
				'standard' => q#Staðaltími í Túrkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Túvalútími#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Sumartími í Úrúgvæ#,
				'generic' => q#Úrúgvætími#,
				'standard' => q#Staðaltími í Úrúgvæ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Sumartími í Úsbekistan#,
				'generic' => q#Úsbekistan-tími#,
				'standard' => q#Staðaltími í Úsbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Sumartími á Vanúatú#,
				'generic' => q#Vanúatú-tími#,
				'standard' => q#Staðaltími á Vanúatú#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venesúelatími#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Sumartími í Vladivostok#,
				'generic' => q#Tími í Vladivostok#,
				'standard' => q#Staðaltími í Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Sumartími í Volgograd#,
				'generic' => q#Tími í Volgograd#,
				'standard' => q#Staðaltími í Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok-tími#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Tími á Wake-eyju#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Tími á Wallis- og Fútúnaeyjum#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Sumartími í Yakutsk#,
				'generic' => q#Tími í Yakutsk#,
				'standard' => q#Staðaltími í Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Sumartími í Yekaterinburg#,
				'generic' => q#Tími í Yekaterinburg#,
				'standard' => q#Staðaltími í Yekaterinborg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Tími í Júkon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
