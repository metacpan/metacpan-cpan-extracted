=encoding utf8

=head1

Locale::CLDR::Locales::Nl - Package for language Dutch

=cut

package Locale::CLDR::Locales::Nl;
# This file auto generated from Data\common\main\nl.xml
#	on Sun  3 Feb  2:09:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'2d-year' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(honderd),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=e),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=e),
				},
			},
		},
		'number-en' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(een­en­),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(twee­ën­),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drie­ën­),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%spellout-cardinal=­en­),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%spellout-cardinal=­en­),
				},
			},
		},
		'ord-ste' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ste),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(min →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nul),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(een),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(twee),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drie),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(vier),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(vijf),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(zes),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(zeven),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(acht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(negen),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tien),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elf),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(twaalf),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(dertien),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(veertien),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(vijftien),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(zestien),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(zeventien),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(achttien),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(negentien),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%%number-en→]twintig),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%%number-en→]dertig),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%%number-en→]veertig),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%%number-en→]vijftig),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%%number-en→]zestig),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%%number-en→]zeventig),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%%number-en→]tachtig),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%%number-en→]negentig),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(honderd[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­honderd[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(duizend[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←­duizend[­→→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(1000),
					rule => q(←←­duizend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← miljoen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← miljard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← biljoen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← biljard[ →→]),
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
				'-x' => {
					divisor => q(1),
					rule => q(min →→),
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
					rule => q(←←→%%2d-year→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'2100' => {
					base_value => q(2100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'3100' => {
					base_value => q(3100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'4100' => {
					base_value => q(4100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'5100' => {
					base_value => q(5100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'6100' => {
					base_value => q(6100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'7100' => {
					base_value => q(7100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'8100' => {
					base_value => q(8100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'9100' => {
					base_value => q(9100),
					divisor => q(100),
					rule => q(←←→%%2d-year→),
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
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(min →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nulste),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eerste),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(tweede),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(derde),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%spellout-cardinal=de),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(=%spellout-cardinal=ste),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(=%spellout-cardinal=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-cardinal=ste),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(honderd→%%ord-ste→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal←­honderd→%%ord-ste→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(duizend→%%ord-ste→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal←­duizend→%%ord-ste→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal←­miljoen→%%ord-ste→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal←­miljard→%%ord-ste→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal←­biljoen→%%ord-ste→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal←­biljard→%%ord-ste→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
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
				'aa' => 'Afar',
 				'ab' => 'Abchazisch',
 				'ace' => 'Atjehs',
 				'ach' => 'Akoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adygees',
 				'ae' => 'Avestisch',
 				'aeb' => 'Tunesisch Arabisch',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Aino',
 				'ak' => 'Akan',
 				'akk' => 'Akkadisch',
 				'akz' => 'Alabama',
 				'ale' => 'Aleoetisch',
 				'aln' => 'Gegisch',
 				'alt' => 'Zuid-Altaïsch',
 				'am' => 'Amhaars',
 				'an' => 'Aragonees',
 				'ang' => 'Oudengels',
 				'anp' => 'Angika',
 				'ar' => 'Arabisch',
 				'arc' => 'Aramees',
 				'arn' => 'Mapudungun',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho',
 				'arq' => 'Algerijns Arabisch',
 				'ars' => 'Nadjdi-Arabisch',
 				'arw' => 'Arawak',
 				'ary' => 'Marokkaans Arabisch',
 				'arz' => 'Egyptisch Arabisch',
 				'as' => 'Assamees',
 				'asa' => 'Asu',
 				'ase' => 'Amerikaanse Gebarentaal',
 				'ast' => 'Asturisch',
 				'av' => 'Avarisch',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbeidzjaans',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Basjkiers',
 				'bal' => 'Beloetsji',
 				'ban' => 'Balinees',
 				'bar' => 'Beiers',
 				'bas' => 'Basa',
 				'bax' => 'Bamoun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala’',
 				'be' => 'Wit-Russisch',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgaars',
 				'bgn' => 'Westers Beloetsji',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bjn' => 'Banjar',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bengaals',
 				'bo' => 'Tibetaans',
 				'bpy' => 'Bishnupriya',
 				'bqi' => 'Bakhtiari',
 				'br' => 'Bretons',
 				'bra' => 'Braj',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnisch',
 				'bss' => 'Akoose',
 				'bua' => 'Boerjatisch',
 				'bug' => 'Buginees',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Catalaans',
 				'cad' => 'Caddo',
 				'car' => 'Caribisch',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ce' => 'Tsjetsjeens',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Chagatai',
 				'chk' => 'Chuukees',
 				'chm' => 'Mari',
 				'chn' => 'Chinook Jargon',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Soranî',
 				'co' => 'Corsicaans',
 				'cop' => 'Koptisch',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crh' => 'Krim-Tataars',
 				'crs' => 'Seychellencreools',
 				'cs' => 'Tsjechisch',
 				'csb' => 'Kasjoebisch',
 				'cu' => 'Kerkslavisch',
 				'cv' => 'Tsjoevasjisch',
 				'cy' => 'Welsh',
 				'da' => 'Deens',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Duits',
 				'del' => 'Delaware',
 				'den' => 'Slavey',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Nedersorbisch',
 				'dtp' => 'Dusun',
 				'dua' => 'Duala',
 				'dum' => 'Middelnederlands',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egl' => 'Emiliano',
 				'egy' => 'Oudegyptisch',
 				'eka' => 'Ekajuk',
 				'el' => 'Grieks',
 				'elx' => 'Elamitisch',
 				'en' => 'Engels',
 				'en_GB@alt=short' => 'Engels (VK)',
 				'en_US@alt=short' => 'Engels (VS)',
 				'enm' => 'Middelengels',
 				'eo' => 'Esperanto',
 				'es' => 'Spaans',
 				'esu' => 'Yupik',
 				'et' => 'Estisch',
 				'eu' => 'Baskisch',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremeens',
 				'fa' => 'Perzisch',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fulah',
 				'fi' => 'Fins',
 				'fil' => 'Filipijns',
 				'fit' => 'Tornedal-Fins',
 				'fj' => 'Fijisch',
 				'fo' => 'Faeröers',
 				'fon' => 'Fon',
 				'fr' => 'Frans',
 				'frc' => 'Cajun-Frans',
 				'frm' => 'Middelfrans',
 				'fro' => 'Oudfrans',
 				'frp' => 'Arpitaans',
 				'frr' => 'Noord-Fries',
 				'frs' => 'Oost-Fries',
 				'fur' => 'Friulisch',
 				'fy' => 'Fries',
 				'ga' => 'Iers',
 				'gaa' => 'Ga',
 				'gag' => 'Gagaoezisch',
 				'gan' => 'Ganyu',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gbz' => 'Zoroastrisch Dari',
 				'gd' => 'Schots-Gaelisch',
 				'gez' => 'Ge’ez',
 				'gil' => 'Gilbertees',
 				'gl' => 'Galicisch',
 				'glk' => 'Gilaki',
 				'gmh' => 'Middelhoogduits',
 				'gn' => 'Guaraní',
 				'goh' => 'Oudhoogduits',
 				'gom' => 'Goa Konkani',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gothisch',
 				'grb' => 'Grebo',
 				'grc' => 'Oudgrieks',
 				'gsw' => 'Zwitserduits',
 				'gu' => 'Gujarati',
 				'guc' => 'Wayuu',
 				'gur' => 'Gurune',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'hak' => 'Hakka',
 				'haw' => 'Hawaïaans',
 				'he' => 'Hebreeuws',
 				'hi' => 'Hindi',
 				'hif' => 'Fijisch Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hettitisch',
 				'hmn' => 'Hmong',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Kroatisch',
 				'hsb' => 'Oppersorbisch',
 				'hsn' => 'Xiangyu',
 				'ht' => 'Haïtiaans Creools',
 				'hu' => 'Hongaars',
 				'hup' => 'Hupa',
 				'hy' => 'Armeens',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesisch',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Yi',
 				'ik' => 'Inupiaq',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingoesjetisch',
 				'io' => 'Ido',
 				'is' => 'IJslands',
 				'it' => 'Italiaans',
 				'iu' => 'Inuktitut',
 				'izh' => 'Ingrisch',
 				'ja' => 'Japans',
 				'jam' => 'Jamaicaans Creools',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Judeo-Perzisch',
 				'jrb' => 'Judeo-Arabisch',
 				'jut' => 'Jutlands',
 				'jv' => 'Javaans',
 				'ka' => 'Georgisch',
 				'kaa' => 'Karakalpaks',
 				'kab' => 'Kabylisch',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardisch',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kaapverdisch Creools',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'kho' => 'Khotanees',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Khowar',
 				'ki' => 'Gikuyu',
 				'kiu' => 'Kirmanckî',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazachs',
 				'kkj' => 'Kako',
 				'kl' => 'Groenlands',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaans',
 				'koi' => 'Komi-Permjaaks',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraeaans',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karatsjaj-Balkarisch',
 				'kri' => 'Krio',
 				'krj' => 'Kinaray-a',
 				'krl' => 'Karelisch',
 				'kru' => 'Kurukh',
 				'ks' => 'Kasjmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kölsch',
 				'ku' => 'Koerdisch',
 				'kum' => 'Koemuks',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'ky' => 'Kirgizisch',
 				'la' => 'Latijn',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Luxemburgs',
 				'lez' => 'Lezgisch',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'Luganda',
 				'li' => 'Limburgs',
 				'lij' => 'Ligurisch',
 				'liv' => 'Lijfs',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombardisch',
 				'ln' => 'Lingala',
 				'lo' => 'Laotiaans',
 				'lol' => 'Mongo',
 				'lou' => 'Louisiana-Creools',
 				'loz' => 'Lozi',
 				'lrc' => 'Noordelijk Luri',
 				'lt' => 'Litouws',
 				'ltg' => 'Letgaals',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Lets',
 				'lzh' => 'Klassiek Chinees',
 				'lzz' => 'Lazisch',
 				'mad' => 'Madoerees',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makassaars',
 				'man' => 'Mandingo',
 				'mas' => 'Maa',
 				'mde' => 'Maba',
 				'mdf' => 'Moksja',
 				'mdr' => 'Mandar',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagassisch',
 				'mga' => 'Middeliers',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshallees',
 				'mi' => 'Maori',
 				'mic' => 'Mi’kmaq',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedonisch',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongools',
 				'mnc' => 'Mantsjoe',
 				'mni' => 'Meitei',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'mrj' => 'West-Mari',
 				'ms' => 'Maleis',
 				'mt' => 'Maltees',
 				'mua' => 'Mundang',
 				'mul' => 'Meerdere talen',
 				'mus' => 'Creek',
 				'mwl' => 'Mirandees',
 				'mwr' => 'Marwari',
 				'mwv' => 'Mentawai',
 				'my' => 'Birmaans',
 				'mye' => 'Myene',
 				'myv' => 'Erzja',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauruaans',
 				'nan' => 'Minnanyu',
 				'nap' => 'Napolitaans',
 				'naq' => 'Nama',
 				'nb' => 'Noors - Bokmål',
 				'nd' => 'Noord-Ndebele',
 				'nds' => 'Nedersaksisch',
 				'nds_NL' => 'Nederduits',
 				'ne' => 'Nepalees',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niueaans',
 				'njo' => 'Ao Naga',
 				'nl' => 'Nederlands',
 				'nmg' => 'Ngumba',
 				'nn' => 'Noors - Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Noors',
 				'nog' => 'Nogai',
 				'non' => 'Oudnoors',
 				'nov' => 'Novial',
 				'nqo' => 'N’Ko',
 				'nr' => 'Zuid-Ndbele',
 				'nso' => 'Noord-Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Klassiek Nepalbhasa',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Occitaans',
 				'oj' => 'Ojibwa',
 				'om' => 'Afaan Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetisch',
 				'osa' => 'Osage',
 				'ota' => 'Ottomaans-Turks',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pal' => 'Pahlavi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiaments',
 				'pau' => 'Palaus',
 				'pcd' => 'Picardisch',
 				'pcm' => 'Nigeriaans Pidgin',
 				'pdc' => 'Pennsylvania-Duits',
 				'pdt' => 'Plautdietsch',
 				'peo' => 'Oudperzisch',
 				'pfl' => 'Paltsisch',
 				'phn' => 'Foenicisch',
 				'pi' => 'Pali',
 				'pl' => 'Pools',
 				'pms' => 'Piëmontees',
 				'pnt' => 'Pontisch',
 				'pon' => 'Pohnpeiaans',
 				'prg' => 'Oudpruisisch',
 				'pro' => 'Oudprovençaals',
 				'ps' => 'Pasjtoe',
 				'ps@alt=variant' => 'Pashto',
 				'pt' => 'Portugees',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'qug' => 'Kichwa',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rgn' => 'Romagnol',
 				'rif' => 'Riffijns',
 				'rm' => 'Reto-Romaans',
 				'rn' => 'Kirundi',
 				'ro' => 'Roemeens',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
 				'root' => 'Root',
 				'rtm' => 'Rotumaans',
 				'ru' => 'Russisch',
 				'rue' => 'Roetheens',
 				'rug' => 'Roviana',
 				'rup' => 'Aroemeens',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskriet',
 				'sad' => 'Sandawe',
 				'sah' => 'Jakoets',
 				'sam' => 'Samaritaans-Aramees',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'saz' => 'Saurashtra',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardijns',
 				'scn' => 'Siciliaans',
 				'sco' => 'Schots',
 				'sd' => 'Sindhi',
 				'sdc' => 'Sassarees',
 				'sdh' => 'Pahlavani',
 				'se' => 'Noord-Samisch',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkoeps',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Oudiers',
 				'sgs' => 'Samogitisch',
 				'sh' => 'Servo-Kroatisch',
 				'shi' => 'Tashelhiyt',
 				'shn' => 'Shan',
 				'shu' => 'Tsjadisch Arabisch',
 				'si' => 'Singalees',
 				'sid' => 'Sidamo',
 				'sk' => 'Slowaaks',
 				'sl' => 'Sloveens',
 				'sli' => 'Silezisch Duits',
 				'sly' => 'Selayar',
 				'sm' => 'Samoaans',
 				'sma' => 'Zuid-Samisch',
 				'smj' => 'Lule-Samisch',
 				'smn' => 'Inari-Samisch',
 				'sms' => 'Skolt-Samisch',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somalisch',
 				'sog' => 'Sogdisch',
 				'sq' => 'Albanees',
 				'sr' => 'Servisch',
 				'srn' => 'Sranantongo',
 				'srr' => 'Serer',
 				'ss' => 'Swazi',
 				'ssy' => 'Saho',
 				'st' => 'Zuid-Sotho',
 				'stq' => 'Saterfries',
 				'su' => 'Soendanees',
 				'suk' => 'Sukuma',
 				'sus' => 'Soesoe',
 				'sux' => 'Soemerisch',
 				'sv' => 'Zweeds',
 				'sw' => 'Swahili',
 				'swb' => 'Shimaore',
 				'syc' => 'Klassiek Syrisch',
 				'syr' => 'Syrisch',
 				'szl' => 'Silezisch',
 				'ta' => 'Tamil',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetun',
 				'tg' => 'Tadzjieks',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmeens',
 				'tkl' => 'Tokelaus',
 				'tkr' => 'Tsakhur',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tly' => 'Talysh',
 				'tmh' => 'Tamashek',
 				'tn' => 'Tswana',
 				'to' => 'Tongaans',
 				'tog' => 'Nyasa Tonga',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turks',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonisch',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tataars',
 				'ttt' => 'Moslim Tat',
 				'tum' => 'Toemboeka',
 				'tvl' => 'Tuvaluaans',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitiaans',
 				'tyv' => 'Toevaans',
 				'tzm' => 'Tamazight (Centraal-Marokko)',
 				'udm' => 'Oedmoerts',
 				'ug' => 'Oeigoers',
 				'uga' => 'Oegaritisch',
 				'uk' => 'Oekraïens',
 				'umb' => 'Umbundu',
 				'und' => 'onbekende taal',
 				'ur' => 'Urdu',
 				'uz' => 'Oezbeeks',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vec' => 'Venetiaans',
 				'vep' => 'Wepsisch',
 				'vi' => 'Vietnamees',
 				'vls' => 'West-Vlaams',
 				'vmf' => 'Opperfrankisch',
 				'vo' => 'Volapük',
 				'vot' => 'Votisch',
 				'vro' => 'Võro',
 				'vun' => 'Vunjo',
 				'wa' => 'Waals',
 				'wae' => 'Walser',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Wuyu',
 				'xal' => 'Kalmuks',
 				'xh' => 'Xhosa',
 				'xmf' => 'Mingreels',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapees',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jiddisch',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonees',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotec',
 				'zbl' => 'Blissymbolen',
 				'zea' => 'Zeeuws',
 				'zen' => 'Zenaga',
 				'zgh' => 'Standaard Marokkaanse Tamazight',
 				'zh' => 'Chinees',
 				'zu' => 'Zoeloe',
 				'zun' => 'Zuni',
 				'zxx' => 'geen linguïstische inhoud',
 				'zza' => 'Zaza',

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
			'Adlm' => 'Adlam',
 			'Afak' => 'Defaka',
 			'Aghb' => 'Kaukasisch Albanees',
 			'Ahom' => 'Ahom',
 			'Arab' => 'Arabisch',
 			'Arab@alt=variant' => 'Perso-Arabisch',
 			'Armi' => 'Keizerlijk Aramees',
 			'Armn' => 'Armeens',
 			'Avst' => 'Avestaans',
 			'Bali' => 'Balinees',
 			'Bamu' => 'Bamoun',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bengaals',
 			'Bhks' => 'Bhaiksuki',
 			'Blis' => 'Blissymbolen',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Buginees',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Verenigde Canadese Aboriginal-symbolen',
 			'Cari' => 'Carisch',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptisch',
 			'Cprt' => 'Cyprisch',
 			'Cyrl' => 'Cyrillisch',
 			'Cyrs' => 'Oudkerkslavisch Cyrillisch',
 			'Deva' => 'Devanagari',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployan snelschrift',
 			'Egyd' => 'Egyptisch demotisch',
 			'Egyh' => 'Egyptisch hiëratisch',
 			'Egyp' => 'Egyptische hiërogliefen',
 			'Elba' => 'Elbasan',
 			'Ethi' => 'Ethiopisch',
 			'Geok' => 'Georgisch Khutsuri',
 			'Geor' => 'Georgisch',
 			'Glag' => 'Glagolitisch',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gothisch',
 			'Gran' => 'Grantha',
 			'Grek' => 'Grieks',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Hanb',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'vereenvoudigd',
 			'Hans@alt=stand-alone' => 'vereenvoudigd Chinees',
 			'Hant' => 'traditioneel',
 			'Hant@alt=stand-alone' => 'traditioneel Chinees',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Hebreeuws',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Anatolische hiërogliefen',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Katakana of Hiragana',
 			'Hung' => 'Oudhongaars',
 			'Inds' => 'Indus',
 			'Ital' => 'Oud-italisch',
 			'Jamo' => 'Jamo',
 			'Java' => 'Javaans',
 			'Jpan' => 'Japans',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreaans',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laotiaans',
 			'Latf' => 'Gotisch Latijns',
 			'Latg' => 'Gaelisch Latijns',
 			'Latn' => 'Latijns',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Lineair A',
 			'Linb' => 'Lineair B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lycisch',
 			'Lydi' => 'Lydisch',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandaeans',
 			'Mani' => 'Manicheaans',
 			'Marc' => 'Marchen',
 			'Maya' => 'Mayahiërogliefen',
 			'Medf' => 'Medefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitisch cursief',
 			'Mero' => 'Meroïtisch',
 			'Mlym' => 'Malayalam',
 			'Modi' => 'Modi',
 			'Mong' => 'Mongools',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei',
 			'Mult' => 'Multani',
 			'Mymr' => 'Birmaans',
 			'Narb' => 'Oud Noord-Arabisch',
 			'Nbat' => 'Nabateaans',
 			'Newa' => 'Newari',
 			'Nkgb' => 'Naxi Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Odia',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmyreens',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Oudpermisch',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Inscriptioneel Pahlavi',
 			'Phlp' => 'Psalmen Pahlavi',
 			'Phlv' => 'Boek Pahlavi',
 			'Phnx' => 'Foenicisch',
 			'Plrd' => 'Pollard-fonetisch',
 			'Prti' => 'Inscriptioneel Parthisch',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi Rohingya',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runic',
 			'Samr' => 'Samaritaans',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Oud Zuid-Arabisch',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'Shavian',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Sindhi',
 			'Sinh' => 'Singalees',
 			'Sogd' => 'Sogdisch',
 			'Sogo' => 'Oud Sogdisch',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Soendanees',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syriac',
 			'Syre' => 'Estrangelo Aramees',
 			'Syrj' => 'West-Aramees',
 			'Syrn' => 'Oost-Aramees',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Nieuw Tai Lue',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibetaans',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritisch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Zichtbare spraak',
 			'Wara' => 'Varang Kshiti',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Oudperzisch',
 			'Xsux' => 'Sumero-Akkadian Cuneiform',
 			'Yiii' => 'Yi',
 			'Zanb' => 'vierkant Zanabazar',
 			'Zinh' => 'Overgeërfd',
 			'Zmth' => 'Wiskundige notatie',
 			'Zsye' => 'emoji',
 			'Zsym' => 'Symbolen',
 			'Zxxx' => 'ongeschreven',
 			'Zyyy' => 'algemeen',
 			'Zzzz' => 'onbekend schriftsysteem',

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
			'001' => 'wereld',
 			'002' => 'Afrika',
 			'003' => 'Noord-Amerika',
 			'005' => 'Zuid-Amerika',
 			'009' => 'Oceanië',
 			'011' => 'West-Afrika',
 			'013' => 'Midden-Amerika',
 			'014' => 'Oost-Afrika',
 			'015' => 'Noord-Afrika',
 			'017' => 'Centraal-Afrika',
 			'018' => 'Zuidelijk Afrika',
 			'019' => 'Amerika',
 			'021' => 'Noordelijk Amerika',
 			'029' => 'Caribisch gebied',
 			'030' => 'Oost-Azië',
 			'034' => 'Zuid-Azië',
 			'035' => 'Zuidoost-Azië',
 			'039' => 'Zuid-Europa',
 			'053' => 'Australazië',
 			'054' => 'Melanesië',
 			'057' => 'Micronesische regio',
 			'061' => 'Polynesië',
 			'142' => 'Azië',
 			'143' => 'Centraal-Azië',
 			'145' => 'West-Azië',
 			'150' => 'Europa',
 			'151' => 'Oost-Europa',
 			'154' => 'Noord-Europa',
 			'155' => 'West-Europa',
 			'202' => 'Sub-Saharaans Afrika',
 			'419' => 'Latijns-Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Verenigde Arabische Emiraten',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua en Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanië',
 			'AM' => 'Armenië',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentinië',
 			'AS' => 'Amerikaans-Samoa',
 			'AT' => 'Oostenrijk',
 			'AU' => 'Australië',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Azerbeidzjan',
 			'BA' => 'Bosnië en Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'België',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarije',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribisch Nederland',
 			'BR' => 'Brazilië',
 			'BS' => 'Bahama’s',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouveteiland',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Cocoseilanden',
 			'CD' => 'Congo-Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Centraal-Afrikaanse Republiek',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'Congo (Republiek)',
 			'CH' => 'Zwitserland',
 			'CI' => 'Ivoorkust',
 			'CI@alt=variant' => 'Republiek Ivoorkust',
 			'CK' => 'Cookeilanden',
 			'CL' => 'Chili',
 			'CM' => 'Kameroen',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Kaapverdië',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmaseiland',
 			'CY' => 'Cyprus',
 			'CZ' => 'Tsjechië',
 			'CZ@alt=variant' => 'Tsjechische Republiek',
 			'DE' => 'Duitsland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denemarken',
 			'DM' => 'Dominica',
 			'DO' => 'Dominicaanse Republiek',
 			'DZ' => 'Algerije',
 			'EA' => 'Ceuta en Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egypte',
 			'EH' => 'Westelijke Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanje',
 			'ET' => 'Ethiopië',
 			'EU' => 'Europese Unie',
 			'EZ' => 'eurozone',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandeilanden',
 			'FK@alt=variant' => 'Falklandeilanden (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Faeröer',
 			'FR' => 'Frankrijk',
 			'GA' => 'Gabon',
 			'GB' => 'Verenigd Koninkrijk',
 			'GB@alt=short' => 'VK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgië',
 			'GF' => 'Frans-Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinee',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatoriaal-Guinea',
 			'GR' => 'Griekenland',
 			'GS' => 'Zuid-Georgia en Zuidelijke Sandwicheilanden',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinee-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong SAR van China',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard en McDonaldeilanden',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatië',
 			'HT' => 'Haïti',
 			'HU' => 'Hongarije',
 			'IC' => 'Canarische Eilanden',
 			'ID' => 'Indonesië',
 			'IE' => 'Ierland',
 			'IL' => 'Israël',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Brits Indische Oceaanterritorium',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'IJsland',
 			'IT' => 'Italië',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordanië',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgizië',
 			'KH' => 'Cambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoren',
 			'KN' => 'Saint Kitts en Nevis',
 			'KP' => 'Noord-Korea',
 			'KR' => 'Zuid-Korea',
 			'KW' => 'Koeweit',
 			'KY' => 'Kaaimaneilanden',
 			'KZ' => 'Kazachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litouwen',
 			'LU' => 'Luxemburg',
 			'LV' => 'Letland',
 			'LY' => 'Libië',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavië',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalleilanden',
 			'MK' => 'Macedonië',
 			'MK@alt=variant' => 'Macedonië (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birma)',
 			'MN' => 'Mongolië',
 			'MO' => 'Macau SAR van China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Noordelijke Marianen',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritanië',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldiven',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Maleisië',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibië',
 			'NC' => 'Nieuw-Caledonië',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederland',
 			'NO' => 'Noorwegen',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nieuw-Zeeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Frans-Polynesië',
 			'PG' => 'Papoea-Nieuw-Guinea',
 			'PH' => 'Filipijnen',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint-Pierre en Miquelon',
 			'PN' => 'Pitcairneilanden',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestijnse gebieden',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'overig Oceanië',
 			'RE' => 'Réunion',
 			'RO' => 'Roemenië',
 			'RS' => 'Servië',
 			'RU' => 'Rusland',
 			'RW' => 'Rwanda',
 			'SA' => 'Saoedi-Arabië',
 			'SB' => 'Salomonseilanden',
 			'SC' => 'Seychellen',
 			'SD' => 'Soedan',
 			'SE' => 'Zweden',
 			'SG' => 'Singapore',
 			'SH' => 'Sint-Helena',
 			'SI' => 'Slovenië',
 			'SJ' => 'Spitsbergen en Jan Mayen',
 			'SK' => 'Slowakije',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalië',
 			'SR' => 'Suriname',
 			'SS' => 'Zuid-Soedan',
 			'ST' => 'Sao Tomé en Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint-Maarten',
 			'SY' => 'Syrië',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- en Caicoseilanden',
 			'TD' => 'Tsjaad',
 			'TF' => 'Franse Gebieden in de zuidelijke Indische Oceaan',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadzjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Oost-Timor',
 			'TL@alt=variant' => 'Democratische Republiek Oost-Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesië',
 			'TO' => 'Tonga',
 			'TR' => 'Turkije',
 			'TT' => 'Trinidad en Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Oekraïne',
 			'UG' => 'Oeganda',
 			'UM' => 'Kleine afgelegen eilanden van de Verenigde Staten',
 			'UN' => 'Verenigde Naties',
 			'UN@alt=short' => 'VN',
 			'US' => 'Verenigde Staten',
 			'US@alt=short' => 'VS',
 			'UY' => 'Uruguay',
 			'UZ' => 'Oezbekistan',
 			'VA' => 'Vaticaanstad',
 			'VC' => 'Saint Vincent en de Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Britse Maagdeneilanden',
 			'VI' => 'Amerikaanse Maagdeneilanden',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis en Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Zuid-Afrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'onbekend gebied',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Traditionele Duitse spelling',
 			'1994' => 'Gestandaardiseerde Resiaanse spelling',
 			'1996' => 'Duitse spelling van 1996',
 			'1606NICT' => 'Laat Middelfrans tot 1606',
 			'1694ACAD' => 'Vroeg modern Frans',
 			'1959ACAD' => 'Academisch',
 			'ABL1943' => 'Spellingsformulering van 1943',
 			'AKUAPEM' => 'Akuapem',
 			'ALALC97' => 'Romanisering ALA-LC, editie 1997',
 			'ALUKU' => 'Aloekoe-dialect',
 			'AO1990' => 'Portugese spellingsovereenkomst van 1990',
 			'AREVELA' => 'Oost-Armeens',
 			'AREVMDA' => 'West-Armeens',
 			'ASANTE' => 'Asante',
 			'BAKU1926' => 'Eenvormig Turkse Latijnse alfabet',
 			'BALANKA' => 'Balanka-dialect van Anii',
 			'BARLA' => 'Barlavento-dialectgroep van Kabuverdianu',
 			'BASICENG' => 'Standaard Engels',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Biskajaans',
 			'BISKE' => 'San Giorgio/Bila-dialect',
 			'BOHORIC' => 'Bohorič-alfabet',
 			'BOONT' => 'Boontling',
 			'COLB1945' => 'Portugese-Braziliaanse spellingsverdrag van 1945',
 			'CORNU' => 'Cornu',
 			'DAJNKO' => 'Dajnko-alfabet',
 			'EKAVSK' => 'Servisch met Ekaviaanse uitspraak',
 			'EMODENG' => 'Vroegmodern Engels',
 			'FONIPA' => 'Internationaal Fonetisch Alfabet',
 			'FONNAPA' => 'Fonnapa',
 			'FONUPA' => 'Oeralisch Fonetisch Alfabet',
 			'FONXSAMP' => 'Transcriptie volgens X-SAMPA',
 			'HEPBURN' => 'Hepburn-romanisering',
 			'HOGNORSK' => 'Hoognoors',
 			'HSISTEMO' => 'H-sistemo',
 			'IJEKAVSK' => 'Servisch met Ijekaviaanse uitspraak',
 			'ITIHASA' => 'Episch Sanskriet',
 			'IVANCHOV' => 'Ivanchov',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Algemene spelling',
 			'KOCIEWIE' => 'Kociewie',
 			'KSCOR' => 'Standaardspelling',
 			'LAUKIKA' => 'Laukika',
 			'LIPAW' => 'Het Lipovaz-dialect van het Resiaans',
 			'LUNA1918' => 'Russische spelling van 1917',
 			'METELKO' => 'Metelko-alfabet',
 			'MONOTON' => 'Monotonaal',
 			'NDYUKA' => 'Ndyuka-dialect',
 			'NEDIS' => 'Natisone-dialect',
 			'NEWFOUND' => 'Newfound',
 			'NJIVA' => 'Gniva/Njiva-dialect',
 			'NULIK' => 'Modern Volapük',
 			'OSOJS' => 'Oseacco/Osojane-dialect',
 			'OXENDICT' => 'Spelling volgens het Oxford English Dictionary',
 			'PAHAWH2' => 'Pahawh2',
 			'PAHAWH3' => 'Pahawh3',
 			'PAHAWH4' => 'Pahawh4',
 			'PAMAKA' => 'Pamaka',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'Pinyin',
 			'POLYTON' => 'Polytonaal',
 			'POSIX' => 'Computer',
 			'PUTER' => 'Puter',
 			'REVISED' => 'Gewijzigde spelling',
 			'RIGIK' => 'Klassiek Volapük',
 			'ROZAJ' => 'Resiaans',
 			'RUMGR' => 'Rumgr',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Schots standaard-Engels',
 			'SCOUSE' => 'Liverpools (Scouse)',
 			'SIMPLE' => 'Simpel',
 			'SOLBA' => 'Stolvizza/Solbica-dialect',
 			'SOTAV' => 'Sotavento-dialectgroep van Kabuverdianu',
 			'SPANGLIS' => 'Spanglis',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilvan',
 			'SUTSILV' => 'Sutsilvan',
 			'TARASK' => 'Taraskievica-spelling',
 			'UCCOR' => 'Eenvormige spelling',
 			'UCRCOR' => 'Eenvormig herziene spelling',
 			'ULSTER' => 'Ulster',
 			'UNIFON' => 'Unifon fonetisch alfabet',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valenciaans',
 			'VALLADER' => 'Vallader',
 			'WADEGILE' => 'Wade-Giles-romanisering',
 			'XSISTEMO' => 'X-sistemo',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'kalender',
 			'cf' => 'valutanotatie',
 			'colalternate' => 'Sorteren van symbolen negeren',
 			'colbackwards' => 'Omgekeerd sorteren op accenten',
 			'colcasefirst' => 'Indelen op hoofdletters/kleine letters',
 			'colcaselevel' => 'Hoofdlettergevoelig sorteren',
 			'collation' => 'sorteervolgorde',
 			'colnormalization' => 'Genormaliseerd sorteren',
 			'colnumeric' => 'Numeriek sorteren',
 			'colstrength' => 'Sorteervoorrang',
 			'currency' => 'valuta',
 			'hc' => 'uursysteem (12 of 24)',
 			'lb' => 'stijl regelafbreking',
 			'ms' => 'maatsysteem',
 			'numbers' => 'cijfers',
 			'timezone' => 'Tijdzone',
 			'va' => 'Landvariant',
 			'x' => 'Privégebruik',

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
 				'buddhist' => q{Boeddhistische kalender},
 				'chinese' => q{Chinese kalender},
 				'coptic' => q{Koptische kalender},
 				'dangi' => q{Dangi-kalender},
 				'ethiopic' => q{Ethiopische kalender},
 				'ethiopic-amete-alem' => q{Ethiopische Amete Alem-kalender},
 				'gregorian' => q{Gregoriaanse kalender},
 				'hebrew' => q{Hebreeuwse kalender},
 				'indian' => q{Indiase nationale kalender},
 				'islamic' => q{Islamitische kalender},
 				'islamic-civil' => q{Islamitische kalender (cyclisch)},
 				'islamic-rgsa' => q{Islamitische kalender (Saudi–Arabië)},
 				'islamic-tbla' => q{Islamitische kalender (epoche)},
 				'islamic-umalqura' => q{Islamitische kalender (Umm al-Qura)},
 				'iso8601' => q{ISO-8601-kalender},
 				'japanese' => q{Japanse kalender},
 				'persian' => q{Perzische kalender},
 				'roc' => q{Kalender van de Chinese Republiek},
 			},
 			'cf' => {
 				'account' => q{financiële valutanotatie},
 				'standard' => q{standaard valutanotatie},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Symbolen sorteren},
 				'shifted' => q{Sorteren zonder symbolen},
 			},
 			'colbackwards' => {
 				'no' => q{Normaal sorteren op accenten},
 				'yes' => q{Omgekeerd sorteren op accenten},
 			},
 			'colcasefirst' => {
 				'lower' => q{Eerst sorteren op kleine letters},
 				'no' => q{Sorteervolgorde algemeen hoofdlettergebruik},
 				'upper' => q{Eerst sorteren op hoofdletters},
 			},
 			'colcaselevel' => {
 				'no' => q{Niet hoofdlettergevoelig sorteren},
 				'yes' => q{Hoofdlettergevoelig sorteren},
 			},
 			'collation' => {
 				'big5han' => q{Traditioneel-Chinese sorteervolgorde - Big5},
 				'compat' => q{vorige sorteervolgorde, voor compatibiliteit},
 				'dictionary' => q{Woordenboeksorteervolgorde},
 				'ducet' => q{standaard Unicode-sorteervolgorde},
 				'emoji' => q{emojisorteervolgorde},
 				'eor' => q{Europese sorteerregels},
 				'gb2312han' => q{Vereenvoudigd-Chinese sorteervolgorde - GB2312},
 				'phonebook' => q{Telefoonboeksorteervolgorde},
 				'phonetic' => q{Fonetische sorteervolgorde},
 				'pinyin' => q{Pinyinvolgorde},
 				'reformed' => q{Herziene sorteervolgorde},
 				'search' => q{algemeen zoeken},
 				'searchjl' => q{Zoeken op eerste Hangul-medeklinker},
 				'standard' => q{standaard sorteervolgorde},
 				'stroke' => q{Streeksorteervolgorde},
 				'traditional' => q{Traditionele sorteervolgorde},
 				'unihan' => q{Sorteervolgorde radicalen/strepen},
 				'zhuyin' => q{Zhuyinvolgorde},
 			},
 			'colnormalization' => {
 				'no' => q{Zonder normalisatie sorteren},
 				'yes' => q{Unicode genormaliseerd sorteren},
 			},
 			'colnumeric' => {
 				'no' => q{Cijfers afzonderlijk sorteren},
 				'yes' => q{Cijfers numeriek sorteren},
 			},
 			'colstrength' => {
 				'identical' => q{Alles sorteren},
 				'primary' => q{Alleen sorteren op letters},
 				'quaternary' => q{Sorteren op accenten/hoofdlettergebruik/breedte/Kana},
 				'secondary' => q{Sorteren op accenten},
 				'tertiary' => q{Sorteren op accenten/hoofdlettergebruik/breedte},
 			},
 			'd0' => {
 				'fwidth' => q{Volledige breedte},
 				'hwidth' => q{Halve breedte},
 				'npinyin' => q{Numeriek},
 			},
 			'hc' => {
 				'h11' => q{12-uursysteem (0-11)},
 				'h12' => q{12-uursysteem (1-12)},
 				'h23' => q{24-uursysteem (0-23)},
 				'h24' => q{24-uursysteem (1-24)},
 			},
 			'lb' => {
 				'loose' => q{losse stijl regelafbreking},
 				'normal' => q{normale stijl regelafbreking},
 				'strict' => q{strikte stijl regelafbreking},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{metriek stelsel},
 				'uksystem' => q{Brits imperiaal stelsel},
 				'ussystem' => q{Amerikaans imperiaal stelsel},
 			},
 			'numbers' => {
 				'ahom' => q{Ahom cijfers},
 				'arab' => q{Arabisch-Indische cijfers},
 				'arabext' => q{uitgebreide Arabisch-Indische cijfers},
 				'armn' => q{Armeense cijfers},
 				'armnlow' => q{kleine Armeense cijfers},
 				'bali' => q{Balinese cijfers},
 				'beng' => q{Bengaalse cijfers},
 				'brah' => q{Brahmi cijfers},
 				'cakm' => q{Chakma cijfers},
 				'cham' => q{Cham cijfers},
 				'cyrl' => q{Cyrillische cijfers},
 				'deva' => q{Devanagari cijfers},
 				'ethi' => q{Ethiopische cijfers},
 				'finance' => q{Financiële cijfers},
 				'fullwide' => q{cijfers met volledige breedte},
 				'geor' => q{Georgische cijfers},
 				'gong' => q{Gunjala Gondi cijfers},
 				'gonm' => q{Masaram Gondi cijfers},
 				'grek' => q{Griekse cijfers},
 				'greklow' => q{kleine Griekse cijfers},
 				'gujr' => q{Gujarati cijfers},
 				'guru' => q{Gurmukhi cijfers},
 				'hanidec' => q{Chinese decimale getallen},
 				'hans' => q{vereenvoudigd Chinese cijfers},
 				'hansfin' => q{vereenvoudigd Chinese financiële cijfers},
 				'hant' => q{traditioneel Chinese cijfers},
 				'hantfin' => q{traditioneel Chinese financiële cijfers},
 				'hebr' => q{Hebreeuwse cijfers},
 				'hmng' => q{Pahawh Hmong cijfers},
 				'java' => q{Javaanse cijfers},
 				'jpan' => q{Japanse cijfers},
 				'jpanfin' => q{Japanse financiële cijfers},
 				'kali' => q{Kayah Li cijfers},
 				'khmr' => q{Khmer cijfers},
 				'knda' => q{Kannada cijfers},
 				'lana' => q{Tai Tham Hora cijfers},
 				'lanatham' => q{Tai Tham Tham cijfers},
 				'laoo' => q{Laotiaanse cijfers},
 				'latn' => q{Westerse cijfers},
 				'lepc' => q{Lepcha cijfers},
 				'limb' => q{Limbu cijfers},
 				'mathbold' => q{vette wiskundige cijfers},
 				'mathdbl' => q{wiskundige cijfers met dubbele lijn},
 				'mathmono' => q{niet-proportionele wiskundige cijfers},
 				'mathsanb' => q{schreefloze vette wiskundige cijfers},
 				'mathsans' => q{schreefloze wiskundige cijfers},
 				'mlym' => q{Malayalam cijfers},
 				'modi' => q{Modi cijfers},
 				'mong' => q{Mongoolse cijfers},
 				'mroo' => q{Mro cijfers},
 				'mtei' => q{Meetei Mayek cijfers},
 				'mymr' => q{Myanmarese cijfers},
 				'mymrshan' => q{Myanmarese Shan cijfers},
 				'mymrtlng' => q{Myanmar Tai Laing cijfers},
 				'native' => q{Binnenlandse cijfers},
 				'nkoo' => q{N’Ko cijfers},
 				'olck' => q{Ol Chiki cijfers},
 				'orya' => q{Odia cijfers},
 				'osma' => q{Osmanya cijfers},
 				'rohg' => q{Hanifi Rohingya cijfers},
 				'roman' => q{Romeinse cijfers},
 				'romanlow' => q{kleine Romeinse cijfers},
 				'saur' => q{Saurashtra cijfers},
 				'shrd' => q{Sharada cijfers},
 				'sind' => q{Khudawadi cijfers},
 				'sinh' => q{Sinhala Lith cijfers},
 				'sora' => q{Sora Sompeng cijfers},
 				'sund' => q{Sundanese cijfers},
 				'takr' => q{Takri cijfers},
 				'talu' => q{nieuwe Tai Lue cijfers},
 				'taml' => q{traditionele Tamil cijfers},
 				'tamldec' => q{Tamil cijfers},
 				'telu' => q{Telugu cijfers},
 				'thai' => q{Thaise cijfers},
 				'tibt' => q{Tibetaanse cijfers},
 				'tirh' => q{Tirhuta cijfers},
 				'traditional' => q{Traditionele cijfers},
 				'vaii' => q{Vai-cijfers},
 				'wara' => q{Warang Citi cijfers},
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
			'metric' => q{metriek},
 			'UK' => q{Brits},
 			'US' => q{Amerikaans},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Taal: {0}',
 			'script' => 'Schrift: {0}',
 			'region' => 'Regio: {0}',

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
			auxiliary => qr{[à â å ã æ ç è ê î ñ ô ø œ ù û ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á ä b c d e é ë f g h i í ï {ij} {íj́} j k l m n o ó ö p q r s t u ú ü v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> qq{‘},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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
						'name' => q(windstreek),
					},
					'acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					'ampere' => {
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					'arc-minute' => {
						'name' => q(boogminuten),
						'one' => q({0} boogminuut),
						'other' => q({0} boogminuten),
					},
					'arc-second' => {
						'name' => q(boogseconden),
						'one' => q({0} boogseconde),
						'other' => q({0} boogseconden),
					},
					'astronomical-unit' => {
						'name' => q(astronomische eenheid),
						'one' => q({0} astronomische eenheid),
						'other' => q({0} astronomische eenheden),
					},
					'atmosphere' => {
						'name' => q(atmosfeer),
						'one' => q({0} atmosfeer),
						'other' => q({0} atmosfeer),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'bushel' => {
						'name' => q(bushel),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(calorie),
						'one' => q({0} calorie),
						'other' => q({0} calorieën),
					},
					'carat' => {
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					'celsius' => {
						'name' => q(graden Celsius),
						'one' => q({0} graad Celsius),
						'other' => q({0} graden Celsius),
					},
					'centiliter' => {
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					'centimeter' => {
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					'century' => {
						'name' => q(eeuwen),
						'one' => q({0} eeuw),
						'other' => q({0} eeuwen),
					},
					'coordinate' => {
						'east' => q({0} oosterlengte),
						'north' => q({0} noorderbreedte),
						'south' => q({0} zuiderbreedte),
						'west' => q({0} westerlengte),
					},
					'cubic-centimeter' => {
						'name' => q(kubieke centimeter),
						'one' => q({0} kubieke centimeter),
						'other' => q({0} kubieke centimeter),
						'per' => q({0} per kubieke centimeter),
					},
					'cubic-foot' => {
						'name' => q(kubieke voet),
						'one' => q({0} kubieke voet),
						'other' => q({0} kubieke voet),
					},
					'cubic-inch' => {
						'name' => q(kubieke inch),
						'one' => q({0} kubieke inch),
						'other' => q({0} kubieke inch),
					},
					'cubic-kilometer' => {
						'name' => q(kubieke kilometer),
						'one' => q({0} kubieke kilometer),
						'other' => q({0} kubieke kilometer),
					},
					'cubic-meter' => {
						'name' => q(kubieke meter),
						'one' => q({0} kubieke meter),
						'other' => q({0} kubieke meter),
						'per' => q({0} per kubieke meter),
					},
					'cubic-mile' => {
						'name' => q(kubieke mijl),
						'one' => q({0} kubieke mijl),
						'other' => q({0} kubieke mijl),
					},
					'cubic-yard' => {
						'name' => q(kubieke yard),
						'one' => q({0} kubieke yard),
						'other' => q({0} kubieke yard),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					'cup-metric' => {
						'name' => q(metrische cup),
						'one' => q({0} metrische cup),
						'other' => q({0} metrische cup),
					},
					'day' => {
						'name' => q(dagen),
						'one' => q({0} dag),
						'other' => q({0} dagen),
						'per' => q({0} per dag),
					},
					'deciliter' => {
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					'decimeter' => {
						'name' => q(decimeter),
						'one' => q({0} decimeter),
						'other' => q({0} decimeter),
					},
					'degree' => {
						'name' => q(booggraden),
						'one' => q({0} booggraad),
						'other' => q({0} booggraden),
					},
					'fahrenheit' => {
						'name' => q(graden Fahrenheit),
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} graden Fahrenheit),
					},
					'fathom' => {
						'name' => q(vadem),
						'one' => q({0} vadem),
						'other' => q({0} vadems),
					},
					'fluid-ounce' => {
						'name' => q(fluid ounce),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounce),
					},
					'foodcalorie' => {
						'name' => q(kilocalorie),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalorieën),
					},
					'foot' => {
						'name' => q(voet),
						'one' => q({0} voet),
						'other' => q({0} voet),
						'per' => q({0} per voet),
					},
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					'g-force' => {
						'name' => q(G-krachten),
						'one' => q({0} G-kracht),
						'other' => q({0} G-krachten),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					'gallon-imperial' => {
						'name' => q(imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0} per imp. gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					'gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'name' => q(hectare),
						'one' => q({0} hectare),
						'other' => q({0} hectare),
					},
					'hectoliter' => {
						'name' => q(hectoliter),
						'one' => q({0} hectoliter),
						'other' => q({0} hectoliter),
					},
					'hectopascal' => {
						'name' => q(hectopascal),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(paardenkrachten),
						'one' => q({0} paardenkracht),
						'other' => q({0} paardenkrachten),
					},
					'hour' => {
						'name' => q(uur),
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0} per uur),
					},
					'inch' => {
						'name' => q(inches),
						'one' => q({0} inch),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					'inch-hg' => {
						'name' => q(inch-kwikdruk),
						'one' => q({0} inch-kwikdruk),
						'other' => q({0} inch-kwikdruk),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					'kilobyte' => {
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					'kilocalorie' => {
						'name' => q(kilocalorie),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalorieën),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					'kilometer' => {
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometer per uur),
						'one' => q({0} kilometer per uur),
						'other' => q({0} kilometer per uur),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowattuur),
						'one' => q({0} kilowattuur),
						'other' => q({0} kilowattuur),
					},
					'knot' => {
						'name' => q(knoop),
						'one' => q({0} knoop),
						'other' => q({0} knopen),
					},
					'light-year' => {
						'name' => q(lichtjaar),
						'one' => q({0} lichtjaar),
						'other' => q({0} lichtjaar),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					'megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					'meter-per-second' => {
						'name' => q(meter per seconde),
						'one' => q({0} meter per seconde),
						'other' => q({0} meter per seconde),
					},
					'meter-per-second-squared' => {
						'name' => q(meter per seconde kwadraat),
						'one' => q({0} meter per seconde kwadraat),
						'other' => q({0} meter per seconde kwadraat),
					},
					'metric-ton' => {
						'name' => q(tonne),
						'one' => q({0} tonne),
						'other' => q({0} tonnes),
					},
					'microgram' => {
						'name' => q(microgram),
						'one' => q({0} microgram),
						'other' => q({0} microgram),
					},
					'micrometer' => {
						'name' => q(micrometer),
						'one' => q({0} micrometer),
						'other' => q({0} micrometer),
					},
					'microsecond' => {
						'name' => q(microseconden),
						'one' => q({0} microseconde),
						'other' => q({0} microseconden),
					},
					'mile' => {
						'name' => q(mijl),
						'one' => q({0} mijl),
						'other' => q({0} mijl),
					},
					'mile-per-gallon' => {
						'name' => q(mijl per gallon),
						'one' => q({0} mijl per gallon),
						'other' => q({0} mijl per gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mijl per imp. gallon),
						'one' => q({0} mijl per imp. gallon),
						'other' => q({0} mijl per imp. gallon),
					},
					'mile-per-hour' => {
						'name' => q(mijl per uur),
						'one' => q({0} mijl per uur),
						'other' => q({0} mijl per uur),
					},
					'mile-scandinavian' => {
						'name' => q(Scandinavische mijl),
						'one' => q({0} Scandinavische mijl),
						'other' => q({0} Scandinavische mijl),
					},
					'milliampere' => {
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligram per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligram per deciliter),
					},
					'milliliter' => {
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					'millimeter' => {
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeter-kwikdruk),
						'one' => q({0} millimeter-kwikdruk),
						'other' => q({0} millimeter-kwikdruk),
					},
					'millimole-per-liter' => {
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					'millisecond' => {
						'name' => q(milliseconden),
						'one' => q({0} milliseconde),
						'other' => q({0} milliseconden),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(minuten),
						'one' => q({0} minuut),
						'other' => q({0} minuten),
						'per' => q({0} per minuut),
					},
					'month' => {
						'name' => q(maanden),
						'one' => q({0} maand),
						'other' => q({0} maanden),
						'per' => q({0} per maand),
					},
					'nanometer' => {
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					'nanosecond' => {
						'name' => q(nanoseconden),
						'one' => q({0} nanoseconde),
						'other' => q({0} nanoseconden),
					},
					'nautical-mile' => {
						'name' => q(zeemijl),
						'one' => q({0} zeemijl),
						'other' => q({0} zeemijlen),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(ounce),
						'one' => q({0} ounce),
						'other' => q({0} ounce),
						'per' => q({0} per ounce),
					},
					'ounce-troy' => {
						'name' => q(troy ounce),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounce),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'percent' => {
						'name' => q(procent),
						'one' => q({0} procent),
						'other' => q({0} procent),
					},
					'permille' => {
						'name' => q(promille),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					'petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					'picometer' => {
						'name' => q(picometer),
						'one' => q({0} picometer),
						'other' => q({0} picometer),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(metrische pint),
						'one' => q({0} metrische pint),
						'other' => q({0} metrische pint),
					},
					'point' => {
						'name' => q(punten),
						'one' => q({0} punt),
						'other' => q({0} punten),
					},
					'pound' => {
						'name' => q(pound),
						'one' => q({0} pound),
						'other' => q({0} pound),
						'per' => q({0} per pound),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					'radian' => {
						'name' => q(radiaal),
						'one' => q({0} radiaal),
						'other' => q({0} radialen),
					},
					'revolution' => {
						'name' => q(toeren),
						'one' => q({0} toer),
						'other' => q({0} toeren),
					},
					'second' => {
						'name' => q(seconden),
						'one' => q({0} seconde),
						'other' => q({0} seconden),
						'per' => q({0} per seconde),
					},
					'square-centimeter' => {
						'name' => q(vierkante centimeter),
						'one' => q({0} vierkante centimeter),
						'other' => q({0} vierkante centimeter),
						'per' => q({0} per vierkante centimeter),
					},
					'square-foot' => {
						'name' => q(vierkante voet),
						'one' => q({0} vierkante voet),
						'other' => q({0} vierkante voet),
					},
					'square-inch' => {
						'name' => q(vierkante inch),
						'one' => q({0} vierkante inch),
						'other' => q({0} vierkante inch),
						'per' => q({0} per vierkante inch),
					},
					'square-kilometer' => {
						'name' => q(vierkante kilometer),
						'one' => q({0} vierkante kilometer),
						'other' => q({0} vierkante kilometer),
						'per' => q({0} per vierkante kilometer),
					},
					'square-meter' => {
						'name' => q(vierkante meter),
						'one' => q({0} vierkante meter),
						'other' => q({0} vierkante meter),
						'per' => q({0} per vierkante meter),
					},
					'square-mile' => {
						'name' => q(vierkante mijl),
						'one' => q({0} vierkante mijl),
						'other' => q({0} vierkante mijl),
						'per' => q({0} per vierkante mijl),
					},
					'square-yard' => {
						'name' => q(vierkante yard),
						'one' => q({0} vierkante yard),
						'other' => q({0} vierkante yard),
					},
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					'tablespoon' => {
						'name' => q(eetlepel),
						'one' => q({0} eetlepel),
						'other' => q({0} eetlepels),
					},
					'teaspoon' => {
						'name' => q(theelepel),
						'one' => q({0} theelepel),
						'other' => q({0} theelepels),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					'terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(weken),
						'one' => q({0} week),
						'other' => q({0} weken),
						'per' => q({0} per week),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					'year' => {
						'name' => q(jaar),
						'one' => q({0} jaar),
						'other' => q({0} jaar),
						'per' => q({0} per jaar),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(windstreek),
					},
					'acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre ft),
						'one' => q({0} l/m²),
						'other' => q({0} l/m²),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'bushel' => {
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
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
						'name' => q(eeuwen),
						'one' => q({0} eeuw),
						'other' => q({0} eeuwen),
					},
					'coordinate' => {
						'east' => q({0} OL),
						'north' => q({0} NB),
						'south' => q({0} ZB),
						'west' => q({0} WL),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
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
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					'day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
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
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(G),
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
						'name' => q(imp. gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
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
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
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
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					'hour' => {
						'name' => q(u),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0}"),
						'other' => q({0}"),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
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
						'name' => q(kJ),
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
						'name' => q(km/u),
						'one' => q({0} km/u),
						'other' => q({0} km/u),
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
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lx),
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
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
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
						'name' => q(m/s),
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
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mijl/imp. gal),
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
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
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'month' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
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
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(promille),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
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
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(tr),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(el),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
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
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(w),
						'one' => q({0} w),
						'other' => q({0} w),
						'per' => q({0}/w),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(jr),
						'one' => q({0} jr),
						'other' => q({0} jr),
						'per' => q({0}/jr),
					},
				},
				'short' => {
					'' => {
						'name' => q(windstreek),
					},
					'acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'bushel' => {
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
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
						'name' => q(eeuwen),
						'one' => q({0} eeuw),
						'other' => q({0} eeuwen),
					},
					'coordinate' => {
						'east' => q({0} OL),
						'north' => q({0} NB),
						'south' => q({0} ZB),
						'west' => q({0} WL),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
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
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					'cup-metric' => {
						'name' => q(metrische cup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(dagen),
						'one' => q({0} dag),
						'other' => q({0} dagen),
						'per' => q({0}/dag),
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
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(G),
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
						'name' => q(imp. gal),
						'one' => q({0} imp. gal),
						'other' => q({0} imp. gal),
						'per' => q({0}/imp. gal),
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
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
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
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					'hour' => {
						'name' => q(uur),
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0}/uur),
					},
					'inch' => {
						'name' => q(inches),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
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
						'name' => q(kJ),
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
						'name' => q(km/u),
						'one' => q({0} km/u),
						'other' => q({0} km/u),
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
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lx),
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
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
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
						'name' => q(m/s),
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
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mijl/imp. gal),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
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
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(mnd),
						'one' => q({0} mnd),
						'other' => q({0} mnd),
						'per' => q({0}/mnd),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
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
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(procent),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(promille),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(punten),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
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
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0} sec),
						'other' => q({0} sec),
						'per' => q({0}/sec),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0} per cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0} per in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0} per km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0} per m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0} per mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(el),
						'one' => q({0} el),
						'other' => q({0} el),
					},
					'teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
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
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(wk),
						'one' => q({0} wk),
						'other' => q({0} wkn),
						'per' => q({0}/wk),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(jr),
						'one' => q({0} jr),
						'other' => q({0} jr),
						'per' => q({0}/jr),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nee|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
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
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‎-‎),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+‎),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(٫),
		},
		'bali' => {
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
		'beng' => {
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
		'brah' => {
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
		'cakm' => {
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
		'cham' => {
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
		'deva' => {
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
		'fullwide' => {
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
		'gong' => {
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
		'gonm' => {
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
		'gujr' => {
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
		'guru' => {
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
		'hanidec' => {
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
		'java' => {
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
		'kali' => {
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
		'khmr' => {
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
		'knda' => {
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
		'lana' => {
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
		'lanatham' => {
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
		'laoo' => {
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
		'lepc' => {
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
		'limb' => {
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
		'mlym' => {
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
		'mong' => {
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
		'mtei' => {
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
		'mymr' => {
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
		'mymrshan' => {
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
		'nkoo' => {
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
		'olck' => {
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
		'orya' => {
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
		'osma' => {
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
		'rohg' => {
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
		'saur' => {
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
		'shrd' => {
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
		'sora' => {
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
		'sund' => {
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
		'takr' => {
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
		'talu' => {
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
		'tamldec' => {
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
		'telu' => {
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
		'thai' => {
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
		'tibt' => {
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
		'vaii' => {
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
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0 mln'.'',
					'other' => '0 mln'.'',
				},
				'10000000' => {
					'one' => '00 mln'.'',
					'other' => '00 mln'.'',
				},
				'100000000' => {
					'one' => '000 mln'.'',
					'other' => '000 mln'.'',
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
					'one' => '0 bln'.'',
					'other' => '0 bln'.'',
				},
				'10000000000000' => {
					'one' => '00 bln'.'',
					'other' => '00 bln'.'',
				},
				'100000000000000' => {
					'one' => '000 bln'.'',
					'other' => '000 bln'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 duizend',
					'other' => '0 duizend',
				},
				'10000' => {
					'one' => '00 duizend',
					'other' => '00 duizend',
				},
				'100000' => {
					'one' => '000 duizend',
					'other' => '000 duizend',
				},
				'1000000' => {
					'one' => '0 miljoen',
					'other' => '0 miljoen',
				},
				'10000000' => {
					'one' => '00 miljoen',
					'other' => '00 miljoen',
				},
				'100000000' => {
					'one' => '000 miljoen',
					'other' => '000 miljoen',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljard',
				},
				'10000000000' => {
					'one' => '00 miljard',
					'other' => '00 miljard',
				},
				'100000000000' => {
					'one' => '000 miljard',
					'other' => '000 miljard',
				},
				'1000000000000' => {
					'one' => '0 biljoen',
					'other' => '0 biljoen',
				},
				'10000000000000' => {
					'one' => '00 biljoen',
					'other' => '00 biljoen',
				},
				'100000000000000' => {
					'one' => '000 biljoen',
					'other' => '000 biljoen',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0 mln'.'',
					'other' => '0 mln'.'',
				},
				'10000000' => {
					'one' => '00 mln'.'',
					'other' => '00 mln'.'',
				},
				'100000000' => {
					'one' => '000 mln'.'',
					'other' => '000 mln'.'',
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
					'one' => '0 bln'.'',
					'other' => '0 bln'.'',
				},
				'10000000000000' => {
					'one' => '00 bln'.'',
					'other' => '00 bln'.'',
				},
				'100000000000000' => {
					'one' => '000 bln'.'',
					'other' => '000 bln'.'',
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
		'arab' => {
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
		'arabext' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'bali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'beng' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'brah' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'cakm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'cham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'deva' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'fullwide' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'gong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'gonm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'gujr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'guru' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'hanidec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'java' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'kali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'khmr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'knda' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'lana' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'lanatham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'laoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'lepc' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'limb' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mlym' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mtei' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mymr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mymrshan' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'nkoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'olck' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'orya' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'osma' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'rohg' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'saur' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'shrd' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'sora' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'sund' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'takr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'talu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'tamldec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'telu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'thai' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'tibt' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'vaii' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '¤ -#,##0.00',
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
		'ADP' => {
			symbol => 'ADP',
			display_name => {
				'currency' => q(Andorrese peseta),
				'one' => q(Andorrese peseta),
				'other' => q(Andorrese peseta),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Verenigde Arabische Emiraten-dirham),
				'one' => q(VAE-dirham),
				'other' => q(VAE-dirham),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(Afghani \(1927–2002\)),
				'one' => q(Afghani \(AFA\)),
				'other' => q(Afghani \(AFA\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghaanse afghani),
				'one' => q(Afghaanse afghani),
				'other' => q(Afghaanse afghani),
			},
		},
		'ALK' => {
			symbol => 'ALK',
			display_name => {
				'currency' => q(Albanese lek \(1946–1965\)),
				'one' => q(Albanese lek \(1946–1965\)),
				'other' => q(Albanese lek \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albanese lek),
				'one' => q(Albanese lek),
				'other' => q(Albanese lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armeense dram),
				'one' => q(Armeense dram),
				'other' => q(Armeense dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Nederlands-Antilliaanse gulden),
				'one' => q(Nederlands-Antilliaanse gulden),
				'other' => q(Nederlands-Antilliaanse gulden),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angolese kwanza),
				'one' => q(Angolese kwanza),
				'other' => q(Angolese kwanza),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(Angolese kwanza \(1977–1990\)),
				'one' => q(Angolese kwanza \(1977–1990\)),
				'other' => q(Angolese kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(Angolese nieuwe kwanza \(1990–2000\)),
				'one' => q(Angolese nieuwe kwanza \(1990–2000\)),
				'other' => q(Angolese nieuwe kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(Angolese kwanza reajustado \(1995–1999\)),
				'one' => q(Angolese kwanza reajustado \(1995–1999\)),
				'other' => q(Angolese kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(Argentijnse austral),
				'one' => q(Argentijnse austral),
				'other' => q(Argentijnse austral),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(Argentijnse peso ley \(1970–1983\)),
				'one' => q(Argentijnse peso ley \(1970–1983\)),
				'other' => q(Argentijnse peso ley \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(Argentijnse peso \(1881–1970\)),
				'one' => q(Argentijnse peso \(1881–1970\)),
				'other' => q(Argentijnse peso \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(Argentijnse peso \(1983–1985\)),
				'one' => q(Argentijnse peso \(1983–1985\)),
				'other' => q(Argentijnse peso \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentijnse peso),
				'one' => q(Argentijnse peso),
				'other' => q(Argentijnse peso),
			},
		},
		'ATS' => {
			symbol => 'ATS',
			display_name => {
				'currency' => q(Oostenrijkse schilling),
				'one' => q(Oostenrijkse schilling),
				'other' => q(Oostenrijkse schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australische dollar),
				'one' => q(Australische dollar),
				'other' => q(Australische dollar),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Arubaanse gulden),
				'one' => q(Arubaanse gulden),
				'other' => q(Arubaanse gulden),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(Azerbeidzjaanse manat \(1993–2006\)),
				'one' => q(Azerbeidzjaanse manat \(1993–2006\)),
				'other' => q(Azerbeidzjaanse manat \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Azerbeidzjaanse manat),
				'one' => q(Azerbeidzjaanse manat),
				'other' => q(Azerbeidzjaanse manat),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(Bosnische dinar),
				'one' => q(Bosnische dinar),
				'other' => q(Bosnische dinar),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosnische convertibele mark),
				'one' => q(Bosnische convertibele mark),
				'other' => q(Bosnische convertibele mark),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(Nieuwe Bosnische dinar \(1994–1997\)),
				'one' => q(Nieuwe Bosnische dinar \(1994–1997\)),
				'other' => q(Nieuwe Bosnische dinar \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbadaanse dollar),
				'one' => q(Barbadaanse dollar),
				'other' => q(Barbadaanse dollar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bengalese taka),
				'one' => q(Bengalese taka),
				'other' => q(Bengalese taka),
			},
		},
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(Belgische frank \(convertibel\)),
				'one' => q(Belgische frank \(convertibel\)),
				'other' => q(Belgische frank \(convertibel\)),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(Belgische frank),
				'one' => q(Belgische frank),
				'other' => q(Belgische frank),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(Belgische frank \(financieel\)),
				'one' => q(Belgische frank \(financieel\)),
				'other' => q(Belgische frank \(financieel\)),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(Bulgaarse harde lev),
				'one' => q(Bulgaarse harde lev),
				'other' => q(Bulgaarse harde lev),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(Bulgaarse socialistische lev),
				'one' => q(Bulgaarse socialistische lev),
				'other' => q(Bulgaarse socialistische lev),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bulgaarse lev),
				'one' => q(Bulgaarse lev),
				'other' => q(Bulgaarse leva),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(Bulgaarse lev \(1879–1952\)),
				'one' => q(Bulgaarse lev \(1879–1952\)),
				'other' => q(Bulgaarse lev \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahreinse dinar),
				'one' => q(Bahreinse dinar),
				'other' => q(Bahreinse dinar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundese frank),
				'one' => q(Burundese frank),
				'other' => q(Burundese frank),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda-dollar),
				'one' => q(Bermuda-dollar),
				'other' => q(Bermuda-dollar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Bruneise dollar),
				'one' => q(Bruneise dollar),
				'other' => q(Bruneise dollar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviaanse boliviano),
				'one' => q(Boliviaanse boliviano),
				'other' => q(Boliviaanse boliviano),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(Boliviaanse boliviano \(1863–1963\)),
				'one' => q(Boliviaanse boliviano \(1863–1963\)),
				'other' => q(Boliviaanse boliviano \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(Boliviaanse peso),
				'one' => q(Boliviaanse peso),
				'other' => q(Boliviaanse peso),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(Boliviaanse mvdol),
				'one' => q(Boliviaanse mvdol),
				'other' => q(Boliviaanse mvdol),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(Braziliaanse cruzeiro novo \(1967–1986\)),
				'one' => q(Braziliaanse cruzeiro novo \(1967–1986\)),
				'other' => q(Braziliaanse cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(Braziliaanse cruzado),
				'one' => q(Braziliaanse cruzado),
				'other' => q(Braziliaanse cruzado),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(Braziliaanse cruzeiro \(1990–1993\)),
				'one' => q(Braziliaanse cruzeiro \(1990–1993\)),
				'other' => q(Braziliaanse cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Braziliaanse real),
				'one' => q(Braziliaanse real),
				'other' => q(Braziliaanse real),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(Braziliaanse nieuwe cruzado \(1989–1990\)),
				'one' => q(Braziliaanse cruzado novo),
				'other' => q(Braziliaanse cruzado novo),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(Braziliaanse cruzeiro),
				'one' => q(Braziliaanse cruzeiro),
				'other' => q(Braziliaanse cruzeiro),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(Braziliaanse cruzeiro \(1942–1967\)),
				'one' => q(Braziliaanse cruzeiro \(1942–1967\)),
				'other' => q(Braziliaanse cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahamaanse dollar),
				'one' => q(Bahamaanse dollar),
				'other' => q(Bahamaanse dollar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Bhutaanse ngultrum),
				'one' => q(Bhutaanse ngultrum),
				'other' => q(Bhutaanse ngultrum),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(Birmese kyat),
				'one' => q(Birmese kyat),
				'other' => q(Birmese kyat),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botswaanse pula),
				'one' => q(Botswaanse pula),
				'other' => q(Botswaanse pula),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(Wit-Russische nieuwe roebel \(1994–1999\)),
				'one' => q(Wit-Russische nieuwe roebel \(1994–1999\)),
				'other' => q(Wit-Russische nieuwe roebel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Wit-Russische roebel),
				'one' => q(Wit-Russische roebel),
				'other' => q(Wit-Russische roebel),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Wit-Russische roebel \(2000–2016\)),
				'one' => q(Wit-Russische roebel \(2000–2016\)),
				'other' => q(Wit-Russische roebel \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Belizaanse dollar),
				'one' => q(Belizaanse dollar),
				'other' => q(Belizaanse dollar),
			},
		},
		'CAD' => {
			symbol => 'C$',
			display_name => {
				'currency' => q(Canadese dollar),
				'one' => q(Canadese dollar),
				'other' => q(Canadese dollar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Congolese frank),
				'one' => q(Congolese frank),
				'other' => q(Congolese frank),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(WIR euro),
				'one' => q(WIR euro),
				'other' => q(WIR euro),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Zwitserse frank),
				'one' => q(Zwitserse frank),
				'other' => q(Zwitserse frank),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(WIR franc),
				'one' => q(WIR franc),
				'other' => q(WIR franc),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(Chileense escudo),
				'one' => q(Chileense escudo),
				'other' => q(Chileense escudo),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(Chileense unidades de fomento),
				'one' => q(Chileense unidades de fomento),
				'other' => q(Chileense unidades de fomento),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Chileense peso),
				'one' => q(Chileense peso),
				'other' => q(Chileense peso),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Chinese renminbi \(offshore\)),
				'one' => q(Chinese yuan \(offshore\)),
				'other' => q(Chinese yuan \(offshore\)),
			},
		},
		'CNX' => {
			symbol => 'CNX',
			display_name => {
				'currency' => q(dollar van de Chinese Volksbank),
				'one' => q(dollar van de Chinese Volksbank),
				'other' => q(dollar van de Chinese Volksbank),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Chinese yuan),
				'one' => q(Chinese yuan),
				'other' => q(Chinese yuan),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Colombiaanse peso),
				'one' => q(Colombiaanse peso),
				'other' => q(Colombiaanse peso),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(Unidad de Valor Real),
				'one' => q(Unidad de Valor Real),
				'other' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Costa Ricaanse colon),
				'one' => q(Costa Ricaanse colon),
				'other' => q(Costa Ricaanse colon),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(Oude Servische dinar),
				'one' => q(Oude Servische dinar),
				'other' => q(Oude Servische dinar),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(Tsjechoslowaakse harde koruna),
				'one' => q(Tsjechoslowaakse harde koruna),
				'other' => q(Tsjechoslowaakse harde koruna),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Cubaanse convertibele peso),
				'one' => q(Cubaanse convertibele peso),
				'other' => q(Cubaanse convertibele peso),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Cubaanse peso),
				'one' => q(Cubaanse peso),
				'other' => q(Cubaanse peso),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Kaapverdische escudo),
				'one' => q(Kaapverdische escudo),
				'other' => q(Kaapverdische escudo),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(Cyprisch pond),
				'one' => q(Cyprisch pond),
				'other' => q(Cyprisch pond),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Tsjechische kroon),
				'one' => q(Tsjechische kroon),
				'other' => q(Tsjechische kronen),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(Oost-Duitse ostmark),
				'one' => q(Oost-Duitse ostmark),
				'other' => q(Oost-Duitse ostmark),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(Duitse mark),
				'one' => q(Duitse mark),
				'other' => q(Duitse mark),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Djiboutiaanse frank),
				'one' => q(Djiboutiaanse frank),
				'other' => q(Djiboutiaanse frank),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Deense kroon),
				'one' => q(Deense kroon),
				'other' => q(Deense kronen),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominicaanse peso),
				'one' => q(Dominicaanse peso),
				'other' => q(Dominicaanse peso),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Algerijnse dinar),
				'one' => q(Algerijnse dinar),
				'other' => q(Algerijnse dinar),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(Ecuadoraanse sucre),
				'one' => q(Ecuadoraanse sucre),
				'other' => q(Ecuadoraanse sucre),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(Ecuadoraanse unidad de valor constante \(UVC\)),
				'one' => q(Ecuadoraanse unidad de valor constante \(UVC\)),
				'other' => q(Ecuadoraanse unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(Estlandse kroon),
				'one' => q(Estlandse kroon),
				'other' => q(Estlandse kroon),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Egyptisch pond),
				'one' => q(Egyptisch pond),
				'other' => q(Egyptisch pond),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritrese nakfa),
				'one' => q(Eritrese nakfa),
				'other' => q(Eritrese nakfa),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(Spaanse peseta \(account A\)),
				'one' => q(Spaanse peseta \(account A\)),
				'other' => q(Spaanse peseta \(account A\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(Spaanse peseta \(convertibele account\)),
				'one' => q(Spaanse peseta \(convertibele account\)),
				'other' => q(Spaanse peseta \(convertibele account\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(Spaanse peseta),
				'one' => q(Spaanse peseta),
				'other' => q(Spaanse peseta),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Ethiopische birr),
				'one' => q(Ethiopische birr),
				'other' => q(Ethiopische birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(Finse markka),
				'one' => q(Finse markka),
				'other' => q(Finse markka),
			},
		},
		'FJD' => {
			symbol => 'FJ$',
			display_name => {
				'currency' => q(Fiji-dollar),
				'one' => q(Fiji-dollar),
				'other' => q(Fiji-dollar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Falklandeilands pond),
				'one' => q(Falklandeilands pond),
				'other' => q(Falklandeilands pond),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(Franse franc),
				'one' => q(Franse franc),
				'other' => q(Franse franc),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Brits pond),
				'one' => q(Brits pond),
				'other' => q(Brits pond),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(Georgische kupon larit),
				'one' => q(Georgische kupon larit),
				'other' => q(Georgische kupon larit),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Georgische lari),
				'one' => q(Georgische lari),
				'other' => q(Georgische lari),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(Ghanese cedi \(1979–2007\)),
				'one' => q(Ghanese cedi \(1979–2007\)),
				'other' => q(Ghanese cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ghanese cedi),
				'one' => q(Ghanese cedi),
				'other' => q(Ghanese cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltarees pond),
				'one' => q(Gibraltarees pond),
				'other' => q(Gibraltarees pond),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambiaanse dalasi),
				'one' => q(Gambiaanse dalasi),
				'other' => q(Gambiaanse dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Guinese frank),
				'one' => q(Guinese frank),
				'other' => q(Guinese frank),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(Guinese syli),
				'one' => q(Guinese syli),
				'other' => q(Guinese syli),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(Equatoriaal-Guinese ekwele guineana),
				'one' => q(Equatoriaal-Guinese ekwele guineana),
				'other' => q(Equatoriaal-Guinese ekwele guineana),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(Griekse drachme),
				'one' => q(Griekse drachme),
				'other' => q(Griekse drachme),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guatemalteekse quetzal),
				'one' => q(Guatemalteekse quetzal),
				'other' => q(Guatemalteekse quetzal),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(Portugees-Guinese escudo),
				'one' => q(Portugees-Guinese escudo),
				'other' => q(Portugees-Guinese escudo),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(Guinee-Bissause peso),
				'one' => q(Guinee-Bissause peso),
				'other' => q(Guinee-Bissause peso),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Guyaanse dollar),
				'one' => q(Guyaanse dollar),
				'other' => q(Guyaanse dollar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hongkongse dollar),
				'one' => q(Hongkongse dollar),
				'other' => q(Hongkongse dollar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Hondurese lempira),
				'one' => q(Hondurese lempira),
				'other' => q(Hondurese lempira),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(Kroatische dinar),
				'one' => q(Kroatische dinar),
				'other' => q(Kroatische dinar),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kroatische kuna),
				'one' => q(Kroatische kuna),
				'other' => q(Kroatische kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haïtiaanse gourde),
				'one' => q(Haïtiaanse gourde),
				'other' => q(Haïtiaanse gourde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Hongaarse forint),
				'one' => q(Hongaarse forint),
				'other' => q(Hongaarse forint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesische roepia),
				'one' => q(Indonesische roepia),
				'other' => q(Indonesische roepia),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(Iers pond),
				'one' => q(Iers pond),
				'other' => q(Iers pond),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(Israëlisch pond),
				'one' => q(Israëlisch pond),
				'other' => q(Israëlisch pond),
			},
		},
		'ILR' => {
			symbol => 'ILR',
			display_name => {
				'currency' => q(Israëlische sjekel \(1980–1985\)),
				'one' => q(Israëlische sjekel \(1980–1985\)),
				'other' => q(Israëlische sjekel \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Israëlische nieuwe shekel),
				'one' => q(Israëlische nieuwe shekel),
				'other' => q(Israëlische nieuwe shekel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Indiase roepie),
				'one' => q(Indiase roepie),
				'other' => q(Indiase roepie),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Iraakse dinar),
				'one' => q(Iraakse dinar),
				'other' => q(Iraakse dinar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Iraanse rial),
				'one' => q(Iraanse rial),
				'other' => q(Iraanse rial),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(IJslandse kroon \(1918–1981\)),
				'one' => q(IJslandse kroon \(1918–1981\)),
				'other' => q(IJslandse kronen \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(IJslandse kroon),
				'one' => q(IJslandse kroon),
				'other' => q(IJslandse kronen),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(Italiaanse lire),
				'one' => q(Italiaanse lire),
				'other' => q(Italiaanse lire),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaicaanse dollar),
				'one' => q(Jamaicaanse dollar),
				'other' => q(Jamaicaanse dollar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jordaanse dinar),
				'one' => q(Jordaanse dinar),
				'other' => q(Jordaanse dinar),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Japanse yen),
				'one' => q(Japanse yen),
				'other' => q(Japanse yen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Keniaanse shilling),
				'one' => q(Keniaanse shilling),
				'other' => q(Keniaanse shilling),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kirgizische som),
				'one' => q(Kirgizische som),
				'other' => q(Kirgizische som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Cambodjaanse riel),
				'one' => q(Cambodjaanse riel),
				'other' => q(Cambodjaanse riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Comorese frank),
				'one' => q(Comorese frank),
				'other' => q(Comorese frank),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Noord-Koreaanse won),
				'one' => q(Noord-Koreaanse won),
				'other' => q(Noord-Koreaanse won),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(Zuid-Koreaanse hwan \(1953–1962\)),
				'one' => q(Zuid-Koreaanse hwan \(1953–1962\)),
				'other' => q(Zuid-Koreaanse hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(Oude Zuid-Koreaanse won \(1945–1953\)),
				'one' => q(oude Zuid-Koreaanse won \(1945–1953\)),
				'other' => q(oude Zuid-Koreaanse won \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Zuid-Koreaanse won),
				'one' => q(Zuid-Koreaanse won),
				'other' => q(Zuid-Koreaanse won),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Koeweitse dinar),
				'one' => q(Koeweitse dinar),
				'other' => q(Koeweitse dinar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kaaimaneilandse dollar),
				'one' => q(Kaaimaneilandse dollar),
				'other' => q(Kaaimaneilandse dollar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kazachse tenge),
				'one' => q(Kazachse tenge),
				'other' => q(Kazachse tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laotiaanse kip),
				'one' => q(Laotiaanse kip),
				'other' => q(Laotiaanse kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libanees pond),
				'one' => q(Libanees pond),
				'other' => q(Libanees pond),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri Lankaanse roepie),
				'one' => q(Sri Lankaanse roepie),
				'other' => q(Sri Lankaanse roepie),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberiaanse dollar),
				'one' => q(Liberiaanse dollar),
				'other' => q(Liberiaanse dollar),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(Lesothaanse loti),
				'one' => q(Lesothaanse loti),
				'other' => q(Lesothaanse loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litouwse litas),
				'one' => q(Litouwse litas),
				'other' => q(Litouwse litas),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(Litouwse talonas),
				'one' => q(Litouwse talonas),
				'other' => q(Litouwse talonas),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(Luxemburgse convertibele franc),
				'one' => q(Luxemburgse convertibele franc),
				'other' => q(Luxemburgse convertibele franc),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(Luxemburgse frank),
				'one' => q(Luxemburgse frank),
				'other' => q(Luxemburgse frank),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(Luxemburgse financiële franc),
				'one' => q(Luxemburgse financiële franc),
				'other' => q(Luxemburgse financiële franc),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Letse lats),
				'one' => q(Letse lats),
				'other' => q(Letse lats),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(Letse roebel),
				'one' => q(Letse roebel),
				'other' => q(Letse roebel),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Libische dinar),
				'one' => q(Libische dinar),
				'other' => q(Libische dinar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokkaanse dirham),
				'one' => q(Marokkaanse dirham),
				'other' => q(Marokkaanse dirham),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(Marokkaanse franc),
				'one' => q(Marokkaanse franc),
				'other' => q(Marokkaanse franc),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(Monegaskische frank),
				'one' => q(Monegaskische frank),
				'other' => q(Monegaskische frank),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(Moldavische cupon),
				'one' => q(Moldavische cupon),
				'other' => q(Moldavische cupon),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldavische leu),
				'one' => q(Moldavische leu),
				'other' => q(Moldavische leu),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Malagassische ariary),
				'one' => q(Malagassische ariary),
				'other' => q(Malagassische ariary),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(Malagassische franc),
				'one' => q(Malagassische franc),
				'other' => q(Malagassische franc),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Macedonische denar),
				'one' => q(Macedonische denar),
				'other' => q(Macedonische denar),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(Macedonische denar \(1992–1993\)),
				'one' => q(Macedonische denar \(1992–1993\)),
				'other' => q(Macedonische denar \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(Malinese franc),
				'one' => q(Malinese franc),
				'other' => q(Malinese franc),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanmarese kyat),
				'one' => q(Myanmarese kyat),
				'other' => q(Myanmarese kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongoolse tugrik),
				'one' => q(Mongoolse tugrik),
				'other' => q(Mongoolse tugrik),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Macause pataca),
				'one' => q(Macause pataca),
				'other' => q(Macause pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mauritaanse ouguiya \(1973–2017\)),
				'one' => q(Mauritaanse ouguiya \(1973–2017\)),
				'other' => q(Mauritaanse ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Mauritaanse ouguiya),
				'one' => q(Mauritaanse ouguiya),
				'other' => q(Mauritaanse ouguiya),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(Maltese lire),
				'one' => q(Maltese lire),
				'other' => q(Maltese lire),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(Maltees pond),
				'one' => q(Maltees pond),
				'other' => q(Maltees pond),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mauritiaanse roepie),
				'one' => q(Mauritiaanse roepie),
				'other' => q(Mauritiaanse roepie),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(Maldivische roepie),
				'one' => q(Maldivische roepie),
				'other' => q(Maldivische roepie),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldivische rufiyaa),
				'one' => q(Maldivische rufiyaa),
				'other' => q(Maldivische rufiyaa),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malawische kwacha),
				'one' => q(Malawische kwacha),
				'other' => q(Malawische kwacha),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Mexicaanse peso),
				'one' => q(Mexicaanse peso),
				'other' => q(Mexicaanse peso),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(Mexicaanse zilveren peso \(1861–1992\)),
				'one' => q(Mexicaanse zilveren peso \(1861–1992\)),
				'other' => q(Mexicaanse zilveren peso \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(Mexicaanse unidad de inversion \(UDI\)),
				'one' => q(Mexicaanse unidad de inversion \(UDI\)),
				'other' => q(Mexicaanse unidad de inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Maleisische ringgit),
				'one' => q(Maleisische ringgit),
				'other' => q(Maleisische ringgit),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(Mozambikaanse escudo),
				'one' => q(Mozambikaanse escudo),
				'other' => q(Mozambikaanse escudo),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(Oude Mozambikaanse metical),
				'one' => q(Oude Mozambikaanse metical),
				'other' => q(Oude Mozambikaanse metical),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mozambikaanse metical),
				'one' => q(Mozambikaanse metical),
				'other' => q(Mozambikaanse metical),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibische dollar),
				'one' => q(Namibische dollar),
				'other' => q(Namibische dollar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigeriaanse naira),
				'one' => q(Nigeriaanse naira),
				'other' => q(Nigeriaanse naira),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(Nicaraguaanse córdoba \(1988–1991\)),
				'one' => q(Nicaraguaanse córdoba \(1988–1991\)),
				'other' => q(Nicaraguaanse córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nicaraguaanse córdoba),
				'one' => q(Nicaraguaanse córdoba),
				'other' => q(Nicaraguaanse córdoba),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(Nederlandse gulden),
				'one' => q(Nederlandse gulden),
				'other' => q(Nederlandse gulden),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Noorse kroon),
				'one' => q(Noorse kroon),
				'other' => q(Noorse kronen),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepalese roepie),
				'one' => q(Nepalese roepie),
				'other' => q(Nepalese roepie),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Nieuw-Zeelandse dollar),
				'one' => q(Nieuw-Zeelandse dollar),
				'other' => q(Nieuw-Zeelandse dollar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omaanse rial),
				'one' => q(Omaanse rial),
				'other' => q(Omaanse rial),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panamese balboa),
				'one' => q(Panamese balboa),
				'other' => q(Panamese balboa),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(Peruaanse inti),
				'one' => q(Peruaanse inti),
				'other' => q(Peruaanse inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peruaanse sol),
				'one' => q(Peruaanse sol),
				'other' => q(Peruaanse sol),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(Peruaanse sol \(1863–1965\)),
				'one' => q(Peruaanse sol \(1863–1965\)),
				'other' => q(Peruaanse sol \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papoea-Nieuw-Guinese kina),
				'one' => q(Papoea-Nieuw-Guinese kina),
				'other' => q(Papoea-Nieuw-Guinese kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipijnse peso),
				'one' => q(Filipijnse peso),
				'other' => q(Filipijnse peso),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistaanse roepie),
				'one' => q(Pakistaanse roepie),
				'other' => q(Pakistaanse roepie),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Poolse zloty),
				'one' => q(Poolse zloty),
				'other' => q(Poolse zloty),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(Poolse zloty \(1950–1995\)),
				'one' => q(Poolse zloty \(1950–1995\)),
				'other' => q(Poolse zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(Portugese escudo),
				'one' => q(Portugese escudo),
				'other' => q(Portugese escudo),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguayaanse guarani),
				'one' => q(Paraguayaanse guarani),
				'other' => q(Paraguayaanse guarani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Qatarese rial),
				'one' => q(Qatarese rial),
				'other' => q(Qatarese rial),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(Rhodesische dollar),
				'one' => q(Rhodesische dollar),
				'other' => q(Rhodesische dollar),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(Oude Roemeense leu),
				'one' => q(Oude Roemeense leu),
				'other' => q(Oude Roemeense leu),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Roemeense leu),
				'one' => q(Roemeense leu),
				'other' => q(Roemeense leu),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Servische dinar),
				'one' => q(Servische dinar),
				'other' => q(Servische dinar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Russische roebel),
				'one' => q(Russische roebel),
				'other' => q(Russische roebel),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(Russische roebel \(1991–1998\)),
				'one' => q(Russische roebel \(1991–1998\)),
				'other' => q(Russische roebel \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Rwandese frank),
				'one' => q(Rwandese frank),
				'other' => q(Rwandese frank),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saoedi-Arabische riyal),
				'one' => q(Saoedi-Arabische riyal),
				'other' => q(Saoedi-Arabische riyal),
			},
		},
		'SBD' => {
			symbol => 'SI$',
			display_name => {
				'currency' => q(Salomon-dollar),
				'one' => q(Salomon-dollar),
				'other' => q(Salomon-dollar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seychelse roepie),
				'one' => q(Seychelse roepie),
				'other' => q(Seychelse roepie),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(Soedanese dinar),
				'one' => q(Soedanese dinar),
				'other' => q(Soedanese dinar),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Soedanees pond),
				'one' => q(Soedanees pond),
				'other' => q(Soedanees pond),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(Soedanees pond \(1957–1998\)),
				'one' => q(Soedanees pond \(1957–1998\)),
				'other' => q(Soedanees pond \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Zweedse kroon),
				'one' => q(Zweedse kroon),
				'other' => q(Zweedse kronen),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singaporese dollar),
				'one' => q(Singaporese dollar),
				'other' => q(Singaporese dollar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Sint-Heleens pond),
				'one' => q(Sint-Heleens pond),
				'other' => q(Sint-Heleens pond),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(Sloveense tolar),
				'one' => q(Sloveense tolar),
				'other' => q(Sloveense tolar),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(Slowaakse koruna),
				'one' => q(Slowaakse koruna),
				'other' => q(Slowaakse koruna),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierraleoonse leone),
				'one' => q(Sierraleoonse leone),
				'other' => q(Sierraleoonse leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somalische shilling),
				'one' => q(Somalische shilling),
				'other' => q(Somalische shilling),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinaamse dollar),
				'one' => q(Surinaamse dollar),
				'other' => q(Surinaamse dollar),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(Surinaamse gulden),
				'one' => q(Surinaamse gulden),
				'other' => q(Surinaamse gulden),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Zuid-Soedanees pond),
				'one' => q(Zuid-Soedanees pond),
				'other' => q(Zuid-Soedanees pond),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Santomese dobra \(1977–2017\)),
				'one' => q(Santomese dobra \(1977–2017\)),
				'other' => q(Santomese dobra \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Santomese dobra),
				'one' => q(Santomese dobra),
				'other' => q(Santomese dobra),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(Sovjet-roebel),
				'one' => q(Sovjet-roebel),
				'other' => q(Sovjet-roebel),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(Salvadoraanse colón),
				'one' => q(Salvadoraanse colón),
				'other' => q(Salvadoraanse colón),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Syrisch pond),
				'one' => q(Syrisch pond),
				'other' => q(Syrisch pond),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Swazische lilangeni),
				'one' => q(Swazische lilangeni),
				'other' => q(Swazische lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thaise baht),
				'one' => q(Thaise baht),
				'other' => q(Thaise baht),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(Tadzjikistaanse roebel),
				'one' => q(Tadzjikistaanse roebel),
				'other' => q(Tadzjikistaanse roebel),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tadzjiekse somoni),
				'one' => q(Tadzjiekse somoni),
				'other' => q(Tadzjiekse somoni),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(Turkmeense manat \(1993–2009\)),
				'one' => q(Turkmeense manat \(1993–2009\)),
				'other' => q(Turkmeense manat \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Turkmeense manat),
				'one' => q(Turkmeense manat),
				'other' => q(Turkmeense manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunesische dinar),
				'one' => q(Tunesische dinar),
				'other' => q(Tunesische dinar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tongaanse paʻanga),
				'one' => q(Tongaanse paʻanga),
				'other' => q(Tongaanse paʻanga),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(Timorese escudo),
				'one' => q(Timorese escudo),
				'other' => q(Timorese escudo),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(Turkse lire),
				'one' => q(oude Turkse lira),
				'other' => q(oude Turkse lira),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turkse lira),
				'one' => q(Turkse lira),
				'other' => q(Turkse lira),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad en Tobago-dollar),
				'one' => q(Trinidad en Tobago-dollar),
				'other' => q(Trinidad en Tobago-dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nieuwe Taiwanese dollar),
				'one' => q(Nieuwe Taiwanese dollar),
				'other' => q(Nieuwe Taiwanese dollar),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzaniaanse shilling),
				'one' => q(Tanzaniaanse shilling),
				'other' => q(Tanzaniaanse shilling),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Oekraïense hryvnia),
				'one' => q(Oekraïense hryvnia),
				'other' => q(Oekraïense hryvnia),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(Oekraïense karbovanetz),
				'one' => q(Oekraïense karbovanetz),
				'other' => q(Oekraïense karbovanetz),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(Oegandese shilling \(1966–1987\)),
				'one' => q(Oegandese shilling \(1966–1987\)),
				'other' => q(Oegandese shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Oegandese shilling),
				'one' => q(Oegandese shilling),
				'other' => q(Oegandese shilling),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Amerikaanse dollar),
				'one' => q(Amerikaanse dollar),
				'other' => q(Amerikaanse dollar),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(Amerikaanse dollar \(volgende dag\)),
				'one' => q(Amerikaanse dollar \(volgende dag\)),
				'other' => q(Amerikaanse dollar \(volgende dag\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(Amerikaanse dollar \(zelfde dag\)),
				'one' => q(Amerikaanse dollar \(zelfde dag\)),
				'other' => q(Amerikaanse dollar \(zelfde dag\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(Uruguayaanse peso en geïndexeerde eenheden),
				'one' => q(Uruguayaanse peso en geïndexeerde eenheden),
				'other' => q(Uruguayaanse peso en geïndexeerde eenheden),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(Uruguayaanse peso \(1975–1993\)),
				'one' => q(Uruguayaanse peso \(1975–1993\)),
				'other' => q(Uruguayaanse peso \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguayaanse peso),
				'one' => q(Uruguayaanse peso),
				'other' => q(Uruguayaanse peso),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Oezbeekse sum),
				'one' => q(Oezbeekse sum),
				'other' => q(Oezbeekse sum),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(Venezolaanse bolivar \(1871–2008\)),
				'one' => q(Venezolaanse bolivar \(1871–2008\)),
				'other' => q(Venezolaanse bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venezolaanse bolivar \(2008–2018\)),
				'one' => q(Venezolaanse bolivar \(2008–2018\)),
				'other' => q(Venezolaanse bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Venezolaanse bolivar),
				'one' => q(Venezolaanse bolivar),
				'other' => q(Venezolaanse bolivar),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vietnamese dong),
				'one' => q(Vietnamese dong),
				'other' => q(Vietnamese dong),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(Vietnamese dong \(1978–1985\)),
				'one' => q(Vietnamese dong \(1978–1985\)),
				'other' => q(Vietnamese dong \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatuaanse vatu),
				'one' => q(Vanuatuaanse vatu),
				'other' => q(Vanuatuaanse vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoaanse tala),
				'one' => q(Samoaanse tala),
				'other' => q(Samoaanse tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA-frank),
				'one' => q(CFA-frank),
				'other' => q(CFA-frank),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(Zilver),
				'one' => q(Troy ounce zilver),
				'other' => q(Troy ounces zilver),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(Goud),
				'one' => q(Troy ounce goud),
				'other' => q(Troy ounces goud),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(Europese samengestelde eenheid),
				'one' => q(Europese samengestelde eenheid),
				'other' => q(Europese samengestelde eenheid),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(Europese monetaire eenheid),
				'one' => q(Europese monetaire eenheid),
				'other' => q(Europese monetaire eenheid),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(Europese rekeneenheid \(XBC\)),
				'one' => q(Europese rekeneenheid \(XBC\)),
				'other' => q(Europese rekeneenheid \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(Europese rekeneenheid \(XBD\)),
				'one' => q(Europese rekeneenheid \(XBD\)),
				'other' => q(Europese rekeneenheid \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Oost-Caribische dollar),
				'one' => q(Oost-Caribische dollar),
				'other' => q(Oost-Caribische dollar),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(Special Drawing Rights),
				'one' => q(Special Drawing Rights),
				'other' => q(Special Drawing Rights),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(European Currency Unit),
				'one' => q(European Currency Unit),
				'other' => q(European Currency Unit),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(Franse gouden franc),
				'one' => q(Franse gouden franc),
				'other' => q(Franse gouden franc),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(Franse UIC-franc),
				'one' => q(Franse UIC-franc),
				'other' => q(Franse UIC-franc),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA-franc BCEAO),
				'one' => q(CFA-franc BCEAO),
				'other' => q(CFA-franc BCEAO),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(Palladium),
				'one' => q(Troy ounce palladium),
				'other' => q(Troy ounces palladium),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(CFP-frank),
				'one' => q(CFP-frank),
				'other' => q(CFP-frank),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(Platina),
				'one' => q(Troy ounce platina),
				'other' => q(Troy ounces platina),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(RINET-fondsen),
				'one' => q(RINET-fondsen),
				'other' => q(RINET-fondsen),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(Sucre),
				'one' => q(Sucre),
				'other' => q(Sucre),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(Valutacode voor testdoeleinden),
				'one' => q(Valutacode voor testdoeleinden),
				'other' => q(Valutacode voor testdoeleinden),
			},
		},
		'XUA' => {
			symbol => 'XUA',
			display_name => {
				'currency' => q(ADB-rekeneenheid),
				'one' => q(ADB-rekeneenheid),
				'other' => q(ADB-rekeneenheid),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(onbekende munteenheid),
				'one' => q(onbekende munteenheid),
				'other' => q(onbekende munteenheid),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(Jemenitische dinar),
				'one' => q(Jemenitische dinar),
				'other' => q(Jemenitische dinar),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Jemenitische rial),
				'one' => q(Jemenitische rial),
				'other' => q(Jemenitische rial),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(Joegoslavische harde dinar),
				'one' => q(Joegoslavische harde dinar),
				'other' => q(Joegoslavische harde dinar),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(Joegoslavische noviy-dinar),
				'one' => q(Joegoslavische noviy-dinar),
				'other' => q(Joegoslavische noviy-dinar),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(Joegoslavische convertibele dinar),
				'one' => q(Joegoslavische convertibele dinar),
				'other' => q(Joegoslavische convertibele dinar),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(Joegoslavische hervormde dinar \(1992–1993\)),
				'one' => q(Joegoslavische hervormde dinar \(1992–1993\)),
				'other' => q(Joegoslavische hervormde dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(Zuid-Afrikaanse rand \(financieel\)),
				'one' => q(Zuid-Afrikaanse rand \(financieel\)),
				'other' => q(Zuid-Afrikaanse rand \(financieel\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Zuid-Afrikaanse rand),
				'one' => q(Zuid-Afrikaanse rand),
				'other' => q(Zuid-Afrikaanse rand),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Zambiaanse kwacha \(1968–2012\)),
				'one' => q(Zambiaanse kwacha \(1968–2012\)),
				'other' => q(Zambiaanse kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zambiaanse kwacha),
				'one' => q(Zambiaanse kwacha),
				'other' => q(Zambiaanse kwacha),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(Zaïrese nieuwe zaïre),
				'one' => q(Zaïrese nieuwe zaïre),
				'other' => q(Zaïrese nieuwe zaïre),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(Zaïrese zaïre),
				'one' => q(Zaïrese zaïre),
				'other' => q(Zaïrese zaïre),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(Zimbabwaanse dollar),
				'one' => q(Zimbabwaanse dollar),
				'other' => q(Zimbabwaanse dollar),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(Zimbabwaanse dollar \(2009\)),
				'one' => q(Zimbabwaanse dollar \(2009\)),
				'other' => q(Zimbabwaanse dollar \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(Zimbabwaanse dollar \(2008\)),
				'one' => q(Zimbabwaanse dollar \(2008\)),
				'other' => q(Zimbabwaanse dollar \(2008\)),
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
					abbreviated => {
						nonleap => [
							'mnd 1',
							'mnd 2',
							'mnd 3',
							'mnd 4',
							'mnd 5',
							'mnd 6',
							'mnd 7',
							'mnd 8',
							'mnd 9',
							'mnd 10',
							'mnd 11',
							'mnd 12'
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
							'maand 1',
							'maand 2',
							'maand 3',
							'maand 4',
							'maand 5',
							'maand 6',
							'maand 7',
							'maand 8',
							'maand 9',
							'maand 10',
							'maand 11',
							'maand 12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'mnd 1',
							'mnd 2',
							'mnd 3',
							'mnd 4',
							'mnd 5',
							'mnd 6',
							'mnd 7',
							'mnd 8',
							'mnd 9',
							'mnd 10',
							'mnd 11',
							'mnd 12'
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
							'maand 1',
							'maand 2',
							'maand 3',
							'maand 4',
							'maand 5',
							'maand 6',
							'maand 7',
							'maand 8',
							'maand 9',
							'maand 10',
							'maand 11',
							'maand 12'
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
							'Tut',
							'Babah',
							'Hatur',
							'Kiyahk',
							'Tubah',
							'Amshir',
							'Baramhat',
							'Baramundah',
							'Bashans',
							'Ba’unah',
							'Abib',
							'Misra',
							'Nasi'
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
							'Tut',
							'Babah',
							'Hatur',
							'Kiyahk',
							'Tubah',
							'Amshir',
							'Baramhat',
							'Baramundah',
							'Bashans',
							'Ba’unah',
							'Abib',
							'Misra',
							'Nasi'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tut',
							'Babah',
							'Hatur',
							'Kiyahk',
							'Tubah',
							'Amshir',
							'Baramhat',
							'Baramundah',
							'Bashans',
							'Ba’unah',
							'Abib',
							'Misra',
							'Nasi'
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
							'Tut',
							'Babah',
							'Hatur',
							'Kiyahk',
							'Tubah',
							'Amshir',
							'Baramhat',
							'Baramundah',
							'Bashans',
							'Ba’unah',
							'Abib',
							'Misra',
							'Nasi'
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
							'mnd 1',
							'mnd 2',
							'mnd 3',
							'mnd 4',
							'mnd 5',
							'mnd 6',
							'mnd 7',
							'mnd 8',
							'mnd 9',
							'mnd 10',
							'mnd 11',
							'mnd 12'
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
							'maand 1',
							'maand 2',
							'maand 3',
							'maand 4',
							'maand 5',
							'maand 6',
							'maand 7',
							'maand 8',
							'maand 9',
							'maand 10',
							'maand 11',
							'maand 12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'mnd 1',
							'mnd 2',
							'mnd 3',
							'mnd 4',
							'mnd 5',
							'mnd 6',
							'mnd 7',
							'mnd 8',
							'mnd 9',
							'mnd 10',
							'mnd 11',
							'mnd 12'
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
							'maand 1',
							'maand 2',
							'maand 3',
							'maand 4',
							'maand 5',
							'maand 6',
							'maand 7',
							'maand 8',
							'maand 9',
							'maand 10',
							'maand 11',
							'maand 12'
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
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahsas',
							'T’er',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Genbot',
							'Säne',
							'Hamle',
							'Nähase',
							'Pagumän'
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
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahsas',
							'T’er',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Genbot',
							'Säne',
							'Hamle',
							'Nähase',
							'Pagumän'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahsas',
							'T’er',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Genbot',
							'Säne',
							'Hamle',
							'Nähase',
							'Pagumän'
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
							'Mäskäräm',
							'Teqemt',
							'Hedar',
							'Tahsas',
							'T’er',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Genbot',
							'Säne',
							'Hamle',
							'Nähase',
							'Pagumän'
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
							'mrt.',
							'apr.',
							'mei',
							'jun.',
							'jul.',
							'aug.',
							'sep.',
							'okt.',
							'nov.',
							'dec.'
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
							'januari',
							'februari',
							'maart',
							'april',
							'mei',
							'juni',
							'juli',
							'augustus',
							'september',
							'oktober',
							'november',
							'december'
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
							'mrt.',
							'apr.',
							'mei',
							'jun.',
							'jul.',
							'aug.',
							'sep.',
							'okt.',
							'nov.',
							'dec.'
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
							'januari',
							'februari',
							'maart',
							'april',
							'mei',
							'juni',
							'juli',
							'augustus',
							'september',
							'oktober',
							'november',
							'december'
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
							'Tisjrie',
							'Chesjwan',
							'Kislev',
							'Tevet',
							'Sjevat',
							'Adar A',
							'Adar',
							'Nisan',
							'Ijar',
							'Sivan',
							'Tammoez',
							'Av',
							'Elloel'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar B'
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
							'Tisjrie',
							'Chesjwan',
							'Kislev',
							'Tevet',
							'Sjevat',
							'Adar A',
							'Adar',
							'Nisan',
							'Ijar',
							'Sivan',
							'Tammoez',
							'Av',
							'Elloel'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar B'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tisjrie',
							'Chesjwan',
							'Kislev',
							'Tevet',
							'Sjevat',
							'Adar A',
							'Adar',
							'Nisan',
							'Ijar',
							'Sivan',
							'Tammoez',
							'Av',
							'Elloel'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar B'
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
							'Tisjrie',
							'Chesjwan',
							'Kislev',
							'Tevet',
							'Sjevat',
							'Adar A',
							'Adar',
							'Nisan',
							'Ijar',
							'Sivan',
							'Tammoez',
							'Av',
							'Elloel'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar B'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaishakha',
							'Jyeshtha',
							'Aashaadha',
							'Shraavana',
							'Bhaadrapada',
							'Ashvina',
							'Kaartika',
							'Agrahayana',
							'Pausha',
							'Maagha',
							'Phaalguna'
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
							'Chaitra',
							'Vaishakha',
							'Jyeshtha',
							'Aashaadha',
							'Shraavana',
							'Bhaadrapada',
							'Ashvina',
							'Kaartika',
							'Agrahayana',
							'Pausha',
							'Maagha',
							'Phaalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaishakha',
							'Jyeshtha',
							'Aashaadha',
							'Shraavana',
							'Bhaadrapada',
							'Ashvina',
							'Kaartika',
							'Agrahayana',
							'Pausha',
							'Maagha',
							'Phaalguna'
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
							'Chaitra',
							'Vaishakha',
							'Jyeshtha',
							'Aashaadha',
							'Shraavana',
							'Bhaadrapada',
							'Ashvina',
							'Kaartika',
							'Agrahayana',
							'Pausha',
							'Maagha',
							'Phaalguna'
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
							'Moeh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Joem. I',
							'Joem. II',
							'Raj.',
							'Sja.',
							'Ram.',
							'Sjaw.',
							'Doe al k.',
							'Doe al h.'
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
							'Moeharram',
							'Safar',
							'Rabiʻa al awal',
							'Rabiʻa al thani',
							'Joemadʻal awal',
							'Joemadʻal thani',
							'Rajab',
							'Sjaʻaban',
							'Ramadan',
							'Sjawal',
							'Doe al kaʻaba',
							'Doe al hizja'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Moeh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Joem. I',
							'Joem. II',
							'Raj.',
							'Sja.',
							'Ram.',
							'Sjaw.',
							'Doe al k.',
							'Doe al h.'
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
							'Moeharram',
							'Safar',
							'Rabiʻa al awal',
							'Rabiʻa al thani',
							'Joemadʻal awal',
							'Joemadʻal thani',
							'Rajab',
							'Sjaʻaban',
							'Ramadan',
							'Sjawal',
							'Doe al kaʻaba',
							'Doe al hizja'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
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
						mon => 'ma',
						tue => 'di',
						wed => 'wo',
						thu => 'do',
						fri => 'vr',
						sat => 'za',
						sun => 'zo'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'W',
						thu => 'D',
						fri => 'V',
						sat => 'Z',
						sun => 'Z'
					},
					short => {
						mon => 'ma',
						tue => 'di',
						wed => 'wo',
						thu => 'do',
						fri => 'vr',
						sat => 'za',
						sun => 'zo'
					},
					wide => {
						mon => 'maandag',
						tue => 'dinsdag',
						wed => 'woensdag',
						thu => 'donderdag',
						fri => 'vrijdag',
						sat => 'zaterdag',
						sun => 'zondag'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'ma',
						tue => 'di',
						wed => 'wo',
						thu => 'do',
						fri => 'vr',
						sat => 'za',
						sun => 'zo'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'W',
						thu => 'D',
						fri => 'V',
						sat => 'Z',
						sun => 'Z'
					},
					short => {
						mon => 'ma',
						tue => 'di',
						wed => 'wo',
						thu => 'do',
						fri => 'vr',
						sat => 'za',
						sun => 'zo'
					},
					wide => {
						mon => 'maandag',
						tue => 'dinsdag',
						wed => 'woensdag',
						thu => 'donderdag',
						fri => 'vrijdag',
						sat => 'zaterdag',
						sun => 'zondag'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1e kwartaal',
						1 => '2e kwartaal',
						2 => '3e kwartaal',
						3 => '4e kwartaal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1e kwartaal',
						1 => '2e kwartaal',
						2 => '3e kwartaal',
						3 => '4e kwartaal'
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
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic-amete-alem') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
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
					'afternoon1' => q{’s middags},
					'night1' => q{’s nachts},
					'evening1' => q{’s avonds},
					'pm' => q{p.m.},
					'midnight' => q{middernacht},
					'morning1' => q{’s ochtends},
					'am' => q{a.m.},
				},
				'narrow' => {
					'midnight' => q{middernacht},
					'pm' => q{p.m.},
					'evening1' => q{’s avonds},
					'am' => q{a.m.},
					'morning1' => q{’s ochtends},
					'afternoon1' => q{’s middags},
					'night1' => q{’s nachts},
				},
				'wide' => {
					'afternoon1' => q{’s middags},
					'night1' => q{’s nachts},
					'evening1' => q{’s avonds},
					'midnight' => q{middernacht},
					'pm' => q{p.m.},
					'morning1' => q{’s ochtends},
					'am' => q{a.m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'pm' => q{p.m.},
					'midnight' => q{middernacht},
					'evening1' => q{avond},
					'am' => q{a.m.},
					'morning1' => q{ochtend},
					'afternoon1' => q{middag},
					'night1' => q{nacht},
				},
				'narrow' => {
					'midnight' => q{middernacht},
					'pm' => q{p.m.},
					'evening1' => q{avond},
					'am' => q{a.m.},
					'morning1' => q{ochtend},
					'afternoon1' => q{middag},
					'night1' => q{nacht},
				},
				'wide' => {
					'afternoon1' => q{middag},
					'night1' => q{nacht},
					'midnight' => q{middernacht},
					'pm' => q{p.m.},
					'evening1' => q{avond},
					'am' => q{a.m.},
					'morning1' => q{ochtend},
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
				'0' => 'era 0',
				'1' => 'era 1'
			},
			narrow => {
				'0' => 'era 0',
				'1' => 'era 1'
			},
			wide => {
				'0' => 'tijdperk 0',
				'1' => 'tijdperk 1'
			},
		},
		'ethiopic-amete-alem' => {
			abbreviated => {
				'0' => 'era 0'
			},
			narrow => {
				'0' => 'era 0'
			},
			wide => {
				'0' => 'tijdperk 0'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'v.Chr.',
				'1' => 'n.Chr.'
			},
			narrow => {
				'0' => 'v.C.',
				'1' => 'n.C.'
			},
			wide => {
				'0' => 'voor Christus',
				'1' => 'na Christus'
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
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'Saʻna Hizjria'
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
				'71' => 'Kaho (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Shōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen-ei (1118-1120)',
				'81' => 'Hoan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hoen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hogen (1156–1159)',
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
				'112' => 'Ken-ei (1206-1207)',
				'113' => 'Shōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Shōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tempuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En-ō (1239-1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun-ō (1260-1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun-ei (1264-1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkei (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkyō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Kareki (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kemmu (1334–1336)',
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
				'174' => 'Bun-an (1444-1449)',
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
				'190' => 'Tenmon (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624-1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenwa (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan-en (1748-1751)',
				'216' => 'Hōryaku (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An-ei (1772-1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man-en (1860-1861)',
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
				'13' => 'Tenpyō-hōji (757–765)',
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
				'78' => 'Ten-ei (1110–1113)',
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
				'146' => 'Enkei (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Kareki (1326–1329)',
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
				'214' => 'Enkei (1744–1748)',
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
				'71' => 'Kaho (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Shōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen-ei (1118-1120)',
				'81' => 'Hoan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hoen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hogen (1156–1159)',
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
				'112' => 'Ken-ei (1206-1207)',
				'113' => 'Shōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Shōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tempuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En-ō (1239-1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun-ō (1260-1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun-ei (1264-1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkei (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkyō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Kareki (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kemmu (1334–1336)',
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
				'174' => 'Bun-an (1444-1449)',
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
				'190' => 'Tenmon (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624-1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenwa (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan-en (1748-1751)',
				'216' => 'Hōryaku (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An-ei (1772-1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man-en (1860-1861)',
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
				'0' => 'voor R.O.C.',
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'voor R.O.C.',
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'voor R.O.C.',
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'chinese' => {
			'full' => q{EEEE d MMMM U},
			'long' => q{d MMMM U},
			'medium' => q{d MMM U},
			'short' => q{dd-MM-yy},
		},
		'coptic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'dangi' => {
			'full' => q{EEEE d MMMM r (U)},
			'long' => q{d MMMM r (U)},
			'medium' => q{d MMM r},
			'short' => q{dd-MM-r},
		},
		'ethiopic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd-MM-y},
		},
		'hebrew' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'indian' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'islamic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'japanese' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'persian' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
		},
		'roc' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd-MM-yy GGGGG},
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
		'ethiopic-amete-alem' => {
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
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'chinese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'coptic' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'dangi' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'ethiopic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'indian' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'islamic' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
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
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'roc' => {
			'full' => q{{1} 'om' {0}},
			'long' => q{{1} 'om' {0}},
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
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMW => q{'week' W 'van' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M-y},
			yMEd => q{E d-M-y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d-M-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'week' w 'in' Y},
		},
		'dangi' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{r (U)},
			GyMMM => q{MMM r (U)},
			GyMMMEd => q{E d MMM r (U)},
			GyMMMd => q{d MMM r},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			UM => q{MM U},
			UMMM => q{MMM U},
			UMMMd => q{d MMM U},
			UMd => q{d-MM U},
			d => q{d},
			y => q{r (U)},
			yMd => q{d-M-r},
			yyyy => q{r (U)},
			yyyyM => q{M-r},
			yyyyMEd => q{E d-M-r},
			yyyyMMM => q{MMM r (U)},
			yyyyMMMEd => q{E d MMM r (U)},
			yyyyMMMM => q{MMMM r (U)},
			yyyyMMMd => q{d MMM r},
			yyyyMd => q{d-M-r},
			yyyyQQQ => q{QQQ r (U)},
			yyyyQQQQ => q{QQQQ r (U)},
		},
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
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
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
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'hebrew' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d MMM},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d MMM},
			d => q{d},
			y => q{y},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'islamic' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'indian' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'coptic' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'chinese' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			Ed => q{E d},
			Gy => q{U},
			GyMMM => q{MMM U},
			GyMMMEd => q{E d MMM U},
			GyMMMd => q{d MMM U},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			UM => q{U MM},
			UMMM => q{U MMM},
			UMMMd => q{U MMM d},
			UMd => q{U MM-d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{U},
			yMd => q{y-MM-dd},
			yyyy => q{U},
			yyyyM => q{M-y},
			yyyyMEd => q{E d-M-y},
			yyyyMMM => q{MMM U},
			yyyyMMMEd => q{E d MMM U},
			yyyyMMMM => q{MMMM U},
			yyyyMMMd => q{d MMM U},
			yyyyMd => q{d-M-y},
			yyyyQQQ => q{QQQ U},
			yyyyQQQQ => q{QQQQ U},
		},
		'persian' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'roc' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'japanese' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'buddhist' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'ethiopic' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d-M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M-y GGGGG},
			yyyyMEd => q{E d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d-M-y GGGGG},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y},
				d => q{E dd-MM-y – E dd-MM-y},
				y => q{E dd-MM-y – E dd-MM-y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
		},
		'dangi' => {
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
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
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
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
				y => q{U–U},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{U MMM–MMM},
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				M => q{U MMMM–MMMM},
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				d => q{U MMM d–d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
			},
		},
		'chinese' => {
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
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
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
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
				y => q{U–U},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{U MMM–MMM},
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				M => q{U MMMM–MMMM},
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				d => q{U MMM d–d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
			},
		},
		'japanese' => {
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
			},
		},
	} },
);

