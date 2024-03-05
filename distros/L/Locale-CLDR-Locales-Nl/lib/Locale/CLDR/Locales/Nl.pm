=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Nl - Package for language Dutch

=cut

package Locale::CLDR::Locales::Nl;
# This file auto generated from Data\common\main\nl.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
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
					rule => q(=#,##0=e),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=e),
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
 				'ajp' => 'Zuid-Levantijns-Arabisch',
 				'ak' => 'Akan',
 				'akk' => 'Akkadisch',
 				'akz' => 'Alabama',
 				'ale' => 'Aleoetisch',
 				'aln' => 'Gegisch',
 				'alt' => 'Zuid-Altaïsch',
 				'am' => 'Amhaars',
 				'an' => 'Aragonees',
 				'ang' => 'Oudengels',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'apc' => 'Levantijns-Arabisch',
 				'ar' => 'Arabisch',
 				'ar_001' => 'modern standaard Arabisch',
 				'arc' => 'Aramees',
 				'arn' => 'Mapudungun',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho',
 				'arq' => 'Algerijns Arabisch',
 				'ars' => 'Nadjdi-Arabisch',
 				'ars@alt=menu' => 'Arabisch, Nadjdi',
 				'arw' => 'Arawak',
 				'ary' => 'Marokkaans Arabisch',
 				'arz' => 'Egyptisch Arabisch',
 				'as' => 'Assamees',
 				'asa' => 'Asu',
 				'ase' => 'Amerikaanse Gebarentaal',
 				'ast' => 'Asturisch',
 				'atj' => 'Atikamekw',
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
 				'be' => 'Belarussisch',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bew' => 'Bataviaans',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgaars',
 				'bgc' => 'Haryanvi',
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
 				'ccp' => 'Chakma',
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
 				'ckb@alt=menu' => 'Koerdisch, Soranî',
 				'ckb@alt=variant' => 'Koerdisch, Soranî',
 				'clc' => 'Chilcotin',
 				'co' => 'Corsicaans',
 				'cop' => 'Koptisch',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crg' => 'Michif',
 				'crh' => 'Krim-Tataars',
 				'crj' => 'Zuidoost-Cree',
 				'crk' => 'Plains Cree',
 				'crl' => 'Noordoost-Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonkisch',
 				'crs' => 'Seychellencreools',
 				'cs' => 'Tsjechisch',
 				'csb' => 'Kasjoebisch',
 				'csw' => 'Swampy Cree',
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
 				'enm' => 'Middelengels',
 				'eo' => 'Esperanto',
 				'es' => 'Spaans',
 				'esu' => 'Yupik',
 				'et' => 'Estisch',
 				'eu' => 'Baskisch',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremeens',
 				'fa' => 'Perzisch',
 				'fa_AF' => 'Dari',
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
 				'hax' => 'Zuid-Haida',
 				'he' => 'Hebreeuws',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
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
 				'hur' => 'Halkomelem',
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
 				'ikt' => 'Westelijk Canadees Inuktitut',
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
 				'kwk' => 'Kwakʼwala',
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
 				'lil' => 'Lillooet',
 				'liv' => 'Lijfs',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombardisch',
 				'ln' => 'Lingala',
 				'lo' => 'Laotiaans',
 				'lol' => 'Mongo',
 				'lou' => 'Louisiana-Creools',
 				'loz' => 'Lozi',
 				'lrc' => 'Noordelijk Luri',
 				'lsm' => 'Saamia',
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
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'mrj' => 'West-Mari',
 				'ms' => 'Maleis',
 				'mt' => 'Maltees',
 				'mua' => 'Mundang',
 				'mul' => 'meerdere talen',
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
 				'nl_BE' => 'Vlaams',
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
 				'ojb' => 'Noordwest-Ojibwe',
 				'ojc' => 'Centraal Ojibwa',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'West-Ojibwe',
 				'oka' => 'Okanagan',
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
 				'pis' => 'Pijin',
 				'pl' => 'Pools',
 				'pms' => 'Piëmontees',
 				'pnt' => 'Pontisch',
 				'pon' => 'Pohnpeiaans',
 				'pqm' => 'Maliseet-Passamaquoddy',
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
 				'rhg' => 'Rohingya',
 				'rif' => 'Riffijns',
 				'rm' => 'Reto-Romaans',
 				'rn' => 'Kirundi',
 				'ro' => 'Roemeens',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
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
 				'slh' => 'Zuid-Lushootseed',
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
 				'str' => 'Straits Salish',
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
 				'tce' => 'Zuid-Tutchone',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetun',
 				'tg' => 'Tadzjieks',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
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
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turks',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonisch',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tataars',
 				'ttm' => 'Noord-Tutchone',
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
 				'zh@alt=menu' => 'Mandarijn',
 				'zh_Hans@alt=long' => 'Mandarijn (vereenvoudigd)',
 				'zh_Hant@alt=long' => 'Mandarijn (traditioneel)',
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
 			'Aran' => 'Nastaliq',
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
 			'Brai' => 'braille',
 			'Bugi' => 'Buginees',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Verenigde Canadese Aboriginal-symbolen',
 			'Cari' => 'Carisch',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Chrs' => 'Chorasmisch',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptisch',
 			'Cpmn' => 'Cypro-Minoïsch',
 			'Cprt' => 'Cyprisch',
 			'Cyrl' => 'Cyrillisch',
 			'Cyrs' => 'Oudkerkslavisch Cyrillisch',
 			'Deva' => 'Devanagari',
 			'Diak' => 'Dives Akuru',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployan snelschrift',
 			'Egyd' => 'Egyptisch demotisch',
 			'Egyh' => 'Egyptisch hiëratisch',
 			'Egyp' => 'Egyptische hiërogliefen',
 			'Elba' => 'Elbasan',
 			'Elym' => 'Elymaisch',
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
 			'Hanb' => 'Han met Bopomofo',
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
 			'Hmnp' => 'Nyiakeng Puachue Hmong',
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
 			'Kawi' => 'Kawi-taal',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Kits' => 'Kitaans kleinschrift',
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
 			'Nagm' => 'Nag Mundari',
 			'Nand' => 'Nandinagari',
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
 			'Ougr' => 'Oud Oeigoers',
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
 			'Qaag' => 'Zawgyi',
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
 			'Tnsa' => 'Tangsa',
 			'Toto' => 'Totoschrift',
 			'Ugar' => 'Ugaritisch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Zichtbare spraak',
 			'Vith' => 'Vithkuqi',
 			'Wara' => 'Varang Kshiti',
 			'Wcho' => 'Wancho',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Oudperzisch',
 			'Xsux' => 'Sumero-Akkadian Cuneiform',
 			'Yezi' => 'Jezidi',
 			'Yiii' => 'Yi',
 			'Zanb' => 'vierkant Zanabazar',
 			'Zinh' => 'Overgeërfd',
 			'Zmth' => 'wiskundige notatie',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symbolen',
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
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Cookeilanden',
 			'CL' => 'Chili',
 			'CM' => 'Kameroen',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Clipperton',
 			'CQ' => 'Sark',
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
 			'IO@alt=chagos' => 'Chagoseilanden',
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
 			'MK' => 'Noord-Macedonië',
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
 			'NZ@alt=variant' => 'Aotearoa Nieuw-Zeeland',
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
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
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
 			'TR@alt=variant' => 'Türkiye',
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
 			'XA' => 'Pseudo-Accenten',
 			'XB' => 'Pseudo-Bidi',
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
 			'ARANES' => 'Aranees',
 			'AREVELA' => 'Oost-Armeens',
 			'AREVMDA' => 'West-Armeens',
 			'ARKAIKA' => 'Archaïsch Esperanto',
 			'ASANTE' => 'Asante',
 			'AUVERN' => 'Auvern',
 			'BAKU1926' => 'Eenvormig Turkse Latijnse alfabet',
 			'BALANKA' => 'Balanka-dialect van Anii',
 			'BARLA' => 'Barlavento-dialectgroep van Kabuverdianu',
 			'BASICENG' => 'Standaard Engels',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Biskajaans',
 			'BISKE' => 'San Giorgio/Bila-dialect',
 			'BOHORIC' => 'Bohorič-alfabet',
 			'BOONT' => 'Boontling',
 			'BORNHOLM' => 'Bornholms',
 			'CISAUP' => 'Cisaup',
 			'COLB1945' => 'Portugese-Braziliaanse spellingsverdrag van 1945',
 			'CORNU' => 'Cornu',
 			'CREISS' => 'Creiss',
 			'DAJNKO' => 'Dajnko-alfabet',
 			'EKAVSK' => 'Servisch met Ekaviaanse uitspraak',
 			'EMODENG' => 'Vroegmodern Engels',
 			'FONIPA' => 'Internationaal Fonetisch Alfabet',
 			'FONKIRSH' => 'Fonkirsh',
 			'FONNAPA' => 'Fonnapa',
 			'FONUPA' => 'Oeralisch Fonetisch Alfabet',
 			'FONXSAMP' => 'Transcriptie volgens X-SAMPA',
 			'GALLO' => 'Gallo',
 			'GASCON' => 'Gascon',
 			'GRCLASS' => 'Grclass',
 			'GRITAL' => 'Grital',
 			'GRMISTR' => 'Grmistr',
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
 			'LEMOSIN' => 'Lemosin',
 			'LENGADOC' => 'Lengadoc',
 			'LIPAW' => 'Het Lipovaz-dialect van het Resiaans',
 			'LUNA1918' => 'Russische spelling van 1917',
 			'METELKO' => 'Metelko-alfabet',
 			'MONOTON' => 'Monotonaal',
 			'NDYUKA' => 'Ndyuka-dialect',
 			'NEDIS' => 'Natisone-dialect',
 			'NEWFOUND' => 'Newfound',
 			'NICARD' => 'Nicard',
 			'NJIVA' => 'Gniva/Njiva-dialect',
 			'NULIK' => 'Modern Volapük',
 			'OSOJS' => 'Oseacco/Osojane-dialect',
 			'OXENDICT' => 'Spelling volgens het Oxford English Dictionary',
 			'PAHAWH2' => 'Pahawh2',
 			'PAHAWH3' => 'Pahawh3',
 			'PAHAWH4' => 'Pahawh4',
 			'PAMAKA' => 'Pamaka',
 			'PEANO' => 'Latijn zonder flexie',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'Pinyin',
 			'POLYTON' => 'Polytonaal',
 			'POSIX' => 'Computer',
 			'PROVENC' => 'Provenc',
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
 			'SYNNEJYL' => 'Zuid-Jutlands',
 			'TARASK' => 'Taraskievica-spelling',
 			'TONGYONG' => 'Tongyong',
 			'TUNUMIIT' => 'Tunumiisiut',
 			'UCCOR' => 'Eenvormige spelling',
 			'UCRCOR' => 'Eenvormig herziene spelling',
 			'ULSTER' => 'Ulster',
 			'UNIFON' => 'Unifon fonetisch alfabet',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valenciaans',
 			'VALLADER' => 'Vallader',
 			'VECDRUKA' => 'Vecā druka',
 			'VIVARAUP' => 'Vivaraup',
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
 				'pinyin' => q{Pinyinsorteervolgorde},
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
 				'diak' => q{Dives Akuru cijfers},
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
 				'hmnp' => q{Nyiakeng Puachue Hmong cijfers},
 				'java' => q{Javaanse cijfers},
 				'jpan' => q{Japanse cijfers},
 				'jpanfin' => q{Japanse financiële cijfers},
 				'kali' => q{Kayah Li cijfers},
 				'kawi' => q{kawi cijfers},
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
 				'nagm' => q{Nag Mundari cijfers},
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
 				'tnsa' => q{Tangsa cijfers},
 				'traditional' => q{Traditionele cijfers},
 				'vaii' => q{Vai cijfers},
 				'wara' => q{Warang Citi cijfers},
 				'wcho' => q{Wancho cijfers},
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
			auxiliary => qr{[àâåã æ ç èê î ñ ôø œ ùû ýÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aáä b c d eéë f g h iíï {ij}{íj́} j k l m n oóö p q r s t uúü v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(hoofdwindstreek),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(hoofdwindstreek),
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
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
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
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
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
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
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
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
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
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
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
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
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
						'1' => q(common),
						'name' => q(G-krachten),
						'one' => q({0} G-kracht),
						'other' => q({0} G-krachten),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(common),
						'name' => q(G-krachten),
						'one' => q({0} G-kracht),
						'other' => q({0} G-krachten),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(common),
						'name' => q(meter per seconde kwadraat),
						'one' => q({0} meter per seconde kwadraat),
						'other' => q({0} meter per seconde kwadraat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(common),
						'name' => q(meter per seconde kwadraat),
						'one' => q({0} meter per seconde kwadraat),
						'other' => q({0} meter per seconde kwadraat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(common),
						'name' => q(boogminuten),
						'one' => q({0} boogminuut),
						'other' => q({0} boogminuten),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(common),
						'name' => q(boogminuten),
						'one' => q({0} boogminuut),
						'other' => q({0} boogminuten),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(common),
						'name' => q(boogseconden),
						'one' => q({0} boogseconde),
						'other' => q({0} boogseconden),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(common),
						'name' => q(boogseconden),
						'one' => q({0} boogseconde),
						'other' => q({0} boogseconden),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(common),
						'name' => q(booggraden),
						'one' => q({0} booggraad),
						'other' => q({0} booggraden),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(common),
						'name' => q(booggraden),
						'one' => q({0} booggraad),
						'other' => q({0} booggraden),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(common),
						'name' => q(radiaal),
						'one' => q({0} radiaal),
						'other' => q({0} radialen),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(common),
						'name' => q(radiaal),
						'one' => q({0} radiaal),
						'other' => q({0} radialen),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(common),
						'name' => q(toeren),
						'one' => q({0} toer),
						'other' => q({0} toeren),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(common),
						'name' => q(toeren),
						'one' => q({0} toer),
						'other' => q({0} toeren),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(common),
						'name' => q(hectare),
						'one' => q({0} hectare),
						'other' => q({0} hectare),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(common),
						'name' => q(hectare),
						'one' => q({0} hectare),
						'other' => q({0} hectare),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(common),
						'name' => q(vierkante centimeter),
						'one' => q({0} vierkante centimeter),
						'other' => q({0} vierkante centimeter),
						'per' => q({0} per vierkante centimeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(common),
						'name' => q(vierkante centimeter),
						'one' => q({0} vierkante centimeter),
						'other' => q({0} vierkante centimeter),
						'per' => q({0} per vierkante centimeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(common),
						'name' => q(vierkante voet),
						'one' => q({0} vierkante voet),
						'other' => q({0} vierkante voet),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(common),
						'name' => q(vierkante voet),
						'one' => q({0} vierkante voet),
						'other' => q({0} vierkante voet),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(vierkante inch),
						'one' => q({0} vierkante inch),
						'other' => q({0} vierkante inch),
						'per' => q({0} per vierkante inch),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(vierkante inch),
						'one' => q({0} vierkante inch),
						'other' => q({0} vierkante inch),
						'per' => q({0} per vierkante inch),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(common),
						'name' => q(vierkante kilometer),
						'one' => q({0} vierkante kilometer),
						'other' => q({0} vierkante kilometer),
						'per' => q({0} per vierkante kilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(common),
						'name' => q(vierkante kilometer),
						'one' => q({0} vierkante kilometer),
						'other' => q({0} vierkante kilometer),
						'per' => q({0} per vierkante kilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(common),
						'name' => q(vierkante meter),
						'one' => q({0} vierkante meter),
						'other' => q({0} vierkante meter),
						'per' => q({0} per vierkante meter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(common),
						'name' => q(vierkante meter),
						'one' => q({0} vierkante meter),
						'other' => q({0} vierkante meter),
						'per' => q({0} per vierkante meter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(common),
						'name' => q(vierkante mijl),
						'one' => q({0} vierkante mijl),
						'other' => q({0} vierkante mijl),
						'per' => q({0} per vierkante mijl),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(common),
						'name' => q(vierkante mijl),
						'one' => q({0} vierkante mijl),
						'other' => q({0} vierkante mijl),
						'per' => q({0} per vierkante mijl),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(vierkante yard),
						'one' => q({0} vierkante yard),
						'other' => q({0} vierkante yard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(vierkante yard),
						'one' => q({0} vierkante yard),
						'other' => q({0} vierkante yard),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(neuter),
						'name' => q(onderdelen),
						'one' => q({0} onderdeel),
						'other' => q({0} onderdelen),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(neuter),
						'name' => q(onderdelen),
						'one' => q({0} onderdeel),
						'other' => q({0} onderdelen),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(neuter),
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(neuter),
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligram per deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligram per deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(common),
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(common),
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(neuter),
						'one' => q({0} procent),
						'other' => q({0} procent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(neuter),
						'one' => q({0} procent),
						'other' => q({0} procent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(neuter),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(neuter),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(neuter),
						'name' => q(basispunt),
						'one' => q({0} basispunt),
						'other' => q({0} basispunten),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(neuter),
						'name' => q(basispunt),
						'one' => q({0} basispunt),
						'other' => q({0} basispunten),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(common),
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(common),
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(common),
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(common),
						'name' => q(mijl per gallon),
						'one' => q({0} mijl per gallon),
						'other' => q({0} mijl per gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(common),
						'name' => q(mijl per gallon),
						'one' => q({0} mijl per gallon),
						'other' => q({0} mijl per gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(common),
						'name' => q(mijl per imp. gallon),
						'one' => q({0} mijl per imp. gallon),
						'other' => q({0} mijl per imp. gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(common),
						'name' => q(mijl per imp. gallon),
						'one' => q({0} mijl per imp. gallon),
						'other' => q({0} mijl per imp. gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} oosterlengte),
						'north' => q({0} noorderbreedte),
						'south' => q({0} zuiderbreedte),
						'west' => q({0} westerlengte),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} oosterlengte),
						'north' => q({0} noorderbreedte),
						'south' => q({0} zuiderbreedte),
						'west' => q({0} westerlengte),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(common),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(common),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(common),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(common),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(common),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(common),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(common),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(common),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(common),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(common),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(common),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(common),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(common),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(common),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(common),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(common),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(common),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(common),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(common),
						'per' => q({0} per dag),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(common),
						'per' => q({0} per dag),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'name' => q(decennia),
						'one' => q({0} decennium),
						'other' => q({0} decennia),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'name' => q(decennia),
						'one' => q({0} decennium),
						'other' => q({0} decennia),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(neuter),
						'per' => q({0} per uur),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(neuter),
						'per' => q({0} per uur),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(common),
						'name' => q(microseconden),
						'one' => q({0} microseconde),
						'other' => q({0} microseconden),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(common),
						'name' => q(microseconden),
						'one' => q({0} microseconde),
						'other' => q({0} microseconden),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(common),
						'name' => q(milliseconden),
						'one' => q({0} milliseconde),
						'other' => q({0} milliseconden),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(common),
						'name' => q(milliseconden),
						'one' => q({0} milliseconde),
						'other' => q({0} milliseconden),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(common),
						'name' => q(minuten),
						'one' => q({0} minuut),
						'other' => q({0} minuten),
						'per' => q({0} per minuut),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(common),
						'name' => q(minuten),
						'one' => q({0} minuut),
						'other' => q({0} minuten),
						'per' => q({0} per minuut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(common),
						'name' => q(maanden),
						'one' => q({0} maand),
						'other' => q({0} maanden),
						'per' => q({0} per maand),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(common),
						'name' => q(maanden),
						'one' => q({0} maand),
						'other' => q({0} maanden),
						'per' => q({0} per maand),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(common),
						'name' => q(nanoseconden),
						'one' => q({0} nanoseconde),
						'other' => q({0} nanoseconden),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(common),
						'name' => q(nanoseconden),
						'one' => q({0} nanoseconde),
						'other' => q({0} nanoseconden),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'name' => q(kwartaal),
						'one' => q({0} kwartaal),
						'other' => q({0} kwartalen),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'name' => q(kwartaal),
						'one' => q({0} kwartaal),
						'other' => q({0} kwartalen),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(common),
						'name' => q(seconden),
						'one' => q({0} seconde),
						'other' => q({0} seconden),
						'per' => q({0} per seconde),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(common),
						'name' => q(seconden),
						'one' => q({0} seconde),
						'other' => q({0} seconden),
						'per' => q({0} per seconde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(common),
						'name' => q(weken),
						'one' => q({0} week),
						'other' => q({0} weken),
						'per' => q({0} per week),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(common),
						'name' => q(weken),
						'one' => q({0} week),
						'other' => q({0} weken),
						'per' => q({0} per week),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(neuter),
						'name' => q(jaar),
						'one' => q({0} jaar),
						'other' => q({0} jaar),
						'per' => q({0} per jaar),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(neuter),
						'name' => q(jaar),
						'one' => q({0} jaar),
						'other' => q({0} jaar),
						'per' => q({0} per jaar),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(common),
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(common),
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(common),
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(common),
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(common),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(common),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(common),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(common),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal unit),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal unit),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal unit),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal unit),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(common),
						'name' => q(calorie),
						'one' => q({0} calorie),
						'other' => q({0} calorieën),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(common),
						'name' => q(calorie),
						'one' => q({0} calorie),
						'other' => q({0} calorieën),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(common),
						'name' => q(kilocalorieën),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalorieën),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(common),
						'name' => q(kilocalorieën),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalorieën),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(common),
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(common),
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(common),
						'name' => q(kilocalorie),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalorieën),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(common),
						'name' => q(kilocalorie),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalorieën),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(common),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(common),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(neuter),
						'name' => q(kilowattuur),
						'one' => q({0} kilowattuur),
						'other' => q({0} kilowattuur),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(neuter),
						'name' => q(kilowattuur),
						'one' => q({0} kilowattuur),
						'other' => q({0} kilowattuur),
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
						'1' => q(neuter),
						'name' => q(ki­lo­wattuur per 100 kilometer),
						'one' => q({0} ki­lo­wattuur per 100 kilometer),
						'other' => q({0} ki­lo­wattuur per 100 kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(neuter),
						'name' => q(ki­lo­wattuur per 100 kilometer),
						'one' => q({0} ki­lo­wattuur per 100 kilometer),
						'other' => q({0} ki­lo­wattuur per 100 kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(common),
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(common),
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound of force),
						'one' => q({0} pound of force),
						'other' => q({0} pound of force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound of force),
						'one' => q({0} pound of force),
						'other' => q({0} pound of force),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(common),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(common),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(common),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(common),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(common),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(common),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(common),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(common),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dots per centimeter),
						'one' => q({0} dot per centimeter),
						'other' => q({0} dots per centimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dots per centimeter),
						'one' => q({0} dot per centimeter),
						'other' => q({0} dots per centimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dots per inch),
						'one' => q({0} dot per inch),
						'other' => q({0} dots per inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dots per inch),
						'one' => q({0} dot per inch),
						'other' => q({0} dots per inch),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(common),
						'name' => q(typografische em),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(common),
						'name' => q(typografische em),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(common),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(common),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(common),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(common),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(common),
						'name' => q(pixels per centimeter),
						'one' => q({0} pixel per centimeter),
						'other' => q({0} pixels per centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(common),
						'name' => q(pixels per centimeter),
						'one' => q({0} pixel per centimeter),
						'other' => q({0} pixels per centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels per inch),
						'one' => q({0} pixel per inch),
						'other' => q({0} pixels per inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels per inch),
						'one' => q({0} pixel per inch),
						'other' => q({0} pixels per inch),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomische eenheid),
						'one' => q({0} astronomische eenheid),
						'other' => q({0} astronomische eenheden),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomische eenheid),
						'one' => q({0} astronomische eenheid),
						'other' => q({0} astronomische eenheden),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(common),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(common),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(common),
						'name' => q(decimeter),
						'one' => q({0} decimeter),
						'other' => q({0} decimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(common),
						'name' => q(decimeter),
						'one' => q({0} decimeter),
						'other' => q({0} decimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(aardstraal),
						'one' => q({0} aardstraal),
						'other' => q({0} aardstralen),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(aardstraal),
						'one' => q({0} aardstraal),
						'other' => q({0} aardstralen),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(vadem),
						'one' => q({0} vadem),
						'other' => q({0} vadems),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(vadem),
						'one' => q({0} vadem),
						'other' => q({0} vadems),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(common),
						'name' => q(voet),
						'one' => q({0} voet),
						'other' => q({0} voet),
						'per' => q({0} per voet),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(common),
						'name' => q(voet),
						'one' => q({0} voet),
						'other' => q({0} voet),
						'per' => q({0} per voet),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(common),
						'one' => q({0} inch),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(common),
						'one' => q({0} inch),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(common),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(common),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lichtjaar),
						'one' => q({0} lichtjaar),
						'other' => q({0} lichtjaar),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lichtjaar),
						'one' => q({0} lichtjaar),
						'other' => q({0} lichtjaar),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(common),
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(common),
						'name' => q(meter),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(common),
						'name' => q(micrometer),
						'one' => q({0} micrometer),
						'other' => q({0} micrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(common),
						'name' => q(micrometer),
						'one' => q({0} micrometer),
						'other' => q({0} micrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(common),
						'name' => q(mijl),
						'one' => q({0} mijl),
						'other' => q({0} mijl),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(common),
						'name' => q(mijl),
						'one' => q({0} mijl),
						'other' => q({0} mijl),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(common),
						'name' => q(Scandinavische mijl),
						'one' => q({0} Scandinavische mijl),
						'other' => q({0} Scandinavische mijl),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(common),
						'name' => q(Scandinavische mijl),
						'one' => q({0} Scandinavische mijl),
						'other' => q({0} Scandinavische mijl),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(common),
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(common),
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(common),
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(common),
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(zeemijl),
						'one' => q({0} zeemijl),
						'other' => q({0} zeemijlen),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(zeemijl),
						'one' => q({0} zeemijl),
						'other' => q({0} zeemijlen),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(common),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(common),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(common),
						'name' => q(picometer),
						'one' => q({0} picometer),
						'other' => q({0} picometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(common),
						'name' => q(picometer),
						'one' => q({0} picometer),
						'other' => q({0} picometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} punt),
						'other' => q({0} punten),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} punt),
						'other' => q({0} punten),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(common),
						'name' => q(zonneradius),
						'one' => q({0} solar radius),
						'other' => q({0} solar radii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(common),
						'name' => q(zonneradius),
						'one' => q({0} solar radius),
						'other' => q({0} solar radii),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(common),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(common),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(common),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(common),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(neuter),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(neuter),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(common),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(common),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(common),
						'name' => q(solar luminosity),
						'one' => q({0} solar luminosity),
						'other' => q({0} solar luminosity),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(common),
						'name' => q(solar luminosity),
						'one' => q({0} solar luminosity),
						'other' => q({0} solar luminosity),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(neuter),
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(neuter),
						'name' => q(karaat),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(common),
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(common),
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(common),
						'name' => q(aardmassa),
						'one' => q({0} aardmassa),
						'other' => q({0} aardmassa),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(common),
						'name' => q(aardmassa),
						'one' => q({0} aardmassa),
						'other' => q({0} aardmassa),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(neuter),
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(neuter),
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(neuter),
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(neuter),
						'name' => q(microgram),
						'one' => q({0} microgram),
						'other' => q({0} microgram),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(neuter),
						'name' => q(microgram),
						'one' => q({0} microgram),
						'other' => q({0} microgram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(neuter),
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(neuter),
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(common),
						'name' => q(ounce),
						'one' => q({0} ounce),
						'other' => q({0} ounce),
						'per' => q({0} per ounce),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(common),
						'name' => q(ounce),
						'one' => q({0} ounce),
						'other' => q({0} ounce),
						'per' => q({0} per ounce),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ounce),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounce),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ounce),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounce),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(common),
						'name' => q(pound),
						'one' => q({0} pound),
						'other' => q({0} pound),
						'per' => q({0} per pound),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(common),
						'name' => q(pound),
						'one' => q({0} pound),
						'other' => q({0} pound),
						'per' => q({0} per pound),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(common),
						'name' => q(zonnemassa),
						'one' => q({0} zonnemassa),
						'other' => q({0} zonnemassa),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(common),
						'name' => q(zonnemassa),
						'one' => q({0} zonnemassa),
						'other' => q({0} zonnemassa),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(common),
						'name' => q(metrische ton),
						'one' => q({0} metrische ton),
						'other' => q({0} metrische ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(common),
						'name' => q(metrische ton),
						'one' => q({0} metrische ton),
						'other' => q({0} metrische ton),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(common),
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(common),
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(paardenkrachten),
						'one' => q({0} paardenkracht),
						'other' => q({0} paardenkrachten),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(paardenkrachten),
						'one' => q({0} paardenkracht),
						'other' => q({0} paardenkrachten),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(common),
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(common),
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(common),
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(common),
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(common),
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(common),
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(common),
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(common),
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(vierkante {0}),
						'one' => q(vierkante {0}),
						'other' => q(vierkante {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(vierkante {0}),
						'one' => q(vierkante {0}),
						'other' => q(vierkante {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kubieke {0}),
						'one' => q(kubieke {0}),
						'other' => q(kubieke {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kubieke {0}),
						'one' => q(kubieke {0}),
						'other' => q(kubieke {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(common),
						'name' => q(atmosfeer),
						'one' => q({0} atmosfeer),
						'other' => q({0} atmosfeer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(common),
						'name' => q(atmosfeer),
						'one' => q({0} atmosfeer),
						'other' => q({0} atmosfeer),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(common),
						'name' => q(hectopascal),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(common),
						'name' => q(hectopascal),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inch-kwikdruk),
						'one' => q({0} inch-kwikdruk),
						'other' => q({0} inch-kwikdruk),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inch-kwikdruk),
						'one' => q({0} inch-kwikdruk),
						'other' => q({0} inch-kwikdruk),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(common),
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(common),
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(common),
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(common),
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(common),
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(common),
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimeter-kwikdruk),
						'one' => q({0} millimeter-kwikdruk),
						'other' => q({0} millimeter-kwikdruk),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimeter-kwikdruk),
						'one' => q({0} millimeter-kwikdruk),
						'other' => q({0} millimeter-kwikdruk),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(common),
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(common),
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(common),
						'name' => q(kilometer per uur),
						'one' => q({0} kilometer per uur),
						'other' => q({0} kilometer per uur),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(common),
						'name' => q(kilometer per uur),
						'one' => q({0} kilometer per uur),
						'other' => q({0} kilometer per uur),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knoop),
						'one' => q({0} knoop),
						'other' => q({0} knopen),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knoop),
						'one' => q({0} knoop),
						'other' => q({0} knopen),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(common),
						'name' => q(meter per seconde),
						'one' => q({0} meter per seconde),
						'other' => q({0} meter per seconde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(common),
						'name' => q(meter per seconde),
						'one' => q({0} meter per seconde),
						'other' => q({0} meter per seconde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(common),
						'name' => q(mijl per uur),
						'one' => q({0} mijl per uur),
						'other' => q({0} mijl per uur),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(common),
						'name' => q(mijl per uur),
						'one' => q({0} mijl per uur),
						'other' => q({0} mijl per uur),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(common),
						'name' => q(graden Celsius),
						'one' => q({0} graad Celsius),
						'other' => q({0} graden Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(common),
						'name' => q(graden Celsius),
						'one' => q({0} graad Celsius),
						'other' => q({0} graden Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(common),
						'name' => q(graden Fahrenheit),
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} graden Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(common),
						'name' => q(graden Fahrenheit),
						'one' => q({0} graad Fahrenheit),
						'other' => q({0} graden Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(common),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(common),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(common),
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(common),
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-force-feet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-force-feet),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrels),
						'one' => q({0} barrel),
						'other' => q({0} barrels),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrels),
						'one' => q({0} barrel),
						'other' => q({0} barrels),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(common),
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(common),
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(common),
						'name' => q(kubieke centimeter),
						'one' => q({0} kubieke centimeter),
						'other' => q({0} kubieke centimeter),
						'per' => q({0} per kubieke centimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(common),
						'name' => q(kubieke centimeter),
						'one' => q({0} kubieke centimeter),
						'other' => q({0} kubieke centimeter),
						'per' => q({0} per kubieke centimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(common),
						'name' => q(kubieke voet),
						'one' => q({0} kubieke voet),
						'other' => q({0} kubieke voet),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(common),
						'name' => q(kubieke voet),
						'one' => q({0} kubieke voet),
						'other' => q({0} kubieke voet),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubieke inch),
						'one' => q({0} kubieke inch),
						'other' => q({0} kubieke inch),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubieke inch),
						'one' => q({0} kubieke inch),
						'other' => q({0} kubieke inch),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(common),
						'name' => q(kubieke kilometer),
						'one' => q({0} kubieke kilometer),
						'other' => q({0} kubieke kilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(common),
						'name' => q(kubieke kilometer),
						'one' => q({0} kubieke kilometer),
						'other' => q({0} kubieke kilometer),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(common),
						'name' => q(kubieke meter),
						'one' => q({0} kubieke meter),
						'other' => q({0} kubieke meter),
						'per' => q({0} per kubieke meter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(common),
						'name' => q(kubieke meter),
						'one' => q({0} kubieke meter),
						'other' => q({0} kubieke meter),
						'per' => q({0} per kubieke meter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(common),
						'name' => q(kubieke mijl),
						'one' => q({0} kubieke mijl),
						'other' => q({0} kubieke mijl),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(common),
						'name' => q(kubieke mijl),
						'one' => q({0} kubieke mijl),
						'other' => q({0} kubieke mijl),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubieke yard),
						'one' => q({0} kubieke yard),
						'other' => q({0} kubieke yard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubieke yard),
						'one' => q({0} kubieke yard),
						'other' => q({0} kubieke yard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(common),
						'one' => q({0} metrische cup),
						'other' => q({0} metrische cup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(common),
						'one' => q({0} metrische cup),
						'other' => q({0} metrische cup),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(common),
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(common),
						'name' => q(deciliter),
						'one' => q({0} deciliter),
						'other' => q({0} deciliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(common),
						'name' => q(dessertlepel),
						'one' => q({0} dessertlepel),
						'other' => q({0} dessertlepels),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(common),
						'name' => q(dessertlepel),
						'one' => q({0} dessertlepel),
						'other' => q({0} dessertlepels),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(common),
						'name' => q(imp. dessertlepel),
						'one' => q({0} imp. dessertlepel),
						'other' => q({0} imp. dessertlepels),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(common),
						'name' => q(imp. dessertlepel),
						'one' => q({0} imp. dessertlepel),
						'other' => q({0} imp. dessertlepels),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(neuter),
						'one' => q({0} drachme),
						'other' => q({0} drachme),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(neuter),
						'one' => q({0} drachme),
						'other' => q({0} drachme),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(common),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(common),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(common),
						'name' => q(fluid ounce),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(common),
						'name' => q(fluid ounce),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(common),
						'name' => q(Imp. fluid ounce),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(common),
						'name' => q(Imp. fluid ounce),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounce),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(common),
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(common),
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(common),
						'name' => q(imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0} per imp. gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(common),
						'name' => q(imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0} per imp. gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(common),
						'name' => q(hectoliter),
						'one' => q({0} hectoliter),
						'other' => q({0} hectoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(common),
						'name' => q(hectoliter),
						'one' => q({0} hectoliter),
						'other' => q({0} hectoliter),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'1' => q(common),
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(common),
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(common),
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(common),
						'name' => q(liter),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(common),
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(common),
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(common),
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(common),
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(neuter),
						'one' => q({0} snufje),
						'other' => q({0} snufjes),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(neuter),
						'one' => q({0} snufje),
						'other' => q({0} snufjes),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(common),
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(common),
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(common),
						'name' => q(metrische pint),
						'one' => q({0} metrische pint),
						'other' => q({0} metrische pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(common),
						'name' => q(metrische pint),
						'one' => q({0} metrische pint),
						'other' => q({0} metrische pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(common),
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(common),
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(common),
						'name' => q(imp. quart),
						'one' => q({0} imp. quart),
						'other' => q({0} imp. quarts),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(common),
						'name' => q(imp. quart),
						'one' => q({0} imp. quart),
						'other' => q({0} imp. quarts),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(common),
						'name' => q(eetlepel),
						'one' => q({0} eetlepel),
						'other' => q({0} eetlepels),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(common),
						'name' => q(eetlepel),
						'one' => q({0} eetlepel),
						'other' => q({0} eetlepels),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(common),
						'name' => q(theelepel),
						'one' => q({0} theelepel),
						'other' => q({0} theelepels),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(common),
						'name' => q(theelepel),
						'one' => q({0} theelepel),
						'other' => q({0} theelepels),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(u),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(u),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kw.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kw.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(w),
						'one' => q({0} w),
						'other' => q({0} w),
						'per' => q({0}/w),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(w),
						'one' => q({0} w),
						'other' => q({0} w),
						'per' => q({0}/w),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dot),
						'one' => q({0} dot),
						'other' => q({0} dot),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dot),
						'one' => q({0} dot),
						'other' => q({0} dot),
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
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(imp. d l),
						'one' => q({0} imp. d l),
						'other' => q({0} imp. d l),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(imp. d l),
						'one' => q({0} imp. d l),
						'other' => q({0} imp. d l),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} drs),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} drs),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} fl ozIm),
						'other' => q({0} fl ozIm),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} fl ozIm),
						'other' => q({0} fl ozIm),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(sn),
						'one' => q({0} sn),
						'other' => q({0} sn),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(sn),
						'one' => q({0} sn),
						'other' => q({0} sn),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(windstreek),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(windstreek),
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
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
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
					'area-square-centimeter' => {
						'per' => q({0} per cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0} per cm²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'per' => q({0} per in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'per' => q({0} per in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'per' => q({0} per km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'per' => q({0} per km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0} per m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0} per m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q({0} per mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q({0} per mi²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(onderdeel),
						'one' => q({0} onderdeel),
						'other' => q({0} ond.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(onderdeel),
						'one' => q({0} onderdeel),
						'other' => q({0} ond.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
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
						'name' => q(millimol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(procent),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(procent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promille),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mijl/imp. gal),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mijl/imp. gal),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} OL),
						'north' => q({0} NB),
						'south' => q({0} ZB),
						'west' => q({0} WL),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} OL),
						'north' => q({0} NB),
						'south' => q({0} ZB),
						'west' => q({0} WL),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(eeuwen),
						'one' => q({0} eeuw),
						'other' => q({0} eeuwen),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(eeuwen),
						'one' => q({0} eeuw),
						'other' => q({0} eeuwen),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dagen),
						'one' => q({0} dag),
						'other' => q({0} dagen),
						'per' => q({0}/dag),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dagen),
						'one' => q({0} dag),
						'other' => q({0} dagen),
						'per' => q({0}/dag),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(uur),
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0}/uur),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(uur),
						'one' => q({0} uur),
						'other' => q({0} uur),
						'per' => q({0}/uur),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mnd),
						'one' => q({0} mnd),
						'other' => q({0} mnd),
						'per' => q({0}/mnd),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mnd),
						'one' => q({0} mnd),
						'other' => q({0} mnd),
						'per' => q({0}/mnd),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kwart.),
						'one' => q({0} kwart.),
						'other' => q({0} kwart.),
						'per' => q({0}/kw.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kwart.),
						'one' => q({0} kwart.),
						'other' => q({0} kwart.),
						'per' => q({0}/kw.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} sec),
						'other' => q({0} sec),
						'per' => q({0}/sec),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} sec),
						'other' => q({0} sec),
						'per' => q({0}/sec),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} wk),
						'other' => q({0} wkn),
						'per' => q({0}/wk),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} wk),
						'other' => q({0} wkn),
						'per' => q({0}/wk),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(jr),
						'one' => q({0} jr),
						'other' => q({0} jr),
						'per' => q({0}/jr),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(jr),
						'one' => q({0} jr),
						'other' => q({0} jr),
						'per' => q({0}/jr),
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
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0} US therm),
						'other' => q({0} US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0} US therm),
						'other' => q({0} US therms),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dots),
						'one' => q({0} dot),
						'other' => q({0} dots),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dots),
						'one' => q({0} dot),
						'other' => q({0} dots),
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
						'name' => q(megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inches),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inches),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lj),
						'one' => q({0} lj),
						'other' => q({0} lj),
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
					'length-point' => {
						'name' => q(punten),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punten),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yards),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yards),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grein),
						'one' => q({0} grein),
						'other' => q({0} grein),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grein),
						'one' => q({0} grein),
						'other' => q({0} grein),
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
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
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
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(windkracht),
						'one' => q({0}),
						'other' => q({0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(windkracht),
						'one' => q({0}),
						'other' => q({0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/u),
						'one' => q({0} km/u),
						'other' => q({0} km/u),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/u),
						'one' => q({0} km/u),
						'other' => q({0} km/u),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
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
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre ft),
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
					'volume-cup' => {
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrische cup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrische cup),
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
						'name' => q(des l),
						'one' => q({0} des l),
						'other' => q({0} des l),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(des l),
						'one' => q({0} des l),
						'other' => q({0} des l),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(imp. des l),
						'one' => q({0} imp. des l),
						'other' => q({0} imp. des lpls),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(imp. des l),
						'one' => q({0} imp. des l),
						'other' => q({0} imp. des lpls),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drachme),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drachme),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(druppel),
						'one' => q({0} druppel),
						'other' => q({0} druppels),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(druppel),
						'one' => q({0} druppel),
						'other' => q({0} druppels),
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
						'name' => q(imp. gal),
						'one' => q({0} imp. gal),
						'other' => q({0} imp. gal),
						'per' => q({0}/imp. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(imp. gal),
						'one' => q({0} imp. gal),
						'other' => q({0} imp. gal),
						'per' => q({0}/imp. gal),
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
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(snufje),
						'one' => q({0} snufje),
						'other' => q({0} snufje),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(snufje),
						'one' => q({0} snufje),
						'other' => q({0} snufje),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(imp. qt),
						'one' => q({0} imp. qt),
						'other' => q({0} imp. qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(imp. qt),
						'one' => q({0} imp. qt),
						'other' => q({0} imp. qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(el),
						'one' => q({0} el),
						'other' => q({0} el),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(el),
						'one' => q({0} el),
						'other' => q({0} el),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tl),
						'one' => q({0} tl),
						'other' => q({0} tl),
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
				end => q({0} en {1}),
				2 => q({0} en {1}),
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
			display_name => {
				'currency' => q(Andorrese peseta),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Verenigde Arabische Emiraten-dirham),
				'one' => q(VAE-dirham),
				'other' => q(VAE-dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghani \(1927–2002\)),
				'one' => q(Afghani \(AFA\)),
				'other' => q(Afghani \(AFA\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghaanse afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albanese lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanese lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armeense dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Nederlands-Antilliaanse gulden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolese kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolese kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolese nieuwe kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolese kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentijnse austral),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Argentijnse peso ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentijnse peso \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentijnse peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentijnse peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Oostenrijkse schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australische dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Arubaanse gulden),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbeidzjaanse manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbeidzjaanse manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnische dinar),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnische convertibele mark),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Nieuwe Bosnische dinar \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadaanse dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bengalese taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgische frank \(convertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgische frank),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgische frank \(financieel\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgaarse harde lev),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Bulgaarse socialistische lev),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaarse lev),
				'one' => q(Bulgaarse lev),
				'other' => q(Bulgaarse leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bulgaarse lev \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreinse dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundese frank),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Bruneise dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviaanse boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliviaanse boliviano \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Boliviaanse peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Boliviaanse mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Braziliaanse cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Braziliaanse cruzado),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Braziliaanse cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Braziliaanse real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Braziliaanse nieuwe cruzado \(1989–1990\)),
				'one' => q(Braziliaanse cruzado novo),
				'other' => q(Braziliaanse cruzado novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Braziliaanse cruzeiro),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Braziliaanse cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamaanse dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutaanse ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Birmese kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswaanse pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Wit-Russische nieuwe roebel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Belarussische roebel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Wit-Russische roebel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belizaanse dollar),
			},
		},
		'CAD' => {
			symbol => 'C$',
			display_name => {
				'currency' => q(Canadese dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese frank),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Zwitserse frank),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franc),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Chileense escudo),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chileense unidades de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chileense peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Chinese yuan \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(dollar van de Chinese Volksbank),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Colombiaanse peso),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Ricaanse colon),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Oude Servische dinar),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tsjechoslowaakse harde koruna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Cubaanse convertibele peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Cubaanse peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kaapverdische escudo),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Cyprisch pond),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tsjechische kroon),
				'one' => q(Tsjechische kroon),
				'other' => q(Tsjechische kronen),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Oost-Duitse ostmark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Duitse mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutiaanse frank),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Deense kroon),
				'one' => q(Deense kroon),
				'other' => q(Deense kronen),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominicaanse peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerijnse dinar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadoraanse sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ecuadoraanse unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estlandse kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptisch pond),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrese nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Spaanse peseta \(account A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Spaanse peseta \(convertibele account\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spaanse peseta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopische birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finse markka),
			},
		},
		'FJD' => {
			symbol => 'FJ$',
			display_name => {
				'currency' => q(Fiji-dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falklandeilands pond),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franse franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britse pond),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgische kupon larit),
			},
		},
		'GEL' => {
			symbol => 'ლ',
			display_name => {
				'currency' => q(Georgische lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanese cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanese cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltarees pond),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiaanse dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinese frank),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinese syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Equatoriaal-Guinese ekwele guineana),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Griekse drachme),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalteekse quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugees-Guinese escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinee-Bissause peso),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyaanse dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkongse dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hondurese lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroatische dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatische kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haïtiaanse gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hongaarse forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesische roepia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Iers pond),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israëlisch pond),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Israëlische sjekel \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israëlische nieuwe shekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indiase roepie),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraakse dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iraanse rial),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(IJslandse kroon \(1918–1981\)),
				'one' => q(IJslandse kroon \(1918–1981\)),
				'other' => q(IJslandse kronen \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(IJslandse kroon),
				'one' => q(IJslandse kroon),
				'other' => q(IJslandse kronen),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italiaanse lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaicaanse dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaanse dinar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanse yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniaanse shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgizische som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Cambodjaanse riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comorese frank),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Noord-Koreaanse won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Zuid-Koreaanse hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Oude Zuid-Koreaanse won \(1945–1953\)),
				'one' => q(oude Zuid-Koreaanse won \(1945–1953\)),
				'other' => q(oude Zuid-Koreaanse won \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Zuid-Koreaanse won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Koeweitse dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaaimaneilandse dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazachse tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotiaanse kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libanees pond),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankaanse roepie),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiaanse dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesothaanse loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litouwse litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litouwse talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxemburgse convertibele franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxemburgse frank),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxemburgse financiële franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Letse lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Letse roebel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libische dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokkaanse dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkaanse franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monegaskische frank),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldavische cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldavische leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagassische ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Malagassische franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedonische denar),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Macedonische denar \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malinese franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmarese kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoolse tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macause pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritaanse ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritaanse ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltese lire),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltees pond),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritiaanse roepie),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Maldivische roepie),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivische rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawische kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexicaanse peso),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexicaanse zilveren peso \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexicaanse unidad de inversion \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Maleisische ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambikaanse escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Oude Mozambikaanse metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambikaanse metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibische dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriaanse naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguaanse córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguaanse córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Nederlandse gulden),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Noorse kroon),
				'one' => q(Noorse kroon),
				'other' => q(Noorse kronen),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese roepie),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Nieuw-Zeelandse dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omaanse rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamese balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruaanse inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruaanse sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruaanse sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papoea-Nieuw-Guinese kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipijnse peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistaanse roepie),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poolse zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Poolse zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugese escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayaanse guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatarese rial),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodesische dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Oude Roemeense leu),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Roemeense leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Servische dinar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russische roebel),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Russische roebel \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandese frank),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saoedi-Arabische riyal),
			},
		},
		'SBD' => {
			symbol => 'SI$',
			display_name => {
				'currency' => q(Salomon-dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychelse roepie),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Soedanese dinar),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Soedanees pond),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Soedanees pond \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Zweedse kroon),
				'one' => q(Zweedse kroon),
				'other' => q(Zweedse kronen),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singaporese dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Sint-Heleens pond),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Sloveense tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slowaakse koruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leoonse leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leoonse leone \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalische shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinaamse dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinaamse gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Zuid-Soedanees pond),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Santomese dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Santomese dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovjet-roebel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadoraanse colón),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrisch pond),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazische lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thaise baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadzjikistaanse roebel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadzjiekse somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmeense manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmeense manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunesische dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongaanse paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timorese escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkse lire),
				'one' => q(oude Turkse lira),
				'other' => q(oude Turkse lira),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkse lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad en Tobago-dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Nieuwe Taiwanese dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniaanse shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Oekraïense hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Oekraïense karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Oegandese shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Oegandese shilling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Amerikaanse dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Amerikaanse dollar \(volgende dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Amerikaanse dollar \(zelfde dag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayaanse peso en geïndexeerde eenheden),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayaanse peso \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayaanse peso),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(Uruguayaanse nominale salarisindexeenheid),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Oezbeekse sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezolaanse bolivar \(1871–2008\)),
			},
		},
		'VED' => {
			display_name => {
				'currency' => q(Bolívar Soberano),
				'one' => q(Bolívar Soberano),
				'other' => q(Bolívar Soberanos),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezolaanse bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezolaanse bolivar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnamese dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vietnamese dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatuaanse vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoaanse tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-frank),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Zilver),
				'one' => q(Troy ounce zilver),
				'other' => q(Troy ounces zilver),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Goud),
				'one' => q(Troy ounce goud),
				'other' => q(Troy ounces goud),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Europese samengestelde eenheid),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Europese monetaire eenheid),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Europese rekeneenheid \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Europese rekeneenheid \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Oost-Caribische dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Special Drawing Rights),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(European Currency Unit),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franse gouden franc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franse UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-franc BCEAO),
			},
		},
		'XPD' => {
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
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platina),
				'one' => q(Troy ounce platina),
				'other' => q(Troy ounces platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-fondsen),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(Sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Valutacode voor testdoeleinden),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(ADB-rekeneenheid),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(onbekende munteenheid),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemenitische dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemenitische rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Joegoslavische harde dinar),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Joegoslavische noviy-dinar),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Joegoslavische convertibele dinar),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Joegoslavische hervormde dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Zuid-Afrikaanse rand \(financieel\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Zuid-Afrikaanse rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiaanse kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambiaanse kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaïrese nieuwe zaïre),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaïrese zaïre),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwaanse dollar),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwaanse dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwaanse dollar \(2008\)),
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
			'ethiopic' => {
				'format' => {
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
							'jan',
							'feb',
							'mrt',
							'apr',
							'mei',
							'jun',
							'jul',
							'aug',
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
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'W',
						thu => 'D',
						fri => 'V',
						sat => 'Z',
						sun => 'Z'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
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
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
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
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
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
			if ($_ eq 'ethiopic-amete-alem') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
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
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
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
					'afternoon1' => q{’s middags},
					'am' => q{a.m.},
					'evening1' => q{’s avonds},
					'midnight' => q{middernacht},
					'morning1' => q{’s ochtends},
					'night1' => q{’s nachts},
					'pm' => q{p.m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{middag},
					'evening1' => q{avond},
					'morning1' => q{ochtend},
					'night1' => q{nacht},
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
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
			abbreviated => {
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
		},
		'indian' => {
		},
		'islamic' => {
			wide => {
				'0' => 'Saʻna Hizjria'
			},
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
				'71' => 'Kaho (1094–1096)',
				'73' => 'Shōtoku (1097–1099)',
				'78' => 'Ten-ei (1110-1113)',
				'80' => 'Gen-ei (1118-1120)',
				'81' => 'Hoan (1120–1124)',
				'86' => 'Hoen (1135–1141)',
				'93' => 'Hogen (1156–1159)',
				'112' => 'Ken-ei (1206-1207)',
				'113' => 'Shōgen (1207–1211)',
				'116' => 'Shōkyū (1219–1222)',
				'123' => 'Tempuku (1233–1234)',
				'127' => 'En-ō (1239-1240)',
				'135' => 'Bun-ō (1260-1261)',
				'137' => 'Bun-ei (1264-1275)',
				'146' => 'Enkei (1308–1311)',
				'151' => 'Genkyō (1321–1324)',
				'153' => 'Kareki (1326–1329)',
				'156' => 'Kemmu (1334–1336)',
				'174' => 'Bun-an (1444-1449)',
				'190' => 'Tenmon (1532–1555)',
				'197' => 'Genwa (1615–1624)',
				'198' => 'Kan-ei (1624-1644)',
				'201' => 'Shōō (1652–1655)',
				'202' => 'Meiryaku (1655–1658)',
				'206' => 'Tenwa (1681–1684)',
				'215' => 'Kan-en (1748-1751)',
				'216' => 'Hōryaku (1751–1764)',
				'218' => 'An-ei (1772-1781)',
				'228' => 'Man-en (1860-1861)'
			},
			narrow => {
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'26' => 'Ten-an (857-859)',
				'146' => 'Enkei (1308–1311)',
				'153' => 'Kareki (1326–1329)',
				'214' => 'Enkei (1744–1748)'
			},
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'dangi' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
		'chinese' => {
			Ed => q{E d},
			Gy => q{U},
			GyMMM => q{MMM U},
			GyMMMEd => q{E d MMM U},
			GyMMMM => q{MMMM r(U)},
			GyMMMMEd => q{E d MMMM r(U)},
			GyMMMMd => q{d MMMM r(U)},
			GyMMMd => q{d MMM U},
			MEd => q{E d-M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{U},
			yMd => q{y-MM-dd},
			yyyy => q{U},
			yyyyM => q{M-y},
			yyyyMEd => q{E d-M-y},
			yyyyMMM => q{MMM U},
			yyyyMMMEd => q{E d MMM U},
			yyyyMMMM => q{MMMM U},
			yyyyMMMMEd => q{E d MMMM r(U)},
			yyyyMMMMd => q{d MMMM r(U)},
			yyyyMMMd => q{d MMM U},
			yyyyMd => q{d-M-y},
			yyyyQQQ => q{QQQ U},
			yyyyQQQQ => q{QQQQ U},
		},
		'dangi' => {
			Gy => q{r (U)},
			GyMMM => q{MMM r (U)},
			GyMMMEd => q{E d MMM r (U)},
			GyMMMd => q{d MMM r},
			UM => q{MM U},
			UMMM => q{MMM U},
			UMMMd => q{d MMM U},
			UMd => q{d-MM U},
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
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E d-M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
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
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E d-M},
			MMMEd => q{E d MMM},
			MMMMW => q{'week' W 'van' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d-M},
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
		'hebrew' => {
			MEd => q{E d MMM},
			Md => q{d MMM},
			y => q{y},
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
		'chinese' => {
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'coptic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'dangi' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'ethiopic' => {
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
				y => q{y – y G},
			},
			GyM => {
				G => q{M-y GGGGG – M-y GGGGG},
				M => q{M-y – M-y GGGGG},
				y => q{M-y – M-y GGGGG},
			},
			GyMEd => {
				G => q{E d-M-y GGGGG – E d-M-y GGGGG},
				M => q{E d-M-y – E d-M-y GGGGG},
				d => q{E d-M-y – E d-M-y GGGGG},
				y => q{E d-M-y – E d-M-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d-M-y GGGGG – d-M-y GGGGG},
				M => q{d-M-y – d-M-y GGGGG},
				d => q{d-M-y – d-M-y GGGGG},
				y => q{d-M-y – d-M-y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
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
				M => q{MM-y – MM-y G},
				y => q{MM-y – MM-y G},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y G},
				d => q{E dd-MM-y – E dd-MM-y G},
				y => q{E dd-MM-y – E dd-MM-y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y G},
				d => q{dd-MM-y – dd-MM-y G},
				y => q{dd-MM-y – dd-MM-y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M-y GGGGG – M-y GGGGG},
				M => q{M-y – M-y GGGGG},
				y => q{M-y – M-y GGGGG},
			},
			GyMEd => {
				G => q{E d-M-y GGGGG – E d-M-y GGGGG},
				M => q{E d-M-y – E d-M-y GGGGG},
				d => q{E d-M-y – E d-M-y GGGGG},
				y => q{E d-M-y – E d-M-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d-M-y GGGGG – d-M-y GGGGG},
				M => q{d-M-y – d-M-y GGGGG},
				d => q{d-M-y – d-M-y GGGGG},
				y => q{d-M-y – d-M-y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd-MM – E dd-MM},
				d => q{E dd-MM – E dd-MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMM => {
				M => q{MMMM–MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			yM => {
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E dd-MM-y – E dd-MM-y},
				d => q{E dd-MM-y – E dd-MM-y},
				y => q{E dd-MM-y – E dd-MM-y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
		},
		'hebrew' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'indian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'islamic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'persian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'roc' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
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
		regionFormat => q(tijd in {0}),
		regionFormat => q(zomertijd in {0}),
		regionFormat => q(standaardtijd in {0}),
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
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Caïro#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoem#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tomé#,
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
				'daylight' => q#Alaska Daylight Time#,
				'generic' => q#Alaska Time#,
				'standard' => q#Alaska Standard Time#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
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
				'daylight' => q#Amazon Summer Time#,
				'generic' => q#Amazon Time#,
				'standard' => q#Amazon Standard Time#,
			},
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Beneden Prinsen Kwartier#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico-Stad#,
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
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central Daylight Time#,
				'generic' => q#Central Time#,
				'standard' => q#Central Standard Time#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern Daylight Time#,
				'generic' => q#Eastern Time#,
				'standard' => q#Eastern Standard Time#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain Daylight Time#,
				'generic' => q#Mountain Time#,
				'standard' => q#Mountain Standard Time#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific Daylight Time#,
				'generic' => q#Pacific Time#,
				'standard' => q#Pacific Standard Time#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr-zomertijd#,
				'generic' => q#Anadyr-tijd#,
				'standard' => q#Anadyr-standaardtijd#,
			},
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
		'Argentina' => {
			long => {
				'daylight' => q#Argentina Summer Time#,
				'generic' => q#Argentina Time#,
				'standard' => q#Argentina Standard Time#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Western Argentina Summer Time#,
				'generic' => q#Western Argentina Time#,
				'standard' => q#Western Argentina Standard Time#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeense zomertijd#,
				'generic' => q#Armeense tijd#,
				'standard' => q#Armeense standaardtijd#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma-Ata#,
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
		'Asia/Beirut' => {
			exemplarCity => q#Beiroet#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tsjojbalsan#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Doesjanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkoetsk#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koeweit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manilla#,
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
		'Asia/Shanghai' => {
			exemplarCity => q#Sjanghai#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
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
				'daylight' => q#Atlantic Daylight Time#,
				'generic' => q#Atlantic Time#,
				'standard' => q#Atlantic Standard Time#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoren#,
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
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Zuid-Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sint-Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
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
				'standard' => q#Bolivia Time#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia Summer Time#,
				'generic' => q#Brasilia Time#,
				'standard' => q#Brasilia Standard Time#,
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
				'daylight' => q#Chile Summer Time#,
				'generic' => q#Chile Time#,
				'standard' => q#Chile Standard Time#,
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
				'daylight' => q#Colombia Summer Time#,
				'generic' => q#Colombia Time#,
				'standard' => q#Colombia Standard Time#,
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
				'daylight' => q#Cuba Daylight Time#,
				'generic' => q#Cuba Time#,
				'standard' => q#Cuba Standard Time#,
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
				'daylight' => q#Easter Island Summer Time#,
				'generic' => q#Easter Island Time#,
				'standard' => q#Easter Island Standard Time#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuador Time#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#gecoördineerde wereldtijd#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#onbekende stad#,
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
		'Europe/Brussels' => {
			exemplarCity => q#Brussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Boekarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Boedapest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ierse standaardtijd#,
			},
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanboel#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
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
		'Europe/Moscow' => {
			exemplarCity => q#Moskou#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parijs#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praag#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Oezjhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticaanstad#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wenen#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
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
				'daylight' => q#Falkland Islands Summer Time#,
				'generic' => q#Falkland Islands Time#,
				'standard' => q#Falkland Islands Standard Time#,
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
				'standard' => q#French Guiana Time#,
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
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos Time#,
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
				'daylight' => q#East Greenland Summer Time#,
				'generic' => q#East Greenland Time#,
				'standard' => q#East Greenland Standard Time#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#West Greenland Summer Time#,
				'generic' => q#West Greenland Time#,
				'standard' => q#West Greenland Standard Time#,
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
				'standard' => q#Guyana Time#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian Daylight Time#,
				'generic' => q#Hawaii-Aleutian Time#,
				'standard' => q#Hawaii-Aleutian Standard Time#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
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
		'Indian/Chagos' => {
			exemplarCity => q#Chagosarchipel#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmaseiland#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocoseilanden#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiven#,
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
				'daylight' => q#Northwest Mexico Daylight Time#,
				'generic' => q#Northwest Mexico Time#,
				'standard' => q#Northwest Mexico Standard Time#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexican Pacific Daylight Time#,
				'generic' => q#Mexican Pacific Time#,
				'standard' => q#Mexican Pacific Standard Time#,
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
				'daylight' => q#Newfoundland Daylight Time#,
				'generic' => q#Newfoundland Time#,
				'standard' => q#Newfoundland Standard Time#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuese tijd#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolkeilandse zomertijd#,
				'generic' => q#Norfolkeilandse tijd#,
				'standard' => q#Norfolkeilandse standaardtijd#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha Summer Time#,
				'generic' => q#Fernando de Noronha Time#,
				'standard' => q#Fernando de Noronha Standard Time#,
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
		'Pacific/Easter' => {
			exemplarCity => q#Paaseiland#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Îles Gambier#,
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
			exemplarCity => q#Marquesaseilanden#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
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
				'daylight' => q#Paraguay Summer Time#,
				'generic' => q#Paraguay Time#,
				'standard' => q#Paraguay Standard Time#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Summer Time#,
				'generic' => q#Peru Time#,
				'standard' => q#Peru Standard Time#,
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
				'daylight' => q#St. Pierre & Miquelon Daylight Time#,
				'generic' => q#St. Pierre & Miquelon Time#,
				'standard' => q#St. Pierre & Miquelon Standard Time#,
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
				'generic' => q#Uruguay Time#,
				'standard' => q#Uruguay Standard Time#,
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
		'Yukon' => {
			long => {
				'standard' => q#Yukon Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
