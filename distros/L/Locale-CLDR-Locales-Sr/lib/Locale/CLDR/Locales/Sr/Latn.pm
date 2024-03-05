=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sr::Latn - Package for language Serbian

=cut

package Locale::CLDR::Locales::Sr::Latn;
# This file auto generated from Data\common\main\sr_Latn.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'ordi' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(i),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(‘ i =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(‘ i =%spellout-ordinal=),
				},
			},
		},
		'ordti' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ti),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(‘ =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(‘ =%spellout-ordinal=),
				},
			},
		},
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
					rule => q(←← koma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dve),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ i →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ i →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ i →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ i →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ i →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ i →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ i →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ i →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←sto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← hiljadu[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← hiljada[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← milijarda[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijarda[ →→]),
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
					rule => q(←← koma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedan),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dva),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četiri),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pet),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(šest),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sedam),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osam),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(devet),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deset),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(jedanaest),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dvanaest),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trinaest),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(četrnaest),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(petnaest),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(šesnaest),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sedamnaest),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(osamnaest),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(devetnaest),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ i →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ i →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ i →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ i →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ i →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ i →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ i →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ i →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←sto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← hiljadu[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← hiljada[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← milijarda[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijarda[ →→]),
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
					rule => q(←← koma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dva),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset[ i →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset[ i →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset[ i →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset[ i →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset[ i →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset[ i →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset[ i →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset[ i →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←sto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← hiljadu[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← hiljada[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← milijarda[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← bilijarda[ →→]),
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
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulti),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(prvi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(drugi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(treći),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(četvrti),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(peti),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(šesti),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sedmi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osmi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(deveti),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deseti),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(jedanaesti),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dvanaesti),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trinaesti),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(četrnaesti),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(petnaesti),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(šesnaesti),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sedamnaesti),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(osamnaesti),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(devetnaesti),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadeset→%%ordi→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trideset→%%ordi→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(četrdeset→%%ordi→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(pedeset→%%ordi→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(šezdeset→%%ordi→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sedamdeset→%%ordi→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(osamdeset→%%ordi→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(devedeset→%%ordi→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sto→%%ordti→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dvesta→%%ordti→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trista→%%ordti→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←sto→%%ordti→),
				},
				'max' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←sto→%%ordti→),
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
				'aa' => 'afarski',
 				'ab' => 'abhaski',
 				'ace' => 'aceški',
 				'ach' => 'akoli',
 				'ada' => 'adangme',
 				'ady' => 'adigejski',
 				'ae' => 'avestanski',
 				'af' => 'afrikans',
 				'afh' => 'afrihili',
 				'agq' => 'agem',
 				'ain' => 'ainu',
 				'ak' => 'akanski',
 				'akk' => 'akadijski',
 				'ale' => 'aleutski',
 				'alt' => 'južnoaltajski',
 				'am' => 'amharski',
 				'an' => 'aragonski',
 				'ang' => 'staroengleski',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arapski',
 				'ar_001' => 'savremeni standardni arapski',
 				'arc' => 'aramejski',
 				'arn' => 'mapuče',
 				'arp' => 'arapaho',
 				'ars' => 'najdiarapski',
 				'arw' => 'aravački',
 				'as' => 'asamski',
 				'asa' => 'asu',
 				'ast' => 'asturijski',
 				'atj' => 'atikameku',
 				'av' => 'avarski',
 				'awa' => 'avadi',
 				'ay' => 'ajmara',
 				'az' => 'azerbejdžanski',
 				'az@alt=short' => 'azerski',
 				'ba' => 'baškirski',
 				'bal' => 'belučki',
 				'ban' => 'balijski',
 				'bas' => 'basa',
 				'be' => 'beloruski',
 				'bej' => 'bedža',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bugarski',
 				'bgc' => 'harijanski',
 				'bgn' => 'zapadni belučki',
 				'bho' => 'bodžpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bla' => 'sisika',
 				'bm' => 'bambara',
 				'bn' => 'bengalski',
 				'bo' => 'tibetanski',
 				'br' => 'bretonski',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosanski',
 				'bua' => 'burjatski',
 				'bug' => 'bugijski',
 				'byn' => 'blinski',
 				'ca' => 'katalonski',
 				'cad' => 'kado',
 				'car' => 'karipski',
 				'cay' => 'kajuga',
 				'cch' => 'atsam',
 				'ccp' => 'čakma',
 				'ce' => 'čečenski',
 				'ceb' => 'sebuanski',
 				'cgg' => 'čiga',
 				'ch' => 'čamoro',
 				'chb' => 'čipča',
 				'chg' => 'čagataj',
 				'chk' => 'čučki',
 				'chm' => 'mari',
 				'chn' => 'činučki',
 				'cho' => 'čoktavski',
 				'chp' => 'čipevjanski',
 				'chr' => 'čeroki',
 				'chy' => 'čejenski',
 				'ckb' => 'centralni kurdski',
 				'clc' => 'čilkotin',
 				'co' => 'korzikanski',
 				'cop' => 'koptski',
 				'cr' => 'kri',
 				'crg' => 'mičif',
 				'crh' => 'krimskotatarski',
 				'crj' => 'jugoistočni kri',
 				'crk' => 'plainskri',
 				'crl' => 'severoistočni kri',
 				'crm' => 'muzkri',
 				'crr' => 'karolinški algonkvijan',
 				'crs' => 'sejšelski kreolski francuski',
 				'cs' => 'češki',
 				'csb' => 'kašupski',
 				'csw' => 'močvarni kri',
 				'cu' => 'crkvenoslovenski',
 				'cv' => 'čuvaški',
 				'cy' => 'velški',
 				'da' => 'danski',
 				'dak' => 'dakota',
 				'dar' => 'darginski',
 				'dav' => 'taita',
 				'de' => 'nemački',
 				'de_AT' => 'austrijski nemački',
 				'de_CH' => 'švajcarski visoki nemački',
 				'del' => 'delaverski',
 				'den' => 'slejvi',
 				'dgr' => 'dogripski',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'donjolužičkosrpski',
 				'dua' => 'duala',
 				'dum' => 'srednjeholandski',
 				'dv' => 'maldivski',
 				'dyo' => 'džola fonji',
 				'dyu' => 'đula',
 				'dz' => 'džonga',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efički',
 				'egy' => 'staroegipatski',
 				'eka' => 'ekadžuk',
 				'el' => 'grčki',
 				'elx' => 'elamitski',
 				'en' => 'engleski',
 				'en_GB' => 'engleski (Velika Britanija)',
 				'en_GB@alt=short' => 'engleski (UK)',
 				'en_US' => 'engleski (Sjedinjene Američke Države)',
 				'en_US@alt=short' => 'engleski (SAD)',
 				'enm' => 'srednjeengleski',
 				'eo' => 'esperanto',
 				'es' => 'španski',
 				'es_ES' => 'španski (Evropa)',
 				'et' => 'estonski',
 				'eu' => 'baskijski',
 				'ewo' => 'evondo',
 				'fa' => 'persijski',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'finski',
 				'fil' => 'filipinski',
 				'fj' => 'fidžijski',
 				'fo' => 'farski',
 				'fon' => 'fon',
 				'fr' => 'francuski',
 				'frc' => 'kajunski francuski',
 				'frm' => 'srednjefrancuski',
 				'fro' => 'starofrancuski',
 				'frr' => 'severnofrizijski',
 				'frs' => 'istočnofrizijski',
 				'fur' => 'friulski',
 				'fy' => 'zapadni frizijski',
 				'ga' => 'irski',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gay' => 'gajo',
 				'gba' => 'gbaja',
 				'gd' => 'škotski gelski',
 				'gez' => 'geez',
 				'gil' => 'gilbertski',
 				'gl' => 'galicijski',
 				'gmh' => 'srednji visokonemački',
 				'gn' => 'gvarani',
 				'goh' => 'staronemački',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotski',
 				'grb' => 'grebo',
 				'grc' => 'starogrčki',
 				'gsw' => 'nemački (Švajcarska)',
 				'gu' => 'gudžarati',
 				'guz' => 'gusi',
 				'gv' => 'manks',
 				'gwi' => 'gvičinski',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'haw' => 'havajski',
 				'hax' => 'južni haida',
 				'he' => 'hebrejski',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hingliš',
 				'hil' => 'hiligajnonski',
 				'hit' => 'hetitski',
 				'hmn' => 'hmonški',
 				'ho' => 'hiri motu',
 				'hr' => 'hrvatski',
 				'hsb' => 'gornjolužičkosrpski',
 				'ht' => 'haićanski',
 				'hu' => 'mađarski',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'jermenski',
 				'hz' => 'herero',
 				'ia' => 'interlingva',
 				'iba' => 'ibanski',
 				'ibb' => 'ibibio',
 				'id' => 'indonežanski',
 				'ie' => 'interlingve',
 				'ig' => 'igbo',
 				'ii' => 'sečuanski ji',
 				'ik' => 'inupik',
 				'ikt' => 'zapadnokanadski inuktitut',
 				'ilo' => 'iloko',
 				'inh' => 'inguški',
 				'io' => 'ido',
 				'is' => 'islandski',
 				'it' => 'italijanski',
 				'iu' => 'inuktitutski',
 				'ja' => 'japanski',
 				'jbo' => 'ložban',
 				'jgo' => 'ngomba',
 				'jmc' => 'mačame',
 				'jpr' => 'judeo-persijski',
 				'jrb' => 'judeo-arapski',
 				'jv' => 'javanski',
 				'ka' => 'gruzijski',
 				'kaa' => 'kara-kalpaški',
 				'kab' => 'kabile',
 				'kac' => 'kačinski',
 				'kaj' => 'džu',
 				'kam' => 'kamba',
 				'kaw' => 'kavi',
 				'kbd' => 'kabardijski',
 				'kcg' => 'tjap',
 				'kde' => 'makonde',
 				'kea' => 'zelenortski',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingang',
 				'kha' => 'kasi',
 				'kho' => 'kotaneški',
 				'khq' => 'kojra čiini',
 				'ki' => 'kikuju',
 				'kj' => 'kvanjama',
 				'kk' => 'kazaški',
 				'kkj' => 'kako',
 				'kl' => 'grenlandski',
 				'kln' => 'kalendžinski',
 				'km' => 'kmerski',
 				'kmb' => 'kimbundu',
 				'kn' => 'kanada',
 				'ko' => 'korejski',
 				'koi' => 'komi-permski',
 				'kok' => 'konkani',
 				'kos' => 'kosrenski',
 				'kpe' => 'kpele',
 				'kr' => 'kanuri',
 				'krc' => 'karačajsko-balkarski',
 				'kri' => 'krio',
 				'krl' => 'karelski',
 				'kru' => 'kuruk',
 				'ks' => 'kašmirski',
 				'ksb' => 'šambala',
 				'ksf' => 'bafija',
 				'ksh' => 'kelnski',
 				'ku' => 'kurdski',
 				'kum' => 'kumički',
 				'kut' => 'kutenaj',
 				'kv' => 'komi',
 				'kw' => 'kornvolski',
 				'kwk' => 'kvakvala',
 				'ky' => 'kirgiski',
 				'la' => 'latinski',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'landa',
 				'lam' => 'lamba',
 				'lb' => 'luksemburški',
 				'lez' => 'lezginski',
 				'lg' => 'ganda',
 				'li' => 'limburški',
 				'lil' => 'lilut',
 				'lkt' => 'lakota',
 				'lmo' => 'lombard',
 				'ln' => 'lingala',
 				'lo' => 'laoski',
 				'lol' => 'mongo',
 				'lou' => 'luizijanski kreolski',
 				'loz' => 'lozi',
 				'lrc' => 'severni luri',
 				'lsm' => 'samia',
 				'lt' => 'litvanski',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luisenjo',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'lujia',
 				'lv' => 'letonski',
 				'mad' => 'madurski',
 				'mag' => 'magahi',
 				'mai' => 'maitili',
 				'mak' => 'makasarski',
 				'man' => 'mandingo',
 				'mas' => 'masajski',
 				'mdf' => 'mokša',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisjen',
 				'mg' => 'malgaški',
 				'mga' => 'srednjeirski',
 				'mgh' => 'makuva-mito',
 				'mgo' => 'meta',
 				'mh' => 'maršalski',
 				'mi' => 'maorski',
 				'mic' => 'mikmak',
 				'min' => 'minangkabau',
 				'mk' => 'makedonski',
 				'ml' => 'malajalam',
 				'mn' => 'mongolski',
 				'mnc' => 'mandžurski',
 				'mni' => 'manipurski',
 				'moe' => 'inuajmun',
 				'moh' => 'mohočki',
 				'mos' => 'mosi',
 				'mr' => 'marati',
 				'ms' => 'malajski',
 				'mt' => 'malteški',
 				'mua' => 'mundang',
 				'mul' => 'Više jezika',
 				'mus' => 'kriški',
 				'mwl' => 'mirandski',
 				'mwr' => 'marvari',
 				'my' => 'burmanski',
 				'myv' => 'erzja',
 				'mzn' => 'mazanderanski',
 				'na' => 'nauruski',
 				'nap' => 'napuljski',
 				'naq' => 'nama',
 				'nb' => 'norveški bukmol',
 				'nd' => 'severni ndebele',
 				'nds' => 'niskonemački',
 				'nds_NL' => 'niskosaksonski',
 				'ne' => 'nepalski',
 				'new' => 'nevari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niuejski',
 				'nl' => 'holandski',
 				'nl_BE' => 'flamanski',
 				'nmg' => 'kvasio',
 				'nn' => 'norveški ninorsk',
 				'nnh' => 'ngiembun',
 				'no' => 'norveški',
 				'nog' => 'nogajski',
 				'non' => 'staronordijski',
 				'nqo' => 'nko',
 				'nr' => 'južni ndebele',
 				'nso' => 'severni soto',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nwc' => 'klasični nevarski',
 				'ny' => 'njandža',
 				'nym' => 'njamvezi',
 				'nyn' => 'njankole',
 				'nyo' => 'njoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitanski',
 				'oj' => 'odžibve',
 				'ojb' => 'severozapadni odžibva',
 				'ojc' => 'centralni odžibva',
 				'ojs' => 'odžikri',
 				'ojw' => 'zapadni odžibva',
 				'oka' => 'okangan',
 				'om' => 'oromo',
 				'or' => 'odija',
 				'os' => 'osetinski',
 				'osa' => 'osage',
 				'ota' => 'osmanski turski',
 				'pa' => 'pendžapski',
 				'pag' => 'pangasinanski',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papijamento',
 				'pau' => 'palauski',
 				'pcm' => 'nigerijski pidžin',
 				'peo' => 'staropersijski',
 				'phn' => 'feničanski',
 				'pi' => 'pali',
 				'pis' => 'pidžin',
 				'pl' => 'poljski',
 				'pon' => 'ponpejski',
 				'pqm' => 'malisepasamakvodi',
 				'prg' => 'pruski',
 				'pro' => 'starooksitanski',
 				'ps' => 'paštunski',
 				'ps@alt=variant' => 'pašto',
 				'pt' => 'portugalski',
 				'pt_PT' => 'portugalski (Portugal)',
 				'qu' => 'kečua',
 				'quc' => 'kiče',
 				'raj' => 'radžastanski',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonganski',
 				'rhg' => 'rohingja',
 				'rm' => 'romanš',
 				'rn' => 'kirundi',
 				'ro' => 'rumunski',
 				'ro_MD' => 'moldavski',
 				'rof' => 'rombo',
 				'rom' => 'romski',
 				'ru' => 'ruski',
 				'rup' => 'cincarski',
 				'rw' => 'kinjaruanda',
 				'rwk' => 'rua',
 				'sa' => 'sanskrit',
 				'sad' => 'sandave',
 				'sah' => 'saha',
 				'sam' => 'samarijanski aramejski',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambaj',
 				'sbp' => 'sangu',
 				'sc' => 'sardinski',
 				'scn' => 'sicilijanski',
 				'sco' => 'škotski',
 				'sd' => 'sindi',
 				'sdh' => 'južnokurdski',
 				'se' => 'severni sami',
 				'seh' => 'sena',
 				'sel' => 'selkupski',
 				'ses' => 'kojraboro seni',
 				'sg' => 'sango',
 				'sga' => 'staroirski',
 				'sh' => 'srpskohrvatski',
 				'shi' => 'tašelhit',
 				'shn' => 'šanski',
 				'si' => 'sinhaleški',
 				'sid' => 'sidamo',
 				'sk' => 'slovački',
 				'sl' => 'slovenački',
 				'slh' => 'južni lašutsid',
 				'sm' => 'samoanski',
 				'sma' => 'južni sami',
 				'smj' => 'lule sami',
 				'smn' => 'inari sami',
 				'sms' => 'skolt sami',
 				'sn' => 'šona',
 				'snk' => 'soninke',
 				'so' => 'somalski',
 				'sog' => 'sogdijski',
 				'sq' => 'albanski',
 				'sr' => 'srpski',
 				'srn' => 'sranan tongo',
 				'srr' => 'sererski',
 				'ss' => 'svazi',
 				'ssy' => 'saho',
 				'st' => 'sesoto',
 				'str' => 'streicsališ',
 				'su' => 'sundanski',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerski',
 				'sv' => 'švedski',
 				'sw' => 'svahili',
 				'sw_CD' => 'kisvahili',
 				'swb' => 'komorski',
 				'syc' => 'sirijački',
 				'syr' => 'sirijski',
 				'ta' => 'tamilski',
 				'tce' => 'južni tačon',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadžički',
 				'tgx' => 'tagiš',
 				'th' => 'tajski',
 				'tht' => 'tahltan',
 				'ti' => 'tigrinja',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turkmenski',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonski',
 				'tli' => 'tlingit',
 				'tmh' => 'tamašek',
 				'tn' => 'cvana',
 				'to' => 'tonganski',
 				'tog' => 'njasa tonga',
 				'tok' => 'tokipona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turski',
 				'trv' => 'taroko',
 				'ts' => 'conga',
 				'tsi' => 'cimšian',
 				'tt' => 'tatarski',
 				'ttm' => 'severni tučon',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'tvi',
 				'twq' => 'tasavak',
 				'ty' => 'tahićanski',
 				'tyv' => 'tuvinski',
 				'tzm' => 'centralnoatlaski tamašek',
 				'udm' => 'udmurtski',
 				'ug' => 'ujgurski',
 				'uga' => 'ugaritski',
 				'uk' => 'ukrajinski',
 				'umb' => 'umbundu',
 				'und' => 'nepoznat jezik',
 				'ur' => 'urdu',
 				'uz' => 'uzbečki',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vijetnamski',
 				'vo' => 'volapik',
 				'vot' => 'vodski',
 				'vun' => 'vundžo',
 				'wa' => 'valonski',
 				'wae' => 'valserski',
 				'wal' => 'volajta',
 				'war' => 'varajski',
 				'was' => 'vašo',
 				'wbp' => 'varlpiri',
 				'wo' => 'volof',
 				'wuu' => 'vu kineski',
 				'xal' => 'kalmički',
 				'xh' => 'kosa',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japski',
 				'yav' => 'jangben',
 				'ybb' => 'jemba',
 				'yi' => 'jidiš',
 				'yo' => 'joruba',
 				'yrl' => 'ningatu',
 				'yue' => 'kantonski',
 				'yue@alt=menu' => 'kantonski kineski',
 				'za' => 'džuanški',
 				'zap' => 'zapotečki',
 				'zbl' => 'blisimboli',
 				'zen' => 'zenaga',
 				'zgh' => 'standardni marokanski tamazigt',
 				'zh' => 'kineski',
 				'zh@alt=menu' => 'mandarinski kineski',
 				'zh_Hans' => 'pojednostavljeni kineski',
 				'zh_Hans@alt=long' => 'pojednostavljeni mandarinski kineski',
 				'zh_Hant' => 'tradicionalni kineski',
 				'zh_Hant@alt=long' => 'tradicionalni mandarinski kineski',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'bez lingvističkog sadržaja',
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
 			'Arab' => 'arapsko pismo',
 			'Arab@alt=variant' => 'persijsko-arapsko pismo',
 			'Aran' => 'nastalik',
 			'Armi' => 'imperijsko aramejsko pismo',
 			'Armn' => 'jermensko pismo',
 			'Avst' => 'avestansko pismo',
 			'Bali' => 'balijsko pismo',
 			'Batk' => 'batak pismo',
 			'Beng' => 'bengalsko pismo',
 			'Blis' => 'blisimbolično pismo',
 			'Bopo' => 'bopomofo pismo',
 			'Brah' => 'bramansko pismo',
 			'Brai' => 'brajevo pismo',
 			'Bugi' => 'buginsko pismo',
 			'Buhd' => 'buhidsko pismo',
 			'Cakm' => 'čakma',
 			'Cans' => 'ujedinjeni kanadski aboridžinski silabici',
 			'Cari' => 'karijsko pismo',
 			'Cham' => 'čamsko pismo',
 			'Cher' => 'čeroki',
 			'Cirt' => 'cirt pismo',
 			'Copt' => 'koptičko pismo',
 			'Cprt' => 'kiparsko pismo',
 			'Cyrl' => 'ćirilica',
 			'Cyrs' => 'Staroslovenska crkvena ćirilica',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'Dezeret',
 			'Egyd' => 'egipatsko narodno pismo',
 			'Egyh' => 'egipatsko hijeratsko pismo',
 			'Egyp' => 'egipatski hijeroglifi',
 			'Ethi' => 'etiopsko pismo',
 			'Geok' => 'gruzijsko khutsuri pismo',
 			'Geor' => 'gruzijsko pismo',
 			'Glag' => 'glagoljica',
 			'Goth' => 'Gotika',
 			'Grek' => 'grčko pismo',
 			'Gujr' => 'gudžaratsko pismo',
 			'Guru' => 'gurmuki pismo',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanuno',
 			'Hans' => 'pojednostavljeno kinesko pismo',
 			'Hans@alt=stand-alone' => 'pojednostavljeno han pismo',
 			'Hant' => 'tradicionalno kinesko pismo',
 			'Hant@alt=stand-alone' => 'tradicionalno han pismo',
 			'Hebr' => 'hebrejsko pismo',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahav hmong pismo',
 			'Hrkt' => 'japanska slogovna pisma',
 			'Hung' => 'staromađarsko pismo',
 			'Inds' => 'induško pismo',
 			'Ital' => 'stari italik',
 			'Jamo' => 'džamo',
 			'Java' => 'javansko pismo',
 			'Jpan' => 'japansko pismo',
 			'Kali' => 'kajah-li pismo',
 			'Kana' => 'katakana',
 			'Khar' => 'karošti pismo',
 			'Khmr' => 'kmersko pismo',
 			'Knda' => 'kanada pismo',
 			'Kore' => 'korejsko pismo',
 			'Kthi' => 'kaiti',
 			'Lana' => 'lanna pismo',
 			'Laoo' => 'laoško pismo',
 			'Latf' => 'latinica (fraktur varijanta)',
 			'Latg' => 'galska latinica',
 			'Latn' => 'latinica',
 			'Lepc' => 'lepča pismo',
 			'Limb' => 'limbu pismo',
 			'Lina' => 'linearno A pismo',
 			'Linb' => 'linearno B pismo',
 			'Lyci' => 'lisijsko pismo',
 			'Lydi' => 'lidijsko pismo',
 			'Mand' => 'mandeansko pismo',
 			'Mani' => 'manihejsko pismo',
 			'Maya' => 'majanski hijeroglifi',
 			'Mero' => 'meroitik pismo',
 			'Mlym' => 'malajalamsko pismo',
 			'Mong' => 'mongolsko pismo',
 			'Moon' => 'mesečevo pismo',
 			'Mtei' => 'meitei majek',
 			'Mymr' => 'mijanmarsko pismo',
 			'Nkoo' => 'nko',
 			'Ogam' => 'ogamsko pismo',
 			'Olck' => 'ol čiki',
 			'Orkh' => 'orkonsko pismo',
 			'Orya' => 'orijansko pismo',
 			'Osma' => 'osmanjansko pismo',
 			'Perm' => 'staro permiksko pismo',
 			'Phag' => 'pags-pa pismo',
 			'Phli' => 'pisani pahlavi',
 			'Phlp' => 'psalter pahlavi',
 			'Phlv' => 'pahlavi pismo',
 			'Phnx' => 'Feničansko pismo',
 			'Plrd' => 'porald fonetsko pismo',
 			'Prti' => 'pisani partian',
 			'Rjng' => 'rejang pismo',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo pismo',
 			'Runr' => 'runsko pismo',
 			'Samr' => 'samaritansko pismo',
 			'Sara' => 'sarati pismo',
 			'Saur' => 'sauraštra pismo',
 			'Sgnw' => 'znakovno pismo',
 			'Shaw' => 'šavijansko pismo',
 			'Sinh' => 'sinhalsko pismo',
 			'Sund' => 'sundansko pismo',
 			'Sylo' => 'siloti nagri pismo',
 			'Syrc' => 'sirijsko pismo',
 			'Syre' => 'sirijsko estrangelo pismo',
 			'Syrj' => 'zapadnosirijsko pismo',
 			'Syrn' => 'pismo istočne Sirije',
 			'Tagb' => 'tagbanva pismo',
 			'Tale' => 'tai le pismo',
 			'Talu' => 'novi tai lue',
 			'Taml' => 'tamilsko pismo',
 			'Tavt' => 'tai viet pismo',
 			'Telu' => 'telugu pismo',
 			'Teng' => 'tengvar pismo',
 			'Tfng' => 'tifinag',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'tana pismo',
 			'Thai' => 'tajlandsko pismo',
 			'Tibt' => 'tibetansko pismo',
 			'Ugar' => 'ugaritsko pismo',
 			'Vaii' => 'vai',
 			'Visp' => 'vidljivi govor',
 			'Xpeo' => 'staropersijsko pismo',
 			'Xsux' => 'sumersko-akadsko kuneiform pismo',
 			'Yiii' => 'ji',
 			'Zinh' => 'nasledno pismo',
 			'Zmth' => 'matematička notacija',
 			'Zsye' => 'emodži',
 			'Zsym' => 'simboli',
 			'Zxxx' => 'nepisani jezik',
 			'Zyyy' => 'zajedničko pismo',
 			'Zzzz' => 'nepoznato pismo',

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
			'001' => 'svet',
 			'002' => 'Afrika',
 			'003' => 'Severnoamerički kontinent',
 			'005' => 'Južna Amerika',
 			'009' => 'Okeanija',
 			'011' => 'Zapadna Afrika',
 			'013' => 'Centralna Amerika',
 			'014' => 'Istočna Afrika',
 			'015' => 'Severna Afrika',
 			'017' => 'Centralna Afrika',
 			'018' => 'Južna Afrika',
 			'019' => 'Severna i Južna Amerika',
 			'021' => 'Severna Amerika',
 			'029' => 'Karibi',
 			'030' => 'Istočna Azija',
 			'034' => 'Južna Azija',
 			'035' => 'Jugoistočna Azija',
 			'039' => 'Južna Evropa',
 			'053' => 'Australija i Novi Zeland',
 			'054' => 'Melanezija',
 			'057' => 'Mikronezijski region',
 			'061' => 'Polinezija',
 			'142' => 'Azija',
 			'143' => 'Centralna Azija',
 			'145' => 'Zapadna Azija',
 			'150' => 'Evropa',
 			'151' => 'Istočna Evropa',
 			'154' => 'Severna Evropa',
 			'155' => 'Zapadna Evropa',
 			'202' => 'Podsaharska Afrika',
 			'419' => 'Latinska Amerika',
 			'AC' => 'Ostrvo Asension',
 			'AD' => 'Andora',
 			'AE' => 'Ujedinjeni Arapski Emirati',
 			'AF' => 'Avganistan',
 			'AG' => 'Antigva i Barbuda',
 			'AI' => 'Angvila',
 			'AL' => 'Albanija',
 			'AM' => 'Jermenija',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktik',
 			'AR' => 'Argentina',
 			'AS' => 'Američka Samoa',
 			'AT' => 'Austrija',
 			'AU' => 'Australija',
 			'AW' => 'Aruba',
 			'AX' => 'Olandska Ostrva',
 			'AZ' => 'Azerbejdžan',
 			'BA' => 'Bosna i Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgija',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bugarska',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sveti Bartolomej',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunej',
 			'BO' => 'Bolivija',
 			'BQ' => 'Karipska Holandija',
 			'BR' => 'Brazil',
 			'BS' => 'Bahami',
 			'BT' => 'Butan',
 			'BV' => 'Ostrvo Buve',
 			'BW' => 'Bocvana',
 			'BY' => 'Belorusija',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosova (Kilingova) Ostrva',
 			'CD' => 'Kongo - Kinšasa',
 			'CD@alt=variant' => 'Kongo (DRK)',
 			'CF' => 'Centralnoafrička Republika',
 			'CG' => 'Kongo - Brazavil',
 			'CG@alt=variant' => 'Kongo (Republika)',
 			'CH' => 'Švajcarska',
 			'CI' => 'Obala Slonovače (Kot d’Ivoar)',
 			'CI@alt=variant' => 'Obala Slonovače',
 			'CK' => 'Kukova Ostrva',
 			'CL' => 'Čile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Kolumbija',
 			'CP' => 'Ostrvo Kliperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Zelenortska Ostrva',
 			'CW' => 'Kurasao',
 			'CX' => 'Božićno Ostrvo',
 			'CY' => 'Kipar',
 			'CZ' => 'Češka',
 			'CZ@alt=variant' => 'Češka Republika',
 			'DE' => 'Nemačka',
 			'DG' => 'Dijego Garsija',
 			'DJ' => 'Džibuti',
 			'DK' => 'Danska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikanska Republika',
 			'DZ' => 'Alžir',
 			'EA' => 'Seuta i Melilja',
 			'EC' => 'Ekvador',
 			'EE' => 'Estonija',
 			'EG' => 'Egipat',
 			'EH' => 'Zapadna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Španija',
 			'ET' => 'Etiopija',
 			'EU' => 'Evropska unija',
 			'EZ' => 'Evrozona',
 			'FI' => 'Finska',
 			'FJ' => 'Fidži',
 			'FK' => 'Foklandska Ostrva',
 			'FK@alt=variant' => 'Foklandska (Malvinska) ostrva',
 			'FM' => 'Mikronezija',
 			'FO' => 'Farska Ostrva',
 			'FR' => 'Francuska',
 			'GA' => 'Gabon',
 			'GB' => 'Ujedinjeno Kraljevstvo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzija',
 			'GF' => 'Francuska Gvajana',
 			'GG' => 'Gernzi',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grenland',
 			'GM' => 'Gambija',
 			'GN' => 'Gvineja',
 			'GP' => 'Gvadelup',
 			'GQ' => 'Ekvatorijalna Gvineja',
 			'GR' => 'Grčka',
 			'GS' => 'Južna Džordžija i Južna Sendvička Ostrva',
 			'GT' => 'Gvatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gvineja-Bisao',
 			'GY' => 'Gvajana',
 			'HK' => 'SAR Hongkong (Kina)',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Ostrvo Herd i Mekdonaldova ostrva',
 			'HN' => 'Honduras',
 			'HR' => 'Hrvatska',
 			'HT' => 'Haiti',
 			'HU' => 'Mađarska',
 			'IC' => 'Kanarska Ostrva',
 			'ID' => 'Indonezija',
 			'IE' => 'Irska',
 			'IL' => 'Izrael',
 			'IM' => 'Ostrvo Man',
 			'IN' => 'Indija',
 			'IO' => 'Britanska teritorija Indijskog okeana',
 			'IO@alt=chagos' => 'arhipelag Čagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italija',
 			'JE' => 'Džerzi',
 			'JM' => 'Jamajka',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenija',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorska Ostrva',
 			'KN' => 'Sent Kits i Nevis',
 			'KP' => 'Severna Koreja',
 			'KR' => 'Južna Koreja',
 			'KW' => 'Kuvajt',
 			'KY' => 'Kajmanska Ostrva',
 			'KZ' => 'Kazahstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Sveta Lucija',
 			'LI' => 'Lihtenštajn',
 			'LK' => 'Šri Lanka',
 			'LR' => 'Liberija',
 			'LS' => 'Lesoto',
 			'LT' => 'Litvanija',
 			'LU' => 'Luksemburg',
 			'LV' => 'Letonija',
 			'LY' => 'Libija',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavija',
 			'ME' => 'Crna Gora',
 			'MF' => 'Sveti Martin (Francuska)',
 			'MG' => 'Madagaskar',
 			'MH' => 'Maršalska Ostrva',
 			'MK' => 'Severna Makedonija',
 			'ML' => 'Mali',
 			'MM' => 'Mijanmar (Burma)',
 			'MN' => 'Mongolija',
 			'MO' => 'SAR Makao (Kina)',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Severna Marijanska Ostrva',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritanija',
 			'MS' => 'Monserat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricijus',
 			'MV' => 'Maldivi',
 			'MW' => 'Malavi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malezija',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibija',
 			'NC' => 'Nova Kaledonija',
 			'NE' => 'Niger',
 			'NF' => 'Ostrvo Norfok',
 			'NG' => 'Nigerija',
 			'NI' => 'Nikaragva',
 			'NL' => 'Holandija',
 			'NO' => 'Norveška',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Novi Zeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francuska Polinezija',
 			'PG' => 'Papua Nova Gvineja',
 			'PH' => 'Filipini',
 			'PK' => 'Pakistan',
 			'PL' => 'Poljska',
 			'PM' => 'Sen Pjer i Mikelon',
 			'PN' => 'Pitkern',
 			'PR' => 'Portoriko',
 			'PS' => 'Palestinske teritorije',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalija',
 			'PW' => 'Palau',
 			'PY' => 'Paragvaj',
 			'QA' => 'Katar',
 			'QO' => 'Okeanija (udaljena ostrva)',
 			'RE' => 'Reinion',
 			'RO' => 'Rumunija',
 			'RS' => 'Srbija',
 			'RU' => 'Rusija',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudijska Arabija',
 			'SB' => 'Solomonska Ostrva',
 			'SC' => 'Sejšeli',
 			'SD' => 'Sudan',
 			'SE' => 'Švedska',
 			'SG' => 'Singapur',
 			'SH' => 'Sveta Jelena',
 			'SI' => 'Slovenija',
 			'SJ' => 'Svalbard i Jan Majen',
 			'SK' => 'Slovačka',
 			'SL' => 'Sijera Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinam',
 			'SS' => 'Južni Sudan',
 			'ST' => 'Sao Tome i Principe',
 			'SV' => 'Salvador',
 			'SX' => 'Sveti Martin (Holandija)',
 			'SY' => 'Sirija',
 			'SZ' => 'Svazilend',
 			'TA' => 'Tristan da Kunja',
 			'TC' => 'Ostrva Turks i Kaikos',
 			'TD' => 'Čad',
 			'TF' => 'Francuske Južne Teritorije',
 			'TG' => 'Togo',
 			'TH' => 'Tajland',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste (Istočni Timor)',
 			'TL@alt=variant' => 'Istočni Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunis',
 			'TO' => 'Tonga',
 			'TR' => 'Turska',
 			'TT' => 'Trinidad i Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tajvan',
 			'TZ' => 'Tanzanija',
 			'UA' => 'Ukrajina',
 			'UG' => 'Uganda',
 			'UM' => 'Udaljena ostrva SAD',
 			'UN' => 'Ujedinjene nacije',
 			'UN@alt=short' => 'UN',
 			'US' => 'Sjedinjene Države',
 			'US@alt=short' => 'SAD',
 			'UY' => 'Urugvaj',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Sent Vinsent i Grenadini',
 			'VE' => 'Venecuela',
 			'VG' => 'Britanska Devičanska Ostrva',
 			'VI' => 'Američka Devičanska Ostrva',
 			'VN' => 'Vijetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Valis i Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudoakcenti',
 			'XB' => 'Pseudobidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Majot',
 			'ZA' => 'Južnoafrička Republika',
 			'ZM' => 'Zambija',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Nepoznat region',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Tradicionalna nemačka ortografija',
 			'1994' => 'Standardnizovana resijanska ortografija',
 			'1996' => 'Nemačka ortografija iz 1996',
 			'1606NICT' => 'Francuski iz kasnog srednjeg veka do 1606.',
 			'1694ACAD' => 'Rani moderni francuski',
 			'1959ACAD' => 'Akademski',
 			'AREVELA' => 'Istočni armenijski',
 			'AREVMDA' => 'Zapadno jermenska',
 			'BAKU1926' => 'Ujedinjen turski latinični alfabet',
 			'BISKE' => 'San Đorđio/Bila dijalekt',
 			'BOONT' => 'Buntling',
 			'FONIPA' => 'IPA fonetika',
 			'FONUPA' => 'UPA fonetika',
 			'KKCOR' => 'Uobičajena ortografija',
 			'LIPAW' => 'Lipovički dijalekt resijanski',
 			'MONOTON' => 'Monotonik',
 			'NEDIS' => 'Natisone dijalekt',
 			'NJIVA' => 'Gnjiva/Njiva dijalkekt',
 			'OSOJS' => 'Oseako/Osojane dijalekt',
 			'POLYTON' => 'Politonik',
 			'POSIX' => 'Kompjuter',
 			'REVISED' => 'Revidirana ortografija',
 			'ROZAJ' => 'Resijan',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Škotski standardni Engleski',
 			'SCOUSE' => 'Skauz',
 			'SOLBA' => 'Stolvica/Solbica dijalekt',
 			'TARASK' => 'Taraskijevička ortografija',
 			'UCCOR' => 'Ujedinjena ortografija',
 			'UCRCOR' => 'Ujedinjena revidirana ortografija',
 			'VALENCIA' => 'Valencijska',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalendar',
 			'cf' => 'format valute',
 			'colalternate' => 'sortiranje uz ignorisanje simbola',
 			'colbackwards' => 'sortiranje prema obrnutim akcentima',
 			'colcasefirst' => 'ređanje prema malom/velikom slovu',
 			'colcaselevel' => 'sortiranje prema malom/velikom slovu',
 			'collation' => 'redosled sortiranja',
 			'colnormalization' => 'normalizovano sortiranje',
 			'colnumeric' => 'numeričko sortiranje',
 			'colstrength' => 'sortiranje prema jačini',
 			'currency' => 'valuta',
 			'hc' => 'prikazivanje vremena (12- ili 24-časovno)',
 			'lb' => 'stil preloma reda',
 			'ms' => 'sistem mernih jedinica',
 			'numbers' => 'brojevi',
 			'timezone' => 'Vremenska zona',
 			'va' => 'Varijanta lokaliteta',
 			'x' => 'Privatna upotreba',

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
 				'buddhist' => q{budistički kalendar},
 				'chinese' => q{kineski kalendar},
 				'coptic' => q{koptski kalendar},
 				'dangi' => q{dangi kalendar},
 				'ethiopic' => q{etiopski kalendar},
 				'ethiopic-amete-alem' => q{etiopski amet alem kalendar},
 				'gregorian' => q{gregorijanski kalendar},
 				'hebrew' => q{hebrejski kalendar},
 				'indian' => q{Indijski nacionalni kalendar},
 				'islamic' => q{islamski kalendar},
 				'islamic-civil' => q{islamski civilni kalendar},
 				'islamic-tbla' => q{islamski astronomski kalendar},
 				'islamic-umalqura' => q{islamski kalendar (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 kalendar},
 				'japanese' => q{japanski kalendar},
 				'persian' => q{persijski kalendar},
 				'roc' => q{kalendar Republike Kine},
 			},
 			'cf' => {
 				'account' => q{računovodstveni format valute},
 				'standard' => q{standardni format valute},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sortiraj simbole},
 				'shifted' => q{Sortiranje uz ignorisanje simbola},
 			},
 			'colbackwards' => {
 				'no' => q{Sortiraj akcente normalno},
 				'yes' => q{Sortiraj akcente obrnuto},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sortiraj prvo mala slova},
 				'no' => q{Sortiraj normalan redosled velikih i malih slova},
 				'upper' => q{Sortiraj prvo velika slova},
 			},
 			'colcaselevel' => {
 				'no' => q{Sortiraj bez obzira na velika i mala slova},
 				'yes' => q{Sortiraj mala i velika slova},
 			},
 			'collation' => {
 				'big5han' => q{tradicionalno kinesko sortiranje},
 				'compat' => q{prethodni redosled sortiranja, zbog kompatibilnosti},
 				'dictionary' => q{redosled sortiranja u rečniku},
 				'ducet' => q{podrazumevani Unicode redosled sortiranja},
 				'eor' => q{evropska pravila redosleda},
 				'gb2312han' => q{pojednostavljeno kinesko sortiranje},
 				'phonebook' => q{sortiranje kao telefonski imenik},
 				'phonetic' => q{fonetski redosled sortiranja},
 				'pinyin' => q{pinjin sortiranje},
 				'reformed' => q{reformisani redosled sortiranja},
 				'search' => q{pretraga opšte namene},
 				'searchjl' => q{Pretraga prema hangul početnom suglasniku},
 				'standard' => q{standardni redosled sortiranja},
 				'stroke' => q{sortiranje po broju poteza},
 				'traditional' => q{tradicionalno sortiranje},
 				'unihan' => q{redosled sortiranja radikalnih poteza},
 				'zhuyin' => q{žujin},
 			},
 			'colnormalization' => {
 				'no' => q{Sortiraj bez normalizacije},
 				'yes' => q{Sortiraj Unicode normalizovano},
 			},
 			'colnumeric' => {
 				'no' => q{Sortiraj cifre pojedinačno},
 				'yes' => q{Sortiraj cifre numerički},
 			},
 			'colstrength' => {
 				'identical' => q{Sortiraj sve},
 				'primary' => q{Sortiraj samo osnovna slova},
 				'quaternary' => q{Sortiraj akcente/mala i velika slova/širinu/kana simbole},
 				'secondary' => q{Sortiraj akcente},
 				'tertiary' => q{Sortiraj akcente/mala i velika slova/širinu},
 			},
 			'd0' => {
 				'fwidth' => q{puna širina},
 				'hwidth' => q{pola širine},
 				'npinyin' => q{Numerička},
 			},
 			'hc' => {
 				'h11' => q{12-časovni sistem (0-11)},
 				'h12' => q{12-časovni sistem (1-12)},
 				'h23' => q{24-časovni sistem (0-23)},
 				'h24' => q{24-časovni sistem (1-24)},
 			},
 			'lb' => {
 				'loose' => q{razmaknuti stil preloma reda},
 				'normal' => q{normalni stil preloma reda},
 				'strict' => q{strogi stil preloma reda},
 			},
 			'm0' => {
 				'bgn' => q{BGN (BGN)},
 				'ungegn' => q{UNGEGN (BGN)},
 			},
 			'ms' => {
 				'metric' => q{metrički},
 				'uksystem' => q{imperijalni},
 				'ussystem' => q{američki},
 			},
 			'numbers' => {
 				'arab' => q{arapsko-indijske cifre},
 				'arabext' => q{produžene arapsko-indijske cifre},
 				'armn' => q{jermenski brojevi},
 				'armnlow' => q{mali jermenski brojevi},
 				'beng' => q{bengalske cifre},
 				'cakm' => q{čakma cifre},
 				'deva' => q{devangari cifre},
 				'ethi' => q{etiopski brojevi},
 				'finance' => q{Finansijski brojevi},
 				'fullwide' => q{cifre pune širine},
 				'geor' => q{gruzijski brojevi},
 				'grek' => q{grčki brojevi},
 				'greklow' => q{mali grčki brojevi},
 				'gujr' => q{gudžaratske cifre},
 				'guru' => q{gurmuki cifre},
 				'hanidec' => q{kineski decimalni brojevi},
 				'hans' => q{pojednostavljeni kineski brojevi},
 				'hansfin' => q{pojednostavljeni kineski finansijski brojevi},
 				'hant' => q{tradicionalni kineski brojevi},
 				'hantfin' => q{tradicionalni kineski finansijski brojevi},
 				'hebr' => q{hebrejski brojevi},
 				'java' => q{javanske cifre},
 				'jpan' => q{japanski brojevi},
 				'jpanfin' => q{japanski finansijski brojevi},
 				'khmr' => q{kmerske cifre},
 				'knda' => q{kanada cifre},
 				'laoo' => q{laoške cifre},
 				'latn' => q{zapadne cifre},
 				'mlym' => q{malajalam cifre},
 				'mong' => q{mongolske cifre},
 				'mtei' => q{mitei majek cifre},
 				'mymr' => q{mijanmarske cifre},
 				'native' => q{lokalne cifre},
 				'olck' => q{ol čiki cifre},
 				'orya' => q{orija cifre},
 				'roman' => q{rimski brojevi},
 				'romanlow' => q{mali rimski brojevi},
 				'taml' => q{tamilski brojevi},
 				'tamldec' => q{tamilske cifre},
 				'telu' => q{telugu cifre},
 				'thai' => q{tajske cifre},
 				'tibt' => q{tibetanske cifre},
 				'traditional' => q{Tradicionalni brojevi},
 				'vaii' => q{vai cifre},
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
			'metric' => q{Metrički},
 			'UK' => q{UK},
 			'US' => q{SAD},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Jezik: {0}',
 			'script' => 'Pismo: {0}',
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
			auxiliary => qr{[å q w x y]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŽ}', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', '{LJ}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a b c č ć d {dž} đ e f g h i j k l {lj} m n {nj} o p r s š t u v z ž]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … ‘‚ “„ ( ) \[ \] \{ \} * #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', '{DŽ}', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', '{LJ}', 'M', 'N', '{NJ}', 'O', 'P', 'Q', 'R', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h.mm',
				hms => 'h.mm.ss',
				ms => 'm.ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(glavni pravac),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(glavni pravac),
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
						'1' => q(rona{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(rona{0}),
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
						'1' => q(feminine),
						'few' => q({0} ge sila),
						'one' => q({0} ge sila),
						'other' => q({0} ge sila),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'few' => q({0} ge sila),
						'one' => q({0} ge sila),
						'other' => q({0} ge sila),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(inanimate),
						'few' => q({0} metra u sekundi na kvadrat),
						'name' => q(metri u sekundi na kvadrat),
						'one' => q({0} metar u sekundi na kvadrat),
						'other' => q({0} metara u sekundi na kvadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(inanimate),
						'few' => q({0} metra u sekundi na kvadrat),
						'name' => q(metri u sekundi na kvadrat),
						'one' => q({0} metar u sekundi na kvadrat),
						'other' => q({0} metara u sekundi na kvadrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(inanimate),
						'few' => q({0} lučna minuta),
						'name' => q(lučni minuti),
						'one' => q({0} lučni minut),
						'other' => q({0} lučnih minuta),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(inanimate),
						'few' => q({0} lučna minuta),
						'name' => q(lučni minuti),
						'one' => q({0} lučni minut),
						'other' => q({0} lučnih minuta),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'few' => q({0} lučne sekunde),
						'name' => q(lučne sekunde),
						'one' => q({0} lučna sekunda),
						'other' => q({0} lučnih sekundi),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'few' => q({0} lučne sekunde),
						'name' => q(lučne sekunde),
						'one' => q({0} lučna sekunda),
						'other' => q({0} lučnih sekundi),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(inanimate),
						'few' => q({0} stepena),
						'one' => q({0} stepen),
						'other' => q({0} stepeni),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(inanimate),
						'few' => q({0} stepena),
						'one' => q({0} stepen),
						'other' => q({0} stepeni),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(inanimate),
						'few' => q({0} radijana),
						'name' => q(radijani),
						'one' => q({0} radijan),
						'other' => q({0} radijana),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(inanimate),
						'few' => q({0} radijana),
						'name' => q(radijani),
						'one' => q({0} radijan),
						'other' => q({0} radijana),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(inanimate),
						'few' => q({0} obrtaja),
						'name' => q(obrtaj),
						'one' => q({0} obrtaj),
						'other' => q({0} obrtaja),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(inanimate),
						'few' => q({0} obrtaja),
						'name' => q(obrtaj),
						'one' => q({0} obrtaj),
						'other' => q({0} obrtaja),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} akera),
						'one' => q({0} aker),
						'other' => q({0} akera),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} akera),
						'one' => q({0} aker),
						'other' => q({0} akera),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(inanimate),
						'few' => q({0} hektara),
						'one' => q({0} hektar),
						'other' => q({0} hektara),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(inanimate),
						'few' => q({0} hektara),
						'one' => q({0} hektar),
						'other' => q({0} hektara),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} kvadratna centimetra),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimetar),
						'other' => q({0} kvadratnih centimetara),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} kvadratna centimetra),
						'name' => q(kvadratni centimetri),
						'one' => q({0} kvadratni centimetar),
						'other' => q({0} kvadratnih centimetara),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} kvadratne stope),
						'one' => q({0} kvadratna stopa),
						'other' => q({0} kvadratnih stopa),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} kvadratne stope),
						'one' => q({0} kvadratna stopa),
						'other' => q({0} kvadratnih stopa),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} kvadratna inča),
						'name' => q(kvadratni inči),
						'one' => q({0} kvadratni inč),
						'other' => q({0} kvadratnih inča),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} kvadratna inča),
						'name' => q(kvadratni inči),
						'one' => q({0} kvadratni inč),
						'other' => q({0} kvadratnih inča),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kvadratna kilometra),
						'one' => q({0} kvadratni kilometar),
						'other' => q({0} kvadratnih kilometara),
						'per' => q({0} po kvadratnom kilometru),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kvadratna kilometra),
						'one' => q({0} kvadratni kilometar),
						'other' => q({0} kvadratnih kilometara),
						'per' => q({0} po kvadratnom kilometru),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(inanimate),
						'few' => q({0} kvadratna metra),
						'one' => q({0} kvadratni metar),
						'other' => q({0} kvadratnih metara),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(inanimate),
						'few' => q({0} kvadratna metra),
						'one' => q({0} kvadratni metar),
						'other' => q({0} kvadratnih metara),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratne milje),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milja),
						'per' => q({0} po kvadratnoj milji),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} kvadratne milje),
						'name' => q(kvadratne milje),
						'one' => q({0} kvadratna milja),
						'other' => q({0} kvadratnih milja),
						'per' => q({0} po kvadratnoj milji),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} kvadratna jarda),
						'name' => q(kvadratni jardi),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jardi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} kvadratna jarda),
						'name' => q(kvadratni jardi),
						'one' => q({0} kvadratni jard),
						'other' => q({0} kvadratnih jardi),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(feminine),
						'name' => q(stavke),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(feminine),
						'name' => q(stavke),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(inanimate),
						'few' => q({0} karata),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(inanimate),
						'few' => q({0} karata),
						'name' => q(karati),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligrama po decilitru),
						'name' => q(miligrami po decilitru),
						'one' => q({0} miligram po decilitru),
						'other' => q({0} miligrama po decilitru),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligrama po decilitru),
						'name' => q(miligrami po decilitru),
						'one' => q({0} miligram po decilitru),
						'other' => q({0} miligrama po decilitru),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(inanimate),
						'few' => q({0} milimola po litri),
						'name' => q(milimol po litri),
						'one' => q({0} milimol po litri),
						'other' => q({0} milimola po litri),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(inanimate),
						'few' => q({0} milimola po litri),
						'name' => q(milimol po litri),
						'one' => q({0} milimol po litri),
						'other' => q({0} milimola po litri),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(inanimate),
						'few' => q({0} mola),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} mola),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(inanimate),
						'few' => q({0} mola),
						'name' => q(moli),
						'one' => q({0} mol),
						'other' => q({0} mola),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(inanimate),
						'few' => q({0} procenata),
						'one' => q({0} procenat),
						'other' => q({0} procenata),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(inanimate),
						'few' => q({0} procenata),
						'one' => q({0} procenat),
						'other' => q({0} procenata),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(inanimate),
						'few' => q({0} promila),
						'one' => q({0} promil),
						'other' => q({0} promila),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(inanimate),
						'few' => q({0} promila),
						'one' => q({0} promil),
						'other' => q({0} promila),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'few' => q({0} čestice na milion),
						'name' => q(čestica na milion),
						'one' => q({0} čestica na milion),
						'other' => q({0} čestica na milion),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'few' => q({0} čestice na milion),
						'name' => q(čestica na milion),
						'one' => q({0} čestica na milion),
						'other' => q({0} čestica na milion),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(inanimate),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(inanimate),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litra na 100 kilometara),
						'name' => q(litri na 100 kilometara),
						'one' => q({0} litar na 100 kilometara),
						'other' => q({0} litara na 100 kilometara),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litra na 100 kilometara),
						'name' => q(litri na 100 kilometara),
						'one' => q({0} litar na 100 kilometara),
						'other' => q({0} litara na 100 kilometara),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litra po kilometru),
						'name' => q(litri po kilometru),
						'one' => q({0} litar po kilometru),
						'other' => q({0} litara po kilometru),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litra po kilometru),
						'name' => q(litri po kilometru),
						'one' => q({0} litar po kilometru),
						'other' => q({0} litara po kilometru),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} milje po galonu),
						'name' => q(milja po galonu),
						'one' => q({0} milja po galonu),
						'other' => q({0} milja po galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} milje po galonu),
						'name' => q(milja po galonu),
						'one' => q({0} milja po galonu),
						'other' => q({0} milja po galonu),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} milje po imperijalnom galonu),
						'name' => q(milja po imperijalnom galonu),
						'one' => q({0} milja po imperijalnom galonu),
						'other' => q({0} milja po imperijalnom galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} milje po imperijalnom galonu),
						'name' => q(milja po imperijalnom galonu),
						'one' => q({0} milja po imperijalnom galonu),
						'other' => q({0} milja po imperijalnom galonu),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(inanimate),
						'few' => q({0} bita),
						'name' => q(bitovi),
						'one' => q({0} bit),
						'other' => q({0} bitova),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(inanimate),
						'few' => q({0} bita),
						'name' => q(bitovi),
						'one' => q({0} bit),
						'other' => q({0} bitova),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(inanimate),
						'few' => q({0} bajta),
						'name' => q(bajtovi),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(inanimate),
						'few' => q({0} bajta),
						'name' => q(bajtovi),
						'one' => q({0} bajt),
						'other' => q({0} bajtova),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(inanimate),
						'few' => q({0} gigabita),
						'name' => q(gigabitovi),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitova),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(inanimate),
						'few' => q({0} gigabita),
						'name' => q(gigabitovi),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitova),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(inanimate),
						'few' => q({0} gigabajta),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtova),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(inanimate),
						'few' => q({0} gigabajta),
						'name' => q(gigabajti),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtova),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(inanimate),
						'few' => q({0} kilobita),
						'name' => q(kilobitovi),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitova),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(inanimate),
						'few' => q({0} kilobita),
						'name' => q(kilobitovi),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitova),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(inanimate),
						'few' => q({0} kilobajta),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtova),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(inanimate),
						'few' => q({0} kilobajta),
						'name' => q(kilobajti),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtova),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(inanimate),
						'few' => q({0} megabita),
						'name' => q(megabitovi),
						'one' => q({0} megabit),
						'other' => q({0} megabitova),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(inanimate),
						'few' => q({0} megabita),
						'name' => q(megabitovi),
						'one' => q({0} megabit),
						'other' => q({0} megabitova),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(inanimate),
						'few' => q({0} megabajta),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtova),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(inanimate),
						'few' => q({0} megabajta),
						'name' => q(megabajti),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtova),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(inanimate),
						'few' => q({0} petabajta),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtova),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(inanimate),
						'few' => q({0} petabajta),
						'name' => q(petabajti),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtova),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(inanimate),
						'few' => q({0} terabita),
						'name' => q(terabitovi),
						'one' => q({0} terabit),
						'other' => q({0} terabitova),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(inanimate),
						'few' => q({0} terabita),
						'name' => q(terabitovi),
						'one' => q({0} terabit),
						'other' => q({0} terabitova),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(inanimate),
						'few' => q({0} terabajta),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajta),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(inanimate),
						'few' => q({0} terabajta),
						'name' => q(terabajti),
						'one' => q({0} terabajt),
						'other' => q({0} terabajta),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(inanimate),
						'few' => q({0} veka),
						'name' => q(vekovi),
						'one' => q({0} vek),
						'other' => q({0} vekova),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(inanimate),
						'few' => q({0} veka),
						'name' => q(vekovi),
						'one' => q({0} vek),
						'other' => q({0} vekova),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(inanimate),
						'name' => q(dani),
						'per' => q({0}/dnevno),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(inanimate),
						'name' => q(dani),
						'per' => q({0}/dnevno),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(feminine),
						'few' => q({0} decenije),
						'name' => q(decenije),
						'one' => q({0} decenija),
						'other' => q({0} decenija),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'few' => q({0} decenije),
						'name' => q(decenije),
						'one' => q({0} decenija),
						'other' => q({0} decenija),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(inanimate),
						'per' => q({0}/sat),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(inanimate),
						'per' => q({0}/sat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekunde),
						'name' => q(mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekunde),
						'name' => q(mikrosekunde),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekunde),
						'name' => q(milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekunde),
						'name' => q(milisekunde),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(inanimate),
						'few' => q({0} minuta),
						'name' => q(minuti),
						'one' => q({0} minut),
						'other' => q({0} minuta),
						'per' => q({0} u minutu),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(inanimate),
						'few' => q({0} minuta),
						'name' => q(minuti),
						'one' => q({0} minut),
						'other' => q({0} minuta),
						'per' => q({0} u minutu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(inanimate),
						'few' => q({0} meseca),
						'one' => q({0} mesec),
						'other' => q({0} meseci),
						'per' => q({0} mesečno),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(inanimate),
						'few' => q({0} meseca),
						'one' => q({0} mesec),
						'other' => q({0} meseci),
						'per' => q({0} mesečno),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekunde),
						'name' => q(nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekunde),
						'name' => q(nanosekunde),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundi),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(inanimate),
						'few' => q({0} kvartala),
						'name' => q(kvartali),
						'one' => q({0} kvartal),
						'other' => q({0} kvartala),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(inanimate),
						'few' => q({0} kvartala),
						'name' => q(kvartali),
						'one' => q({0} kvartal),
						'other' => q({0} kvartala),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
						'per' => q({0}/u sekundi),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'few' => q({0} sekunde),
						'name' => q(sekunde),
						'one' => q({0} sekunda),
						'other' => q({0} sekundi),
						'per' => q({0}/u sekundi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'few' => q({0} nedelje),
						'name' => q(nedelje),
						'one' => q({0} nedelja),
						'other' => q({0} nedelja),
						'per' => q({0} nedeljno),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'few' => q({0} nedelje),
						'name' => q(nedelje),
						'one' => q({0} nedelja),
						'other' => q({0} nedelja),
						'per' => q({0} nedeljno),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(feminine),
						'few' => q({0} godine),
						'name' => q(godine),
						'one' => q({0} godina),
						'other' => q({0} godina),
						'per' => q({0} godišnje),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(feminine),
						'few' => q({0} godine),
						'name' => q(godine),
						'one' => q({0} godina),
						'other' => q({0} godina),
						'per' => q({0} godišnje),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(inanimate),
						'few' => q({0} ampera),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} ampera),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(inanimate),
						'few' => q({0} ampera),
						'name' => q(amperi),
						'one' => q({0} amper),
						'other' => q({0} ampera),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(inanimate),
						'few' => q({0} miliampera),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(inanimate),
						'few' => q({0} miliampera),
						'name' => q(miliamperi),
						'one' => q({0} miliamper),
						'other' => q({0} miliampera),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(inanimate),
						'few' => q({0} oma),
						'name' => q(omi),
						'one' => q({0} om),
						'other' => q({0} oma),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(inanimate),
						'few' => q({0} oma),
						'name' => q(omi),
						'one' => q({0} om),
						'other' => q({0} oma),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(inanimate),
						'few' => q({0} volta),
						'name' => q(volti),
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(inanimate),
						'few' => q({0} volta),
						'name' => q(volti),
						'one' => q({0} volt),
						'other' => q({0} volti),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Britanska termalna jedinica),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Britanska termalna jedinica),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektronvolta),
						'name' => q(elektronvolti),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolti),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektronvolta),
						'name' => q(elektronvolti),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolti),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kalorije),
						'name' => q(Kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kalorije),
						'name' => q(Kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorija),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(inanimate),
						'few' => q({0} džula),
						'name' => q(džuli),
						'one' => q({0} džul),
						'other' => q({0} džula),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(inanimate),
						'few' => q({0} džula),
						'name' => q(džuli),
						'one' => q({0} džul),
						'other' => q({0} džula),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorija),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorija),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(inanimate),
						'few' => q({0} kilodžula),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(inanimate),
						'few' => q({0} kilodžula),
						'name' => q(kilodžuli),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžula),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilovat-sata),
						'name' => q(kilovat-sati),
						'one' => q({0} kilovat-sat),
						'other' => q({0} kilovat-sati),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilovat-sata),
						'name' => q(kilovat-sati),
						'one' => q({0} kilovat-sat),
						'other' => q({0} kilovat-sati),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(US therms),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(inanimate),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(inanimate),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(inanimate),
						'few' => q({0} njutna),
						'name' => q(njutni),
						'one' => q({0} njutn),
						'other' => q({0} njutna),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(inanimate),
						'few' => q({0} njutna),
						'name' => q(njutni),
						'one' => q({0} njutn),
						'other' => q({0} njutna),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} funte sile),
						'name' => q(funti sile),
						'one' => q({0} funta sile),
						'other' => q({0} funti sile),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} funte sile),
						'name' => q(funti sile),
						'one' => q({0} funta sile),
						'other' => q({0} funti sile),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(inanimate),
						'few' => q({0} gigaherca),
						'name' => q(gigaherci),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherca),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(inanimate),
						'few' => q({0} gigaherca),
						'name' => q(gigaherci),
						'one' => q({0} gigaherc),
						'other' => q({0} gigaherca),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(inanimate),
						'few' => q({0} herca),
						'name' => q(herci),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(inanimate),
						'few' => q({0} herca),
						'name' => q(herci),
						'one' => q({0} herc),
						'other' => q({0} herca),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(inanimate),
						'few' => q({0} kiloherca),
						'name' => q(kiloherci),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherca),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(inanimate),
						'few' => q({0} kiloherca),
						'name' => q(kiloherci),
						'one' => q({0} kiloherc),
						'other' => q({0} kiloherca),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(inanimate),
						'few' => q({0} megaherca),
						'name' => q(megaherci),
						'one' => q({0} megaherc),
						'other' => q({0} megaherca),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(inanimate),
						'few' => q({0} megaherca),
						'name' => q(megaherci),
						'one' => q({0} megaherc),
						'other' => q({0} megaherca),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(tačke),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(tačke),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(tačke po centimetru),
						'one' => q({0} tačka po centimetru),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(tačke po centimetru),
						'one' => q({0} tačka po centimetru),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(tačke po inču),
						'one' => q({0} tačka po inču),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(tačke po inču),
						'one' => q({0} tačka po inču),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(inanimate),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(inanimate),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(inanimate),
						'few' => q({0} megapiksela),
						'name' => q(megapikseli),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksela),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(inanimate),
						'few' => q({0} megapiksela),
						'name' => q(megapikseli),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksela),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(inanimate),
						'few' => q({0} piksela),
						'name' => q(pikseli),
						'one' => q({0} piksel),
						'other' => q({0} piksela),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(inanimate),
						'few' => q({0} piksela),
						'name' => q(pikseli),
						'one' => q({0} piksel),
						'other' => q({0} piksela),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} piksela na centimetar),
						'name' => q(pikseli po centimetru),
						'one' => q({0} piksel na centimetar),
						'other' => q({0} piksela na centimetar),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} piksela na centimetar),
						'name' => q(pikseli po centimetru),
						'one' => q({0} piksel na centimetar),
						'other' => q({0} piksela na centimetar),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} piksela po inču),
						'name' => q(pikseli po inču),
						'one' => q({0} piksel po inču),
						'other' => q({0} piksela po inču),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} piksela po inču),
						'name' => q(pikseli po inču),
						'one' => q({0} piksel po inču),
						'other' => q({0} piksela po inču),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomske jedinice),
						'name' => q(astronomske jedinice),
						'one' => q({0} astronomska jedinica),
						'other' => q({0} astronomskih jedinica),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomske jedinice),
						'name' => q(astronomske jedinice),
						'one' => q({0} astronomska jedinica),
						'other' => q({0} astronomskih jedinica),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetra),
						'name' => q(centimetri),
						'one' => q({0} centimetar),
						'other' => q({0} centimetara),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetra),
						'name' => q(centimetri),
						'one' => q({0} centimetar),
						'other' => q({0} centimetara),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(inanimate),
						'few' => q({0} decimetra),
						'name' => q(decimetri),
						'one' => q({0} decimetar),
						'other' => q({0} decimetara),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(inanimate),
						'few' => q({0} decimetra),
						'name' => q(decimetri),
						'one' => q({0} decimetar),
						'other' => q({0} decimetara),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} poluprečnik Zemlje),
						'name' => q(poluprečnik Zemlje),
						'one' => q({0} poluprečnik Zemlje),
						'other' => q({0} poluprečnika Zemlje),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} poluprečnik Zemlje),
						'name' => q(poluprečnik Zemlje),
						'one' => q({0} poluprečnik Zemlje),
						'other' => q({0} poluprečnika Zemlje),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} hvata),
						'name' => q(hvati),
						'one' => q({0} hvat),
						'other' => q({0} hvati),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} hvata),
						'name' => q(hvati),
						'one' => q({0} hvat),
						'other' => q({0} hvati),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} stope),
						'name' => q(stope),
						'one' => q({0} stopa),
						'other' => q({0} stopa),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} stope),
						'name' => q(stope),
						'one' => q({0} stopa),
						'other' => q({0} stopa),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlonga),
						'one' => q({0} furlong),
						'other' => q({0} furlonga),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlonga),
						'one' => q({0} furlong),
						'other' => q({0} furlonga),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometra),
						'name' => q(kilometri),
						'one' => q({0} kilometar),
						'other' => q({0} kilometara),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometra),
						'name' => q(kilometri),
						'one' => q({0} kilometar),
						'other' => q({0} kilometara),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} svetlosne godine),
						'name' => q(svetlosne godine),
						'one' => q({0} svetlosna godina),
						'other' => q({0} svetlosnih godina),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} svetlosne godine),
						'name' => q(svetlosne godine),
						'one' => q({0} svetlosna godina),
						'other' => q({0} svetlosnih godina),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metra),
						'name' => q(metri),
						'one' => q({0} metar),
						'other' => q({0} metara),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(inanimate),
						'few' => q({0} metra),
						'name' => q(metri),
						'one' => q({0} metar),
						'other' => q({0} metara),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(inanimate),
						'few' => q({0} mikrometra),
						'name' => q(mikrometri),
						'one' => q({0} mikrometar),
						'other' => q({0} mikrometara),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(inanimate),
						'few' => q({0} mikrometra),
						'name' => q(mikrometri),
						'one' => q({0} mikrometar),
						'other' => q({0} mikrometara),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavska milja),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milja),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} skandinavske milje),
						'name' => q(skandinavska milja),
						'one' => q({0} skandinavska milja),
						'other' => q({0} skandinavskih milja),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(inanimate),
						'few' => q({0} milimetra),
						'name' => q(milimetri),
						'one' => q({0} milimetar),
						'other' => q({0} milimetara),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(inanimate),
						'few' => q({0} milimetra),
						'name' => q(milimetri),
						'one' => q({0} milimetar),
						'other' => q({0} milimetara),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(inanimate),
						'few' => q({0} nanometra),
						'name' => q(nanometri),
						'one' => q({0} nanometar),
						'other' => q({0} nanometara),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(inanimate),
						'few' => q({0} nanometra),
						'name' => q(nanometri),
						'one' => q({0} nanometar),
						'other' => q({0} nanometara),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} nautičke milje),
						'name' => q(nautičke milje),
						'one' => q({0} nautička milja),
						'other' => q({0} nautičkih milja),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} nautičke milje),
						'name' => q(nautičke milje),
						'one' => q({0} nautička milja),
						'other' => q({0} nautičkih milja),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parseka),
						'one' => q({0} parsek),
						'other' => q({0} parseka),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parseka),
						'one' => q({0} parsek),
						'other' => q({0} parseka),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(inanimate),
						'few' => q({0} pikometra),
						'one' => q({0} pikometar),
						'other' => q({0} pikometara),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(inanimate),
						'few' => q({0} pikometra),
						'one' => q({0} pikometar),
						'other' => q({0} pikometara),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} sunčeva poluprečnika),
						'name' => q(sunčevi poluprečnici),
						'one' => q({0} sunčev poluprečnik),
						'other' => q({0} sunčevih poluprečnika),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} sunčeva poluprečnika),
						'name' => q(sunčevi poluprečnici),
						'one' => q({0} sunčev poluprečnik),
						'other' => q({0} sunčevih poluprečnika),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} jarda),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} jarda),
						'one' => q({0} jard),
						'other' => q({0} jardi),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'few' => q({0} kandele),
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'few' => q({0} kandele),
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(inanimate),
						'few' => q({0} lumena),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumena),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(inanimate),
						'few' => q({0} lumena),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumena),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(inanimate),
						'few' => q({0} luksa),
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksa),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(inanimate),
						'few' => q({0} luksa),
						'name' => q(luks),
						'one' => q({0} luks),
						'other' => q({0} luksa),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(inanimate),
						'few' => q({0} karata),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(inanimate),
						'few' => q({0} karata),
						'one' => q({0} karat),
						'other' => q({0} karata),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltona),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} daltona),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltona),
						'name' => q(daltoni),
						'one' => q({0} dalton),
						'other' => q({0} daltona),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} mase zemlje),
						'name' => q(mase zemlje),
						'one' => q({0} masa zemlje),
						'other' => q({0} masa zemlje),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} mase zemlje),
						'name' => q(mase zemlje),
						'one' => q({0} masa zemlje),
						'other' => q({0} masa zemlje),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grejna),
						'one' => q({0} grejn),
						'other' => q({0} grejna),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grejna),
						'one' => q({0} grejn),
						'other' => q({0} grejna),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(inanimate),
						'few' => q({0} grama),
						'one' => q({0} gram),
						'other' => q({0} grama),
						'per' => q({0} po gramu),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(inanimate),
						'few' => q({0} grama),
						'one' => q({0} gram),
						'other' => q({0} grama),
						'per' => q({0} po gramu),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(inanimate),
						'few' => q({0} kilograma),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilograma),
						'per' => q({0} po kilogramu),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(inanimate),
						'few' => q({0} kilograma),
						'name' => q(kilogrami),
						'one' => q({0} kilogram),
						'other' => q({0} kilograma),
						'per' => q({0} po kilogramu),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(inanimate),
						'few' => q({0} mikrograma),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrograma),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(inanimate),
						'few' => q({0} mikrograma),
						'name' => q(mikrogrami),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrograma),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(inanimate),
						'few' => q({0} miligrama),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligrama),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(inanimate),
						'few' => q({0} miligrama),
						'name' => q(miligrami),
						'one' => q({0} miligram),
						'other' => q({0} miligrama),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
						'per' => q({0} po unci),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
						'per' => q({0} po unci),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} fine unce),
						'name' => q(fine unce),
						'one' => q({0} fina unca),
						'other' => q({0} finih unci),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} fine unce),
						'name' => q(fine unce),
						'one' => q({0} fina unca),
						'other' => q({0} finih unci),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} funte),
						'name' => q(funte),
						'one' => q({0} funta),
						'other' => q({0} funti),
						'per' => q({0} po funti),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} funte),
						'name' => q(funte),
						'one' => q({0} funta),
						'other' => q({0} funti),
						'per' => q({0} po funti),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} mase sunca),
						'name' => q(mase sunca),
						'one' => q({0} masa sunca),
						'other' => q({0} masa sunca),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} mase sunca),
						'name' => q(mase sunca),
						'one' => q({0} masa sunca),
						'other' => q({0} masa sunca),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} američke tone),
						'name' => q(američke tone),
						'one' => q({0} američka tona),
						'other' => q({0} američkih tona),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} američke tone),
						'name' => q(američke tone),
						'one' => q({0} američka tona),
						'other' => q({0} američkih tona),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} tone),
						'name' => q(tone),
						'one' => q({0} tona),
						'other' => q({0} tona),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} tone),
						'name' => q(tone),
						'one' => q({0} tona),
						'other' => q({0} tona),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'few' => q({0} metričke tone),
						'name' => q(metričke tone),
						'one' => q({0} metrička tona),
						'other' => q({0} metričkih tona),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'few' => q({0} metričke tone),
						'name' => q(metričke tone),
						'one' => q({0} metrička tona),
						'other' => q({0} metričkih tona),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(inanimate),
						'few' => q({0} gigavata),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavati),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(inanimate),
						'few' => q({0} gigavata),
						'name' => q(gigavati),
						'one' => q({0} gigavat),
						'other' => q({0} gigavati),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} konjske snage),
						'name' => q(konjske snage),
						'one' => q({0} konjska snaga),
						'other' => q({0} konjskih snaga),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} konjske snage),
						'name' => q(konjske snage),
						'one' => q({0} konjska snaga),
						'other' => q({0} konjskih snaga),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(inanimate),
						'few' => q({0} kilovata),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovati),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(inanimate),
						'few' => q({0} kilovata),
						'name' => q(kilovati),
						'one' => q({0} kilovat),
						'other' => q({0} kilovati),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(inanimate),
						'few' => q({0} megavata),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavati),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(inanimate),
						'few' => q({0} megavata),
						'name' => q(megavati),
						'one' => q({0} megavat),
						'other' => q({0} megavati),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(inanimate),
						'few' => q({0} milivata),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivati),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(inanimate),
						'few' => q({0} milivata),
						'name' => q(milivati),
						'one' => q({0} milivat),
						'other' => q({0} milivati),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(inanimate),
						'few' => q({0} vata),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vati),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(inanimate),
						'few' => q({0} vata),
						'name' => q(vati),
						'one' => q({0} vat),
						'other' => q({0} vati),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(kvadratni {0}),
						'few' => q(kvadratna {0}),
						'one' => q(kvadratni {0}),
						'other' => q(kvadratnih {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(kvadratni {0}),
						'few' => q(kvadratna {0}),
						'one' => q(kvadratni {0}),
						'other' => q(kvadratnih {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kubni {0}),
						'few' => q(kubna {0}),
						'one' => q(kubni {0}),
						'other' => q(kubnih {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kubni {0}),
						'few' => q(kubna {0}),
						'one' => q(kubni {0}),
						'other' => q(kubnih {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosfere),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(inanimate),
						'few' => q({0} bara),
						'name' => q(bari),
						'one' => q({0} bar),
						'other' => q({0} bara),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(inanimate),
						'few' => q({0} bara),
						'name' => q(bari),
						'one' => q({0} bar),
						'other' => q({0} bara),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(inanimate),
						'few' => q({0} hektopaskala),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskala),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(inanimate),
						'few' => q({0} hektopaskala),
						'name' => q(hektopaskali),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskala),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inča živinog stuba),
						'name' => q(inči živinog stuba),
						'one' => q({0} inč živinog stuba),
						'other' => q({0} inča živinog stuba),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inča živinog stuba),
						'name' => q(inči živinog stuba),
						'one' => q({0} inč živinog stuba),
						'other' => q({0} inča živinog stuba),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(inanimate),
						'few' => q({0} kilopaskala),
						'name' => q(kilopaskali),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskala),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(inanimate),
						'few' => q({0} kilopaskala),
						'name' => q(kilopaskali),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskala),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(inanimate),
						'few' => q({0} megapaskala),
						'name' => q(megapaskali),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskala),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(inanimate),
						'few' => q({0} megapaskala),
						'name' => q(megapaskali),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskala),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(inanimate),
						'few' => q({0} milibara),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(inanimate),
						'few' => q({0} milibara),
						'name' => q(milibari),
						'one' => q({0} milibar),
						'other' => q({0} milibara),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetra živinog stuba),
						'name' => q(milimetri živinog stuba),
						'one' => q({0} milimetar živinog stuba),
						'other' => q({0} milimetara živinog stuba),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetra živinog stuba),
						'name' => q(milimetri živinog stuba),
						'one' => q({0} milimetar živinog stuba),
						'other' => q({0} milimetara živinog stuba),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(inanimate),
						'few' => q({0} paskala),
						'name' => q(paskali),
						'one' => q({0} paskal),
						'other' => q({0} paskala),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(inanimate),
						'few' => q({0} paskala),
						'name' => q(paskali),
						'one' => q({0} paskal),
						'other' => q({0} paskala),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} funte po kvadratnom inču),
						'name' => q(funte po kvadratnom inču),
						'one' => q({0} funta po kvadratnom inču),
						'other' => q({0} funti po kvadratnom inču),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} funte po kvadratnom inču),
						'name' => q(funte po kvadratnom inču),
						'one' => q({0} funta po kvadratnom inču),
						'other' => q({0} funti po kvadratnom inču),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bofor),
						'one' => q(Bofor {0}),
						'other' => q(Bofor {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bofor),
						'one' => q(Bofor {0}),
						'other' => q(Bofor {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilometra na sat),
						'name' => q(kilometri na sat),
						'one' => q({0} kilometar na sat),
						'other' => q({0} kilometara na sat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilometra na sat),
						'name' => q(kilometri na sat),
						'one' => q({0} kilometar na sat),
						'other' => q({0} kilometara na sat),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} čvora),
						'name' => q(čvor),
						'one' => q({0} čvor),
						'other' => q({0} čvorova),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} čvora),
						'name' => q(čvor),
						'one' => q({0} čvor),
						'other' => q({0} čvorova),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(inanimate),
						'few' => q({0} metra u sekundi),
						'one' => q({0} metar u sekundi),
						'other' => q({0} metara u sekundi),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(inanimate),
						'few' => q({0} metra u sekundi),
						'one' => q({0} metar u sekundi),
						'other' => q({0} metara u sekundi),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} milje na sat),
						'one' => q({0} milja na sat),
						'other' => q({0} milja na sat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} milje na sat),
						'one' => q({0} milja na sat),
						'other' => q({0} milja na sat),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(inanimate),
						'few' => q({0} stepena Celzijusa),
						'name' => q(stepeni Celzijusa),
						'one' => q({0} stepen Celzijusa),
						'other' => q({0} stepeni Celzijusa),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(inanimate),
						'few' => q({0} stepena Celzijusa),
						'name' => q(stepeni Celzijusa),
						'one' => q({0} stepen Celzijusa),
						'other' => q({0} stepeni Celzijusa),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stepena Farenhajta),
						'one' => q({0} stepen Farenhajta),
						'other' => q({0} stepeni Farenhajta),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stepena Farenhajta),
						'one' => q({0} stepen Farenhajta),
						'other' => q({0} stepeni Farenhajta),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(inanimate),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(inanimate),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(inanimate),
						'few' => q({0} kelvina),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvina),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(inanimate),
						'few' => q({0} kelvina),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvina),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(inanimate),
						'few' => q({0} njutn-metra),
						'name' => q(njutn-metri),
						'one' => q({0} njutn-metar),
						'other' => q({0} njutn-metara),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(inanimate),
						'few' => q({0} njutn-metra),
						'name' => q(njutn-metri),
						'one' => q({0} njutn-metar),
						'other' => q({0} njutn-metara),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} funte sile stope),
						'name' => q(funta-stope),
						'one' => q({0} funta sile stope),
						'other' => q({0} funti sile stope),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} funte sile stope),
						'name' => q(funta-stope),
						'one' => q({0} funta sile stope),
						'other' => q({0} funti sile stope),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} aker stope),
						'name' => q(aker stope),
						'one' => q({0} aker stopa),
						'other' => q({0} aker stopa),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} aker stope),
						'name' => q(aker stope),
						'one' => q({0} aker stopa),
						'other' => q({0} aker stopa),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barela),
						'name' => q(bareli),
						'one' => q({0} barel),
						'other' => q({0} barela),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barela),
						'name' => q(bareli),
						'one' => q({0} barel),
						'other' => q({0} barela),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušela),
						'name' => q(bušeli),
						'one' => q({0} bušel),
						'other' => q({0} bušela),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušela),
						'name' => q(bušeli),
						'one' => q({0} bušel),
						'other' => q({0} bušela),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(inanimate),
						'few' => q({0} centilitra),
						'name' => q(centilitri),
						'one' => q({0} centilitar),
						'other' => q({0} centilitara),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(inanimate),
						'few' => q({0} centilitra),
						'name' => q(centilitri),
						'one' => q({0} centilitar),
						'other' => q({0} centilitara),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} kubna centimetra),
						'name' => q(kubni centimetri),
						'one' => q({0} kubni centimetar),
						'other' => q({0} kubnih centimetara),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} kubna centimetra),
						'name' => q(kubni centimetri),
						'one' => q({0} kubni centimetar),
						'other' => q({0} kubnih centimetara),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} kubne stope),
						'name' => q(kubne stope),
						'one' => q({0} kubna stopa),
						'other' => q({0} kubnih stopa),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} kubne stope),
						'name' => q(kubne stope),
						'one' => q({0} kubna stopa),
						'other' => q({0} kubnih stopa),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} kubna inča),
						'name' => q(kubni inči),
						'one' => q({0} kubni inč),
						'other' => q({0} kubnih inča),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} kubna inča),
						'name' => q(kubni inči),
						'one' => q({0} kubni inč),
						'other' => q({0} kubnih inča),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kubna kilometra),
						'name' => q(kubni kilometri),
						'one' => q({0} kubni kilometar),
						'other' => q({0} kubnih kilometara),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kubna kilometra),
						'name' => q(kubni kilometri),
						'one' => q({0} kubni kilometar),
						'other' => q({0} kubnih kilometara),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(inanimate),
						'few' => q({0} kubna metra),
						'name' => q(kubni metri),
						'one' => q({0} kubni metar),
						'other' => q({0} kubnih metara),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(inanimate),
						'few' => q({0} kubna metra),
						'name' => q(kubni metri),
						'one' => q({0} kubni metar),
						'other' => q({0} kubnih metara),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} kubne milje),
						'name' => q(kubne milje),
						'one' => q({0} kubna milja),
						'other' => q({0} kubnih milja),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} kubne milje),
						'name' => q(kubne milje),
						'one' => q({0} kubna milja),
						'other' => q({0} kubnih milja),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} kubna jarda),
						'name' => q(kubni jardi),
						'one' => q({0} kubni jard),
						'other' => q({0} kubnih jardi),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} kubna jarda),
						'name' => q(kubni jardi),
						'one' => q({0} kubni jard),
						'other' => q({0} kubnih jardi),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} šolje),
						'one' => q({0} šolja),
						'other' => q({0} šolja),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} šolje),
						'one' => q({0} šolja),
						'other' => q({0} šolja),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'few' => q({0} metričke šolje),
						'name' => q(metrička šolja),
						'one' => q({0} metrička šolja),
						'other' => q({0} metričkih šolja),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'few' => q({0} metričke šolje),
						'name' => q(metrička šolja),
						'one' => q({0} metrička šolja),
						'other' => q({0} metričkih šolja),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(inanimate),
						'few' => q({0} decilitra),
						'name' => q(decilitri),
						'one' => q({0} decilitar),
						'other' => q({0} decilitara),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(inanimate),
						'few' => q({0} decilitra),
						'name' => q(decilitri),
						'one' => q({0} decilitar),
						'other' => q({0} decilitara),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} desertne kašičice),
						'name' => q(desertna kašičica),
						'one' => q({0} desertna kašičica),
						'other' => q({0} desertnih kašičica),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} desertne kašičice),
						'name' => q(desertna kašičica),
						'one' => q({0} desertna kašičica),
						'other' => q({0} desertnih kašičica),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imperijske desertne kašičice),
						'name' => q(imperijska desertna kašičica),
						'one' => q({0} imperijska desertna kašičica),
						'other' => q({0} imperijskih desertnih kašičica),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imperijske desertne kašičice),
						'name' => q(imperijska desertna kašičica),
						'one' => q({0} imperijska desertna kašičica),
						'other' => q({0} imperijskih desertnih kašičica),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} drama tečnosti),
						'one' => q({0} dram tečnosti),
						'other' => q({0} drama tečnosti),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} drama tečnosti),
						'one' => q({0} dram tečnosti),
						'other' => q({0} drama tečnosti),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} unce tečnosti),
						'name' => q(unce tečnosti),
						'one' => q({0} unca tečnosti),
						'other' => q({0} unci tečnosti),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} unce tečnosti),
						'name' => q(unce tečnosti),
						'one' => q({0} unca tečnosti),
						'other' => q({0} unci tečnosti),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} imperijske unce tečnosti),
						'name' => q(imperijske unce tečnosti),
						'one' => q({0} imperijska unca tečnosti),
						'other' => q({0} imperijskih unci tečnosti),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} imperijske unce tečnosti),
						'name' => q(imperijske unce tečnosti),
						'one' => q({0} imperijska unca tečnosti),
						'other' => q({0} imperijskih unci tečnosti),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galona),
						'name' => q(galoni),
						'one' => q({0} galon),
						'other' => q({0} galona),
						'per' => q({0} po galonu),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galona),
						'name' => q(galoni),
						'one' => q({0} galon),
						'other' => q({0} galona),
						'per' => q({0} po galonu),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} imp. galona),
						'name' => q(imperijalni galon),
						'one' => q({0} imp. galon),
						'other' => q({0} imp. galona),
						'per' => q({0} po imp. galonu),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} imp. galona),
						'name' => q(imperijalni galon),
						'one' => q({0} imp. galon),
						'other' => q({0} imp. galona),
						'per' => q({0} po imp. galonu),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(inanimate),
						'few' => q({0} hektolitra),
						'name' => q(hektolitri),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitara),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(inanimate),
						'few' => q({0} hektolitra),
						'name' => q(hektolitri),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitara),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(inanimate),
						'few' => q({0} litra),
						'one' => q({0} litar),
						'other' => q({0} litara),
						'per' => q({0} po litri),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(inanimate),
						'few' => q({0} litra),
						'one' => q({0} litar),
						'other' => q({0} litara),
						'per' => q({0} po litri),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(inanimate),
						'few' => q({0} megalitra),
						'name' => q(megalitri),
						'one' => q({0} megalitar),
						'other' => q({0} megalitara),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(inanimate),
						'few' => q({0} megalitra),
						'name' => q(megalitri),
						'one' => q({0} megalitar),
						'other' => q({0} megalitara),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(inanimate),
						'few' => q({0} mililitra),
						'name' => q(mililitri),
						'one' => q({0} mililitar),
						'other' => q({0} mililitara),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(inanimate),
						'few' => q({0} mililitra),
						'name' => q(mililitri),
						'one' => q({0} mililitar),
						'other' => q({0} mililitara),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinti),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinte),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinti),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metričke pinte),
						'name' => q(metričke pinte),
						'one' => q({0} metrička pinta),
						'other' => q({0} metričkih pinti),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metričke pinte),
						'name' => q(metričke pinte),
						'one' => q({0} metrička pinta),
						'other' => q({0} metričkih pinti),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} kvarta),
						'name' => q(kvarti),
						'one' => q({0} kvarat),
						'other' => q({0} kvarata),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} kvarta),
						'name' => q(kvarti),
						'one' => q({0} kvarat),
						'other' => q({0} kvarata),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} imperijske četvrtine),
						'name' => q(imperijska četvrtina),
						'one' => q({0} imperijska četvrtina),
						'other' => q({0} imperijskih četvrtina),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} imperijske četvrtine),
						'name' => q(imperijska četvrtina),
						'one' => q({0} imperijska četvrtina),
						'other' => q({0} imperijskih četvrtina),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} kašike),
						'name' => q(kašike),
						'one' => q({0} kašika),
						'other' => q({0} kašika),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} kašike),
						'name' => q(kašike),
						'one' => q({0} kašika),
						'other' => q({0} kašika),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} kašičice),
						'name' => q(kašičice),
						'one' => q({0} kašičica),
						'other' => q({0} kašičica),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} kašičice),
						'name' => q(kašičice),
						'one' => q({0} kašičica),
						'other' => q({0} kašičica),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} L/100km),
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} L/100km),
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp),
						'name' => q(mpg Imp),
						'one' => q({0} mpg Imp),
						'other' => q({0} mpg Imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp),
						'name' => q(mpg Imp),
						'one' => q({0} mpg Imp),
						'other' => q({0} mpg Imp),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} č),
						'name' => q(č),
						'one' => q({0} č),
						'other' => q({0} č),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} č),
						'name' => q(č),
						'one' => q({0} č),
						'other' => q({0} č),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} m),
						'name' => q(m.),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} m),
						'name' => q(m.),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} k),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} k),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} n),
						'name' => q(n.),
						'one' => q({0} n),
						'other' => q({0} n),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} n),
						'name' => q(n.),
						'one' => q({0} n),
						'other' => q({0} n),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} g),
						'name' => q(g.),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} g),
						'name' => q(g.),
						'one' => q({0} g),
						'other' => q({0} g),
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
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} milje),
						'one' => q({0} milja),
						'other' => q({0} milja),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
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
						'few' => q({0} unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unce),
						'one' => q({0} unca),
						'other' => q({0} unci),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} ks),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} ks),
						'one' => q({0} ks),
						'other' => q({0} ks),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp),
						'name' => q(Imp fl oz),
						'one' => q({0} fl oz Imp),
						'other' => q({0} fl oz Imp),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp),
						'name' => q(Imp fl oz),
						'one' => q({0} fl oz Imp),
						'other' => q({0} fl oz Imp),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0}/gal Imp),
						'name' => q(Imp gal),
						'one' => q({0}/gal Imp),
						'other' => q({0}/gal Imp),
						'per' => q({0}/gal Imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0}/gal Imp),
						'name' => q(Imp gal),
						'one' => q({0}/gal Imp),
						'other' => q({0}/gal Imp),
						'per' => q({0}/gal Imp),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} džigera),
						'one' => q({0} džigera),
						'other' => q({0} džigera),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} džigera),
						'one' => q({0} džigera),
						'other' => q({0} džigera),
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
					'volume-pinch' => {
						'few' => q({0} pn),
						'one' => q({0} pn),
						'other' => q({0} pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} pn),
						'one' => q({0} pn),
						'other' => q({0} pn),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} qt Imp),
						'one' => q({0} qt Imp),
						'other' => q({0} qt Imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} qt Imp),
						'one' => q({0} qt Imp),
						'other' => q({0} qt Imp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(pravac),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(pravac),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ge sila),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ge sila),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(lučni min),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(lučni min),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(lučne sek),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(lučne sek),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(stepeni),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(stepeni),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akeri),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akeri),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunama),
						'name' => q(dunami),
						'one' => q({0} dunam),
						'other' => q({0} dunama),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunama),
						'name' => q(dunami),
						'one' => q({0} dunam),
						'other' => q({0} dunama),
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
						'name' => q(kvadratne stope),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadratne stope),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kvadratni kilometri),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kvadratni kilometri),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kvadratni metri),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kvadratni metri),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} stavke),
						'name' => q(stavka),
						'one' => q({0} stavka),
						'other' => q({0} stavki),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} stavke),
						'name' => q(stavka),
						'one' => q({0} stavka),
						'other' => q({0} stavki),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(procenat),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(procenat),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promil),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} L/100 km),
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} L/100 km),
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}I),
						'north' => q({0}S),
						'south' => q({0}J),
						'west' => q({0}Z),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} b),
						'name' => q(bit),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} b),
						'name' => q(bit),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} B),
						'name' => q(bajt),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} B),
						'name' => q(bajt),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} v),
						'name' => q(v.),
						'one' => q({0} v),
						'other' => q({0} v),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} v),
						'name' => q(v.),
						'one' => q({0} v),
						'other' => q({0} v),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dana),
						'name' => q(d.),
						'one' => q({0} dan),
						'other' => q({0} dana),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dana),
						'name' => q(d.),
						'one' => q({0} dan),
						'other' => q({0} dana),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dec.),
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dec.),
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} sata),
						'name' => q(sati),
						'one' => q({0} sat),
						'other' => q({0} sati),
						'per' => q({0}/č),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} sata),
						'name' => q(sati),
						'one' => q({0} sat),
						'other' => q({0} sati),
						'per' => q({0}/č),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mes.),
						'name' => q(meseci),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mes.),
						'name' => q(meseci),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} kv),
						'name' => q(kv),
						'one' => q({0} kv),
						'other' => q({0} kv),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} kv),
						'name' => q(kv),
						'one' => q({0} kv),
						'other' => q({0} kv),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sek),
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sek),
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} ned.),
						'name' => q(ned.),
						'one' => q({0} ned.),
						'other' => q({0} ned.),
						'per' => q({0}/n),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} ned.),
						'name' => q(ned.),
						'one' => q({0} ned.),
						'other' => q({0} ned.),
						'per' => q({0}/n),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} god.),
						'name' => q(god.),
						'one' => q({0} god),
						'other' => q({0} god.),
						'per' => q({0}/god),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} god.),
						'name' => q(god.),
						'one' => q({0} god),
						'other' => q({0} god.),
						'per' => q({0}/god),
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
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
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
						'few' => q({0} US therms),
						'one' => q({0} US therm),
						'other' => q({0} US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} US therms),
						'one' => q({0} US therm),
						'other' => q({0} US therms),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(njutn),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(njutn),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} tačke),
						'name' => q(tačka),
						'one' => q({0} tačka),
						'other' => q({0} tačaka),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} tačke),
						'name' => q(tačka),
						'one' => q({0} tačka),
						'other' => q({0} tačaka),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(dpcm),
						'one' => q({0} ppcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'name' => q(dpcm),
						'one' => q({0} ppcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(dpi),
						'one' => q({0} ppi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ppi),
						'name' => q(dpi),
						'one' => q({0} ppi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} aj),
						'name' => q(aj),
						'one' => q({0} aj),
						'other' => q({0} aj),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} aj),
						'name' => q(aj),
						'one' => q({0} aj),
						'other' => q({0} aj),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(hv),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(hv),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlonzi),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlonzi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} inča),
						'name' => q(inči),
						'one' => q({0} inč),
						'other' => q({0} inča),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} inča),
						'name' => q(inči),
						'one' => q({0} inč),
						'other' => q({0} inča),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sg),
						'name' => q(svetlosne god.),
						'one' => q({0} sg),
						'other' => q({0} sg),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sg),
						'name' => q(svetlosne god.),
						'one' => q({0} sg),
						'other' => q({0} sg),
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
						'name' => q(milje),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milje),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parseci),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parseci),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometri),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometri),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} jrd),
						'name' => q(jardi),
						'one' => q({0} jrd),
						'other' => q({0} jrd),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} jrd),
						'name' => q(jardi),
						'one' => q({0} jrd),
						'other' => q({0} jrd),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karati),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karati),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grejn),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grejn),
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
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bf),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'name' => q(Bf),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metri u sekundi),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metri u sekundi),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milje na sat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milje na sat),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(stepeni Farenhajta),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(stepeni Farenhajta),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} š.),
						'name' => q(šolje),
						'one' => q({0} š.),
						'other' => q({0} š.),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} š.),
						'name' => q(šolje),
						'one' => q({0} š.),
						'other' => q({0} š.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} des. kaš.),
						'name' => q(des. kaš.),
						'one' => q({0} des. kaš.),
						'other' => q({0} des. kaš.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} des. kaš.),
						'name' => q(des. kaš.),
						'one' => q({0} des. kaš.),
						'other' => q({0} des. kaš.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imp. des. kaš.),
						'name' => q(imp. des. kaš.),
						'one' => q({0} imp. des. kaš.),
						'other' => q({0} imp. des. kaš.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imp. des. kaš.),
						'name' => q(imp. des. kaš.),
						'one' => q({0} imp. des. kaš.),
						'other' => q({0} imp. des. kaš.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram tečnosti),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram tečnosti),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kapi),
						'name' => q(kap),
						'one' => q({0} kap),
						'other' => q({0} kapi),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kapi),
						'name' => q(kap),
						'one' => q({0} kap),
						'other' => q({0} kapi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} džigera),
						'name' => q(džiger),
						'one' => q({0} džiger),
						'other' => q({0} džigera),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} džigera),
						'name' => q(džiger),
						'one' => q({0} džiger),
						'other' => q({0} džigera),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litri),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litri),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} prstohvata),
						'name' => q(prstohvat),
						'one' => q({0} prstohvat),
						'other' => q({0} prstohvata),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} prstohvata),
						'name' => q(prstohvat),
						'one' => q({0} prstohvat),
						'other' => q({0} prstohvata),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} kaš.),
						'name' => q(kaš.),
						'one' => q({0} kaš.),
						'other' => q({0} kaš.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} kaš.),
						'name' => q(kaš.),
						'one' => q({0} kaš.),
						'other' => q({0} kaš.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} kašič.),
						'name' => q(kašič.),
						'one' => q({0} kašič.),
						'other' => q({0} kašič.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} kašič.),
						'name' => q(kašič.),
						'one' => q({0} kašič.),
						'other' => q({0} kašič.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:da|d|yes|y)$' }
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
				end => q({0} i {1}),
				2 => q({0} i {1}),
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
					'few' => '0 hiljade',
					'one' => '0 hiljada',
					'other' => '0 hiljada',
				},
				'10000' => {
					'few' => '00 hiljade',
					'one' => '00 hiljada',
					'other' => '00 hiljada',
				},
				'100000' => {
					'few' => '000 hiljade',
					'one' => '000 hiljada',
					'other' => '000 hiljada',
				},
				'1000000' => {
					'few' => '0 miliona',
					'one' => '0 milion',
					'other' => '0 miliona',
				},
				'10000000' => {
					'few' => '00 miliona',
					'one' => '00 milion',
					'other' => '00 miliona',
				},
				'100000000' => {
					'few' => '000 miliona',
					'one' => '000 milion',
					'other' => '000 miliona',
				},
				'1000000000' => {
					'few' => '0 milijarde',
					'one' => '0 milijarda',
					'other' => '0 milijardi',
				},
				'10000000000' => {
					'few' => '00 milijarde',
					'one' => '00 milijarda',
					'other' => '00 milijardi',
				},
				'100000000000' => {
					'few' => '000 milijarde',
					'one' => '000 milijarda',
					'other' => '000 milijardi',
				},
				'1000000000000' => {
					'few' => '0 biliona',
					'one' => '0 bilion',
					'other' => '0 biliona',
				},
				'10000000000000' => {
					'few' => '00 biliona',
					'one' => '00 bilion',
					'other' => '00 biliona',
				},
				'100000000000000' => {
					'few' => '000 biliona',
					'one' => '000 bilion',
					'other' => '000 biliona',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 hilj'.'',
					'other' => '0 hilj'.'',
				},
				'10000' => {
					'one' => '00 hilj'.'',
					'other' => '00 hilj'.'',
				},
				'100000' => {
					'one' => '000 hilj'.'',
					'other' => '000 hilj'.'',
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
					'one' => '0 mlrd'.'',
					'other' => '0 mlrd'.'',
				},
				'10000000000' => {
					'one' => '00 mlrd'.'',
					'other' => '00 mlrd'.'',
				},
				'100000000000' => {
					'one' => '000 mlrd'.'',
					'other' => '000 mlrd'.'',
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
		'ADP' => {
			display_name => {
				'currency' => q(Andorska pezeta),
				'few' => q(andorske pezete),
				'one' => q(andorska pezeta),
				'other' => q(andorske pezete),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham UAE),
				'few' => q(dirhama UAE),
				'one' => q(dirham UAE),
				'other' => q(dirhama UAE),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Avganistanski avgani \(1927–2002\)),
				'few' => q(avganistanska avgana \(1927–2002\)),
				'one' => q(avganistanski avgani \(1927–2002\)),
				'other' => q(avganistanskih avgana \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(avganistanski avgani),
				'few' => q(avganistanska avgana),
				'one' => q(avganistanski avgani),
				'other' => q(avganistanskih avgana),
			},
		},
		'ALK' => {
			display_name => {
				'few' => q(stara albanska leka),
				'one' => q(stari albanski lek),
				'other' => q(starih albanskih leka),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albanski lek),
				'few' => q(albanska leka),
				'one' => q(albanski lek),
				'other' => q(albanskih leka),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(jermenski dram),
				'few' => q(jermenska drama),
				'one' => q(jermenski dram),
				'other' => q(jermenska drama),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(holandskoantilski gulden),
				'few' => q(holandskoantilska guldena),
				'one' => q(holandskoantilski gulden),
				'other' => q(holandskoantilskih guldena),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolska kvanza),
				'few' => q(angolske kvanze),
				'one' => q(angolska kvanza),
				'other' => q(angolskih kvanzi),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolijska kvanza \(1977–1990\)),
				'few' => q(angolijske kvanze \(1977–1990\)),
				'one' => q(angolijska kvanza \(1977–1990\)),
				'other' => q(angolijskih kvanzi \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolijska nova kvanza \(1990–2000\)),
				'few' => q(angolijske nove kvanze),
				'one' => q(angolijska nova kvanza),
				'other' => q(angolijskih novih kvanzi),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolijska kvanza reađustado \(1995–1999\)),
				'few' => q(angolijske kvanze reađustado \(1995–1999\)),
				'one' => q(angolijska kvanza reađustado \(1995–1999\)),
				'other' => q(angolijskih kvanzi reađustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentinski austral),
				'few' => q(argentinska australa),
				'one' => q(argentinski austral),
				'other' => q(argentinskih australa),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Argentinski pezos lej),
				'few' => q(argentinska pezos leja),
				'one' => q(argentinski pezos lej),
				'other' => q(argentinskih pezos leja),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentinski pezos monedo nacional),
				'few' => q(argentinska pezos moneda nacional),
				'one' => q(argentinski pezos monedo nacional),
				'other' => q(argentinskih pezos moneda nacionala),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentinski pezo \(1983–1985\)),
				'few' => q(argentinska pezosa \(1983–1985\)),
				'one' => q(argentinski pezo \(1983–1985\)),
				'other' => q(argentinskih pezosa \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinski pezos),
				'few' => q(argentinska pezosa),
				'one' => q(argentinski pezos),
				'other' => q(argentinskih pezosa),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Austrijski šiling),
				'few' => q(austrijska šilinga),
				'one' => q(austrijski šiling),
				'other' => q(austrijskih šilinga),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(australijski dolar),
				'few' => q(australijska dolara),
				'one' => q(australijski dolar),
				'other' => q(australijskih dolara),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubanski florin),
				'few' => q(arubanska florina),
				'one' => q(arubanski florin),
				'other' => q(arubanskih florina),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbejdžanski manat \(1993–2006\)),
				'few' => q(azerbejdžanska manata \(1993–2006\)),
				'one' => q(azerbejdžanski manat \(1993–2006\)),
				'other' => q(azerbejdžanskih manata \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbejdžanski manat),
				'few' => q(azerbejdžanska manata),
				'one' => q(azerbejdžanski manat),
				'other' => q(azerbejdžanskih manata),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosansko-Hercegovački dinar),
				'few' => q(bosansko-hercegovačka dinara),
				'one' => q(bosansko-hercegovački dinar),
				'other' => q(bosansko-hercegovačkih dinara),
			},
		},
		'BAM' => {
			symbol => 'KM',
			display_name => {
				'currency' => q(bosansko-hercegovačka konvertibilna marka),
				'few' => q(bosansko-hercegovačke konvertibilne marke),
				'one' => q(bosansko-hercegovačka konvertibilna marka),
				'other' => q(bosansko-hercegovačkih konvertibilnih maraka),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Bosansko-hercegovački novi dinar),
				'few' => q(bosansko-hercegovačka nova dinara),
				'one' => q(bosansko-hercegovački novi dinar),
				'other' => q(bosansko-hercegovačkih novih dinara),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoški dolar),
				'few' => q(barbadoška dolara),
				'one' => q(barbadoški dolar),
				'other' => q(barbadoških dolara),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeška taka),
				'few' => q(bangladeške take),
				'one' => q(bangladeška taka),
				'other' => q(bangladeških taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgijski franak \(konvertibilni\)),
				'few' => q(belgijska franka \(konvertibilna\)),
				'one' => q(belgijski franak \(konvertibilni\)),
				'other' => q(belgijskih franaka \(konvertibilnih\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgijski franak),
				'few' => q(belgijska franka),
				'one' => q(belgijski franak),
				'other' => q(belgijskih franaka),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgijski franak \(finansijski\)),
				'few' => q(belgijska franka \(finansijska\)),
				'one' => q(belgijski franak \(finansijski\)),
				'other' => q(belgijskih franaka \(finansijskih\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bugarski tvrdi lev),
				'few' => q(bugarska tvrda leva),
				'one' => q(bugarski tvrdi lev),
				'other' => q(bugarskih tvrdih leva),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Bugarski socijalistički lev),
				'few' => q(bugarska socijalistička leva),
				'one' => q(bugarski socijalistički lev),
				'other' => q(bugarskih socijalističkih leva),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bugarski lev),
				'few' => q(bugarska leva),
				'one' => q(bugarski lev),
				'other' => q(bugarskih leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Stari bugarski lev),
				'few' => q(stara bugarska leva),
				'one' => q(stari bugarski lev),
				'other' => q(starih bugarskih leva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahreinski dinar),
				'few' => q(bahreinska dinara),
				'one' => q(bahreinski dinar),
				'other' => q(bahreinskih dinara),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundski franak),
				'few' => q(burundska franka),
				'one' => q(burundski franak),
				'other' => q(burundskih franaka),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudski dolar),
				'few' => q(bermudska dolara),
				'one' => q(bermudski dolar),
				'other' => q(bermudskih dolara),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brunejski dolar),
				'few' => q(brunejska dolara),
				'one' => q(brunejski dolar),
				'other' => q(brunejskih dolara),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivijski bolivijano),
				'few' => q(bolivijska bolivijana),
				'one' => q(bolivijski bolivijano),
				'other' => q(bolivijskih bolivijana),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Stari bolivijski bolivijano),
				'few' => q(stara bolivijska bolivijana),
				'one' => q(stari bolivijski bolivijano),
				'other' => q(starih bolivijskih bolivijana),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivijski pezo),
				'few' => q(bolivijska pezosa),
				'one' => q(bolivijski pezo),
				'other' => q(bolivijskih pezosa),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivijski mvdol),
				'few' => q(bolivijska mvdola),
				'one' => q(bolivijski mvdol),
				'other' => q(bolivijskih mvdola),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brazilski novi kruzeiro \(1967–1986\)),
				'few' => q(brazilska nova kruzeira \(1967–1986\)),
				'one' => q(brazilski novi kruzeiro \(1967–1986\)),
				'other' => q(brazilskih novih kruzeira \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brazilijski kruzado),
				'few' => q(brazilska kruzadosa),
				'one' => q(brazilski kruzados),
				'other' => q(brazilskih kruzadosa),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brazilski kruzeiro \(1990–1993\)),
				'few' => q(brazilska kruzeira \(1990–1993\)),
				'one' => q(brazilski kruzeiro \(1990–1993\)),
				'other' => q(brazilskih kruzeira \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brazilski real),
				'few' => q(brazilska reala),
				'one' => q(brazilski real),
				'other' => q(brazilskih reala),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brazilijski novi kruzado),
				'few' => q(brazilska nova kruzada),
				'one' => q(brazilski novi kruzado),
				'other' => q(brazilskih novih kruzada),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazilski kruzeiro),
				'few' => q(brazilska kruzeira),
				'one' => q(brazilski kruzeiro),
				'other' => q(brazilskih kruzeira),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Stari brazilski kruzeiro),
				'few' => q(stara brazilska kruzeira),
				'one' => q(stari brazilski kruzeiro),
				'other' => q(starih brazilskih kruzeira),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamski dolar),
				'few' => q(bahamska dolara),
				'one' => q(bahamski dolar),
				'other' => q(bahamskih dolara),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(butanski ngultrum),
				'few' => q(butanska ngultruma),
				'one' => q(butanski ngultrum),
				'other' => q(butanskih ngultruma),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmanski kjat),
				'few' => q(burmanska kjata),
				'one' => q(burmanski kjat),
				'other' => q(burmanskih kjata),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(bocvanska pula),
				'few' => q(bocvanske pule),
				'one' => q(bocvanska pula),
				'other' => q(bocvanskih pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Beloruska nova rublja \(1994–1999\)),
				'few' => q(beloruske nove rublja \(1994–1999\)),
				'one' => q(beloruska nova rublja \(1994–1999\)),
				'other' => q(beloruskih novih rublji \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'r.',
			display_name => {
				'currency' => q(beloruska rublja),
				'few' => q(beloruske rublje),
				'one' => q(beloruska rublja),
				'other' => q(beloruskih rublji),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Beloruska rublja \(2000–2016\)),
				'few' => q(beloruske rublje \(2000–2016\)),
				'one' => q(beloruska rublja \(2000–2016\)),
				'other' => q(beloruskih rublji \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(beliski dolar),
				'few' => q(beliska dolara),
				'one' => q(beliski dolar),
				'other' => q(beliskih dolara),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kanadski dolar),
				'few' => q(kanadska dolara),
				'one' => q(kanadski dolar),
				'other' => q(kanadskih dolara),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongoanski franak),
				'few' => q(kongoanska franka),
				'one' => q(kongoanski franak),
				'other' => q(kongoanskih franaka),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR evro),
				'few' => q(WIR evra),
				'one' => q(WIR evro),
				'other' => q(WIR evra),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(švajcarski franak),
				'few' => q(švajcarska franka),
				'one' => q(švajcarski franak),
				'other' => q(švajcarskih franaka),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franak),
				'few' => q(WIR franka),
				'one' => q(WIR franak),
				'other' => q(WIR franaka),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Čileanski eskudo),
				'few' => q(čileanska eskuda),
				'one' => q(čileanski eskudo),
				'other' => q(čileanskih eskuda),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Čileovski unidades se fomento),
				'few' => q(čileanska unidades de fomenta),
				'one' => q(čileanski unidades de fomento),
				'other' => q(čileanski unidadesi de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(čileanski pezos),
				'few' => q(čileanska pezosa),
				'one' => q(čileanski pezos),
				'other' => q(čileanskih pezosa),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kineski juan \(ostrvski\)),
				'few' => q(kineska juana \(ostrvska\)),
				'one' => q(kineski juan \(ostrvski\)),
				'other' => q(kineskih juana \(ostrvskih\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dolar kineske narodne banke),
				'few' => q(dolara kineske narodne banke),
				'one' => q(dolar kineske narodne banke),
				'other' => q(dolara kineske narodne banke),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(kineski juan),
				'few' => q(kineska juana),
				'one' => q(kineski juan),
				'other' => q(kineskih juana),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbijski pezos),
				'few' => q(kolumbijska pezosa),
				'one' => q(kolumbijski pezos),
				'other' => q(kolumbijskih pezosa),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de valorški real),
				'few' => q(nidad de valor reala),
				'one' => q(unidad de valorški real),
				'other' => q(unidad de valorških reala),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostarikanski kolon),
				'few' => q(kostarikanska kolona),
				'one' => q(kostarikanski kolon),
				'other' => q(kostarikanskih kolona),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Stari srpski dinar),
				'few' => q(stara srpska dinara),
				'one' => q(stari srpski dinar),
				'other' => q(starih srpskih dinara),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Čehoslovačka tvrda kruna),
				'few' => q(čehoslovačke tvrde krune),
				'one' => q(čehoslovačka tvrda kruna),
				'other' => q(čehoslovačkih tvrdih kruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubanski konvertibilni pezos),
				'few' => q(kubanska konvertibilna pezosa),
				'one' => q(kubanski konvertibilni pezos),
				'other' => q(kubanskih konvertibilnih pezosa),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubanski pezos),
				'few' => q(kubanska pezosa),
				'one' => q(kubanski pezos),
				'other' => q(kubanskih pezosa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(zelenortski eskudo),
				'few' => q(zelenortska eskuda),
				'one' => q(zelenortski eskudo),
				'other' => q(zelenortskih eskuda),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kiparska funta),
				'few' => q(kiparske funte),
				'one' => q(kiparska funta),
				'other' => q(kiparskih funti),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(češka kruna),
				'few' => q(češke krune),
				'one' => q(češka kruna),
				'other' => q(čeških kruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Istočno-nemačka marka),
				'few' => q(istočno-nemačke marke),
				'one' => q(istočno-nemačka marka),
				'other' => q(istočno-nemačkih maraka),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Nemačka marka),
				'few' => q(nemačke marke),
				'one' => q(nemačka marka),
				'other' => q(nemačkih maraka),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(džibutski franak),
				'few' => q(džibutska franka),
				'one' => q(džibutski franak),
				'other' => q(džibutskih franaka),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(danska kruna),
				'few' => q(danske krune),
				'one' => q(danska kruna),
				'other' => q(danskih kruna),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikanski pezos),
				'few' => q(dominikanska pezosa),
				'one' => q(dominikanski pezos),
				'other' => q(dominikanskih pezosa),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alžirski dinar),
				'few' => q(alžirska dinara),
				'one' => q(alžirski dinar),
				'other' => q(alžirskih dinara),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ekvadorski sakr),
				'few' => q(ekvadorska sakra),
				'one' => q(ekvadorski sakr),
				'other' => q(ekvadorskih sakra),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ekvadorski unidad de valor konstante),
				'few' => q(ekvadorska unidad de valor konstanta),
				'one' => q(ekvadorski unidad de valor konstante),
				'other' => q(ekvadorskih unidad de valor konstanta),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estonska kroon),
				'few' => q(estonske krune),
				'one' => q(estonska kruna),
				'other' => q(estonskih kruna),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egipatska funta),
				'few' => q(egipatske funte),
				'one' => q(egipatska funta),
				'other' => q(egipatskih funti),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrejska nakfa),
				'few' => q(eritrejske nakfe),
				'one' => q(eritrejska nakfa),
				'other' => q(eritrejskih nakfi),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Španska pezeta \(račun\)),
				'few' => q(španske pezete \(A račun\)),
				'one' => q(španska pezeta \(A račun\)),
				'other' => q(španskih pezeta \(A račun\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Španska pezeta \(konvertibilniračun\)),
				'few' => q(španske pezete \(konvertibilan račun\)),
				'one' => q(španska pezeta \(konvertibilan račun\)),
				'other' => q(španskih pezeta \(konvertibilan račun\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Španska pezeta),
				'few' => q(španska pezeta),
				'one' => q(španska pezeta),
				'other' => q(španske pezete),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopijski bir),
				'few' => q(etiopska bira),
				'one' => q(etiopski bir),
				'other' => q(etiopskih bira),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Evro),
				'few' => q(evra),
				'one' => q(evro),
				'other' => q(evra),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finska marka),
				'few' => q(finske marke),
				'one' => q(finska marka),
				'other' => q(finskih maraka),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidžijski dolar),
				'few' => q(fidžijska dolara),
				'one' => q(fidžijski dolar),
				'other' => q(fidžijskih dolara),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(folklandska funta),
				'few' => q(foklandske funte),
				'one' => q(foklandska funta),
				'other' => q(foklandskih funti),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Francuski franak),
				'few' => q(francuska franka),
				'one' => q(francuski franak),
				'other' => q(francuskih franaka),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britanska funta),
				'few' => q(britanske funte),
				'one' => q(britanska funta),
				'other' => q(britanskih funti),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Gruzijski kupon larit),
				'few' => q(gruzijska kupon larita),
				'one' => q(gruzijski kupon larit),
				'other' => q(gruzijskih kupon larita),
			},
		},
		'GEL' => {
			symbol => 'ლ',
			display_name => {
				'currency' => q(gruzijski lari),
				'few' => q(gruzijska larija),
				'one' => q(gruzijski lari),
				'other' => q(gruzijskih larija),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ganski cedi \(1979–2007\)),
				'few' => q(ganska ceda \(1979–2007\)),
				'one' => q(ganski ced \(1979–2007\)),
				'other' => q(ganskih ceda \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ganski sedi),
				'few' => q(ganska sedija),
				'one' => q(ganski sedi),
				'other' => q(ganskih sedija),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarska funta),
				'few' => q(gibraltarske funte),
				'one' => q(gibraltarska funta),
				'other' => q(gibraltarskih funti),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambijski dalasi),
				'few' => q(gambijskih dalasija),
				'one' => q(gambijski dalasi),
				'other' => q(gambijskih dalasija),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(gvinejski franak),
				'few' => q(gvinejska franka),
				'one' => q(gvinejski franak),
				'other' => q(gvinejskih franaka),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Gvinejski sili),
				'few' => q(gvinejska sila),
				'one' => q(gvinejski sili),
				'other' => q(gvinejskih sila),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekvatorijalno-gvinejski ekvele),
				'few' => q(ekvatorijalno-gvinejska ekvela),
				'one' => q(ekvatorijalno-gvinejski ekvele),
				'other' => q(ekvatorijalno-gvinejskih ekvela),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Grčka drahma),
				'few' => q(grčke drahme),
				'one' => q(grčka drahma),
				'other' => q(grčkih drahmi),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(gvatemalski kecal),
				'few' => q(gvatemalska kecala),
				'one' => q(gvatemalski kecal),
				'other' => q(gvatemalskih kecala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugalska gvineja eskudo),
				'few' => q(portugalsko-gvinejska eskuda),
				'one' => q(portugalsko-gvinejski eskudo),
				'other' => q(portugalsko-gvinejskih eskuda),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Gvineja Bisao Pezo),
				'few' => q(gvineja-bisaoška pezosa),
				'one' => q(gvineja-bisaoški pezo),
				'other' => q(gvineja-bisaoških pezosa),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(gvajanski dolar),
				'few' => q(gvajanska dolara),
				'one' => q(gvajanski dolar),
				'other' => q(gvajanskih dolara),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(hongkonški dolar),
				'few' => q(hongkonška dolara),
				'one' => q(hongkonški dolar),
				'other' => q(hongkonških dolara),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraška lempira),
				'few' => q(honduraške lempire),
				'one' => q(honduraška lempira),
				'other' => q(honduraških lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Hrvatski dinar),
				'few' => q(hrvatska dinara),
				'one' => q(hrvatski dinar),
				'other' => q(hrvatskih dinara),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(hrvatska kuna),
				'few' => q(hrvatske kune),
				'one' => q(hrvatska kuna),
				'other' => q(hrvatskih kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haićanski gurd),
				'few' => q(haićanska gurda),
				'one' => q(haićanski gurd),
				'other' => q(haićanskih gurda),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(mađarska forinta),
				'few' => q(mađarske forinte),
				'one' => q(mađarska forinta),
				'other' => q(mađarskih forinti),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonežanska rupija),
				'few' => q(indonežanske rupije),
				'one' => q(indonežanska rupija),
				'other' => q(indonežanskih rupija),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irska funta),
				'few' => q(irske funte),
				'one' => q(irska funta),
				'other' => q(irskih funti),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Izraelska funta),
				'few' => q(izraelske funte),
				'one' => q(izraelska funta),
				'other' => q(izraelskih funti),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Stari izraelski šekeli),
				'few' => q(stari izraelski šekeli),
				'one' => q(stari izraelski šekeli),
				'other' => q(stari izraelski šekeli),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(izraelski novi šekel),
				'few' => q(izraelska nova šekela),
				'one' => q(izraelski novi šekel),
				'other' => q(izraelskih novih šekela),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indijska rupija),
				'few' => q(indijske rupije),
				'one' => q(indijska rupija),
				'other' => q(indijskih rupija),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irački dinar),
				'few' => q(iračka dinara),
				'one' => q(irački dinar),
				'other' => q(iračkih dinara),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranski rijal),
				'few' => q(iranska rijala),
				'one' => q(iranski rijal),
				'other' => q(iranskih rijala),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Stara islandska kruna),
				'few' => q(stara islandska kruna),
				'one' => q(stara islandska kruna),
				'other' => q(stara islandska kruna),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandska kruna),
				'few' => q(islandske krune),
				'one' => q(islandska kruna),
				'other' => q(islandskih kruna),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italijanska lira),
				'few' => q(italijanske lire),
				'one' => q(italijanska lira),
				'other' => q(italijanske lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamajčanski dolar),
				'few' => q(jamajčanska dolara),
				'one' => q(jamajčanski dolar),
				'other' => q(jamajčanskix dolara),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordanski dinar),
				'few' => q(jordanska dinara),
				'one' => q(jordanski dinar),
				'other' => q(jordanskih dinara),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japanski jen),
				'few' => q(japanska jena),
				'one' => q(japanski jen),
				'other' => q(japanskih jena),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenijski šiling),
				'few' => q(kenijska šilinga),
				'one' => q(kenijski šiling),
				'other' => q(kenijskih šilinga),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgistanski som),
				'few' => q(kirgistanska soma),
				'one' => q(kirgistanski som),
				'other' => q(kirgistanskih soma),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodžanski rijel),
				'few' => q(kambodžanska rijela),
				'one' => q(kambodžanski rijel),
				'other' => q(kambodžanskih rijela),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorski franak),
				'few' => q(komorska franka),
				'one' => q(komorski franak),
				'other' => q(komorskih franaka),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(severnokorejski von),
				'few' => q(severnokorejska vona),
				'one' => q(severnokorejski von),
				'other' => q(severnokorejskih vona),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Južnokorejski hvan),
				'few' => q(južnokorejska hvana),
				'one' => q(južnokorejski hvan),
				'other' => q(južnokorejskih hvana),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Stari južnokorejski von),
				'few' => q(stara južnokorejska vona),
				'one' => q(stari južnokorejski von),
				'other' => q(starih južnokorejskih vona),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(južnokorejski von),
				'few' => q(južnokorejska vona),
				'one' => q(južnokorejski von),
				'other' => q(južnokorejskih vona),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuvajtski dinar),
				'few' => q(kuvajtska dinara),
				'one' => q(kuvajtski dinar),
				'other' => q(kuvajtskih dinara),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmanski dolar),
				'few' => q(kajmanska dolara),
				'one' => q(kajmanski dolar),
				'other' => q(kajmanskih dolara),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazahstanski tenge),
				'few' => q(kazahstanska tengea),
				'one' => q(kazahstanski tenge),
				'other' => q(kazahstanskih tengea),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoski kip),
				'few' => q(laoska kipa),
				'one' => q(laoski kip),
				'other' => q(laoskih kipa),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanska funta),
				'few' => q(libanske funte),
				'one' => q(libanska funta),
				'other' => q(libanskih funti),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(šrilančanska rupija),
				'few' => q(šrilančanske rupije),
				'one' => q(šrilančanska rupija),
				'other' => q(šrilančanskih rupija),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberijski dolar),
				'few' => q(liberijska dolara),
				'one' => q(liberijski dolar),
				'other' => q(liberijskih dolara),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesotski loti),
				'few' => q(lesotska lotija),
				'one' => q(lesotski loti),
				'other' => q(lesotskih lotija),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litvanski litas),
				'few' => q(litvanska litasa),
				'one' => q(litvanski litas),
				'other' => q(litvanskih litasa),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litvanski talonas),
				'few' => q(litvanska talonasa),
				'one' => q(litvanski talonas),
				'other' => q(litvanskih talonasa),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luksemburški konvertibilni franak),
				'few' => q(luksemburška konvertibilna franka),
				'one' => q(luksemburški konvertibilni franak),
				'other' => q(luksemburških konvertibilnih franaka),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luksemburški franak),
				'few' => q(luksemburška franka),
				'one' => q(luksemburški franak),
				'other' => q(luksemburški franci),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luksemburški finansijski franak),
				'few' => q(luksemburška finansijska franka),
				'one' => q(luksemburški finansijski franak),
				'other' => q(luksemburških finansijskih franaka),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Latvijski lati),
				'few' => q(latvijska lata),
				'one' => q(latvijski lat),
				'other' => q(latvijskih lata),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvijska rublja),
				'few' => q(latvijske rublje),
				'one' => q(latvijska rublja),
				'other' => q(latvijskih rublji),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libijski dinar),
				'few' => q(libijska dinara),
				'one' => q(libijski dinar),
				'other' => q(libijskih dinara),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokanski dirham),
				'few' => q(marokanska dirhama),
				'one' => q(marokanski dirham),
				'other' => q(marokanskih dirhama),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokanski franak),
				'few' => q(marokanska franka),
				'one' => q(marokanski franak),
				'other' => q(marokanskih franaka),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monegaskanski franak),
				'few' => q(monegaskanska franka),
				'one' => q(monegaskanski franak),
				'other' => q(monegaskanskih franaka),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldovanski kupon),
				'few' => q(moldovanska kupona),
				'one' => q(moldovanski kupon),
				'other' => q(moldovanskih kupona),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldavski lej),
				'few' => q(moldavska leja),
				'one' => q(moldavski lej),
				'other' => q(moldavskih leja),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(malgaški arijari),
				'few' => q(malgaška arijarija),
				'one' => q(malgaški arijari),
				'other' => q(malgaških arijarija),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Malagasijski franak),
				'few' => q(malagašajska franka),
				'one' => q(malagašajski franak),
				'other' => q(malagašajski franci),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonski denar),
				'few' => q(makedonska denara),
				'one' => q(makedonski denar),
				'other' => q(makedonskih denara),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Stari makedonski denar),
				'few' => q(stara makedonska denara),
				'one' => q(stari makedonski denar),
				'other' => q(starih makedonskih denara),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malijanski franak),
				'few' => q(malijska franka),
				'one' => q(malijski franak),
				'other' => q(malijskih franaka),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(mjanmarski kjat),
				'few' => q(mjanmarska kjata),
				'one' => q(mjanmarski kjat),
				'other' => q(mjanmarskih kjata),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolska tugrika),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskih tugrika),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaoska pataka),
				'few' => q(makaoske patake),
				'one' => q(makaoska pataka),
				'other' => q(makaoskih pataka),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritanijska ogija \(1973–2017\)),
				'few' => q(mauritanijske ogije \(1973–2017\)),
				'one' => q(mauritanijska ogija \(1973–2017\)),
				'other' => q(mauritanijskih ogija \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritanska ogija),
				'few' => q(mauritanske ogije),
				'one' => q(mauritanska ogija),
				'other' => q(mauritanskih ogija),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Malteška lira),
				'few' => q(malteške lire),
				'one' => q(malteška lira),
				'other' => q(malteških lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Malteška funta),
				'few' => q(malteške funte),
				'one' => q(malteška funta),
				'other' => q(malteških funti),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauricijska rupija),
				'few' => q(mauricijske rupije),
				'one' => q(mauricijska rupija),
				'other' => q(mauricijskih rupija),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivska rufija),
				'few' => q(maldivske rufije),
				'one' => q(maldivska rufija),
				'other' => q(maldivskih rufija),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malavijska kvača),
				'few' => q(malavijske kvače),
				'one' => q(malavijska kvača),
				'other' => q(malavijskih kvača),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(meksički pezos),
				'few' => q(meksička pezosa),
				'one' => q(meksički pezos),
				'other' => q(meksičkih pezosa),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Meksički srebrni pezo \(1861–1992\)),
				'few' => q(meksička srebrna pezosa),
				'one' => q(meksički srebrni pezo),
				'other' => q(meksičkih srebrnih pezosa),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Meksički unidad de inversion \(UDI\)),
				'few' => q(meksička unidads de inverziona),
				'one' => q(meksički unidads de inverzion),
				'other' => q(meksičkih unidads de inverziona),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malezijski ringit),
				'few' => q(malezijska ringita),
				'one' => q(malezijski ringit),
				'other' => q(malezijskih ringita),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambijski eskudo),
				'few' => q(mozambijska eskuda),
				'one' => q(mozambijski eskudo),
				'other' => q(mozambijskih eskuda),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Stari mozambijski metikal),
				'few' => q(stara mozambijska metikala),
				'one' => q(stari mozambijski metikal),
				'other' => q(starih mozambijskih metikala),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambički metikal),
				'few' => q(mozambička metikala),
				'one' => q(mozambički metikal),
				'other' => q(mozambičkih metikala),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibijski dolar),
				'few' => q(namibijska dolara),
				'one' => q(namibijski dolar),
				'other' => q(namibijskih dolara),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigerijska naira),
				'few' => q(nigerijske naire),
				'one' => q(nigerijska naira),
				'other' => q(nigerijskih naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nikaragvanska kordoba \(1988–1991\)),
				'few' => q(nikaragvanske kordobe \(1988–1991\)),
				'one' => q(nikaragvanska kordoba \(1988–1991\)),
				'other' => q(nikaragvanskih kordoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaragvanska kordoba),
				'few' => q(nikaragvanske kordobe),
				'one' => q(nikaragvanska kordoba),
				'other' => q(nikaragvanskih kordoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Holandski gulden),
				'few' => q(holandska guldena),
				'one' => q(holandski gulden),
				'other' => q(holandskih guldena),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norveška kruna),
				'few' => q(norveške krune),
				'one' => q(norveška kruna),
				'other' => q(norveških kruna),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalska rupija),
				'few' => q(nepalske rupije),
				'one' => q(nepalska rupija),
				'other' => q(nepalskih rupija),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(novozelandski dolar),
				'few' => q(novozelandska dolara),
				'one' => q(novozelandski dolar),
				'other' => q(novozelandskih dolara),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanski rijal),
				'few' => q(omanska rijala),
				'one' => q(omanski rijal),
				'other' => q(omanskih rijala),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamska balboa),
				'few' => q(panamske balboe),
				'one' => q(panamska balboa),
				'other' => q(panamskih balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruanski inti),
				'few' => q(peruvijska intija),
				'one' => q(peruvijski inti),
				'other' => q(peruvijskih intija),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruanski sol),
				'few' => q(peruanska sola),
				'one' => q(peruanski sol),
				'other' => q(peruanskih sola),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruanski sol \(1863–1965\)),
				'few' => q(peruanska sola \(1863–1965\)),
				'one' => q(peruanski sol \(1863–1965\)),
				'other' => q(peruanskih sola \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuanska kina),
				'few' => q(papuanske kine),
				'one' => q(papuanska kina),
				'other' => q(papuanskih kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filipinski pezos),
				'few' => q(filipinska pezosa),
				'one' => q(filipinski pezos),
				'other' => q(filipinskih pezosa),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistanska rupija),
				'few' => q(pakistanske rupije),
				'one' => q(pakistanska rupija),
				'other' => q(pakistanskih rupija),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(poljski zlot),
				'few' => q(poljska zlota),
				'one' => q(poljski zlot),
				'other' => q(poljskih zlota),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Poljski zloti \(1950–1995\)),
				'few' => q(poljska zlota \(1950–1995\)),
				'one' => q(poljski zlot \(1950–1995\)),
				'other' => q(poljskih zlota \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugalski eskudo),
				'few' => q(portugalska eskuda),
				'one' => q(portugalski eskudo),
				'other' => q(portugalskih eskuda),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paragvajski gvarani),
				'few' => q(paragvajska gvaranija),
				'one' => q(paragvajski gvarani),
				'other' => q(paragvajskih gvaranija),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarski rijal),
				'few' => q(katarska rijala),
				'one' => q(katarski rijal),
				'other' => q(katarskih rijala),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rodejskidolar),
				'few' => q(rodežanska dolara),
				'one' => q(rodežanski dolar),
				'other' => q(rodežanskih dolara),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumunski lej \(1952–2006\)),
				'few' => q(rumunska leja \(1952–2006\)),
				'one' => q(rumunski lej \(1952–2006\)),
				'other' => q(rumunskih leja \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumunski lej),
				'few' => q(rumunska leja),
				'one' => q(rumunski lej),
				'other' => q(rumunskih leja),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(srpski dinar),
				'few' => q(srpska dinara),
				'one' => q(srpski dinar),
				'other' => q(srpskih dinara),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruska rublja),
				'few' => q(ruske rublje),
				'one' => q(ruska rublja),
				'other' => q(ruskih rublji),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Ruska rublja \(1991–1998\)),
				'few' => q(ruske rublje \(1991–1998\)),
				'one' => q(ruska rublja \(1991–1998\)),
				'other' => q(ruskih rublji \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandski franak),
				'few' => q(ruandska franka),
				'one' => q(ruandski franak),
				'other' => q(ruandskih franaka),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudijski rijal),
				'few' => q(saudijska rijala),
				'one' => q(saudijski rijal),
				'other' => q(saudijskih rijala),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(solomonski dolar),
				'few' => q(solomonska dolara),
				'one' => q(solomonski dolar),
				'other' => q(solomonskih dolara),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(sejšelska rupija),
				'few' => q(sejšelske rupije),
				'one' => q(sejšelska rupija),
				'other' => q(sejšelskih rupija),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Stari sudanski dinar),
				'few' => q(stara sudanska dinara),
				'one' => q(stari sudanski dinar),
				'other' => q(starih sudanskih dinara),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanska funta),
				'few' => q(sudanske funte),
				'one' => q(sudanska funta),
				'other' => q(sudanskih funti),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Stara sudanska funta),
				'few' => q(stare sudanske funte),
				'one' => q(stara sudanska funta),
				'other' => q(starih sudanskih funti),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(švedska kruna),
				'few' => q(švedske krune),
				'one' => q(švedska kruna),
				'other' => q(švedskih kruna),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurska dolara),
				'one' => q(singapurski dolar),
				'other' => q(singapurskih dolara),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(funta Svete Jelene),
				'few' => q(funte Svete Jelene),
				'one' => q(funta Svete Jelene),
				'other' => q(funti Svete Jelene),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovenački tolar),
				'few' => q(slovenačka tolara),
				'one' => q(slovenački tolar),
				'other' => q(slovenačkih tolara),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovačka kruna),
				'few' => q(slovačke krune),
				'one' => q(slovačka kruna),
				'other' => q(slovačkih kruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sijeraleonski leone),
				'few' => q(sijeraleonska leona),
				'one' => q(sijeraleonski leone),
				'other' => q(sijeraleonskih leona),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sijeraleonski leone \(1964—2022\)),
				'few' => q(sijeraleonska leona \(1964—2022\)),
				'one' => q(sijeraleonski leone \(1964—2022\)),
				'other' => q(sijeraleonskih leona \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somalijski šiling),
				'few' => q(somalijska šilinga),
				'one' => q(somalijski šiling),
				'other' => q(somalijskih šilinga),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamski dolar),
				'few' => q(surinamska dolara),
				'one' => q(surinamski dolar),
				'other' => q(surinamskih dolara),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamski gilder),
				'few' => q(surinamska gildera),
				'one' => q(surinamski gilder),
				'other' => q(surinamskih gildera),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(južnosudanska funta),
				'few' => q(južnosudanske funte),
				'one' => q(južnosudanska funta),
				'other' => q(južnosudanskih funti),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Saotomska dobra \(1977–2017\)),
				'few' => q(saotomske dobre \(1977–2017\)),
				'one' => q(saotomska dobra \(1977–2017\)),
				'other' => q(saotomskih dobri \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(saotomska dobra),
				'few' => q(saotomske dobre),
				'one' => q(saotomska dobra),
				'other' => q(saotomskih dobri),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovjetska rublja),
				'few' => q(sovjetske rublje),
				'one' => q(sovjetska rublja),
				'other' => q(sovjetskih rublji),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadorski kolon),
				'few' => q(salvadorska kolona),
				'one' => q(salvadorski kolon),
				'other' => q(salvadorskih kolona),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sirijska funta),
				'few' => q(sirijske funte),
				'one' => q(sirijska funta),
				'other' => q(sirijskih funti),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(svazilendski lilangeni),
				'few' => q(svazilendska lilangenija),
				'one' => q(svazilendski lilangeni),
				'other' => q(svazilendskih lilangenija),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(tajlandski bat),
				'few' => q(tajlandska bata),
				'one' => q(tajlandski bat),
				'other' => q(tajlandskih bata),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadžihistanska rublja),
				'few' => q(tadžihistanske rublje),
				'one' => q(tadžihistanska rublja),
				'other' => q(tadžihistanskih rublji),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadžikistanski somon),
				'few' => q(tadžikistanska somona),
				'one' => q(tadžikistanski somon),
				'other' => q(tadžikistanskih somona),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistanski manat \(1993–2009\)),
				'few' => q(turkmenistanska manata \(1993–2009\)),
				'one' => q(turkmenistanski manat \(1993–2009\)),
				'other' => q(turkmenistanski manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenistanski manat),
				'few' => q(turkmenistanska manata),
				'one' => q(turkmenistanski manat),
				'other' => q(turkmenistanskih manata),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuniski dinar),
				'few' => q(tuniska dinara),
				'one' => q(tuniski dinar),
				'other' => q(tuniskih dinara),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tonganska panga),
				'few' => q(tonganske pange),
				'one' => q(tonganska panga),
				'other' => q(tonganskih pangi),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timorški eskudo),
				'few' => q(timorška eskuda),
				'one' => q(timorški eskudo),
				'other' => q(timorških eskuda),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turska lira \(1922–2005\)),
				'few' => q(turske lire \(1922–2005\)),
				'one' => q(turska lira \(1922–2005\)),
				'other' => q(turskih lira \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turska lira),
				'few' => q(turske lire),
				'one' => q(turska lira),
				'other' => q(turskih lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad-tobagoški dolar),
				'few' => q(trinidad-tobagoška dolara),
				'one' => q(trinidad-tobagoški dolar),
				'other' => q(trinidad-tobagoških dolara),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(novi tajvanski dolar),
				'few' => q(nova tajvanska dolara),
				'one' => q(novi tajvanski dolar),
				'other' => q(novih tajvanskih dolara),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanijski šiling),
				'few' => q(tanzanijska šilinga),
				'one' => q(tanzanijski šiling),
				'other' => q(tanzanijskih šilinga),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrajinska grivna),
				'few' => q(ukrajinske grivne),
				'one' => q(ukrajinska grivna),
				'other' => q(ukrajinskih hrivnji),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrajinski karbovaneti),
				'few' => q(ukrajinska karbovanciva),
				'one' => q(ukrajinski karbovanec),
				'other' => q(ukrajinskih karbovanciva),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandski šiling \(1966–1987\)),
				'few' => q(ugandijska šilinga \(1966–1987\)),
				'one' => q(ugandijski šiling \(1966–1987\)),
				'other' => q(ugandijskih šilinga \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandski šiling),
				'few' => q(ugandska šilinga),
				'one' => q(ugandski šiling),
				'other' => q(ugandskih šilinga),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(američki dolar),
				'few' => q(američka dolara),
				'one' => q(američki dolar),
				'other' => q(američkih dolara),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(SAD dolar \(sledeći dan\)),
				'few' => q(SAD dolara \(sledeći dan\)),
				'one' => q(SAD dolar \(sledeći dan\)),
				'other' => q(SAD dolara \(sledeći dan\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(SAD dolar \(isti dan\)),
				'few' => q(SAD dolara \(isti dan\)),
				'one' => q(SAD dolar \(isti dan\)),
				'other' => q(SAD dolara \(isti dan\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Urugvajski pezo en unidades indeksadas),
				'few' => q(urugvajska pezosa en unidades indeksadesa),
				'one' => q(urugvajski pezo en unidades indeksades),
				'other' => q(ugvajskih pezosa en unidades indeksadesa),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Urugvajski pezo \(1975–1993\)),
				'few' => q(urugvajska pezosa \(1975–1993\)),
				'one' => q(urugvajski pezo \(1975–1993\)),
				'other' => q(urugvajskih pezosa \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(urugvajski pezos),
				'few' => q(urugvajska pezosa),
				'one' => q(urugvajski pezos),
				'other' => q(urugvajskih pezosa),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbekistanski som),
				'few' => q(uzbekistanska soma),
				'one' => q(uzbekistanski som),
				'other' => q(uzbekistanskih soma),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venecuelanski bolivar \(1871–2008\)),
				'few' => q(venecuelanska bolivara \(1871–2008\)),
				'one' => q(venecuelanski bolivar \(1871–2008\)),
				'other' => q(venecuelanskih bolivara \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venecuelanski bolivar \(2008–2018\)),
				'few' => q(venecuelanska bolivara \(2008–2018\)),
				'one' => q(venecuelanski bolivar \(2008–2018\)),
				'other' => q(venecuelanskih bolivara \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venecuelanski bolivar),
				'few' => q(venecuelanska bolivara),
				'one' => q(venecuelanski bolivar),
				'other' => q(venecuelanskih bolivara),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vijetnamski dong),
				'few' => q(vijetnamska donga),
				'one' => q(vijetnamski dong),
				'other' => q(vijetnamskih donga),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vijetnamski dong \(1978–1985\)),
				'few' => q(vijetnamska donga \(1978–1985\)),
				'one' => q(vijetnamski dong \(1978–1985\)),
				'other' => q(vijetnamskih donga \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatski vatu),
				'few' => q(vanuatska vatua),
				'one' => q(vanuatski vatu),
				'other' => q(vanuatskih vatua),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoanska tala),
				'few' => q(samoanske tale),
				'one' => q(samoanska tala),
				'other' => q(samoanskih tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(centralnoafrički franak),
				'few' => q(centralnoafrička franka),
				'one' => q(centralnoafrički franak),
				'other' => q(centralnoafričkih franaka),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Srebro),
				'few' => q(srebra),
				'one' => q(srebro),
				'other' => q(srebra),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Zlato),
				'few' => q(zlata),
				'one' => q(zlato),
				'other' => q(zlata),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Evropska kompozitna jedinica),
				'few' => q(evropske kompozitne jedinice),
				'one' => q(evropska kompozitna jedinica),
				'other' => q(evropskih kompozitnih jedinica),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Evropska novčana jedinica),
				'few' => q(evropske novčane jedinice \(XBB\)),
				'one' => q(evropska novčana jedinica \(XBB\)),
				'other' => q(evropske novčane jedinice \(XBB\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Evropska jedinica računa \(XBC\)),
				'few' => q(evropske jedinice računa \(XBC\)),
				'one' => q(evropska jedinica računa \(XBC\)),
				'other' => q(evropskih jedinica računa \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Evropska jedinica računa \(XBD\)),
				'few' => q(evropske jedinice računa \(XBD\)),
				'one' => q(evropska jedinica računa \(XBD\)),
				'other' => q(evropskih jedinica računa \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(istočnokaripski dolar),
				'few' => q(istočnokaripska dolara),
				'one' => q(istočnokaripski dolar),
				'other' => q(istočnokaripskix dolara),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Posebna crtaća prava),
				'few' => q(posebna crtaća prava),
				'one' => q(posebno crtaće pravo),
				'other' => q(posebnih crtaćih prava),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Evropska valutna jedinica),
				'few' => q(evropske novčane jedinice \(XEU\)),
				'one' => q(evropska novčana jedinica \(XEU\)),
				'other' => q(evropskih novčanih jedinica),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Francuski zlatni franak),
				'few' => q(francuska zlatna franka),
				'one' => q(francuski zlatni franak),
				'other' => q(francuskih zlatnih franaka),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Francuski UIC-franak),
				'few' => q(francuska UIC-franka),
				'one' => q(francuski UIC-franak),
				'other' => q(francuskih UIC-franaka),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(zapadnoafrički franak),
				'few' => q(zapadnoafrička franka),
				'one' => q(zapadnoafrički franak),
				'other' => q(zapadnoafričkih franaka),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladijum),
				'few' => q(paladijuma),
				'one' => q(paladijum),
				'other' => q(paladijuma),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP franak),
				'few' => q(CFP franka),
				'one' => q(CFP franak),
				'other' => q(CFP franaka),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platina),
				'few' => q(platine),
				'one' => q(platina),
				'other' => q(platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET fond),
				'few' => q(RINET fonda),
				'one' => q(RINET fond),
				'other' => q(RINET fondova),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Kod testirane valute),
				'few' => q(koda testirane valute),
				'one' => q(kod testirane valute),
				'other' => q(kodova testirane valute),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nepoznata valuta),
				'few' => q(nepoznate valute),
				'one' => q(nepoznata jedinica valute),
				'other' => q(nepoznatih valuta),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemenski dinar),
				'few' => q(jemenska dolara),
				'one' => q(jemenski dolar),
				'other' => q(jemenskih dolara),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenski rijal),
				'few' => q(jemenska rijala),
				'one' => q(jemenski rijal),
				'other' => q(jemenskih rijala),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslovenski tvrdi dinar),
				'few' => q(jugoslovenska tvrda dinara),
				'one' => q(jugoslovenski tvrdi dinar),
				'other' => q(jugoslovenskih tvrdih dinara),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslovenski novi dinar),
				'few' => q(jugoslovenska nova dinara),
				'one' => q(jugoslovenski novi dinar),
				'other' => q(jugoslovenskih novih dinara),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslovenski konvertibilni dinar),
				'few' => q(jugoslovenska konvertibilna dinara),
				'one' => q(jugoslovenski konvertibilni dinar),
				'other' => q(jugoslovenskih konvertibilnih dinara),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Jugoslovenski reformirani dinar),
				'few' => q(jugoslovenska reformirana dinara),
				'one' => q(jugoslovenski reformirani dinar),
				'other' => q(jugoslovenskih reformiranih dinara),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Južno-afrički rand \(finansijski\)),
				'few' => q(južnoafrička randa \(finansijska\)),
				'one' => q(južnoafrički rand \(finansijski\)),
				'other' => q(južnoafričkih randa \(finansijskih\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(južnoafrički rand),
				'few' => q(južnoafrička randa),
				'one' => q(južnoafrički rand),
				'other' => q(južnoafričkih randa),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambijska kvača \(1968–2012\)),
				'few' => q(zambijske kvače \(1968–2012\)),
				'one' => q(zambijska kvača \(1968–2012\)),
				'other' => q(zambijskih kvača \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambijska kvača),
				'few' => q(zambijske kvače),
				'one' => q(zambijska kvača),
				'other' => q(zambijskih kvača),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zairski novi zair),
				'few' => q(zairska nova zaira),
				'one' => q(zairski novi zair),
				'other' => q(zairskih novih zaira),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairski zair),
				'few' => q(zairska zaira),
				'one' => q(zairski zair),
				'other' => q(zairskih zaira),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabveanski dolar \(1980–2008\)),
				'few' => q(zimbabvejska dolara \(1980–2008\)),
				'one' => q(zimbabvejski dolar \(1980–2008\)),
				'other' => q(zimbabvejskih dolara \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabveanski dolar \(2009\)),
				'few' => q(zimbabvejska dolara \(2009\)),
				'one' => q(zimbabvejski dolar \(2009\)),
				'other' => q(zimbabvejskih dolara \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabveanski dolar \(2008\)),
				'few' => q(zimbabvejska dolara \(2008\)),
				'one' => q(zimbabvejski dolar \(2008\)),
				'other' => q(zimbabvejskih dolara \(2008\)),
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
							'Taut',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amšir',
							'Baramhat',
							'Baramuda',
							'Bašans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasi'
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
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Jekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehase',
							'Pagumen'
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
							'jan',
							'feb',
							'mar',
							'apr',
							'maj',
							'jun',
							'jul',
							'avg',
							'sep',
							'okt',
							'nov',
							'dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januar',
							'februar',
							'mart',
							'april',
							'maj',
							'jun',
							'jul',
							'avgust',
							'septembar',
							'oktobar',
							'novembar',
							'decembar'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'j',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
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
							'Tišri',
							'Hešvan',
							'Kislev',
							'Tevet',
							'Ševat',
							'Adar I',
							'Adar',
							'Nisan',
							'Ijar',
							'Sivan',
							'Tamuz',
							'Av',
							'Elul'
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
							'Vaisaka',
							'Jiaista',
							'Asada',
							'Sravana',
							'Badra',
							'Asvina',
							'Kartika',
							'Argajana',
							'Pauza',
							'Maga',
							'Falguna'
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
							'Muh.',
							'Saf.',
							'Reb. 1',
							'Reb. 2',
							'Džum. 1',
							'Džum. 2',
							'Redž.',
							'Ša.',
							'Ram.',
							'Še.',
							'Zul-k.',
							'Zul-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharem',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rađab',
							'Šaʻban',
							'Ramadan',
							'Šaval',
							'Duʻl-Kiʻda',
							'Duʻl-hiđa'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'Muharem',
							'Safer',
							'Rebi 1',
							'Rebi 2',
							'Džumade 1',
							'Džumade 2',
							'Redžeb',
							'Šaʻban',
							'Ramazan',
							'Ševal',
							'Zul-kade',
							'Zul-hidže'
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
							'Faravadin',
							'Ordibehešt',
							'Kordad',
							'Tir',
							'Mordad',
							'Šahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dej',
							'Bahman',
							'Esfand'
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
						mon => 'pon',
						tue => 'uto',
						wed => 'sre',
						thu => 'čet',
						fri => 'pet',
						sat => 'sub',
						sun => 'ned'
					},
					short => {
						mon => 'po',
						tue => 'ut',
						wed => 'sr',
						thu => 'če',
						fri => 'pe',
						sat => 'su',
						sun => 'ne'
					},
					wide => {
						mon => 'ponedeljak',
						tue => 'utorak',
						wed => 'sreda',
						thu => 'četvrtak',
						fri => 'petak',
						sat => 'subota',
						sun => 'nedelja'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'p',
						tue => 'u',
						wed => 's',
						thu => 'č',
						fri => 'p',
						sat => 's',
						sun => 'n'
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
					abbreviated => {0 => '1. kv.',
						1 => '2. kv.',
						2 => '3. kv.',
						3 => '4. kv.'
					},
					wide => {0 => 'prvi kvartal',
						1 => 'drugi kvartal',
						2 => 'treći kvartal',
						3 => 'četvrti kvartal'
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
					'afternoon1' => q{po podne},
					'evening1' => q{uveče},
					'midnight' => q{ponoć},
					'morning1' => q{ujutro},
					'night1' => q{noću},
					'noon' => q{podne},
				},
				'narrow' => {
					'afternoon1' => q{po podne},
					'evening1' => q{uveče},
					'midnight' => q{ponoć},
					'morning1' => q{ujutru},
					'night1' => q{noću},
					'noon' => q{podne},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{popodne},
					'evening1' => q{veče},
					'morning1' => q{jutro},
					'night1' => q{noć},
				},
				'narrow' => {
					'am' => q{pre podne},
					'pm' => q{po podne},
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
				'0' => 'BE'
			},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'p. n. e.',
				'1' => 'n. e.'
			},
			narrow => {
				'0' => 'p.n.e.',
				'1' => 'n.e.'
			},
			wide => {
				'0' => 'pre nove ere',
				'1' => 'nove ere'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'SAKA'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuči (650–671)',
				'2' => 'Hakuho (672–686)',
				'3' => 'Šučo (686–701)',
				'4' => 'Taiho (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Vado (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Joro (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tempio (729–749)',
				'11' => 'Tempio-kampo (749-749)',
				'12' => 'Tempio-šoho (749-757)',
				'13' => 'Tempio-hođi (757-765)',
				'14' => 'Tempo-đingo (765-767)',
				'15' => 'Đingo-keiun (767-770)',
				'16' => 'Hoki (770–780)',
				'17' => 'Ten-o (781-782)',
				'18' => 'Enrjaku (782–806)',
				'19' => 'Daido (806–810)',
				'20' => 'Konin (810–824)',
				'21' => 'Tenčo (824–834)',
				'22' => 'Šova (834–848)',
				'23' => 'Kajo (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saiko (854–857)',
				'26' => 'Tenan (857–859)',
				'27' => 'Jogan (859–877)',
				'28' => 'Genkei (877–885)',
				'29' => 'Ninja (885–889)',
				'30' => 'Kampjo (889–898)',
				'31' => 'Šotai (898–901)',
				'32' => 'Enđi (901–923)',
				'33' => 'Enčo (923–931)',
				'34' => 'Šohei (931–938)',
				'35' => 'Tengjo (938–947)',
				'36' => 'Tenriaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ova (961–964)',
				'39' => 'Koho (964–968)',
				'40' => 'Ana (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten-en (973-976)',
				'43' => 'Jogen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kana (985–987)',
				'47' => 'Ei-en (987-989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Šorjaku (990–995)',
				'50' => 'Čotoku (995–999)',
				'51' => 'Čoho (999–1004)',
				'52' => 'Kanko (1004–1012)',
				'53' => 'Čova (1012–1017)',
				'54' => 'Kanin (1017–1021)',
				'55' => 'Đian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Čogen (1028–1037)',
				'58' => 'Čorjaku (1037–1040)',
				'59' => 'Čokju (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eišo (1046–1053)',
				'62' => 'Tenđi (1053–1058)',
				'63' => 'Kohei (1058–1065)',
				'64' => 'Đirjaku (1065–1069)',
				'65' => 'Enkju (1069–1074)',
				'66' => 'Šoho (1074–1077)',
				'67' => 'Šorjaku (1077–1081)',
				'68' => 'Eišo (1081–1084)',
				'69' => 'Otoku (1084–1087)',
				'70' => 'Kanđi (1087–1094)',
				'71' => 'Kaho (1094–1096)',
				'72' => 'Eičo (1096–1097)',
				'73' => 'Šotoku (1097–1099)',
				'74' => 'Kova (1099–1104)',
				'75' => 'Čođi (1104–1106)',
				'76' => 'Kašo (1106–1108)',
				'77' => 'Tenin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikju (1113–1118)',
				'80' => 'Đen-ei (1118-1120)',
				'81' => 'Hoan (1120–1124)',
				'82' => 'Tenđi (1124–1126)',
				'83' => 'Daiđi (1126–1131)',
				'84' => 'Tenšo (1131–1132)',
				'85' => 'Čošao (1132–1135)',
				'86' => 'Hoen (1135–1141)',
				'87' => 'Eiđi (1141–1142)',
				'88' => 'Kođi (1142–1144)',
				'89' => 'Tenjo (1144–1145)',
				'90' => 'Kjuan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kjuju (1154–1156)',
				'93' => 'Hogen (1156–1159)',
				'94' => 'Heiđi (1159–1160)',
				'95' => 'Eirjaku (1160–1161)',
				'96' => 'Oho (1161–1163)',
				'97' => 'Čokan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin-an (1166-1169)',
				'100' => 'Kao (1169–1171)',
				'101' => 'Šoan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Đišo (1177–1181)',
				'104' => 'Jova (1181–1182)',
				'105' => 'Đuei (1182–1184)',
				'106' => 'Genrjuku (1184–1185)',
				'107' => 'Bunđi (1185–1190)',
				'108' => 'Kenkju (1190–1199)',
				'109' => 'Šođi (1199–1201)',
				'110' => 'Kenin (1201–1204)',
				'111' => 'Genkju (1204–1206)',
				'112' => 'Ken-ei (1206-1207)',
				'113' => 'Šogen (1207–1211)',
				'114' => 'Kenrjaku (1211–1213)',
				'115' => 'Kenpo (1213–1219)',
				'116' => 'Šokju (1219–1222)',
				'117' => 'Đu (1222–1224)',
				'118' => 'Đenin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Đoei (1232–1233)',
				'123' => 'Tempuku (1233–1234)',
				'124' => 'Bunrjaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Rjakunin (1238–1239)',
				'127' => 'En-o (1239-1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hođi (1247–1249)',
				'131' => 'Kenčo (1249–1256)',
				'132' => 'Kogen (1256–1257)',
				'133' => 'Šoka (1257–1259)',
				'134' => 'Šogen (1259–1260)',
				'135' => 'Bun-o (1260-1261)',
				'136' => 'Kočo (1261–1264)',
				'137' => 'Bun-ei (1264-1275)',
				'138' => 'Kenđi (1275–1278)',
				'139' => 'Koan (1278–1288)',
				'140' => 'Šu (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Šoan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuđi (1306–1308)',
				'146' => 'Enkei (1308–1311)',
				'147' => 'Očo (1311–1312)',
				'148' => 'Šova (1312–1317)',
				'149' => 'Bunpo (1317–1319)',
				'150' => 'Đeno (1319–1321)',
				'151' => 'Đenkjo (1321–1324)',
				'152' => 'Šoču (1324–1326)',
				'153' => 'Kareki (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genko (1331–1334)',
				'156' => 'Kemu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kokoku (1340–1346)',
				'159' => 'Šohei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Buču (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Korjaku (1379–1381)',
				'164' => 'Kova (1381–1384)',
				'165' => 'Genču (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Ku (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Oei (1394–1428)',
				'171' => 'Šočo (1428–1429)',
				'172' => 'Eikjo (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun-an (1444-1449)',
				'175' => 'Hotoku (1449–1452)',
				'176' => 'Kjotoku (1452–1455)',
				'177' => 'Košo (1455–1457)',
				'178' => 'Čoroku (1457–1460)',
				'179' => 'Kanšo (1460–1466)',
				'180' => 'Bunšo (1466–1467)',
				'181' => 'Onin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Čokjo (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meio (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eišo (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kjoroku (1528–1532)',
				'190' => 'Tenmon (1532–1555)',
				'191' => 'Kođi (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenšo (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keičo (1596–1615)',
				'197' => 'Genva (1615–1624)',
				'198' => 'Kan-ei (1624-1644)',
				'199' => 'Šoho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Šu (1652–1655)',
				'202' => 'Meirjaku (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpo (1673–1681)',
				'206' => 'Tenva (1681–1684)',
				'207' => 'Jokjo (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hoei (1704–1711)',
				'210' => 'Šotoku (1711–1716)',
				'211' => 'Kjoho (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpo (1741–1744)',
				'214' => 'Enkjo (1744–1748)',
				'215' => 'Kan-en (1748-1751)',
				'216' => 'Horjaku (1751–1764)',
				'217' => 'Meiva (1764–1772)',
				'218' => 'An-ei (1772-1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kjova (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpo (1830–1844)',
				'225' => 'Koka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man-en (1860-1861)',
				'229' => 'Bunkju (1861–1864)',
				'230' => 'Genđi (1864–1865)',
				'231' => 'Keiko (1865–1868)',
				'232' => 'Meiđi',
				'233' => 'Taišo',
				'234' => 'Šova',
				'235' => 'Haisei',
				'236' => 'Reiva'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Pre RK',
				'1' => 'RK'
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
			'full' => q{EEEE, d. MMMM y. G},
			'long' => q{d. MMMM y. G},
			'medium' => q{d.MM.y. G},
			'short' => q{d.M.y. GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y.},
			'long' => q{d. MMMM y.},
			'medium' => q{d. M. y.},
			'short' => q{d.M.yy.},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/yy G},
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
		'buddhist' => {
		},
		'coptic' => {
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
			Bhm => q{hh:mm B},
			Bhms => q{hh:mm:ss B},
			EBhm => q{E hh:mm B},
			EBhms => q{E hh:mm:ss B},
			Ed => q{E d.},
			Ehm => q{E hh:mm a},
			Ehms => q{E hh:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{MMM y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			GyMd => q{d.M.y. GGGGG},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMMdd => q{dd.MMM},
			MMdd => q{MM-dd},
			Md => q{d.M.},
			h => q{h a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			y => q{y. G},
			yyyy => q{y. G},
			yyyyM => q{M.y. GGGGG},
			yyyyMEd => q{E, d.M.y. GGGGG},
			yyyyMM => q{MM.y. G},
			yyyyMMM => q{MMM y. G},
			yyyyMMMEd => q{E, d. MMM y. G},
			yyyyMMMM => q{MMMM y. G},
			yyyyMMMd => q{d. MMM y. G},
			yyyyMMdd => q{dd.MM.y. G},
			yyyyMd => q{d.M.y. GGGGG},
			yyyyQQQ => q{QQQ, y. G},
			yyyyQQQQ => q{QQQQ y. G},
		},
		'gregorian' => {
			Bhm => q{hh:mm B},
			Bhms => q{hh:mm:ss B},
			E => q{E},
			EBhm => q{E hh:mm B},
			EBhms => q{E hh:mm:ss B},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y. G},
			GyMMM => q{MMM y. G},
			GyMMMEd => q{E, d. MMM y. G},
			GyMMMd => q{d. MMM y. G},
			GyMd => q{d.MM.y. GGGGG},
			MEd => q{E, d. M.},
			MMMEd => q{E d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{W. 'sedmica' 'u' MMMM.},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMMdd => q{dd.MMM},
			MMdd => q{dd.MM.},
			Md => q{d. M.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			y => q{y.},
			yM => q{M. y.},
			yMEd => q{E, d. M. y.},
			yMM => q{MM.y.},
			yMMM => q{MMM y.},
			yMMMEd => q{E, d. MMM y.},
			yMMMM => q{MMMM y.},
			yMMMd => q{d. MMM y.},
			yMMdd => q{dd.MM.y.},
			yMd => q{d. M. y.},
			yQQQ => q{QQQ y.},
			yQQQQ => q{QQQQ y.},
			yw => q{w. 'sedmica' 'u' Y.},
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
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d.M – E, d.M},
				d => q{E, d.M – E, d.M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd. MMM – E, dd. MMM},
				d => q{E, dd. – E, dd. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d – d. MMM},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			fallback => '{0} – {1}',
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
				y => q{y – y. G},
			},
			yM => {
				M => q{M.y – M.y. GGGGG},
				y => q{M.y – M.y. GGGGG},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y. GGGGG},
				d => q{E, d.M.y – E, d.M.y. GGGGG},
				y => q{E, d.M.y – E, d.M.y. GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y. G},
				y => q{MMM y – MMM y. G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y. G},
				d => q{E, d. MMM – E, d. MMM y. G},
				y => q{E, d. MMM y – E, d. MMM y. G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y. G},
				y => q{MMMM y. – MMMM y. G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y. G},
				d => q{d–d. MMM y. G},
				y => q{d. MMM y. – d. MMM y. G},
			},
			yMd => {
				M => q{d.M.y. – d.M.y.},
				d => q{d.M.y – d.M.y. GGGGG},
				y => q{d.M.y – d.M.y. GGGGG},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d. M. – E, d. M.},
				d => q{E, d. M. – E, d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd. MMM – E, dd. MMM},
				d => q{E, dd. – E, dd. MMM},
			},
			MMMd => {
				M => q{dd. MMM – dd. MMM},
				d => q{dd.–dd. MMM},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			fallback => '{0} – {1}',
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
				M => q{M – M. y.},
				y => q{M.y. – M.y.},
			},
			yMEd => {
				M => q{E, d. M. y. – E, d. M. y.},
				d => q{E, d. M. y. – E, d. M. y.},
				y => q{E, d. M. y. – E, d. M. y.},
			},
			yMMM => {
				M => q{MMM–MMM y.},
				y => q{MMM y. – MMM y.},
			},
			yMMMEd => {
				M => q{E, dd. MMM – E, dd. MMM y.},
				d => q{E, dd. – E, dd. MMM y.},
				y => q{E, dd. MMM y. – E, dd. MMM y.},
			},
			yMMMM => {
				M => q{MMMM – MMMM y.},
				y => q{MMMM y. – MMMM y.},
			},
			yMMMd => {
				M => q{dd. MMM – dd. MMM y.},
				d => q{dd.–dd. MMM y.},
				y => q{dd. MMM y. – dd. MMM y.},
			},
			yMd => {
				M => q{d. M. y. – d. M. y.},
				d => q{d. M. y. – d. M. y.},
				y => q{d. M. y. – d. M. y.},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0}, letnje vreme),
		regionFormat => q({0}, standardno vreme),
		'Acre' => {
			long => {
				'daylight' => q#Akre letnje računanje vremena#,
				'generic' => q#Akre vreme#,
				'standard' => q#Akre standardno vreme#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Avganistan vreme#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidžan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžir#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmera#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banžul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisao#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantir#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazavil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Budžumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar-es-Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ajun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaboron#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johanesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Džuba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinšasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaši#,
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
			exemplarCity => q#Mogadiš#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovija#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Najrobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndžamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Nijamej#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakšot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
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
			exemplarCity => q#Vindhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Centralno-afričko vreme#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Istočno-afričko vreme#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Južno-afričko vreme#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Zapadno-afričko letnje vreme#,
				'generic' => q#Zapadno-afričko vreme#,
				'standard' => q#Zapadno-afričko standardno vreme#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aljaska, letnje vreme#,
				'generic' => q#Aljaska#,
				'standard' => q#Aljaska, standardno vreme#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almati letnje računanje vremena#,
				'generic' => q#Almati vreme#,
				'standard' => q#Almati standardno vreme#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon, letnje vreme#,
				'generic' => q#Amazon vreme#,
				'standard' => q#Amazon, standardno vreme#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Enkoridž#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angvila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigva#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Aragvajana#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Galjegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Huan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Lui#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ušuaija#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baija#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Baija Banderas#,
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
			exemplarCity => q#Blank-Sejblon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Bojzi#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Ajres#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembridž Bej#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kajen#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmanska Ostrva#,
		},
		'America/Chicago' => {
			exemplarCity => q#Čikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Čihuahua#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Siudad Huarez#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Koral Harbur#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshagen#,
		},
		'America/Dawson' => {
			exemplarCity => q#Doson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Doson Krik#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glejs Bej#,
		},
		'America/Godthab' => {
			exemplarCity => q#Gothab#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gus Bej#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gvadalupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Gvajakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gvajana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosiljo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Noks, Indijana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indijana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pitersburg, Indijana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tel Siti, Indijana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevaj, Indijana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincenes, Indijana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Vinamak, Indijana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikvaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Žužui#,
		},
		'America/Juneau' => {
			exemplarCity => q#Žuno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montičelo, Kentaki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendajk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Anđeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luivile#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Louer Prinsiz Kvorter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Masejo#,
		},
		'America/Managua' => {
			exemplarCity => q#Managva#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigo#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksiko Siti#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterej#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasau#,
		},
		'America/New_York' => {
			exemplarCity => q#Njujork#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronja#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Bijula, Severna Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Centar, Severna Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Novi Salem, Severna Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ohinaga#,
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
			exemplarCity => q#Finiks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port o Prens#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spejn#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Veljo#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rejni River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Resife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Izabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santjago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paolo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Skorezbisund#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sv. Bartolomej#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sv. Džon#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sent Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sv. Lucija#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sv. Toma#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sent Vinsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Svift Kurent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tul#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tander Bej#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tihuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Vajthors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vinipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Jakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Jelounajf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Severnoameričko centralno letnje vreme#,
				'generic' => q#Severnoameričko centralno vreme#,
				'standard' => q#Severnoameričko centralno standardno vreme#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Severnoameričko istočno letnje vreme#,
				'generic' => q#Severnoameričko istočno vreme#,
				'standard' => q#Severnoameričko istočno standardno vreme#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Severnoameričko planinsko letnje vreme#,
				'generic' => q#Severnoameričko planinsko vreme#,
				'standard' => q#Severnoameričko planinsko standardno vreme#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Severnoameričko pacifičko letnje vreme#,
				'generic' => q#Severnoameričko pacifičko vreme#,
				'standard' => q#Severnoameričko pacifičko standardno vreme#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadir letnje računanje vremena#,
				'generic' => q#Anadir vreme#,
				'standard' => q#Anadir standardno vreme#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kejsi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dejvis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dimon d’Urvil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Mekvori#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Moson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Makmurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Šova#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Trol#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apija, letnje vreme#,
				'generic' => q#Apija vreme#,
				'standard' => q#Apija, standardno vreme#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Akvatau letnje računanje vremena#,
				'generic' => q#Akvatau vreme#,
				'standard' => q#Akvatau standardno vreme#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Akutobe letnje računanje vremena#,
				'generic' => q#Akutobe vreme#,
				'standard' => q#Akutobe standardno vreme#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabijsko letnje vreme#,
				'generic' => q#Arabijsko vreme#,
				'standard' => q#Arabijsko standardno vreme#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longjerbjen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina, letnje vreme#,
				'generic' => q#Argentina vreme#,
				'standard' => q#Argentina, standardno vreme#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Zapadna Argentina, letnje vreme#,
				'generic' => q#Zapadna Argentina vreme#,
				'standard' => q#Zapadna Argentina, standardno vreme#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Jermenija, letnje vreme#,
				'generic' => q#Jermenija vreme#,
				'standard' => q#Jermenija, standardno vreme#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Akutobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ašhabad#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
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
			exemplarCity => q#Bejrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunej#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
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
			exemplarCity => q#Damask#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
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
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkuck#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Džakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Džajapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalim#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karači#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kučing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikozija#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznjeck#,
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
			exemplarCity => q#Pnom Pen#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontijanak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Ši Min#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šangaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednjekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timpu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumći#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vijentijan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantsko letnje vreme#,
				'generic' => q#Atlantsko vreme#,
				'standard' => q#Atlantsko standardno vreme#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azori#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarska ostrva#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Zelenortska Ostrva#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Farska Ostrva#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rejkjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Južna Džordžija#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sveta Jelena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelejd#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brizbejn#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hil#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kari#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darvin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Iukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Hau#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidnej#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australijsko centralno letnje vreme#,
				'generic' => q#Australijsko centralno vreme#,
				'standard' => q#Australijsko centralno standardno vreme#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australijsko centralno zapadno letnje vreme#,
				'generic' => q#Australijsko centralno zapadno vreme#,
				'standard' => q#Australijsko centralno zapadno standardno vreme#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australijsko istočno letnje vreme#,
				'generic' => q#Australijsko istočno vreme#,
				'standard' => q#Australijsko istočno standardno vreme#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australijsko zapadno letnje vreme#,
				'generic' => q#Australijsko zapadno vreme#,
				'standard' => q#Australijsko zapadno standardno vreme#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbejdžan, letnje vreme#,
				'generic' => q#Azerbejdžan vreme#,
				'standard' => q#Azerbejdžan, standardno vreme#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azori, letnje vreme#,
				'generic' => q#Azori vreme#,
				'standard' => q#Azori, standardno vreme#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeš, letnje vreme#,
				'generic' => q#Bangladeš vreme#,
				'standard' => q#Bangladeš, standardno vreme#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan vreme#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivija vreme#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brazilija, letnje vreme#,
				'generic' => q#Brazilija vreme#,
				'standard' => q#Brazilija, standardno vreme#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunej Darusalum vreme#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Zelenortska Ostrva, letnje vreme#,
				'generic' => q#Zelenortska Ostrva vreme#,
				'standard' => q#Zelenortska Ostrva, standardno vreme#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Čamoro vreme#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Čatam, letnje vreme#,
				'generic' => q#Čatam vreme#,
				'standard' => q#Čatam, standardno vreme#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Čile, letnje vreme#,
				'generic' => q#Čile vreme#,
				'standard' => q#Čile, standardno vreme#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kina, letnje vreme#,
				'generic' => q#Kina vreme#,
				'standard' => q#Kinesko standardno vreme#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Čojbalsan, letnje vreme#,
				'generic' => q#Čojbalsan vreme#,
				'standard' => q#Čojbalsan, standardno vreme#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Božićno ostrvo vreme#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokos (Keling) Ostrva vreme#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbija, letnje vreme#,
				'generic' => q#Kolumbija vreme#,
				'standard' => q#Kolumbija, standardno vreme#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kukova ostrva, polu-letnje vreme#,
				'generic' => q#Kukova ostrva vreme#,
				'standard' => q#Kukova ostrva, standardno vreme#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba, letnje vreme#,
				'generic' => q#Kuba#,
				'standard' => q#Kuba, standardno vreme#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Dejvis vreme#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dimon d’Urvil vreme#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Istočni timor vreme#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Uskršnja ostrva, letnje vreme#,
				'generic' => q#Uskršnja ostrva vreme#,
				'standard' => q#Uskršnja ostrva, standardno vreme#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvador vreme#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinisano univerzalno vreme#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Nepoznat grad#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brisel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukurešt#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budimpešta#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Bisingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišinjev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dablin#,
			long => {
				'daylight' => q#Irska, standardno vreme#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernzi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrvo Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Džerzi#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalinjingrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Britanija, letnje vreme#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Marihamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariz#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
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
			exemplarCity => q#Simferopolj#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skoplje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Beč#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnjus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporožje#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Cirih#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Srednjeevropsko letnje vreme#,
				'generic' => q#Srednjeevropsko vreme#,
				'standard' => q#Srednjeevropsko standardno vreme#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Istočnoevropsko letnje vreme#,
				'generic' => q#Istočnoevropsko vreme#,
				'standard' => q#Istočnoevropsko standardno vreme#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Vreme daljeg istoka Evrope#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Zapadnoevropsko letnje vreme#,
				'generic' => q#Zapadnoevropsko vreme#,
				'standard' => q#Zapadnoevropsko standardno vreme#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklandska Ostrva, letnje vreme#,
				'generic' => q#Folklandska Ostrva vreme#,
				'standard' => q#Folklandska Ostrva, standardno vreme#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidži, letnje vreme#,
				'generic' => q#Fidži vreme#,
				'standard' => q#Fidži, standardno vreme#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francuska Gvajana vreme#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Francusko južno i antarktičko vreme#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Srednje vreme po Griniču#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos vreme#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambije vreme#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzija, letnje vreme#,
				'generic' => q#Gruzija vreme#,
				'standard' => q#Gruzija, standardno vreme#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert ostrva vreme#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Istočni Grenland, letnje vreme#,
				'generic' => q#Istočni Grenland#,
				'standard' => q#Istočni Grenland, standardno vreme#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Zapadni Grenland, letnje vreme#,
				'generic' => q#Zapadni Grenland#,
				'standard' => q#Zapadni Grenland, standardno vreme#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam standardno vreme#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Zalivsko vreme#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gvajana vreme#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havajsko-aleutsko letnje vreme#,
				'generic' => q#Havajsko-aleutsko vreme#,
				'standard' => q#Havajsko-aleutsko standardno vreme#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong, letnje vreme#,
				'generic' => q#Hong Kong vreme#,
				'standard' => q#Hong Kong, standardno vreme#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd, letnje vreme#,
				'generic' => q#Hovd vreme#,
				'standard' => q#Hovd, standardno vreme#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indijsko standardno vreme#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Čagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Božić#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivi#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricijus#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Majot#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indijsko okeansko vreme#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokina vreme#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Centralno-indonezijsko vreme#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Istočno-indonezijsko vreme#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Zapadno-indonezijsko vreme#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran, letnje vreme#,
				'generic' => q#Iran vreme#,
				'standard' => q#Iran, standardno vreme#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkuck, letnje vreme#,
				'generic' => q#Irkuck vreme#,
				'standard' => q#Irkuck, standardno vreme#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izraelsko letnje vreme#,
				'generic' => q#Izraelsko vreme#,
				'standard' => q#Izraelsko standardno vreme#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japansko letnje vreme#,
				'generic' => q#Japansko vreme#,
				'standard' => q#Japansko standardno vreme#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsko-kamčatsko letnje računanje vremena#,
				'generic' => q#Petropavlovsko-kamčatsko vreme#,
				'standard' => q#Petropavlovsko-kamčatsko standardno vreme#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Istočno-kazahstansko vreme#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Zapadno-kazahstansko vreme#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejsko letnje vreme#,
				'generic' => q#Korejsko vreme#,
				'standard' => q#Korejsko standardno vreme#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Košre vreme#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk, letnje vreme#,
				'generic' => q#Krasnojarsk vreme#,
				'standard' => q#Krasnojarsk, standardno vreme#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistan vreme#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Šri Lanka vreme#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ostrva Lajn vreme#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Hov, letnje vreme#,
				'generic' => q#Lord Hov vreme#,
				'standard' => q#Lord Hov, standardno vreme#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Makao letnje računanje vremena#,
				'generic' => q#Makao vreme#,
				'standard' => q#Makao standardno vreme#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Ostrvo Makveri vreme#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan, letnje vreme#,
				'generic' => q#Magadan vreme#,
				'standard' => q#Magadan, standardno vreme#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malezija vreme#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivi vreme#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markiz vreme#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Maršalska Ostrva vreme#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauricijus, letnje vreme#,
				'generic' => q#Mauricijus vreme#,
				'standard' => q#Mauricijus, standardno vreme#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Moson vreme#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Severozapadni Meksiko, letnje vreme#,
				'generic' => q#Severozapadni Meksiko#,
				'standard' => q#Severozapadni Meksiko, standardno vreme#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksički Pacifik, letnje vreme#,
				'generic' => q#Meksički Pacifik#,
				'standard' => q#Meksički Pacifik, standardno vreme#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Bator, letnje vreme#,
				'generic' => q#Ulan Bator vreme#,
				'standard' => q#Ulan Bator, standardno vreme#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva, letnje vreme#,
				'generic' => q#Moskva vreme#,
				'standard' => q#Moskva, standardno vreme#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mijanmar vreme#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru vreme#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal vreme#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nova Kaledonija, letnje vreme#,
				'generic' => q#Nova Kaledonija vreme#,
				'standard' => q#Nova Kaledonija, standardno vreme#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Novi Zeland, letnje vreme#,
				'generic' => q#Novi Zeland vreme#,
				'standard' => q#Novi Zeland, standardno vreme#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Njufaundlend, letnje vreme#,
				'generic' => q#Njufaundlend#,
				'standard' => q#Njufaundlend, standardno vreme#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue vreme#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Ostrvo, letnje vreme#,
				'generic' => q#Norfolk Ostrvo vreme#,
				'standard' => q#Norfolk Ostrvo, standardno vreme#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronja, letnje vreme#,
				'generic' => q#Fernando de Noronja vreme#,
				'standard' => q#Fernando de Noronja, standardno vreme#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Severna Marijanska Ostrva vreme#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk, letnje vreme#,
				'generic' => q#Novosibirsk vreme#,
				'standard' => q#Novosibirsk, standardno vreme#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk, letnje vreme#,
				'generic' => q#Omsk vreme#,
				'standard' => q#Omsk, standardno vreme#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apija#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Okland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Buganvil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Čatam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Uskršnje ostrvo#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efat#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderberi#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambije#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Gvadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Džonston#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Kanton#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Košre#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kvadžalejin#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvej#,
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
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponape#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Morzbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Sajpan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarava#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Truk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Vejk#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Valis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan, letnje vreme#,
				'generic' => q#Pakistan vreme#,
				'standard' => q#Pakistan, standardno vreme#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau vreme#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Nova Gvineja vreme#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragvaj, letnje vreme#,
				'generic' => q#Paragvaj vreme#,
				'standard' => q#Paragvaj, standardno vreme#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru, letnje vreme#,
				'generic' => q#Peru vreme#,
				'standard' => q#Peru, standardno vreme#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipini, letnje vreme#,
				'generic' => q#Filipini vreme#,
				'standard' => q#Filipini, standardno vreme#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Feniks ostrva vreme#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sen Pjer i Mikelon, letnje vreme#,
				'generic' => q#Sen Pjer i Mikelon#,
				'standard' => q#Sen Pjer i Mikelon, standardno vreme#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkern vreme#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponpej vreme#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjongjanško vreme#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kizilorda letnje računanje vremena#,
				'generic' => q#Kizilorda vreme#,
				'standard' => q#Kizilorda standardno vreme#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reinion vreme#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera vreme#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalin, letnje vreme#,
				'generic' => q#Sahalin vreme#,
				'standard' => q#Sahalin, standardno vreme#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara letnje računanje vremena#,
				'generic' => q#Samara vreme#,
				'standard' => q#Samara standardno vreme#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa, letnje vreme#,
				'generic' => q#Samoa vreme#,
				'standard' => q#Samoa, standardno vreme#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Sejšeli vreme#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur, standardno vreme#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomonska Ostrva vreme#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Južna Džordžija vreme#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam vreme#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Šova vreme#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti vreme#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tajpej, letnje vreme#,
				'generic' => q#Tajpej vreme#,
				'standard' => q#Tajpej, standardno vreme#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadžikistan vreme#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau vreme#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga, letnje vreme#,
				'generic' => q#Tonga vreme#,
				'standard' => q#Tonga, standardno vreme#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Čuuk vreme#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan, letnje vreme#,
				'generic' => q#Turkmenistan vreme#,
				'standard' => q#Turkmenistan, standardno vreme#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu vreme#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugvaj, letnje vreme#,
				'generic' => q#Urugvaj vreme#,
				'standard' => q#Urugvaj, standardno vreme#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistan, letnje vreme#,
				'generic' => q#Uzbekistan vreme#,
				'standard' => q#Uzbekistan, standardno vreme#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu, letnje vreme#,
				'generic' => q#Vanuatu vreme#,
				'standard' => q#Vanuatu, standardno vreme#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venecuela vreme#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok, letnje vreme#,
				'generic' => q#Vladivostok vreme#,
				'standard' => q#Vladivostok, standardno vreme#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd, letnje vreme#,
				'generic' => q#Volgograd vreme#,
				'standard' => q#Volgograd, standardno vreme#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok vreme#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Vejk ostrvo vreme#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Valis i Futuna Ostrva vreme#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk, letnje vreme#,
				'generic' => q#Jakutsk vreme#,
				'standard' => q#Jakutsk, standardno vreme#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg, letnje vreme#,
				'generic' => q#Jekaterinburg vreme#,
				'standard' => q#Jekaterinburg, standardno vreme#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Jukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