has 'month_patterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
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
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(begin van de lente),
						1 => q(regenwater),
						2 => q(insecten ontwaken),
						3 => q(lentepunt),
						4 => q(licht en helder),
						5 => q(nat graan),
						6 => q(begin van de zomer),
						7 => q(vol graan),
						8 => q(oogst graan),
						9 => q(zomerpunt),
						10 => q(warm),
						11 => q(heet),
						12 => q(begin van de herfst),
						13 => q(einde van de hitte),
						14 => q(witte dauw),
						15 => q(herfstpunt),
						16 => q(koude dauw),
						17 => q(eerste vorst),
						18 => q(begin van de winter),
						19 => q(lichte sneeuw),
						20 => q(zware sneeuw),
						21 => q(winterpunt),
						22 => q(koel),
						23 => q(koud),
					},
					'narrow' => {
						0 => q(begin van de lente),
						1 => q(regenwater),
						2 => q(insecten ontwaken),
						3 => q(lentepunt),
						4 => q(licht en helder),
						5 => q(nat graan),
						6 => q(begin van de zomer),
						7 => q(vol graan),
						8 => q(oogst graan),
						9 => q(zomerpunt),
						10 => q(warm),
						11 => q(heet),
						12 => q(begin van de herfst),
						13 => q(einde van de hitte),
						14 => q(witte dauw),
						15 => q(herfstpunt),
						16 => q(koude dauw),
						17 => q(eerste vorst),
						18 => q(begin van de winter),
						19 => q(lichte sneeuw),
						20 => q(zware sneeuw),
						21 => q(winterpunt),
						22 => q(koel),
						23 => q(koud),
					},
					'wide' => {
						0 => q(begin van de lente),
						1 => q(regenwater),
						2 => q(insecten ontwaken),
						3 => q(lentepunt),
						4 => q(licht en helder),
						5 => q(nat graan),
						6 => q(begin van de zomer),
						7 => q(vol graan),
						8 => q(oogst graan),
						9 => q(zomerpunt),
						10 => q(warm),
						11 => q(heet),
						12 => q(begin van de herfst),
						13 => q(einde van de hitte),
						14 => q(witte dauw),
						15 => q(herfstpunt),
						16 => q(koude dauw),
						17 => q(eerste vorst),
						18 => q(begin van de winter),
						19 => q(lichte sneeuw),
						20 => q(zware sneeuw),
						21 => q(winterpunt),
						22 => q(koel),
						23 => q(koud),
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
						0 => q(Rat),
						1 => q(Os),
						2 => q(Tijger),
						3 => q(Konijn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Paard),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Haan),
						10 => q(Hond),
						11 => q(Varken),
					},
					'narrow' => {
						0 => q(Rat),
						1 => q(Os),
						2 => q(Tijger),
						3 => q(Konijn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Paard),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Haan),
						10 => q(Hond),
						11 => q(Varken),
					},
					'wide' => {
						0 => q(Rat),
						1 => q(Os),
						2 => q(Tijger),
						3 => q(Konijn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Paard),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Haan),
						10 => q(Hond),
						11 => q(Varken),
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
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(begin van de lente),
						1 => q(regenwater),
						2 => q(insecten ontwaken),
						3 => q(lentepunt),
						4 => q(licht en helder),
						5 => q(nat graan),
						6 => q(begin van de zomer),
						7 => q(vol graan),
						8 => q(oogst graan),
						9 => q(zomerpunt),
						10 => q(warm),
						11 => q(heet),
						12 => q(begin van de herfst),
						13 => q(einde van de hitte),
						14 => q(witte dauw),
						15 => q(herfstpunt),
						16 => q(koude dauw),
						17 => q(eerste vorst),
						18 => q(begin van de winter),
						19 => q(lichte sneeuw),
						20 => q(zware sneeuw),
						21 => q(winterpunt),
						22 => q(koel),
						23 => q(koud),
					},
					'narrow' => {
						0 => q(begin van de lente),
						1 => q(regenwater),
						2 => q(insecten ontwaken),
						3 => q(lentepunt),
						4 => q(licht en helder),
						5 => q(nat graan),
						6 => q(begin van de zomer),
						7 => q(vol graan),
						8 => q(oogst graan),
						9 => q(zomerpunt),
						10 => q(warm),
						11 => q(heet),
						12 => q(begin van de herfst),
						13 => q(einde van de hitte),
						14 => q(witte dauw),
						15 => q(herfstpunt),
						16 => q(koude dauw),
						17 => q(eerste vorst),
						18 => q(begin van de winter),
						19 => q(lichte sneeuw),
						20 => q(zware sneeuw),
						21 => q(winterpunt),
						22 => q(koel),
						23 => q(koud),
					},
					'wide' => {
						0 => q(begin van de lente),
						1 => q(regenwater),
						2 => q(insecten ontwaken),
						3 => q(lentepunt),
						4 => q(licht en helder),
						5 => q(nat graan),
						6 => q(begin van de zomer),
						7 => q(vol graan),
						8 => q(oogst graan),
						9 => q(zomerpunt),
						10 => q(warm),
						11 => q(heet),
						12 => q(begin van de herfst),
						13 => q(einde van de hitte),
						14 => q(witte dauw),
						15 => q(herfstpunt),
						16 => q(koude dauw),
						17 => q(eerste vorst),
						18 => q(begin van de winter),
						19 => q(lichte sneeuw),
						20 => q(zware sneeuw),
						21 => q(winterpunt),
						22 => q(koel),
						23 => q(koud),
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
						0 => q(Rat),
						1 => q(Os),
						2 => q(Tijger),
						3 => q(Konijn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Paard),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Haan),
						10 => q(Hond),
						11 => q(Varken),
					},
					'narrow' => {
						0 => q(Rat),
						1 => q(Os),
						2 => q(Tijger),
						3 => q(Konijn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Paard),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Haan),
						10 => q(Hond),
						11 => q(Varken),
					},
					'wide' => {
						0 => q(Rat),
						1 => q(Os),
						2 => q(Tijger),
						3 => q(Konijn),
						4 => q(Draak),
						5 => q(Slang),
						6 => q(Paard),
						7 => q(Geit),
						8 => q(Aap),
						9 => q(Haan),
						10 => q(Hond),
						11 => q(Varken),
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
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}-tijd),
		regionFormat => q(zomertijd {0}),
		regionFormat => q(standaardtijd {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre-zomertijd#,
				'generic' => q#Acre-tijd#,
				'standard' => q#Acre-standaardtijd#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghaanse tijd#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
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
			exemplarCity => q#Caïro#,
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
			exemplarCity => q#Khartoem#,
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
			exemplarCity => q#Sao Tomé#,
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
				'standard' => q#Centraal-Afrikaanse tijd#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oost-Afrikaanse tijd#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Zuid-Afrikaanse tijd#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#West-Afrikaanse zomertijd#,
				'generic' => q#West-Afrikaanse tijd#,
				'standard' => q#West-Afrikaanse standaardtijd#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-zomertijd#,
				'generic' => q#Alaska-tijd#,
				'standard' => q#Alaska-standaardtijd#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Alma-Ata-zomertijd#,
				'generic' => q#Alma-Ata-tijd#,
				'standard' => q#Alma-Ata-standaardtijd#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazone-zomertijd#,
				'generic' => q#Amazone-tijd#,
				'standard' => q#Amazone-standaardtijd#,
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
			exemplarCity => q#Río Gallegos#,
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
			exemplarCity => q#Tucumán#,
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
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderas#,
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
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
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
			exemplarCity => q#Beneden Prinsen Kwartier#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
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
			exemplarCity => q#Mazatlán#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico-Stad#,
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
			exemplarCity => q#Beulah, Noord-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Noord-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Noord-Dakota#,
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
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
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
				'daylight' => q#Central-zomertijd#,
				'generic' => q#Central-tijd#,
				'standard' => q#Central-standaardtijd#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern-zomertijd#,
				'generic' => q#Eastern-tijd#,
				'standard' => q#Eastern-standaardtijd#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain-zomertijd#,
				'generic' => q#Mountain-tijd#,
				'standard' => q#Mountain-standaardtijd#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific-zomertijd#,
				'generic' => q#Pacific-tijd#,
				'standard' => q#Pacific-standaardtijd#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr-zomertijd#,
				'generic' => q#Anadyr-tijd#,
				'standard' => q#Anadyr-standaardtijd#,
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
				'daylight' => q#Apia-zomertijd#,
				'generic' => q#Apia-tijd#,
				'standard' => q#Apia-standaardtijd#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtau-zomertijd#,
				'generic' => q#Aqtau-tijd#,
				'standard' => q#Aqtau-standaardtijd#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtöbe-zomertijd#,
				'generic' => q#Aqtöbe-tijd#,
				'standard' => q#Aqtöbe-standaardtijd#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabische zomertijd#,
				'generic' => q#Arabische tijd#,
				'standard' => q#Arabische standaardtijd#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentijnse zomertijd#,
				'generic' => q#Argentijnse tijd#,
				'standard' => q#Argentijnse standaardtijd#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#West-Argentijnse zomertijd#,
				'generic' => q#West-Argentijnse tijd#,
				'standard' => q#West-Argentijnse standaardtijd#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeense zomertijd#,
				'generic' => q#Armeense tijd#,
				'standard' => q#Armeense standaardtijd#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma-Ata#,
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
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjchabad#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atıraw#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakoe#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beiroet#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tsjojbalsan#,
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
			exemplarCity => q#Doesjanbe#,
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
			exemplarCity => q#Irkoetsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
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
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koeweit#,
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
			exemplarCity => q#Manilla#,
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
			exemplarCity => q#Phnom-Penh#,
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
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minhstad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Sjanghai#,
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
			exemplarCity => q#Tasjkent#,
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
			exemplarCity => q#Tokio#,
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
			exemplarCity => q#Jakoetsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinenburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic-zomertijd#,
				'generic' => q#Atlantic-tijd#,
				'standard' => q#Atlantic-standaardtijd#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoren#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canarische Eilanden#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kaapverdië#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faeröer#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Zuid-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sint-Helena#,
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
				'daylight' => q#Midden-Australische zomertijd#,
				'generic' => q#Midden-Australische tijd#,
				'standard' => q#Midden-Australische standaardtijd#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Midden-Australische westelijke zomertijd#,
				'generic' => q#Midden-Australische westelijke tijd#,
				'standard' => q#Midden-Australische westelijke standaardtijd#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Oost-Australische zomertijd#,
				'generic' => q#Oost-Australische tijd#,
				'standard' => q#Oost-Australische standaardtijd#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#West-Australische zomertijd#,
				'generic' => q#West-Australische tijd#,
				'standard' => q#West-Australische standaardtijd#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbeidzjaanse zomertijd#,
				'generic' => q#Azerbeidzjaanse tijd#,
				'standard' => q#Azerbeidzjaanse standaardtijd#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoren-zomertijd#,
				'generic' => q#Azoren-tijd#,
				'standard' => q#Azoren-standaardtijd#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bengalese zomertijd#,
				'generic' => q#Bengalese tijd#,
				'standard' => q#Bengalese standaardtijd#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutaanse tijd#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliviaanse tijd#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Braziliaanse zomertijd#,
				'generic' => q#Braziliaanse tijd#,
				'standard' => q#Braziliaanse standaardtijd#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruneise tijd#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kaapverdische zomertijd#,
				'generic' => q#Kaapverdische tijd#,
				'standard' => q#Kaapverdische standaardtijd#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Casey tijd#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-tijd#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham-zomertijd#,
				'generic' => q#Chatham-tijd#,
				'standard' => q#Chatham-standaardtijd#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chileense zomertijd#,
				'generic' => q#Chileense tijd#,
				'standard' => q#Chileense standaardtijd#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chinese zomertijd#,
				'generic' => q#Chinese tijd#,
				'standard' => q#Chinese standaardtijd#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Tsjojbalsan-zomertijd#,
				'generic' => q#Tsjojbalsan-tijd#,
				'standard' => q#Tsjojbalsan-standaardtijd#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmaseilandse tijd#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocoseilandse tijd#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombiaanse zomertijd#,
				'generic' => q#Colombiaanse tijd#,
				'standard' => q#Colombiaanse standaardtijd#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookeilandse halve zomertijd#,
				'generic' => q#Cookeilandse tijd#,
				'standard' => q#Cookeilandse standaardtijd#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cubaanse zomertijd#,
				'generic' => q#Cubaanse tijd#,
				'standard' => q#Cubaanse standaardtijd#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis-tijd#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville-tijd#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Oost-Timorese tijd#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Paaseilandse zomertijd#,
				'generic' => q#Paaseilandse tijd#,
				'standard' => q#Paaseilandse standaardtijd#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadoraanse tijd#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Gecoördineerde wereldtijd#,
			},
			short => {
				'standard' => q#UTC#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#onbekende stad#,
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
			exemplarCity => q#Athene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlijn#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Boekarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Boedapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Ierse standaardtijd#,
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
			exemplarCity => q#Istanboel#,
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
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londen#,
			long => {
				'daylight' => q#Britse zomertijd#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
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
			exemplarCity => q#Moskou#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parijs#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praag#,
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
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Oezjhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticaanstad#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wenen#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Midden-Europese zomertijd#,
				'generic' => q#Midden-Europese tijd#,
				'standard' => q#Midden-Europese standaardtijd#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oost-Europese zomertijd#,
				'generic' => q#Oost-Europese tijd#,
				'standard' => q#Oost-Europese standaardtijd#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Verder-oostelijk-Europese tijd#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#West-Europese zomertijd#,
				'generic' => q#West-Europese tijd#,
				'standard' => q#West-Europese standaardtijd#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandeilandse zomertijd#,
				'generic' => q#Falklandeilandse tijd#,
				'standard' => q#Falklandeilandse standaardtijd#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fijische zomertijd#,
				'generic' => q#Fijische tijd#,
				'standard' => q#Fijische standaardtijd#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Frans-Guyaanse tijd#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Franse zuidelijke en Antarctische tijd#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagoseilandse standaardtijd#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiereilandse tijd#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgische zomertijd#,
				'generic' => q#Georgische tijd#,
				'standard' => q#Georgische standaardtijd#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilberteilandse tijd#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Oost-Groenlandse zomertijd#,
				'generic' => q#Oost-Groenlandse tijd#,
				'standard' => q#Oost-Groenlandse standaardtijd#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#West-Groenlandse zomertijd#,
				'generic' => q#West-Groenlandse tijd#,
				'standard' => q#West-Groenlandse standaardtijd#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guamese standaardtijd#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golf-standaardtijd#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyaanse tijd#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleoetische zomertijd#,
				'generic' => q#Hawaii-Aleoetische tijd#,
				'standard' => q#Hawaii-Aleoetische standaardtijd#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongse zomertijd#,
				'generic' => q#Hongkongse tijd#,
				'standard' => q#Hongkongse standaardtijd#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd-zomertijd#,
				'generic' => q#Hovd-tijd#,
				'standard' => q#Hovd-standaardtijd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indiase tijd#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagosarchipel#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmaseiland#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocoseilanden#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiven#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indische Oceaan-tijd#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochinese tijd#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Centraal-Indonesische tijd#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oost-Indonesische tijd#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#West-Indonesische tijd#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iraanse zomertijd#,
				'generic' => q#Iraanse tijd#,
				'standard' => q#Iraanse standaardtijd#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkoetsk-zomertijd#,
				'generic' => q#Irkoetsk-tijd#,
				'standard' => q#Irkoetsk-standaardtijd#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israëlische zomertijd#,
				'generic' => q#Israëlische tijd#,
				'standard' => q#Israëlische standaardtijd#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japanse zomertijd#,
				'generic' => q#Japanse tijd#,
				'standard' => q#Japanse standaardtijd#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamtsjatski-zomertijd#,
				'generic' => q#Petropavlovsk-Kamtsjatski-tijd#,
				'standard' => q#Petropavlovsk-Kamtsjatski-standaardtijd#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Oost-Kazachse tijd#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#West-Kazachse tijd#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreaanse zomertijd#,
				'generic' => q#Koreaanse tijd#,
				'standard' => q#Koreaanse standaardtijd#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraese tijd#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk-zomertijd#,
				'generic' => q#Krasnojarsk-tijd#,
				'standard' => q#Krasnojarsk-standaardtijd#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgizische tijd#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lanka-tijd#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line-eilandse tijd#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe-eilandse zomertijd#,
				'generic' => q#Lord Howe-eilandse tijd#,
				'standard' => q#Lord Howe-eilandse standaardtijd#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macause zomertijd#,
				'generic' => q#Macause tijd#,
				'standard' => q#Macause standaardtijd#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie-eilandse tijd#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan-zomertijd#,
				'generic' => q#Magadan-tijd#,
				'standard' => q#Magadan-standaardtijd#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Maleisische tijd#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivische tijd#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesaseilandse tijd#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshalleilandse tijd#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritiaanse zomertijd#,
				'generic' => q#Mauritiaanse tijd#,
				'standard' => q#Mauritiaanse standaardtijd#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson-tijd#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Noordwest-Mexicaanse zomertijd#,
				'generic' => q#Noordwest-Mexicaanse tijd#,
				'standard' => q#Noordwest-Mexicaanse standaardtijd#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexicaanse Pacific-zomertijd#,
				'generic' => q#Mexicaanse Pacific-tijd#,
				'standard' => q#Mexicaanse Pacific-standaardtijd#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar-zomertijd#,
				'generic' => q#Ulaanbaatar-tijd#,
				'standard' => q#Ulaanbaatar-standaardtijd#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskou-zomertijd#,
				'generic' => q#Moskou-tijd#,
				'standard' => q#Moskou-standaardtijd#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarese tijd#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauruaanse tijd#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalese tijd#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nieuw-Caledonische zomertijd#,
				'generic' => q#Nieuw-Caledonische tijd#,
				'standard' => q#Nieuw-Caledonische standaardtijd#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nieuw-Zeelandse zomertijd#,
				'generic' => q#Nieuw-Zeelandse tijd#,
				'standard' => q#Nieuw-Zeelandse standaardtijd#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland-zomertijd#,
				'generic' => q#Newfoundland-tijd#,
				'standard' => q#Newfoundland-standaardtijd#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuese tijd#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolkeilandse tijd#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha-zomertijd#,
				'generic' => q#Fernando de Noronha-tijd#,
				'standard' => q#Fernando de Noronha-standaardtijd#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Noordelijk Mariaanse tijd#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk-zomertijd#,
				'generic' => q#Novosibirsk-tijd#,
				'standard' => q#Novosibirsk-standaardtijd#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk-zomertijd#,
				'generic' => q#Omsk-tijd#,
				'standard' => q#Omsk-standaardtijd#,
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
			exemplarCity => q#Paaseiland#,
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
			exemplarCity => q#Îles Gambier#,
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
			exemplarCity => q#Marquesaseilanden#,
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
				'daylight' => q#Pakistaanse zomertijd#,
				'generic' => q#Pakistaanse tijd#,
				'standard' => q#Pakistaanse standaardtijd#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Belause tijd#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papoea-Nieuw-Guineese tijd#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayaanse zomertijd#,
				'generic' => q#Paraguayaanse tijd#,
				'standard' => q#Paraguayaanse standaardtijd#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruaanse zomertijd#,
				'generic' => q#Peruaanse tijd#,
				'standard' => q#Peruaanse standaardtijd#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipijnse zomertijd#,
				'generic' => q#Filipijnse tijd#,
				'standard' => q#Filipijnse standaardtijd#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixeilandse tijd#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint Pierre en Miquelon-zomertijd#,
				'generic' => q#Saint Pierre en Miquelon-tijd#,
				'standard' => q#Saint Pierre en Miquelon-standaardtijd#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairneilandse tijd#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pohnpei-tijd#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang-tijd#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylorda-zomertijd#,
				'generic' => q#Qyzylorda-tijd#,
				'standard' => q#Qyzylorda-standaardtijd#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunionse tijd#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera-tijd#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalin-zomertijd#,
				'generic' => q#Sachalin-tijd#,
				'standard' => q#Sachalin-standaardtijd#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara-zomertijd#,
				'generic' => q#Samara-tijd#,
				'standard' => q#Samara-standaardtijd#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoaanse zomertijd#,
				'generic' => q#Samoaanse tijd#,
				'standard' => q#Samoaanse standaardtijd#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelse tijd#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singaporese standaardtijd#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonseilandse tijd#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Zuid-Georgische tijd#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinaamse tijd#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa-tijd#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitiaanse tijd#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei-zomertijd#,
				'generic' => q#Taipei-tijd#,
				'standard' => q#Taipei-standaardtijd#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadzjiekse tijd#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-eilandse tijd#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongaanse zomertijd#,
				'generic' => q#Tongaanse tijd#,
				'standard' => q#Tongaanse standaardtijd#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukse tijd#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmeense zomertijd#,
				'generic' => q#Turkmeense tijd#,
				'standard' => q#Turkmeense standaardtijd#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvaluaanse tijd#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayaanse zomertijd#,
				'generic' => q#Uruguayaanse tijd#,
				'standard' => q#Uruguayaanse standaardtijd#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oezbeekse zomertijd#,
				'generic' => q#Oezbeekse tijd#,
				'standard' => q#Oezbeekse standaardtijd#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatuaanse zomertijd#,
				'generic' => q#Vanuatuaanse tijd#,
				'standard' => q#Vanuatuaanse standaardtijd#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezolaanse tijd#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok-zomertijd#,
				'generic' => q#Vladivostok-tijd#,
				'standard' => q#Vladivostok-standaardtijd#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd-zomertijd#,
				'generic' => q#Wolgograd-tijd#,
				'standard' => q#Wolgograd-standaardtijd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok-tijd#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake-eilandse tijd#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis en Futunase tijd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakoetsk-zomertijd#,
				'generic' => q#Jakoetsk-tijd#,
				'standard' => q#Jakoetsk-standaardtijd#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinenburg-zomertijd#,
				'generic' => q#Jekaterinenburg-tijd#,
				'standard' => q#Jekaterinenburg-standaardtijd#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
