=encoding utf8

=head1

Locale::CLDR::Locales::Cs - Package for language Czech

=cut

package Locale::CLDR::Locales::Cs;
# This file auto generated from Data/common/main/cs.xml
#	on Mon 11 Apr  5:25:42 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
		use bignum;
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
 				'av' => 'avarština',
 				'avk' => 'kotava',
 				'awa' => 'awadhština',
 				'ay' => 'ajmarština',
 				'az' => 'ázerbájdžánština',
 				'az@alt=short' => 'ázerbájdžánština',
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
 				'co' => 'korsičtina',
 				'cop' => 'koptština',
 				'cps' => 'kapiznonština',
 				'cr' => 'kríjština',
 				'crh' => 'turečtina (krymská)',
 				'crs' => 'kreolština (seychelská)',
 				'cs' => 'čeština',
 				'csb' => 'kašubština',
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
 				'en_US@alt=short' => 'angličtina (USA)',
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
 				'he' => 'hebrejština',
 				'hi' => 'hindština',
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
 				'liv' => 'livonština',
 				'lkt' => 'lakotština',
 				'lmo' => 'lombardština',
 				'ln' => 'lingalština',
 				'lo' => 'laoština',
 				'lol' => 'mongština',
 				'lou' => 'kreolština (Louisiana)',
 				'loz' => 'lozština',
 				'lrc' => 'lúrština (severní)',
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
 				'pl' => 'polština',
 				'pms' => 'piemonština',
 				'pnt' => 'pontština',
 				'pon' => 'pohnpeiština',
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
 				'rif' => 'rífština',
 				'rm' => 'rétorománština',
 				'rn' => 'kirundština',
 				'ro' => 'rumunština',
 				'ro_MD' => 'moldavština',
 				'rof' => 'rombo',
 				'rom' => 'romština',
 				'root' => 'kořen',
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
 				'tcy' => 'tuluština',
 				'te' => 'telugština',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetumština',
 				'tg' => 'tádžičtina',
 				'th' => 'thajština',
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
 				'tpi' => 'tok pisin',
 				'tr' => 'turečtina',
 				'tru' => 'turojština',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakonština',
 				'tsi' => 'tsimšijské jazyky',
 				'tt' => 'tatarština',
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
 				'za' => 'čuangština',
 				'zap' => 'zapotéčtina',
 				'zbl' => 'bliss systém',
 				'zea' => 'zélandština',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight (standardní marocký)',
 				'zh' => 'čínština',
 				'zh_Hans' => 'čínština (zjednodušená)',
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
			'Afak' => 'afaka',
 			'Aghb' => 'kavkazskoalbánské',
 			'Arab' => 'arabské',
 			'Arab@alt=variant' => 'persko-arabské',
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
 			'Rjng' => 'redžanské',
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
 			'MK' => 'Makedonie',
 			'MK@alt=variant' => 'Makedonie (FYROM)',
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
 			'SZ' => 'Svazijsko',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks a Caicos',
 			'TD' => 'Čad',
 			'TF' => 'Francouzská jižní území',
 			'TG' => 'Togo',
 			'TH' => 'Thajsko',
 			'TJ' => 'Tádžikistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Východní Timor',
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
 			'colcaselevel' => 'Rozlišovaní velkých a malých písmen při řazení',
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
 				'ethiopic-amete-alem' => q{Etiopský kalendář (Amete-Alem)},
 				'gregorian' => q{Gregoriánský kalendář},
 				'hebrew' => q{Hebrejský kalendář},
 				'indian' => q{Indický národní kalendář},
 				'islamic' => q{Islámský kalendář},
 				'islamic-civil' => q{Muslimský občanský kalendář},
 				'islamic-umalqura' => q{Muslimský kalendář (Umm al-Qura)},
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
 				'zhuyin' => q{Ču-jin},
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
 				'mymr' => q{Myanmarské číslice},
 				'native' => q{Nativní číslice},
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
			auxiliary => qr{[à ă â å ä ã ā æ ç è ĕ ê ë ē ì ĭ î ï ī ľ ł ñ ò ŏ ô ö ø ō œ ŕ ù ŭ û ü ū ÿ]},
			index => ['A', 'B', 'C', 'Č', 'D', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'Ř', 'S', 'Š', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[a á b c č d ď e é ě f g h {ch} i í j k l m n ň o ó p q r ř s š t ť u ú ů v w x y ý z ž]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – , ; \: ! ? . … ‘ ‚ “ „ ( ) \[ \] § @ * / \&]},
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
			'final' => '{0}…',
			'initial' => '… {0}',
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
			'word-initial' => '… {0}',
			'word-medial' => '{0}… {1}',
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
						'name' => q(světová strana),
					},
					'acre' => {
						'few' => q({0} akry),
						'many' => q({0} akru),
						'name' => q(akry),
						'one' => q({0} akr),
						'other' => q({0} akrů),
					},
					'acre-foot' => {
						'few' => q({0} akro-stopy),
						'many' => q({0} akro-stopy),
						'name' => q(akro-stopy),
						'one' => q({0} akro-stopa),
						'other' => q({0} akro-stop),
					},
					'ampere' => {
						'few' => q({0} ampéry),
						'many' => q({0} ampéru),
						'name' => q(ampéry),
						'one' => q({0} ampér),
						'other' => q({0} ampérů),
					},
					'arc-minute' => {
						'few' => q({0} minuty),
						'many' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minut),
					},
					'arc-second' => {
						'few' => q({0} vteřiny),
						'many' => q({0} vteřiny),
						'name' => q(vteřiny),
						'one' => q({0} vteřina),
						'other' => q({0} vteřin),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomické jednotky),
						'many' => q({0} astronomické jednotky),
						'name' => q(astronomické jednotky),
						'one' => q({0} astronomická jednotka),
						'other' => q({0} astronomických jednotek),
					},
					'atmosphere' => {
						'few' => q({0} atmosféry),
						'many' => q({0} atmosféry),
						'name' => q(atmosféry),
						'one' => q({0} atmosféra),
						'other' => q({0} atmosfér),
					},
					'bit' => {
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitů),
					},
					'bushel' => {
						'few' => q({0} bušly),
						'many' => q({0} bušlu),
						'name' => q(bušly),
						'one' => q({0} bušl),
						'other' => q({0} bušlů),
					},
					'byte' => {
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajty),
						'one' => q({0} bajt),
						'other' => q({0} bajtů),
					},
					'calorie' => {
						'few' => q({0} kalorie),
						'many' => q({0} kalorie),
						'name' => q(kalorie),
						'one' => q({0} kalorie),
						'other' => q({0} kalorií),
					},
					'carat' => {
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátů),
					},
					'celsius' => {
						'few' => q({0} stupně Celsia),
						'many' => q({0} stupně Celsia),
						'name' => q(stupně Celsia),
						'one' => q({0} stupeň Celsia),
						'other' => q({0} stupňů Celsia),
					},
					'centiliter' => {
						'few' => q({0} centilitry),
						'many' => q({0} centilitru),
						'name' => q(centilitry),
						'one' => q({0} centilitr),
						'other' => q({0} centilitrů),
					},
					'centimeter' => {
						'few' => q({0} centimetry),
						'many' => q({0} centimetru),
						'name' => q(centimetry),
						'one' => q({0} centimetr),
						'other' => q({0} centimetrů),
						'per' => q({0} na centimetr),
					},
					'century' => {
						'few' => q({0} století),
						'many' => q({0} století),
						'name' => q(století),
						'one' => q({0} století),
						'other' => q({0} století),
					},
					'coordinate' => {
						'east' => q({0} východní délky),
						'north' => q({0} severní šířky),
						'south' => q({0} jižní šířky),
						'west' => q({0} západní délky),
					},
					'cubic-centimeter' => {
						'few' => q({0} centimetry krychlové),
						'many' => q({0} centimetru krychlového),
						'name' => q(centimetry krychlové),
						'one' => q({0} centimetr krychlový),
						'other' => q({0} centimetrů krychlových),
						'per' => q({0} na centimetr krychlový),
					},
					'cubic-foot' => {
						'few' => q({0} stopy krychlové),
						'many' => q({0} stopy krychlové),
						'name' => q(stopy krychlové),
						'one' => q({0} stopa krychlová),
						'other' => q({0} stop krychlových),
					},
					'cubic-inch' => {
						'few' => q({0} palce krychlové),
						'many' => q({0} palce krychlového),
						'name' => q(palce krychlové),
						'one' => q({0} palec krychlový),
						'other' => q({0} palců krychlových),
					},
					'cubic-kilometer' => {
						'few' => q({0} kilometry krychlové),
						'many' => q({0} kilometru krychlového),
						'name' => q(kilometry krychlové),
						'one' => q({0} kilometr krychlový),
						'other' => q({0} kilometrů krychlových),
					},
					'cubic-meter' => {
						'few' => q({0} metry krychlové),
						'many' => q({0} metru krychlového),
						'name' => q(metry krychlové),
						'one' => q({0} metr krychlový),
						'other' => q({0} metrů krychlových),
						'per' => q({0} na metr krychlový),
					},
					'cubic-mile' => {
						'few' => q({0} míle krychlové),
						'many' => q({0} míle krychlové),
						'name' => q(míle krychlové),
						'one' => q({0} míle krychlová),
						'other' => q({0} mil krychlových),
					},
					'cubic-yard' => {
						'few' => q({0} yardy krychlové),
						'many' => q({0} yardu krychlového),
						'name' => q(yardy krychlové),
						'one' => q({0} yard krychlový),
						'other' => q({0} yardů krychlových),
					},
					'cup' => {
						'few' => q({0} šálky),
						'many' => q({0} šálku),
						'name' => q(šálek),
						'one' => q({0} šálek),
						'other' => q({0} šálků),
					},
					'cup-metric' => {
						'few' => q({0} metrické šálky),
						'many' => q({0} metrického šálku),
						'name' => q(metrické šálky),
						'one' => q({0} metrický šálek),
						'other' => q({0} metrických šálků),
					},
					'day' => {
						'few' => q({0} dny),
						'many' => q({0} dne),
						'name' => q(dny),
						'one' => q({0} den),
						'other' => q({0} dní),
						'per' => q({0} za den),
					},
					'deciliter' => {
						'few' => q({0} decilitry),
						'many' => q({0} decilitru),
						'name' => q(decilitry),
						'one' => q({0} decilitr),
						'other' => q({0} decilitrů),
					},
					'decimeter' => {
						'few' => q({0} decimetry),
						'many' => q({0} decimetru),
						'name' => q(decimetry),
						'one' => q({0} decimetr),
						'other' => q({0} decimetrů),
					},
					'degree' => {
						'few' => q({0} stupně),
						'many' => q({0} stupně),
						'name' => q(stupně),
						'one' => q({0} stupeň),
						'other' => q({0} stupňů),
					},
					'fahrenheit' => {
						'few' => q({0} stupně Fahrenheita),
						'many' => q({0} stupně Fahrenheita),
						'name' => q(stupně Fahrenheita),
						'one' => q({0} stupeň Fahrenheita),
						'other' => q({0} stupňů Fahrenheita),
					},
					'fathom' => {
						'few' => q({0} fathomy),
						'many' => q({0} fathomu),
						'name' => q(fathomy),
						'one' => q({0} fathom),
						'other' => q({0} fathomů),
					},
					'fluid-ounce' => {
						'few' => q({0} kapalinové unce),
						'many' => q({0} kapalinové unce),
						'name' => q(kapalinové unce),
						'one' => q({0} kapalinová unce),
						'other' => q({0} kapalinových uncí),
					},
					'foodcalorie' => {
						'few' => q({0} kilokalorie),
						'many' => q({0} kilokalorie),
						'name' => q(kilokalorie),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorií),
					},
					'foot' => {
						'few' => q({0} stopy),
						'many' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stop),
						'per' => q({0} na stopu),
					},
					'furlong' => {
						'few' => q({0} furlongy),
						'many' => q({0} furlongu),
						'name' => q(furlongy),
						'one' => q({0} furlong),
						'other' => q({0} furlongů),
					},
					'g-force' => {
						'few' => q({0} G),
						'many' => q({0} G),
						'name' => q(gravitační síla),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} galony),
						'many' => q({0} galonu),
						'name' => q(galony),
						'one' => q({0} galon),
						'other' => q({0} galonů),
						'per' => q({0} na galon),
					},
					'gallon-imperial' => {
						'few' => q({0} imp. galony),
						'many' => q({0} imp. galonu),
						'name' => q(imp. galony),
						'one' => q({0} imp. galon),
						'other' => q({0} imp. galonů),
						'per' => q({0} na imp. galon),
					},
					'generic' => {
						'few' => q({0} stupně),
						'many' => q({0} stupně),
						'name' => q(stupně),
						'one' => q({0} stupeň),
						'other' => q({0} stupňů),
					},
					'gigabit' => {
						'few' => q({0} gigabity),
						'many' => q({0} gigabitu),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitů),
					},
					'gigabyte' => {
						'few' => q({0} gigabajty),
						'many' => q({0} gigabajtu),
						'name' => q(gigabajty),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtů),
					},
					'gigahertz' => {
						'few' => q({0} gigahertzy),
						'many' => q({0} gigahertzu),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzů),
					},
					'gigawatt' => {
						'few' => q({0} gigawatty),
						'many' => q({0} gigawattu),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattů),
					},
					'gram' => {
						'few' => q({0} gramy),
						'many' => q({0} gramu),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramů),
						'per' => q({0} na gram),
					},
					'hectare' => {
						'few' => q({0} hektary),
						'many' => q({0} hektaru),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarů),
					},
					'hectoliter' => {
						'few' => q({0} hektolitry),
						'many' => q({0} hektolitru),
						'name' => q(hektolitr),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitrů),
					},
					'hectopascal' => {
						'few' => q({0} hektopascaly),
						'many' => q({0} hektopascalu),
						'name' => q(hektopascaly),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalů),
					},
					'hertz' => {
						'few' => q({0} hertzy),
						'many' => q({0} hertzu),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzů),
					},
					'horsepower' => {
						'few' => q({0} koňské síly),
						'many' => q({0} koňské síly),
						'name' => q(koňská síla),
						'one' => q({0} koňská síla),
						'other' => q({0} koňských sil),
					},
					'hour' => {
						'few' => q({0} hodiny),
						'many' => q({0} hodiny),
						'name' => q(hodiny),
						'one' => q({0} hodina),
						'other' => q({0} hodin),
						'per' => q({0} za hodinu),
					},
					'inch' => {
						'few' => q({0} palce),
						'many' => q({0} palce),
						'name' => q(palce),
						'one' => q({0} palec),
						'other' => q({0} palců),
						'per' => q({0} na palec),
					},
					'inch-hg' => {
						'few' => q({0} palce rtuti),
						'many' => q({0} palce rtuti),
						'name' => q(palce rtuti),
						'one' => q({0} palec rtuti),
						'other' => q({0} palců rtuti),
					},
					'joule' => {
						'few' => q({0} jouly),
						'many' => q({0} joulu),
						'name' => q(jouly),
						'one' => q({0} joule),
						'other' => q({0} joulů),
					},
					'karat' => {
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátů),
					},
					'kelvin' => {
						'few' => q({0} kelviny),
						'many' => q({0} kelvinu),
						'name' => q(kelviny),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinů),
					},
					'kilobit' => {
						'few' => q({0} kilobity),
						'many' => q({0} kilobitu),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitů),
					},
					'kilobyte' => {
						'few' => q({0} kilobajty),
						'many' => q({0} kilobajtu),
						'name' => q(kilobajty),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtů),
					},
					'kilocalorie' => {
						'few' => q({0} kilokalorie),
						'many' => q({0} kilokalorie),
						'name' => q(kilokalorie),
						'one' => q({0} kilokalorie),
						'other' => q({0} kilokalorií),
					},
					'kilogram' => {
						'few' => q({0} kilogramy),
						'many' => q({0} kilogramu),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramů),
						'per' => q({0} na kilogram),
					},
					'kilohertz' => {
						'few' => q({0} kilohertzy),
						'many' => q({0} kilohertzu),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzů),
					},
					'kilojoule' => {
						'few' => q({0} kilojouly),
						'many' => q({0} kilojoulu),
						'name' => q(kilojouly),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulů),
					},
					'kilometer' => {
						'few' => q({0} kilometry),
						'many' => q({0} kilometru),
						'name' => q(kilometry),
						'one' => q({0} kilometr),
						'other' => q({0} kilometrů),
						'per' => q({0} na kilometr),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometry za hodinu),
						'many' => q({0} kilometru za hodinu),
						'name' => q(kilometry za hodinu),
						'one' => q({0} kilometr za hodinu),
						'other' => q({0} kilometrů za hodinu),
					},
					'kilowatt' => {
						'few' => q({0} kilowatty),
						'many' => q({0} kilowattu),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattů),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilowatthodiny),
						'many' => q({0} kilowatthodiny),
						'name' => q(kilowatthodiny),
						'one' => q({0} kilowatthodina),
						'other' => q({0} kilowatthodin),
					},
					'knot' => {
						'few' => q({0} uzly),
						'many' => q({0} uzlu),
						'name' => q(uzly),
						'one' => q({0} uzel),
						'other' => q({0} uzlů),
					},
					'light-year' => {
						'few' => q({0} světelné roky),
						'many' => q({0} světelného roku),
						'name' => q(světelné roky),
						'one' => q({0} světelný rok),
						'other' => q({0} světelných let),
					},
					'liter' => {
						'few' => q({0} litry),
						'many' => q({0} litru),
						'name' => q(litry),
						'one' => q({0} litr),
						'other' => q({0} litrů),
						'per' => q({0} na litr),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} litry na sto kilometrů),
						'many' => q({0} litru na sto kilometrů),
						'name' => q(litry na sto kilometrů),
						'one' => q({0} litr na sto kilometrů),
						'other' => q({0} litrů na sto kilometrů),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litry na kilometr),
						'many' => q({0} litru na kilometr),
						'name' => q(litry na kilometr),
						'one' => q({0} litr na kilometr),
						'other' => q({0} litrů na kilometr),
					},
					'lux' => {
						'few' => q({0} luxy),
						'many' => q({0} luxu),
						'name' => q(luxy),
						'one' => q({0} lux),
						'other' => q({0} luxů),
					},
					'megabit' => {
						'few' => q({0} megabity),
						'many' => q({0} megabitu),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitů),
					},
					'megabyte' => {
						'few' => q({0} megabajty),
						'many' => q({0} megabajtu),
						'name' => q(megabajty),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtů),
					},
					'megahertz' => {
						'few' => q({0} megahertzy),
						'many' => q({0} megahertzu),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzů),
					},
					'megaliter' => {
						'few' => q({0} megalitry),
						'many' => q({0} megalitru),
						'name' => q(megalitry),
						'one' => q({0} megalitr),
						'other' => q({0} megalitrů),
					},
					'megawatt' => {
						'few' => q({0} megawatty),
						'many' => q({0} megawattu),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattů),
					},
					'meter' => {
						'few' => q({0} metry),
						'many' => q({0} metru),
						'name' => q(metry),
						'one' => q({0} metr),
						'other' => q({0} metrů),
						'per' => q({0} na metr),
					},
					'meter-per-second' => {
						'few' => q({0} metry za sekundu),
						'many' => q({0} metru za sekundu),
						'name' => q(metry za sekundu),
						'one' => q({0} metr za sekundu),
						'other' => q({0} metrů za sekundu),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metry za sekundu na druhou),
						'many' => q({0} metru za sekundu na druhou),
						'name' => q(metr za sekundu na druhou),
						'one' => q({0} metr za sekundu na druhou),
						'other' => q({0} metrů za sekundu na druhou),
					},
					'metric-ton' => {
						'few' => q({0} metrické tuny),
						'many' => q({0} metrické tuny),
						'name' => q(metrické tuny),
						'one' => q({0} metrická tuna),
						'other' => q({0} metrických tun),
					},
					'microgram' => {
						'few' => q({0} mikrogramy),
						'many' => q({0} mikrogramu),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramů),
					},
					'micrometer' => {
						'few' => q({0} mikrometry),
						'many' => q({0} mikrometru),
						'name' => q(mikrometry),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometrů),
					},
					'microsecond' => {
						'few' => q({0} mikrosekundy),
						'many' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekund),
					},
					'mile' => {
						'few' => q({0} míle),
						'many' => q({0} míle),
						'name' => q(míle),
						'one' => q({0} míle),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'few' => q({0} míle na galon),
						'many' => q({0} míle na galon),
						'name' => q(míle na galon),
						'one' => q({0} míle na galon),
						'other' => q({0} mil na galon),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} míle na imp. galon),
						'many' => q({0} míle na imp. galon),
						'name' => q(míle na imp. galon),
						'one' => q({0} míle na imp. galon),
						'other' => q({0} mil na imp. galon),
					},
					'mile-per-hour' => {
						'few' => q({0} míle za hodinu),
						'many' => q({0} míle za hodinu),
						'name' => q(míle za hodinu),
						'one' => q({0} míle za hodinu),
						'other' => q({0} mil za hodinu),
					},
					'mile-scandinavian' => {
						'few' => q({0} skandinávské míle),
						'many' => q({0} skandinávské míle),
						'name' => q(skandinávské míle),
						'one' => q({0} skandinávská míle),
						'other' => q({0} skandinávských mil),
					},
					'milliampere' => {
						'few' => q({0} miliampéry),
						'many' => q({0} miliampéru),
						'name' => q(miliampéry),
						'one' => q({0} miliampér),
						'other' => q({0} miliampérů),
					},
					'millibar' => {
						'few' => q({0} milibary),
						'many' => q({0} milibaru),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarů),
					},
					'milligram' => {
						'few' => q({0} miligramy),
						'many' => q({0} miligramu),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramů),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} miligramy na decilitr),
						'many' => q({0} miligramu na decilitr),
						'name' => q(miligramy na decilitr),
						'one' => q({0} miligram na decilitr),
						'other' => q({0} miligramů na decilitr),
					},
					'milliliter' => {
						'few' => q({0} mililitry),
						'many' => q({0} mililitru),
						'name' => q(mililitry),
						'one' => q({0} mililitr),
						'other' => q({0} mililitrů),
					},
					'millimeter' => {
						'few' => q({0} milimetry),
						'many' => q({0} milimetru),
						'name' => q(milimetry),
						'one' => q({0} milimetr),
						'other' => q({0} milimetrů),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetry rtuti),
						'many' => q({0} milimetru rtuti),
						'name' => q(milimetry rtuti),
						'one' => q({0} milimetr rtuti),
						'other' => q({0} milimetrů rtuti),
					},
					'millimole-per-liter' => {
						'few' => q({0} milimoly na litr),
						'many' => q({0} milimolu na litr),
						'name' => q(milimoly na litr),
						'one' => q({0} milimol na litr),
						'other' => q({0} milimolů na litr),
					},
					'millisecond' => {
						'few' => q({0} milisekundy),
						'many' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekund),
					},
					'milliwatt' => {
						'few' => q({0} miliwatty),
						'many' => q({0} miliwattu),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattů),
					},
					'minute' => {
						'few' => q({0} minuty),
						'many' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minut),
						'per' => q({0} za minutu),
					},
					'month' => {
						'few' => q({0} měsíce),
						'many' => q({0} měsíce),
						'name' => q(měsíce),
						'one' => q({0} měsíc),
						'other' => q({0} měsíců),
						'per' => q({0} za měsíc),
					},
					'nanometer' => {
						'few' => q({0} nanometry),
						'many' => q({0} nanometru),
						'name' => q(nanometry),
						'one' => q({0} nanometr),
						'other' => q({0} nanometrů),
					},
					'nanosecond' => {
						'few' => q({0} nanosekundy),
						'many' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekund),
					},
					'nautical-mile' => {
						'few' => q({0} námořní míle),
						'many' => q({0} námořní míle),
						'name' => q(námořní míle),
						'one' => q({0} námořní míle),
						'other' => q({0} námořních mil),
					},
					'ohm' => {
						'few' => q({0} ohmy),
						'many' => q({0} ohmu),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmů),
					},
					'ounce' => {
						'few' => q({0} unce),
						'many' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unce),
						'other' => q({0} uncí),
						'per' => q({0} na unci),
					},
					'ounce-troy' => {
						'few' => q({0} trojské unce),
						'many' => q({0} trojské unce),
						'name' => q(trojské unce),
						'one' => q({0} trojská unce),
						'other' => q({0} trojských uncí),
					},
					'parsec' => {
						'few' => q({0} parseky),
						'many' => q({0} parseku),
						'name' => q(parseky),
						'one' => q({0} parsek),
						'other' => q({0} parseků),
					},
					'part-per-million' => {
						'few' => q({0} díly z milionu),
						'many' => q({0} dílu z milionu),
						'name' => q(díly z milionu),
						'one' => q({0} díl z milionu),
						'other' => q({0} dílů z milionu),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0} procenta),
						'many' => q({0} procenta),
						'name' => q(procenta),
						'one' => q({0} procento),
						'other' => q({0} procent),
					},
					'permille' => {
						'few' => q({0} promile),
						'many' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promile),
						'other' => q({0} promile),
					},
					'petabyte' => {
						'few' => q({0} petabajty),
						'many' => q({0} petabajtu),
						'name' => q(petabajty),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtů),
					},
					'picometer' => {
						'few' => q({0} pikometry),
						'many' => q({0} pikometru),
						'name' => q(pikometry),
						'one' => q({0} pikometr),
						'other' => q({0} pikometrů),
					},
					'pint' => {
						'few' => q({0} pinty),
						'many' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pinta),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'few' => q({0} metrické pinty),
						'many' => q({0} metrické pinty),
						'name' => q(metrické pinty),
						'one' => q({0} metrická pinta),
						'other' => q({0} metrických pint),
					},
					'point' => {
						'few' => q({0} body),
						'many' => q({0} bodu),
						'name' => q(body),
						'one' => q({0} bod),
						'other' => q({0} bodů),
					},
					'pound' => {
						'few' => q({0} libry),
						'many' => q({0} libry),
						'name' => q(libra),
						'one' => q({0} libra),
						'other' => q({0} liber),
						'per' => q({0} na libru),
					},
					'pound-per-square-inch' => {
						'few' => q({0} libry na čtvereční palec),
						'many' => q({0} libry na čtvereční palec),
						'name' => q(libry na čtvereční palec),
						'one' => q({0} libra na čtvereční palec),
						'other' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} kvarty),
						'many' => q({0} kvartu),
						'name' => q(kvarty),
						'one' => q({0} kvart),
						'other' => q({0} kvartů),
					},
					'radian' => {
						'few' => q({0} radiány),
						'many' => q({0} radiánu),
						'name' => q(radiány),
						'one' => q({0} radián),
						'other' => q({0} radiánů),
					},
					'revolution' => {
						'few' => q({0} otáčky),
						'many' => q({0} otáčky),
						'name' => q(otáčky),
						'one' => q({0} otáčka),
						'other' => q({0} otáček),
					},
					'second' => {
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekund),
						'per' => q({0} za sekundu),
					},
					'square-centimeter' => {
						'few' => q({0} centimetry čtvereční),
						'many' => q({0} centimetru čtverečního),
						'name' => q(centimetry čtvereční),
						'one' => q({0} centimetr čtvereční),
						'other' => q({0} centimetrů čtverečních),
						'per' => q({0} na centimetr čtvereční),
					},
					'square-foot' => {
						'few' => q({0} stopy čtvereční),
						'many' => q({0} stopy čtvereční),
						'name' => q(stopy čtvereční),
						'one' => q({0} stopa čtvereční),
						'other' => q({0} stop čtverečních),
					},
					'square-inch' => {
						'few' => q({0} palce čtvereční),
						'many' => q({0} palce čtverečního),
						'name' => q(palce čtvereční),
						'one' => q({0} palec čtvereční),
						'other' => q({0} palců čtverečních),
						'per' => q({0} na palec čtvereční),
					},
					'square-kilometer' => {
						'few' => q({0} kilometry čtvereční),
						'many' => q({0} kilometru čtverečního),
						'name' => q(kilometry čtvereční),
						'one' => q({0} kilometr čtvereční),
						'other' => q({0} kilometrů čtverečních),
						'per' => q({0} na kilometr čtvereční),
					},
					'square-meter' => {
						'few' => q({0} metry čtvereční),
						'many' => q({0} metru čtverečního),
						'name' => q(metry čtvereční),
						'one' => q({0} metr čtvereční),
						'other' => q({0} metrů čtverečních),
						'per' => q({0} na metr čtvereční),
					},
					'square-mile' => {
						'few' => q({0} míle čtvereční),
						'many' => q({0} míle čtvereční),
						'name' => q(míle čtvereční),
						'one' => q({0} míle čtvereční),
						'other' => q({0} mil čtverečních),
						'per' => q({0} na míli čtvereční),
					},
					'square-yard' => {
						'few' => q({0} yardy čtvereční),
						'many' => q({0} yardu čtverečního),
						'name' => q(yardy čtvereční),
						'one' => q({0} yard čtvereční),
						'other' => q({0} yardů čtverečních),
					},
					'stone' => {
						'few' => q({0} kameny),
						'many' => q({0} kamene),
						'name' => q(kameny),
						'one' => q({0} kámen),
						'other' => q({0} kamenů),
					},
					'tablespoon' => {
						'few' => q({0} lžíce),
						'many' => q({0} lžíce),
						'name' => q(lžíce),
						'one' => q({0} lžíce),
						'other' => q({0} lžic),
					},
					'teaspoon' => {
						'few' => q({0} lžičky),
						'many' => q({0} lžičky),
						'name' => q(lžička),
						'one' => q({0} lžička),
						'other' => q({0} lžiček),
					},
					'terabit' => {
						'few' => q({0} terabity),
						'many' => q({0} terabitu),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitů),
					},
					'terabyte' => {
						'few' => q({0} terabajty),
						'many' => q({0} terabajtu),
						'name' => q(terabajty),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtů),
					},
					'ton' => {
						'few' => q({0} tuny),
						'many' => q({0} tuny),
						'name' => q(tuny),
						'one' => q({0} tuna),
						'other' => q({0} tun),
					},
					'volt' => {
						'few' => q({0} volty),
						'many' => q({0} voltu),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltů),
					},
					'watt' => {
						'few' => q({0} watty),
						'many' => q({0} wattu),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattů),
					},
					'week' => {
						'few' => q({0} týdny),
						'many' => q({0} týdne),
						'name' => q(týdny),
						'one' => q({0} týden),
						'other' => q({0} týdnů),
						'per' => q({0} za týden),
					},
					'yard' => {
						'few' => q({0} yardy),
						'many' => q({0} yardu),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardů),
					},
					'year' => {
						'few' => q({0} roky),
						'many' => q({0} roku),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} let),
						'per' => q({0} za rok),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(směr),
					},
					'acre' => {
						'few' => q({0} ac),
						'many' => q({0} ac),
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'many' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'many' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bitů),
					},
					'bushel' => {
						'few' => q({0} bu),
						'many' => q({0} bu),
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtů),
					},
					'calorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} CD),
						'many' => q({0} CD),
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'many' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'few' => q({0} stol.),
						'many' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'many' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'many' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'many' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'many' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'many' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'many' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'few' => q({0} mc),
						'many' => q({0} mc),
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'few' => q({0} d),
						'many' => q({0} d),
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'many' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'few' => q({0} fth),
						'many' => q({0} fth),
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'few' => q({0} fur),
						'many' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'many' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(gal Imp.),
					},
					'generic' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'many' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'many' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'many' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'many' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'many' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'many' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'many' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} hp),
						'many' => q({0} hp),
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'few' => q({0} h),
						'many' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'many' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'many' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'many' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'many' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'many' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'many' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'many' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'many' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'many' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'few' => q({0} kn),
						'many' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} ly),
						'many' => q({0} ly),
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'many' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'many' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'many' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'many' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'many' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} mt),
						'many' => q({0} mt),
						'name' => q(mt),
						'one' => q({0} mt),
						'other' => q({0} mt),
					},
					'microgram' => {
						'few' => q({0} µg),
						'many' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'many' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'many' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'many' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'many' => q({0} mi/h),
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'many' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'many' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mb),
						'many' => q({0} mb),
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram' => {
						'few' => q({0} mg),
						'many' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'many' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'many' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'many' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'month' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/měs.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'many' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'many' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'many' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'many' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'many' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'many' => q({0} oz t),
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'many' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'few' => q({0} ppm),
						'many' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'picometer' => {
						'few' => q({0} pm),
						'many' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'few' => q({0} mpt),
						'many' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'many' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'many' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'many' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'many' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					'second' => {
						'few' => q({0} s),
						'many' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'many' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'many' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'many' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'many' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'many' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'many' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'many' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'few' => q({0} st),
						'many' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'few' => q({0} tbsp),
						'many' => q({0} tbsp),
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'few' => q({0} tsp),
						'many' => q({0} tsp),
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'volt' => {
						'few' => q({0} V),
						'many' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'many' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/týd.),
					},
					'yard' => {
						'few' => q({0} yd),
						'many' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} r),
						'many' => q({0} r),
						'name' => q(r),
						'one' => q({0} r),
						'other' => q({0} r),
						'per' => q({0}/r),
					},
				},
				'short' => {
					'' => {
						'name' => q(směr),
					},
					'acre' => {
						'few' => q({0} ac),
						'many' => q({0} ac),
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'many' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'many' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'atmosphere' => {
						'few' => q({0} atm),
						'many' => q({0} atm),
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bitů),
					},
					'bushel' => {
						'few' => q({0} bu),
						'many' => q({0} bu),
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajt),
						'one' => q({0} bajt),
						'other' => q({0} bajtů),
					},
					'calorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} CD),
						'many' => q({0} CD),
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'many' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'few' => q({0} stol.),
						'many' => q({0} stol.),
						'name' => q(stol.),
						'one' => q({0} stol.),
						'other' => q({0} stol.),
					},
					'coordinate' => {
						'east' => q({0} v. d.),
						'north' => q({0} s. š.),
						'south' => q({0} j. š.),
						'west' => q({0} z. d.),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'many' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'many' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'many' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'many' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'many' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'many' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'few' => q({0} mc),
						'many' => q({0} mc),
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'few' => q({0} dny),
						'many' => q({0} dne),
						'name' => q(dny),
						'one' => q({0} den),
						'other' => q({0} dní),
						'per' => q({0}/den),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'many' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'few' => q({0} fth),
						'many' => q({0} fth),
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'few' => q({0} ft),
						'many' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'few' => q({0} fur),
						'many' => q({0} fur),
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'few' => q({0} G),
						'many' => q({0} G),
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'many' => q({0} gal Imp.),
						'name' => q(gal Imp.),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'many' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'many' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'many' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'many' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'many' => q({0} ha),
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'many' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'many' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} hp),
						'many' => q({0} hp),
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'few' => q({0} h),
						'many' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0} in),
						'many' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'many' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'many' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'many' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'many' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'many' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'many' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'many' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'many' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'many' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'few' => q({0} kn),
						'many' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} ly),
						'many' => q({0} ly),
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'many' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'many' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'many' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'many' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'many' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} mt),
						'many' => q({0} mt),
						'name' => q(mt),
						'one' => q({0} mt),
						'other' => q({0} mt),
					},
					'microgram' => {
						'few' => q({0} µg),
						'many' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'many' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'many' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'many' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp.),
						'many' => q({0} mpg Imp.),
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'many' => q({0} mi/h),
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'many' => q({0} smi),
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'many' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mb),
						'many' => q({0} mb),
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram' => {
						'few' => q({0} mg),
						'many' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'many' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'many' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'many' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} min),
						'many' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'few' => q({0} měs.),
						'many' => q({0} měs.),
						'name' => q(měs.),
						'one' => q({0} měs.),
						'other' => q({0} měs.),
						'per' => q({0}/měs.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'many' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'many' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} nmi),
						'many' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'many' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'many' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'many' => q({0} oz t),
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'many' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'few' => q({0} ppm),
						'many' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					'petabyte' => {
						'few' => q({0} PB),
						'many' => q({0} PB),
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'few' => q({0} pm),
						'many' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'few' => q({0} mpt),
						'many' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'few' => q({0} lb),
						'many' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'many' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'many' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'many' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					'second' => {
						'few' => q({0} s),
						'many' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'many' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'many' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'many' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'many' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'many' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'many' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'many' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'few' => q({0} st),
						'many' => q({0} st),
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'few' => q({0} tbsp),
						'many' => q({0} tbsp),
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'few' => q({0} tsp),
						'many' => q({0} tsp),
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'volt' => {
						'few' => q({0} V),
						'many' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'many' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} týd.),
						'many' => q({0} týd.),
						'name' => q(týd.),
						'one' => q({0} týd.),
						'other' => q({0} týd.),
						'per' => q({0}/týd.),
					},
					'yard' => {
						'few' => q({0} yd),
						'many' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} roky),
						'many' => q({0} roku),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} let),
						'per' => q({0}/r),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} a {1}),
				2 => q({0}, {1}),
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
		'arab' => {
			'decimal' => q(٫),
			'exponential' => q(اس),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(؜-),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪؜),
			'plusSign' => q(؜+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'timeSeparator' => q(٫),
		},
		'bali' => {
			'timeSeparator' => q(:),
		},
		'beng' => {
			'timeSeparator' => q(:),
		},
		'brah' => {
			'timeSeparator' => q(:),
		},
		'cakm' => {
			'timeSeparator' => q(:),
		},
		'cham' => {
			'timeSeparator' => q(:),
		},
		'deva' => {
			'timeSeparator' => q(:),
		},
		'fullwide' => {
			'timeSeparator' => q(:),
		},
		'gonm' => {
			'timeSeparator' => q(:),
		},
		'gujr' => {
			'timeSeparator' => q(:),
		},
		'guru' => {
			'timeSeparator' => q(:),
		},
		'hanidec' => {
			'timeSeparator' => q(:),
		},
		'java' => {
			'timeSeparator' => q(:),
		},
		'kali' => {
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
		'khmr' => {
			'timeSeparator' => q(:),
		},
		'knda' => {
			'timeSeparator' => q(:),
		},
		'lana' => {
			'timeSeparator' => q(:),
		},
		'lanatham' => {
			'timeSeparator' => q(:),
		},
		'laoo' => {
			'timeSeparator' => q(:),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
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
		'lepc' => {
			'timeSeparator' => q(:),
		},
		'limb' => {
			'timeSeparator' => q(:),
		},
		'mlym' => {
			'timeSeparator' => q(:),
		},
		'mong' => {
			'timeSeparator' => q(:),
		},
		'mtei' => {
			'timeSeparator' => q(:),
		},
		'mymr' => {
			'timeSeparator' => q(:),
		},
		'mymrshan' => {
			'timeSeparator' => q(:),
		},
		'nkoo' => {
			'timeSeparator' => q(:),
		},
		'olck' => {
			'timeSeparator' => q(:),
		},
		'orya' => {
			'timeSeparator' => q(:),
		},
		'osma' => {
			'timeSeparator' => q(:),
		},
		'saur' => {
			'timeSeparator' => q(:),
		},
		'shrd' => {
			'timeSeparator' => q(:),
		},
		'sora' => {
			'timeSeparator' => q(:),
		},
		'sund' => {
			'timeSeparator' => q(:),
		},
		'takr' => {
			'timeSeparator' => q(:),
		},
		'talu' => {
			'timeSeparator' => q(:),
		},
		'tamldec' => {
			'timeSeparator' => q(:),
		},
		'telu' => {
			'timeSeparator' => q(:),
		},
		'thai' => {
			'timeSeparator' => q(:),
		},
		'tibt' => {
			'timeSeparator' => q(:),
		},
		'vaii' => {
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
					'few' => '0 tis'.'',
					'many' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'many' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'many' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mil'.'',
					'many' => '0 mil'.'',
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'few' => '00 mil'.'',
					'many' => '00 mil'.'',
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'few' => '000 mil'.'',
					'many' => '000 mil'.'',
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'few' => '0 mld'.'',
					'many' => '0 mld'.'',
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'few' => '00 mld'.'',
					'many' => '00 mld'.'',
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'few' => '000 mld'.'',
					'many' => '000 mld'.'',
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'many' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'many' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'many' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
					'few' => '0 tis'.'',
					'many' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'many' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'many' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mil'.'',
					'many' => '0 mil'.'',
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'few' => '00 mil'.'',
					'many' => '00 mil'.'',
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'few' => '000 mil'.'',
					'many' => '000 mil'.'',
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'few' => '0 mld'.'',
					'many' => '0 mld'.'',
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'few' => '00 mld'.'',
					'many' => '00 mld'.'',
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'few' => '000 mld'.'',
					'many' => '000 mld'.'',
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'many' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'many' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'many' => '000 bil'.'',
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
			symbol => 'ADP',
			display_name => {
				'currency' => q(andorrská peseta),
				'few' => q(andorrské pesety),
				'many' => q(andorrské pesety),
				'one' => q(andorrská peseta),
				'other' => q(andorrských peset),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(SAE dirham),
				'few' => q(SAE dirhamy),
				'many' => q(SAE dirhamu),
				'one' => q(SAE dirham),
				'other' => q(SAE dirhamů),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(afghánský afghán \(1927–2002\)),
				'few' => q(afghánské afghány \(1927–2002\)),
				'many' => q(afghánského afghánu \(1927–2002\)),
				'one' => q(afghánský afghán \(1927–2002\)),
				'other' => q(afghánských afghánů \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afghánský afghán),
				'few' => q(afghánské afghány),
				'many' => q(afghánského afghánu),
				'one' => q(afghánský afghán),
				'other' => q(afghánských afghánů),
			},
		},
		'ALK' => {
			symbol => 'ALK',
			display_name => {
				'currency' => q(albánský lek \(1946–1965\)),
				'few' => q(albánské leky \(1946–1965\)),
				'many' => q(albánského leku \(1946–1965\)),
				'one' => q(albánský lek \(1946–1965\)),
				'other' => q(albánských leků \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albánský lek),
				'few' => q(albánské leky),
				'many' => q(albánského leku),
				'one' => q(albánský lek),
				'other' => q(albánských leků),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(arménský dram),
				'few' => q(arménské dramy),
				'many' => q(arménského dramu),
				'one' => q(arménský dram),
				'other' => q(arménských dramů),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(nizozemskoantilský gulden),
				'few' => q(nizozemskoantilské guldeny),
				'many' => q(nizozemskoantilského guldenu),
				'one' => q(nizozemskoantilský gulden),
				'other' => q(nizozemskoantilských guldenů),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(angolská kwanza),
				'few' => q(angolské kwanzy),
				'many' => q(angolské kwanzy),
				'one' => q(angolská kwanza),
				'other' => q(angolských kwanz),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(angolská kwanza \(1977–1991\)),
				'few' => q(angolské kwanzy \(1977–1991\)),
				'many' => q(angolské kwanzy \(1977–1991\)),
				'one' => q(angolská kwanza \(1977–1991\)),
				'other' => q(angolských kwanz \(1977–1991\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(angolská kwanza \(1990–2000\)),
				'few' => q(angolské kwanzy \(1990–2000\)),
				'many' => q(angolské kwanzy \(1990–2000\)),
				'one' => q(angolská kwanza \(1990–2000\)),
				'other' => q(angolských kwanz \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(angolská kwanza \(1995–1999\)),
				'few' => q(angolská kwanza \(1995–1999\)),
				'many' => q(angolské kwanzy \(1995–1999\)),
				'one' => q(angolská nový kwanza \(1995–1999\)),
				'other' => q(angolských kwanz \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(argentinský austral),
				'few' => q(argentinské australy),
				'many' => q(argentinského australu),
				'one' => q(argentinský austral),
				'other' => q(argentinských australů),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(argentinské peso ley \(1970–1983\)),
				'few' => q(argentinská pesa ley \(1970–1983\)),
				'many' => q(argentinského pesa ley \(1970–1983\)),
				'one' => q(argentinské peso ley \(1970–1983\)),
				'other' => q(argentinských pes ley \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(argentinské peso \(1881–1970\)),
				'few' => q(argentinská pesa \(1881–1970\)),
				'many' => q(argentinského pesa \(1881–1970\)),
				'one' => q(argentinské peso \(1881–1970\)),
				'other' => q(argentinských pes \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(argentinské peso \(1983–1985\)),
				'few' => q(argentinská pesa \(1983–1985\)),
				'many' => q(argentinského pesa \(1983–1985\)),
				'one' => q(argentinské peso \(1983–1985\)),
				'other' => q(argentinských pes \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(argentinské peso),
				'few' => q(argentinská pesa),
				'many' => q(argentinského pesa),
				'one' => q(argentinské peso),
				'other' => q(argentinských pes),
			},
		},
		'ATS' => {
			symbol => 'ATS',
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
			symbol => 'AWG',
			display_name => {
				'currency' => q(arubský zlatý),
				'few' => q(arubské zlaté),
				'many' => q(arubského zlatého),
				'one' => q(arubský zlatý),
				'other' => q(arubských zlatých),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(ázerbájdžánský manat \(1993–2006\)),
				'few' => q(ázerbájdžánské manaty \(1993–2006\)),
				'many' => q(ázerbájdžánského manatu \(1993–2006\)),
				'one' => q(ázerbájdžánský manat \(1993–2006\)),
				'other' => q(ázerbájdžánských manatů \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(ázerbájdžánský manat),
				'few' => q(ázerbájdžánské manaty),
				'many' => q(ázerbájdžánského manatu),
				'one' => q(ázerbájdžánský manat),
				'other' => q(ázerbájdžánských manatů),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(bosenský dinár \(1992–1994\)),
				'few' => q(bosenské dináry \(1992–1994\)),
				'many' => q(bosenského dináru \(1992–1994\)),
				'one' => q(bosenský dinár \(1992–1994\)),
				'other' => q(bosenských dinárů \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(bosenská konvertibilní marka),
				'few' => q(bosenské konvertibilní marky),
				'many' => q(bosenské konvertibilní marky),
				'one' => q(bosenská konvertibilní marka),
				'other' => q(bosenských konvertibilních marek),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(bosenský nový dinár \(1994–1997\)),
				'few' => q(bosenské nové dináry \(1994–1997\)),
				'many' => q(bosenského nového dináru \(1994–1997\)),
				'one' => q(bosenský nový dinár \(1994–1997\)),
				'other' => q(bosenských nových dinárů \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadoský dolar),
				'few' => q(barbadoské dolary),
				'many' => q(barbadoského dolaru),
				'one' => q(barbadoský dolar),
				'other' => q(barbadoských dolarů),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(bangladéšská taka),
				'few' => q(bangladéšské taky),
				'many' => q(bangladéšské taky),
				'one' => q(bangladéšská taka),
				'other' => q(bangladéšských tak),
			},
		},
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(belgický konvertibilní frank),
				'few' => q(belgické konvertibilní franky),
				'many' => q(belgického konvertibilního franku),
				'one' => q(belgický konvertibilní frank),
				'other' => q(belgických konvertibilních franků),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(belgický frank),
				'few' => q(belgické franky),
				'many' => q(belgického franku),
				'one' => q(belgický frank),
				'other' => q(belgických franků),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(belgický finanční frank),
				'few' => q(belgické finanční franky),
				'many' => q(belgického finančního franku),
				'one' => q(belgický finanční frank),
				'other' => q(belgických finančních franků),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(bulharský tvrdý leva),
				'few' => q(bulharské tvrdé leva),
				'many' => q(bulharského tvrdého leva),
				'one' => q(bulharský tvrdý leva),
				'other' => q(bulharských tvrdých leva),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(bulharský socialistický leva),
				'few' => q(bulharské socialistické leva),
				'many' => q(bulharského socialistického leva),
				'one' => q(bulharský socialistický leva),
				'other' => q(bulharských socialistických leva),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bulharský leva),
				'few' => q(bulharské leva),
				'many' => q(bulharského leva),
				'one' => q(bulharský leva),
				'other' => q(bulharských leva),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(bulharský lev \(1879–1952\)),
				'few' => q(bulharské leva \(1879–1952\)),
				'many' => q(bulharského leva \(1879–1952\)),
				'one' => q(bulharský lev \(1879–1952\)),
				'other' => q(bulharských leva \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahrajnský dinár),
				'few' => q(bahrajnské dináry),
				'many' => q(bahrajnského dináru),
				'one' => q(bahrajnský dinár),
				'other' => q(bahrajnských dinárů),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundský frank),
				'few' => q(burundské franky),
				'many' => q(burundského franku),
				'one' => q(burundský frank),
				'other' => q(burundských franků),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(bermudský dolar),
				'few' => q(bermudské dolary),
				'many' => q(bermudského dolaru),
				'one' => q(bermudský dolar),
				'other' => q(bermudských dolarů),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(brunejský dolar),
				'few' => q(brunejské dolary),
				'many' => q(brunejského dolaru),
				'one' => q(brunejský dolar),
				'other' => q(brunejských dolarů),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(bolivijský boliviano),
				'few' => q(bolivijské bolivianos),
				'many' => q(bolivijského boliviana),
				'one' => q(bolivijský boliviano),
				'other' => q(bolivijských bolivianos),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(bolivijský boliviano \(1863–1963\)),
				'few' => q(bolivijské bolivianos \(1863–1963\)),
				'many' => q(bolivijského boliviana \(1863–1963\)),
				'one' => q(bolivijský boliviano \(1863–1963\)),
				'other' => q(bolivijských bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(bolivijské peso),
				'few' => q(bolivijská pesa),
				'many' => q(bolivijského pesa),
				'one' => q(bolivijské peso),
				'other' => q(bolivijských pes),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(bolivijský mvdol),
				'few' => q(bolivijské mvdoly),
				'many' => q(bolivijského mvdolu),
				'one' => q(bolivijský mvdol),
				'other' => q(bolivijských mvdolů),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(brazilské nové cruzeiro \(1967–1986\)),
				'few' => q(brazilská nová cruzeira \(1967–1986\)),
				'many' => q(brazilského nového cruzeira \(1967–1986\)),
				'one' => q(brazilské nové cruzeiro \(1967–1986\)),
				'other' => q(brazilských nových cruzeir \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(brazilské cruzado \(1986–1989\)),
				'few' => q(brazilská cruzada \(1986–1989\)),
				'many' => q(brazilského cruzada \(1986–1989\)),
				'one' => q(brazilské cruzado \(1986–1989\)),
				'other' => q(brazilských cruzad \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(brazilské cruzeiro \(1990–1993\)),
				'few' => q(brazilská cruzeira \(1990–1993\)),
				'many' => q(brazilského cruzeira \(1990–1993\)),
				'one' => q(brazilské cruzeiro \(1990–1993\)),
				'other' => q(brazilských cruzeir \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(brazilský real),
				'few' => q(brazilské realy),
				'many' => q(brazilského realu),
				'one' => q(brazilský real),
				'other' => q(brazilských realů),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(brazilské nové cruzado \(1989–1990\)),
				'few' => q(brazilská nová cruzada \(1989–1990\)),
				'many' => q(brazilského nového cruzada \(1989–1990\)),
				'one' => q(brazilské nové cruzado \(1989–1990\)),
				'other' => q(brazilských nových cruzad \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(brazilské cruzeiro \(1993–1994\)),
				'few' => q(brazilská cruzeira \(1993–1994\)),
				'many' => q(brazilského cruzeira \(1993–1994\)),
				'one' => q(brazilské cruzeiro \(1993–1994\)),
				'other' => q(brazilských cruzeir \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(brazilské cruzeiro \(1942–1967\)),
				'few' => q(brazilská cruzeira \(1942–1967\)),
				'many' => q(brazilského cruzeira \(1942–1967\)),
				'one' => q(brazilské cruzeiro \(1942–1967\)),
				'other' => q(brazilských cruzeir \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(bahamský dolar),
				'few' => q(bahamské dolary),
				'many' => q(bahamského dolaru),
				'one' => q(bahamský dolar),
				'other' => q(bahamských dolarů),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(bhútánský ngultrum),
				'few' => q(bhútánské ngultrumy),
				'many' => q(bhútánského ngultrumu),
				'one' => q(bhútánský ngultrum),
				'other' => q(bhútánských ngultrumů),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(barmský kyat),
				'few' => q(barmské kyaty),
				'many' => q(barmského kyatu),
				'one' => q(barmský kyat),
				'other' => q(barmských kyatů),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(botswanská pula),
				'few' => q(botswanské puly),
				'many' => q(botswanské puly),
				'one' => q(botswanská pula),
				'other' => q(botswanských pul),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(běloruský rubl \(1994–1999\)),
				'few' => q(běloruské rubly \(1994–1999\)),
				'many' => q(běloruského rublu \(1994–1999\)),
				'one' => q(běloruský rubl \(1994–1999\)),
				'other' => q(běloruských rublů \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(běloruský rubl),
				'few' => q(běloruské rubly),
				'many' => q(běloruského rublu),
				'one' => q(běloruský rubl),
				'other' => q(běloruských rublů),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(běloruský rubl \(2000–2016\)),
				'few' => q(běloruské rubly \(2000–2016\)),
				'many' => q(běloruského rublu \(2000–2016\)),
				'one' => q(běloruský rubl \(2000–2016\)),
				'other' => q(běloruských rublů \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(belizský dolar),
				'few' => q(belizské dolary),
				'many' => q(belizského dolaru),
				'one' => q(belizský dolar),
				'other' => q(belizských dolarů),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(kanadský dolar),
				'few' => q(kanadské dolary),
				'many' => q(kanadského dolaru),
				'one' => q(kanadský dolar),
				'other' => q(kanadských dolarů),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(konžský frank),
				'few' => q(konžské franky),
				'many' => q(konžského franku),
				'one' => q(konžský frank),
				'other' => q(konžských franků),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(švýcarské WIR-euro),
				'few' => q(švýcarská WIR-eura),
				'many' => q(švýcarského WIR-eura),
				'one' => q(švýcarské WIR-euro),
				'other' => q(švýcarských WIR-eur),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(švýcarský frank),
				'few' => q(švýcarské franky),
				'many' => q(švýcarského franku),
				'one' => q(švýcarský frank),
				'other' => q(švýcarských franků),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(švýcarský WIR-frank),
				'few' => q(švýcarské WIR-franky),
				'many' => q(švýcarského WIR-franku),
				'one' => q(švýcarský WIR-frank),
				'other' => q(švýcarských WIR-franků),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(chilské escudo),
				'few' => q(chilská escuda),
				'many' => q(chilského escuda),
				'one' => q(chilské escudo),
				'other' => q(chilských escud),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(chilská účetní jednotka \(UF\)),
				'few' => q(chilské účetní jednotky \(UF\)),
				'many' => q(chilské účetní jednotky \(UF\)),
				'one' => q(chilská účetní jednotka \(UF\)),
				'other' => q(chilských účetních jednotek \(UF\)),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(chilské peso),
				'few' => q(chilská pesa),
				'many' => q(chilského pesa),
				'one' => q(chilské peso),
				'other' => q(chilských pes),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(čínský jüan \(offshore\)),
				'few' => q(čínské jüany \(offshore\)),
				'many' => q(čínského jüanu \(offshore\)),
				'one' => q(čínský jüan \(offshore\)),
				'other' => q(čínských jüanů \(offshore\)),
			},
		},
		'CNX' => {
			symbol => 'CNX',
			display_name => {
				'currency' => q(čínský dolar ČLB),
				'few' => q(čínské dolary ČLB),
				'many' => q(čínského dolaru ČLB),
				'one' => q(čínský dolar ČLB),
				'other' => q(čínských dolarů ČLB),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(čínský jüan),
				'few' => q(čínské jüany),
				'many' => q(čínského jüanu),
				'one' => q(čínský jüan),
				'other' => q(čínských jüanů),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(kolumbijské peso),
				'few' => q(kolumbijská pesa),
				'many' => q(kolumbijského pesa),
				'one' => q(kolumbijské peso),
				'other' => q(kolumbijských pes),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(kolumbijská jednotka reálné hodnoty),
				'few' => q(kolumbijské jednotky reálné hodnoty),
				'many' => q(kolumbijské jednotky reálné hodnoty),
				'one' => q(kolumbijská jednotka reálné hodnoty),
				'other' => q(kolumbijských jednotek reálné hodnoty),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(kostarický colón),
				'few' => q(kostarické colóny),
				'many' => q(kostarického colónu),
				'one' => q(kostarický colón),
				'other' => q(kostarických colónů),
			},
		},
		'CSD' => {
			symbol => 'CSD',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubánské konvertibilní peso),
				'few' => q(kubánská konvertibilní pesa),
				'many' => q(kubánského konvertibilního pesa),
				'one' => q(kubánské konvertibilní peso),
				'other' => q(kubánských konvertibilních pes),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubánské peso),
				'few' => q(kubánská pesa),
				'many' => q(kubánského pesa),
				'one' => q(kubánské peso),
				'other' => q(kubánských pes),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(kapverdské escudo),
				'few' => q(kapverdská escuda),
				'many' => q(kapverdského escuda),
				'one' => q(kapverdské escudo),
				'other' => q(kapverdských escud),
			},
		},
		'CYP' => {
			symbol => 'CYP',
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
			symbol => 'DDM',
			display_name => {
				'currency' => q(východoněmecká marka),
				'few' => q(východoněmecké marky),
				'many' => q(východoněmecké marky),
				'one' => q(východoněmecká marka),
				'other' => q(východoněmeckých marek),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(německá marka),
				'few' => q(německé marky),
				'many' => q(německé marky),
				'one' => q(německá marka),
				'other' => q(německých marek),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(džibutský frank),
				'few' => q(džibutské franky),
				'many' => q(džibutského franku),
				'one' => q(džibutský frank),
				'other' => q(džibutských franků),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(dánská koruna),
				'few' => q(dánské koruny),
				'many' => q(dánské koruny),
				'one' => q(dánská koruna),
				'other' => q(dánských korun),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dominikánské peso),
				'few' => q(dominikánská pesa),
				'many' => q(dominikánského pesa),
				'one' => q(dominikánské peso),
				'other' => q(dominikánských pes),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(alžírský dinár),
				'few' => q(alžírské dináry),
				'many' => q(alžírského dináru),
				'one' => q(alžírský dinár),
				'other' => q(alžírských dinárů),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(ekvádorský sucre),
				'few' => q(ekvádorské sucre),
				'many' => q(ekvádorského sucre),
				'one' => q(ekvádorský sucre),
				'other' => q(ekvádorských sucre),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(ekvádorská jednotka konstantní hodnoty),
				'few' => q(ekvádorské jednotky konstantní hodnoty),
				'many' => q(ekvádorské jednotky konstantní hodnoty),
				'one' => q(ekvádorská jednotka konstantní hodnoty),
				'other' => q(ekvádorských jednotek konstantní hodnoty),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(estonská koruna),
				'few' => q(estonské koruny),
				'many' => q(estonské koruny),
				'one' => q(estonská koruna),
				'other' => q(estonských korun),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(egyptská libra),
				'few' => q(egyptské libry),
				'many' => q(egyptské libry),
				'one' => q(egyptská libra),
				'other' => q(egyptských liber),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(eritrejská nakfa),
				'few' => q(eritrejské nakfy),
				'many' => q(eritrejské nakfy),
				'one' => q(eritrejská nakfa),
				'other' => q(eritrejských nakf),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(španělská peseta \(„A“ účet\)),
				'few' => q(španělské pesety \(„A“ účet\)),
				'many' => q(španělské pesety \(„A“ účet\)),
				'one' => q(španělská peseta \(„A“ účet\)),
				'other' => q(španělských peset \(„A“ účet\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(španělská peseta \(konvertibilní účet\)),
				'few' => q(španělské pesety \(konvertibilní účet\)),
				'many' => q(španělské pesety \(konvertibilní účet\)),
				'one' => q(španělská peseta \(konvertibilní účet\)),
				'other' => q(španělských peset \(konvertibilní účet\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(španělská peseta),
				'few' => q(španělské pesety),
				'many' => q(španělské pesety),
				'one' => q(španělská peseta),
				'other' => q(španělských peset),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiopský birr),
				'few' => q(etiopské birry),
				'many' => q(etiopského birru),
				'one' => q(etiopský birr),
				'other' => q(etiopských birrů),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'few' => q(eura),
				'many' => q(eura),
				'one' => q(euro),
				'other' => q(eur),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(finská marka),
				'few' => q(finské marky),
				'many' => q(finské marky),
				'one' => q(finská marka),
				'other' => q(finských marek),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(fidžijský dolar),
				'few' => q(fidžijské dolary),
				'many' => q(fidžijského dolaru),
				'one' => q(fidžijský dolar),
				'other' => q(fidžijských dolarů),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(falklandská libra),
				'few' => q(falklandské libry),
				'many' => q(falklandské libry),
				'one' => q(falklandská libra),
				'other' => q(falklandských liber),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(francouzský frank),
				'few' => q(francouzské franky),
				'many' => q(francouzského franku),
				'one' => q(francouzský frank),
				'other' => q(francouzských franků),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(britská libra),
				'few' => q(britské libry),
				'many' => q(britské libry),
				'one' => q(britská libra),
				'other' => q(britských liber),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(gruzínské kuponové lari),
				'few' => q(gruzínské kuponové lari),
				'many' => q(gruzínského kuponového lari),
				'one' => q(gruzínské kuponové lari),
				'other' => q(gruzínských kuponových lari),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(gruzínské lari),
				'few' => q(gruzínské lari),
				'many' => q(gruzínského lari),
				'one' => q(gruzínské lari),
				'other' => q(gruzínských lari),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(ghanský cedi \(1979–2007\)),
				'few' => q(ghanské cedi \(1979–2007\)),
				'many' => q(ghanského cedi \(1979–2007\)),
				'one' => q(ghanský cedi \(1979–2007\)),
				'other' => q(ghanských cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ghanský cedi),
				'few' => q(ghanské cedi),
				'many' => q(ghanského cedi),
				'one' => q(ghanský cedi),
				'other' => q(ghanských cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltarská libra),
				'few' => q(gibraltarské libry),
				'many' => q(gibraltarské libry),
				'one' => q(gibraltarská libra),
				'other' => q(gibraltarských liber),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambijský dalasi),
				'few' => q(gambijské dalasi),
				'many' => q(gambijského dalasi),
				'one' => q(gambijský dalasi),
				'other' => q(gambijských dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(guinejský frank),
				'few' => q(guinejské franky),
				'many' => q(guinejského franku),
				'one' => q(guinejský frank),
				'other' => q(guinejských franků),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(guinejský syli),
				'few' => q(guinejské syli),
				'many' => q(guinejského syli),
				'one' => q(guinejský syli),
				'other' => q(guinejských syli),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(rovníkovoguinejský ekwele),
				'few' => q(rovníkovoguinejské ekwele),
				'many' => q(rovníkovoguinejského ekwele),
				'one' => q(rovníkovoguinejský ekwele),
				'other' => q(rovníkovoguinejských ekwele),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(řecká drachma),
				'few' => q(řecké drachmy),
				'many' => q(řecké drachmy),
				'one' => q(řecká drachma),
				'other' => q(řeckých drachem),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(guatemalský quetzal),
				'few' => q(guatemalské quetzaly),
				'many' => q(guatemalského quetzalu),
				'one' => q(guatemalský quetzal),
				'other' => q(guatemalských quetzalů),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(portugalskoguinejské escudo),
				'few' => q(portugalskoguinejská escuda),
				'many' => q(portugalskoguinejského escuda),
				'one' => q(portugalskoguinejské escudo),
				'other' => q(portugalskoguinejských escud),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(guinejsko-bissauské peso),
				'few' => q(guinejsko-bissauská pesa),
				'many' => q(guinejsko-bissauského pesa),
				'one' => q(guinejsko-bissauské peso),
				'other' => q(guinejsko-bissauských pes),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(guyanský dolar),
				'few' => q(guyanské dolary),
				'many' => q(guyanského dolaru),
				'one' => q(guyanský dolar),
				'other' => q(guyanských dolarů),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(hongkongský dolar),
				'few' => q(hongkongské dolary),
				'many' => q(hongkongského dolaru),
				'one' => q(hongkongský dolar),
				'other' => q(hongkongských dolarů),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(honduraská lempira),
				'few' => q(honduraské lempiry),
				'many' => q(honduraské lempiry),
				'one' => q(honduraská lempira),
				'other' => q(honduraských lempir),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(chorvatský dinár),
				'few' => q(chorvatské dináry),
				'many' => q(chorvatského dináru),
				'one' => q(chorvatský dinár),
				'other' => q(chorvatských dinárů),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(chorvatská kuna),
				'few' => q(chorvatské kuny),
				'many' => q(chorvatské kuny),
				'one' => q(chorvatská kuna),
				'other' => q(chorvatských kun),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haitský gourde),
				'few' => q(haitské gourde),
				'many' => q(haitského gourde),
				'one' => q(haitský gourde),
				'other' => q(haitských gourde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(maďarský forint),
				'few' => q(maďarské forinty),
				'many' => q(maďarského forintu),
				'one' => q(maďarský forint),
				'other' => q(maďarských forintů),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(indonéská rupie),
				'few' => q(indonéské rupie),
				'many' => q(indonéské rupie),
				'one' => q(indonéská rupie),
				'other' => q(indonéských rupií),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(irská libra),
				'few' => q(irské libry),
				'many' => q(irské libry),
				'one' => q(irská libra),
				'other' => q(irských liber),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(izraelská libra),
				'few' => q(izraelské libry),
				'many' => q(izraelské libry),
				'one' => q(izraelská libra),
				'other' => q(izraelských liber),
			},
		},
		'ILR' => {
			symbol => 'ILR',
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
				'other' => q(izraelských nový šekelů),
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
			symbol => 'IQD',
			display_name => {
				'currency' => q(irácký dinár),
				'few' => q(irácké dináry),
				'many' => q(iráckého dináru),
				'one' => q(irácký dinár),
				'other' => q(iráckých dinárů),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(íránský rijál),
				'few' => q(íránské rijály),
				'many' => q(íránského rijálu),
				'one' => q(íránský rijál),
				'other' => q(íránských rijálů),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(islandská koruna \(1918–1981\)),
				'few' => q(islandské koruny \(1918–1981\)),
				'many' => q(islandské koruny \(1918–1981\)),
				'one' => q(islandská koruna \(1918–1981\)),
				'other' => q(islandských korun \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(islandská koruna),
				'few' => q(islandské koruny),
				'many' => q(islandské koruny),
				'one' => q(islandská koruna),
				'other' => q(islandských korun),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(italská lira),
				'few' => q(italské liry),
				'many' => q(italské liry),
				'one' => q(italská lira),
				'other' => q(italských lir),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamajský dolar),
				'few' => q(jamajské dolary),
				'many' => q(jamajského dolaru),
				'one' => q(jamajský dolar),
				'other' => q(jamajských dolarů),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(jordánský dinár),
				'few' => q(jordánské dináry),
				'many' => q(jordánského dináru),
				'one' => q(jordánský dinár),
				'other' => q(jordánských dinárů),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(japonský jen),
				'few' => q(japonské jeny),
				'many' => q(japonského jenu),
				'one' => q(japonský jen),
				'other' => q(japonských jenů),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(keňský šilink),
				'few' => q(keňské šilinky),
				'many' => q(keňského šilinku),
				'one' => q(keňský šilink),
				'other' => q(keňských šilinků),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kyrgyzský som),
				'few' => q(kyrgyzské somy),
				'many' => q(kyrgyzského somu),
				'one' => q(kyrgyzský som),
				'other' => q(kyrgyzských somů),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambodžský riel),
				'few' => q(kambodžské riely),
				'many' => q(kambodžského rielu),
				'one' => q(kambodžský riel),
				'other' => q(kambodžských rielů),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(komorský frank),
				'few' => q(komorské franky),
				'many' => q(komorského franku),
				'one' => q(komorský frank),
				'other' => q(komorských franků),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(severokorejský won),
				'few' => q(severokorejské wony),
				'many' => q(severokorejského wonu),
				'one' => q(severokorejský won),
				'other' => q(severokorejských wonů),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(jihokorejský hwan \(1953–1962\)),
				'few' => q(jihokorejské hwany \(1953–1962\)),
				'many' => q(jihokorejského hwanu \(1953–1962\)),
				'one' => q(jihokorejský hwan \(1953–1962\)),
				'other' => q(jihokorejských hwanů \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(jihokorejský won \(1945–1953\)),
				'few' => q(jihokorejské wony \(1945–1953\)),
				'many' => q(jihokorejského wonu \(1945–1953\)),
				'one' => q(jihokorejský won \(1945–1953\)),
				'other' => q(jihokorejských wonů \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(jihokorejský won),
				'few' => q(jihokorejské wony),
				'many' => q(jihokorejského wonu),
				'one' => q(jihokorejský won),
				'other' => q(jihokorejských wonů),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuvajtský dinár),
				'few' => q(kuvajtské dináry),
				'many' => q(kuvajtského dináru),
				'one' => q(kuvajtský dinár),
				'other' => q(kuvajtských dinárů),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(kajmanský dolar),
				'few' => q(kajmanské dolary),
				'many' => q(kajmanského dolaru),
				'one' => q(kajmanský dolar),
				'other' => q(kajmanských dolarů),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kazašské tenge),
				'few' => q(kazašské tenge),
				'many' => q(kazašského tenge),
				'one' => q(kazašské tenge),
				'other' => q(kazašských tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laoský kip),
				'few' => q(laoské kipy),
				'many' => q(laoského kipu),
				'one' => q(laoský kip),
				'other' => q(laoských kipů),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanonská libra),
				'few' => q(libanonské libry),
				'many' => q(libanonské libry),
				'one' => q(libanonská libra),
				'other' => q(libanonských liber),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(srílanská rupie),
				'few' => q(srílanské rupie),
				'many' => q(srílanské rupie),
				'one' => q(srílanská rupie),
				'other' => q(srílanských rupií),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(liberijský dolar),
				'few' => q(liberijské dolary),
				'many' => q(liberijského dolaru),
				'one' => q(liberijský dolar),
				'other' => q(liberijských dolarů),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(lesothský loti),
				'few' => q(lesothské maloti),
				'many' => q(lesothského loti),
				'one' => q(lesothský loti),
				'other' => q(lesothských maloti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(litevský litas),
				'few' => q(litevské lity),
				'many' => q(litevského litu),
				'one' => q(litevský litas),
				'other' => q(litevských litů),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(litevský talonas),
				'few' => q(litevské talony),
				'many' => q(litevského talonu),
				'one' => q(litevský talonas),
				'other' => q(litevských talonů),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(lucemburský konvertibilní frank),
				'few' => q(lucemburské konvertibilní franky),
				'many' => q(lucemburského konvertibilního franku),
				'one' => q(lucemburský konvertibilní frank),
				'other' => q(lucemburských konvertibilních franků),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(lucemburský frank),
				'few' => q(lucemburské franky),
				'many' => q(lucemburského franku),
				'one' => q(lucemburský frank),
				'other' => q(lucemburských franků),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(lucemburský finanční frank),
				'few' => q(lucemburské finanční franky),
				'many' => q(lucemburského finančního franku),
				'one' => q(lucemburský finanční frank),
				'other' => q(lucemburských finančních franků),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(lotyšský lat),
				'few' => q(lotyšské laty),
				'many' => q(lotyšského latu),
				'one' => q(lotyšský lat),
				'other' => q(lotyšských latů),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(lotyšský rubl),
				'few' => q(lotyšské rubly),
				'many' => q(lotyšského rublu),
				'one' => q(lotyšský rubl),
				'other' => q(lotyšských rublů),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(libyjský dinár),
				'few' => q(libyjské dináry),
				'many' => q(libyjského dináru),
				'one' => q(libyjský dinár),
				'other' => q(libyjských dinárů),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(marocký dinár),
				'few' => q(marocké dináry),
				'many' => q(marockého dináru),
				'one' => q(marocký dinár),
				'other' => q(marockých dinárů),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(marocký frank),
				'few' => q(marocké franky),
				'many' => q(marockého franku),
				'one' => q(marocký frank),
				'other' => q(marockých franků),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(monacký frank),
				'few' => q(monacké franky),
				'many' => q(monackého franku),
				'one' => q(monacký frank),
				'other' => q(monackých franků),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(moldavský kupon),
				'few' => q(moldavské kupony),
				'many' => q(moldavského kuponu),
				'one' => q(moldavský kupon),
				'other' => q(moldavských kuponů),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldavský leu),
				'few' => q(moldavské lei),
				'many' => q(moldavského leu),
				'one' => q(moldavský leu),
				'other' => q(moldavských lei),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(madagaskarský ariary),
				'few' => q(madagaskarské ariary),
				'many' => q(madagaskarského ariary),
				'one' => q(madagaskarský ariary),
				'other' => q(madagaskarských ariary),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(madagaskarský frank),
				'few' => q(madagaskarské franky),
				'many' => q(madagaskarského franku),
				'one' => q(madagaskarský frank),
				'other' => q(madagaskarských franků),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(makedonský denár),
				'few' => q(makedonské denáry),
				'many' => q(makedonského denáru),
				'one' => q(makedonský denár),
				'other' => q(makedonských denárů),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(makedonský denár \(1992–1993\)),
				'few' => q(makedonské denáry \(1992–1993\)),
				'many' => q(makedonského denáru \(1992–1993\)),
				'one' => q(makedonský denár \(1992–1993\)),
				'other' => q(makedonských denárů \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(malijský frank),
				'few' => q(malijské franky),
				'many' => q(malijského franku),
				'one' => q(malijský frank),
				'other' => q(malijských franků),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(myanmarský kyat),
				'few' => q(myanmarské kyaty),
				'many' => q(myanmarského kyatu),
				'one' => q(myanmarský kyat),
				'other' => q(myanmarských kyatů),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongolský tugrik),
				'few' => q(mongolské tugriky),
				'many' => q(mongolského tugriku),
				'one' => q(mongolský tugrik),
				'other' => q(mongolských tugriků),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(macajská pataca),
				'few' => q(macajské patacy),
				'many' => q(macajské patacy),
				'one' => q(macajská pataca),
				'other' => q(macajských patac),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(mauritánská ouguiya \(1973–2017\)),
				'few' => q(mauritánské ouguiye \(1973–2017\)),
				'many' => q(mauritánské ouguiye \(1973–2017\)),
				'one' => q(mauritánská ouguiya \(1973–2017\)),
				'other' => q(mauritánských ouguiyí \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(mauritánská ouguiya),
				'few' => q(mauritánské ouguiye),
				'many' => q(mauritánské ouguiye),
				'one' => q(mauritánská ouguiya),
				'other' => q(mauritánských ouguiyí),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(maltská lira),
				'few' => q(maltské liry),
				'many' => q(maltské liry),
				'one' => q(maltská lira),
				'other' => q(maltských lir),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(maltská libra),
				'few' => q(maltské libry),
				'many' => q(maltské libry),
				'one' => q(maltská libra),
				'other' => q(maltských liber),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(mauricijská rupie),
				'few' => q(mauricijské rupie),
				'many' => q(mauricijské rupie),
				'one' => q(mauricijská rupie),
				'other' => q(mauricijských rupií),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(maledivská rupie \(1947–1981\)),
				'few' => q(maledivské rupie \(1947–1981\)),
				'many' => q(maledivské rupie \(1947–1981\)),
				'one' => q(maledivská rupie \(1947–1981\)),
				'other' => q(maledivských rupií \(1947–1981\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maledivská rupie),
				'few' => q(maledivské rupie),
				'many' => q(maledivské rupie),
				'one' => q(maledivská rupie),
				'other' => q(maledivských rupií),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(malawijská kwacha),
				'few' => q(malawijské kwachy),
				'many' => q(malawijské kwachy),
				'one' => q(malawijská kwacha),
				'other' => q(malawijských kwach),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(mexické peso),
				'few' => q(mexická pesa),
				'many' => q(mexického pesa),
				'one' => q(mexické peso),
				'other' => q(mexických pes),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(mexické stříbrné peso \(1861–1992\)),
				'few' => q(mexická stříbrná pesa \(1861–1992\)),
				'many' => q(mexického stříbrného pesa \(1861–1992\)),
				'one' => q(mexické stříbrné peso \(1861–1992\)),
				'other' => q(mexických stříbrných pes \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(mexická investiční jednotka),
				'few' => q(mexické investiční jednotky),
				'many' => q(mexické investiční jednotky),
				'one' => q(mexická investiční jednotka),
				'other' => q(mexických investičních jednotek),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(malajsijský ringgit),
				'few' => q(malajsijské ringgity),
				'many' => q(malajsijského ringgitu),
				'one' => q(malajsijský ringgit),
				'other' => q(malajsijských ringgitů),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(mosambický escudo),
				'few' => q(mosambická escuda),
				'many' => q(mosambického escuda),
				'one' => q(mosambický escudo),
				'other' => q(mosambických escud),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(mosambický metical \(1980–2006\)),
				'few' => q(mosambické meticaly \(1980–2006\)),
				'many' => q(mosambického meticalu \(1980–2006\)),
				'one' => q(mosambický metical \(1980–2006\)),
				'other' => q(mosambických meticalů \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(mozambický metical),
				'few' => q(mozambické meticaly),
				'many' => q(mozambického meticalu),
				'one' => q(mozambický metical),
				'other' => q(mozambických meticalů),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namibijský dolar),
				'few' => q(namibijské dolary),
				'many' => q(namibijského dolaru),
				'one' => q(namibijský dolar),
				'other' => q(namibijských dolarů),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(nigerijská naira),
				'few' => q(nigerijské nairy),
				'many' => q(nigerijské nairy),
				'one' => q(nigerijská naira),
				'other' => q(nigerijských nair),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(nikaragujská córdoba \(1988–1991\)),
				'few' => q(nikaragujské córdoby \(1988–1991\)),
				'many' => q(nikaragujské córdoby \(1988–1991\)),
				'one' => q(nikaragujská córdoba \(1988–1991\)),
				'other' => q(nikaragujských córdob \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(nikaragujská córdoba),
				'few' => q(nikaragujské córdoby),
				'many' => q(nikaragujské córdoby),
				'one' => q(nikaragujská córdoba),
				'other' => q(nikaragujských córdob),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(nizozemský gulden),
				'few' => q(nizozemské guldeny),
				'many' => q(nizozemského guldenu),
				'one' => q(nizozemský gulden),
				'other' => q(nizozemských guldenů),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(norská koruna),
				'few' => q(norské koruny),
				'many' => q(norské koruny),
				'one' => q(norská koruna),
				'other' => q(norských korun),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(nepálská rupie),
				'few' => q(nepálské rupie),
				'many' => q(nepálské rupie),
				'one' => q(nepálská rupie),
				'other' => q(nepálských rupií),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(novozélandský dolar),
				'few' => q(novozélandské dolary),
				'many' => q(novozélandského dolaru),
				'one' => q(novozélandský dolar),
				'other' => q(novozélandských dolarů),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(ománský rijál),
				'few' => q(ománské rijály),
				'many' => q(ománského rijálu),
				'one' => q(ománský rijál),
				'other' => q(ománských rijálů),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(panamská balboa),
				'few' => q(panamské balboy),
				'many' => q(panamské balboy),
				'one' => q(panamská balboa),
				'other' => q(panamských balboí),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(peruánská inti),
				'few' => q(peruánské inti),
				'many' => q(peruánské inti),
				'one' => q(peruánská inti),
				'other' => q(peruánských inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(peruánský sol),
				'few' => q(peruánské soly),
				'many' => q(peruánského solu),
				'one' => q(peruánský sol),
				'other' => q(peruánských solů),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(peruánský sol \(1863–1965\)),
				'few' => q(peruánské soly \(1863–1965\)),
				'many' => q(peruánského solu \(1863–1965\)),
				'one' => q(peruánský sol \(1863–1965\)),
				'other' => q(peruánských solů \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(pákistánská rupie),
				'few' => q(pákistánské rupie),
				'many' => q(pákistánské rupie),
				'one' => q(pákistánská rupie),
				'other' => q(pákistánských rupií),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(polský zlotý),
				'few' => q(polské zloté),
				'many' => q(polského zlotého),
				'one' => q(polský zlotý),
				'other' => q(polských zlotých),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(polský zlotý \(1950–1995\)),
				'few' => q(polské zloté \(1950–1995\)),
				'many' => q(polského zlotého \(1950–1995\)),
				'one' => q(polský zlotý \(1950–1995\)),
				'other' => q(polských zlotých \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(portugalské escudo),
				'few' => q(portugalská escuda),
				'many' => q(portugalského escuda),
				'one' => q(portugalské escudo),
				'other' => q(portugalských escud),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(paraguajské guarani),
				'few' => q(paraguajská guarani),
				'many' => q(paraguajského guarani),
				'one' => q(paraguajské guarani),
				'other' => q(paraguajských guarani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(katarský rijál),
				'few' => q(katarské rijály),
				'many' => q(katarského rijálu),
				'one' => q(katarský rijál),
				'other' => q(katarských rijálů),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(rhodéský dolar),
				'few' => q(rhodéské dolary),
				'many' => q(rhodéského dolaru),
				'one' => q(rhodéský dolar),
				'other' => q(rhodéských dolarů),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(rumunské leu \(1952–2006\)),
				'few' => q(rumunské lei \(1952–2006\)),
				'many' => q(rumunského leu \(1952–2006\)),
				'one' => q(rumunské leu \(1952–2006\)),
				'other' => q(rumunských lei \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(rumunský leu),
				'few' => q(rumunské lei),
				'many' => q(rumunského leu),
				'one' => q(rumunský leu),
				'other' => q(rumunských lei),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(srbský dinár),
				'few' => q(srbské dináry),
				'many' => q(srbského dináru),
				'one' => q(srbský dinár),
				'other' => q(srbských dinárů),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(ruský rubl),
				'few' => q(ruské rubly),
				'many' => q(ruského rublu),
				'one' => q(ruský rubl),
				'other' => q(ruských rublů),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(ruský rubl \(1991–1998\)),
				'few' => q(ruské rubly \(1991–1998\)),
				'many' => q(ruského rublu \(1991–1998\)),
				'one' => q(ruský rubl \(1991–1998\)),
				'other' => q(ruských rublů \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(rwandský frank),
				'few' => q(rwandské franky),
				'many' => q(rwandského franku),
				'one' => q(rwandský frank),
				'other' => q(rwandských franků),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(saúdský rijál),
				'few' => q(saúdské rijály),
				'many' => q(saúdského rijálu),
				'one' => q(saúdský rijál),
				'other' => q(saúdských rijálů),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(šalamounský dolar),
				'few' => q(šalamounské dolary),
				'many' => q(šalamounského dolaru),
				'one' => q(šalamounský dolar),
				'other' => q(šalamounských dolarů),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(seychelská rupie),
				'few' => q(seychelské rupie),
				'many' => q(seychelské rupie),
				'one' => q(seychelská rupie),
				'other' => q(seychelských rupií),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(súdánský dinár \(1992–2007\)),
				'few' => q(súdánské dináry \(1992–2007\)),
				'many' => q(súdánského dináru \(1992–2007\)),
				'one' => q(súdánský dinár \(1992–2007\)),
				'other' => q(súdánských dinárů \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(súdánská libra),
				'few' => q(súdánské libry),
				'many' => q(súdánské libry),
				'one' => q(súdánská libra),
				'other' => q(súdánských liber),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(súdánská libra \(1957–1998\)),
				'few' => q(súdánské libry \(1957–1998\)),
				'many' => q(súdánské libry \(1957–1998\)),
				'one' => q(súdánská libra \(1957–1998\)),
				'other' => q(súdánských liber \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(švédská koruna),
				'few' => q(švédské koruny),
				'many' => q(švédské koruny),
				'one' => q(švédská koruna),
				'other' => q(švédských korun),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(singapurský dolar),
				'few' => q(singapurské dolary),
				'many' => q(singapurského dolaru),
				'one' => q(singapurský dolar),
				'other' => q(singapurských dolarů),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(svatohelenská libra),
				'few' => q(svatohelenské libry),
				'many' => q(svatohelenské libry),
				'one' => q(svatohelenská libra),
				'other' => q(svatohelenských liber),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(slovinský tolar),
				'few' => q(slovinské tolary),
				'many' => q(slovinského tolaru),
				'one' => q(slovinský tolar),
				'other' => q(slovinských tolarů),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(slovenská koruna),
				'few' => q(slovenské koruny),
				'many' => q(slovenské koruny),
				'one' => q(slovenská koruna),
				'other' => q(slovenských korun),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(sierro-leonský leone),
				'few' => q(sierro-leonské leone),
				'many' => q(sierro-leonského leone),
				'one' => q(sierro-leonský leone),
				'other' => q(sierro-leonských leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(somálský šilink),
				'few' => q(somálské šilinky),
				'many' => q(somálského šilinku),
				'one' => q(somálský šilink),
				'other' => q(somálských šilinků),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(surinamský dolar),
				'few' => q(surinamské dolary),
				'many' => q(surinamského dolaru),
				'one' => q(surinamský dolar),
				'other' => q(surinamských dolarů),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(surinamský zlatý),
				'few' => q(surinamské zlaté),
				'many' => q(surinamského zlatého),
				'one' => q(surinamský zlatý),
				'other' => q(surinamských zlatých),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(jihosúdánská libra),
				'few' => q(jihosúdánské libry),
				'many' => q(jihosúdánské libry),
				'one' => q(jihosúdánská libra),
				'other' => q(jihosúdánských liber),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(svatotomášská dobra \(1977–2017\)),
				'few' => q(svatotomášské dobry \(1977–2017\)),
				'many' => q(svatotomášské dobry \(1977–2017\)),
				'one' => q(svatotomášská dobra \(1977–2017\)),
				'other' => q(svatotomášských dober \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(svatotomášská dobra),
				'few' => q(svatotomášské dobry),
				'many' => q(svatotomášské dobry),
				'one' => q(svatotomášská dobra),
				'other' => q(svatotomášských dober),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(sovětský rubl),
				'few' => q(sovětské rubly),
				'many' => q(sovětského rublu),
				'one' => q(sovětský rubl),
				'other' => q(sovětských rublů),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(salvadorský colón),
				'few' => q(salvadorské colóny),
				'many' => q(salvadorského colónu),
				'one' => q(salvadorský colón),
				'other' => q(salvadorských colónů),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(syrská libra),
				'few' => q(syrské libry),
				'many' => q(syrské libry),
				'one' => q(syrská libra),
				'other' => q(syrských liber),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(svazijský lilangeni),
				'few' => q(svazijské emalangeni),
				'many' => q(svazijského lilangeni),
				'one' => q(svazijský lilangeni),
				'other' => q(svazijských emalangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(thajský baht),
				'few' => q(thajské bahty),
				'many' => q(thajského bahtu),
				'one' => q(thajský baht),
				'other' => q(thajských bahtů),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(tádžický rubl),
				'few' => q(tádžické rubly),
				'many' => q(tádžického rublu),
				'one' => q(tádžický rubl),
				'other' => q(tádžických rublů),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(tádžické somoni),
				'few' => q(tádžická somoni),
				'many' => q(tádžického somoni),
				'one' => q(tádžické somoni),
				'other' => q(tádžických somoni),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(turkmenský manat \(1993–2009\)),
				'few' => q(turkmenské manaty \(1993–2009\)),
				'many' => q(turkmenského manatu \(1993–2009\)),
				'one' => q(turkmenský manat \(1993–2009\)),
				'other' => q(turkmenských manatů \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(turkmenský manat),
				'few' => q(turkmenské manaty),
				'many' => q(turkmenského manatu),
				'one' => q(turkmenský manat),
				'other' => q(turkmenských manatů),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tuniský dinár),
				'few' => q(tuniské dináry),
				'many' => q(tuniského dináru),
				'one' => q(tuniský dinár),
				'other' => q(tuniských dinárů),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(tonžská paanga),
				'few' => q(tonžské paangy),
				'many' => q(tonžské paangy),
				'one' => q(tonžská paanga),
				'other' => q(tonžských paang),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(timorské escudo),
				'few' => q(timorská escuda),
				'many' => q(timorského escuda),
				'one' => q(timorské escudo),
				'other' => q(timorských escud),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(turecká lira \(1922–2005\)),
				'few' => q(turecké liry \(1922–2005\)),
				'many' => q(turecké liry \(1922–2005\)),
				'one' => q(turecká lira \(1922–2005\)),
				'other' => q(tureckých lir \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(turecká lira),
				'few' => q(turecké liry),
				'many' => q(turecké liry),
				'one' => q(turecká lira),
				'other' => q(tureckých lir),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzanský šilink),
				'few' => q(tanzanské šilinky),
				'many' => q(tanzanského šilinku),
				'one' => q(tanzanský šilink),
				'other' => q(tanzanských šilinků),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(ukrajinská hřivna),
				'few' => q(ukrajinské hřivny),
				'many' => q(ukrajinské hřivny),
				'one' => q(ukrajinská hřivna),
				'other' => q(ukrajinských hřiven),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(ukrajinský karbovanec),
				'few' => q(ukrajinské karbovance),
				'many' => q(ukrajinského karbovance),
				'one' => q(ukrajinský karbovanec),
				'other' => q(ukrajinských karbovanců),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(ugandský šilink \(1966–1987\)),
				'few' => q(ugandské šilinky \(1966–1987\)),
				'many' => q(ugandského šilinku \(1966–1987\)),
				'one' => q(ugandský šilink \(1966–1987\)),
				'other' => q(ugandských šilinků \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(ugandský šilink),
				'few' => q(ugandské šilinky),
				'many' => q(ugandského šilinku),
				'one' => q(ugandský šilink),
				'other' => q(ugandských šilinků),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(americký dolar),
				'few' => q(americké dolary),
				'many' => q(amerického dolaru),
				'one' => q(americký dolar),
				'other' => q(amerických dolarů),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(americký dolar \(příští den\)),
				'few' => q(americké dolary \(příští den\)),
				'many' => q(amerického dolaru \(příští den\)),
				'one' => q(americký dolar \(příští den\)),
				'other' => q(amerických dolarů \(příští den\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(americký dolar \(týž den\)),
				'few' => q(americké dolary \(týž den\)),
				'many' => q(amerického dolaru \(týž den\)),
				'one' => q(americký dolar \(týž den\)),
				'other' => q(amerických dolarů \(týž den\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(uruguayské peso \(v indexovaných jednotkách\)),
				'few' => q(uruguayská pesa \(v indexovaných jednotkách\)),
				'many' => q(uruguayského pesa \(v indexovaných jednotkách\)),
				'one' => q(uruguayské peso \(v indexovaných jednotkách\)),
				'other' => q(uruguayských pes \(v indexovaných jednotkách\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(uruguayské peso \(1975–1993\)),
				'few' => q(uruguayská pesa \(1975–1993\)),
				'many' => q(uruguayského pesa \(1975–1993\)),
				'one' => q(uruguayské peso \(1975–1993\)),
				'other' => q(uruguayských pes \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(uruguayské peso),
				'few' => q(uruguayská pesa),
				'many' => q(uruguayského pesa),
				'one' => q(uruguayské peso),
				'other' => q(uruguayských pes),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(uzbecký sum),
				'few' => q(uzbecké sumy),
				'many' => q(uzbeckého sumu),
				'one' => q(uzbecký sum),
				'other' => q(uzbeckých sumů),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(venezuelský bolívar \(1871–2008\)),
				'few' => q(venezuelské bolívary \(1871–2008\)),
				'many' => q(venezuelského bolívaru \(1871–2008\)),
				'one' => q(venezuelský bolívar \(1871–2008\)),
				'other' => q(venezuelských bolívarů \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(venezuelský bolívar \(2008–2018\)),
				'few' => q(venezuelské bolívary \(2008–2018\)),
				'many' => q(venezuelského bolívaru \(2008–2018\)),
				'one' => q(venezuelský bolívar \(2008–2018\)),
				'other' => q(venezuelských bolívarů \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
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
			symbol => 'VNN',
			display_name => {
				'currency' => q(vietnamský dong \(1978–1985\)),
				'few' => q(vietnamské dongy \(1978–1985\)),
				'many' => q(vietnamského dongu \(1978–1985\)),
				'one' => q(vietnamský dong \(1978–1985\)),
				'other' => q(vietnamských dongů \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatský vatu),
				'few' => q(vanuatské vatu),
				'many' => q(vanuatského vatu),
				'one' => q(vanuatský vatu),
				'other' => q(vanuatských vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(samojská tala),
				'few' => q(samojské taly),
				'many' => q(samojské taly),
				'one' => q(samojská tala),
				'other' => q(samojských tal),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA/BEAC frank),
				'few' => q(CFA/BEAC franky),
				'many' => q(CFA/BEAC franku),
				'one' => q(CFA/BEAC frank),
				'other' => q(CFA/BEAC franků),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(stříbro),
				'few' => q(trojské unce stříbra),
				'many' => q(trojské unce stříbra),
				'one' => q(trojská unce stříbra),
				'other' => q(trojských uncí stříbra),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(zlato),
				'few' => q(trojské unce zlata),
				'many' => q(trojské unce zlata),
				'one' => q(trojská unce zlata),
				'other' => q(trojských uncí zlata),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(evropská smíšená jednotka),
				'few' => q(evropské smíšené jednotky),
				'many' => q(evropské smíšené jednotky),
				'one' => q(evropská smíšená jednotka),
				'other' => q(evropských smíšených jednotek),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(evropská peněžní jednotka),
				'few' => q(evropské peněžní jednotky),
				'many' => q(evropské peněžní jednotky),
				'one' => q(evropská peněžní jednotka),
				'other' => q(evropských peněžních jednotek),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(evropská jednotka účtu 9 \(XBC\)),
				'few' => q(evropské jednotky účtu 9 \(XBC\)),
				'many' => q(evropské jednotky účtu 9 \(XBC\)),
				'one' => q(evropská jednotka účtu 9 \(XBC\)),
				'other' => q(evropských jednotek účtu 9 \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(evropská jednotka účtu 17 \(XBD\)),
				'few' => q(evropské jednotky účtu 17 \(XBD\)),
				'many' => q(evropské jednotky účtu 17 \(XBD\)),
				'one' => q(evropská jednotka účtu 17 \(XBD\)),
				'other' => q(evropských jednotek účtu 17 \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(východokaribský dolar),
				'few' => q(východokaribské dolary),
				'many' => q(východokaribského dolaru),
				'one' => q(východokaribský dolar),
				'other' => q(východokaribských dolarů),
			},
		},
		'XDR' => {
			symbol => 'XDR',
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
			symbol => 'XFO',
			display_name => {
				'currency' => q(francouzský zlatý frank),
				'few' => q(francouzské zlaté franky),
				'many' => q(francouzského zlatého franku),
				'one' => q(francouzský zlatý frank),
				'other' => q(francouzských zlatých franků),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(francouzský UIC frank),
				'few' => q(francouzské UIC franky),
				'many' => q(francouzského UIC franku),
				'one' => q(francouzský UIC frank),
				'other' => q(francouzských UIC franků),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA/BCEAO frank),
				'few' => q(CFA/BCEAO franky),
				'many' => q(CFA/BCEAO franku),
				'one' => q(CFA/BCEAO frank),
				'other' => q(CFA/BCEAO franků),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(palladium),
				'few' => q(trojské unce palladia),
				'many' => q(trojské unce palladia),
				'one' => q(trojská unce palladia),
				'other' => q(trojských uncí palladia),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP frank),
				'few' => q(CFP franky),
				'many' => q(CFP franku),
				'one' => q(CFP frank),
				'other' => q(CFP franků),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(platina),
				'few' => q(trojské unce platiny),
				'many' => q(trojské unce platiny),
				'one' => q(trojská unce platiny),
				'other' => q(trojských uncí platiny),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(kód fondů RINET),
				'few' => q(kód fondů RINET),
				'many' => q(kód fondů RINET),
				'one' => q(kód fondů RINET),
				'other' => q(kód fondů RINET),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(sucre),
				'few' => q(sucre),
				'many' => q(sucre),
				'one' => q(sucre),
				'other' => q(sucre),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(kód zvlášť vyhrazený pro testovací účely),
				'few' => q(kódy zvlášť vyhrazené pro testovací účely),
				'many' => q(kódu zvlášť vyhrazeného pro testovací účely),
				'one' => q(kód zvlášť vyhrazený pro testovací účely),
				'other' => q(kódů zvlášť vyhrazených pro testovací účely),
			},
		},
		'XUA' => {
			symbol => 'XUA',
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(neznámá měna),
				'few' => q(neznámá měna),
				'many' => q(neznámá měna),
				'one' => q(neznámá měna),
				'other' => q(neznámá měna),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(jemenský dinár),
				'few' => q(jemenské dináry),
				'many' => q(jemenského dináru),
				'one' => q(jemenský dinár),
				'other' => q(jemenských dinárů),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(jemenský rijál),
				'few' => q(jemenské rijály),
				'many' => q(jemenského rijálu),
				'one' => q(jemenský rijál),
				'other' => q(jemenských rijálů),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(jugoslávský dinár \(1966–1990\)),
				'few' => q(jugoslávské dináry \(1966–1990\)),
				'many' => q(jugoslávského dináru \(1966–1990\)),
				'one' => q(jugoslávský dinár \(1966–1990\)),
				'other' => q(jugoslávských dinárů \(1966–1990\)),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(jugoslávský nový dinár \(1994–2002\)),
				'few' => q(jugoslávské nové dináry \(1994–2002\)),
				'many' => q(jugoslávského nového dináru \(1994–2002\)),
				'one' => q(jugoslávský nový dinár \(1994–2002\)),
				'other' => q(jugoslávských nových dinárů \(1994–2002\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(jugoslávský konvertibilní dinár \(1990–1992\)),
				'few' => q(jugoslávské konvertibilní dináry \(1990–1992\)),
				'many' => q(jugoslávského konvertibilního dináru \(1990–1992\)),
				'one' => q(jugoslávský konvertibilní dinár \(1990–1992\)),
				'other' => q(jugoslávských konvertibilních dinárů \(1990–1992\)),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(jugoslávský reformovaný dinár \(1992–1993\)),
				'few' => q(jugoslávské reformované dináry \(1992–1993\)),
				'many' => q(jugoslávského reformovaného dináru \(1992–1993\)),
				'one' => q(jugoslávský reformovaný dinár \(1992–1993\)),
				'other' => q(jugoslávských reformovaných dinárů \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(jihoafrický finanční rand),
				'few' => q(jihoafrické finanční randy),
				'many' => q(jihoafrického finančního randu),
				'one' => q(jihoafrický finanční rand),
				'other' => q(jihoafrických finančních randů),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(jihoafrický rand),
				'few' => q(jihoafrické randy),
				'many' => q(jihoafrického randu),
				'one' => q(jihoafrický rand),
				'other' => q(jihoafrických randů),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(zambijská kwacha \(1968–2012\)),
				'few' => q(zambijské kwachy \(1968–2012\)),
				'many' => q(zambijské kwachy \(1968–2012\)),
				'one' => q(zambijská kwacha \(1968–2012\)),
				'other' => q(zambijských kwach \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(zambijská kwacha),
				'few' => q(zambijské kwachy),
				'many' => q(zambijské kwachy),
				'one' => q(zambijská kwacha),
				'other' => q(zambijských kwach),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(zairský nový zaire \(1993–1998\)),
				'few' => q(zairské nové zairy \(1993–1998\)),
				'many' => q(zairského nového zairu \(1993–1998\)),
				'one' => q(zairský nový zaire \(1993–1998\)),
				'other' => q(zairských nových zairů \(1993–1998\)),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(zairský zaire \(1971–1993\)),
				'few' => q(zairské zairy \(1971–1993\)),
				'many' => q(zairského zairu \(1971–1993\)),
				'one' => q(zairský zaire \(1971–1993\)),
				'other' => q(zairských zairů \(1971–1993\)),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(zimbabwský dolar \(1980–2008\)),
				'few' => q(zimbabwské dolary \(1980–2008\)),
				'many' => q(zimbabwského dolaru \(1980–2008\)),
				'one' => q(zimbabwský dolar \(1980–2008\)),
				'other' => q(zimbabwských dolarů \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(zimbabwský dolar \(2009\)),
				'few' => q(zimbabwské dolary \(2009\)),
				'many' => q(zimbabwského dolaru \(2009\)),
				'one' => q(zimbabwský dolar \(2009\)),
				'other' => q(zimbabwských dolarů \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
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
			'chinese' => {
				'format' => {
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
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
				'stand-alone' => {
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
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
					abbreviated => {
						nonleap => [
							'M01',
							'M02',
							'M03',
							'M04',
							'M05',
							'M06',
							'M07',
							'M08',
							'M09',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
					abbreviated => {
						nonleap => [
							'M01',
							'M02',
							'M03',
							'M04',
							'M05',
							'M06',
							'M07',
							'M08',
							'M09',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
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
				'stand-alone' => {
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
					abbreviated => {
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adar II'
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adar II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adar II'
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adar II'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
				'stand-alone' => {
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
				'stand-alone' => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
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
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
				'stand-alone' => {
					abbreviated => {
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
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
					narrow => {
						mon => 'P',
						tue => 'Ú',
						wed => 'S',
						thu => 'Č',
						fri => 'P',
						sat => 'S',
						sun => 'N'
					},
					short => {
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
					abbreviated => {
						mon => 'po',
						tue => 'út',
						wed => 'st',
						thu => 'čt',
						fri => 'pá',
						sat => 'so',
						sun => 'ne'
					},
					narrow => {
						mon => 'P',
						tue => 'Ú',
						wed => 'S',
						thu => 'Č',
						fri => 'P',
						sat => 'S',
						sun => 'N'
					},
					short => {
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. čtvrtletí',
						1 => '2. čtvrtletí',
						2 => '3. čtvrtletí',
						3 => '4. čtvrtletí'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'buddhist') {
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
					'am' => q{dop.},
					'evening1' => q{v.},
					'midnight' => q{půl.},
					'morning1' => q{r.},
					'morning2' => q{d.},
					'night1' => q{n.},
					'noon' => q{pol.},
					'pm' => q{odp.},
				},
				'wide' => {
					'afternoon1' => q{odpoledne},
					'am' => q{dop.},
					'evening1' => q{večer},
					'midnight' => q{půlnoc},
					'morning1' => q{ráno},
					'morning2' => q{dopoledne},
					'night1' => q{v noci},
					'noon' => q{poledne},
					'pm' => q{odp.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{odpoledne},
					'am' => q{dop.},
					'evening1' => q{večer},
					'midnight' => q{půlnoc},
					'morning1' => q{ráno},
					'morning2' => q{dopoledne},
					'night1' => q{noc},
					'noon' => q{poledne},
					'pm' => q{odp.},
				},
				'narrow' => {
					'afternoon1' => q{odp.},
					'am' => q{dop.},
					'evening1' => q{več.},
					'midnight' => q{půl.},
					'morning1' => q{ráno},
					'morning2' => q{dop.},
					'night1' => q{noc},
					'noon' => q{pol.},
					'pm' => q{odp.},
				},
				'wide' => {
					'afternoon1' => q{odpoledne},
					'am' => q{dop.},
					'evening1' => q{večer},
					'midnight' => q{půlnoc},
					'morning1' => q{ráno},
					'morning2' => q{dopoledne},
					'night1' => q{noc},
					'noon' => q{poledne},
					'pm' => q{odp.},
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
			narrow => {
				'0' => 'BE'
			},
			wide => {
				'0' => 'BE'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'dangi' => {
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
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
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'AM'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Šaka'
			},
			narrow => {
				'0' => 'Šaka'
			},
			wide => {
				'0' => 'Šaka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'AH'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei'
			},
			narrow => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'M',
				'233' => 'T',
				'234' => 'S',
				'235' => 'H'
			},
			wide => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			narrow => {
				'0' => 'AP'
			},
			wide => {
				'0' => 'AP'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'před ROC',
				'1' => 'ROC'
			},
			narrow => {
				'0' => 'před ROC',
				'1' => 'ROC'
			},
			wide => {
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
		'buddhist' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'chinese' => {
			'full' => q{EEEE, d. M. y},
			'long' => q{d. M. y},
			'medium' => q{d. M. y},
			'short' => q{d. M. y},
		},
		'coptic' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'dangi' => {
		},
		'ethiopic' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
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
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'indian' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'islamic' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'japanese' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'persian' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'roc' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. M. y G},
			'short' => q{dd.MM.yy GGGGG},
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
			'full' => q{H:mm:ss zzzz},
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
		'buddhist' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'chinese' => {
		},
		'coptic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'dangi' => {
		},
		'ethiopic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'indian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'islamic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'japanese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'persian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'roc' => {
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
		'buddhist' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'coptic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'ethiopic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmv => q{H:mm v},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMW => q{W. 'týden' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
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
		'hebrew' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'indian' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'islamic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'japanese' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'persian' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMEd => q{E d. MMMM y G},
			GyMMMMd => q{d. MMMM y G},
			GyMMMd => q{d. M. y G},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
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
		'buddhist' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'coptic' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'ethiopic' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'generic' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y},
				d => q{E dd.MM.y – E dd.MM.y},
				y => q{E dd.MM.y – E dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y},
				d => q{E d. M. – E d. M. y},
				y => q{E d. M. y – E d. M. y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d. M. – d. M. y},
				d => q{d.–d. M. y},
				y => q{d. M. y – d. M. y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
		'hebrew' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'indian' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'islamic' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'japanese' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'persian' => {
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
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d.–d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd.MM.y – E dd.MM.y G},
				d => q{E dd.MM.y – E dd.MM.y G},
				y => q{E dd.MM.y – E dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d.–d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
	} },
);

has 'month_patterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'dangi' => {
			'format' => {
				'abbreviated' => {
					'leap' => q{{0}bis},
				},
				'narrow' => {
					'leap' => q{{0}b},
				},
				'wide' => {
					'leap' => q{{0}bis},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{{0}bis},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'leap' => q{{0}bis},
				},
				'narrow' => {
					'leap' => q{{0}b},
				},
				'wide' => {
					'leap' => q{{0}bis},
				},
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
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
					'narrow' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
					'wide' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
			'days' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'wide' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'months' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'wide' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'wide' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
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
					'narrow' => {
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
					'wide' => {
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
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
					'narrow' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
					'wide' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
			'days' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'wide' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'months' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'wide' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'narrow' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
					'wide' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
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
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q(Časové pásmo {0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acrejský letní čas#,
				'generic' => q#Acrejský čas#,
				'standard' => q#Acrejský standardní čas#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghánský čas#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidžan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžír#,
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
			exemplarCity => q#Káhira#,
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
			exemplarCity => q#Džibuti#,
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
			exemplarCity => q#Chartúm#,
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
			exemplarCity => q#Lomé#,
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
			exemplarCity => q#Mogadišu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndžamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakšott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Svatý Tomáš#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Středoafrický čas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Východoafrický čas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Jihoafrický čas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Západoafrický letní čas#,
				'generic' => q#Západoafrický čas#,
				'standard' => q#Západoafrický standardní čas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aljašský letní čas#,
				'generic' => q#Aljašský čas#,
				'standard' => q#Aljašský standardní čas#,
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
				'daylight' => q#Amazonský letní čas#,
				'generic' => q#Amazonský čas#,
				'standard' => q#Amazonský standardní čas#,
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
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
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
			exemplarCity => q#Bogotá#,
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
			exemplarCity => q#Cancún#,
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
			exemplarCity => q#Kajmanské ostrovy#,
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
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
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
			exemplarCity => q#Jamajka#,
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
			exemplarCity => q#Martinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
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
			exemplarCity => q#Ciudad de México#,
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
			exemplarCity => q#Beulah, Severní Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Severní Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Severní Dakota#,
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
			exemplarCity => q#Portoriko#,
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
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Svatý Bartoloměj#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
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
				'daylight' => q#Severoamerický centrální letní čas#,
				'generic' => q#Severoamerický centrální čas#,
				'standard' => q#Severoamerický centrální standardní čas#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Severoamerický východní letní čas#,
				'generic' => q#Severoamerický východní čas#,
				'standard' => q#Severoamerický východní standardní čas#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Severoamerický horský letní čas#,
				'generic' => q#Severoamerický horský čas#,
				'standard' => q#Severoamerický horský standardní čas#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Severoamerický pacifický letní čas#,
				'generic' => q#Severoamerický pacifický čas#,
				'standard' => q#Severoamerický pacifický standardní čas#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyrský letní čas#,
				'generic' => q#Anadyrský čas#,
				'standard' => q#Anadyrský standardní čas#,
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
				'daylight' => q#Apijský letní čas#,
				'generic' => q#Apijský čas#,
				'standard' => q#Apijský standardní čas#,
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
				'daylight' => q#Arabský letní čas#,
				'generic' => q#Arabský čas#,
				'standard' => q#Arabský standardní čas#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinský letní čas#,
				'generic' => q#Argentinský čas#,
				'standard' => q#Argentinský standardní čas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Západoargentinský letní čas#,
				'generic' => q#Západoargentinský čas#,
				'standard' => q#Západoargentinský standardní čas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Arménský letní čas#,
				'generic' => q#Arménský čas#,
				'standard' => q#Arménský standardní čas#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
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
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdád#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrajn#,
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
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
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
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
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
			exemplarCity => q#Macao#,
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
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikósie#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuzněck#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnompenh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pchjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
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
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
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
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
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
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulánbátar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
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
				'daylight' => q#Atlantický letní čas#,
				'generic' => q#Atlantický čas#,
				'standard' => q#Atlantický standardní čas#,
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
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
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
				'daylight' => q#Středoaustralský letní čas#,
				'generic' => q#Středoaustralský čas#,
				'standard' => q#Středoaustralský standardní čas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Středozápadní australský letní čas#,
				'generic' => q#Středozápadní australský čas#,
				'standard' => q#Středozápadní australský standardní čas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Východoaustralský letní čas#,
				'generic' => q#Východoaustralský čas#,
				'standard' => q#Východoaustralský standardní čas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Západoaustralský letní čas#,
				'generic' => q#Západoaustralský čas#,
				'standard' => q#Západoaustralský standardní čas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ázerbájdžánský letní čas#,
				'generic' => q#Ázerbájdžánský čas#,
				'standard' => q#Ázerbájdžánský standardní čas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorský letní čas#,
				'generic' => q#Azorský čas#,
				'standard' => q#Azorský standardní čas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladéšský letní čas#,
				'generic' => q#Bangladéšský čas#,
				'standard' => q#Bangladéšský standardní čas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhútánský čas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivijský čas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilijský letní čas#,
				'generic' => q#Brasilijský čas#,
				'standard' => q#Brasilijský standardní čas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunejský čas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapverdský letní čas#,
				'generic' => q#Kapverdský čas#,
				'standard' => q#Kapverdský standardní čas#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Čas Caseyho stanice#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorrský čas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathamský letní čas#,
				'generic' => q#Chathamský čas#,
				'standard' => q#Chathamský standardní čas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilský letní čas#,
				'generic' => q#Chilský čas#,
				'standard' => q#Chilský standardní čas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Čínský letní čas#,
				'generic' => q#Čínský čas#,
				'standard' => q#Čínský standardní čas#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Čojbalsanský letní čas#,
				'generic' => q#Čojbalsanský čas#,
				'standard' => q#Čojbalsanský standardní čas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Čas Vánočního ostrova#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Čas Kokosových ostrovů#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbijský letní čas#,
				'generic' => q#Kolumbijský čas#,
				'standard' => q#Kolumbijský standardní čas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Letní čas Cookových ostrovů#,
				'generic' => q#Čas Cookových ostrovů#,
				'standard' => q#Standardní čas Cookových ostrovů#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubánský letní čas#,
				'generic' => q#Kubánský čas#,
				'standard' => q#Kubánský standardní čas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Čas Davisovy stanice#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Čas stanice Dumonta d’Urvilla#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Východotimorský čas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Letní čas Velikonočního ostrova#,
				'generic' => q#Čas Velikonočního ostrova#,
				'standard' => q#Standardní čas Velikonočního ostrova#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvádorský čas#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinovaný světový čas#,
			},
			short => {
				'standard' => q#UTC#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#neznámé město#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
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
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
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
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišiněv#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kodaň#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Irský letní čas#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinky#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrov Man#,
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
			exemplarCity => q#Kyjev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
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
				'daylight' => q#Britský letní čas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lucemburk#,
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
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paříž#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Řím#,
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
			exemplarCity => q#Sofie#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
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
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikán#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vídeň#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
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
				'daylight' => q#Středoevropský letní čas#,
				'generic' => q#Středoevropský čas#,
				'standard' => q#Středoevropský standardní čas#,
			},
			short => {
				'daylight' => q#SELČ#,
				'generic' => q#SEČ#,
				'standard' => q#SEČ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Východoevropský letní čas#,
				'generic' => q#Východoevropský čas#,
				'standard' => q#Východoevropský standardní čas#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Dálněvýchodoevropský čas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Západoevropský letní čas#,
				'generic' => q#Západoevropský čas#,
				'standard' => q#Západoevropský standardní čas#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandský letní čas#,
				'generic' => q#Falklandský čas#,
				'standard' => q#Falklandský standardní čas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidžijský letní čas#,
				'generic' => q#Fidžijský čas#,
				'standard' => q#Fidžijský standardní čas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francouzskoguyanský čas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Čas Francouzských jižních a antarktických území#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichský střední čas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapážský čas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambierský čas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruzínský letní čas#,
				'generic' => q#Gruzínský čas#,
				'standard' => q#Gruzínský standardní čas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Čas Gilbertových ostrovů#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Východogrónský letní čas#,
				'generic' => q#Východogrónský čas#,
				'standard' => q#Východogrónský standardní čas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Západogrónský letní čas#,
				'generic' => q#Západogrónský čas#,
				'standard' => q#Západogrónský standardní čas#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guamský čas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Standardní čas Perského zálivu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyanský čas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havajsko-aleutský letní čas#,
				'generic' => q#Havajsko-aleutský čas#,
				'standard' => q#Havajsko-aleutský standardní čas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongský letní čas#,
				'generic' => q#Hongkongský čas#,
				'standard' => q#Hongkongský standardní čas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovdský letní čas#,
				'generic' => q#Hovdský čas#,
				'standard' => q#Hovdský standardní čas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indický čas#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
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
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indickooceánský čas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indočínský čas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Středoindonéský čas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Východoindonéský čas#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Západoindonéský čas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Íránský letní čas#,
				'generic' => q#Íránský čas#,
				'standard' => q#Íránský standardní čas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutský letní čas#,
				'generic' => q#Irkutský čas#,
				'standard' => q#Irkutský standardní čas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Izraelský letní čas#,
				'generic' => q#Izraelský čas#,
				'standard' => q#Izraelský standardní čas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japonský letní čas#,
				'generic' => q#Japonský čas#,
				'standard' => q#Japonský standardní čas#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsko-kamčatský letní čas#,
				'generic' => q#Petropavlovsko-kamčatský čas#,
				'standard' => q#Petropavlovsko-kamčatský standardní čas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Východokazachstánský čas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Západokazachstánský čas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejský letní čas#,
				'generic' => q#Korejský čas#,
				'standard' => q#Korejský standardní čas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrajský čas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarský letní čas#,
				'generic' => q#Krasnojarský čas#,
				'standard' => q#Krasnojarský standardní čas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kyrgyzský čas#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Srílanský čas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Čas Rovníkových ostrovů#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Letní čas ostrova lorda Howa#,
				'generic' => q#Čas ostrova lorda Howa#,
				'standard' => q#Standardní čas ostrova lorda Howa#,
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
				'standard' => q#Čas ostrova Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadanský letní čas#,
				'generic' => q#Magadanský čas#,
				'standard' => q#Magadanský standardní čas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malajský čas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maledivský čas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markézský čas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Čas Marshallových ostrovů#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauricijský letní čas#,
				'generic' => q#Mauricijský čas#,
				'standard' => q#Mauricijský standardní čas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Čas Mawsonovy stanice#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Severozápadní mexický letní čas#,
				'generic' => q#Severozápadní mexický čas#,
				'standard' => q#Severozápadní mexický standardní čas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexický pacifický letní čas#,
				'generic' => q#Mexický pacifický čas#,
				'standard' => q#Mexický pacifický standardní čas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulánbátarský letní čas#,
				'generic' => q#Ulánbátarský čas#,
				'standard' => q#Ulánbátarský standardní čas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskevský letní čas#,
				'generic' => q#Moskevský čas#,
				'standard' => q#Moskevský standardní čas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarský čas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Naurský čas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepálský čas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Novokaledonský letní čas#,
				'generic' => q#Novokaledonský čas#,
				'standard' => q#Novokaledonský standardní čas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Novozélandský letní čas#,
				'generic' => q#Novozélandský čas#,
				'standard' => q#Novozélandský standardní čas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundlandský letní čas#,
				'generic' => q#Newfoundlandský čas#,
				'standard' => q#Newfoundlandský standardní čas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuejský čas#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolský čas#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Letní čas souostroví Fernando de Noronha#,
				'generic' => q#Čas souostroví Fernando de Noronha#,
				'standard' => q#Standardní čas souostroví Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Severomariánský čas#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirský letní čas#,
				'generic' => q#Novosibirský čas#,
				'standard' => q#Novosibirský standardní čas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omský letní čas#,
				'generic' => q#Omský čas#,
				'standard' => q#Omský standardní čas#,
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
			exemplarCity => q#Galapágy#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambierovy ostrovy#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
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
			exemplarCity => q#Markézy#,
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
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairnovy ostrovy#,
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
			exemplarCity => q#Chuukské ostrovy#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pákistánský letní čas#,
				'generic' => q#Pákistánský čas#,
				'standard' => q#Pákistánský standardní čas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palauský čas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Čas Papuy-Nové Guiney#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayský letní čas#,
				'generic' => q#Paraguayský čas#,
				'standard' => q#Paraguayský standardní čas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruánský letní čas#,
				'generic' => q#Peruánský čas#,
				'standard' => q#Peruánský standardní čas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipínský letní čas#,
				'generic' => q#Filipínský čas#,
				'standard' => q#Filipínský standardní čas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Čas Fénixových ostrovů#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Pierre-miquelonský letní čas#,
				'generic' => q#Pierre-miquelonský čas#,
				'standard' => q#Pierre-miquelonský standardní čas#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Čas Pitcairnova ostrova#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapský čas#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pchjongjangský čas#,
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
				'standard' => q#Réunionský čas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Čas Rotherovy stanice#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalinský letní čas#,
				'generic' => q#Sachalinský čas#,
				'standard' => q#Sachalinský standardní čas#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samarský letní čas#,
				'generic' => q#Samarský čas#,
				'standard' => q#Samarský standardní čas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samojský letní čas#,
				'generic' => q#Samojský čas#,
				'standard' => q#Samojský standardní čas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelský čas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapurský čas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Čas Šalamounových ostrovů#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Čas Jižní Georgie#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamský čas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Čas stanice Šówa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitský čas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tchajpejský letní čas#,
				'generic' => q#Tchajpejský čas#,
				'standard' => q#Tchajpejský standardní čas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tádžický čas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelauský čas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonžský letní čas#,
				'generic' => q#Tonžský čas#,
				'standard' => q#Tonžský standardní čas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukský čas#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenský letní čas#,
				'generic' => q#Turkmenský čas#,
				'standard' => q#Turkmenský standardní čas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalský čas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayský letní čas#,
				'generic' => q#Uruguayský čas#,
				'standard' => q#Uruguayský standardní čas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbecký letní čas#,
				'generic' => q#Uzbecký čas#,
				'standard' => q#Uzbecký standardní čas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatský letní čas#,
				'generic' => q#Vanuatský čas#,
				'standard' => q#Vanuatský standardní čas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelský čas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostocký letní čas#,
				'generic' => q#Vladivostocký čas#,
				'standard' => q#Vladivostocký standardní čas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgogradský letní čas#,
				'generic' => q#Volgogradský čas#,
				'standard' => q#Volgogradský standardní čas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Čas stanice Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Čas ostrova Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Čas ostrovů Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutský letní čas#,
				'generic' => q#Jakutský čas#,
				'standard' => q#Jakutský standardní čas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekatěrinburský letní čas#,
				'generic' => q#Jekatěrinburský čas#,
				'standard' => q#Jekatěrinburský standardní čas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
