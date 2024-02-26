=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cs - Package for language Czech

=cut

package Locale::CLDR::Locales::Cs;
# This file auto generated from Data\common\main\cs.xml
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
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← čárka →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dvě),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←cet[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(padesát[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šedesát[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedmdesát[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osmdesát[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devadesát[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← stě[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← sta[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← set[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíce[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milión[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milióny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miliónů[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardů[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilión[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilióny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biliónů[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardů[ →→]),
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
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← čárka →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jeden),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dva),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tři),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(čtyři),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pět),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(šest),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sedm),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osm),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(devět),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deset),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(jedenáct),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dvanáct),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(třináct),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(čtrnáct),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(patnáct),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(šestnáct),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sedmnáct),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(osmnáct),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(devatenáct),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←cet[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(padesát[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šedesát[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedmdesát[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osmdesát[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devadesát[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← stě[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← sta[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← set[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíce[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milión[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milióny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miliónů[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardů[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilión[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilióny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biliónů[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardů[ →→]),
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
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← čárka →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dvě),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←cet[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(padesát[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šedesát[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedmdesát[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osmdesát[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devadesát[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← stě[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← sta[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine← set[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíce[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milión[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milióny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miliónů[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardů[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilión[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilióny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biliónů[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardů[ →→]),
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
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afarština',
 				'ab' => 'abcházština',
 				'ace' => 'acehština',
 				'ach' => 'akolština',
 				'ada' => 'adangme',
 				'ady' => 'adygejština',
 				'ae' => 'avestánština',
 				'aeb' => 'arabština (tuniská)',
 				'af' => 'afrikánština',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainština',
 				'ak' => 'akanština',
 				'akk' => 'akkadština',
 				'akz' => 'alabamština',
 				'ale' => 'aleutština',
 				'aln' => 'albánština (Gheg)',
 				'alt' => 'altajština (jižní)',
 				'am' => 'amharština',
 				'an' => 'aragonština',
 				'ang' => 'staroangličtina',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabština',
 				'ar_001' => 'arabština (moderní standardní)',
 				'arc' => 'aramejština',
 				'arn' => 'mapudungun',
 				'aro' => 'araonština',
 				'arp' => 'arapažština',
 				'arq' => 'arabština (alžírská)',
 				'ars' => 'arabština (Nadžd)',
 				'arw' => 'arawacké jazyky',
 				'ary' => 'arabština (marocká)',
 				'arz' => 'arabština (egyptská)',
 				'as' => 'ásámština',
 				'asa' => 'asu',
 				'ase' => 'znaková řeč (americká)',
 				'ast' => 'asturština',
 				'atj' => 'atikamekština',
 				'av' => 'avarština',
 				'avk' => 'kotava',
 				'awa' => 'awadhština',
 				'ay' => 'ajmarština',
 				'az' => 'ázerbájdžánština',
 				'az@alt=short' => 'azerština',
 				'ba' => 'baškirština',
 				'bal' => 'balúčština',
 				'ban' => 'balijština',
 				'bar' => 'bavorština',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'bbc' => 'batak toba',
 				'bbj' => 'ghomala',
 				'be' => 'běloruština',
 				'bej' => 'bedža',
 				'bem' => 'bembština',
 				'bew' => 'batavština',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'badagština',
 				'bg' => 'bulharština',
 				'bgc' => 'harijánština',
 				'bgn' => 'balúčština (západní)',
 				'bho' => 'bhódžpurština',
 				'bi' => 'bislamština',
 				'bik' => 'bikolština',
 				'bin' => 'bini',
 				'bjn' => 'bandžarština',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambarština',
 				'bn' => 'bengálština',
 				'bo' => 'tibetština',
 				'bpy' => 'bišnuprijskomanipurština',
 				'bqi' => 'bachtijárština',
 				'br' => 'bretonština',
 				'bra' => 'bradžština',
 				'brh' => 'brahujština',
 				'brx' => 'bodoština',
 				'bs' => 'bosenština',
 				'bss' => 'akoose',
 				'bua' => 'burjatština',
 				'bug' => 'bugiština',
 				'bum' => 'bulu',
 				'byn' => 'blinština',
 				'byv' => 'medumba',
 				'ca' => 'katalánština',
 				'cad' => 'caddo',
 				'car' => 'karibština',
 				'cay' => 'kajugština',
 				'cch' => 'atsam',
 				'ccp' => 'čakma',
 				'ce' => 'čečenština',
 				'ceb' => 'cebuánština',
 				'cgg' => 'kiga',
 				'ch' => 'čamoro',
 				'chb' => 'čibča',
 				'chg' => 'čagatajština',
 				'chk' => 'čukština',
 				'chm' => 'marijština',
 				'chn' => 'činuk pidžin',
 				'cho' => 'čoktština',
 				'chp' => 'čipevajština',
 				'chr' => 'čerokézština',
 				'chy' => 'čejenština',
 				'ckb' => 'kurdština (sorání)',
 				'ckb@alt=menu' => 'kurdština (centrální)',
 				'clc' => 'čilkotinština',
 				'co' => 'korsičtina',
 				'cop' => 'koptština',
 				'cps' => 'kapiznonština',
 				'cr' => 'kríjština',
 				'crg' => 'mičif',
 				'crh' => 'tatarština (krymská)',
 				'crj' => 'kríjština (jihovýchodní)',
 				'crk' => 'kríjština (z plání)',
 				'crl' => 'kríjština (severovýchodní)',
 				'crm' => 'kríjština (Moose)',
 				'crr' => 'algonkinština (Karolína)',
 				'crs' => 'kreolština (seychelská)',
 				'cs' => 'čeština',
 				'csb' => 'kašubština',
 				'csw' => 'kríjština (z bažin)',
 				'cu' => 'staroslověnština',
 				'cv' => 'čuvaština',
 				'cy' => 'velština',
 				'da' => 'dánština',
 				'dak' => 'dakotština',
 				'dar' => 'dargština',
 				'dav' => 'taita',
 				'de' => 'němčina',
 				'de_CH' => 'němčina standardní (Švýcarsko)',
 				'del' => 'delawarština',
 				'den' => 'slejvština (athabaský jazyk)',
 				'dgr' => 'dogrib',
 				'din' => 'dinkština',
 				'dje' => 'zarmština',
 				'doi' => 'dogarština',
 				'dsb' => 'dolnolužická srbština',
 				'dtp' => 'kadazandusunština',
 				'dua' => 'dualština',
 				'dum' => 'holandština (středověká)',
 				'dv' => 'maledivština',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'djula',
 				'dz' => 'dzongkä',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'eweština',
 				'efi' => 'efikština',
 				'egl' => 'emilijština',
 				'egy' => 'egyptština stará',
 				'eka' => 'ekajuk',
 				'el' => 'řečtina',
 				'elx' => 'elamitština',
 				'en' => 'angličtina',
 				'en_GB' => 'angličtina (Velká Británie)',
 				'en_GB@alt=short' => 'angličtina (VB)',
 				'en_US' => 'angličtina (USA)',
 				'enm' => 'angličtina (středověká)',
 				'eo' => 'esperanto',
 				'es' => 'španělština',
 				'es_ES' => 'španělština (Evropa)',
 				'esu' => 'jupikština (středoaljašská)',
 				'et' => 'estonština',
 				'eu' => 'baskičtina',
 				'ewo' => 'ewondo',
 				'ext' => 'extremadurština',
 				'fa' => 'perština',
 				'fa_AF' => 'darí',
 				'fan' => 'fang',
 				'fat' => 'fantština',
 				'ff' => 'fulbština',
 				'fi' => 'finština',
 				'fil' => 'filipínština',
 				'fit' => 'finština (tornedalská)',
 				'fj' => 'fidžijština',
 				'fo' => 'faerština',
 				'fon' => 'fonština',
 				'fr' => 'francouzština',
 				'frc' => 'francouzština (cajunská)',
 				'frm' => 'francouzština (středověká)',
 				'fro' => 'francouzština (stará)',
 				'frp' => 'franko-provensálština',
 				'frr' => 'fríština (severní)',
 				'frs' => 'fríština (východní)',
 				'fur' => 'furlanština',
 				'fy' => 'fríština (západní)',
 				'ga' => 'irština',
 				'gaa' => 'gaština',
 				'gag' => 'gagauzština',
 				'gan' => 'čínština (dialekty Gan)',
 				'gay' => 'gayo',
 				'gba' => 'gbaja',
 				'gbz' => 'daríjština (zoroastrijská)',
 				'gd' => 'skotská gaelština',
 				'gez' => 'geez',
 				'gil' => 'kiribatština',
 				'gl' => 'galicijština',
 				'glk' => 'gilačtina',
 				'gmh' => 'hornoněmčina (středověká)',
 				'gn' => 'guaranština',
 				'goh' => 'hornoněmčina (stará)',
 				'gom' => 'konkánština (Goa)',
 				'gon' => 'góndština',
 				'gor' => 'gorontalo',
 				'got' => 'gótština',
 				'grb' => 'grebo',
 				'grc' => 'starořečtina',
 				'gsw' => 'němčina (Švýcarsko)',
 				'gu' => 'gudžarátština',
 				'guc' => 'wayúuština',
 				'gur' => 'frafra',
 				'guz' => 'gusii',
 				'gv' => 'manština',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hauština',
 				'hai' => 'haidština',
 				'hak' => 'čínština (dialekty Hakka)',
 				'haw' => 'havajština',
 				'hax' => 'haidština (jižní)',
 				'he' => 'hebrejština',
 				'hi' => 'hindština',
 				'hi_Latn@alt=variant' => 'hingliš',
 				'hif' => 'hindština (Fidži)',
 				'hil' => 'hiligajnonština',
 				'hit' => 'chetitština',
 				'hmn' => 'hmongština',
 				'ho' => 'hiri motu',
 				'hr' => 'chorvatština',
 				'hsb' => 'hornolužická srbština',
 				'hsn' => 'čínština (dialekty Xiang)',
 				'ht' => 'haitština',
 				'hu' => 'maďarština',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'arménština',
 				'hz' => 'hererština',
 				'ia' => 'interlingua',
 				'iba' => 'ibanština',
 				'ibb' => 'ibibio',
 				'id' => 'indonéština',
 				'ie' => 'interlingue',
 				'ig' => 'igboština',
 				'ii' => 'iština (sečuánská)',
 				'ik' => 'inupiakština',
 				'ikt' => 'inuktitutština (západokanadská)',
 				'ilo' => 'ilokánština',
 				'inh' => 'inguština',
 				'io' => 'ido',
 				'is' => 'islandština',
 				'it' => 'italština',
 				'iu' => 'inuktitutština',
 				'izh' => 'ingrijština',
 				'ja' => 'japonština',
 				'jam' => 'jamajská kreolština',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'mašame',
 				'jpr' => 'judeoperština',
 				'jrb' => 'judeoarabština',
 				'jut' => 'jutština',
 				'jv' => 'javánština',
 				'ka' => 'gruzínština',
 				'kaa' => 'karakalpačtina',
 				'kab' => 'kabylština',
 				'kac' => 'kačijština',
 				'kaj' => 'jju',
 				'kam' => 'kambština',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardinština',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kapverdština',
 				'ken' => 'kenyang',
 				'kfo' => 'koro',
 				'kg' => 'konžština',
 				'kgp' => 'kaingang',
 				'kha' => 'khásí',
 				'kho' => 'chotánština',
 				'khq' => 'koyra chiini',
 				'khw' => 'chovarština',
 				'ki' => 'kikujština',
 				'kiu' => 'zazakština',
 				'kj' => 'kuaňamština',
 				'kk' => 'kazaština',
 				'kkj' => 'kako',
 				'kl' => 'grónština',
 				'kln' => 'kalendžin',
 				'km' => 'khmérština',
 				'kmb' => 'kimbundština',
 				'kn' => 'kannadština',
 				'ko' => 'korejština',
 				'koi' => 'komi-permjačtina',
 				'kok' => 'konkánština',
 				'kos' => 'kosrajština',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karačajevo-balkarština',
 				'kri' => 'krio',
 				'krj' => 'kinaraj-a',
 				'krl' => 'karelština',
 				'kru' => 'kuruchština',
 				'ks' => 'kašmírština',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kolínština',
 				'ku' => 'kurdština',
 				'kum' => 'kumyčtina',
 				'kut' => 'kutenajština',
 				'kv' => 'komijština',
 				'kw' => 'kornština',
 				'kwk' => 'kvakiutština',
 				'ky' => 'kyrgyzština',
 				'la' => 'latina',
 				'lad' => 'ladinština',
 				'lag' => 'langi',
 				'lah' => 'lahndština',
 				'lam' => 'lambština',
 				'lb' => 'lucemburština',
 				'lez' => 'lezginština',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'gandština',
 				'li' => 'limburština',
 				'lij' => 'ligurština',
 				'lil' => 'lillooetština',
 				'liv' => 'livonština',
 				'lkt' => 'lakotština',
 				'lmo' => 'lombardština',
 				'ln' => 'lingalština',
 				'lo' => 'laoština',
 				'lol' => 'mongština',
 				'lou' => 'kreolština (Louisiana)',
 				'loz' => 'lozština',
 				'lrc' => 'lúrština (severní)',
 				'lsm' => 'samia',
 				'lt' => 'litevština',
 				'ltg' => 'latgalština',
 				'lu' => 'lubu-katanžština',
 				'lua' => 'luba-luluaština',
 				'lui' => 'luiseňo',
 				'lun' => 'lundština',
 				'luo' => 'luoština',
 				'lus' => 'mizoština',
 				'luy' => 'luhja',
 				'lv' => 'lotyština',
 				'lzh' => 'čínština (klasická)',
 				'lzz' => 'lazština',
 				'mad' => 'madurština',
 				'maf' => 'mafa',
 				'mag' => 'magahijština',
 				'mai' => 'maithiliština',
 				'mak' => 'makasarština',
 				'man' => 'mandingština',
 				'mas' => 'masajština',
 				'mde' => 'maba',
 				'mdf' => 'mokšanština',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauricijská kreolština',
 				'mg' => 'malgaština',
 				'mga' => 'irština (středověká)',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'maršálština',
 				'mi' => 'maorština',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedonština',
 				'ml' => 'malajálamština',
 				'mn' => 'mongolština',
 				'mnc' => 'mandžuština',
 				'mni' => 'manipurština',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawkština',
 				'mos' => 'mosi',
 				'mr' => 'maráthština',
 				'mrj' => 'marijština (západní)',
 				'ms' => 'malajština',
 				'mt' => 'maltština',
 				'mua' => 'mundang',
 				'mul' => 'více jazyků',
 				'mus' => 'kríkština',
 				'mwl' => 'mirandština',
 				'mwr' => 'márvárština',
 				'mwv' => 'mentavajština',
 				'my' => 'barmština',
 				'mye' => 'myene',
 				'myv' => 'erzjanština',
 				'mzn' => 'mázandaránština',
 				'na' => 'naurština',
 				'nan' => 'čínština (dialekty Minnan)',
 				'nap' => 'neapolština',
 				'naq' => 'namaština',
 				'nb' => 'norština (bokmål)',
 				'nd' => 'ndebele (Zimbabwe)',
 				'nds' => 'dolnoněmčina',
 				'nds_NL' => 'dolnosaština',
 				'ne' => 'nepálština',
 				'new' => 'névárština',
 				'ng' => 'ndondština',
 				'nia' => 'nias',
 				'niu' => 'niueština',
 				'njo' => 'ao (jazyky Nágálandu)',
 				'nl' => 'nizozemština',
 				'nl_BE' => 'vlámština',
 				'nmg' => 'kwasio',
 				'nn' => 'norština (nynorsk)',
 				'nnh' => 'ngiemboon',
 				'no' => 'norština',
 				'nog' => 'nogajština',
 				'non' => 'norština historická',
 				'nov' => 'novial',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele (Jižní Afrika)',
 				'nso' => 'sotština (severní)',
 				'nus' => 'nuerština',
 				'nv' => 'navažština',
 				'nwc' => 'newarština (klasická)',
 				'ny' => 'ňandžština',
 				'nym' => 'ňamwežština',
 				'nyn' => 'ňankolština',
 				'nyo' => 'ňorština',
 				'nzi' => 'nzima',
 				'oc' => 'okcitánština',
 				'oj' => 'odžibvejština',
 				'ojb' => 'odžibvejština (severozápadní)',
 				'ojc' => 'odžibvejština (střední)',
 				'ojs' => 'odžibvejština (severní)',
 				'ojw' => 'odžibvejština (západní)',
 				'oka' => 'okanaganština',
 				'om' => 'oromština',
 				'or' => 'urijština',
 				'os' => 'osetština',
 				'osa' => 'osage',
 				'ota' => 'turečtina (osmanská)',
 				'pa' => 'paňdžábština',
 				'pag' => 'pangasinanština',
 				'pal' => 'pahlavština',
 				'pam' => 'papangau',
 				'pap' => 'papiamento',
 				'pau' => 'palauština',
 				'pcd' => 'picardština',
 				'pcm' => 'nigerijský pidžin',
 				'pdc' => 'němčina (pensylvánská)',
 				'pdt' => 'němčina (plautdietsch)',
 				'peo' => 'staroperština',
 				'pfl' => 'falčtina',
 				'phn' => 'féničtina',
 				'pi' => 'pálí',
 				'pis' => 'pidžin (Šalomounovy ostrovy)',
 				'pl' => 'polština',
 				'pms' => 'piemonština',
 				'pnt' => 'pontština',
 				'pon' => 'pohnpeiština',
 				'pqm' => 'malesitština-passamaquoddština',
 				'prg' => 'pruština',
 				'pro' => 'provensálština',
 				'ps' => 'paštština',
 				'pt' => 'portugalština',
 				'pt_PT' => 'portugalština (Evropa)',
 				'qu' => 'kečuánština',
 				'quc' => 'kičé',
 				'qug' => 'kečuánština (chimborazo)',
 				'raj' => 'rádžastánština',
 				'rap' => 'rapanujština',
 				'rar' => 'rarotongánština',
 				'rgn' => 'romaňolština',
 				'rhg' => 'rohingština',
 				'rif' => 'rífština',
 				'rm' => 'rétorománština',
 				'rn' => 'kirundština',
 				'ro' => 'rumunština',
 				'ro_MD' => 'moldavština',
 				'rof' => 'rombo',
 				'rom' => 'romština',
 				'rtm' => 'rotumanština',
 				'ru' => 'ruština',
 				'rue' => 'rusínština',
 				'rug' => 'rovianština',
 				'rup' => 'arumunština',
 				'rw' => 'kiňarwandština',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrt',
 				'sad' => 'sandawština',
 				'sah' => 'jakutština',
 				'sam' => 'samarština',
 				'saq' => 'samburu',
 				'sas' => 'sasakština',
 				'sat' => 'santálština',
 				'saz' => 'saurášterština',
 				'sba' => 'ngambay',
 				'sbp' => 'sangoština',
 				'sc' => 'sardština',
 				'scn' => 'sicilština',
 				'sco' => 'skotština',
 				'sd' => 'sindhština',
 				'sdc' => 'sassarština',
 				'sdh' => 'kurdština (jižní)',
 				'se' => 'sámština (severní)',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sei' => 'seriština',
 				'sel' => 'selkupština',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sangština',
 				'sga' => 'irština (stará)',
 				'sgs' => 'žemaitština',
 				'sh' => 'srbochorvatština',
 				'shi' => 'tašelhit',
 				'shn' => 'šanština',
 				'shu' => 'arabština (čadská)',
 				'si' => 'sinhálština',
 				'sid' => 'sidamo',
 				'sk' => 'slovenština',
 				'sl' => 'slovinština',
 				'slh' => 'lushootseed (jižní)',
 				'sli' => 'němčina (slezská)',
 				'sly' => 'selajarština',
 				'sm' => 'samojština',
 				'sma' => 'sámština (jižní)',
 				'smj' => 'sámština (lulejská)',
 				'smn' => 'sámština (inarijská)',
 				'sms' => 'sámština (skoltská)',
 				'sn' => 'šonština',
 				'snk' => 'sonikština',
 				'so' => 'somálština',
 				'sog' => 'sogdština',
 				'sq' => 'albánština',
 				'sr' => 'srbština',
 				'srn' => 'sranan tongo',
 				'srr' => 'sererština',
 				'ss' => 'siswatština',
 				'ssy' => 'saho',
 				'st' => 'sotština (jižní)',
 				'stq' => 'fríština (saterlandská)',
 				'str' => 'saliština (z úžin)',
 				'su' => 'sundština',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerština',
 				'sv' => 'švédština',
 				'sw' => 'svahilština',
 				'sw_CD' => 'svahilština (Kongo)',
 				'swb' => 'komorština',
 				'syc' => 'syrština (klasická)',
 				'syr' => 'syrština',
 				'szl' => 'slezština',
 				'ta' => 'tamilština',
 				'tce' => 'tutčonština (jižní)',
 				'tcy' => 'tuluština',
 				'te' => 'telugština',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetumština',
 				'tg' => 'tádžičtina',
 				'tgx' => 'tagiš',
 				'th' => 'thajština',
 				'tht' => 'tahltan',
 				'ti' => 'tigrinijština',
 				'tig' => 'tigrejština',
 				'tiv' => 'tivština',
 				'tk' => 'turkmenština',
 				'tkl' => 'tokelauština',
 				'tkr' => 'cachurština',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonština',
 				'tli' => 'tlingit',
 				'tly' => 'talyština',
 				'tmh' => 'tamašek',
 				'tn' => 'setswanština',
 				'to' => 'tongánština',
 				'tog' => 'tonžština (nyasa)',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turečtina',
 				'tru' => 'turojština',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakonština',
 				'tsi' => 'tsimšijské jazyky',
 				'tt' => 'tatarština',
 				'ttm' => 'tutčonština (severní)',
 				'ttt' => 'tatština',
 				'tum' => 'tumbukština',
 				'tvl' => 'tuvalština',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitština',
 				'tyv' => 'tuvinština',
 				'tzm' => 'tamazight (střední Maroko)',
 				'udm' => 'udmurtština',
 				'ug' => 'ujgurština',
 				'uga' => 'ugaritština',
 				'uk' => 'ukrajinština',
 				'umb' => 'umbundu',
 				'und' => 'neznámý jazyk',
 				'ur' => 'urdština',
 				'uz' => 'uzbečtina',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'benátština',
 				'vep' => 'vepština',
 				'vi' => 'vietnamština',
 				'vls' => 'vlámština (západní)',
 				'vmf' => 'němčina (mohansko-franské dialekty)',
 				'vo' => 'volapük',
 				'vot' => 'votština',
 				'vro' => 'võruština',
 				'vun' => 'vunjo',
 				'wa' => 'valonština',
 				'wae' => 'němčina (walser)',
 				'wal' => 'wolajtština',
 				'war' => 'warajština',
 				'was' => 'waština',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolofština',
 				'wuu' => 'čínština (dialekty Wu)',
 				'xal' => 'kalmyčtina',
 				'xh' => 'xhoština',
 				'xmf' => 'mingrelština',
 				'xog' => 'sogština',
 				'yao' => 'jaoština',
 				'yap' => 'japština',
 				'yav' => 'jangbenština',
 				'ybb' => 'yemba',
 				'yi' => 'jidiš',
 				'yo' => 'jorubština',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantonština',
 				'yue@alt=menu' => 'čínština (kantonština)',
 				'za' => 'čuangština',
 				'zap' => 'zapotéčtina',
 				'zbl' => 'bliss systém',
 				'zea' => 'zélandština',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight (standardní marocký)',
 				'zh' => 'čínština',
 				'zh@alt=menu' => 'standardní čínština',
 				'zh_Hans' => 'čínština (zjednodušená)',
 				'zh_Hans@alt=long' => 'standardní čínština (zjednodušená)',
 				'zh_Hant@alt=long' => 'standardní čínština (tradiční)',
 				'zu' => 'zuluština',
 				'zun' => 'zunijština',
 				'zxx' => 'žádný jazykový obsah',
 				'zza' => 'zaza',

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
 			'Afak' => 'afaka',
 			'Aghb' => 'kavkazskoalbánské',
 			'Arab' => 'arabské',
 			'Arab@alt=variant' => 'persko-arabské',
 			'Aran' => 'nastalik',
 			'Armi' => 'aramejské (imperiální)',
 			'Armn' => 'arménské',
 			'Avst' => 'avestánské',
 			'Bali' => 'balijské',
 			'Bamu' => 'bamumské',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batacké',
 			'Beng' => 'bengálské',
 			'Blis' => 'Blissovo písmo',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'bráhmí',
 			'Brai' => 'Braillovo písmo',
 			'Bugi' => 'buginské',
 			'Buhd' => 'buhidské',
 			'Cakm' => 'čakma',
 			'Cans' => 'slabičné písmo kanadských domorodců',
 			'Cari' => 'karijské',
 			'Cham' => 'čam',
 			'Cher' => 'čerokí',
 			'Cirt' => 'kirt',
 			'Copt' => 'koptské',
 			'Cprt' => 'kyperské',
 			'Cyrl' => 'cyrilice',
 			'Cyrs' => 'cyrilce - staroslověnská',
 			'Deva' => 'dévanágarí',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'Duployého těsnopis',
 			'Egyd' => 'egyptské démotické',
 			'Egyh' => 'egyptské hieratické',
 			'Egyp' => 'egyptské hieroglyfy',
 			'Elba' => 'elbasanské',
 			'Ethi' => 'etiopské',
 			'Geok' => 'gruzínské chutsuri',
 			'Geor' => 'gruzínské',
 			'Glag' => 'hlaholice',
 			'Gong' => 'gundžala gondí',
 			'Goth' => 'gotické',
 			'Gran' => 'grantha',
 			'Grek' => 'řecké',
 			'Gujr' => 'gudžarátí',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunóo',
 			'Hans' => 'zjednodušené',
 			'Hans@alt=stand-alone' => 'han (zjednodušené)',
 			'Hant' => 'tradiční',
 			'Hant@alt=stand-alone' => 'han (tradiční)',
 			'Hebr' => 'hebrejské',
 			'Hira' => 'hiragana',
 			'Hluw' => 'anatolské hieroglyfy',
 			'Hmng' => 'hmongské',
 			'Hmnp' => 'nyiakeng puachue hmong',
 			'Hrkt' => 'japonské slabičné',
 			'Hung' => 'staromaďarské',
 			'Inds' => 'harappské',
 			'Ital' => 'etruské',
 			'Jamo' => 'jamo',
 			'Java' => 'javánské',
 			'Jpan' => 'japonské',
 			'Jurc' => 'džürčenské',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kháróšthí',
 			'Khmr' => 'khmerské',
 			'Khoj' => 'chodžiki',
 			'Knda' => 'kannadské',
 			'Kore' => 'korejské',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laoské',
 			'Latf' => 'latinka - lomená',
 			'Latg' => 'latinka - galská',
 			'Latn' => 'latinka',
 			'Lepc' => 'lepčské',
 			'Limb' => 'limbu',
 			'Lina' => 'lineární A',
 			'Linb' => 'lineární B',
 			'Lisu' => 'Fraserovo',
 			'Loma' => 'loma',
 			'Lyci' => 'lýkijské',
 			'Lydi' => 'lýdské',
 			'Mahj' => 'mahádžaní',
 			'Mand' => 'mandejské',
 			'Mani' => 'manichejské',
 			'Maya' => 'mayské hieroglyfy',
 			'Mend' => 'mendské',
 			'Merc' => 'meroitické psací',
 			'Mero' => 'meroitické',
 			'Mlym' => 'malajlámské',
 			'Modi' => 'modí',
 			'Mong' => 'mongolské',
 			'Moon' => 'Moonovo písmo',
 			'Mroo' => 'mro',
 			'Mtei' => 'mejtej majek (manipurské)',
 			'Mymr' => 'myanmarské',
 			'Narb' => 'staroseveroarabské',
 			'Nbat' => 'nabatejské',
 			'Nkgb' => 'naxi geba',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nü-šu',
 			'Ogam' => 'ogamské',
 			'Olck' => 'santálské (ol chiki)',
 			'Orkh' => 'orchonské',
 			'Orya' => 'urijské',
 			'Osma' => 'osmanské',
 			'Palm' => 'palmýrské',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'staropermské',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavské klínové',
 			'Phlp' => 'pahlavské žalmové',
 			'Phlv' => 'pahlavské knižní',
 			'Phnx' => 'fénické',
 			'Plrd' => 'Pollardova fonetická abeceda',
 			'Prti' => 'parthské klínové',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'redžanské',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runové',
 			'Samr' => 'samařské',
 			'Sara' => 'sarati',
 			'Sarb' => 'starojihoarabské',
 			'Saur' => 'saurášterské',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'Shawova abeceda',
 			'Shrd' => 'šáradá',
 			'Sidd' => 'siddham',
 			'Sind' => 'chudábádí',
 			'Sinh' => 'sinhálské',
 			'Sora' => 'sora sompeng',
 			'Sund' => 'sundské',
 			'Sylo' => 'sylhetské',
 			'Syrc' => 'syrské',
 			'Syre' => 'syrské - estrangelo',
 			'Syrj' => 'syrské - západní',
 			'Syrn' => 'syrské - východní',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takrí',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lü nové',
 			'Taml' => 'tamilské',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugské',
 			'Teng' => 'tengwar',
 			'Tfng' => 'berberské',
 			'Tglg' => 'tagalské',
 			'Thaa' => 'thaana',
 			'Thai' => 'thajské',
 			'Tibt' => 'tibetské',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaritské klínové',
 			'Vaii' => 'vai',
 			'Visp' => 'viditelná řeč',
 			'Wara' => 'varang kšiti',
 			'Wole' => 'karolínské (woleai)',
 			'Xpeo' => 'staroperské klínové písmo',
 			'Xsux' => 'sumero-akkadské klínové písmo',
 			'Yiii' => 'yi',
 			'Zinh' => 'zděděné',
 			'Zmth' => 'matematický zápis',
 			'Zsye' => 'emodži',
 			'Zsym' => 'symboly',
 			'Zxxx' => 'bez zápisu',
 			'Zyyy' => 'obecné',
 			'Zzzz' => 'neznámé písmo',

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
			'001' => 'svět',
 			'002' => 'Afrika',
 			'003' => 'Severní Amerika',
 			'005' => 'Jižní Amerika',
 			'009' => 'Oceánie',
 			'011' => 'západní Afrika',
 			'013' => 'Střední Amerika',
 			'014' => 'východní Afrika',
 			'015' => 'severní Afrika',
 			'017' => 'střední Afrika',
 			'018' => 'jižní Afrika',
 			'019' => 'Amerika',
 			'021' => 'Severní Amerika (oblast)',
 			'029' => 'Karibik',
 			'030' => 'východní Asie',
 			'034' => 'jižní Asie',
 			'035' => 'jihovýchodní Asie',
 			'039' => 'jižní Evropa',
 			'053' => 'Australasie',
 			'054' => 'Melanésie',
 			'057' => 'Mikronésie (region)',
 			'061' => 'Polynésie',
 			'142' => 'Asie',
 			'143' => 'Střední Asie',
 			'145' => 'západní Asie',
 			'150' => 'Evropa',
 			'151' => 'východní Evropa',
 			'154' => 'severní Evropa',
 			'155' => 'západní Evropa',
 			'202' => 'subsaharská Afrika',
 			'419' => 'Latinská Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Spojené arabské emiráty',
 			'AF' => 'Afghánistán',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albánie',
 			'AM' => 'Arménie',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktida',
 			'AR' => 'Argentina',
 			'AS' => 'Americká Samoa',
 			'AT' => 'Rakousko',
 			'AU' => 'Austrálie',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandy',
 			'AZ' => 'Ázerbájdžán',
 			'BA' => 'Bosna a Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladéš',
 			'BE' => 'Belgie',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulharsko',
 			'BH' => 'Bahrajn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Svatý Bartoloměj',
 			'BM' => 'Bermudy',
 			'BN' => 'Brunej',
 			'BO' => 'Bolívie',
 			'BQ' => 'Karibské Nizozemsko',
 			'BR' => 'Brazílie',
 			'BS' => 'Bahamy',
 			'BT' => 'Bhútán',
 			'BV' => 'Bouvetův ostrov',
 			'BW' => 'Botswana',
 			'BY' => 'Bělorusko',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosové ostrovy',
 			'CD' => 'Kongo – Kinshasa',
 			'CD@alt=variant' => 'Kongo (DRK)',
 			'CF' => 'Středoafrická republika',
 			'CG' => 'Kongo – Brazzaville',
 			'CG@alt=variant' => 'Kongo (republika)',
 			'CH' => 'Švýcarsko',
 			'CI' => 'Pobřeží slonoviny',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cookovy ostrovy',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Čína',
 			'CO' => 'Kolumbie',
 			'CP' => 'Clippertonův ostrov',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kapverdy',
 			'CW' => 'Curaçao',
 			'CX' => 'Vánoční ostrov',
 			'CY' => 'Kypr',
 			'CZ' => 'Česko',
 			'CZ@alt=variant' => 'Česká republika',
 			'DE' => 'Německo',
 			'DG' => 'Diego García',
 			'DJ' => 'Džibutsko',
 			'DK' => 'Dánsko',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikánská republika',
 			'DZ' => 'Alžírsko',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ekvádor',
 			'EE' => 'Estonsko',
 			'EG' => 'Egypt',
 			'EH' => 'Západní Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Španělsko',
 			'ET' => 'Etiopie',
 			'EU' => 'Evropská unie',
 			'EZ' => 'eurozóna',
 			'FI' => 'Finsko',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandské ostrovy',
 			'FK@alt=variant' => 'Falklandské ostrovy (Malvíny)',
 			'FM' => 'Mikronésie',
 			'FO' => 'Faerské ostrovy',
 			'FR' => 'Francie',
 			'GA' => 'Gabon',
 			'GB' => 'Spojené království',
 			'GB@alt=short' => 'GB',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzie',
 			'GF' => 'Francouzská Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grónsko',
 			'GM' => 'Gambie',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Rovníková Guinea',
 			'GR' => 'Řecko',
 			'GS' => 'Jižní Georgie a Jižní Sandwichovy ostrovy',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong – ZAO Číny',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardův ostrov a McDonaldovy ostrovy',
 			'HN' => 'Honduras',
 			'HR' => 'Chorvatsko',
 			'HT' => 'Haiti',
 			'HU' => 'Maďarsko',
 			'IC' => 'Kanárské ostrovy',
 			'ID' => 'Indonésie',
 			'IE' => 'Irsko',
 			'IL' => 'Izrael',
 			'IM' => 'Ostrov Man',
 			'IN' => 'Indie',
 			'IO' => 'Britské indickooceánské území',
 			'IO@alt=chagos' => 'Čagoské ostrovy',
 			'IQ' => 'Irák',
 			'IR' => 'Írán',
 			'IS' => 'Island',
 			'IT' => 'Itálie',
 			'JE' => 'Jersey',
 			'JM' => 'Jamajka',
 			'JO' => 'Jordánsko',
 			'JP' => 'Japonsko',
 			'KE' => 'Keňa',
 			'KG' => 'Kyrgyzstán',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komory',
 			'KN' => 'Svatý Kryštof a Nevis',
 			'KP' => 'Severní Korea',
 			'KR' => 'Jižní Korea',
 			'KW' => 'Kuvajt',
 			'KY' => 'Kajmanské ostrovy',
 			'KZ' => 'Kazachstán',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Svatá Lucie',
 			'LI' => 'Lichtenštejnsko',
 			'LK' => 'Srí Lanka',
 			'LR' => 'Libérie',
 			'LS' => 'Lesotho',
 			'LT' => 'Litva',
 			'LU' => 'Lucembursko',
 			'LV' => 'Lotyšsko',
 			'LY' => 'Libye',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavsko',
 			'ME' => 'Černá Hora',
 			'MF' => 'Svatý Martin (Francie)',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallovy ostrovy',
 			'MK' => 'Severní Makedonie',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Barma)',
 			'MN' => 'Mongolsko',
 			'MO' => 'Macao – ZAO Číny',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Severní Mariany',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritánie',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricius',
 			'MV' => 'Maledivy',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malajsie',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibie',
 			'NC' => 'Nová Kaledonie',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk',
 			'NG' => 'Nigérie',
 			'NI' => 'Nikaragua',
 			'NL' => 'Nizozemsko',
 			'NO' => 'Norsko',
 			'NP' => 'Nepál',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nový Zéland',
 			'NZ@alt=variant' => 'Aotearoa – Nový Zéland',
 			'OM' => 'Omán',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francouzská Polynésie',
 			'PG' => 'Papua-Nová Guinea',
 			'PH' => 'Filipíny',
 			'PK' => 'Pákistán',
 			'PL' => 'Polsko',
 			'PM' => 'Saint-Pierre a Miquelon',
 			'PN' => 'Pitcairnovy ostrovy',
 			'PR' => 'Portoriko',
 			'PS' => 'Palestinská území',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalsko',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'vnější Oceánie',
 			'RE' => 'Réunion',
 			'RO' => 'Rumunsko',
 			'RS' => 'Srbsko',
 			'RU' => 'Rusko',
 			'RW' => 'Rwanda',
 			'SA' => 'Saúdská Arábie',
 			'SB' => 'Šalamounovy ostrovy',
 			'SC' => 'Seychely',
 			'SD' => 'Súdán',
 			'SE' => 'Švédsko',
 			'SG' => 'Singapur',
 			'SH' => 'Svatá Helena',
 			'SI' => 'Slovinsko',
 			'SJ' => 'Špicberky a Jan Mayen',
 			'SK' => 'Slovensko',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somálsko',
 			'SR' => 'Surinam',
 			'SS' => 'Jižní Súdán',
 			'ST' => 'Svatý Tomáš a Princův ostrov',
 			'SV' => 'Salvador',
 			'SX' => 'Svatý Martin (Nizozemsko)',
 			'SY' => 'Sýrie',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Svazijsko',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks a Caicos',
 			'TD' => 'Čad',
 			'TF' => 'Francouzská jižní území',
 			'TG' => 'Togo',
 			'TH' => 'Thajsko',
 			'TJ' => 'Tádžikistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Východní Timor',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Tunisko',
 			'TO' => 'Tonga',
 			'TR' => 'Turecko',
 			'TT' => 'Trinidad a Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tchaj-wan',
 			'TZ' => 'Tanzanie',
 			'UA' => 'Ukrajina',
 			'UG' => 'Uganda',
 			'UM' => 'Menší odlehlé ostrovy USA',
 			'UN' => 'Organizace spojených národů',
 			'UN@alt=short' => 'OSN',
 			'US' => 'Spojené státy',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistán',
 			'VA' => 'Vatikán',
 			'VC' => 'Svatý Vincenc a Grenadiny',
 			'VE' => 'Venezuela',
 			'VG' => 'Britské Panenské ostrovy',
 			'VI' => 'Americké Panenské ostrovy',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'simulovaná diakritika',
 			'XB' => 'simulovaný obousměrný zápis',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Jihoafrická republika',
 			'ZM' => 'Zambie',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'neznámá oblast',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'PINYIN' => 'pinyin',
 			'SCOTLAND' => 'angličtina (Skotsko)',
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
			'calendar' => 'Kalendář',
 			'cf' => 'Měnový formát',
 			'colalternate' => 'Ignorovat řazení symbolů',
 			'colbackwards' => 'Obrácené řazení akcentů',
 			'colcasefirst' => 'Řazení velkých a malých písmen',
 			'colcaselevel' => 'Rozlišování velkých a malých písmen při řazení',
 			'collation' => 'Řazení',
 			'colnormalization' => 'Normalizované řazení',
 			'colnumeric' => 'Číselné řazení',
 			'colstrength' => 'Míra řazení',
 			'currency' => 'Měna',
 			'hc' => 'Hodinový cyklus (12 vs. 24)',
 			'lb' => 'Styl zalamování řádků',
 			'ms' => 'Měrná soustava',
 			'numbers' => 'Čísla',
 			'timezone' => 'Časové pásmo',
 			'va' => 'Varianta národního prostředí',
 			'x' => 'Soukromé použití',

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
 				'buddhist' => q{Buddhistický kalendář},
 				'chinese' => q{Čínský kalendář},
 				'coptic' => q{Koptský kalendář},
 				'dangi' => q{Korejský kalendář Dangi},
 				'ethiopic' => q{Etiopský kalendář},
 				'ethiopic-amete-alem' => q{Etiopský kalendář (amete alem)},
 				'gregorian' => q{Gregoriánský kalendář},
 				'hebrew' => q{Hebrejský kalendář},
 				'indian' => q{Indický národní kalendář},
 				'islamic' => q{Kalendář podle hidžry},
 				'islamic-civil' => q{Kalendář podle hidžry (občanský)},
 				'islamic-umalqura' => q{Kalendář podle hidžry (Umm al-Qura)},
 				'iso8601' => q{Kalendář ISO-8601},
 				'japanese' => q{Japonský kalendář},
 				'persian' => q{Perský kalendář},
 				'roc' => q{Kalendář Čínské republiky},
 			},
 			'cf' => {
 				'account' => q{Účetní měnový formát},
 				'standard' => q{Standardní měnový formát},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Řadit symboly},
 				'shifted' => q{Při řazení ignorovat symboly},
 			},
 			'colbackwards' => {
 				'no' => q{Normální řazení akcentů},
 				'yes' => q{Řadit akcenty opačně},
 			},
 			'colcasefirst' => {
 				'lower' => q{Nejdříve řadit malá písmena},
 				'no' => q{Běžné řazení velkých a malých písmen},
 				'upper' => q{Nejdříve řadit velká písmena},
 			},
 			'colcaselevel' => {
 				'no' => q{Nerozlišovat při řazení velká a malá písmena},
 				'yes' => q{Rozlišovat při řazení velká a malá písmena},
 			},
 			'collation' => {
 				'big5han' => q{Řazení pro tradiční čínštinu – Big5},
 				'compat' => q{Předchozí řazení, kompatibilita},
 				'dictionary' => q{Slovníkové řazení},
 				'ducet' => q{Výchozí řazení Unicode},
 				'eor' => q{Evropské řazení},
 				'gb2312han' => q{Řazení pro zjednodušenou čínštinu – GB2312},
 				'phonebook' => q{Řazení telefonního seznamu},
 				'phonetic' => q{Fonetické řazení},
 				'pinyin' => q{Řazení podle pchin-jinu},
 				'reformed' => q{Reformované řazení},
 				'search' => q{Obecné hledání},
 				'searchjl' => q{Vyhledávat podle počáteční souhlásky písma hangul},
 				'standard' => q{Standardní řazení},
 				'stroke' => q{Řazení podle tahů},
 				'traditional' => q{Tradiční řazení},
 				'unihan' => q{Řazení podle radikálů},
 				'zhuyin' => q{Řazení podle ču-jinu},
 			},
 			'colnormalization' => {
 				'no' => q{Řadit bez normalizace},
 				'yes' => q{Řadit podle normalizovaného kódování Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{Řadit číslice jednotlivě},
 				'yes' => q{Řadit číslice numericky},
 			},
 			'colstrength' => {
 				'identical' => q{Řadit vše},
 				'primary' => q{Řadit pouze základní písmena},
 				'quaternary' => q{Řadit akcenty/velká a malá písmena/šířku/kana},
 				'secondary' => q{Řadit akcenty},
 				'tertiary' => q{Řadit akcenty/velká a malá písmena/šířku},
 			},
 			'd0' => {
 				'fwidth' => q{Plná šířka},
 				'hwidth' => q{Poloviční šířka},
 				'npinyin' => q{Numerický},
 			},
 			'hc' => {
 				'h11' => q{12hodinový systém (0–11)},
 				'h12' => q{12hodinový systém (1–12)},
 				'h23' => q{24hodinový systém (0–23)},
 				'h24' => q{24hodinový systém (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Volný styl zalamování řádků},
 				'normal' => q{Běžný styl zalamování řádků},
 				'strict' => q{Striktní styl zalamování řádků},
 			},
 			'm0' => {
 				'bgn' => q{Transliterace podle BGN},
 				'ungegn' => q{Transliterace podle UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{Metrická soustava},
 				'uksystem' => q{Britská měrná soustava},
 				'ussystem' => q{Americká měrná soustava},
 			},
 			'numbers' => {
 				'arab' => q{Arabsko-indické číslice},
 				'arabext' => q{Rozšířené arabsko-indické číslice},
 				'armn' => q{Arménské číslice},
 				'armnlow' => q{Malé arménské číslice},
 				'bali' => q{Balijské číslice},
 				'beng' => q{Bengálské číslice},
 				'cakm' => q{Čakmské číslice},
 				'deva' => q{Číslice písma dévanágarí},
 				'ethi' => q{Etiopské číslice},
 				'finance' => q{Finanční zápis čísel},
 				'fullwide' => q{Číslice – plná šířka},
 				'geor' => q{Gruzínské číslice},
 				'grek' => q{Řecké číslice},
 				'greklow' => q{Malé řecké číslice},
 				'gujr' => q{Gudžarátské číslice},
 				'guru' => q{Číslice gurmukhí},
 				'hanidec' => q{Čínské desítkové číslice},
 				'hans' => q{Číslice zjednodušené čínštiny},
 				'hansfin' => q{Finanční číslice zjednodušené čínštiny},
 				'hant' => q{Číslice tradiční čínštiny},
 				'hantfin' => q{Finanční číslice tradiční čínštiny},
 				'hebr' => q{Hebrejské číslice},
 				'java' => q{Javánské číslice},
 				'jpan' => q{Japonské číslice},
 				'jpanfin' => q{Japonské finanční číslice},
 				'khmr' => q{Khmerské číslice},
 				'knda' => q{Kannadské číslice},
 				'laoo' => q{Laoské číslice},
 				'latn' => q{Západní číslice},
 				'mlym' => q{Malajálamské číslice},
 				'mong' => q{Mongolské číslice},
 				'mtei' => q{Manipurské číslice},
 				'mymr' => q{Myanmarské číslice},
 				'native' => q{Nativní číslice},
 				'olck' => q{Santálské číslice},
 				'orya' => q{Urijské číslice},
 				'osma' => q{Somálské číslice},
 				'roman' => q{Římské číslice},
 				'romanlow' => q{Malé římské číslice},
 				'saur' => q{Saurášterské číslice},
 				'sund' => q{Sundské číslice},
 				'taml' => q{Tamilské tradiční číslice},
 				'tamldec' => q{Tamilské číslice},
 				'telu' => q{Telugské číslice},
 				'thai' => q{Thajské číslice},
 				'tibt' => q{Tibetské číslice},
 				'traditional' => q{Tradiční číslovky},
 				'vaii' => q{Vaiské číslice},
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
			'metric' => q{metrický},
 			'UK' => q{Velká Británie},
 			'US' => q{USA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Jazyk: {0}',
 			'script' => 'Písmo: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[àăâåäãā æ ç èĕêëē ìĭîïī ľł ñ òŏôöøō œ ŕ ùŭûüū ÿ]},
			index => ['A', 'B', 'C', 'Č', 'D', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'Ř', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[aá b c č dď eéě f g h {ch} ií j k l m nň oó p q r ř s š tť uúů v w x yý z ž]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … ‘‚ “„ ( ) \[ \] § @ * / \&]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'D', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'Ř', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'initial' => '… {0}',
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
			'word-medial' => '{0}… {1}',
		};
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
						'name' => q(světová strana),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(světová strana),
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
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
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
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
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
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
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
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
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
						'1' => q(feminine),
						'few' => q({0} gravitační síly),
						'many' => q({0} gravitační síly),
						'name' => q(gravitační síla),
						'one' => q({0} gravitační síla),
						'other' => q({0} gravitačních sil),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'few' => q({0} gravitační síly),
						'many' => q({0} gravitační síly),
						'name' => q(gravitační síla),
						'one' => q({0} gravitační síla),
						'other' => q({0} gravitačních sil),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(inanimate),
						'few' => q({0} metry za sekundu na druhou),
						'many' => q({0} metru za sekundu na druhou),
						'name' => q(metry za sekundu na druhou),
						'one' => q({0} metr za sekundu na druhou),
						'other' => q({0} metrů za sekundu na druhou),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(inanimate),
						'few' => q({0} metry za sekundu na druhou),
						'many' => q({0} metru za sekundu na druhou),
						'name' => q(metry za sekundu na druhou),
						'one' => q({0} metr za sekundu na druhou),
						'other' => q({0} metrů za sekundu na druhou),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'few' => q({0} minuty),
						'many' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minut),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'few' => q({0} minuty),
						'many' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minut),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'few' => q({0} vteřiny),
						'many' => q({0} vteřiny),
						'name' => q(vteřiny),
						'one' => q({0} vteřina),
						'other' => q({0} vteřin),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'few' => q({0} vteřiny),
						'many' => q({0} vteřiny),
						'name' => q(vteřiny),
						'one' => q({0} vteřina),
						'other' => q({0} vteřin),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(inanimate),
						'few' => q({0} stupně),
						'many' => q({0} stupně),
						'name' => q(stupně),
						'one' => q({0} stupeň),
						'other' => q({0} stupňů),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(inanimate),
						'few' => q({0} stupně),
						'many' => q({0} stupně),
						'name' => q(stupně),
						'one' => q({0} stupeň),
						'other' => q({0} stupňů),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(inanimate),
						'few' => q({0} radiány),
						'many' => q({0} radiánu),
						'name' => q(radiány),
						'one' => q({0} radián),
						'other' => q({0} radiánů),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(inanimate),
						'few' => q({0} radiány),
						'many' => q({0} radiánu),
						'name' => q(radiány),
						'one' => q({0} radián),
						'other' => q({0} radiánů),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'few' => q({0} otáčky),
						'many' => q({0} otáčky),
						'name' => q(otáčky),
						'one' => q({0} otáčka),
						'other' => q({0} otáček),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'few' => q({0} otáčky),
						'many' => q({0} otáčky),
						'name' => q(otáčky),
						'one' => q({0} otáčka),
						'other' => q({0} otáček),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} akry),
						'many' => q({0} akru),
						'name' => q(akry),
						'one' => q({0} akr),
						'other' => q({0} akrů),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} akry),
						'many' => q({0} akru),
						'name' => q(akry),
						'one' => q({0} akr),
						'other' => q({0} akrů),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunamy),
						'many' => q({0} dunamu),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamů),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunamy),
						'many' => q({0} dunamu),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamů),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(inanimate),
						'few' => q({0} hektary),
						'many' => q({0} hektaru),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarů),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(inanimate),
						'few' => q({0} hektary),
						'many' => q({0} hektaru),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarů),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetry čtvereční),
						'many' => q({0} centimetru čtverečního),
						'name' => q(centimetry čtvereční),
						'one' => q({0} centimetr čtvereční),
						'other' => q({0} centimetrů čtverečních),
						'per' => q({0} na centimetr čtvereční),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetry čtvereční),
						'many' => q({0} centimetru čtverečního),
						'name' => q(centimetry čtvereční),
						'one' => q({0} centimetr čtvereční),
						'other' => q({0} centimetrů čtverečních),
						'per' => q({0} na centimetr čtvereční),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} stopy čtvereční),
						'many' => q({0} stopy čtvereční),
						'name' => q(stopy čtvereční),
						'one' => q({0} stopa čtvereční),
						'other' => q({0} stop čtverečních),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} stopy čtvereční),
						'many' => q({0} stopy čtvereční),
						'name' => q(stopy čtvereční),
						'one' => q({0} stopa čtvereční),
						'other' => q({0} stop čtverečních),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} palce čtvereční),
						'many' => q({0} palce čtverečního),
						'name' => q(palce čtvereční),
						'one' => q({0} palec čtvereční),
						'other' => q({0} palců čtverečních),
						'per' => q({0} na palec čtvereční),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} palce čtvereční),
						'many' => q({0} palce čtverečního),
						'name' => q(palce čtvereční),
						'one' => q({0} palec čtvereční),
						'other' => q({0} palců čtverečních),
						'per' => q({0} na palec čtvereční),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry čtvereční),
						'many' => q({0} kilometru čtverečního),
						'name' => q(kilometry čtvereční),
						'one' => q({0} kilometr čtvereční),
						'other' => q({0} kilometrů čtverečních),
						'per' => q({0} na kilometr čtvereční),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry čtvereční),
						'many' => q({0} kilometru čtverečního),
						'name' => q(kilometry čtvereční),
						'one' => q({0} kilometr čtvereční),
						'other' => q({0} kilometrů čtverečních),
						'per' => q({0} na kilometr čtvereční),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metry čtvereční),
						'many' => q({0} metru čtverečního),
						'name' => q(metry čtvereční),
						'one' => q({0} metr čtvereční),
						'other' => q({0} metrů čtverečních),
						'per' => q({0} na metr čtvereční),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metry čtvereční),
						'many' => q({0} metru čtverečního),
						'name' => q(metry čtvereční),
						'one' => q({0} metr čtvereční),
						'other' => q({0} metrů čtverečních),
						'per' => q({0} na metr čtvereční),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} míle čtvereční),
						'many' => q({0} míle čtvereční),
						'name' => q(míle čtvereční),
						'one' => q({0} míle čtvereční),
						'other' => q({0} mil čtverečních),
						'per' => q({0} na míli čtvereční),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} míle čtvereční),
						'many' => q({0} míle čtvereční),
						'name' => q(míle čtvereční),
						'one' => q({0} míle čtvereční),
						'other' => q({0} mil čtverečních),
						'per' => q({0} na míli čtvereční),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} yardy čtvereční),
						'many' => q({0} yardu čtverečního),
						'name' => q(yardy čtvereční),
						'one' => q({0} yard čtvereční),
						'other' => q({0} yardů čtverečních),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} yardy čtvereční),
						'many' => q({0} yardu čtverečního),
						'name' => q(yardy čtvereční),
						'one' => q({0} yard čtvereční),
						'other' => q({0} yardů čtverečních),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(feminine),
						'few' => q({0} položky),
						'many' => q({0} položky),
						'one' => q({0} položka),
						'other' => q({0} položek),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(feminine),
						'few' => q({0} položky),
						'many' => q({0} položky),
						'one' => q({0} položka),
						'other' => q({0} položek),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátů),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátů),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na decilitr),
						'many' => q({0} miligramu na decilitr),
						'name' => q(miligramy na decilitr),
						'one' => q({0} miligram na decilitr),
						'other' => q({0} miligramů na decilitr),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na decilitr),
						'many' => q({0} miligramu na decilitr),
						'name' => q(miligramy na decilitr),
						'one' => q({0} miligram na decilitr),
						'other' => q({0} miligramů na decilitr),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(inanimate),
						'few' => q({0} milimoly na litr),
						'many' => q({0} milimolu na litr),
						'name' => q(milimoly na litr),
						'one' => q({0} milimol na litr),
						'other' => q({0} milimolů na litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(inanimate),
						'few' => q({0} milimoly na litr),
						'many' => q({0} milimolu na litr),
						'name' => q(milimoly na litr),
						'one' => q({0} milimol na litr),
						'other' => q({0} milimolů na litr),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(inanimate),
						'few' => q({0} moly),
						'many' => q({0} molu),
						'name' => q(moly),
						'one' => q({0} mol),
						'other' => q({0} molů),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(inanimate),
						'few' => q({0} moly),
						'many' => q({0} molu),
						'name' => q(moly),
						'one' => q({0} mol),
						'other' => q({0} molů),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(neuter),
						'few' => q({0} procenta),
						'many' => q({0} procenta),
						'name' => q(procenta),
						'one' => q({0} procento),
						'other' => q({0} procent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(neuter),
						'few' => q({0} procenta),
						'many' => q({0} procenta),
						'name' => q(procenta),
						'one' => q({0} procento),
						'other' => q({0} procent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(neuter),
						'few' => q({0} promile),
						'many' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promile),
						'other' => q({0} promile),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(neuter),
						'few' => q({0} promile),
						'many' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promile),
						'other' => q({0} promile),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(inanimate),
						'few' => q({0} díly z milionu),
						'many' => q({0} dílu z milionu),
						'name' => q(díly z milionu),
						'one' => q({0} díl z milionu),
						'other' => q({0} dílů z milionu),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(inanimate),
						'few' => q({0} díly z milionu),
						'many' => q({0} dílu z milionu),
						'name' => q(díly z milionu),
						'one' => q({0} díl z milionu),
						'other' => q({0} dílů z milionu),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(feminine),
						'few' => q({0} desetiny promile),
						'many' => q({0} desetiny promile),
						'name' => q(desetiny promile),
						'one' => q({0} desetina promile),
						'other' => q({0} desetin promile),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(feminine),
						'few' => q({0} desetiny promile),
						'many' => q({0} desetiny promile),
						'name' => q(desetiny promile),
						'one' => q({0} desetina promile),
						'other' => q({0} desetin promile),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litry na sto kilometrů),
						'many' => q({0} litru na sto kilometrů),
						'name' => q(litry na sto kilometrů),
						'one' => q({0} litr na sto kilometrů),
						'other' => q({0} litrů na sto kilometrů),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litry na sto kilometrů),
						'many' => q({0} litru na sto kilometrů),
						'name' => q(litry na sto kilometrů),
						'one' => q({0} litr na sto kilometrů),
						'other' => q({0} litrů na sto kilometrů),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litry na kilometr),
						'many' => q({0} litru na kilometr),
						'name' => q(litry na kilometr),
						'one' => q({0} litr na kilometr),
						'other' => q({0} litrů na kilometr),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litry na kilometr),
						'many' => q({0} litru na kilometr),
						'name' => q(litry na kilometr),
						'one' => q({0} litr na kilometr),
						'other' => q({0} litrů na kilometr),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} míle na galon),
						'many' => q({0} míle na galon),
						'name' => q(míle na galon),
						'one' => q({0} míle na galon),
						'other' => q({0} mil na galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} míle na galon),
						'many' => q({0} míle na galon),
						'name' => q(míle na galon),
						'one' => q({0} míle na galon),
						'other' => q({0} mil na galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} míle na britský galon),
						'many' => q({0} míle na britský galon),
						'name' => q(míle na britský galon),
						'one' => q({0} míle na britský galon),
						'other' => q({0} mil na britský galon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} míle na britský galon),
						'many' => q({0} míle na britský galon),
						'name' => q(míle na britský galon),
						'one' => q({0} míle na britský galon),
						'other' => q({0} mil na britský galon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} východní délky),
						'north' => q({0} severní šířky),
						'south' => q({0} jižní šířky),
						'west' => q({0} západní délky),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} východní délky),
						'north' => q({0} severní šířky),
						'south' => q({0} jižní šířky),
						'west' => q({0} západní délky),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(inanimate),
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitů),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(inanimate),
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitů),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(inanimate),
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajty),
						'one' => q({0} bajt),
						'other' => q({0} bajtů),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(inanimate),
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajty),
						'one' => q({0} bajt),
						'other' => q({0} bajtů),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(inanimate),
						'few' => q({0} gigabity),
						'many' => q({0} gigabitu),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitů),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(inanimate),
						'few' => q({0} gigabity),
						'many' => q({0} gigabitu),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitů),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(inanimate),
						'few' => q({0} gigabajty),
						'many' => q({0} gigabajtu),
						'name' => q(gigabajty),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtů),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(inanimate),
						'few' => q({0} gigabajty),
						'many' => q({0} gigabajtu),
						'name' => q(gigabajty),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtů),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(inanimate),
						'few' => q({0} kilobity),
						'many' => q({0} kilobitu),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitů),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(inanimate),
						'few' => q({0} kilobity),
						'many' => q({0} kilobitu),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitů),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(inanimate),
						'few' => q({0} kilobajty),
						'many' => q({0} kilobajtu),
						'name' => q(kilobajty),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtů),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(inanimate),
						'few' => q({0} kilobajty),
						'many' => q({0} kilobajtu),
						'name' => q(kilobajty),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtů),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(inanimate),
						'few' => q({0} megabity),
						'many' => q({0} megabitu),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitů),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(inanimate),
						'few' => q({0} megabity),
						'many' => q({0} megabitu),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitů),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(inanimate),
						'few' => q({0} megabajty),
						'many' => q({0} megabajtu),
						'name' => q(megabajty),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtů),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(inanimate),
						'few' => q({0} megabajty),
						'many' => q({0} megabajtu),
						'name' => q(megabajty),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtů),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(inanimate),
						'few' => q({0} petabajty),
						'many' => q({0} petabajtu),
						'name' => q(petabajty),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtů),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(inanimate),
						'few' => q({0} petabajty),
						'many' => q({0} petabajtu),
						'name' => q(petabajty),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtů),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(inanimate),
						'few' => q({0} terabity),
						'many' => q({0} terabitu),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitů),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(inanimate),
						'few' => q({0} terabity),
						'many' => q({0} terabitu),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitů),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(inanimate),
						'few' => q({0} terabajty),
						'many' => q({0} terabajtu),
						'name' => q(terabajty),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtů),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(inanimate),
						'few' => q({0} terabajty),
						'many' => q({0} terabajtu),
						'name' => q(terabajty),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtů),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'few' => q({0} století),
						'many' => q({0} století),
						'name' => q(století),
						'one' => q({0} století),
						'other' => q({0} století),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'few' => q({0} století),
						'many' => q({0} století),
						'name' => q(století),
						'one' => q({0} století),
						'other' => q({0} století),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(inanimate),
						'few' => q({0} dny),
						'many' => q({0} dne),
						'one' => q({0} den),
						'other' => q({0} dnů),
						'per' => q({0} za den),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(inanimate),
						'few' => q({0} dny),
						'many' => q({0} dne),
						'one' => q({0} den),
						'other' => q({0} dnů),
						'per' => q({0} za den),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(inanimate),
						'few' => q({0} dny),
						'many' => q({0} dne),
						'one' => q({0} den),
						'other' => q({0} dnů),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(inanimate),
						'few' => q({0} dny),
						'many' => q({0} dne),
						'one' => q({0} den),
						'other' => q({0} dnů),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'few' => q({0} desetiletí),
						'many' => q({0} desetiletí),
						'name' => q(desetiletí),
						'one' => q({0} desetiletí),
						'other' => q({0} desetiletí),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'few' => q({0} desetiletí),
						'many' => q({0} desetiletí),
						'name' => q(desetiletí),
						'one' => q({0} desetiletí),
						'other' => q({0} desetiletí),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'few' => q({0} hodiny),
						'many' => q({0} hodiny),
						'name' => q(hodiny),
						'one' => q({0} hodina),
						'other' => q({0} hodin),
						'per' => q({0} za hodinu),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'few' => q({0} hodiny),
						'many' => q({0} hodiny),
						'name' => q(hodiny),
						'one' => q({0} hodina),
						'other' => q({0} hodin),
						'per' => q({0} za hodinu),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekundy),
						'many' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekund),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekundy),
						'many' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekund),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekundy),
						'many' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekund),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekundy),
						'many' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekund),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'few' => q({0} minuty),
						'many' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minut),
						'per' => q({0} za minutu),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'few' => q({0} minuty),
						'many' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minut),
						'per' => q({0} za minutu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(inanimate),
						'few' => q({0} měsíce),
						'many' => q({0} měsíce),
						'name' => q(měsíce),
						'one' => q({0} měsíc),
						'other' => q({0} měsíců),
						'per' => q({0} za měsíc),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(inanimate),
						'few' => q({0} měsíce),
						'many' => q({0} měsíce),
						'name' => q(měsíce),
						'one' => q({0} měsíc),
						'other' => q({0} měsíců),
						'per' => q({0} za měsíc),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekundy),
						'many' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekund),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekundy),
						'many' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekund),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'few' => q({0} čtvrtletí),
						'many' => q({0} čtvrtletí),
						'name' => q(čtvrtletí),
						'one' => q({0} čtvrtletí),
						'other' => q({0} čtvrtletí),
						'per' => q({0} za čtvrtletí),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'few' => q({0} čtvrtletí),
						'many' => q({0} čtvrtletí),
						'name' => q(čtvrtletí),
						'one' => q({0} čtvrtletí),
						'other' => q({0} čtvrtletí),
						'per' => q({0} za čtvrtletí),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekund),
						'per' => q({0} za sekundu),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekund),
						'per' => q({0} za sekundu),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(inanimate),
						'few' => q({0} týdny),
						'many' => q({0} týdne),
						'name' => q(týdny),
						'one' => q({0} týden),
						'other' => q({0} týdnů),
						'per' => q({0} za týden),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(inanimate),
						'few' => q({0} týdny),
						'many' => q({0} týdne),
						'name' => q(týdny),
						'one' => q({0} týden),
						'other' => q({0} týdnů),
						'per' => q({0} za týden),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(inanimate),
						'few' => q({0} roky),
						'many' => q({0} roku),
						'one' => q({0} rok),
						'other' => q({0} let),
						'per' => q({0} za rok),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(inanimate),
						'few' => q({0} roky),
						'many' => q({0} roku),
						'one' => q({0} rok),
						'other' => q({0} let),
						'per' => q({0} za rok),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(inanimate),
						'few' => q({0} ampéry),
						'many' => q({0} ampéru),
						'name' => q(ampéry),
						'one' => q({0} ampér),
						'other' => q({0} ampérů),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(inanimate),
						'few' => q({0} ampéry),
						'many' => q({0} ampéru),
						'name' => q(ampéry),
						'one' => q({0} ampér),
						'other' => q({0} ampérů),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(inanimate),
						'few' => q({0} miliampéry),
						'many' => q({0} miliampéru),
						'name' => q(miliampéry),
						'one' => q({0} miliampér),
						'other' => q({0} miliampérů),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(inanimate),
						'few' => q({0} miliampéry),
						'many' => q({0} miliampéru),
						'name' => q(miliampéry),
						'one' => q({0} miliampér),
						'other' => q({0} miliampérů),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(inanimate),
						'few' => q({0} ohmy),
						'many' => q({0} ohmu),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmů),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(inanimate),
						'few' => q({0} ohmy),
						'many' => q({0} ohmu),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmů),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(inanimate),
						'few' => q({0} volty),
						'many' => q({0} voltu),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltů),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(inanimate),
						'few' => q({0} volty),
						'many' => q({0} voltu),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltů),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} britské tepelné jednotky),
						'many' => q({0} britské tepelné jednotky),
						'name' => q(britské tepelné jednotky),
						'one' => q({0} britská tepelná jednotka),
						'other' => q({0} britských tepelných jednotek),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} britské tepelné jednotky),
						'many' => q({0} britské tepelné jednotky),
						'name' => q(britské tepelné jednotky),
						'one' => q({0} britská tepelná jednotka),
						'other' => q({0} britských tepelných jednotek),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalorie),
						'many' => q({0} kalorie),
						'name' => q(kalorie),
						'one' => q({0} kalorie),
						'other' => q({0} kalorií),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalorie),
						'many' => q({0} kalorie),
						'name' => q(kalorie),
						'one' => q({0} kalorie),
						'other' => q({0} kalorií),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektronvolty),
						'many' => q({0} elektronvoltu),
						'name' => q(elektronvolty),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltů),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektronvolty),
						'many' => q({0} elektronvoltu),
						'name' => q(elektronvolty),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltů),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kilokalorie),
						'many' => q({0} kilokalorie),
						'name' => q(kilokalorie),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorií),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kilokalorie),
						'many' => q({0} kilokalorie),
						'name' => q(kilokalorie),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorií),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(inanimate),
						'few' => q({0} jouly),
						'many' => q({0} joulu),
						'name' => q(jouly),
						'one' => q({0} joule),
						'other' => q({0} joulů),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(inanimate),
						'few' => q({0} jouly),
						'many' => q({0} joulu),
						'name' => q(jouly),
						'one' => q({0} joule),
						'other' => q({0} joulů),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilokalorie),
						'many' => q({0} kilokalorie),
						'name' => q(kilokalorie),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorií),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilokalorie),
						'many' => q({0} kilokalorie),
						'name' => q(kilokalorie),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorií),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(inanimate),
						'few' => q({0} kilojouly),
						'many' => q({0} kilojoulu),
						'name' => q(kilojouly),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulů),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(inanimate),
						'few' => q({0} kilojouly),
						'many' => q({0} kilojoulu),
						'name' => q(kilojouly),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulů),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(feminine),
						'few' => q({0} kilowatthodiny),
						'many' => q({0} kilowatthodiny),
						'name' => q(kilowatthodiny),
						'one' => q({0} kilowatthodina),
						'other' => q({0} kilowatthodin),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(feminine),
						'few' => q({0} kilowatthodiny),
						'many' => q({0} kilowatthodiny),
						'name' => q(kilowatthodiny),
						'one' => q({0} kilowatthodina),
						'other' => q({0} kilowatthodin),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} thermy),
						'many' => q({0} thermu),
						'name' => q(thermy),
						'one' => q({0} therm),
						'other' => q({0} thermů),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} thermy),
						'many' => q({0} thermu),
						'name' => q(thermy),
						'one' => q({0} therm),
						'other' => q({0} thermů),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'few' => q({0} kilowatthodiny na sto kilometrů),
						'many' => q({0} kilowatthodiny na sto kilometrů),
						'name' => q(kilowatthodiny na sto kilometrů),
						'one' => q({0} kilowatthodina na sto kilometrů),
						'other' => q({0} kilowatthodin na sto kilometrů),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'few' => q({0} kilowatthodiny na sto kilometrů),
						'many' => q({0} kilowatthodiny na sto kilometrů),
						'name' => q(kilowatthodiny na sto kilometrů),
						'one' => q({0} kilowatthodina na sto kilometrů),
						'other' => q({0} kilowatthodin na sto kilometrů),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(inanimate),
						'few' => q({0} newtony),
						'many' => q({0} newtonu),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonů),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(inanimate),
						'few' => q({0} newtony),
						'many' => q({0} newtonu),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonů),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} libry síly),
						'many' => q({0} libry síly),
						'name' => q(libry síly),
						'one' => q({0} libra síly),
						'other' => q({0} liber síly),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} libry síly),
						'many' => q({0} libry síly),
						'name' => q(libry síly),
						'one' => q({0} libra síly),
						'other' => q({0} liber síly),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(inanimate),
						'few' => q({0} gigahertzy),
						'many' => q({0} gigahertzu),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzů),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(inanimate),
						'few' => q({0} gigahertzy),
						'many' => q({0} gigahertzu),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzů),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(inanimate),
						'few' => q({0} hertzy),
						'many' => q({0} hertzu),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzů),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(inanimate),
						'few' => q({0} hertzy),
						'many' => q({0} hertzu),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzů),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(inanimate),
						'few' => q({0} kilohertzy),
						'many' => q({0} kilohertzu),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzů),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(inanimate),
						'few' => q({0} kilohertzy),
						'many' => q({0} kilohertzu),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzů),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(inanimate),
						'few' => q({0} megahertzy),
						'many' => q({0} megahertzu),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzů),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(inanimate),
						'few' => q({0} megahertzy),
						'many' => q({0} megahertzu),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzů),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} obrazové body),
						'many' => q({0} obrazového bodu),
						'name' => q(obrazové body),
						'one' => q({0} obrazový bod),
						'other' => q({0} obrazových bodů),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} obrazové body),
						'many' => q({0} obrazového bodu),
						'name' => q(obrazové body),
						'one' => q({0} obrazový bod),
						'other' => q({0} obrazových bodů),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} body na centimetr),
						'many' => q({0} bodu na centimetr),
						'name' => q(body na centimetr),
						'one' => q({0} bod na centimetr),
						'other' => q({0} bodů na centimetr),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} body na centimetr),
						'many' => q({0} bodu na centimetr),
						'name' => q(body na centimetr),
						'one' => q({0} bod na centimetr),
						'other' => q({0} bodů na centimetr),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} body na palec),
						'many' => q({0} bodu na palec),
						'name' => q(body na palec),
						'one' => q({0} bod na palec),
						'other' => q({0} bodů na palec),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} body na palec),
						'many' => q({0} bodu na palec),
						'name' => q(body na palec),
						'one' => q({0} bod na palec),
						'other' => q({0} bodů na palec),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(inanimate),
						'few' => q({0} čtverčíky),
						'many' => q({0} čtverčíku),
						'name' => q(čtverčíky),
						'one' => q({0} čtverčík),
						'other' => q({0} čtverčíků),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(inanimate),
						'few' => q({0} čtverčíky),
						'many' => q({0} čtverčíku),
						'name' => q(čtverčíky),
						'one' => q({0} čtverčík),
						'other' => q({0} čtverčíků),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(inanimate),
						'few' => q({0} megapixely),
						'many' => q({0} megapixelu),
						'name' => q(megapixely),
						'one' => q({0} megapixel),
						'other' => q({0} megapixelů),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(inanimate),
						'few' => q({0} megapixely),
						'many' => q({0} megapixelu),
						'name' => q(megapixely),
						'one' => q({0} megapixel),
						'other' => q({0} megapixelů),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(inanimate),
						'few' => q({0} pixely),
						'many' => q({0} pixelu),
						'name' => q(pixely),
						'one' => q({0} pixel),
						'other' => q({0} pixelů),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(inanimate),
						'few' => q({0} pixely),
						'many' => q({0} pixelu),
						'name' => q(pixely),
						'one' => q({0} pixel),
						'other' => q({0} pixelů),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} pixely na centimetr),
						'many' => q({0} pixelu na centimetr),
						'name' => q(pixely na centimetr),
						'one' => q({0} pixel na centimetr),
						'other' => q({0} pixelů na centimetr),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} pixely na centimetr),
						'many' => q({0} pixelu na centimetr),
						'name' => q(pixely na centimetr),
						'one' => q({0} pixel na centimetr),
						'other' => q({0} pixelů na centimetr),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} pixely na palec),
						'many' => q({0} pixelu na palec),
						'name' => q(pixely na palec),
						'one' => q({0} pixel na palec),
						'other' => q({0} pixelů na palec),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} pixely na palec),
						'many' => q({0} pixelu na palec),
						'name' => q(pixely na palec),
						'one' => q({0} pixel na palec),
						'other' => q({0} pixelů na palec),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomické jednotky),
						'many' => q({0} astronomické jednotky),
						'name' => q(astronomické jednotky),
						'one' => q({0} astronomická jednotka),
						'other' => q({0} astronomických jednotek),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomické jednotky),
						'many' => q({0} astronomické jednotky),
						'name' => q(astronomické jednotky),
						'one' => q({0} astronomická jednotka),
						'other' => q({0} astronomických jednotek),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetry),
						'many' => q({0} centimetru),
						'name' => q(centimetry),
						'one' => q({0} centimetr),
						'other' => q({0} centimetrů),
						'per' => q({0} na centimetr),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetry),
						'many' => q({0} centimetru),
						'name' => q(centimetry),
						'one' => q({0} centimetr),
						'other' => q({0} centimetrů),
						'per' => q({0} na centimetr),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(inanimate),
						'few' => q({0} decimetry),
						'many' => q({0} decimetru),
						'name' => q(decimetry),
						'one' => q({0} decimetr),
						'other' => q({0} decimetrů),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(inanimate),
						'few' => q({0} decimetry),
						'many' => q({0} decimetru),
						'name' => q(decimetry),
						'one' => q({0} decimetr),
						'other' => q({0} decimetrů),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} poloměry Země),
						'many' => q({0} poloměru Země),
						'name' => q(poloměr Země),
						'one' => q({0} poloměr Země),
						'other' => q({0} poloměrů Země),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} poloměry Země),
						'many' => q({0} poloměru Země),
						'name' => q(poloměr Země),
						'one' => q({0} poloměr Země),
						'other' => q({0} poloměrů Země),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} sáhy),
						'many' => q({0} sáhu),
						'name' => q(sáhy),
						'one' => q({0} sáh),
						'other' => q({0} sáhů),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} sáhy),
						'many' => q({0} sáhu),
						'name' => q(sáhy),
						'one' => q({0} sáh),
						'other' => q({0} sáhů),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} stopy),
						'many' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stop),
						'per' => q({0} na stopu),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} stopy),
						'many' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stop),
						'per' => q({0} na stopu),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlongy),
						'many' => q({0} furlongu),
						'name' => q(furlongy),
						'one' => q({0} furlong),
						'other' => q({0} furlongů),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlongy),
						'many' => q({0} furlongu),
						'name' => q(furlongy),
						'one' => q({0} furlong),
						'other' => q({0} furlongů),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} palce),
						'many' => q({0} palce),
						'name' => q(palce),
						'one' => q({0} palec),
						'other' => q({0} palců),
						'per' => q({0} na palec),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} palce),
						'many' => q({0} palce),
						'name' => q(palce),
						'one' => q({0} palec),
						'other' => q({0} palců),
						'per' => q({0} na palec),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry),
						'many' => q({0} kilometru),
						'name' => q(kilometry),
						'one' => q({0} kilometr),
						'other' => q({0} kilometrů),
						'per' => q({0} na kilometr),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry),
						'many' => q({0} kilometru),
						'name' => q(kilometry),
						'one' => q({0} kilometr),
						'other' => q({0} kilometrů),
						'per' => q({0} na kilometr),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} světelné roky),
						'many' => q({0} světelného roku),
						'name' => q(světelné roky),
						'one' => q({0} světelný rok),
						'other' => q({0} světelných let),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} světelné roky),
						'many' => q({0} světelného roku),
						'name' => q(světelné roky),
						'one' => q({0} světelný rok),
						'other' => q({0} světelných let),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metry),
						'many' => q({0} metru),
						'name' => q(metry),
						'one' => q({0} metr),
						'other' => q({0} metrů),
						'per' => q({0} na metr),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(inanimate),
						'few' => q({0} metry),
						'many' => q({0} metru),
						'name' => q(metry),
						'one' => q({0} metr),
						'other' => q({0} metrů),
						'per' => q({0} na metr),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(inanimate),
						'few' => q({0} mikrometry),
						'many' => q({0} mikrometru),
						'name' => q(mikrometry),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometrů),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(inanimate),
						'few' => q({0} mikrometry),
						'many' => q({0} mikrometru),
						'name' => q(mikrometry),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometrů),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} míle),
						'many' => q({0} míle),
						'name' => q(míle),
						'one' => q({0} míle),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} míle),
						'many' => q({0} míle),
						'name' => q(míle),
						'one' => q({0} míle),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} skandinávské míle),
						'many' => q({0} skandinávské míle),
						'name' => q(skandinávské míle),
						'one' => q({0} skandinávská míle),
						'other' => q({0} skandinávských mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} skandinávské míle),
						'many' => q({0} skandinávské míle),
						'name' => q(skandinávské míle),
						'one' => q({0} skandinávská míle),
						'other' => q({0} skandinávských mil),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(inanimate),
						'few' => q({0} milimetry),
						'many' => q({0} milimetru),
						'name' => q(milimetry),
						'one' => q({0} milimetr),
						'other' => q({0} milimetrů),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(inanimate),
						'few' => q({0} milimetry),
						'many' => q({0} milimetru),
						'name' => q(milimetry),
						'one' => q({0} milimetr),
						'other' => q({0} milimetrů),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(inanimate),
						'few' => q({0} nanometry),
						'many' => q({0} nanometru),
						'name' => q(nanometry),
						'one' => q({0} nanometr),
						'other' => q({0} nanometrů),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(inanimate),
						'few' => q({0} nanometry),
						'many' => q({0} nanometru),
						'name' => q(nanometry),
						'one' => q({0} nanometr),
						'other' => q({0} nanometrů),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} námořní míle),
						'many' => q({0} námořní míle),
						'name' => q(námořní míle),
						'one' => q({0} námořní míle),
						'other' => q({0} námořních mil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} námořní míle),
						'many' => q({0} námořní míle),
						'name' => q(námořní míle),
						'one' => q({0} námořní míle),
						'other' => q({0} námořních mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parseky),
						'many' => q({0} parseku),
						'name' => q(parseky),
						'one' => q({0} parsek),
						'other' => q({0} parseků),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parseky),
						'many' => q({0} parseku),
						'name' => q(parseky),
						'one' => q({0} parsek),
						'other' => q({0} parseků),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(inanimate),
						'few' => q({0} pikometry),
						'many' => q({0} pikometru),
						'name' => q(pikometry),
						'one' => q({0} pikometr),
						'other' => q({0} pikometrů),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(inanimate),
						'few' => q({0} pikometry),
						'many' => q({0} pikometru),
						'name' => q(pikometry),
						'one' => q({0} pikometr),
						'other' => q({0} pikometrů),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} body),
						'many' => q({0} bodu),
						'name' => q(body),
						'one' => q({0} bod),
						'other' => q({0} bodů),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} body),
						'many' => q({0} bodu),
						'name' => q(body),
						'one' => q({0} bod),
						'other' => q({0} bodů),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} poloměry Slunce),
						'many' => q({0} poloměru Slunce),
						'name' => q(poloměr Slunce),
						'one' => q({0} poloměr Slunce),
						'other' => q({0} poloměrů Slunce),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} poloměry Slunce),
						'many' => q({0} poloměru Slunce),
						'name' => q(poloměr Slunce),
						'one' => q({0} poloměr Slunce),
						'other' => q({0} poloměrů Slunce),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yardy),
						'many' => q({0} yardu),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardů),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yardy),
						'many' => q({0} yardu),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardů),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'few' => q({0} kandely),
						'many' => q({0} kandely),
						'name' => q(kandely),
						'one' => q({0} kandela),
						'other' => q({0} kandel),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'few' => q({0} kandely),
						'many' => q({0} kandely),
						'name' => q(kandely),
						'one' => q({0} kandela),
						'other' => q({0} kandel),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(inanimate),
						'few' => q({0} lumeny),
						'many' => q({0} lumenu),
						'name' => q(lumeny),
						'one' => q({0} lumen),
						'other' => q({0} lumenů),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(inanimate),
						'few' => q({0} lumeny),
						'many' => q({0} lumenu),
						'name' => q(lumeny),
						'one' => q({0} lumen),
						'other' => q({0} lumenů),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(inanimate),
						'few' => q({0} luxy),
						'many' => q({0} luxu),
						'name' => q(luxy),
						'one' => q({0} lux),
						'other' => q({0} luxů),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(inanimate),
						'few' => q({0} luxy),
						'many' => q({0} luxu),
						'name' => q(luxy),
						'one' => q({0} lux),
						'other' => q({0} luxů),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} zářivé výkony Slunce),
						'many' => q({0} zářivého výkonu Slunce),
						'name' => q(zářivé výkony Slunce),
						'one' => q({0} zářivý výkon Slunce),
						'other' => q({0} zářivých výkonů Slunce),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} zářivé výkony Slunce),
						'many' => q({0} zářivého výkonu Slunce),
						'name' => q(zářivé výkony Slunce),
						'one' => q({0} zářivý výkon Slunce),
						'other' => q({0} zářivých výkonů Slunce),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátů),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátů),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltony),
						'many' => q({0} daltonu),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonů),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltony),
						'many' => q({0} daltonu),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonů),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} hmotnosti Země),
						'many' => q({0} hmotnosti Země),
						'name' => q(hmotnosti Země),
						'one' => q({0} hmotnost Země),
						'other' => q({0} hmotností Země),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} hmotnosti Země),
						'many' => q({0} hmotnosti Země),
						'name' => q(hmotnosti Země),
						'one' => q({0} hmotnost Země),
						'other' => q({0} hmotností Země),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grainy),
						'many' => q({0} grainu),
						'name' => q(grainy),
						'one' => q({0} grain),
						'other' => q({0} grainů),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grainy),
						'many' => q({0} grainu),
						'name' => q(grainy),
						'one' => q({0} grain),
						'other' => q({0} grainů),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(inanimate),
						'few' => q({0} gramy),
						'many' => q({0} gramu),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramů),
						'per' => q({0} na gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(inanimate),
						'few' => q({0} gramy),
						'many' => q({0} gramu),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramů),
						'per' => q({0} na gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(inanimate),
						'few' => q({0} kilogramy),
						'many' => q({0} kilogramu),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramů),
						'per' => q({0} na kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(inanimate),
						'few' => q({0} kilogramy),
						'many' => q({0} kilogramu),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramů),
						'per' => q({0} na kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(inanimate),
						'few' => q({0} mikrogramy),
						'many' => q({0} mikrogramu),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramů),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(inanimate),
						'few' => q({0} mikrogramy),
						'many' => q({0} mikrogramu),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramů),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(inanimate),
						'few' => q({0} miligramy),
						'many' => q({0} miligramu),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramů),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(inanimate),
						'few' => q({0} miligramy),
						'many' => q({0} miligramu),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramů),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unce),
						'many' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unce),
						'other' => q({0} uncí),
						'per' => q({0} na unci),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unce),
						'many' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unce),
						'other' => q({0} uncí),
						'per' => q({0} na unci),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} trojské unce),
						'many' => q({0} trojské unce),
						'name' => q(trojské unce),
						'one' => q({0} trojská unce),
						'other' => q({0} trojských uncí),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} trojské unce),
						'many' => q({0} trojské unce),
						'name' => q(trojské unce),
						'one' => q({0} trojská unce),
						'other' => q({0} trojských uncí),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} libry),
						'many' => q({0} libry),
						'name' => q(libry),
						'one' => q({0} libra),
						'other' => q({0} liber),
						'per' => q({0} na libru),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} libry),
						'many' => q({0} libry),
						'name' => q(libry),
						'one' => q({0} libra),
						'other' => q({0} liber),
						'per' => q({0} na libru),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} hmotnosti Slunce),
						'many' => q({0} hmotnosti Slunce),
						'name' => q(hmotnosti Slunce),
						'one' => q({0} hmotnost Slunce),
						'other' => q({0} hmotností Slunce),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} hmotnosti Slunce),
						'many' => q({0} hmotnosti Slunce),
						'name' => q(hmotnosti Slunce),
						'one' => q({0} hmotnost Slunce),
						'other' => q({0} hmotností Slunce),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} kameny),
						'many' => q({0} kamene),
						'name' => q(kameny),
						'one' => q({0} kámen),
						'other' => q({0} kamenů),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} kameny),
						'many' => q({0} kamene),
						'name' => q(kameny),
						'one' => q({0} kámen),
						'other' => q({0} kamenů),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} americké tuny),
						'many' => q({0} americké tuny),
						'name' => q(americké tuny),
						'one' => q({0} americká tuna),
						'other' => q({0} amerických tun),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} americké tuny),
						'many' => q({0} americké tuny),
						'name' => q(americké tuny),
						'one' => q({0} americká tuna),
						'other' => q({0} amerických tun),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'few' => q({0} tuny),
						'many' => q({0} tuny),
						'name' => q(tuny),
						'one' => q({0} tuna),
						'other' => q({0} tun),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'few' => q({0} tuny),
						'many' => q({0} tuny),
						'name' => q(tuny),
						'one' => q({0} tuna),
						'other' => q({0} tun),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(inanimate),
						'few' => q({0} gigawatty),
						'many' => q({0} gigawattu),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattů),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(inanimate),
						'few' => q({0} gigawatty),
						'many' => q({0} gigawattu),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattů),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} koňské síly),
						'many' => q({0} koňské síly),
						'name' => q(koňská síla),
						'one' => q({0} koňská síla),
						'other' => q({0} koňských sil),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} koňské síly),
						'many' => q({0} koňské síly),
						'name' => q(koňská síla),
						'one' => q({0} koňská síla),
						'other' => q({0} koňských sil),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(inanimate),
						'few' => q({0} kilowatty),
						'many' => q({0} kilowattu),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattů),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(inanimate),
						'few' => q({0} kilowatty),
						'many' => q({0} kilowattu),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattů),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(inanimate),
						'few' => q({0} megawatty),
						'many' => q({0} megawattu),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattů),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(inanimate),
						'few' => q({0} megawatty),
						'many' => q({0} megawattu),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattů),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(inanimate),
						'few' => q({0} miliwatty),
						'many' => q({0} miliwattu),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattů),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(inanimate),
						'few' => q({0} miliwatty),
						'many' => q({0} miliwattu),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattů),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(inanimate),
						'few' => q({0} watty),
						'many' => q({0} wattu),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattů),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(inanimate),
						'few' => q({0} watty),
						'many' => q({0} wattu),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattů),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q({0} čtvereční),
						'many' => q({0} čtverečního),
						'one' => q({0} čtvereční),
						'other' => q({0} čtverečních),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q({0} čtvereční),
						'many' => q({0} čtverečního),
						'one' => q({0} čtvereční),
						'other' => q({0} čtverečních),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q({0} krychlová),
						'many' => q({0} krychlového),
						'one' => q({0} krychlové),
						'other' => q({0} krychlových),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q({0} krychlová),
						'many' => q({0} krychlového),
						'one' => q({0} krychlové),
						'other' => q({0} krychlových),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosféry),
						'many' => q({0} atmosféry),
						'name' => q(atmosféry),
						'one' => q({0} atmosféra),
						'other' => q({0} atmosfér),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosféry),
						'many' => q({0} atmosféry),
						'name' => q(atmosféry),
						'one' => q({0} atmosféra),
						'other' => q({0} atmosfér),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(inanimate),
						'few' => q({0} bary),
						'many' => q({0} baru),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barů),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(inanimate),
						'few' => q({0} bary),
						'many' => q({0} baru),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barů),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(inanimate),
						'few' => q({0} hektopascaly),
						'many' => q({0} hektopascalu),
						'name' => q(hektopascaly),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalů),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(inanimate),
						'few' => q({0} hektopascaly),
						'many' => q({0} hektopascalu),
						'name' => q(hektopascaly),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalů),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} palce rtuťového sloupce),
						'many' => q({0} palce rtuťového sloupce),
						'name' => q(palce rtuťového sloupce),
						'one' => q({0} palec rtuťového sloupce),
						'other' => q({0} palců rtuťového sloupce),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} palce rtuťového sloupce),
						'many' => q({0} palce rtuťového sloupce),
						'name' => q(palce rtuťového sloupce),
						'one' => q({0} palec rtuťového sloupce),
						'other' => q({0} palců rtuťového sloupce),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(inanimate),
						'few' => q({0} kilopascaly),
						'many' => q({0} kilopascalu),
						'name' => q(kilopascaly),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalů),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(inanimate),
						'few' => q({0} kilopascaly),
						'many' => q({0} kilopascalu),
						'name' => q(kilopascaly),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalů),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(inanimate),
						'few' => q({0} megapascaly),
						'many' => q({0} megapascalu),
						'name' => q(megapascaly),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalů),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(inanimate),
						'few' => q({0} megapascaly),
						'many' => q({0} megapascalu),
						'name' => q(megapascaly),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalů),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(inanimate),
						'few' => q({0} milibary),
						'many' => q({0} milibaru),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarů),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(inanimate),
						'few' => q({0} milibary),
						'many' => q({0} milibaru),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarů),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetry rtuťového sloupce),
						'many' => q({0} milimetru rtuťového sloupce),
						'name' => q(milimetry rtuťového sloupce),
						'one' => q({0} milimetr rtuťového sloupce),
						'other' => q({0} milimetrů rtuťového sloupce),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetry rtuťového sloupce),
						'many' => q({0} milimetru rtuťového sloupce),
						'name' => q(milimetry rtuťového sloupce),
						'one' => q({0} milimetr rtuťového sloupce),
						'other' => q({0} milimetrů rtuťového sloupce),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(inanimate),
						'few' => q({0} pascaly),
						'many' => q({0} pascalu),
						'name' => q(pascaly),
						'one' => q({0} pascal),
						'other' => q({0} pascalů),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(inanimate),
						'few' => q({0} pascaly),
						'many' => q({0} pascalu),
						'name' => q(pascaly),
						'one' => q({0} pascal),
						'other' => q({0} pascalů),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} libry na čtvereční palec),
						'many' => q({0} libry na čtvereční palec),
						'name' => q(libry na čtvereční palec),
						'one' => q({0} libra na čtvereční palec),
						'other' => q({0} liber na čtvereční palec),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} libry na čtvereční palec),
						'many' => q({0} libry na čtvereční palec),
						'name' => q(libry na čtvereční palec),
						'one' => q({0} libra na čtvereční palec),
						'other' => q({0} liber na čtvereční palec),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0}. stupeň Beaufortovy stupnice),
						'many' => q({0}. stupeň Beaufortovy stupnice),
						'name' => q(stupně Beaufortovy stupnice),
						'one' => q({0}. stupeň Beaufortovy stupnice),
						'other' => q({0}. stupeň Beaufortovy stupnice),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0}. stupeň Beaufortovy stupnice),
						'many' => q({0}. stupeň Beaufortovy stupnice),
						'name' => q(stupně Beaufortovy stupnice),
						'one' => q({0}. stupeň Beaufortovy stupnice),
						'other' => q({0}. stupeň Beaufortovy stupnice),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry za hodinu),
						'many' => q({0} kilometru za hodinu),
						'name' => q(kilometry za hodinu),
						'one' => q({0} kilometr za hodinu),
						'other' => q({0} kilometrů za hodinu),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry za hodinu),
						'many' => q({0} kilometru za hodinu),
						'name' => q(kilometry za hodinu),
						'one' => q({0} kilometr za hodinu),
						'other' => q({0} kilometrů za hodinu),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} uzly),
						'many' => q({0} uzlu),
						'name' => q(uzly),
						'one' => q({0} uzel),
						'other' => q({0} uzlů),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} uzly),
						'many' => q({0} uzlu),
						'name' => q(uzly),
						'one' => q({0} uzel),
						'other' => q({0} uzlů),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(inanimate),
						'few' => q({0} metry za sekundu),
						'many' => q({0} metru za sekundu),
						'name' => q(metry za sekundu),
						'one' => q({0} metr za sekundu),
						'other' => q({0} metrů za sekundu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(inanimate),
						'few' => q({0} metry za sekundu),
						'many' => q({0} metru za sekundu),
						'name' => q(metry za sekundu),
						'one' => q({0} metr za sekundu),
						'other' => q({0} metrů za sekundu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} míle za hodinu),
						'many' => q({0} míle za hodinu),
						'name' => q(míle za hodinu),
						'one' => q({0} míle za hodinu),
						'other' => q({0} mil za hodinu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} míle za hodinu),
						'many' => q({0} míle za hodinu),
						'name' => q(míle za hodinu),
						'one' => q({0} míle za hodinu),
						'other' => q({0} mil za hodinu),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(inanimate),
						'few' => q({0} stupně Celsia),
						'many' => q({0} stupně Celsia),
						'name' => q(stupně Celsia),
						'one' => q({0} stupeň Celsia),
						'other' => q({0} stupňů Celsia),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(inanimate),
						'few' => q({0} stupně Celsia),
						'many' => q({0} stupně Celsia),
						'name' => q(stupně Celsia),
						'one' => q({0} stupeň Celsia),
						'other' => q({0} stupňů Celsia),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stupně Fahrenheita),
						'many' => q({0} stupně Fahrenheita),
						'name' => q(stupně Fahrenheita),
						'one' => q({0} stupeň Fahrenheita),
						'other' => q({0} stupňů Fahrenheita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stupně Fahrenheita),
						'many' => q({0} stupně Fahrenheita),
						'name' => q(stupně Fahrenheita),
						'one' => q({0} stupeň Fahrenheita),
						'other' => q({0} stupňů Fahrenheita),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(inanimate),
						'few' => q({0} stupně),
						'many' => q({0} stupně),
						'name' => q(stupně),
						'one' => q({0} stupeň),
						'other' => q({0} stupňů),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(inanimate),
						'few' => q({0} stupně),
						'many' => q({0} stupně),
						'name' => q(stupně),
						'one' => q({0} stupeň),
						'other' => q({0} stupňů),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(inanimate),
						'few' => q({0} kelviny),
						'many' => q({0} kelvinu),
						'name' => q(kelviny),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinů),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(inanimate),
						'few' => q({0} kelviny),
						'many' => q({0} kelvinu),
						'name' => q(kelviny),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinů),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(inanimate),
						'few' => q({0} newtonmetry),
						'many' => q({0} newtonmetru),
						'name' => q(newtonmetry),
						'one' => q({0} newtonmetr),
						'other' => q({0} newtonmetrů),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(inanimate),
						'few' => q({0} newtonmetry),
						'many' => q({0} newtonmetru),
						'name' => q(newtonmetry),
						'one' => q({0} newtonmetr),
						'other' => q({0} newtonmetrů),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} librostopy),
						'many' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostop),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} librostopy),
						'many' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostop),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} akro-stopy),
						'many' => q({0} akro-stopy),
						'name' => q(akro-stopy),
						'one' => q({0} akro-stopa),
						'other' => q({0} akro-stop),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} akro-stopy),
						'many' => q({0} akro-stopy),
						'name' => q(akro-stopy),
						'one' => q({0} akro-stopa),
						'other' => q({0} akro-stop),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barely),
						'many' => q({0} barelu),
						'name' => q(barely),
						'one' => q({0} barel),
						'other' => q({0} barelů),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barely),
						'many' => q({0} barelu),
						'name' => q(barely),
						'one' => q({0} barel),
						'other' => q({0} barelů),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušly),
						'many' => q({0} bušlu),
						'name' => q(bušly),
						'one' => q({0} bušl),
						'other' => q({0} bušlů),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušly),
						'many' => q({0} bušlu),
						'name' => q(bušly),
						'one' => q({0} bušl),
						'other' => q({0} bušlů),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(inanimate),
						'few' => q({0} centilitry),
						'many' => q({0} centilitru),
						'name' => q(centilitry),
						'one' => q({0} centilitr),
						'other' => q({0} centilitrů),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(inanimate),
						'few' => q({0} centilitry),
						'many' => q({0} centilitru),
						'name' => q(centilitry),
						'one' => q({0} centilitr),
						'other' => q({0} centilitrů),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetry krychlové),
						'many' => q({0} centimetru krychlového),
						'name' => q(centimetry krychlové),
						'one' => q({0} centimetr krychlový),
						'other' => q({0} centimetrů krychlových),
						'per' => q({0} na centimetr krychlový),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetry krychlové),
						'many' => q({0} centimetru krychlového),
						'name' => q(centimetry krychlové),
						'one' => q({0} centimetr krychlový),
						'other' => q({0} centimetrů krychlových),
						'per' => q({0} na centimetr krychlový),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} stopy krychlové),
						'many' => q({0} stopy krychlové),
						'name' => q(stopy krychlové),
						'one' => q({0} stopa krychlová),
						'other' => q({0} stop krychlových),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} stopy krychlové),
						'many' => q({0} stopy krychlové),
						'name' => q(stopy krychlové),
						'one' => q({0} stopa krychlová),
						'other' => q({0} stop krychlových),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} palce krychlové),
						'many' => q({0} palce krychlového),
						'name' => q(palce krychlové),
						'one' => q({0} palec krychlový),
						'other' => q({0} palců krychlových),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} palce krychlové),
						'many' => q({0} palce krychlového),
						'name' => q(palce krychlové),
						'one' => q({0} palec krychlový),
						'other' => q({0} palců krychlových),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry krychlové),
						'many' => q({0} kilometru krychlového),
						'name' => q(kilometry krychlové),
						'one' => q({0} kilometr krychlový),
						'other' => q({0} kilometrů krychlových),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometry krychlové),
						'many' => q({0} kilometru krychlového),
						'name' => q(kilometry krychlové),
						'one' => q({0} kilometr krychlový),
						'other' => q({0} kilometrů krychlových),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metry krychlové),
						'many' => q({0} metru krychlového),
						'name' => q(metry krychlové),
						'one' => q({0} metr krychlový),
						'other' => q({0} metrů krychlových),
						'per' => q({0} na metr krychlový),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metry krychlové),
						'many' => q({0} metru krychlového),
						'name' => q(metry krychlové),
						'one' => q({0} metr krychlový),
						'other' => q({0} metrů krychlových),
						'per' => q({0} na metr krychlový),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} míle krychlové),
						'many' => q({0} míle krychlové),
						'name' => q(míle krychlové),
						'one' => q({0} míle krychlová),
						'other' => q({0} mil krychlových),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} míle krychlové),
						'many' => q({0} míle krychlové),
						'name' => q(míle krychlové),
						'one' => q({0} míle krychlová),
						'other' => q({0} mil krychlových),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} yardy krychlové),
						'many' => q({0} yardu krychlového),
						'name' => q(yardy krychlové),
						'one' => q({0} yard krychlový),
						'other' => q({0} yardů krychlových),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} yardy krychlové),
						'many' => q({0} yardu krychlového),
						'name' => q(yardy krychlové),
						'one' => q({0} yard krychlový),
						'other' => q({0} yardů krychlových),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} šálky),
						'many' => q({0} šálku),
						'name' => q(šálky),
						'one' => q({0} šálek),
						'other' => q({0} šálků),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} šálky),
						'many' => q({0} šálku),
						'name' => q(šálky),
						'one' => q({0} šálek),
						'other' => q({0} šálků),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(inanimate),
						'few' => q({0} metrické šálky),
						'many' => q({0} metrického šálku),
						'name' => q(metrické šálky),
						'one' => q({0} metrický šálek),
						'other' => q({0} metrických šálků),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(inanimate),
						'few' => q({0} metrické šálky),
						'many' => q({0} metrického šálku),
						'name' => q(metrické šálky),
						'one' => q({0} metrický šálek),
						'other' => q({0} metrických šálků),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(inanimate),
						'few' => q({0} decilitry),
						'many' => q({0} decilitru),
						'name' => q(decilitry),
						'one' => q({0} decilitr),
						'other' => q({0} decilitrů),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(inanimate),
						'few' => q({0} decilitry),
						'many' => q({0} decilitru),
						'name' => q(decilitry),
						'one' => q({0} decilitr),
						'other' => q({0} decilitrů),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dezertní lžičky),
						'many' => q({0} dezertní lžičky),
						'name' => q(dezertní lžičky),
						'one' => q({0} dezertní lžička),
						'other' => q({0} dezertních lžiček),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dezertní lžičky),
						'many' => q({0} dezertní lžičky),
						'name' => q(dezertní lžičky),
						'one' => q({0} dezertní lžička),
						'other' => q({0} dezertních lžiček),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} britské dezertní lžičky),
						'many' => q({0} britské dezertní lžičky),
						'name' => q(britské dezertní lžičky),
						'one' => q({0} britská dezertní lžička),
						'other' => q({0} britských dezertních lžiček),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} britské dezertní lžičky),
						'many' => q({0} britské dezertní lžičky),
						'name' => q(britské dezertní lžičky),
						'one' => q({0} britská dezertní lžička),
						'other' => q({0} britských dezertních lžiček),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} duté dramy),
						'many' => q({0} dutého dramu),
						'name' => q(duté dramy),
						'one' => q({0} dutý dram),
						'other' => q({0} dutých dramů),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} duté dramy),
						'many' => q({0} dutého dramu),
						'name' => q(duté dramy),
						'one' => q({0} dutý dram),
						'other' => q({0} dutých dramů),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} duté unce),
						'many' => q({0} duté unce),
						'name' => q(duté unce),
						'one' => q({0} dutá unce),
						'other' => q({0} dutých uncí),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} duté unce),
						'many' => q({0} duté unce),
						'name' => q(duté unce),
						'one' => q({0} dutá unce),
						'other' => q({0} dutých uncí),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} britské duté unce),
						'many' => q({0} britské duté unce),
						'name' => q(britské duté unce),
						'one' => q({0} britská dutá unce),
						'other' => q({0} britských dutých uncí),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} britské duté unce),
						'many' => q({0} britské duté unce),
						'name' => q(britské duté unce),
						'one' => q({0} britská dutá unce),
						'other' => q({0} britských dutých uncí),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galony),
						'many' => q({0} galonu),
						'name' => q(galony),
						'one' => q({0} galon),
						'other' => q({0} galonů),
						'per' => q({0} na galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galony),
						'many' => q({0} galonu),
						'name' => q(galony),
						'one' => q({0} galon),
						'other' => q({0} galonů),
						'per' => q({0} na galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} britské galony),
						'many' => q({0} britského galonu),
						'name' => q(britské galony),
						'one' => q({0} britský galon),
						'other' => q({0} britských galonů),
						'per' => q({0} na britský galon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} britské galony),
						'many' => q({0} britského galonu),
						'name' => q(britské galony),
						'one' => q({0} britský galon),
						'other' => q({0} britských galonů),
						'per' => q({0} na britský galon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(inanimate),
						'few' => q({0} hektolitry),
						'many' => q({0} hektolitru),
						'name' => q(hektolitry),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitrů),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(inanimate),
						'few' => q({0} hektolitry),
						'many' => q({0} hektolitru),
						'name' => q(hektolitry),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitrů),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} barmanské odměrky),
						'many' => q({0} barmanské odměrky),
						'name' => q(barmanské odměrky),
						'one' => q({0} barmanská odměrka),
						'other' => q({0} barmanských odměrek),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} barmanské odměrky),
						'many' => q({0} barmanské odměrky),
						'name' => q(barmanské odměrky),
						'one' => q({0} barmanská odměrka),
						'other' => q({0} barmanských odměrek),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(inanimate),
						'few' => q({0} litry),
						'many' => q({0} litru),
						'name' => q(litry),
						'one' => q({0} litr),
						'other' => q({0} litrů),
						'per' => q({0} na litr),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(inanimate),
						'few' => q({0} litry),
						'many' => q({0} litru),
						'name' => q(litry),
						'one' => q({0} litr),
						'other' => q({0} litrů),
						'per' => q({0} na litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(inanimate),
						'few' => q({0} megalitry),
						'many' => q({0} megalitru),
						'name' => q(megalitry),
						'one' => q({0} megalitr),
						'other' => q({0} megalitrů),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(inanimate),
						'few' => q({0} megalitry),
						'many' => q({0} megalitru),
						'name' => q(megalitry),
						'one' => q({0} megalitr),
						'other' => q({0} megalitrů),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(inanimate),
						'few' => q({0} mililitry),
						'many' => q({0} mililitru),
						'name' => q(mililitry),
						'one' => q({0} mililitr),
						'other' => q({0} mililitrů),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(inanimate),
						'few' => q({0} mililitry),
						'many' => q({0} mililitru),
						'name' => q(mililitry),
						'one' => q({0} mililitr),
						'other' => q({0} mililitrů),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinty),
						'many' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pinta),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinty),
						'many' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pinta),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrické pinty),
						'many' => q({0} metrické pinty),
						'name' => q(metrické pinty),
						'one' => q({0} metrická pinta),
						'other' => q({0} metrických pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrické pinty),
						'many' => q({0} metrické pinty),
						'name' => q(metrické pinty),
						'one' => q({0} metrická pinta),
						'other' => q({0} metrických pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} kvarty),
						'many' => q({0} kvartu),
						'name' => q(kvarty),
						'one' => q({0} kvart),
						'other' => q({0} kvartů),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} kvarty),
						'many' => q({0} kvartu),
						'name' => q(kvarty),
						'one' => q({0} kvart),
						'other' => q({0} kvartů),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} britské kvarty),
						'many' => q({0} britského kvartu),
						'name' => q(britské kvarty),
						'one' => q({0} britský kvart),
						'other' => q({0} britských kvartů),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} britské kvarty),
						'many' => q({0} britského kvartu),
						'name' => q(britské kvarty),
						'one' => q({0} britský kvart),
						'other' => q({0} britských kvartů),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} lžíce),
						'many' => q({0} lžíce),
						'name' => q(lžíce),
						'one' => q({0} lžíce),
						'other' => q({0} lžic),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} lžíce),
						'many' => q({0} lžíce),
						'name' => q(lžíce),
						'one' => q({0} lžíce),
						'other' => q({0} lžic),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} lžičky),
						'many' => q({0} lžičky),
						'name' => q(lžičky),
						'one' => q({0} lžička),
						'other' => q({0} lžiček),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} lžičky),
						'many' => q({0} lžičky),
						'name' => q(lžičky),
						'one' => q({0} lžička),
						'other' => q({0} lžiček),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} pol.),
						'many' => q({0} pol.),
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} pol.),
						'many' => q({0} pol.),
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'many' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'many' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpgIm),
						'many' => q({0} mpgIm),
						'name' => q(mpgIm),
						'one' => q({0} mpgIm),
						'other' => q({0} mpgIm),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpgIm),
						'many' => q({0} mpgIm),
						'name' => q(mpgIm),
						'one' => q({0} mpgIm),
						'other' => q({0} mpgIm),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} d.),
						'many' => q({0} d.),
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} d.),
						'many' => q({0} d.),
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dek.),
						'many' => q({0} dek.),
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dek.),
						'many' => q({0} dek.),
						'name' => q(dek.),
						'one' => q({0} dek.),
						'other' => q({0} dek.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} kv.),
						'many' => q({0} kv.),
						'name' => q(kv.),
						'one' => q({0} kv.),
						'other' => q({0} kv.),
						'per' => q({0}/kv.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} kv.),
						'many' => q({0} kv.),
						'name' => q(kv.),
						'one' => q({0} kv.),
						'other' => q({0} kv.),
						'per' => q({0}/kv.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} t.),
						'many' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} t.),
						'many' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} r.),
						'many' => q({0} r.),
						'name' => q(r.),
						'one' => q({0} r.),
						'other' => q({0} l.),
						'per' => q({0}/r.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} r.),
						'many' => q({0} r.),
						'name' => q(r.),
						'one' => q({0} r.),
						'other' => q({0} l.),
						'per' => q({0}/r.),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(bod),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(bod),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0}″ Hg),
						'many' => q({0}″ Hg),
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0}″ Hg),
						'many' => q({0}″ Hg),
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} dspIm),
						'many' => q({0} dspIm),
						'name' => q(dspIm),
						'one' => q({0} dspIm),
						'other' => q({0} dspIm),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} dspIm),
						'many' => q({0} dspIm),
						'name' => q(dspIm),
						'one' => q({0} dspIm),
						'other' => q({0} dspIm),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz Im),
						'many' => q({0} fl oz Im),
						'name' => q(fl oz Im),
						'one' => q({0} fl oz Im),
						'other' => q({0} fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz Im),
						'many' => q({0} fl oz Im),
						'name' => q(fl oz Im),
						'one' => q({0} fl oz Im),
						'other' => q({0} fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} galIm),
						'many' => q({0} galIm),
						'name' => q(galIm),
						'one' => q({0} galIm),
						'other' => q({0} galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} galIm),
						'many' => q({0} galIm),
						'name' => q(galIm),
						'one' => q({0} galIm),
						'other' => q({0} galIm),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} odm.),
						'many' => q({0} odm.),
						'name' => q(odm.),
						'one' => q({0} odm.),
						'other' => q({0} odm.),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} odm.),
						'many' => q({0} odm.),
						'name' => q(odm.),
						'one' => q({0} odm.),
						'other' => q({0} odm.),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} šp.),
						'many' => q({0} šp.),
						'name' => q(šp.),
						'one' => q({0} šp.),
						'other' => q({0} šp.),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} šp.),
						'many' => q({0} šp.),
						'name' => q(šp.),
						'one' => q({0} šp.),
						'other' => q({0} šp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(směr),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(směr),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
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
					'angle-revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dun.),
						'many' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dun.),
						'many' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
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
						'few' => q({0} položky),
						'many' => q({0} položky),
						'name' => q(položky),
						'one' => q({0} položka),
						'other' => q({0} položek),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} položky),
						'many' => q({0} položky),
						'name' => q(položky),
						'one' => q({0} položka),
						'other' => q({0} položek),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'many' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'many' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} v. d.),
						'north' => q({0} s. š.),
						'south' => q({0} j. š.),
						'west' => q({0} z. d.),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} v. d.),
						'north' => q({0} s. š.),
						'south' => q({0} j. š.),
						'west' => q({0} z. d.),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} b),
						'many' => q({0} b),
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} b),
						'many' => q({0} b),
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} B),
						'many' => q({0} B),
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} B),
						'many' => q({0} B),
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} stol.),
						'many' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} stol.),
						'many' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dny),
						'many' => q({0} dne),
						'name' => q(dny),
						'one' => q({0} den),
						'other' => q({0} dnů),
						'per' => q({0}/den),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dny),
						'many' => q({0} dne),
						'name' => q(dny),
						'one' => q({0} den),
						'other' => q({0} dnů),
						'per' => q({0}/den),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} desetil.),
						'many' => q({0} desetil.),
						'name' => q(desetil.),
						'one' => q({0} desetil.),
						'other' => q({0} desetil.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} desetil.),
						'many' => q({0} desetil.),
						'name' => q(desetil.),
						'one' => q({0} desetil.),
						'other' => q({0} desetil.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} měs.),
						'many' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'per' => q({0}/měs.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} měs.),
						'many' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'per' => q({0}/měs.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} čtvrtl.),
						'many' => q({0} čtvrtl.),
						'name' => q(čtvrtl.),
						'one' => q({0} čtvrtl.),
						'other' => q({0} čtvrtl.),
						'per' => q({0}/čtvrtl.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} čtvrtl.),
						'many' => q({0} čtvrtl.),
						'name' => q(čtvrtl.),
						'one' => q({0} čtvrtl.),
						'other' => q({0} čtvrtl.),
						'per' => q({0}/čtvrtl.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} týd.),
						'many' => q({0} týd.),
						'name' => q(týd.),
						'one' => q({0} týd.),
						'other' => q({0} týd.),
						'per' => q({0}/týd.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} týd.),
						'many' => q({0} týd.),
						'name' => q(týd.),
						'one' => q({0} týd.),
						'other' => q({0} týd.),
						'per' => q({0}/týd.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} roky),
						'many' => q({0} roku),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} let),
						'per' => q({0}/rok),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} roky),
						'many' => q({0} roku),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} let),
						'per' => q({0}/rok),
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
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} BTU),
						'many' => q({0} BTU),
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} BTU),
						'many' => q({0} BTU),
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} therm),
						'many' => q({0} therm),
						'name' => q(therm),
						'one' => q({0} therm),
						'other' => q({0} therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} therm),
						'many' => q({0} therm),
						'name' => q(therm),
						'one' => q({0} therm),
						'other' => q({0} therm),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pixely),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pixely),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} DPCM),
						'many' => q({0} DPCM),
						'name' => q(DPCM),
						'one' => q({0} DPCM),
						'other' => q({0} DPCM),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} DPCM),
						'many' => q({0} DPCM),
						'name' => q(DPCM),
						'one' => q({0} DPCM),
						'other' => q({0} DPCM),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} DPI),
						'many' => q({0} DPI),
						'name' => q(DPI),
						'one' => q({0} DPI),
						'other' => q({0} DPI),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} DPI),
						'many' => q({0} DPI),
						'name' => q(DPI),
						'one' => q({0} DPI),
						'other' => q({0} DPI),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} Mpx),
						'many' => q({0} Mpx),
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} Mpx),
						'many' => q({0} Mpx),
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} PPCM),
						'many' => q({0} PPCM),
						'name' => q(PPCM),
						'one' => q({0} PPCM),
						'other' => q({0} PPCM),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} PPCM),
						'many' => q({0} PPCM),
						'name' => q(PPCM),
						'one' => q({0} PPCM),
						'other' => q({0} PPCM),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} PPI),
						'many' => q({0} PPI),
						'name' => q(PPI),
						'one' => q({0} PPI),
						'other' => q({0} PPI),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} PPI),
						'many' => q({0} PPI),
						'name' => q(PPI),
						'one' => q({0} PPI),
						'other' => q({0} PPI),
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
					'mass-grain' => {
						'few' => q({0} gr),
						'many' => q({0} gr),
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} gr),
						'many' => q({0} gr),
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
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
					'mass-ton' => {
						'few' => q({0} sht),
						'many' => q({0} sht),
						'name' => q(sht),
						'one' => q({0} sht),
						'other' => q({0} sht),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} sht),
						'many' => q({0} sht),
						'name' => q(sht),
						'one' => q({0} sht),
						'other' => q({0} sht),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mb),
						'many' => q({0} mb),
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mb),
						'many' => q({0} mb),
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0} Bft),
						'many' => q({0} Bft),
						'one' => q({0} Bft),
						'other' => q({0} Bft),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0} Bft),
						'many' => q({0} Bft),
						'one' => q({0} Bft),
						'other' => q({0} Bft),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} Nm),
						'many' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} Nm),
						'many' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} dstspn Imp.),
						'many' => q({0} dstspn Imp.),
						'name' => q(dstspn Imp.),
						'one' => q({0} dstspn Imp.),
						'other' => q({0} dstspn Imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} dstspn Imp.),
						'many' => q({0} dstspn Imp.),
						'name' => q(dstspn Imp.),
						'one' => q({0} dstspn Imp.),
						'other' => q({0} dstspn Imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} fl dr),
						'many' => q({0} fl dr),
						'name' => q(fl dr),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} fl dr),
						'many' => q({0} fl dr),
						'name' => q(fl dr),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kapky),
						'many' => q({0} kapky),
						'name' => q(kapky),
						'one' => q({0} kapka),
						'other' => q({0} kapek),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kapky),
						'many' => q({0} kapky),
						'name' => q(kapky),
						'one' => q({0} kapka),
						'other' => q({0} kapek),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal Imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} odměrky),
						'many' => q({0} odměrky),
						'name' => q(odměrky),
						'one' => q({0} odměrka),
						'other' => q({0} odměrek),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} odměrky),
						'many' => q({0} odměrky),
						'name' => q(odměrky),
						'one' => q({0} odměrka),
						'other' => q({0} odměrek),
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
					'volume-megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} špetky),
						'many' => q({0} špetky),
						'name' => q(špetky),
						'one' => q({0} špetka),
						'other' => q({0} špetek),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} špetky),
						'many' => q({0} špetky),
						'name' => q(špetky),
						'one' => q({0} špetka),
						'other' => q({0} špetek),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ano|a|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ne|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} a {1}),
				2 => q({0} a {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
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
					'few' => '0 tisíce',
					'many' => '0 tisíce',
					'one' => '0 tisíc',
					'other' => '0 tisíc',
				},
				'10000' => {
					'few' => '00 tisíc',
					'many' => '00 tisíce',
					'one' => '00 tisíc',
					'other' => '00 tisíc',
				},
				'100000' => {
					'few' => '000 tisíc',
					'many' => '000 tisíce',
					'one' => '000 tisíc',
					'other' => '000 tisíc',
				},
				'1000000' => {
					'few' => '0 miliony',
					'many' => '0 milionu',
					'one' => '0 milion',
					'other' => '0 milionů',
				},
				'10000000' => {
					'few' => '00 milionů',
					'many' => '00 milionu',
					'one' => '00 milionů',
					'other' => '00 milionů',
				},
				'100000000' => {
					'few' => '000 milionů',
					'many' => '000 milionu',
					'one' => '000 milionů',
					'other' => '000 milionů',
				},
				'1000000000' => {
					'few' => '0 miliardy',
					'many' => '0 miliardy',
					'one' => '0 miliarda',
					'other' => '0 miliard',
				},
				'10000000000' => {
					'few' => '00 miliard',
					'many' => '00 miliardy',
					'one' => '00 miliard',
					'other' => '00 miliard',
				},
				'100000000000' => {
					'few' => '000 miliard',
					'many' => '000 miliardy',
					'one' => '000 miliard',
					'other' => '000 miliard',
				},
				'1000000000000' => {
					'few' => '0 biliony',
					'many' => '0 bilionu',
					'one' => '0 bilion',
					'other' => '0 bilionů',
				},
				'10000000000000' => {
					'few' => '00 bilionů',
					'many' => '00 bilionu',
					'one' => '00 bilionů',
					'other' => '00 bilionů',
				},
				'100000000000000' => {
					'few' => '000 bilionů',
					'many' => '000 bilionu',
					'one' => '000 bilionů',
					'other' => '000 bilionů',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
				'currency' => q(andorrská peseta),
				'few' => q(andorrské pesety),
				'many' => q(andorrské pesety),
				'one' => q(andorrská peseta),
				'other' => q(andorrských peset),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(SAE dirham),
				'few' => q(SAE dirhamy),
				'many' => q(SAE dirhamu),
				'one' => q(SAE dirham),
				'other' => q(SAE dirhamů),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghánský afghán \(1927–2002\)),
				'few' => q(afghánské afghány \(1927–2002\)),
				'many' => q(afghánského afghánu \(1927–2002\)),
				'one' => q(afghánský afghán \(1927–2002\)),
				'other' => q(afghánských afghánů \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghánský afghán),
				'few' => q(afghánské afghány),
				'many' => q(afghánského afghánu),
				'one' => q(afghánský afghán),
				'other' => q(afghánských afghánů),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albánský lek \(1946–1965\)),
				'few' => q(albánské leky \(1946–1965\)),
				'many' => q(albánského leku \(1946–1965\)),
				'one' => q(albánský lek \(1946–1965\)),
				'other' => q(albánských leků \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albánský lek),
				'few' => q(albánské leky),
				'many' => q(albánského leku),
				'one' => q(albánský lek),
				'other' => q(albánských leků),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(arménský dram),
				'few' => q(arménské dramy),
				'many' => q(arménského dramu),
				'one' => q(arménský dram),
				'other' => q(arménských dramů),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nizozemskoantilský gulden),
				'few' => q(nizozemskoantilské guldeny),
				'many' => q(nizozemskoantilského guldenu),
				'one' => q(nizozemskoantilský gulden),
				'other' => q(nizozemskoantilských guldenů),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolská kwanza),
				'few' => q(angolské kwanzy),
				'many' => q(angolské kwanzy),
				'one' => q(angolská kwanza),
				'other' => q(angolských kwanz),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolská kwanza \(1977–1991\)),
				'few' => q(angolské kwanzy \(1977–1991\)),
				'many' => q(angolské kwanzy \(1977–1991\)),
				'one' => q(angolská kwanza \(1977–1991\)),
				'other' => q(angolských kwanz \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolská kwanza \(1990–2000\)),
				'few' => q(angolské kwanzy \(1990–2000\)),
				'many' => q(angolské kwanzy \(1990–2000\)),
				'one' => q(angolská kwanza \(1990–2000\)),
				'other' => q(angolských kwanz \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolská kwanza \(1995–1999\)),
				'few' => q(angolská kwanza \(1995–1999\)),
				'many' => q(angolské kwanzy \(1995–1999\)),
				'one' => q(angolská nový kwanza \(1995–1999\)),
				'other' => q(angolských kwanz \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinský austral),
				'few' => q(argentinské australy),
				'many' => q(argentinského australu),
				'one' => q(argentinský austral),
				'other' => q(argentinských australů),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentinské peso ley \(1970–1983\)),
				'few' => q(argentinská pesa ley \(1970–1983\)),
				'many' => q(argentinského pesa ley \(1970–1983\)),
				'one' => q(argentinské peso ley \(1970–1983\)),
				'other' => q(argentinských pes ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentinské peso \(1881–1970\)),
				'few' => q(argentinská pesa \(1881–1970\)),
				'many' => q(argentinského pesa \(1881–1970\)),
				'one' => q(argentinské peso \(1881–1970\)),
				'other' => q(argentinských pes \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinské peso \(1983–1985\)),
				'few' => q(argentinská pesa \(1983–1985\)),
				'many' => q(argentinského pesa \(1983–1985\)),
				'one' => q(argentinské peso \(1983–1985\)),
				'other' => q(argentinských pes \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinské peso),
				'few' => q(argentinská pesa),
				'many' => q(argentinského pesa),
				'one' => q(argentinské peso),
				'other' => q(argentinských pes),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(rakouský šilink),
				'few' => q(rakouské šilinky),
				'many' => q(rakouského šilinku),
				'one' => q(rakouský šilink),
				'other' => q(rakouských šilinků),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(australský dolar),
				'few' => q(australské dolary),
				'many' => q(australského dolaru),
				'one' => q(australský dolar),
				'other' => q(australských dolarů),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubský zlatý),
				'few' => q(arubské zlaté),
				'many' => q(arubského zlatého),
				'one' => q(arubský zlatý),
				'other' => q(arubských zlatých),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(ázerbájdžánský manat \(1993–2006\)),
				'few' => q(ázerbájdžánské manaty \(1993–2006\)),
				'many' => q(ázerbájdžánského manatu \(1993–2006\)),
				'one' => q(ázerbájdžánský manat \(1993–2006\)),
				'other' => q(ázerbájdžánských manatů \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(ázerbájdžánský manat),
				'few' => q(ázerbájdžánské manaty),
				'many' => q(ázerbájdžánského manatu),
				'one' => q(ázerbájdžánský manat),
				'other' => q(ázerbájdžánských manatů),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosenský dinár \(1992–1994\)),
				'few' => q(bosenské dináry \(1992–1994\)),
				'many' => q(bosenského dináru \(1992–1994\)),
				'one' => q(bosenský dinár \(1992–1994\)),
				'other' => q(bosenských dinárů \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosenská konvertibilní marka),
				'few' => q(bosenské konvertibilní marky),
				'many' => q(bosenské konvertibilní marky),
				'one' => q(bosenská konvertibilní marka),
				'other' => q(bosenských konvertibilních marek),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(bosenský nový dinár \(1994–1997\)),
				'few' => q(bosenské nové dináry \(1994–1997\)),
				'many' => q(bosenského nového dináru \(1994–1997\)),
				'one' => q(bosenský nový dinár \(1994–1997\)),
				'other' => q(bosenských nových dinárů \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoský dolar),
				'few' => q(barbadoské dolary),
				'many' => q(barbadoského dolaru),
				'one' => q(barbadoský dolar),
				'other' => q(barbadoských dolarů),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladéšská taka),
				'few' => q(bangladéšské taky),
				'many' => q(bangladéšské taky),
				'one' => q(bangladéšská taka),
				'other' => q(bangladéšských tak),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgický konvertibilní frank),
				'few' => q(belgické konvertibilní franky),
				'many' => q(belgického konvertibilního franku),
				'one' => q(belgický konvertibilní frank),
				'other' => q(belgických konvertibilních franků),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgický frank),
				'few' => q(belgické franky),
				'many' => q(belgického franku),
				'one' => q(belgický frank),
				'other' => q(belgických franků),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgický finanční frank),
				'few' => q(belgické finanční franky),
				'many' => q(belgického finančního franku),
				'one' => q(belgický finanční frank),
				'other' => q(belgických finančních franků),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulharský tvrdý leva),
				'few' => q(bulharské tvrdé leva),
				'many' => q(bulharského tvrdého leva),
				'one' => q(bulharský tvrdý leva),
				'other' => q(bulharských tvrdých leva),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bulharský socialistický leva),
				'few' => q(bulharské socialistické leva),
				'many' => q(bulharského socialistického leva),
				'one' => q(bulharský socialistický leva),
				'other' => q(bulharských socialistických leva),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulharský leva),
				'few' => q(bulharské leva),
				'many' => q(bulharského leva),
				'one' => q(bulharský leva),
				'other' => q(bulharských leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulharský lev \(1879–1952\)),
				'few' => q(bulharské leva \(1879–1952\)),
				'many' => q(bulharského leva \(1879–1952\)),
				'one' => q(bulharský lev \(1879–1952\)),
				'other' => q(bulharských leva \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrajnský dinár),
				'few' => q(bahrajnské dináry),
				'many' => q(bahrajnského dináru),
				'one' => q(bahrajnský dinár),
				'other' => q(bahrajnských dinárů),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundský frank),
				'few' => q(burundské franky),
				'many' => q(burundského franku),
				'one' => q(burundský frank),
				'other' => q(burundských franků),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudský dolar),
				'few' => q(bermudské dolary),
				'many' => q(bermudského dolaru),
				'one' => q(bermudský dolar),
				'other' => q(bermudských dolarů),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brunejský dolar),
				'few' => q(brunejské dolary),
				'many' => q(brunejského dolaru),
				'one' => q(brunejský dolar),
				'other' => q(brunejských dolarů),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivijský boliviano),
				'few' => q(bolivijské bolivianos),
				'many' => q(bolivijského boliviana),
				'one' => q(bolivijský boliviano),
				'other' => q(bolivijských bolivianos),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(bolivijský boliviano \(1863–1963\)),
				'few' => q(bolivijské bolivianos \(1863–1963\)),
				'many' => q(bolivijského boliviana \(1863–1963\)),
				'one' => q(bolivijský boliviano \(1863–1963\)),
				'other' => q(bolivijských bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(bolivijské peso),
				'few' => q(bolivijská pesa),
				'many' => q(bolivijského pesa),
				'one' => q(bolivijské peso),
				'other' => q(bolivijských pes),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(bolivijský mvdol),
				'few' => q(bolivijské mvdoly),
				'many' => q(bolivijského mvdolu),
				'one' => q(bolivijský mvdol),
				'other' => q(bolivijských mvdolů),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazilské nové cruzeiro \(1967–1986\)),
				'few' => q(brazilská nová cruzeira \(1967–1986\)),
				'many' => q(brazilského nového cruzeira \(1967–1986\)),
				'one' => q(brazilské nové cruzeiro \(1967–1986\)),
				'other' => q(brazilských nových cruzeir \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilské cruzado \(1986–1989\)),
				'few' => q(brazilská cruzada \(1986–1989\)),
				'many' => q(brazilského cruzada \(1986–1989\)),
				'one' => q(brazilské cruzado \(1986–1989\)),
				'other' => q(brazilských cruzad \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brazilské cruzeiro \(1990–1993\)),
				'few' => q(brazilská cruzeira \(1990–1993\)),
				'many' => q(brazilského cruzeira \(1990–1993\)),
				'one' => q(brazilské cruzeiro \(1990–1993\)),
				'other' => q(brazilských cruzeir \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brazilský real),
				'few' => q(brazilské realy),
				'many' => q(brazilského realu),
				'one' => q(brazilský real),
				'other' => q(brazilských realů),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazilské nové cruzado \(1989–1990\)),
				'few' => q(brazilská nová cruzada \(1989–1990\)),
				'many' => q(brazilského nového cruzada \(1989–1990\)),
				'one' => q(brazilské nové cruzado \(1989–1990\)),
				'other' => q(brazilských nových cruzad \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brazilské cruzeiro \(1993–1994\)),
				'few' => q(brazilská cruzeira \(1993–1994\)),
				'many' => q(brazilského cruzeira \(1993–1994\)),
				'one' => q(brazilské cruzeiro \(1993–1994\)),
				'other' => q(brazilských cruzeir \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(brazilské cruzeiro \(1942–1967\)),
				'few' => q(brazilská cruzeira \(1942–1967\)),
				'many' => q(brazilského cruzeira \(1942–1967\)),
				'one' => q(brazilské cruzeiro \(1942–1967\)),
				'other' => q(brazilských cruzeir \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamský dolar),
				'few' => q(bahamské dolary),
				'many' => q(bahamského dolaru),
				'one' => q(bahamský dolar),
				'other' => q(bahamských dolarů),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhútánský ngultrum),
				'few' => q(bhútánské ngultrumy),
				'many' => q(bhútánského ngultrumu),
				'one' => q(bhútánský ngultrum),
				'other' => q(bhútánských ngultrumů),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(barmský kyat),
				'few' => q(barmské kyaty),
				'many' => q(barmského kyatu),
				'one' => q(barmský kyat),
				'other' => q(barmských kyatů),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanská pula),
				'few' => q(botswanské puly),
				'many' => q(botswanské puly),
				'one' => q(botswanská pula),
				'other' => q(botswanských pul),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(běloruský rubl \(1994–1999\)),
				'few' => q(běloruské rubly \(1994–1999\)),
				'many' => q(běloruského rublu \(1994–1999\)),
				'one' => q(běloruský rubl \(1994–1999\)),
				'other' => q(běloruských rublů \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(běloruský rubl),
				'few' => q(běloruské rubly),
				'many' => q(běloruského rublu),
				'one' => q(běloruský rubl),
				'other' => q(běloruských rublů),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(běloruský rubl \(2000–2016\)),
				'few' => q(běloruské rubly \(2000–2016\)),
				'many' => q(běloruského rublu \(2000–2016\)),
				'one' => q(běloruský rubl \(2000–2016\)),
				'other' => q(běloruských rublů \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizský dolar),
				'few' => q(belizské dolary),
				'many' => q(belizského dolaru),
				'one' => q(belizský dolar),
				'other' => q(belizských dolarů),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kanadský dolar),
				'few' => q(kanadské dolary),
				'many' => q(kanadského dolaru),
				'one' => q(kanadský dolar),
				'other' => q(kanadských dolarů),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(konžský frank),
				'few' => q(konžské franky),
				'many' => q(konžského franku),
				'one' => q(konžský frank),
				'other' => q(konžských franků),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(švýcarské WIR-euro),
				'few' => q(švýcarská WIR-eura),
				'many' => q(švýcarského WIR-eura),
				'one' => q(švýcarské WIR-euro),
				'other' => q(švýcarských WIR-eur),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(švýcarský frank),
				'few' => q(švýcarské franky),
				'many' => q(švýcarského franku),
				'one' => q(švýcarský frank),
				'other' => q(švýcarských franků),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(švýcarský WIR-frank),
				'few' => q(švýcarské WIR-franky),
				'many' => q(švýcarského WIR-franku),
				'one' => q(švýcarský WIR-frank),
				'other' => q(švýcarských WIR-franků),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(chilské escudo),
				'few' => q(chilská escuda),
				'many' => q(chilského escuda),
				'one' => q(chilské escudo),
				'other' => q(chilských escud),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(chilská účetní jednotka \(UF\)),
				'few' => q(chilské účetní jednotky \(UF\)),
				'many' => q(chilské účetní jednotky \(UF\)),
				'one' => q(chilská účetní jednotka \(UF\)),
				'other' => q(chilských účetních jednotek \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilské peso),
				'few' => q(chilská pesa),
				'many' => q(chilského pesa),
				'one' => q(chilské peso),
				'other' => q(chilských pes),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(čínský jüan \(offshore\)),
				'few' => q(čínské jüany \(offshore\)),
				'many' => q(čínského jüanu \(offshore\)),
				'one' => q(čínský jüan \(offshore\)),
				'other' => q(čínských jüanů \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(čínský dolar ČLB),
				'few' => q(čínské dolary ČLB),
				'many' => q(čínského dolaru ČLB),
				'one' => q(čínský dolar ČLB),
				'other' => q(čínských dolarů ČLB),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(čínský jüan),
				'few' => q(čínské jüany),
				'many' => q(čínského jüanu),
				'one' => q(čínský jüan),
				'other' => q(čínských jüanů),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbijské peso),
				'few' => q(kolumbijská pesa),
				'many' => q(kolumbijského pesa),
				'one' => q(kolumbijské peso),
				'other' => q(kolumbijských pes),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(kolumbijská jednotka reálné hodnoty),
				'few' => q(kolumbijské jednotky reálné hodnoty),
				'many' => q(kolumbijské jednotky reálné hodnoty),
				'one' => q(kolumbijská jednotka reálné hodnoty),
				'other' => q(kolumbijských jednotek reálné hodnoty),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostarický colón),
				'few' => q(kostarické colóny),
				'many' => q(kostarického colónu),
				'one' => q(kostarický colón),
				'other' => q(kostarických colónů),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(srbský dinár \(2002–2006\)),
				'few' => q(srbské dináry \(2002–2006\)),
				'many' => q(srbského dináru \(2002–2006\)),
				'one' => q(srbský dinár \(2002–2006\)),
				'other' => q(srbských dinárů \(2002–2006\)),
			},
		},
		'CSK' => {
			symbol => 'Kčs',
			display_name => {
				'currency' => q(československá koruna),
				'few' => q(československé koruny),
				'many' => q(československé koruny),
				'one' => q(československá koruna),
				'other' => q(československých korun),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubánské konvertibilní peso),
				'few' => q(kubánská konvertibilní pesa),
				'many' => q(kubánského konvertibilního pesa),
				'one' => q(kubánské konvertibilní peso),
				'other' => q(kubánských konvertibilních pes),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubánské peso),
				'few' => q(kubánská pesa),
				'many' => q(kubánského pesa),
				'one' => q(kubánské peso),
				'other' => q(kubánských pes),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdské escudo),
				'few' => q(kapverdská escuda),
				'many' => q(kapverdského escuda),
				'one' => q(kapverdské escudo),
				'other' => q(kapverdských escud),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(kyperská libra),
				'few' => q(kyperské libry),
				'many' => q(kyperské libry),
				'one' => q(kyperská libra),
				'other' => q(kyperských liber),
			},
		},
		'CZK' => {
			symbol => 'Kč',
			display_name => {
				'currency' => q(česká koruna),
				'few' => q(české koruny),
				'many' => q(české koruny),
				'one' => q(česká koruna),
				'other' => q(českých korun),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(východoněmecká marka),
				'few' => q(východoněmecké marky),
				'many' => q(východoněmecké marky),
				'one' => q(východoněmecká marka),
				'other' => q(východoněmeckých marek),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(německá marka),
				'few' => q(německé marky),
				'many' => q(německé marky),
				'one' => q(německá marka),
				'other' => q(německých marek),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(džibutský frank),
				'few' => q(džibutské franky),
				'many' => q(džibutského franku),
				'one' => q(džibutský frank),
				'other' => q(džibutských franků),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dánská koruna),
				'few' => q(dánské koruny),
				'many' => q(dánské koruny),
				'one' => q(dánská koruna),
				'other' => q(dánských korun),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikánské peso),
				'few' => q(dominikánská pesa),
				'many' => q(dominikánského pesa),
				'one' => q(dominikánské peso),
				'other' => q(dominikánských pes),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alžírský dinár),
				'few' => q(alžírské dináry),
				'many' => q(alžírského dináru),
				'one' => q(alžírský dinár),
				'other' => q(alžírských dinárů),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ekvádorský sucre),
				'few' => q(ekvádorské sucre),
				'many' => q(ekvádorského sucre),
				'one' => q(ekvádorský sucre),
				'other' => q(ekvádorských sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ekvádorská jednotka konstantní hodnoty),
				'few' => q(ekvádorské jednotky konstantní hodnoty),
				'many' => q(ekvádorské jednotky konstantní hodnoty),
				'one' => q(ekvádorská jednotka konstantní hodnoty),
				'other' => q(ekvádorských jednotek konstantní hodnoty),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estonská koruna),
				'few' => q(estonské koruny),
				'many' => q(estonské koruny),
				'one' => q(estonská koruna),
				'other' => q(estonských korun),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptská libra),
				'few' => q(egyptské libry),
				'many' => q(egyptské libry),
				'one' => q(egyptská libra),
				'other' => q(egyptských liber),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrejská nakfa),
				'few' => q(eritrejské nakfy),
				'many' => q(eritrejské nakfy),
				'one' => q(eritrejská nakfa),
				'other' => q(eritrejských nakf),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(španělská peseta \(„A“ účet\)),
				'few' => q(španělské pesety \(„A“ účet\)),
				'many' => q(španělské pesety \(„A“ účet\)),
				'one' => q(španělská peseta \(„A“ účet\)),
				'other' => q(španělských peset \(„A“ účet\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(španělská peseta \(konvertibilní účet\)),
				'few' => q(španělské pesety \(konvertibilní účet\)),
				'many' => q(španělské pesety \(konvertibilní účet\)),
				'one' => q(španělská peseta \(konvertibilní účet\)),
				'other' => q(španělských peset \(konvertibilní účet\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(španělská peseta),
				'few' => q(španělské pesety),
				'many' => q(španělské pesety),
				'one' => q(španělská peseta),
				'other' => q(španělských peset),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopský birr),
				'few' => q(etiopské birry),
				'many' => q(etiopského birru),
				'one' => q(etiopský birr),
				'other' => q(etiopských birrů),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'few' => q(eura),
				'many' => q(eura),
				'one' => q(euro),
				'other' => q(eur),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finská marka),
				'few' => q(finské marky),
				'many' => q(finské marky),
				'one' => q(finská marka),
				'other' => q(finských marek),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidžijský dolar),
				'few' => q(fidžijské dolary),
				'many' => q(fidžijského dolaru),
				'one' => q(fidžijský dolar),
				'other' => q(fidžijských dolarů),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandská libra),
				'few' => q(falklandské libry),
				'many' => q(falklandské libry),
				'one' => q(falklandská libra),
				'other' => q(falklandských liber),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(francouzský frank),
				'few' => q(francouzské franky),
				'many' => q(francouzského franku),
				'one' => q(francouzský frank),
				'other' => q(francouzských franků),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britská libra),
				'few' => q(britské libry),
				'many' => q(britské libry),
				'one' => q(britská libra),
				'other' => q(britských liber),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(gruzínské kuponové lari),
				'few' => q(gruzínské kuponové lari),
				'many' => q(gruzínského kuponového lari),
				'one' => q(gruzínské kuponové lari),
				'other' => q(gruzínských kuponových lari),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(gruzínské lari),
				'few' => q(gruzínské lari),
				'many' => q(gruzínského lari),
				'one' => q(gruzínské lari),
				'other' => q(gruzínských lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanský cedi \(1979–2007\)),
				'few' => q(ghanské cedi \(1979–2007\)),
				'many' => q(ghanského cedi \(1979–2007\)),
				'one' => q(ghanský cedi \(1979–2007\)),
				'other' => q(ghanských cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanský cedi),
				'few' => q(ghanské cedi),
				'many' => q(ghanského cedi),
				'one' => q(ghanský cedi),
				'other' => q(ghanských cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarská libra),
				'few' => q(gibraltarské libry),
				'many' => q(gibraltarské libry),
				'one' => q(gibraltarská libra),
				'other' => q(gibraltarských liber),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambijský dalasi),
				'few' => q(gambijské dalasi),
				'many' => q(gambijského dalasi),
				'one' => q(gambijský dalasi),
				'other' => q(gambijských dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guinejský frank),
				'few' => q(guinejské franky),
				'many' => q(guinejského franku),
				'one' => q(guinejský frank),
				'other' => q(guinejských franků),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(guinejský syli),
				'few' => q(guinejské syli),
				'many' => q(guinejského syli),
				'one' => q(guinejský syli),
				'other' => q(guinejských syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(rovníkovoguinejský ekwele),
				'few' => q(rovníkovoguinejské ekwele),
				'many' => q(rovníkovoguinejského ekwele),
				'one' => q(rovníkovoguinejský ekwele),
				'other' => q(rovníkovoguinejských ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(řecká drachma),
				'few' => q(řecké drachmy),
				'many' => q(řecké drachmy),
				'one' => q(řecká drachma),
				'other' => q(řeckých drachem),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalský quetzal),
				'few' => q(guatemalské quetzaly),
				'many' => q(guatemalského quetzalu),
				'one' => q(guatemalský quetzal),
				'other' => q(guatemalských quetzalů),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(portugalskoguinejské escudo),
				'few' => q(portugalskoguinejská escuda),
				'many' => q(portugalskoguinejského escuda),
				'one' => q(portugalskoguinejské escudo),
				'other' => q(portugalskoguinejských escud),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(guinejsko-bissauské peso),
				'few' => q(guinejsko-bissauská pesa),
				'many' => q(guinejsko-bissauského pesa),
				'one' => q(guinejsko-bissauské peso),
				'other' => q(guinejsko-bissauských pes),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanský dolar),
				'few' => q(guyanské dolary),
				'many' => q(guyanského dolaru),
				'one' => q(guyanský dolar),
				'other' => q(guyanských dolarů),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(hongkongský dolar),
				'few' => q(hongkongské dolary),
				'many' => q(hongkongského dolaru),
				'one' => q(hongkongský dolar),
				'other' => q(hongkongských dolarů),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraská lempira),
				'few' => q(honduraské lempiry),
				'many' => q(honduraské lempiry),
				'one' => q(honduraská lempira),
				'other' => q(honduraských lempir),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(chorvatský dinár),
				'few' => q(chorvatské dináry),
				'many' => q(chorvatského dináru),
				'one' => q(chorvatský dinár),
				'other' => q(chorvatských dinárů),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(chorvatská kuna),
				'few' => q(chorvatské kuny),
				'many' => q(chorvatské kuny),
				'one' => q(chorvatská kuna),
				'other' => q(chorvatských kun),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitský gourde),
				'few' => q(haitské gourde),
				'many' => q(haitského gourde),
				'one' => q(haitský gourde),
				'other' => q(haitských gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(maďarský forint),
				'few' => q(maďarské forinty),
				'many' => q(maďarského forintu),
				'one' => q(maďarský forint),
				'other' => q(maďarských forintů),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonéská rupie),
				'few' => q(indonéské rupie),
				'many' => q(indonéské rupie),
				'one' => q(indonéská rupie),
				'other' => q(indonéských rupií),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(irská libra),
				'few' => q(irské libry),
				'many' => q(irské libry),
				'one' => q(irská libra),
				'other' => q(irských liber),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(izraelská libra),
				'few' => q(izraelské libry),
				'many' => q(izraelské libry),
				'one' => q(izraelská libra),
				'other' => q(izraelských liber),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(izraelský šekel \(1980–1985\)),
				'few' => q(izraelské šekely \(1980–1985\)),
				'many' => q(izraelského šekelu \(1980–1985\)),
				'one' => q(izraelský šekel \(1980–1985\)),
				'other' => q(izraelských šekelů \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(izraelský nový šekel),
				'few' => q(izraelské nové šekely),
				'many' => q(izraelského nového šekelu),
				'one' => q(izraelský nový šekel),
				'other' => q(izraelských nových šekelů),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indická rupie),
				'few' => q(indické rupie),
				'many' => q(indické rupie),
				'one' => q(indická rupie),
				'other' => q(indických rupií),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irácký dinár),
				'few' => q(irácké dináry),
				'many' => q(iráckého dináru),
				'one' => q(irácký dinár),
				'other' => q(iráckých dinárů),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(íránský rijál),
				'few' => q(íránské rijály),
				'many' => q(íránského rijálu),
				'one' => q(íránský rijál),
				'other' => q(íránských rijálů),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(islandská koruna \(1918–1981\)),
				'few' => q(islandské koruny \(1918–1981\)),
				'many' => q(islandské koruny \(1918–1981\)),
				'one' => q(islandská koruna \(1918–1981\)),
				'other' => q(islandských korun \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandská koruna),
				'few' => q(islandské koruny),
				'many' => q(islandské koruny),
				'one' => q(islandská koruna),
				'other' => q(islandských korun),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italská lira),
				'few' => q(italské liry),
				'many' => q(italské liry),
				'one' => q(italská lira),
				'other' => q(italských lir),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamajský dolar),
				'few' => q(jamajské dolary),
				'many' => q(jamajského dolaru),
				'one' => q(jamajský dolar),
				'other' => q(jamajských dolarů),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordánský dinár),
				'few' => q(jordánské dináry),
				'many' => q(jordánského dináru),
				'one' => q(jordánský dinár),
				'other' => q(jordánských dinárů),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japonský jen),
				'few' => q(japonské jeny),
				'many' => q(japonského jenu),
				'one' => q(japonský jen),
				'other' => q(japonských jenů),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(keňský šilink),
				'few' => q(keňské šilinky),
				'many' => q(keňského šilinku),
				'one' => q(keňský šilink),
				'other' => q(keňských šilinků),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kyrgyzský som),
				'few' => q(kyrgyzské somy),
				'many' => q(kyrgyzského somu),
				'one' => q(kyrgyzský som),
				'other' => q(kyrgyzských somů),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodžský riel),
				'few' => q(kambodžské riely),
				'many' => q(kambodžského rielu),
				'one' => q(kambodžský riel),
				'other' => q(kambodžských rielů),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorský frank),
				'few' => q(komorské franky),
				'many' => q(komorského franku),
				'one' => q(komorský frank),
				'other' => q(komorských franků),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(severokorejský won),
				'few' => q(severokorejské wony),
				'many' => q(severokorejského wonu),
				'one' => q(severokorejský won),
				'other' => q(severokorejských wonů),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(jihokorejský hwan \(1953–1962\)),
				'few' => q(jihokorejské hwany \(1953–1962\)),
				'many' => q(jihokorejského hwanu \(1953–1962\)),
				'one' => q(jihokorejský hwan \(1953–1962\)),
				'other' => q(jihokorejských hwanů \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(jihokorejský won \(1945–1953\)),
				'few' => q(jihokorejské wony \(1945–1953\)),
				'many' => q(jihokorejského wonu \(1945–1953\)),
				'one' => q(jihokorejský won \(1945–1953\)),
				'other' => q(jihokorejských wonů \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(jihokorejský won),
				'few' => q(jihokorejské wony),
				'many' => q(jihokorejského wonu),
				'one' => q(jihokorejský won),
				'other' => q(jihokorejských wonů),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuvajtský dinár),
				'few' => q(kuvajtské dináry),
				'many' => q(kuvajtského dináru),
				'one' => q(kuvajtský dinár),
				'other' => q(kuvajtských dinárů),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmanský dolar),
				'few' => q(kajmanské dolary),
				'many' => q(kajmanského dolaru),
				'one' => q(kajmanský dolar),
				'other' => q(kajmanských dolarů),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazašské tenge),
				'few' => q(kazašské tenge),
				'many' => q(kazašského tenge),
				'one' => q(kazašské tenge),
				'other' => q(kazašských tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoský kip),
				'few' => q(laoské kipy),
				'many' => q(laoského kipu),
				'one' => q(laoský kip),
				'other' => q(laoských kipů),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanonská libra),
				'few' => q(libanonské libry),
				'many' => q(libanonské libry),
				'one' => q(libanonská libra),
				'other' => q(libanonských liber),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srílanská rupie),
				'few' => q(srílanské rupie),
				'many' => q(srílanské rupie),
				'one' => q(srílanská rupie),
				'other' => q(srílanských rupií),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberijský dolar),
				'few' => q(liberijské dolary),
				'many' => q(liberijského dolaru),
				'one' => q(liberijský dolar),
				'other' => q(liberijských dolarů),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothský loti),
				'few' => q(lesothské maloti),
				'many' => q(lesothského loti),
				'one' => q(lesothský loti),
				'other' => q(lesothských maloti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litevský litas),
				'few' => q(litevské lity),
				'many' => q(litevského litu),
				'one' => q(litevský litas),
				'other' => q(litevských litů),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litevský talonas),
				'few' => q(litevské talony),
				'many' => q(litevského talonu),
				'one' => q(litevský talonas),
				'other' => q(litevských talonů),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(lucemburský konvertibilní frank),
				'few' => q(lucemburské konvertibilní franky),
				'many' => q(lucemburského konvertibilního franku),
				'one' => q(lucemburský konvertibilní frank),
				'other' => q(lucemburských konvertibilních franků),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(lucemburský frank),
				'few' => q(lucemburské franky),
				'many' => q(lucemburského franku),
				'one' => q(lucemburský frank),
				'other' => q(lucemburských franků),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(lucemburský finanční frank),
				'few' => q(lucemburské finanční franky),
				'many' => q(lucemburského finančního franku),
				'one' => q(lucemburský finanční frank),
				'other' => q(lucemburských finančních franků),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lotyšský lat),
				'few' => q(lotyšské laty),
				'many' => q(lotyšského latu),
				'one' => q(lotyšský lat),
				'other' => q(lotyšských latů),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(lotyšský rubl),
				'few' => q(lotyšské rubly),
				'many' => q(lotyšského rublu),
				'one' => q(lotyšský rubl),
				'other' => q(lotyšských rublů),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyjský dinár),
				'few' => q(libyjské dináry),
				'many' => q(libyjského dináru),
				'one' => q(libyjský dinár),
				'other' => q(libyjských dinárů),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marocký dinár),
				'few' => q(marocké dináry),
				'many' => q(marockého dináru),
				'one' => q(marocký dinár),
				'other' => q(marockých dinárů),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(marocký frank),
				'few' => q(marocké franky),
				'many' => q(marockého franku),
				'one' => q(marocký frank),
				'other' => q(marockých franků),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monacký frank),
				'few' => q(monacké franky),
				'many' => q(monackého franku),
				'one' => q(monacký frank),
				'other' => q(monackých franků),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldavský kupon),
				'few' => q(moldavské kupony),
				'many' => q(moldavského kuponu),
				'one' => q(moldavský kupon),
				'other' => q(moldavských kuponů),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldavský leu),
				'few' => q(moldavské lei),
				'many' => q(moldavského leu),
				'one' => q(moldavský leu),
				'other' => q(moldavských lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskarský ariary),
				'few' => q(madagaskarské ariary),
				'many' => q(madagaskarského ariary),
				'one' => q(madagaskarský ariary),
				'other' => q(madagaskarských ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(madagaskarský frank),
				'few' => q(madagaskarské franky),
				'many' => q(madagaskarského franku),
				'one' => q(madagaskarský frank),
				'other' => q(madagaskarských franků),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonský denár),
				'few' => q(makedonské denáry),
				'many' => q(makedonského denáru),
				'one' => q(makedonský denár),
				'other' => q(makedonských denárů),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedonský denár \(1992–1993\)),
				'few' => q(makedonské denáry \(1992–1993\)),
				'many' => q(makedonského denáru \(1992–1993\)),
				'one' => q(makedonský denár \(1992–1993\)),
				'other' => q(makedonských denárů \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(malijský frank),
				'few' => q(malijské franky),
				'many' => q(malijského franku),
				'one' => q(malijský frank),
				'other' => q(malijských franků),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarský kyat),
				'few' => q(myanmarské kyaty),
				'many' => q(myanmarského kyatu),
				'one' => q(myanmarský kyat),
				'other' => q(myanmarských kyatů),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolský tugrik),
				'few' => q(mongolské tugriky),
				'many' => q(mongolského tugriku),
				'one' => q(mongolský tugrik),
				'other' => q(mongolských tugriků),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macajská pataca),
				'few' => q(macajské patacy),
				'many' => q(macajské patacy),
				'one' => q(macajská pataca),
				'other' => q(macajských patac),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauritánská ouguiya \(1973–2017\)),
				'few' => q(mauritánské ouguiye \(1973–2017\)),
				'many' => q(mauritánské ouguiye \(1973–2017\)),
				'one' => q(mauritánská ouguiya \(1973–2017\)),
				'other' => q(mauritánských ouguiyí \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritánská ouguiya),
				'few' => q(mauritánské ouguiye),
				'many' => q(mauritánské ouguiye),
				'one' => q(mauritánská ouguiya),
				'other' => q(mauritánských ouguiyí),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltská lira),
				'few' => q(maltské liry),
				'many' => q(maltské liry),
				'one' => q(maltská lira),
				'other' => q(maltských lir),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltská libra),
				'few' => q(maltské libry),
				'many' => q(maltské libry),
				'one' => q(maltská libra),
				'other' => q(maltských liber),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauricijská rupie),
				'few' => q(mauricijské rupie),
				'many' => q(mauricijské rupie),
				'one' => q(mauricijská rupie),
				'other' => q(mauricijských rupií),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(maledivská rupie \(1947–1981\)),
				'few' => q(maledivské rupie \(1947–1981\)),
				'many' => q(maledivské rupie \(1947–1981\)),
				'one' => q(maledivská rupie \(1947–1981\)),
				'other' => q(maledivských rupií \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maledivská rupie),
				'few' => q(maledivské rupie),
				'many' => q(maledivské rupie),
				'one' => q(maledivská rupie),
				'other' => q(maledivských rupií),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawijská kwacha),
				'few' => q(malawijské kwachy),
				'many' => q(malawijské kwachy),
				'one' => q(malawijská kwacha),
				'other' => q(malawijských kwach),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexické peso),
				'few' => q(mexická pesa),
				'many' => q(mexického pesa),
				'one' => q(mexické peso),
				'other' => q(mexických pes),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(mexické stříbrné peso \(1861–1992\)),
				'few' => q(mexická stříbrná pesa \(1861–1992\)),
				'many' => q(mexického stříbrného pesa \(1861–1992\)),
				'one' => q(mexické stříbrné peso \(1861–1992\)),
				'other' => q(mexických stříbrných pes \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(mexická investiční jednotka),
				'few' => q(mexické investiční jednotky),
				'many' => q(mexické investiční jednotky),
				'one' => q(mexická investiční jednotka),
				'other' => q(mexických investičních jednotek),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajsijský ringgit),
				'few' => q(malajsijské ringgity),
				'many' => q(malajsijského ringgitu),
				'one' => q(malajsijský ringgit),
				'other' => q(malajsijských ringgitů),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mosambický escudo),
				'few' => q(mosambická escuda),
				'many' => q(mosambického escuda),
				'one' => q(mosambický escudo),
				'other' => q(mosambických escud),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mosambický metical \(1980–2006\)),
				'few' => q(mosambické meticaly \(1980–2006\)),
				'many' => q(mosambického meticalu \(1980–2006\)),
				'one' => q(mosambický metical \(1980–2006\)),
				'other' => q(mosambických meticalů \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambický metical),
				'few' => q(mozambické meticaly),
				'many' => q(mozambického meticalu),
				'one' => q(mozambický metical),
				'other' => q(mozambických meticalů),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibijský dolar),
				'few' => q(namibijské dolary),
				'many' => q(namibijského dolaru),
				'one' => q(namibijský dolar),
				'other' => q(namibijských dolarů),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigerijská naira),
				'few' => q(nigerijské nairy),
				'many' => q(nigerijské nairy),
				'one' => q(nigerijská naira),
				'other' => q(nigerijských nair),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nikaragujská córdoba \(1988–1991\)),
				'few' => q(nikaragujské córdoby \(1988–1991\)),
				'many' => q(nikaragujské córdoby \(1988–1991\)),
				'one' => q(nikaragujská córdoba \(1988–1991\)),
				'other' => q(nikaragujských córdob \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaragujská córdoba),
				'few' => q(nikaragujské córdoby),
				'many' => q(nikaragujské córdoby),
				'one' => q(nikaragujská córdoba),
				'other' => q(nikaragujských córdob),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nizozemský gulden),
				'few' => q(nizozemské guldeny),
				'many' => q(nizozemského guldenu),
				'one' => q(nizozemský gulden),
				'other' => q(nizozemských guldenů),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norská koruna),
				'few' => q(norské koruny),
				'many' => q(norské koruny),
				'one' => q(norská koruna),
				'other' => q(norských korun),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepálská rupie),
				'few' => q(nepálské rupie),
				'many' => q(nepálské rupie),
				'one' => q(nepálská rupie),
				'other' => q(nepálských rupií),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(novozélandský dolar),
				'few' => q(novozélandské dolary),
				'many' => q(novozélandského dolaru),
				'one' => q(novozélandský dolar),
				'other' => q(novozélandských dolarů),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ománský rijál),
				'few' => q(ománské rijály),
				'many' => q(ománského rijálu),
				'one' => q(ománský rijál),
				'other' => q(ománských rijálů),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamská balboa),
				'few' => q(panamské balboy),
				'many' => q(panamské balboy),
				'one' => q(panamská balboa),
				'other' => q(panamských balboí),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruánská inti),
				'few' => q(peruánské inti),
				'many' => q(peruánské inti),
				'one' => q(peruánská inti),
				'other' => q(peruánských inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruánský sol),
				'few' => q(peruánské soly),
				'many' => q(peruánského solu),
				'one' => q(peruánský sol),
				'other' => q(peruánských solů),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruánský sol \(1863–1965\)),
				'few' => q(peruánské soly \(1863–1965\)),
				'many' => q(peruánského solu \(1863–1965\)),
				'one' => q(peruánský sol \(1863–1965\)),
				'other' => q(peruánských solů \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuánská nová kina),
				'few' => q(papuánské nové kiny),
				'many' => q(papuánské nové kiny),
				'one' => q(papuánská nová kina),
				'other' => q(papuánských nových kin),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filipínské peso),
				'few' => q(filipínská pesa),
				'many' => q(filipínského pesa),
				'one' => q(filipínské peso),
				'other' => q(filipínských pes),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pákistánská rupie),
				'few' => q(pákistánské rupie),
				'many' => q(pákistánské rupie),
				'one' => q(pákistánská rupie),
				'other' => q(pákistánských rupií),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polský zlotý),
				'few' => q(polské zloté),
				'many' => q(polského zlotého),
				'one' => q(polský zlotý),
				'other' => q(polských zlotých),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polský zlotý \(1950–1995\)),
				'few' => q(polské zloté \(1950–1995\)),
				'many' => q(polského zlotého \(1950–1995\)),
				'one' => q(polský zlotý \(1950–1995\)),
				'other' => q(polských zlotých \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugalské escudo),
				'few' => q(portugalská escuda),
				'many' => q(portugalského escuda),
				'one' => q(portugalské escudo),
				'other' => q(portugalských escud),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguajské guarani),
				'few' => q(paraguajská guarani),
				'many' => q(paraguajského guarani),
				'one' => q(paraguajské guarani),
				'other' => q(paraguajských guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarský rijál),
				'few' => q(katarské rijály),
				'many' => q(katarského rijálu),
				'one' => q(katarský rijál),
				'other' => q(katarských rijálů),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodéský dolar),
				'few' => q(rhodéské dolary),
				'many' => q(rhodéského dolaru),
				'one' => q(rhodéský dolar),
				'other' => q(rhodéských dolarů),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(rumunské leu \(1952–2006\)),
				'few' => q(rumunské lei \(1952–2006\)),
				'many' => q(rumunského leu \(1952–2006\)),
				'one' => q(rumunské leu \(1952–2006\)),
				'other' => q(rumunských lei \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(rumunský leu),
				'few' => q(rumunské lei),
				'many' => q(rumunského leu),
				'one' => q(rumunský leu),
				'other' => q(rumunských lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(srbský dinár),
				'few' => q(srbské dináry),
				'many' => q(srbského dináru),
				'one' => q(srbský dinár),
				'other' => q(srbských dinárů),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruský rubl),
				'few' => q(ruské rubly),
				'many' => q(ruského rublu),
				'one' => q(ruský rubl),
				'other' => q(ruských rublů),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(ruský rubl \(1991–1998\)),
				'few' => q(ruské rubly \(1991–1998\)),
				'many' => q(ruského rublu \(1991–1998\)),
				'one' => q(ruský rubl \(1991–1998\)),
				'other' => q(ruských rublů \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandský frank),
				'few' => q(rwandské franky),
				'many' => q(rwandského franku),
				'one' => q(rwandský frank),
				'other' => q(rwandských franků),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saúdský rijál),
				'few' => q(saúdské rijály),
				'many' => q(saúdského rijálu),
				'one' => q(saúdský rijál),
				'other' => q(saúdských rijálů),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(šalamounský dolar),
				'few' => q(šalamounské dolary),
				'many' => q(šalamounského dolaru),
				'one' => q(šalamounský dolar),
				'other' => q(šalamounských dolarů),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelská rupie),
				'few' => q(seychelské rupie),
				'many' => q(seychelské rupie),
				'one' => q(seychelská rupie),
				'other' => q(seychelských rupií),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(súdánský dinár \(1992–2007\)),
				'few' => q(súdánské dináry \(1992–2007\)),
				'many' => q(súdánského dináru \(1992–2007\)),
				'one' => q(súdánský dinár \(1992–2007\)),
				'other' => q(súdánských dinárů \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(súdánská libra),
				'few' => q(súdánské libry),
				'many' => q(súdánské libry),
				'one' => q(súdánská libra),
				'other' => q(súdánských liber),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(súdánská libra \(1957–1998\)),
				'few' => q(súdánské libry \(1957–1998\)),
				'many' => q(súdánské libry \(1957–1998\)),
				'one' => q(súdánská libra \(1957–1998\)),
				'other' => q(súdánských liber \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(švédská koruna),
				'few' => q(švédské koruny),
				'many' => q(švédské koruny),
				'one' => q(švédská koruna),
				'other' => q(švédských korun),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurský dolar),
				'few' => q(singapurské dolary),
				'many' => q(singapurského dolaru),
				'one' => q(singapurský dolar),
				'other' => q(singapurských dolarů),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(svatohelenská libra),
				'few' => q(svatohelenské libry),
				'many' => q(svatohelenské libry),
				'one' => q(svatohelenská libra),
				'other' => q(svatohelenských liber),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovinský tolar),
				'few' => q(slovinské tolary),
				'many' => q(slovinského tolaru),
				'one' => q(slovinský tolar),
				'other' => q(slovinských tolarů),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovenská koruna),
				'few' => q(slovenské koruny),
				'many' => q(slovenské koruny),
				'one' => q(slovenská koruna),
				'other' => q(slovenských korun),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierro-leonský leone),
				'few' => q(sierro-leonské leone),
				'many' => q(sierro-leonského leone),
				'one' => q(sierro-leonský leone),
				'other' => q(sierro-leonských leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierro-leonský leone \(1964—2022\)),
				'few' => q(sierro-leonské leone \(1964—2022\)),
				'many' => q(sierro-leonského leone \(1964—2022\)),
				'one' => q(sierro-leonský leone \(1964—2022\)),
				'other' => q(sierro-leonských leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somálský šilink),
				'few' => q(somálské šilinky),
				'many' => q(somálského šilinku),
				'one' => q(somálský šilink),
				'other' => q(somálských šilinků),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamský dolar),
				'few' => q(surinamské dolary),
				'many' => q(surinamského dolaru),
				'one' => q(surinamský dolar),
				'other' => q(surinamských dolarů),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamský zlatý),
				'few' => q(surinamské zlaté),
				'many' => q(surinamského zlatého),
				'one' => q(surinamský zlatý),
				'other' => q(surinamských zlatých),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(jihosúdánská libra),
				'few' => q(jihosúdánské libry),
				'many' => q(jihosúdánské libry),
				'one' => q(jihosúdánská libra),
				'other' => q(jihosúdánských liber),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(svatotomášská dobra \(1977–2017\)),
				'few' => q(svatotomášské dobry \(1977–2017\)),
				'many' => q(svatotomášské dobry \(1977–2017\)),
				'one' => q(svatotomášská dobra \(1977–2017\)),
				'other' => q(svatotomášských dober \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(svatotomášská dobra),
				'few' => q(svatotomášské dobry),
				'many' => q(svatotomášské dobry),
				'one' => q(svatotomášská dobra),
				'other' => q(svatotomášských dober),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovětský rubl),
				'few' => q(sovětské rubly),
				'many' => q(sovětského rublu),
				'one' => q(sovětský rubl),
				'other' => q(sovětských rublů),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadorský colón),
				'few' => q(salvadorské colóny),
				'many' => q(salvadorského colónu),
				'one' => q(salvadorský colón),
				'other' => q(salvadorských colónů),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syrská libra),
				'few' => q(syrské libry),
				'many' => q(syrské libry),
				'one' => q(syrská libra),
				'other' => q(syrských liber),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(svazijský lilangeni),
				'few' => q(svazijské emalangeni),
				'many' => q(svazijského lilangeni),
				'one' => q(svazijský lilangeni),
				'other' => q(svazijských emalangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thajský baht),
				'few' => q(thajské bahty),
				'many' => q(thajského bahtu),
				'one' => q(thajský baht),
				'other' => q(thajských bahtů),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tádžický rubl),
				'few' => q(tádžické rubly),
				'many' => q(tádžického rublu),
				'one' => q(tádžický rubl),
				'other' => q(tádžických rublů),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tádžické somoni),
				'few' => q(tádžická somoni),
				'many' => q(tádžického somoni),
				'one' => q(tádžické somoni),
				'other' => q(tádžických somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenský manat \(1993–2009\)),
				'few' => q(turkmenské manaty \(1993–2009\)),
				'many' => q(turkmenského manatu \(1993–2009\)),
				'one' => q(turkmenský manat \(1993–2009\)),
				'other' => q(turkmenských manatů \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenský manat),
				'few' => q(turkmenské manaty),
				'many' => q(turkmenského manatu),
				'one' => q(turkmenský manat),
				'other' => q(turkmenských manatů),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuniský dinár),
				'few' => q(tuniské dináry),
				'many' => q(tuniského dináru),
				'one' => q(tuniský dinár),
				'other' => q(tuniských dinárů),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tonžská paanga),
				'few' => q(tonžské paangy),
				'many' => q(tonžské paangy),
				'one' => q(tonžská paanga),
				'other' => q(tonžských paang),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timorské escudo),
				'few' => q(timorská escuda),
				'many' => q(timorského escuda),
				'one' => q(timorské escudo),
				'other' => q(timorských escud),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(turecká lira \(1922–2005\)),
				'few' => q(turecké liry \(1922–2005\)),
				'many' => q(turecké liry \(1922–2005\)),
				'one' => q(turecká lira \(1922–2005\)),
				'other' => q(tureckých lir \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turecká lira),
				'few' => q(turecké liry),
				'many' => q(turecké liry),
				'one' => q(turecká lira),
				'other' => q(tureckých lir),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidadský dolar),
				'few' => q(trinidadské dolary),
				'many' => q(trinidadského dolaru),
				'one' => q(trinidadský dolar),
				'other' => q(trinidadských dolarů),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(tchajwanský dolar),
				'few' => q(tchajwanské dolary),
				'many' => q(tchajwanského dolaru),
				'one' => q(tchajwanský dolar),
				'other' => q(tchajwanských dolarů),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanský šilink),
				'few' => q(tanzanské šilinky),
				'many' => q(tanzanského šilinku),
				'one' => q(tanzanský šilink),
				'other' => q(tanzanských šilinků),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrajinská hřivna),
				'few' => q(ukrajinské hřivny),
				'many' => q(ukrajinské hřivny),
				'one' => q(ukrajinská hřivna),
				'other' => q(ukrajinských hřiven),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrajinský karbovanec),
				'few' => q(ukrajinské karbovance),
				'many' => q(ukrajinského karbovance),
				'one' => q(ukrajinský karbovanec),
				'other' => q(ukrajinských karbovanců),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandský šilink \(1966–1987\)),
				'few' => q(ugandské šilinky \(1966–1987\)),
				'many' => q(ugandského šilinku \(1966–1987\)),
				'one' => q(ugandský šilink \(1966–1987\)),
				'other' => q(ugandských šilinků \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandský šilink),
				'few' => q(ugandské šilinky),
				'many' => q(ugandského šilinku),
				'one' => q(ugandský šilink),
				'other' => q(ugandských šilinků),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(americký dolar),
				'few' => q(americké dolary),
				'many' => q(amerického dolaru),
				'one' => q(americký dolar),
				'other' => q(amerických dolarů),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(americký dolar \(příští den\)),
				'few' => q(americké dolary \(příští den\)),
				'many' => q(amerického dolaru \(příští den\)),
				'one' => q(americký dolar \(příští den\)),
				'other' => q(amerických dolarů \(příští den\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(americký dolar \(týž den\)),
				'few' => q(americké dolary \(týž den\)),
				'many' => q(amerického dolaru \(týž den\)),
				'one' => q(americký dolar \(týž den\)),
				'other' => q(amerických dolarů \(týž den\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguayské peso \(v indexovaných jednotkách\)),
				'few' => q(uruguayská pesa \(v indexovaných jednotkách\)),
				'many' => q(uruguayského pesa \(v indexovaných jednotkách\)),
				'one' => q(uruguayské peso \(v indexovaných jednotkách\)),
				'other' => q(uruguayských pes \(v indexovaných jednotkách\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayské peso \(1975–1993\)),
				'few' => q(uruguayská pesa \(1975–1993\)),
				'many' => q(uruguayského pesa \(1975–1993\)),
				'one' => q(uruguayské peso \(1975–1993\)),
				'other' => q(uruguayských pes \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayské peso),
				'few' => q(uruguayská pesa),
				'many' => q(uruguayského pesa),
				'one' => q(uruguayské peso),
				'other' => q(uruguayských pes),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbecký sum),
				'few' => q(uzbecké sumy),
				'many' => q(uzbeckého sumu),
				'one' => q(uzbecký sum),
				'other' => q(uzbeckých sumů),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelský bolívar \(1871–2008\)),
				'few' => q(venezuelské bolívary \(1871–2008\)),
				'many' => q(venezuelského bolívaru \(1871–2008\)),
				'one' => q(venezuelský bolívar \(1871–2008\)),
				'other' => q(venezuelských bolívarů \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelský bolívar \(2008–2018\)),
				'few' => q(venezuelské bolívary \(2008–2018\)),
				'many' => q(venezuelského bolívaru \(2008–2018\)),
				'one' => q(venezuelský bolívar \(2008–2018\)),
				'other' => q(venezuelských bolívarů \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelský bolívar),
				'few' => q(venezuelské bolívary),
				'many' => q(venezuelského bolívaru),
				'one' => q(venezuelský bolívar),
				'other' => q(venezuelských bolívarů),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnamský dong),
				'few' => q(vietnamské dongy),
				'many' => q(vietnamského dongu),
				'one' => q(vietnamský dong),
				'other' => q(vietnamských dongů),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamský dong \(1978–1985\)),
				'few' => q(vietnamské dongy \(1978–1985\)),
				'many' => q(vietnamského dongu \(1978–1985\)),
				'one' => q(vietnamský dong \(1978–1985\)),
				'other' => q(vietnamských dongů \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatský vatu),
				'few' => q(vanuatské vatu),
				'many' => q(vanuatského vatu),
				'one' => q(vanuatský vatu),
				'other' => q(vanuatských vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samojská tala),
				'few' => q(samojské taly),
				'many' => q(samojské taly),
				'one' => q(samojská tala),
				'other' => q(samojských tal),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA/BEAC frank),
				'few' => q(CFA/BEAC franky),
				'many' => q(CFA/BEAC franku),
				'one' => q(CFA/BEAC frank),
				'other' => q(CFA/BEAC franků),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(stříbro),
				'few' => q(trojské unce stříbra),
				'many' => q(trojské unce stříbra),
				'one' => q(trojská unce stříbra),
				'other' => q(trojských uncí stříbra),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(zlato),
				'few' => q(trojské unce zlata),
				'many' => q(trojské unce zlata),
				'one' => q(trojská unce zlata),
				'other' => q(trojských uncí zlata),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(evropská smíšená jednotka),
				'few' => q(evropské smíšené jednotky),
				'many' => q(evropské smíšené jednotky),
				'one' => q(evropská smíšená jednotka),
				'other' => q(evropských smíšených jednotek),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(evropská peněžní jednotka),
				'few' => q(evropské peněžní jednotky),
				'many' => q(evropské peněžní jednotky),
				'one' => q(evropská peněžní jednotka),
				'other' => q(evropských peněžních jednotek),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(evropská jednotka účtu 9 \(XBC\)),
				'few' => q(evropské jednotky účtu 9 \(XBC\)),
				'many' => q(evropské jednotky účtu 9 \(XBC\)),
				'one' => q(evropská jednotka účtu 9 \(XBC\)),
				'other' => q(evropských jednotek účtu 9 \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(evropská jednotka účtu 17 \(XBD\)),
				'few' => q(evropské jednotky účtu 17 \(XBD\)),
				'many' => q(evropské jednotky účtu 17 \(XBD\)),
				'one' => q(evropská jednotka účtu 17 \(XBD\)),
				'other' => q(evropských jednotek účtu 17 \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(východokaribský dolar),
				'few' => q(východokaribské dolary),
				'many' => q(východokaribského dolaru),
				'one' => q(východokaribský dolar),
				'other' => q(východokaribských dolarů),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(SDR),
			},
		},
		'XEU' => {
			symbol => 'ECU',
			display_name => {
				'currency' => q(evropská měnová jednotka),
				'few' => q(ECU),
				'many' => q(ECU),
				'one' => q(ECU),
				'other' => q(ECU),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(francouzský zlatý frank),
				'few' => q(francouzské zlaté franky),
				'many' => q(francouzského zlatého franku),
				'one' => q(francouzský zlatý frank),
				'other' => q(francouzských zlatých franků),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(francouzský UIC frank),
				'few' => q(francouzské UIC franky),
				'many' => q(francouzského UIC franku),
				'one' => q(francouzský UIC frank),
				'other' => q(francouzských UIC franků),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA/BCEAO frank),
				'few' => q(CFA/BCEAO franky),
				'many' => q(CFA/BCEAO franku),
				'one' => q(CFA/BCEAO frank),
				'other' => q(CFA/BCEAO franků),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'few' => q(trojské unce palladia),
				'many' => q(trojské unce palladia),
				'one' => q(trojská unce palladia),
				'other' => q(trojských uncí palladia),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP frank),
				'few' => q(CFP franky),
				'many' => q(CFP franku),
				'one' => q(CFP frank),
				'other' => q(CFP franků),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'few' => q(trojské unce platiny),
				'many' => q(trojské unce platiny),
				'one' => q(trojská unce platiny),
				'other' => q(trojských uncí platiny),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(kód fondů RINET),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(kód zvlášť vyhrazený pro testovací účely),
				'few' => q(kódy zvlášť vyhrazené pro testovací účely),
				'many' => q(kódu zvlášť vyhrazeného pro testovací účely),
				'one' => q(kód zvlášť vyhrazený pro testovací účely),
				'other' => q(kódů zvlášť vyhrazených pro testovací účely),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(neznámá měna),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenský dinár),
				'few' => q(jemenské dináry),
				'many' => q(jemenského dináru),
				'one' => q(jemenský dinár),
				'other' => q(jemenských dinárů),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenský rijál),
				'few' => q(jemenské rijály),
				'many' => q(jemenského rijálu),
				'one' => q(jemenský rijál),
				'other' => q(jemenských rijálů),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(jugoslávský dinár \(1966–1990\)),
				'few' => q(jugoslávské dináry \(1966–1990\)),
				'many' => q(jugoslávského dináru \(1966–1990\)),
				'one' => q(jugoslávský dinár \(1966–1990\)),
				'other' => q(jugoslávských dinárů \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(jugoslávský nový dinár \(1994–2002\)),
				'few' => q(jugoslávské nové dináry \(1994–2002\)),
				'many' => q(jugoslávského nového dináru \(1994–2002\)),
				'one' => q(jugoslávský nový dinár \(1994–2002\)),
				'other' => q(jugoslávských nových dinárů \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslávský konvertibilní dinár \(1990–1992\)),
				'few' => q(jugoslávské konvertibilní dináry \(1990–1992\)),
				'many' => q(jugoslávského konvertibilního dináru \(1990–1992\)),
				'one' => q(jugoslávský konvertibilní dinár \(1990–1992\)),
				'other' => q(jugoslávských konvertibilních dinárů \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(jugoslávský reformovaný dinár \(1992–1993\)),
				'few' => q(jugoslávské reformované dináry \(1992–1993\)),
				'many' => q(jugoslávského reformovaného dináru \(1992–1993\)),
				'one' => q(jugoslávský reformovaný dinár \(1992–1993\)),
				'other' => q(jugoslávských reformovaných dinárů \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(jihoafrický finanční rand),
				'few' => q(jihoafrické finanční randy),
				'many' => q(jihoafrického finančního randu),
				'one' => q(jihoafrický finanční rand),
				'other' => q(jihoafrických finančních randů),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(jihoafrický rand),
				'few' => q(jihoafrické randy),
				'many' => q(jihoafrického randu),
				'one' => q(jihoafrický rand),
				'other' => q(jihoafrických randů),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambijská kwacha \(1968–2012\)),
				'few' => q(zambijské kwachy \(1968–2012\)),
				'many' => q(zambijské kwachy \(1968–2012\)),
				'one' => q(zambijská kwacha \(1968–2012\)),
				'other' => q(zambijských kwach \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambijská kwacha),
				'few' => q(zambijské kwachy),
				'many' => q(zambijské kwachy),
				'one' => q(zambijská kwacha),
				'other' => q(zambijských kwach),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairský nový zaire \(1993–1998\)),
				'few' => q(zairské nové zairy \(1993–1998\)),
				'many' => q(zairského nového zairu \(1993–1998\)),
				'one' => q(zairský nový zaire \(1993–1998\)),
				'other' => q(zairských nových zairů \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairský zaire \(1971–1993\)),
				'few' => q(zairské zairy \(1971–1993\)),
				'many' => q(zairského zairu \(1971–1993\)),
				'one' => q(zairský zaire \(1971–1993\)),
				'other' => q(zairských zairů \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwský dolar \(1980–2008\)),
				'few' => q(zimbabwské dolary \(1980–2008\)),
				'many' => q(zimbabwského dolaru \(1980–2008\)),
				'one' => q(zimbabwský dolar \(1980–2008\)),
				'other' => q(zimbabwských dolarů \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(zimbabwský dolar \(2009\)),
				'few' => q(zimbabwské dolary \(2009\)),
				'many' => q(zimbabwského dolaru \(2009\)),
				'one' => q(zimbabwský dolar \(2009\)),
				'other' => q(zimbabwských dolarů \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(zimbabwský dolar \(2008\)),
				'few' => q(zimbabwské dolary \(2008\)),
				'many' => q(zimbabwského dolaru \(2008\)),
				'one' => q(zimbabwský dolar \(2008\)),
				'other' => q(zimbabwských dolarů \(2008\)),
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
							'hatour',
							'kiahk',
							'touba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'ba’ouna',
							'abib',
							'mesra',
							'nasie'
						],
						leap => [
							
						],
					},
				},
			},
			'dangi' => {
				'format' => {
					wide => {
						nonleap => [
							'První měsíc',
							'Druhý měsíc',
							'Třetí měsíc',
							'Čtvrtý měsíc',
							'Pátý měsíc',
							'Šestý měsíc',
							'Sedmý měsíc',
							'Osmý měsíc',
							'Devátý měsíc',
							'Desátý měsíc',
							'Jedenáctý měsíc',
							'Dvanáctý měsíc'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'První měsíc',
							'Druhý měsíc',
							'Třetí měsíc',
							'Čtvrtý měsíc',
							'Pátý měsíc',
							'Šestý měsíc',
							'Sedmý měsíc',
							'Osmý měsíc',
							'Devátý měsíc',
							'Desátý měsíc',
							'Jedenáctý měsíc',
							'Dvanáctý měsíc'
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
							'tikemet',
							'hidar',
							'tahesas',
							'tir',
							'yekatit',
							'megabit',
							'miyaza',
							'ginbot',
							'sene',
							'hamle',
							'nehase',
							'pagume'
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
							'led',
							'úno',
							'bře',
							'dub',
							'kvě',
							'čvn',
							'čvc',
							'srp',
							'zář',
							'říj',
							'lis',
							'pro'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ledna',
							'února',
							'března',
							'dubna',
							'května',
							'června',
							'července',
							'srpna',
							'září',
							'října',
							'listopadu',
							'prosince'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'leden',
							'únor',
							'březen',
							'duben',
							'květen',
							'červen',
							'červenec',
							'srpen',
							'září',
							'říjen',
							'listopad',
							'prosinec'
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
							'chešvan',
							'kislev',
							'tevet',
							'ševat',
							'adar I',
							'adar',
							'nisan',
							'ijar',
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
							'čaitra',
							'vaišákh',
							'džjéšth',
							'ášádh',
							'šrávana',
							'bhádrapad',
							'ášvin',
							'kártik',
							'agrahajana',
							'pauš',
							'mágh',
							'phálgun'
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
							'reb. I',
							'reb. II',
							'džum. I',
							'džum. II',
							'red.',
							'ša.',
							'ram.',
							'šaw.',
							'zú l-k.',
							'zú l-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharrem',
							'safar',
							'rebí’u l-awwal',
							'rebí’u s-sání',
							'džumádá al-úlá',
							'džumádá al-áchira',
							'redžeb',
							'ša’bán',
							'ramadán',
							'šawwal',
							'zú l-ka’da',
							'zú l-hidždža'
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
							'ordibehešt',
							'chordád',
							'tír',
							'mordád',
							'šahrívar',
							'mehr',
							'ábán',
							'ázar',
							'dei',
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
						mon => 'po',
						tue => 'út',
						wed => 'st',
						thu => 'čt',
						fri => 'pá',
						sat => 'so',
						sun => 'ne'
					},
					wide => {
						mon => 'pondělí',
						tue => 'úterý',
						wed => 'středa',
						thu => 'čtvrtek',
						fri => 'pátek',
						sat => 'sobota',
						sun => 'neděle'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'P',
						tue => 'Ú',
						wed => 'S',
						thu => 'Č',
						fri => 'P',
						sat => 'S',
						sun => 'N'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => '1. čtvrtletí',
						1 => '2. čtvrtletí',
						2 => '3. čtvrtletí',
						3 => '4. čtvrtletí'
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
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
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
					'afternoon1' => q{odp.},
					'am' => q{dop.},
					'evening1' => q{več.},
					'midnight' => q{půln.},
					'morning1' => q{r.},
					'morning2' => q{dop.},
					'night1' => q{v n.},
					'noon' => q{pol.},
					'pm' => q{odp.},
				},
				'narrow' => {
					'afternoon1' => q{o.},
					'evening1' => q{v.},
					'midnight' => q{půl.},
					'morning1' => q{r.},
					'morning2' => q{d.},
					'night1' => q{n.},
					'noon' => q{pol.},
				},
				'wide' => {
					'afternoon1' => q{odpoledne},
					'evening1' => q{večer},
					'midnight' => q{půlnoc},
					'morning1' => q{ráno},
					'morning2' => q{dopoledne},
					'night1' => q{v noci},
					'noon' => q{poledne},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{odpoledne},
					'evening1' => q{večer},
					'midnight' => q{půlnoc},
					'morning1' => q{ráno},
					'morning2' => q{dopoledne},
					'night1' => q{noc},
					'noon' => q{poledne},
				},
				'narrow' => {
					'afternoon1' => q{odp.},
					'evening1' => q{več.},
					'midnight' => q{půl.},
					'morning1' => q{ráno},
					'morning2' => q{dop.},
					'night1' => q{noc},
					'noon' => q{pol.},
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
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'př. n. l.',
				'1' => 'n. l.'
			},
			narrow => {
				'0' => 'př.n.l.',
				'1' => 'n.l.'
			},
			wide => {
				'0' => 'před naším letopočtem',
				'1' => 'našeho letopočtu'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'Šaka'
			},
		},
		'islamic' => {
		},
		'japanese' => {
			abbreviated => {
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'26' => 'Ten-an (857-859)',
				'78' => 'Ten-ei (1110-1113)'
			},
			narrow => {
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'26' => 'Ten-an (857-859)',
				'78' => 'Ten-ei (1110-1113)'
			},
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'před ROC',
				'1' => 'ROC'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'full' => q{EEEE, d. M. y},
			'long' => q{d. M. y},
			'medium' => q{d. M. y},
			'short' => q{d. M. y},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. M. y},
			'short' => q{dd.MM.yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
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
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{H:mm:ss, zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
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
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			GyMd => q{d. M. y GGGGG},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{E d. M.},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d. M. y GGGGG},
			yyyyMMM => q{LLLL y G},
			yyyyMMMEd => q{E d. M. y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMMEd => q{E d. MMMM y G},
			yyyyMMMMd => q{d. MMMM y G},
			yyyyMMMd => q{d. M. y G},
			yyyyMd => q{d. M. y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			GyMd => q{d. M. y GGGGG},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmsvvvv => q{H:mm:ss, vvvv},
			Hmv => q{H:mm v},
			Hmvvvv => q{H:mm, vvvv},
			MEd => q{E d. M.},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMW => q{W. 'týden' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmsvvvv => q{h:mm:ss a, vvvv},
			hmv => q{h:mm a v},
			hmvvvv => q{h:mm a, vvvv},
			yM => q{M/y},
			yMEd => q{E d. M. y},
			yMMM => q{LLLL y},
			yMMMEd => q{E d. M. y},
			yMMMM => q{LLLL y},
			yMMMMEd => q{E d. MMMM y},
			yMMMMd => q{d. MMMM y},
			yMMMd => q{d. M. y},
			yMd => q{d. M. y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'týden' 'roku' Y},
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
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d. M. y GGGGG – E d. M. y GGGGG},
				M => q{E d. M. y – E d. M. y GGGGG},
				d => q{E d. M. y – E d. M. y GGGGG},
				y => q{E d. M. y – E d. M. y GGGGG},
			},
			GyMMM => {
				G => q{LLLL y G – LLLL y G},
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			GyMMMEd => {
				G => q{E d. M. y G – E d. M. y G},
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			GyMMMd => {
				G => q{d. M. y G – d. M. y G},
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			GyMd => {
				G => q{d. M. y GGGGG – d. M. y GGGGG},
				M => q{d. M. y – d. M. y GGGGG},
				d => q{d. M. y – d. M. y GGGGG},
				y => q{d. M. y – d. M. y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hmvvvv => {
				H => q{H:mm–H:mm, vvvv},
				m => q{H:mm–H:mm, vvvv},
			},
			Hv => {
				H => q{H–H v},
			},
			Hvvvv => {
				H => q{H–H, vvvv},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
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
			hmvvvv => {
				a => q{h:mm a – h:mm a, vvvv},
				h => q{h:mm–h:mm a, vvvv},
				m => q{h:mm–h:mm a, vvvv},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			hvvvv => {
				a => q{h a – h a, vvvv},
				h => q{h–h a, vvvv},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d. M. y GGGGG – E d. M. y GGGGG},
				M => q{E d. M. y – E d. M. y GGGGG},
				d => q{E d. M. y – E d. M. y GGGGG},
				y => q{E d. M. y – E d. M. y GGGGG},
			},
			GyMMM => {
				G => q{LLLL y G – LLLL y G},
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			GyMMMEd => {
				G => q{E d. M. y G – E d. M. y G},
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			GyMMMd => {
				G => q{d. M. y G – d. M. y G},
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			GyMd => {
				G => q{d. M. y GGGGG – d. M. y GGGGG},
				M => q{d. M. y – d. M. y GGGGG},
				d => q{d. M. y – d. M. y GGGGG},
				y => q{d. M. y – d. M. y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hmvvvv => {
				H => q{H:mm–H:mm, vvvv},
				m => q{H:mm–H:mm, vvvv},
			},
			Hv => {
				H => q{H–H v},
			},
			Hvvvv => {
				H => q{H–H, vvvv},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
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
			hmvvvv => {
				a => q{h:mm a – h:mm a, vvvv},
				h => q{h:mm–h:mm a, vvvv},
				m => q{h:mm–h:mm a, vvvv},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			hvvvv => {
				a => q{h a – h a, vvvv},
				h => q{h–h a, vvvv},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y},
				d => q{E dd.MM.y – E dd.MM.y},
				y => q{E dd.MM.y – E dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y},
				d => q{E d. M. – E d. M. y},
				y => q{E d. M. y – E d. M. y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d. M. – d. M. y},
				d => q{d.–d. M. y},
				y => q{d. M. y – d. M. y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(krysa),
						1 => q(buvol),
						2 => q(tygr),
						3 => q(zajíc),
						4 => q(drak),
						5 => q(had),
						6 => q(kůň),
						7 => q(koza),
						8 => q(opice),
						9 => q(kohout),
						10 => q(pes),
						11 => q(vepř),
					},
				},
			},
		},
		'dangi' => {
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Krysa),
						1 => q(Buvol),
						2 => q(Tygr),
						3 => q(Zajíc),
						4 => q(Drak),
						5 => q(Had),
						6 => q(Kůň),
						7 => q(Koza),
						8 => q(Opice),
						9 => q(Kohout),
						10 => q(Pes),
						11 => q(Vepř),
					},
					'narrow' => {
						0 => q(Krysa),
						1 => q(Buvol),
						2 => q(Tygr),
						3 => q(Zajíc),
						4 => q(Drak),
						5 => q(Had),
						6 => q(Kůň),
						7 => q(Koza),
						8 => q(Opice),
						9 => q(Kohout),
						10 => q(Pes),
						11 => q(Vepř),
					},
					'wide' => {
						0 => q(Krysa),
						1 => q(Buvol),
						2 => q(Tygr),
						3 => q(Zajíc),
						4 => q(Drak),
						5 => q(Had),
						6 => q(Kůň),
						7 => q(Koza),
						8 => q(Opice),
						9 => q(Kohout),
						10 => q(Pes),
						11 => q(Vepř),
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
		hourFormat => q(+H:mm;-H:mm),
		regionFormat => q(časové pásmo {0}),
		'Acre' => {
			long => {
				'daylight' => q#acrejský letní čas#,
				'generic' => q#acrejský čas#,
				'standard' => q#acrejský standardní čas#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#afghánský čas#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidžan#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžír#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Káhira#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Chartúm#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadišu#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndžamena#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakšott#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Svatý Tomáš#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#středoafrický čas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#východoafrický čas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#jihoafrický čas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#západoafrický letní čas#,
				'generic' => q#západoafrický čas#,
				'standard' => q#západoafrický standardní čas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#aljašský letní čas#,
				'generic' => q#aljašský čas#,
				'standard' => q#aljašský standardní čas#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatský letní čas#,
				'generic' => q#Almatský čas#,
				'standard' => q#Almatský standardní čas#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#amazonský letní čas#,
				'generic' => q#amazonský čas#,
				'standard' => q#amazonský standardní čas#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmanské ostrovy#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de México#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Severní Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Severní Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Severní Dakota#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoriko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Svatý Bartoloměj#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Svatý Kryštof#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Svatá Lucie#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Svatý Tomáš (Karibik)#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Svatý Vincenc#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#severoamerický centrální letní čas#,
				'generic' => q#severoamerický centrální čas#,
				'standard' => q#severoamerický centrální standardní čas#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#severoamerický východní letní čas#,
				'generic' => q#severoamerický východní čas#,
				'standard' => q#severoamerický východní standardní čas#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#severoamerický horský letní čas#,
				'generic' => q#severoamerický horský čas#,
				'standard' => q#severoamerický horský standardní čas#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#severoamerický pacifický letní čas#,
				'generic' => q#severoamerický pacifický čas#,
				'standard' => q#severoamerický pacifický standardní čas#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#anadyrský letní čas#,
				'generic' => q#anadyrský čas#,
				'standard' => q#anadyrský standardní čas#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#apijský letní čas#,
				'generic' => q#apijský čas#,
				'standard' => q#apijský standardní čas#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aktauský letní čas#,
				'generic' => q#Aktauský čas#,
				'standard' => q#Aktauský standardní čas#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aktobský letní čas#,
				'generic' => q#Aktobský čas#,
				'standard' => q#Aktobský standardní čas#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arabský letní čas#,
				'generic' => q#arabský čas#,
				'standard' => q#arabský standardní čas#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentinský letní čas#,
				'generic' => q#argentinský čas#,
				'standard' => q#argentinský standardní čas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#západoargentinský letní čas#,
				'generic' => q#západoargentinský čas#,
				'standard' => q#západoargentinský standardní čas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#arménský letní čas#,
				'generic' => q#arménský čas#,
				'standard' => q#arménský standardní čas#,
			},
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ašchabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdád#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrajn#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrút#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunej#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Čojbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damašek#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dháka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalém#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kábul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karáčí#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Káthmándú#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kučing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikósie#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuzněck#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnompenh#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pchjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijád#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Či Minovo město#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Soul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šanghaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Sredněkolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tchaj-pej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimbú#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulánbátar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekatěrinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlantický letní čas#,
				'generic' => q#atlantický čas#,
				'standard' => q#atlantický standardní čas#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorské ostrovy#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudy#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanárské ostrovy#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kapverdy#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faerské ostrovy#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Jižní Georgie#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Svatá Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#středoaustralský letní čas#,
				'generic' => q#středoaustralský čas#,
				'standard' => q#středoaustralský standardní čas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#středozápadní australský letní čas#,
				'generic' => q#středozápadní australský čas#,
				'standard' => q#středozápadní australský standardní čas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#východoaustralský letní čas#,
				'generic' => q#východoaustralský čas#,
				'standard' => q#východoaustralský standardní čas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#západoaustralský letní čas#,
				'generic' => q#západoaustralský čas#,
				'standard' => q#západoaustralský standardní čas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ázerbájdžánský letní čas#,
				'generic' => q#ázerbájdžánský čas#,
				'standard' => q#ázerbájdžánský standardní čas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#azorský letní čas#,
				'generic' => q#azorský čas#,
				'standard' => q#azorský standardní čas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladéšský letní čas#,
				'generic' => q#bangladéšský čas#,
				'standard' => q#bangladéšský standardní čas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#bhútánský čas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#bolivijský čas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#brasilijský letní čas#,
				'generic' => q#brasilijský čas#,
				'standard' => q#brasilijský standardní čas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#brunejský čas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kapverdský letní čas#,
				'generic' => q#kapverdský čas#,
				'standard' => q#kapverdský standardní čas#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#čas Caseyho stanice#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#chamorrský čas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#chathamský letní čas#,
				'generic' => q#chathamský čas#,
				'standard' => q#chathamský standardní čas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilský letní čas#,
				'generic' => q#chilský čas#,
				'standard' => q#chilský standardní čas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#čínský letní čas#,
				'generic' => q#čínský čas#,
				'standard' => q#čínský standardní čas#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#čojbalsanský letní čas#,
				'generic' => q#čojbalsanský čas#,
				'standard' => q#čojbalsanský standardní čas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#čas Vánočního ostrova#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#čas Kokosových ostrovů#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolumbijský letní čas#,
				'generic' => q#kolumbijský čas#,
				'standard' => q#kolumbijský standardní čas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#letní čas Cookových ostrovů#,
				'generic' => q#čas Cookových ostrovů#,
				'standard' => q#standardní čas Cookových ostrovů#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubánský letní čas#,
				'generic' => q#kubánský čas#,
				'standard' => q#kubánský standardní čas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#čas Davisovy stanice#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#čas stanice Dumonta d’Urvilla#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#východotimorský čas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#letní čas Velikonočního ostrova#,
				'generic' => q#čas Velikonočního ostrova#,
				'standard' => q#standardní čas Velikonočního ostrova#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ekvádorský čas#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinovaný světový čas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#neznámé město#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrachaň#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athény#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Bělehrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukurešť#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapešť#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišiněv#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kodaň#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#irský letní čas#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinky#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrov Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kyjev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lublaň#,
		},
		'Europe/London' => {
			exemplarCity => q#Londýn#,
			long => {
				'daylight' => q#britský letní čas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lucemburk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paříž#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Řím#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofie#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikán#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vídeň#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Záhřeb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Záporoží#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Curych#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#středoevropský letní čas#,
				'generic' => q#středoevropský čas#,
				'standard' => q#středoevropský standardní čas#,
			},
			short => {
				'daylight' => q#SELČ#,
				'generic' => q#SEČ#,
				'standard' => q#SEČ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#východoevropský letní čas#,
				'generic' => q#východoevropský čas#,
				'standard' => q#východoevropský standardní čas#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#dálněvýchodoevropský čas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#západoevropský letní čas#,
				'generic' => q#západoevropský čas#,
				'standard' => q#západoevropský standardní čas#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#falklandský letní čas#,
				'generic' => q#falklandský čas#,
				'standard' => q#falklandský standardní čas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fidžijský letní čas#,
				'generic' => q#fidžijský čas#,
				'standard' => q#fidžijský standardní čas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#francouzskoguyanský čas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#čas Francouzských jižních a antarktických území#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#greenwichský střední čas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#galapážský čas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#gambierský čas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#gruzínský letní čas#,
				'generic' => q#gruzínský čas#,
				'standard' => q#gruzínský standardní čas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#čas Gilbertových ostrovů#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#východogrónský letní čas#,
				'generic' => q#východogrónský čas#,
				'standard' => q#východogrónský standardní čas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#západogrónský letní čas#,
				'generic' => q#západogrónský čas#,
				'standard' => q#západogrónský standardní čas#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guamský čas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#standardní čas Perského zálivu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyanský čas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#havajsko-aleutský letní čas#,
				'generic' => q#havajsko-aleutský čas#,
				'standard' => q#havajsko-aleutský standardní čas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hongkongský letní čas#,
				'generic' => q#hongkongský čas#,
				'standard' => q#hongkongský standardní čas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#hovdský letní čas#,
				'generic' => q#hovdský čas#,
				'standard' => q#hovdský standardní čas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indický čas#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Vánoční ostrov#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosové ostrovy#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komory#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelenovy ostrovy#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maledivy#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricius#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#indickooceánský čas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indočínský čas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#středoindonéský čas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#východoindonéský čas#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#západoindonéský čas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#íránský letní čas#,
				'generic' => q#íránský čas#,
				'standard' => q#íránský standardní čas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#irkutský letní čas#,
				'generic' => q#irkutský čas#,
				'standard' => q#irkutský standardní čas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#izraelský letní čas#,
				'generic' => q#izraelský čas#,
				'standard' => q#izraelský standardní čas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japonský letní čas#,
				'generic' => q#japonský čas#,
				'standard' => q#japonský standardní čas#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#petropavlovsko-kamčatský letní čas#,
				'generic' => q#petropavlovsko-kamčatský čas#,
				'standard' => q#petropavlovsko-kamčatský standardní čas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#východokazachstánský čas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#západokazachstánský čas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#korejský letní čas#,
				'generic' => q#korejský čas#,
				'standard' => q#korejský standardní čas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#kosrajský čas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#krasnojarský letní čas#,
				'generic' => q#krasnojarský čas#,
				'standard' => q#krasnojarský standardní čas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kyrgyzský čas#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Srílanský čas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#čas Rovníkových ostrovů#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#letní čas ostrova lorda Howa#,
				'generic' => q#čas ostrova lorda Howa#,
				'standard' => q#standardní čas ostrova lorda Howa#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macajský letní čas#,
				'generic' => q#Macajský čas#,
				'standard' => q#Macajský standardní čas#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#čas ostrova Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#magadanský letní čas#,
				'generic' => q#magadanský čas#,
				'standard' => q#magadanský standardní čas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malajský čas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maledivský čas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#markézský čas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#čas Marshallových ostrovů#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#mauricijský letní čas#,
				'generic' => q#mauricijský čas#,
				'standard' => q#mauricijský standardní čas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#čas Mawsonovy stanice#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#severozápadní mexický letní čas#,
				'generic' => q#severozápadní mexický čas#,
				'standard' => q#severozápadní mexický standardní čas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#mexický pacifický letní čas#,
				'generic' => q#mexický pacifický čas#,
				'standard' => q#mexický pacifický standardní čas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ulánbátarský letní čas#,
				'generic' => q#ulánbátarský čas#,
				'standard' => q#ulánbátarský standardní čas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#moskevský letní čas#,
				'generic' => q#moskevský čas#,
				'standard' => q#moskevský standardní čas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#myanmarský čas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#naurský čas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepálský čas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#novokaledonský letní čas#,
				'generic' => q#novokaledonský čas#,
				'standard' => q#novokaledonský standardní čas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#novozélandský letní čas#,
				'generic' => q#novozélandský čas#,
				'standard' => q#novozélandský standardní čas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#newfoundlandský letní čas#,
				'generic' => q#newfoundlandský čas#,
				'standard' => q#newfoundlandský standardní čas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#niuejský čas#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#norfolkský letní čas#,
				'generic' => q#norfolkský čas#,
				'standard' => q#norfolkský standardní čas#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#letní čas souostroví Fernando de Noronha#,
				'generic' => q#čas souostroví Fernando de Noronha#,
				'standard' => q#standardní čas souostroví Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Severomariánský čas#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#novosibirský letní čas#,
				'generic' => q#novosibirský čas#,
				'standard' => q#novosibirský standardní čas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#omský letní čas#,
				'generic' => q#omský čas#,
				'standard' => q#omský standardní čas#,
			},
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chathamské ostrovy#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Velikonoční ostrov#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapágy#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambierovy ostrovy#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markézy#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairnovy ostrovy#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuukské ostrovy#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pákistánský letní čas#,
				'generic' => q#pákistánský čas#,
				'standard' => q#pákistánský standardní čas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palauský čas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#čas Papuy-Nové Guiney#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguayský letní čas#,
				'generic' => q#paraguayský čas#,
				'standard' => q#paraguayský standardní čas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruánský letní čas#,
				'generic' => q#peruánský čas#,
				'standard' => q#peruánský standardní čas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filipínský letní čas#,
				'generic' => q#filipínský čas#,
				'standard' => q#filipínský standardní čas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#čas Fénixových ostrovů#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#pierre-miquelonský letní čas#,
				'generic' => q#pierre-miquelonský čas#,
				'standard' => q#pierre-miquelonský standardní čas#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#čas Pitcairnových ostrovů#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ponapský čas#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#pchjongjangský čas#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kyzylordský letní čas#,
				'generic' => q#Kyzylordský čas#,
				'standard' => q#Kyzylordský standardní čas#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#réunionský čas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#čas Rotherovy stanice#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sachalinský letní čas#,
				'generic' => q#sachalinský čas#,
				'standard' => q#sachalinský standardní čas#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#samarský letní čas#,
				'generic' => q#samarský čas#,
				'standard' => q#samarský standardní čas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samojský letní čas#,
				'generic' => q#samojský čas#,
				'standard' => q#samojský standardní čas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#seychelský čas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singapurský čas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#čas Šalamounových ostrovů#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#čas Jižní Georgie#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinamský čas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#čas stanice Šówa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahitský čas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#tchajpejský letní čas#,
				'generic' => q#tchajpejský čas#,
				'standard' => q#tchajpejský standardní čas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tádžický čas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tokelauský čas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tonžský letní čas#,
				'generic' => q#tonžský čas#,
				'standard' => q#tonžský standardní čas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#chuukský čas#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmenský letní čas#,
				'generic' => q#turkmenský čas#,
				'standard' => q#turkmenský standardní čas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvalský čas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayský letní čas#,
				'generic' => q#uruguayský čas#,
				'standard' => q#uruguayský standardní čas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzbecký letní čas#,
				'generic' => q#uzbecký čas#,
				'standard' => q#uzbecký standardní čas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatský letní čas#,
				'generic' => q#vanuatský čas#,
				'standard' => q#vanuatský standardní čas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelský čas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#vladivostocký letní čas#,
				'generic' => q#vladivostocký čas#,
				'standard' => q#vladivostocký standardní čas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#volgogradský letní čas#,
				'generic' => q#volgogradský čas#,
				'standard' => q#volgogradský standardní čas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#čas stanice Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#čas ostrova Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#čas ostrovů Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#jakutský letní čas#,
				'generic' => q#jakutský čas#,
				'standard' => q#jakutský standardní čas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#jekatěrinburský letní čas#,
				'generic' => q#jekatěrinburský čas#,
				'standard' => q#jekatěrinburský standardní čas#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#yukonský čas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
