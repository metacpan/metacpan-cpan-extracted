=head1

Locale::CLDR::Locales::Is - Package for language Icelandic

=cut

package Locale::CLDR::Locales::Is;
# This file auto generated from Data\common\main\is.xml
#	on Sun  5 Aug  6:05:53 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
 				'anp' => 'angíka',
 				'ar' => 'arabíska',
 				'ar_001' => 'stöðluð nútímaarabíska',
 				'arc' => 'arameíska',
 				'arn' => 'mapuche',
 				'arp' => 'arapahó',
 				'arw' => 'aravakska',
 				'as' => 'assamska',
 				'asa' => 'asu',
 				'ast' => 'astúríska',
 				'av' => 'avaríska',
 				'awa' => 'avadí',
 				'ay' => 'aímara',
 				'az' => 'aserska',
 				'az@alt=short' => 'aserska',
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
 				'ckb' => 'sorani-kúrdíska',
 				'co' => 'korsíska',
 				'cop' => 'koptíska',
 				'cr' => 'krí',
 				'crh' => 'krímtyrkneska',
 				'crs' => 'Seselwa kreólsk franska',
 				'cs' => 'tékkneska',
 				'csb' => 'kasúbíska',
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
 				'gay' => 'gajó',
 				'gba' => 'gbaja',
 				'gd' => 'skosk gelíska',
 				'gez' => 'gís',
 				'gil' => 'gilberska',
 				'gl' => 'galíanska',
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
 				'he' => 'hebreska',
 				'hi' => 'hindí',
 				'hil' => 'híligaínon',
 				'hit' => 'hettitíska',
 				'hmn' => 'hmong',
 				'ho' => 'hírímótú',
 				'hr' => 'króatíska',
 				'hsb' => 'hásorbneska',
 				'ht' => 'haítíska',
 				'hu' => 'ungverska',
 				'hup' => 'húpa',
 				'hy' => 'armenska',
 				'hz' => 'hereró',
 				'ia' => 'alþjóðatunga',
 				'iba' => 'íban',
 				'ibb' => 'ibibio',
 				'id' => 'indónesíska',
 				'ie' => 'interlingve',
 				'ig' => 'ígbó',
 				'ii' => 'sísúanjí',
 				'ik' => 'ínúpíak',
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
 				'lkt' => 'lakóta',
 				'ln' => 'lingala',
 				'lo' => 'laó',
 				'lol' => 'mongó',
 				'lou' => 'kreólska (Louisiana)',
 				'loz' => 'lozi',
 				'lrc' => 'norðurlúrí',
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
 				'moh' => 'móhíska',
 				'mos' => 'mossí',
 				'mr' => 'maratí',
 				'ms' => 'malaíska',
 				'mt' => 'maltneska',
 				'mua' => 'mundang',
 				'mul' => 'margvísleg mál',
 				'mus' => 'krík',
 				'mwl' => 'mirandesíska',
 				'mwr' => 'marvarí',
 				'my' => 'burmneska',
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
 				'ny' => 'njanja; sísjeva; sjeva',
 				'nym' => 'njamvesí',
 				'nyn' => 'nyankole',
 				'nyo' => 'njóró',
 				'nzi' => 'nsíma',
 				'oc' => 'oksítaníska',
 				'oj' => 'ojibva',
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
 				'pl' => 'pólska',
 				'pon' => 'ponpeiska',
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
 				'rm' => 'rómanska',
 				'rn' => 'rúndí',
 				'ro' => 'rúmenska',
 				'ro_MD' => 'moldóvska',
 				'rof' => 'rombó',
 				'rom' => 'romaní',
 				'root' => 'rót',
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
 				'su' => 'súndanska',
 				'suk' => 'súkúma',
 				'sus' => 'súsú',
 				'sux' => 'súmerska',
 				'sv' => 'sænska',
 				'sw' => 'svahílí',
 				'sw_CD' => 'Kongó-svahílí',
 				'swb' => 'shimaoríska',
 				'syc' => 'klassísk sýrlenska',
 				'syr' => 'sýrlenska',
 				'ta' => 'tamílska',
 				'te' => 'telúgú',
 				'tem' => 'tímne',
 				'teo' => 'tesó',
 				'ter' => 'terenó',
 				'tet' => 'tetúm',
 				'tg' => 'tadsjikska',
 				'th' => 'taílenska',
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
 				'tpi' => 'tokpisin',
 				'tr' => 'tyrkneska',
 				'trv' => 'tarókó',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimsíska',
 				'tt' => 'tatarska',
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
 				'xal' => 'kalmúkska',
 				'xh' => 'sósa',
 				'xog' => 'sóga',
 				'yao' => 'jaó',
 				'yap' => 'japíska',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddíska',
 				'yo' => 'jórúba',
 				'yue' => 'kantoneska',
 				'za' => 'súang',
 				'zap' => 'sapótek',
 				'zbl' => 'blisstákn',
 				'zen' => 'senaga',
 				'zgh' => 'staðlað marokkóskt tamazight',
 				'zh' => 'kínverska',
 				'zh_Hans' => 'kínverska (einfölduð)',
 				'zh_Hant' => 'kínverska (hefðbundin)',
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
			'Arab' => 'arabískt',
 			'Arab@alt=variant' => 'persneskt-arabískt',
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
 			'021' => 'Ameríka norðan Mexikó',
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
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Fílabeinsströndin',
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
 			'GB@alt=short' => 'Bretland',
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
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalleyjar',
 			'MK' => 'Makedónía',
 			'MK@alt=variant' => 'Makedónía (Fyrrverandi lýðveldi Júgóslavíu)',
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
 			'SX' => 'Sankti Martin',
 			'SY' => 'Sýrland',
 			'SZ' => 'Svasíland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicoseyjar',
 			'TD' => 'Tsjad',
 			'TF' => 'Frönsku suðlægu landsvæðin',
 			'TG' => 'Tógó',
 			'TH' => 'Taíland',
 			'TJ' => 'Tadsjikistan',
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
			'calendar' => 'Dagatal',
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
 				'buddhist' => q{Búddískt dagatal},
 				'chinese' => q{Kínverskt dagatal},
 				'coptic' => q{Koptískt tímatal},
 				'dangi' => q{Dangi dagatal},
 				'ethiopic' => q{Eþíópískt dagatal},
 				'ethiopic-amete-alem' => q{Eþíópískt ‘amete alem’ tímatal},
 				'gregorian' => q{Gregorískt dagatal},
 				'hebrew' => q{Hebreskt dagatal},
 				'indian' => q{indverskt dagatal},
 				'islamic' => q{Íslamskt dagatal},
 				'islamic-civil' => q{Íslamskt borgaradagatal},
 				'islamic-umalqura' => q{Íslamskt dagatal (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 dagatal},
 				'japanese' => q{Japanskt dagatal},
 				'persian' => q{Persneskt dagatal},
 				'roc' => q{Minguo dagatal},
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
 				'jpan' => q{Japanskir tölustafir},
 				'jpanfin' => q{Japanskar fjármálatölur},
 				'khmr' => q{Kmerískar tölur},
 				'knda' => q{Kannada-tölur},
 				'laoo' => q{Lao-tölur},
 				'latn' => q{Vestrænar tölur},
 				'mlym' => q{Malayalam-tölur},
 				'mong' => q{Mongólskar tölur},
 				'mymr' => q{Mjanmarskar tölur},
 				'native' => q{Upprunalegir tölustafir},
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
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ‚ " “ „ ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Á', 'B', 'C', 'D', 'Ð', 'E', 'É', 'F', 'G', 'H', 'I', 'Í', 'J', 'K', 'L', 'M', 'N', 'O', 'Ó', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ú', 'V', 'W', 'X', 'Y', 'Ý', 'Z', 'Þ', 'Æ', 'Ö'], };
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
					'acre' => {
						'name' => q(ekrur),
						'one' => q({0} ekra),
						'other' => q({0} ekrur),
					},
					'acre-foot' => {
						'name' => q(ekrufet),
						'one' => q({0} ekrufet),
						'other' => q({0} ekrufet),
					},
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					'arc-minute' => {
						'name' => q(bogamínútur),
						'one' => q({0} bogamínúta),
						'other' => q({0} bogamínútur),
					},
					'arc-second' => {
						'name' => q(bogasekúndur),
						'one' => q({0} bogasekúnda),
						'other' => q({0} bogasekúndur),
					},
					'astronomical-unit' => {
						'name' => q(stjarnfræðieiningar),
						'one' => q({0} stjarnfræðieining),
						'other' => q({0} stjarnfræðieiningar),
					},
					'bit' => {
						'name' => q(bitar),
						'one' => q({0} biti),
						'other' => q({0} bitar),
					},
					'byte' => {
						'name' => q(bæti),
						'one' => q({0} bæti),
						'other' => q({0} bæti),
					},
					'calorie' => {
						'name' => q(kaloríur),
						'one' => q({0} kaloría),
						'other' => q({0} kaloríur),
					},
					'carat' => {
						'name' => q(karöt),
						'one' => q({0} karat),
						'other' => q({0} karöt),
					},
					'celsius' => {
						'name' => q(gráður á Celsíus),
						'one' => q({0} gráða á Celsíus),
						'other' => q({0} gráður á Celsíus),
					},
					'centiliter' => {
						'name' => q(sentilítrar),
						'one' => q({0} sentilítri),
						'other' => q({0} sentilítrar),
					},
					'centimeter' => {
						'name' => q(sentimetrar),
						'one' => q({0} sentimetri),
						'other' => q({0} sentimetrar),
						'per' => q({0} á sentimetra),
					},
					'century' => {
						'name' => q(aldir),
						'one' => q({0} öld),
						'other' => q({0} aldir),
					},
					'coordinate' => {
						'east' => q({0} austur),
						'north' => q({0} norður),
						'south' => q({0} suður),
						'west' => q({0} vestur),
					},
					'cubic-centimeter' => {
						'name' => q(rúmsentimetrar),
						'one' => q({0} rúmsentimetri),
						'other' => q({0} rúmsentimetrar),
						'per' => q({0} á rúmsentimetra),
					},
					'cubic-foot' => {
						'name' => q(rúmfet),
						'one' => q({0} rúmfet),
						'other' => q({0} rúmfet),
					},
					'cubic-inch' => {
						'name' => q(rúmtommur),
						'one' => q({0} rúmtomma),
						'other' => q({0} rúmtommur),
					},
					'cubic-kilometer' => {
						'name' => q(rúmkílómetrar),
						'one' => q({0} rúmkílómetri),
						'other' => q({0} rúmkílómetrar),
					},
					'cubic-meter' => {
						'name' => q(rúmmetrar),
						'one' => q({0} rúmmetri),
						'other' => q({0} rúmmetrar),
						'per' => q({0} á rúmmetra),
					},
					'cubic-mile' => {
						'name' => q(rúmmílur),
						'one' => q({0} rúmmíla),
						'other' => q({0} rúmmílur),
					},
					'cubic-yard' => {
						'name' => q(rúmyardar),
						'one' => q({0} rúmyard),
						'other' => q({0} rúmyardar),
					},
					'cup' => {
						'name' => q(bollar),
						'one' => q({0} bolli),
						'other' => q({0} bollar),
					},
					'cup-metric' => {
						'name' => q(ástralskir bollar),
						'one' => q({0} ástralskur bolli),
						'other' => q({0} ástralskir bollar),
					},
					'day' => {
						'name' => q(dagar),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0} á dag),
					},
					'deciliter' => {
						'name' => q(desilítrar),
						'one' => q({0} desilítri),
						'other' => q({0} desilítrar),
					},
					'decimeter' => {
						'name' => q(desimetrar),
						'one' => q({0} desimetri),
						'other' => q({0} desimetrar),
					},
					'degree' => {
						'name' => q(gráður),
						'one' => q({0} gráða),
						'other' => q({0} gráður),
					},
					'fahrenheit' => {
						'name' => q(gráður á Fahrenheit),
						'one' => q({0} gráða á Fahrenheit),
						'other' => q({0} gráður á Fahrenheit),
					},
					'fathom' => {
						'name' => q(faðmar),
						'one' => q({0} faðmur),
						'other' => q({0} faðmar),
					},
					'fluid-ounce' => {
						'name' => q(vökvaúnsur),
						'one' => q({0} vökvaúnsa),
						'other' => q({0} vökvaúnsur),
					},
					'foodcalorie' => {
						'name' => q(hitaeiningar),
						'one' => q({0} hitaeining),
						'other' => q({0} hitaeiningar),
					},
					'foot' => {
						'name' => q(fet),
						'one' => q({0} fet),
						'other' => q({0} fet),
						'per' => q({0} á fet),
					},
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					'g-force' => {
						'name' => q(þyngdarhröðun),
						'one' => q({0} þyngdarhröðun),
						'other' => q({0} þyngdarhröðun),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} á gallon),
					},
					'gallon-imperial' => {
						'name' => q(Breskt gallon),
						'one' => q({0} breskt gallon),
						'other' => q({0} breskt gallon),
						'per' => q({0}/ á breskt gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gígabitar),
						'one' => q({0} gígabiti),
						'other' => q({0} gígabitar),
					},
					'gigabyte' => {
						'name' => q(gígabæti),
						'one' => q({0} gígabæti),
						'other' => q({0} gígabæti),
					},
					'gigahertz' => {
						'name' => q(gígahertz),
						'one' => q({0} gígahertz),
						'other' => q({0} gígahertz),
					},
					'gigawatt' => {
						'name' => q(gígavött),
						'one' => q({0} gígavatt),
						'other' => q({0} gígavött),
					},
					'gram' => {
						'name' => q(grömm),
						'one' => q({0} gramm),
						'other' => q({0} grömm),
						'per' => q({0} á gramm),
					},
					'hectare' => {
						'name' => q(hektarar),
						'one' => q({0} hektari),
						'other' => q({0} hektarar),
					},
					'hectoliter' => {
						'name' => q(hektólítrar),
						'one' => q({0} hektólítri),
						'other' => q({0} hektólítrar),
					},
					'hectopascal' => {
						'name' => q(hektópasköl),
						'one' => q({0} hektópaskal),
						'other' => q({0} hektópasköl),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(hestöfl),
						'one' => q({0} hestafl),
						'other' => q({0} hestöfl),
					},
					'hour' => {
						'name' => q(klukkustundir),
						'one' => q({0} klukkustund),
						'other' => q({0} klukkustundir),
						'per' => q({0} á klst.),
					},
					'inch' => {
						'name' => q(tommur),
						'one' => q({0} tomma),
						'other' => q({0} tommur),
						'per' => q({0} á tommu),
					},
					'inch-hg' => {
						'name' => q(tommur af kvikvasilfri),
						'one' => q({0} tomma af kvikasilfri),
						'other' => q({0} tommur af kvikvasilfri),
					},
					'joule' => {
						'name' => q(júl),
						'one' => q({0} júl),
						'other' => q({0} júl),
					},
					'karat' => {
						'name' => q(karöt),
						'one' => q({0} karat),
						'other' => q({0} karöt),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kílóbitar),
						'one' => q({0} kílóbiti),
						'other' => q({0} kílóbitar),
					},
					'kilobyte' => {
						'name' => q(kílóbæti),
						'one' => q({0} kílóbæti),
						'other' => q({0} kílóbæti),
					},
					'kilocalorie' => {
						'name' => q(kílókaloríur),
						'one' => q({0} kílókaloría),
						'other' => q({0} kílókaloríur),
					},
					'kilogram' => {
						'name' => q(kílógrömm),
						'one' => q({0} kílógramm),
						'other' => q({0} kílógrömm),
						'per' => q({0} á kílógramm),
					},
					'kilohertz' => {
						'name' => q(kílóhertz),
						'one' => q({0} kílóhertz),
						'other' => q({0} kílóhertz),
					},
					'kilojoule' => {
						'name' => q(kílójúl),
						'one' => q({0} kílójúl),
						'other' => q({0} kílójúl),
					},
					'kilometer' => {
						'name' => q(kílómetrar),
						'one' => q({0} kílómetri),
						'other' => q({0} kílómetrar),
						'per' => q({0} á kílómetra),
					},
					'kilometer-per-hour' => {
						'name' => q(kílómetrar á klukkustund),
						'one' => q({0} kílómetri á klukkustund),
						'other' => q({0} kílómetrar á klukkustund),
					},
					'kilowatt' => {
						'name' => q(kílóvött),
						'one' => q({0} kílóvatt),
						'other' => q({0} kílóvött),
					},
					'kilowatt-hour' => {
						'name' => q(kílóvattstundir),
						'one' => q({0} kílóvattstund),
						'other' => q({0} kílóvattstundir),
					},
					'knot' => {
						'name' => q(hnútar),
						'one' => q({0} hútur),
						'other' => q({0} hnútar),
					},
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
					},
					'liter' => {
						'name' => q(lítrar),
						'one' => q({0} lítri),
						'other' => q({0} lítrar),
						'per' => q({0} á lítra),
					},
					'liter-per-100kilometers' => {
						'name' => q(lítrar á 100 kílómetra),
						'one' => q({0} lítri á 100 kílómetra),
						'other' => q({0} lítrar á 100 kílómetra),
					},
					'liter-per-kilometer' => {
						'name' => q(lítrar á kílómetra),
						'one' => q({0} lítri á kílómetra),
						'other' => q({0} lítrar á kílómetra),
					},
					'lux' => {
						'name' => q(lúx),
						'one' => q({0} lúx),
						'other' => q({0} lúx),
					},
					'megabit' => {
						'name' => q(megabitar),
						'one' => q({0} megabiti),
						'other' => q({0} megabitar),
					},
					'megabyte' => {
						'name' => q(megabæti),
						'one' => q({0} megabæti),
						'other' => q({0} megabæti),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megalítrar),
						'one' => q({0} megalítri),
						'other' => q({0} megalítrar),
					},
					'megawatt' => {
						'name' => q(megavött),
						'one' => q({0} megavatt),
						'other' => q({0} megavött),
					},
					'meter' => {
						'name' => q(metrar),
						'one' => q({0} metri),
						'other' => q({0} metrar),
						'per' => q({0} á metra),
					},
					'meter-per-second' => {
						'name' => q(metrar á sekúndu),
						'one' => q({0} metri á sekúndu),
						'other' => q({0} metrar á sekúndu),
					},
					'meter-per-second-squared' => {
						'name' => q(metrar á sekúndu, á sekúndu),
						'one' => q({0} metri á sekúndu, á sekúndu),
						'other' => q({0} metrar á sekúndu, á sekúndu),
					},
					'metric-ton' => {
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
					},
					'microgram' => {
						'name' => q(míkrógrömm),
						'one' => q({0} míkrógramm),
						'other' => q({0} míkrógrömm),
					},
					'micrometer' => {
						'name' => q(míkrómetrar),
						'one' => q({0} míkrómetri),
						'other' => q({0} míkrómetrar),
					},
					'microsecond' => {
						'name' => q(míkrósekúndur),
						'one' => q({0} míkrósekúnda),
						'other' => q({0} míkrósekúndur),
					},
					'mile' => {
						'name' => q(mílur),
						'one' => q({0} míla),
						'other' => q({0} mílur),
					},
					'mile-per-gallon' => {
						'name' => q(mílur á gallon),
						'one' => q({0} míla á gallon),
						'other' => q({0} mílur á gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mílur á breskt gallon),
						'one' => q({0} míla á breskt gallon),
						'other' => q({0} mílur á breskt gallon),
					},
					'mile-per-hour' => {
						'name' => q(mílur á klukkustund),
						'one' => q({0} míla á klukkustund),
						'other' => q({0} mílur á klukkustund),
					},
					'mile-scandinavian' => {
						'name' => q(sænsk míla),
						'one' => q({0} sænsk míla),
						'other' => q({0} sænskar mílur),
					},
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					'millibar' => {
						'name' => q(millibör),
						'one' => q({0} millibar),
						'other' => q({0} millibör),
					},
					'milligram' => {
						'name' => q(milligrömm),
						'one' => q({0} milligramm),
						'other' => q({0} milligrömm),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrömm á desílítra),
						'one' => q({0} milligramm á desílítra),
						'other' => q({0} milligrömm á desílítra),
					},
					'milliliter' => {
						'name' => q(millilítrar),
						'one' => q({0} millilítri),
						'other' => q({0} millilítrar),
					},
					'millimeter' => {
						'name' => q(millimetrar),
						'one' => q({0} millimetri),
						'other' => q({0} millimetrar),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimetrar af kvikasilfri),
						'one' => q({0} millimetrar af kvikasilfri),
						'other' => q({0} millimetrar af kvikasilfri),
					},
					'millimole-per-liter' => {
						'name' => q(millimól á lítra),
						'one' => q({0} millimól á lítra),
						'other' => q({0} millimól á lítra),
					},
					'millisecond' => {
						'name' => q(millisekúndur),
						'one' => q({0} millisekúnda),
						'other' => q({0} millisekúndur),
					},
					'milliwatt' => {
						'name' => q(millivött),
						'one' => q({0} millivatt),
						'other' => q({0} millivött),
					},
					'minute' => {
						'name' => q(mínútur),
						'one' => q({0} mínúta),
						'other' => q({0} mínútur),
						'per' => q({0} á mínútu),
					},
					'month' => {
						'name' => q(mánuðir),
						'one' => q({0} mánuður),
						'other' => q({0} mánuðir),
						'per' => q({0} á mánuði),
					},
					'nanometer' => {
						'name' => q(nanómetrar),
						'one' => q({0} nanómetri),
						'other' => q({0} nanómetrar),
					},
					'nanosecond' => {
						'name' => q(nanósekúndur),
						'one' => q({0} nanósekúnda),
						'other' => q({0} nanósekúndur),
					},
					'nautical-mile' => {
						'name' => q(sjómílur),
						'one' => q({0} sjómíla),
						'other' => q({0} sjómílur),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(únsur),
						'one' => q({0} únsa),
						'other' => q({0} únsur),
						'per' => q({0} á únsu),
					},
					'ounce-troy' => {
						'name' => q(troyesúnsur),
						'one' => q({0} troyesúnsa),
						'other' => q({0} troyesúnsur),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(milljónarhlutar),
						'one' => q({0} milljónarhluti),
						'other' => q({0} milljónarhlutar),
					},
					'per' => {
						'1' => q({0} á {1}),
					},
					'picometer' => {
						'name' => q(píkómetrar),
						'one' => q({0} píkómetri),
						'other' => q({0} píkómetrar),
					},
					'pint' => {
						'name' => q(hálfpottar),
						'one' => q({0} hálfpottur),
						'other' => q({0} hálfpottar),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0} á pund),
					},
					'pound-per-square-inch' => {
						'name' => q(pund á fertommu),
						'one' => q({0} pund á fertommu),
						'other' => q({0} pund á fertommu),
					},
					'quart' => {
						'name' => q(kvartar),
						'one' => q({0} kvart),
						'other' => q({0} kvartar),
					},
					'radian' => {
						'name' => q(radíanar),
						'one' => q({0} radían),
						'other' => q({0} radíanar),
					},
					'revolution' => {
						'name' => q(snúningur),
						'one' => q({0} snúningur),
						'other' => q({0} snúningar),
					},
					'second' => {
						'name' => q(sekúndur),
						'one' => q({0} sekúnda),
						'other' => q({0} sekúndur),
						'per' => q({0} á sekúndu),
					},
					'square-centimeter' => {
						'name' => q(fersentimetrar),
						'one' => q({0} fersentimetri),
						'other' => q({0} fersentimetrar),
						'per' => q({0} á fersentimetra),
					},
					'square-foot' => {
						'name' => q(ferfet),
						'one' => q({0} ferfet),
						'other' => q({0} ferfet),
					},
					'square-inch' => {
						'name' => q(fertommur),
						'one' => q({0} fertomma),
						'other' => q({0} fertommur),
						'per' => q({0} á fertommu),
					},
					'square-kilometer' => {
						'name' => q(ferkílómetrar),
						'one' => q({0} ferkílómetri),
						'other' => q({0} ferkílómetrar),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(fermetrar),
						'one' => q({0} fermetri),
						'other' => q({0} fermetrar),
						'per' => q({0} á fermetra),
					},
					'square-mile' => {
						'name' => q(fermílur),
						'one' => q({0} fermíla),
						'other' => q({0} fermílur),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(feryardar),
						'one' => q({0} feryard),
						'other' => q({0} feryardar),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					'tablespoon' => {
						'name' => q(matskeiðar),
						'one' => q({0} matskeið),
						'other' => q({0} matskeiðar),
					},
					'teaspoon' => {
						'name' => q(teskeiðar),
						'one' => q({0} teskeið),
						'other' => q({0} teskeiðar),
					},
					'terabit' => {
						'name' => q(terabitar),
						'one' => q({0} terabiti),
						'other' => q({0} terabitar),
					},
					'terabyte' => {
						'name' => q(terabæti),
						'one' => q({0} terabæti),
						'other' => q({0} terabæti),
					},
					'ton' => {
						'name' => q(bandarískt tonn),
						'one' => q({0} bandarískt tonn),
						'other' => q({0} bandarísk tonn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(vött),
						'one' => q({0} vatt),
						'other' => q({0} vött),
					},
					'week' => {
						'name' => q(vikur),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0} á viku),
					},
					'yard' => {
						'name' => q(yardar),
						'one' => q({0} yard),
						'other' => q({0} yardar),
					},
					'year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0} á ári),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(se),
						'one' => q({0} se),
						'other' => q({0} se),
					},
					'carat' => {
						'name' => q(karöt),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(árh),
						'one' => q({0}árh),
						'other' => q({0}árh),
					},
					'coordinate' => {
						'east' => q({0}A),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					'cubic-centimeter' => {
						'per' => q({0}/cm³),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					'day' => {
						'name' => q(dagur),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(faðmur),
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					'foot' => {
						'name' => q(fet),
						'one' => q({0} fet),
						'other' => q({0} fet),
						'per' => q({0}/fet),
					},
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					'g-force' => {
						'name' => q(g-hröðun),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} ek),
						'other' => q({0} ek),
					},
					'hour' => {
						'name' => q(klukkustund),
						'one' => q({0} klst.),
						'other' => q({0} klst.),
						'per' => q({0}/klst.),
					},
					'inch' => {
						'name' => q(tommur),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/tom),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/klst.),
						'one' => q({0} km/klst.),
						'other' => q({0} km/klst.),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} lj.),
						'other' => q({0} lj.),
					},
					'liter' => {
						'name' => q(lítri),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/sek.),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmetrar),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsek.),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mílur),
						'one' => q({0} mí),
						'other' => q({0} mí),
					},
					'mile-per-hour' => {
						'name' => q(mílur/klst.),
						'one' => q({0} míla/klst.),
						'other' => q({0} míl./klst.),
					},
					'mile-scandinavian' => {
						'name' => q(sænskar mílur),
						'one' => q({0} sæ. míl),
						'other' => q({0} sæ. míl),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbör),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(millisek.),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'name' => q(mín.),
						'one' => q({0} mín.),
						'other' => q({0} mín.),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(mánuður),
						'one' => q({0} mán.),
						'other' => q({0} mán.),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanósek.),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(sml),
						'one' => q({0} sml),
						'other' => q({0} sml),
					},
					'ounce' => {
						'name' => q(únsur),
						'one' => q({0} únsa),
						'other' => q({0} únsur),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'point' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} p.),
						'other' => q({0} p.),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					'square-centimeter' => {
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'one' => q({0} ferfet),
						'other' => q({0} ferfet),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'one' => q({0}mí²),
						'other' => q({0}mí²),
					},
					'stone' => {
						'name' => q(stone),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					'ton' => {
						'name' => q(BNA tonn),
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(vika),
						'one' => q({0} v.),
						'other' => q({0} v.),
						'per' => q({0}/v),
					},
					'yard' => {
						'name' => q(yardar),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(ár),
						'one' => q({0}á),
						'other' => q({0}á),
						'per' => q({0}/ár),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(ekrur),
						'one' => q({0} ek.),
						'other' => q({0} ek.),
					},
					'acre-foot' => {
						'name' => q(ekrufet),
						'one' => q({0} ekrufet),
						'other' => q({0} ekrufet),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(bogamín.),
						'one' => q({0} bogamín.),
						'other' => q({0} bogamín.),
					},
					'arc-second' => {
						'name' => q(bogasek.),
						'one' => q({0} bogasek.),
						'other' => q({0} bogasek.),
					},
					'astronomical-unit' => {
						'name' => q(se),
						'one' => q({0} se),
						'other' => q({0} se),
					},
					'bit' => {
						'name' => q(biti),
						'one' => q({0} biti),
						'other' => q({0} bitar),
					},
					'byte' => {
						'name' => q(bæti),
						'one' => q({0} bæti),
						'other' => q({0} bæti),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(karöt),
						'one' => q({0} kt.),
						'other' => q({0} kt.),
					},
					'celsius' => {
						'name' => q(gráður á Celsíus),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(árh),
						'one' => q({0} árh),
						'other' => q({0} árh),
					},
					'coordinate' => {
						'east' => q({0} A),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(fet³),
						'one' => q({0} fet³),
						'other' => q({0} fet³),
					},
					'cubic-inch' => {
						'name' => q(tommur³),
						'one' => q({0} t³),
						'other' => q({0} t³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mí³),
						'one' => q({0} mí³),
						'other' => q({0} mí³),
					},
					'cubic-yard' => {
						'name' => q(yardar³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(bollar),
						'one' => q({0} bolli),
						'other' => q({0} bollar),
					},
					'cup-metric' => {
						'name' => q(ástr. bolli),
						'one' => q({0} ástr. bolli),
						'other' => q({0} ástr. bollar),
					},
					'day' => {
						'name' => q(dagar),
						'one' => q({0} dagur),
						'other' => q({0} dagar),
						'per' => q({0}/d.),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(gráður),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(faðmar),
						'one' => q({0} ftm),
						'other' => q({0} ftm),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'foot' => {
						'name' => q(fet),
						'one' => q({0} fet),
						'other' => q({0} fet),
						'per' => q({0}/fet),
					},
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(g-hröðun),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(breskt gal.),
						'one' => q({0} breskt gal.),
						'other' => q({0} breskt gal.),
						'per' => q({0} breskt gal.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(grömm),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hektarar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hö),
						'one' => q({0} hö),
						'other' => q({0} hö),
					},
					'hour' => {
						'name' => q(klukkustundir),
						'one' => q({0} klst.),
						'other' => q({0} klst.),
						'per' => q({0}/klst.),
					},
					'inch' => {
						'name' => q(tommur),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(júl),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kílójúl),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(kílómetrar á klukkustund),
						'one' => q({0} km/klst.),
						'other' => q({0} km/klst.),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(ljósár),
						'one' => q({0} ljósár),
						'other' => q({0} ljósár),
					},
					'liter' => {
						'name' => q(lítrar),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(lítrar/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lúx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(metrar/sek.),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(metrar/sek²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmetrar),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsek.),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mílur),
						'one' => q({0} mí),
						'other' => q({0} mí),
					},
					'mile-per-gallon' => {
						'name' => q(mílur/gallon),
						'one' => q({0} mí./gal.),
						'other' => q({0} mí./gal.),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mílur/breskt gal.),
						'one' => q({0} mí./br.g.),
						'other' => q({0} mí./br.g.),
					},
					'mile-per-hour' => {
						'name' => q(mílur/klst.),
						'one' => q({0} míla/klst.),
						'other' => q({0} mílur/klst.),
					},
					'mile-scandinavian' => {
						'name' => q(sæ. míl.),
						'one' => q({0} sæ. míl.),
						'other' => q({0} sæ. míl.),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbör),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(millimól/lítri),
						'one' => q({0} m.mól/l),
						'other' => q({0} m.mól/l),
					},
					'millisecond' => {
						'name' => q(millisek.),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(mín.),
						'one' => q({0} mín.),
						'other' => q({0} mín.),
						'per' => q({0}/mín.),
					},
					'month' => {
						'name' => q(mánuðir),
						'one' => q({0} mán.),
						'other' => q({0} mán.),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanósek.),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(sml),
						'one' => q({0} sml),
						'other' => q({0} sml),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(troyesoz),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(milljónarhlutar),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(hálfp.),
						'one' => q({0} hálfp.),
						'other' => q({0} hálfp.),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(stig),
						'one' => q({0} stig),
						'other' => q({0} stig),
					},
					'pound' => {
						'name' => q(pund),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qts),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(sn.),
						'one' => q({0} sn.),
						'other' => q({0} sn.),
					},
					'second' => {
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'per' => q({0}/sek.),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ferfet),
						'one' => q({0} ferfet),
						'other' => q({0} ferfet),
					},
					'square-inch' => {
						'name' => q(tommur²),
						'one' => q({0} t²),
						'other' => q({0} t²),
						'per' => q({0}/t²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(fermetrar),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(fermílur),
						'one' => q({0} fermíla),
						'other' => q({0} fermílur),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yardar²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(msk),
						'one' => q({0} msk),
						'other' => q({0} msk),
					},
					'teaspoon' => {
						'name' => q(tsk),
						'one' => q({0} tsk),
						'other' => q({0} tsk),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(BNA tonn),
						'one' => q({0} BNA tn),
						'other' => q({0} BNA tn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(vött),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(vikur),
						'one' => q({0} vika),
						'other' => q({0} vikur),
						'per' => q({0}/v),
					},
					'yard' => {
						'name' => q(yardar),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(ár),
						'one' => q({0} ár),
						'other' => q({0} ár),
						'per' => q({0}/ári),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} og {1}),
				2 => q({0} og {1}),
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
			'minusSign' => q(؜-),
			'plusSign' => q(؜+),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
				'currency' => q(Andorrskur peseti),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(arabískt dírham),
				'one' => q(arabískt dírham),
				'other' => q(arabísk dírhöm),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgani),
				'one' => q(afgani),
				'other' => q(afganar),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albanskt lek),
				'one' => q(albanskt lek),
				'other' => q(albönsk lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(armenskt dramm),
				'one' => q(armenskt dramm),
				'other' => q(armensk drömm),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(hollenskt Antillugyllini),
				'one' => q(hollenskt Antillugyllini),
				'other' => q(hollensk Antillugyllini),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'AWG',
			display_name => {
				'currency' => q(arúbönsk flórína),
				'one' => q(arúbönsk flórína),
				'other' => q(arúbanskar flórínur),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(aserskt manat),
				'one' => q(aserskt manat),
				'other' => q(asersk manöt),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(skiptanlegt Bosníu og Hersegóvínu-mark),
				'one' => q(skiptanlegt Bosníu og Hersegóvínu-mark),
				'other' => q(skiptanleg Bosníu og Hersegóvínu-mörk),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadoskur dalur),
				'one' => q(barbadoskur dalur),
				'other' => q(barbadoskir dalir),
			},
		},
		'BDT' => {
			symbol => 'BDT',
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
			symbol => 'BGN',
			display_name => {
				'currency' => q(búlgarskt lef),
				'one' => q(búlgarskt lef),
				'other' => q(búlgörsk lef),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bareinskur denari),
				'one' => q(bareinskur denari),
				'other' => q(bareinskir denarar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(búrúndískur franki),
				'one' => q(búrúndískur franki),
				'other' => q(búrúndískir frankar),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermúdadalur),
				'one' => q(Bermúdadalur),
				'other' => q(Bermúdadalir),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(brúneiskur dalur),
				'one' => q(brúneiskur dalur),
				'other' => q(brúneiskir dalir),
			},
		},
		'BOB' => {
			symbol => 'BOB',
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
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahamadalur),
				'one' => q(Bahamadalur),
				'other' => q(Bahamadalir),
			},
		},
		'BTN' => {
			symbol => 'BTN',
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
			symbol => 'BWP',
			display_name => {
				'currency' => q(botsvönsk púla),
				'one' => q(botsvönsk púla),
				'other' => q(botsvanskar púlur),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(hvítrússnesk rúbla),
				'one' => q(hvítrússnesk rúbla),
				'other' => q(hvítrússneskar rúblur),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(hvítrússnesk rúbla \(2000–2016\)),
				'one' => q(hvítrússnesk rúbla \(2000–2016\)),
				'other' => q(hvítrússneskar rúblur \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
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
			symbol => 'CDF',
			display_name => {
				'currency' => q(kongóskur franki),
				'one' => q(kongóskur franki),
				'other' => q(kongóskir frankar),
			},
		},
		'CHF' => {
			symbol => 'CHF',
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
			symbol => 'CLP',
			display_name => {
				'currency' => q(síleskur pesi),
				'one' => q(síleskur pesi),
				'other' => q(síleskir pesar),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(kínverskt júan \(utan heimalands\)),
				'one' => q(kínverskt júan \(utan heimalands\)),
				'other' => q(kínverskt júan \(utan heimalands\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(kínverskt júan),
				'one' => q(kínverskt júan),
				'other' => q(kínversk júön),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(kólumbískur pesi),
				'one' => q(kólumbískur pesi),
				'other' => q(kólumbískir pesar),
			},
		},
		'CRC' => {
			symbol => 'CRC',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(kúbverskur skiptanlegur pesi),
				'one' => q(kúbverskur skiptanlegur pesói),
				'other' => q(kúbverskir skiptanlegir pesóar),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kúbverskur pesi),
				'one' => q(kúbverskur pesi),
				'other' => q(kúbverskir pesar),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
			symbol => 'CZK',
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
			symbol => 'DJF',
			display_name => {
				'currency' => q(djíbútískur franki),
				'one' => q(djíbútískur franki),
				'other' => q(djíbútískir frankar),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(dönsk króna),
				'one' => q(dönsk króna),
				'other' => q(danskar krónur),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dóminískur pesi),
				'one' => q(dóminískur pesi),
				'other' => q(dóminískir pesar),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
			symbol => 'EGP',
			display_name => {
				'currency' => q(egypskt pund),
				'one' => q(egypskt pund),
				'other' => q(egypsk pund),
			},
		},
		'ERN' => {
			symbol => 'ERN',
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
			symbol => 'ETB',
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
			symbol => 'FJD',
			display_name => {
				'currency' => q(fidjeyskur dalur),
				'one' => q(fidjeyskur dalur),
				'other' => q(fidjeyskir dalir),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
				'one' => q(sterlingspund),
				'other' => q(sterlingspund),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(georgískur lari),
				'one' => q(georgískur lari),
				'other' => q(georgískir larar),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ganverskur sedi),
				'one' => q(ganverskur sedi),
				'other' => q(ganverskir sedar),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gíbraltarspund),
				'one' => q(Gíbraltarspund),
				'other' => q(Gíbraltarspund),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambískur dalasi),
				'one' => q(gambískur dalasi),
				'other' => q(gambískir dalasar),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
			display_name => {
				'currency' => q(gvæjanskur dalur),
				'one' => q(gvæjanskur dalur),
				'other' => q(gvæjanskir dalir),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hong Kong-dalur),
				'one' => q(Hong Kong-dalur),
				'other' => q(Hong Kong-dalir),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(hondúrsk lempíra),
				'one' => q(hondúrsk lempíra),
				'other' => q(hondúrskar lempírur),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(króatísk kúna),
				'one' => q(króatísk kúna),
				'other' => q(króatískar kúnur),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haítískur gúrdi),
				'one' => q(haítískur gúrdi),
				'other' => q(haítískir gúrdar),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(ungversk fórinta),
				'one' => q(ungversk fórinta),
				'other' => q(ungverskar fórintur),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => '₪',
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
			symbol => 'IQD',
			display_name => {
				'currency' => q(írakskur denari),
				'one' => q(írakskur denari),
				'other' => q(írakskir denarar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(íranskt ríal),
				'one' => q(íranskt ríal),
				'other' => q(írönsk ríöl),
			},
		},
		'ISK' => {
			symbol => 'ISK',
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
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamaískur dalur),
				'one' => q(jamaískur dalur),
				'other' => q(jamaískir dalir),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(jórdanskur denari),
				'one' => q(jórdanskur denari),
				'other' => q(jórdanskir denarar),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(japanskt jen),
				'one' => q(japanskt jen),
				'other' => q(japönsk jen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(kenískur skildingur),
				'one' => q(kenískur skildingur),
				'other' => q(kenískir skildingar),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgiskt som),
				'one' => q(kirgiskt som),
				'other' => q(kirgisk som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambódískt ríal),
				'one' => q(kambódískt ríal),
				'other' => q(kambódísk ríöl),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(kómoreyskur franki),
				'one' => q(kómoreyskur franki),
				'other' => q(kómoreyskir frankar),
			},
		},
		'KPW' => {
			symbol => 'KPW',
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
			symbol => 'KWD',
			display_name => {
				'currency' => q(kúveiskur denari),
				'one' => q(kúveiskur denari),
				'other' => q(kúveiskir denarar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(caymaneyskur dalur),
				'one' => q(caymaneyskur dalur),
				'other' => q(caymaneyskir dalir),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kasakst tengi),
				'one' => q(kasakst tengi),
				'other' => q(kasöksk tengi),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laoskt kip),
				'one' => q(laoskt kip),
				'other' => q(laosk kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(líbanskt pund),
				'one' => q(líbanskt pund),
				'other' => q(líbönsk pund),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(srílönsk rúpía),
				'one' => q(srílönsk rúpía),
				'other' => q(srílanskar rúpíur),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(líberískur dalur),
				'one' => q(líberískur dalur),
				'other' => q(líberískir dalir),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
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
			symbol => 'LVL',
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
			symbol => 'LYD',
			display_name => {
				'currency' => q(líbískur denari),
				'one' => q(líbískur denari),
				'other' => q(líbískir denarar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldavískt lei),
				'one' => q(moldavískt lei),
				'other' => q(moldavísk lei),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
			symbol => 'MKD',
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
			symbol => 'MMK',
			display_name => {
				'currency' => q(mjanmarskt kjat),
				'one' => q(mjanmarskt kjat),
				'other' => q(mjanmörsk kjöt),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongólskur túríkur),
				'one' => q(mongólskur túríkur),
				'other' => q(mongólskir túríkar),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(makaósk pataka),
				'one' => q(makaósk pataka),
				'other' => q(makaóskar patökur),
			},
		},
		'MRO' => {
			symbol => 'MRO',
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(máritísk rúpía),
				'one' => q(máritísk rúpía),
				'other' => q(máritískar rúpíur),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maldíveysk rúpía),
				'one' => q(maldíveysk rúpía),
				'other' => q(maldíveyskar rúpíur),
			},
		},
		'MWK' => {
			symbol => 'MWK',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(mósambískt metikal),
				'one' => q(mósambískt metikal),
				'other' => q(mósambísk metiköl),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namibískur dalur),
				'one' => q(namibískur dalur),
				'other' => q(namibískir dalir),
			},
		},
		'NGN' => {
			symbol => 'NGN',
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
			symbol => 'NIO',
			display_name => {
				'currency' => q(níkaraögsk kordóva),
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
			symbol => 'NOK',
			display_name => {
				'currency' => q(norsk króna),
				'one' => q(norsk króna),
				'other' => q(norskar krónur),
			},
		},
		'NPR' => {
			symbol => 'NPR',
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
			symbol => 'OMR',
			display_name => {
				'currency' => q(ómanskt ríal),
				'one' => q(ómanskt ríal),
				'other' => q(ómönsk ríöl),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(balbói),
				'one' => q(balbói),
				'other' => q(balbóar),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(perúskt sól),
				'one' => q(perúskt sól),
				'other' => q(perúsk sól),
			},
		},
		'PGK' => {
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakistönsk rúpía),
				'one' => q(pakistönsk rúpía),
				'other' => q(pakistanskar rúpíur),
			},
		},
		'PLN' => {
			symbol => 'PLN',
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(paragvæskt gvaraní),
				'one' => q(paragvæskt gvaraní),
				'other' => q(paragvæsk gvaraní),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(katarskt ríal),
				'one' => q(katarskt ríal),
				'other' => q(katörsk ríöl),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rúmenskt lei \(1952–2006\)),
				'one' => q(Rúmenskt lei \(1952–2006\)),
				'other' => q(Rúmenskt lei \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(rúmenskt lei),
				'one' => q(rúmenskt lei),
				'other' => q(rúmensk lei),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(serbneskur denari),
				'one' => q(serbneskur denari),
				'other' => q(serbneskir denarar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
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
			symbol => 'RWF',
			display_name => {
				'currency' => q(rúandskur franki),
				'one' => q(rúandskur franki),
				'other' => q(rúandskir frankar),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(sádíarabískt ríal),
				'one' => q(sádiarabískt ríal),
				'other' => q(sádiarabísk ríöl),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(salómonseyskur dalur),
				'one' => q(salómonseyskur dalur),
				'other' => q(salómonseyskir dalir),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
			symbol => 'SDG',
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
			symbol => 'SEK',
			display_name => {
				'currency' => q(sænsk króna),
				'one' => q(sænsk króna),
				'other' => q(sænskar krónur),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(singapúrskur dalur),
				'one' => q(singapúrskur dalur),
				'other' => q(singapúrskir dalir),
			},
		},
		'SHP' => {
			symbol => 'SHP',
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(síerraleónsk ljóna),
				'one' => q(síerraleónsk ljóna),
				'other' => q(síerraleónskar ljónur),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(sómalískur skildingur),
				'one' => q(sómalískur skildingur),
				'other' => q(sómalískir skildingar),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(suðursúdanskt pund),
				'one' => q(suðursúdanskt pund),
				'other' => q(suðursúdönsk pund),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Saó Tóme og Prinsípe-dóbra \(1977–2017\)),
				'one' => q(Saó Tóme og Prinsípe-dóbra \(1977–2017\)),
				'other' => q(Saó Tóme og Prinsípe-dóbrur \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
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
				'one' => q(El Salvador Colon),
				'other' => q(El Salvador Colon),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(sýrlenskt pund),
				'one' => q(sýrlenskt pund),
				'other' => q(sýrlensk pund),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(svasílenskur lílangeni),
				'one' => q(svasílenskur lílangeni),
				'other' => q(svasílenskir lílangenar),
			},
		},
		'THB' => {
			symbol => 'THB',
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
			symbol => 'TJS',
			display_name => {
				'currency' => q(tadsjikskur sómóni),
				'one' => q(tadsjikskur sómóni),
				'other' => q(tadsjikskir sómónar),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Túrkmenskt manat \(1993–2009\)),
				'one' => q(Túrkmenskt manat \(1993–2009\)),
				'other' => q(Túrkmenskt manat \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(túrkmenskt manat),
				'one' => q(túrkmenskt manat),
				'other' => q(túrkmensk manöt),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(túnískur denari),
				'one' => q(túniskur denari),
				'other' => q(túniskir denarar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
			symbol => 'TRY',
			display_name => {
				'currency' => q(tyrknesk líra),
				'one' => q(tyrknesk líra),
				'other' => q(tyrkneskar lírur),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(tansanískur skildingur),
				'one' => q(tansanískur skildingur),
				'other' => q(tansanískir skildingar),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
			symbol => 'UGX',
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(úrúgvæskur pesi),
				'one' => q(úrúgvæskur pesi),
				'other' => q(úrúgvæskir pesar),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
			symbol => 'VEF',
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
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanúatúskt vatú),
				'one' => q(vanúatúskt vatú),
				'other' => q(vanúatúsk vatú),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samóatala),
				'one' => q(Samóatala),
				'other' => q(Samóatölur),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(miðafrískur franki),
				'one' => q(miðafrískur franki),
				'other' => q(miðafrískir frankar),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(unse silfur),
				'one' => q(unse silfur),
				'other' => q(unse silfur),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(unse gull),
				'one' => q(unse gull),
				'other' => q(unse gull),
			},
		},
		'XCD' => {
			symbol => 'EC$',
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
			symbol => 'CFA',
			display_name => {
				'currency' => q(vesturafrískur franki),
				'one' => q(vesturafrískur franki),
				'other' => q(vesturafrískir frankar),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(unse palladín),
				'one' => q(unse palladín),
				'other' => q(unse palladín),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(pólinesískur franki),
				'one' => q(pólinesískur franki),
				'other' => q(pólinesískir frankar),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(unse platína),
				'one' => q(unse platína),
				'other' => q(unse platína),
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
			symbol => 'YER',
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
			symbol => 'ZAR',
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
			symbol => 'ZMW',
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
				'stand-alone' => {
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
					narrow => {
						mon => 'M',
						tue => 'Þ',
						wed => 'M',
						thu => 'F',
						fri => 'F',
						sat => 'L',
						sun => 'S'
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
					abbreviated => {
						mon => 'mán.',
						tue => 'þri.',
						wed => 'mið.',
						thu => 'fim.',
						fri => 'fös.',
						sat => 'lau.',
						sun => 'sun.'
					},
					narrow => {
						mon => 'M',
						tue => 'Þ',
						wed => 'M',
						thu => 'F',
						fri => 'F',
						sat => 'L',
						sun => 'S'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. fjórðungur',
						1 => '2. fjórðungur',
						2 => '3. fjórðungur',
						3 => '4. fjórðungur'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'F1',
						1 => 'F2',
						2 => 'F3',
						3 => 'F4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'persian') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
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
					'am' => q{f.h.},
					'evening1' => q{að kvöldi},
					'afternoon1' => q{síðdegis},
					'morning1' => q{að morgni},
					'noon' => q{hádegi},
					'pm' => q{e.h.},
					'midnight' => q{miðnætti},
					'night1' => q{að nóttu},
				},
				'wide' => {
					'afternoon1' => q{síðdegis},
					'evening1' => q{að kvöldi},
					'morning1' => q{að morgni},
					'am' => q{f.h.},
					'noon' => q{hádegi},
					'midnight' => q{miðnætti},
					'pm' => q{e.h.},
					'night1' => q{að nóttu},
				},
				'narrow' => {
					'midnight' => q{mn.},
					'pm' => q{e.},
					'night1' => q{n.},
					'morning1' => q{mrg.},
					'evening1' => q{kv.},
					'afternoon1' => q{sd.},
					'am' => q{f.},
					'noon' => q{h.},
				},
			},
			'stand-alone' => {
				'wide' => {
					'afternoon1' => q{eftir hádegi},
					'evening1' => q{kvöld},
					'morning1' => q{morgunn},
					'am' => q{f.h.},
					'noon' => q{hádegi},
					'midnight' => q{miðnætti},
					'pm' => q{e.h.},
					'night1' => q{nótt},
				},
				'narrow' => {
					'night1' => q{n.},
					'pm' => q{e.h.},
					'midnight' => q{mn.},
					'noon' => q{hd.},
					'am' => q{f.h.},
					'morning1' => q{mrg.},
					'evening1' => q{kv.},
					'afternoon1' => q{sd.},
				},
				'abbreviated' => {
					'pm' => q{e.h.},
					'midnight' => q{miðnætti},
					'night1' => q{nótt},
					'am' => q{f.h.},
					'evening1' => q{kvöld},
					'afternoon1' => q{síðdegis},
					'morning1' => q{morgunn},
					'noon' => q{hádegi},
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
			narrow => {
				'0' => 'BD'
			},
			wide => {
				'0' => 'búddhadagatal'
			},
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
		'ethiopic' => {
			abbreviated => {
				'0' => 'Tímabil0',
				'1' => 'Tímabil1'
			},
			narrow => {
				'0' => 'Tímabil0',
				'1' => 'Tímabil1'
			},
			wide => {
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
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'Anno Mundi'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
			narrow => {
				'0' => 'Saka'
			},
			wide => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'EH'
			},
			narrow => {
				'0' => 'EH'
			},
			wide => {
				'0' => 'eftir Hijra'
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
				'0' => 'fyrir lýðv. Kína',
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'fyrir lv.K.',
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'fyrir lýðveldi Kína',
				'1' => 'Minguo'
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
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'coptic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'ethiopic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
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
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'indian' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'islamic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'persian' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'roc' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
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
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'coptic' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'ethiopic' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'generic' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
		},
		'indian' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'islamic' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'persian' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'roc' => {
			'full' => q{{1} 'kl'. {0}},
			'long' => q{{1} 'kl'. {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{v – HH:mm:ss},
			Hmv => q{v – HH:mm},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{'viku' W 'í' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
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
		'buddhist' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'hebrew' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'indian' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'islamic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'coptic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'roc' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'persian' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
		'ethiopic' => {
			E => q{ccc},
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
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
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.M.–d.M.},
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
				M => q{M.y – M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y},
				d => q{E, d.M.y – E, d.M.y},
				y => q{E, d.M.y – E, d.M.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d.M.y – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
		'buddhist' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'hebrew' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'indian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'islamic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'coptic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'roc' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'persian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'ethiopic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d. – E, d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
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
				M => q{M.–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E, d.M. – E, d.M.y G},
				d => q{E, d. – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
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
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (sumartími)),
		regionFormat => q({0} (staðaltími)),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistantími#,
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
			exemplarCity => q#Algeirsborg#,
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
			exemplarCity => q#Bissá#,
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
			exemplarCity => q#Kaíró#,
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
			exemplarCity => q#Djibútí#,
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
			exemplarCity => q#Jóhannesarborg#,
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
			exemplarCity => q#Saó Tóme#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípólí#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnisborg#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angvilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antígva#,
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
			exemplarCity => q#Arúba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
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
			exemplarCity => q#Belís#,
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
			exemplarCity => q#Kankún#,
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
			exemplarCity => q#Cayman-eyjar#,
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
			exemplarCity => q#Kostaríka#,
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
			exemplarCity => q#Dóminíka#,
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
			exemplarCity => q#Gvadelúp#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gvæjana#,
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
			exemplarCity => q#Jamaíka#,
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
			exemplarCity => q#Martiník#,
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
			exemplarCity => q#Mexíkóborg#,
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
			exemplarCity => q#Púertó Ríkó#,
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
			exemplarCity => q#Sankti Bartólómeusareyjar#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
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
			exemplarCity => q#Tortóla#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakú#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirút#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brúnei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkútta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
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
			exemplarCity => q#Djakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
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
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kúala Lúmpúr#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kúveit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makaó#,
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
			exemplarCity => q#Níkósía#,
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
			exemplarCity => q#Pjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
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
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
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
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tókýó#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Úlan Bator#,
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
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
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
				'standard' => q#Tíminn á Tímor-Leste#,
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
			exemplarCity => q#Aþena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
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
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kaupmannahöfn#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Sumartími á Írlandi#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gíbraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mön#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbúl#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kænugarður#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
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
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Maríuhöfn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
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
			exemplarCity => q#Róm#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marínó#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevó#,
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
			exemplarCity => q#Sófía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokkhólmur#,
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
			exemplarCity => q#Vatíkanið#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vín#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilníus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsjá#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Jólaey#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kókoseyjar#,
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
			exemplarCity => q#Maldíveyjar#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Máritíus#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
				'standard' => q#Tími á Norfolk-eyju#,
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
				'generic' => q#Tíminn í Omsk#,
				'standard' => q#Staðaltími í Omsk#,
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
			exemplarCity => q#Páskaeyja#,
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
			exemplarCity => q#Fidjí#,
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
			exemplarCity => q#Gvam#,
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
			exemplarCity => q#Marquesas-eyjar#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nárú#,
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
			exemplarCity => q#Palá#,
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
			exemplarCity => q#Tahítí#,
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
				'generic' => q#Tíminn í Yakutsk#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
