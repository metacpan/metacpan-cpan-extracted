=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Vi - Package for language Vietnamese

=cut

package Locale::CLDR::Locales::Vi;
# This file auto generated from Data\common\main\vi.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'after-hundred' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(lẻ =%spellout-cardinal=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'after-thousand-or-more' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(không trăm =%%after-hundred=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal=),
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
					rule => q(thứ =#,##0=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(thứ =#,##0=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(âm →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(không),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← phẩy →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(một),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(hai),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ba),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(bốn),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(năm),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sáu),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(bảy),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(tám),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(chín),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(mười[ →%%teen→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←← mươi[ →%%x-ty→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← trăm[ →%%after-hundred→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← nghìn[ →%%after-thousand-or-more→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← triệu[ →%%after-hundred→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← tỷ[ →%%after-hundred→]),
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(thứ =%spellout-cardinal=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(thứ nhất),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(thứ nhì),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(thứ =%spellout-cardinal=),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(thứ tư),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(thứ =%spellout-cardinal=),
				},
				'max' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(thứ =%spellout-cardinal=),
				},
			},
		},
		'teen' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(lăm),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'x-ty' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(mốt),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%teen=),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(tư),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(=%%teen=),
				},
				'max' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(=%%teen=),
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
				'aa' => 'Tiếng Afar',
 				'ab' => 'Tiếng Abkhazia',
 				'ace' => 'Tiếng Achinese',
 				'ach' => 'Tiếng Acoli',
 				'ada' => 'Tiếng Adangme',
 				'ady' => 'Tiếng Adyghe',
 				'ae' => 'Tiếng Avestan',
 				'af' => 'Tiếng Afrikaans',
 				'afh' => 'Tiếng Afrihili',
 				'agq' => 'Tiếng Aghem',
 				'ain' => 'Tiếng Ainu',
 				'ak' => 'Tiếng Akan',
 				'akk' => 'Tiếng Akkadia',
 				'akz' => 'Tiếng Alabama',
 				'ale' => 'Tiếng Aleut',
 				'aln' => 'Tiếng Gheg Albani',
 				'alt' => 'Tiếng Altai Miền Nam',
 				'am' => 'Tiếng Amharic',
 				'an' => 'Tiếng Aragon',
 				'ang' => 'Tiếng Anh cổ',
 				'ann' => 'Tiếng Obolo',
 				'anp' => 'Tiếng Angika',
 				'ar' => 'Tiếng Ả Rập',
 				'ar_001' => 'Tiếng Ả Rập Hiện đại',
 				'arc' => 'Tiếng Aramaic',
 				'arn' => 'Tiếng Mapuche',
 				'aro' => 'Tiếng Araona',
 				'arp' => 'Tiếng Arapaho',
 				'arq' => 'Tiếng Ả Rập Algeria',
 				'ars' => 'Tiếng Ả Rập Najdi',
 				'arw' => 'Tiếng Arawak',
 				'arz' => 'Tiếng Ả Rập Ai Cập',
 				'as' => 'Tiếng Assam',
 				'asa' => 'Tiếng Asu',
 				'ase' => 'Ngôn ngữ Ký hiệu Mỹ',
 				'ast' => 'Tiếng Asturias',
 				'atj' => 'Tiếng Atikamekw',
 				'av' => 'Tiếng Avaric',
 				'awa' => 'Tiếng Awadhi',
 				'ay' => 'Tiếng Aymara',
 				'az' => 'Tiếng Azerbaijan',
 				'az@alt=short' => 'Tiếng Azeri',
 				'ba' => 'Tiếng Bashkir',
 				'bal' => 'Tiếng Baluchi',
 				'ban' => 'Tiếng Bali',
 				'bar' => 'Tiếng Bavaria',
 				'bas' => 'Tiếng Basaa',
 				'bax' => 'Tiếng Bamun',
 				'bbc' => 'Tiếng Batak Toba',
 				'bbj' => 'Tiếng Ghomala',
 				'be' => 'Tiếng Belarus',
 				'bej' => 'Tiếng Beja',
 				'bem' => 'Tiếng Bemba',
 				'bew' => 'Tiếng Betawi',
 				'bez' => 'Tiếng Bena',
 				'bfd' => 'Tiếng Bafut',
 				'bfq' => 'Tiếng Badaga',
 				'bg' => 'Tiếng Bulgaria',
 				'bgc' => 'Tiếng Haryana',
 				'bgn' => 'Tiếng Tây Balochi',
 				'bho' => 'Tiếng Bhojpuri',
 				'bi' => 'Tiếng Bislama',
 				'bik' => 'Tiếng Bikol',
 				'bin' => 'Tiếng Bini',
 				'bjn' => 'Tiếng Banjar',
 				'bkm' => 'Tiếng Kom',
 				'bla' => 'Tiếng Siksika',
 				'bm' => 'Tiếng Bambara',
 				'bn' => 'Tiếng Bangla',
 				'bo' => 'Tiếng Tây Tạng',
 				'bpy' => 'Tiếng Bishnupriya',
 				'bqi' => 'Tiếng Bakhtiari',
 				'br' => 'Tiếng Breton',
 				'bra' => 'Tiếng Braj',
 				'brh' => 'Tiếng Brahui',
 				'brx' => 'Tiếng Bodo',
 				'bs' => 'Tiếng Bosnia',
 				'bss' => 'Tiếng Akoose',
 				'bua' => 'Tiếng Buriat',
 				'bug' => 'Tiếng Bugin',
 				'bum' => 'Tiếng Bulu',
 				'byn' => 'Tiếng Blin',
 				'byv' => 'Tiếng Medumba',
 				'ca' => 'Tiếng Catalan',
 				'cad' => 'Tiếng Caddo',
 				'car' => 'Tiếng Carib',
 				'cay' => 'Tiếng Cayuga',
 				'cch' => 'Tiếng Atsam',
 				'ccp' => 'Tiếng Chakma',
 				'ce' => 'Tiếng Chechen',
 				'ceb' => 'Tiếng Cebuano',
 				'cgg' => 'Tiếng Chiga',
 				'ch' => 'Tiếng Chamorro',
 				'chb' => 'Tiếng Chibcha',
 				'chg' => 'Tiếng Chagatai',
 				'chk' => 'Tiếng Chuuk',
 				'chm' => 'Tiếng Mari',
 				'chn' => 'Biệt ngữ Chinook',
 				'cho' => 'Tiếng Choctaw',
 				'chp' => 'Tiếng Chipewyan',
 				'chr' => 'Tiếng Cherokee',
 				'chy' => 'Tiếng Cheyenne',
 				'ckb' => 'Tiếng Kurd Miền Trung',
 				'ckb@alt=variant' => 'Tiếng Kurd Sorani',
 				'clc' => 'Tiếng Chilcotin',
 				'co' => 'Tiếng Corsica',
 				'cop' => 'Tiếng Coptic',
 				'cps' => 'Tiếng Capiznon',
 				'cr' => 'Tiếng Cree',
 				'crg' => 'Tiếng Michif',
 				'crh' => 'Tiếng Thổ Nhĩ Kỳ Crimean',
 				'crj' => 'Tiếng Cree Đông Nam',
 				'crk' => 'Tiếng Plains Cree',
 				'crl' => 'Tiếng Cree Đông Bắc',
 				'crm' => 'Tiếng Moose Cree',
 				'crr' => 'Tiếng Carolina Algonquian',
 				'crs' => 'Tiếng Pháp Seselwa Creole',
 				'cs' => 'Tiếng Séc',
 				'csb' => 'Tiếng Kashubia',
 				'csw' => 'Tiếng Swampy Cree',
 				'cu' => 'Tiếng Slavơ Nhà thờ',
 				'cv' => 'Tiếng Chuvash',
 				'cy' => 'Tiếng Wales',
 				'da' => 'Tiếng Đan Mạch',
 				'dak' => 'Tiếng Dakota',
 				'dar' => 'Tiếng Dargwa',
 				'dav' => 'Tiếng Taita',
 				'de' => 'Tiếng Đức',
 				'de_CH' => 'Tiếng Thượng Giéc-man (Thụy Sĩ)',
 				'del' => 'Tiếng Delaware',
 				'den' => 'Tiếng Slave',
 				'dgr' => 'Tiếng Dogrib',
 				'din' => 'Tiếng Dinka',
 				'dje' => 'Tiếng Zarma',
 				'doi' => 'Tiếng Dogri',
 				'dsb' => 'Tiếng Hạ Sorbia',
 				'dtp' => 'Tiếng Dusun Miền Trung',
 				'dua' => 'Tiếng Duala',
 				'dum' => 'Tiếng Hà Lan Trung cổ',
 				'dv' => 'Tiếng Divehi',
 				'dyo' => 'Tiếng Jola-Fonyi',
 				'dyu' => 'Tiếng Dyula',
 				'dz' => 'Tiếng Dzongkha',
 				'dzg' => 'Tiếng Dazaga',
 				'ebu' => 'Tiếng Embu',
 				'ee' => 'Tiếng Ewe',
 				'efi' => 'Tiếng Efik',
 				'egl' => 'Tiếng Emilia',
 				'egy' => 'Tiếng Ai Cập cổ',
 				'eka' => 'Tiếng Ekajuk',
 				'el' => 'Tiếng Hy Lạp',
 				'elx' => 'Tiếng Elamite',
 				'en' => 'Tiếng Anh',
 				'en_GB' => 'Tiếng Anh (Anh)',
 				'en_US' => 'Tiếng Anh (Mỹ)',
 				'enm' => 'Tiếng Anh Trung cổ',
 				'eo' => 'Tiếng Quốc Tế Ngữ',
 				'es' => 'Tiếng Tây Ban Nha',
 				'es_419' => 'Tiếng Tây Ban Nha (Mỹ La tinh)',
 				'es_ES' => 'Tiếng Tây Ban Nha (Châu Âu)',
 				'esu' => 'Tiếng Yupik Miền Trung',
 				'et' => 'Tiếng Estonia',
 				'eu' => 'Tiếng Basque',
 				'ewo' => 'Tiếng Ewondo',
 				'ext' => 'Tiếng Extremadura',
 				'fa' => 'Tiếng Ba Tư',
 				'fa_AF' => 'Tiếng Dari',
 				'fan' => 'Tiếng Fang',
 				'fat' => 'Tiếng Fanti',
 				'ff' => 'Tiếng Fulah',
 				'fi' => 'Tiếng Phần Lan',
 				'fil' => 'Tiếng Philippines',
 				'fj' => 'Tiếng Fiji',
 				'fo' => 'Tiếng Faroe',
 				'fon' => 'Tiếng Fon',
 				'fr' => 'Tiếng Pháp',
 				'frc' => 'Tiếng Pháp Cajun',
 				'frm' => 'Tiếng Pháp Trung cổ',
 				'fro' => 'Tiếng Pháp cổ',
 				'frp' => 'Tiếng Arpitan',
 				'frr' => 'Tiếng Frisia Miền Bắc',
 				'frs' => 'Tiếng Frisian Miền Đông',
 				'fur' => 'Tiếng Friulian',
 				'fy' => 'Tiếng Frisia',
 				'ga' => 'Tiếng Ireland',
 				'gaa' => 'Tiếng Ga',
 				'gag' => 'Tiếng Gagauz',
 				'gan' => 'Tiếng Cám',
 				'gay' => 'Tiếng Gayo',
 				'gba' => 'Tiếng Gbaya',
 				'gd' => 'Tiếng Gael Scotland',
 				'gez' => 'Tiếng Geez',
 				'gil' => 'Tiếng Gilbert',
 				'gl' => 'Tiếng Galician',
 				'glk' => 'Tiếng Gilaki',
 				'gmh' => 'Tiếng Thượng Giéc-man Trung cổ',
 				'gn' => 'Tiếng Guarani',
 				'goh' => 'Tiếng Thượng Giéc-man cổ',
 				'gom' => 'Tiếng Goan Konkani',
 				'gon' => 'Tiếng Gondi',
 				'gor' => 'Tiếng Gorontalo',
 				'got' => 'Tiếng Gô-tích',
 				'grb' => 'Tiếng Grebo',
 				'grc' => 'Tiếng Hy Lạp cổ',
 				'gsw' => 'Tiếng Đức (Thụy Sĩ)',
 				'gu' => 'Tiếng Gujarati',
 				'gur' => 'Tiếng Frafra',
 				'guz' => 'Tiếng Gusii',
 				'gv' => 'Tiếng Manx',
 				'gwi' => 'Tiếng Gwichʼin',
 				'ha' => 'Tiếng Hausa',
 				'hai' => 'Tiếng Haida',
 				'hak' => 'Tiếng Khách Gia',
 				'haw' => 'Tiếng Hawaii',
 				'hax' => 'Tiếng Haida miền Nam',
 				'he' => 'Tiếng Do Thái',
 				'hi' => 'Tiếng Hindi',
 				'hi_Latn@alt=variant' => 'Tiếng Hindi (lai tiếng Anh)',
 				'hif' => 'Tiếng Fiji Hindi',
 				'hil' => 'Tiếng Hiligaynon',
 				'hit' => 'Tiếng Hittite',
 				'hmn' => 'Tiếng H’Mông',
 				'ho' => 'Tiếng Hiri Motu',
 				'hr' => 'Tiếng Croatia',
 				'hsb' => 'Tiếng Thượng Sorbia',
 				'hsn' => 'Tiếng Tương',
 				'ht' => 'Tiếng Haiti',
 				'hu' => 'Tiếng Hungary',
 				'hup' => 'Tiếng Hupa',
 				'hur' => 'Tiếng Halkomelem',
 				'hy' => 'Tiếng Armenia',
 				'hz' => 'Tiếng Herero',
 				'ia' => 'Tiếng Khoa Học Quốc Tế',
 				'iba' => 'Tiếng Iban',
 				'ibb' => 'Tiếng Ibibio',
 				'id' => 'Tiếng Indonesia',
 				'ie' => 'Tiếng Interlingue',
 				'ig' => 'Tiếng Igbo',
 				'ii' => 'Tiếng Di Tứ Xuyên',
 				'ik' => 'Tiếng Inupiaq',
 				'ikt' => 'Tiếng Inuktitut miền Tây Canada',
 				'ilo' => 'Tiếng Iloko',
 				'inh' => 'Tiếng Ingush',
 				'io' => 'Tiếng Ido',
 				'is' => 'Tiếng Iceland',
 				'it' => 'Tiếng Italy',
 				'iu' => 'Tiếng Inuktitut',
 				'izh' => 'Tiếng Ingria',
 				'ja' => 'Tiếng Nhật',
 				'jam' => 'Tiếng Anh Jamaica Creole',
 				'jbo' => 'Tiếng Lojban',
 				'jgo' => 'Tiếng Ngomba',
 				'jmc' => 'Tiếng Machame',
 				'jpr' => 'Tiếng Judeo-Ba Tư',
 				'jrb' => 'Tiếng Judeo-Ả Rập',
 				'jut' => 'Tiếng Jutish',
 				'jv' => 'Tiếng Java',
 				'ka' => 'Tiếng Georgia',
 				'kaa' => 'Tiếng Kara-Kalpak',
 				'kab' => 'Tiếng Kabyle',
 				'kac' => 'Tiếng Kachin',
 				'kaj' => 'Tiếng Jju',
 				'kam' => 'Tiếng Kamba',
 				'kaw' => 'Tiếng Kawi',
 				'kbd' => 'Tiếng Kabardian',
 				'kbl' => 'Tiếng Kanembu',
 				'kcg' => 'Tiếng Tyap',
 				'kde' => 'Tiếng Makonde',
 				'kea' => 'Tiếng Kabuverdianu',
 				'kfo' => 'Tiếng Koro',
 				'kg' => 'Tiếng Kongo',
 				'kgp' => 'Tiếng Kaingang',
 				'kha' => 'Tiếng Khasi',
 				'kho' => 'Tiếng Khotan',
 				'khq' => 'Tiếng Koyra Chiini',
 				'ki' => 'Tiếng Kikuyu',
 				'kj' => 'Tiếng Kuanyama',
 				'kk' => 'Tiếng Kazakh',
 				'kkj' => 'Tiếng Kako',
 				'kl' => 'Tiếng Kalaallisut',
 				'kln' => 'Tiếng Kalenjin',
 				'km' => 'Tiếng Khmer',
 				'kmb' => 'Tiếng Kimbundu',
 				'kn' => 'Tiếng Kannada',
 				'ko' => 'Tiếng Hàn',
 				'koi' => 'Tiếng Komi-Permyak',
 				'kok' => 'Tiếng Konkani',
 				'kos' => 'Tiếng Kosrae',
 				'kpe' => 'Tiếng Kpelle',
 				'kr' => 'Tiếng Kanuri',
 				'krc' => 'Tiếng Karachay-Balkar',
 				'krl' => 'Tiếng Karelian',
 				'kru' => 'Tiếng Kurukh',
 				'ks' => 'Tiếng Kashmir',
 				'ksb' => 'Tiếng Shambala',
 				'ksf' => 'Tiếng Bafia',
 				'ksh' => 'Tiếng Cologne',
 				'ku' => 'Tiếng Kurd',
 				'kum' => 'Tiếng Kumyk',
 				'kut' => 'Tiếng Kutenai',
 				'kv' => 'Tiếng Komi',
 				'kw' => 'Tiếng Cornwall',
 				'kwk' => 'Tiếng Kwakʼwala',
 				'ky' => 'Tiếng Kyrgyz',
 				'la' => 'Tiếng La-tinh',
 				'lad' => 'Tiếng Ladino',
 				'lag' => 'Tiếng Langi',
 				'lah' => 'Tiếng Lahnda',
 				'lam' => 'Tiếng Lamba',
 				'lb' => 'Tiếng Luxembourg',
 				'lez' => 'Tiếng Lezghian',
 				'lg' => 'Tiếng Ganda',
 				'li' => 'Tiếng Limburg',
 				'lil' => 'Tiếng Lillooet',
 				'lkt' => 'Tiếng Lakota',
 				'lmo' => 'Tiếng Lombard',
 				'ln' => 'Tiếng Lingala',
 				'lo' => 'Tiếng Lào',
 				'lol' => 'Tiếng Mongo',
 				'lou' => 'Tiếng Creole Louisiana',
 				'loz' => 'Tiếng Lozi',
 				'lrc' => 'Tiếng Bắc Luri',
 				'lsm' => 'Tiếng Saamia',
 				'lt' => 'Tiếng Litva',
 				'lu' => 'Tiếng Luba-Katanga',
 				'lua' => 'Tiếng Luba-Lulua',
 				'lui' => 'Tiếng Luiseno',
 				'lun' => 'Tiếng Lunda',
 				'luo' => 'Tiếng Luo',
 				'lus' => 'Tiếng Lushai',
 				'luy' => 'Tiếng Luyia',
 				'lv' => 'Tiếng Latvia',
 				'mad' => 'Tiếng Madura',
 				'maf' => 'Tiếng Mafa',
 				'mag' => 'Tiếng Magahi',
 				'mai' => 'Tiếng Maithili',
 				'mak' => 'Tiếng Makasar',
 				'man' => 'Tiếng Mandingo',
 				'mas' => 'Tiếng Masai',
 				'mde' => 'Tiếng Maba',
 				'mdf' => 'Tiếng Moksha',
 				'mdr' => 'Tiếng Mandar',
 				'men' => 'Tiếng Mende',
 				'mer' => 'Tiếng Meru',
 				'mfe' => 'Tiếng Morisyen',
 				'mg' => 'Tiếng Malagasy',
 				'mga' => 'Tiếng Ai-len Trung cổ',
 				'mgh' => 'Tiếng Makhuwa-Meetto',
 				'mgo' => 'Tiếng Meta’',
 				'mh' => 'Tiếng Marshall',
 				'mi' => 'Tiếng Māori',
 				'mic' => 'Tiếng Micmac',
 				'min' => 'Tiếng Minangkabau',
 				'mk' => 'Tiếng Macedonia',
 				'ml' => 'Tiếng Malayalam',
 				'mn' => 'Tiếng Mông Cổ',
 				'mnc' => 'Tiếng Mãn Châu',
 				'mni' => 'Tiếng Manipuri',
 				'moe' => 'Tiếng Innu-aimun',
 				'moh' => 'Tiếng Mohawk',
 				'mos' => 'Tiếng Mossi',
 				'mr' => 'Tiếng Marathi',
 				'ms' => 'Tiếng Mã Lai',
 				'mt' => 'Tiếng Malta',
 				'mua' => 'Tiếng Mundang',
 				'mul' => 'Nhiều Ngôn ngữ',
 				'mus' => 'Tiếng Creek',
 				'mwl' => 'Tiếng Miranda',
 				'mwr' => 'Tiếng Marwari',
 				'my' => 'Tiếng Miến Điện',
 				'mye' => 'Tiếng Myene',
 				'myv' => 'Tiếng Erzya',
 				'mzn' => 'Tiếng Mazanderani',
 				'na' => 'Tiếng Nauru',
 				'nan' => 'Tiếng Mân Nam',
 				'nap' => 'Tiếng Napoli',
 				'naq' => 'Tiếng Nama',
 				'nb' => 'Tiếng Na Uy (Bokmål)',
 				'nd' => 'Tiếng Ndebele Miền Bắc',
 				'nds' => 'Tiếng Hạ Giéc-man',
 				'nds_NL' => 'Tiếng Hạ Saxon',
 				'ne' => 'Tiếng Nepal',
 				'new' => 'Tiếng Newari',
 				'ng' => 'Tiếng Ndonga',
 				'nia' => 'Tiếng Nias',
 				'niu' => 'Tiếng Niuean',
 				'njo' => 'Tiếng Ao Naga',
 				'nl' => 'Tiếng Hà Lan',
 				'nl_BE' => 'Tiếng Flemish',
 				'nmg' => 'Tiếng Kwasio',
 				'nn' => 'Tiếng Na Uy (Nynorsk)',
 				'nnh' => 'Tiếng Ngiemboon',
 				'no' => 'Tiếng Na Uy',
 				'nog' => 'Tiếng Nogai',
 				'non' => 'Tiếng Na Uy cổ',
 				'nqo' => 'Tiếng N’Ko',
 				'nr' => 'Tiếng Ndebele Miền Nam',
 				'nso' => 'Tiếng Sotho Miền Bắc',
 				'nus' => 'Tiếng Nuer',
 				'nv' => 'Tiếng Navajo',
 				'nwc' => 'Tiếng Newari cổ',
 				'ny' => 'Tiếng Nyanja',
 				'nym' => 'Tiếng Nyamwezi',
 				'nyn' => 'Tiếng Nyankole',
 				'nyo' => 'Tiếng Nyoro',
 				'nzi' => 'Tiếng Nzima',
 				'oc' => 'Tiếng Occitan',
 				'oj' => 'Tiếng Ojibwa',
 				'ojb' => 'Tiếng Ojibwe Tây Bắc',
 				'ojc' => 'Tiếng Ojibwe miền Trung',
 				'ojs' => 'Tiếng Oji-Cree',
 				'ojw' => 'Tiếng Ojibwe miền Tây',
 				'oka' => 'Tiếng Okanagan',
 				'om' => 'Tiếng Oromo',
 				'or' => 'Tiếng Odia',
 				'os' => 'Tiếng Ossetic',
 				'osa' => 'Tiếng Osage',
 				'ota' => 'Tiếng Thổ Nhĩ Kỳ Ottoman',
 				'pa' => 'Tiếng Punjab',
 				'pag' => 'Tiếng Pangasinan',
 				'pal' => 'Tiếng Pahlavi',
 				'pam' => 'Tiếng Pampanga',
 				'pap' => 'Tiếng Papiamento',
 				'pau' => 'Tiếng Palauan',
 				'pcm' => 'Tiếng Nigeria Pidgin',
 				'peo' => 'Tiếng Ba Tư cổ',
 				'phn' => 'Tiếng Phoenicia',
 				'pi' => 'Tiếng Pali',
 				'pis' => 'Tiếng Pijin',
 				'pl' => 'Tiếng Ba Lan',
 				'pon' => 'Tiếng Pohnpeian',
 				'pqm' => 'Tiếng Maliseet-Passamaquoddy',
 				'prg' => 'Tiếng Prussia',
 				'pro' => 'Tiếng Provençal cổ',
 				'ps' => 'Tiếng Pashto',
 				'ps@alt=variant' => 'Tiếng Pushto',
 				'pt' => 'Tiếng Bồ Đào Nha',
 				'pt_PT' => 'Tiếng Bồ Đào Nha (Châu Âu)',
 				'qu' => 'Tiếng Quechua',
 				'quc' => 'Tiếng Kʼicheʼ',
 				'qug' => 'Tiếng Quechua ở Cao nguyên Chimborazo',
 				'raj' => 'Tiếng Rajasthani',
 				'rap' => 'Tiếng Rapanui',
 				'rar' => 'Tiếng Rarotongan',
 				'rhg' => 'Tiếng Rohingya',
 				'rm' => 'Tiếng Romansh',
 				'rn' => 'Tiếng Rundi',
 				'ro' => 'Tiếng Romania',
 				'ro_MD' => 'Tiếng Moldova',
 				'rof' => 'Tiếng Rombo',
 				'rom' => 'Tiếng Romany',
 				'ru' => 'Tiếng Nga',
 				'rup' => 'Tiếng Aromania',
 				'rw' => 'Tiếng Kinyarwanda',
 				'rwk' => 'Tiếng Rwa',
 				'sa' => 'Tiếng Phạn',
 				'sad' => 'Tiếng Sandawe',
 				'sah' => 'Tiếng Sakha',
 				'sam' => 'Tiếng Samaritan Aramaic',
 				'saq' => 'Tiếng Samburu',
 				'sas' => 'Tiếng Sasak',
 				'sat' => 'Tiếng Santali',
 				'sba' => 'Tiếng Ngambay',
 				'sbp' => 'Tiếng Sangu',
 				'sc' => 'Tiếng Sardinia',
 				'scn' => 'Tiếng Sicilia',
 				'sco' => 'Tiếng Scots',
 				'sd' => 'Tiếng Sindhi',
 				'sdh' => 'Tiếng Kurd Miền Nam',
 				'se' => 'Tiếng Sami Miền Bắc',
 				'see' => 'Tiếng Seneca',
 				'seh' => 'Tiếng Sena',
 				'sel' => 'Tiếng Selkup',
 				'ses' => 'Tiếng Koyraboro Senni',
 				'sg' => 'Tiếng Sango',
 				'sga' => 'Tiếng Ai-len cổ',
 				'sh' => 'Tiếng Serbo-Croatia',
 				'shi' => 'Tiếng Tachelhit',
 				'shn' => 'Tiếng Shan',
 				'shu' => 'Tiếng Ả-Rập Chad',
 				'si' => 'Tiếng Sinhala',
 				'sid' => 'Tiếng Sidamo',
 				'sk' => 'Tiếng Slovak',
 				'sl' => 'Tiếng Slovenia',
 				'slh' => 'Tiếng Lushootseed miền Nam',
 				'sm' => 'Tiếng Samoa',
 				'sma' => 'Tiếng Sami Miền Nam',
 				'smj' => 'Tiếng Lule Sami',
 				'smn' => 'Tiếng Inari Sami',
 				'sms' => 'Tiếng Skolt Sami',
 				'sn' => 'Tiếng Shona',
 				'snk' => 'Tiếng Soninke',
 				'so' => 'Tiếng Somali',
 				'sog' => 'Tiếng Sogdien',
 				'sq' => 'Tiếng Albania',
 				'sr' => 'Tiếng Serbia',
 				'srn' => 'Tiếng Sranan Tongo',
 				'srr' => 'Tiếng Serer',
 				'ss' => 'Tiếng Swati',
 				'ssy' => 'Tiếng Saho',
 				'st' => 'Tiếng Sotho Miền Nam',
 				'str' => 'Tiếng Straits Salish',
 				'su' => 'Tiếng Sunda',
 				'suk' => 'Tiếng Sukuma',
 				'sus' => 'Tiếng Susu',
 				'sux' => 'Tiếng Sumeria',
 				'sv' => 'Tiếng Thụy Điển',
 				'sw' => 'Tiếng Swahili',
 				'sw_CD' => 'Tiếng Swahili Congo',
 				'swb' => 'Tiếng Cômo',
 				'syc' => 'Tiếng Syriac cổ',
 				'syr' => 'Tiếng Syriac',
 				'ta' => 'Tiếng Tamil',
 				'tce' => 'Tiếng Tutchone miền Nam',
 				'te' => 'Tiếng Telugu',
 				'tem' => 'Tiếng Timne',
 				'teo' => 'Tiếng Teso',
 				'ter' => 'Tiếng Tereno',
 				'tet' => 'Tiếng Tetum',
 				'tg' => 'Tiếng Tajik',
 				'tgx' => 'Tiếng Tagish',
 				'th' => 'Tiếng Thái',
 				'tht' => 'Tiếng Tahltan',
 				'ti' => 'Tiếng Tigrinya',
 				'tig' => 'Tiếng Tigre',
 				'tiv' => 'Tiếng Tiv',
 				'tk' => 'Tiếng Turkmen',
 				'tkl' => 'Tiếng Tokelau',
 				'tl' => 'Tiếng Tagalog',
 				'tlh' => 'Tiếng Klingon',
 				'tli' => 'Tiếng Tlingit',
 				'tmh' => 'Tiếng Tamashek',
 				'tn' => 'Tiếng Tswana',
 				'to' => 'Tiếng Tonga',
 				'tog' => 'Tiếng Nyasa Tonga',
 				'tok' => 'Tiếng Toki Pona',
 				'tpi' => 'Tiếng Tok Pisin',
 				'tr' => 'Tiếng Thổ Nhĩ Kỳ',
 				'trv' => 'Tiếng Taroko',
 				'ts' => 'Tiếng Tsonga',
 				'tsi' => 'Tiếng Tsimshian',
 				'tt' => 'Tiếng Tatar',
 				'ttm' => 'Tiếng Tutchone miền Bắc',
 				'tum' => 'Tiếng Tumbuka',
 				'tvl' => 'Tiếng Tuvalu',
 				'tw' => 'Tiếng Twi',
 				'twq' => 'Tiếng Tasawaq',
 				'ty' => 'Tiếng Tahiti',
 				'tyv' => 'Tiếng Tuvinian',
 				'tzm' => 'Tiếng Tamazight Miền Trung Ma-rốc',
 				'udm' => 'Tiếng Udmurt',
 				'ug' => 'Tiếng Uyghur',
 				'uga' => 'Tiếng Ugaritic',
 				'uk' => 'Tiếng Ukraina',
 				'umb' => 'Tiếng Umbundu',
 				'und' => 'Ngôn ngữ không xác định',
 				'ur' => 'Tiếng Urdu',
 				'uz' => 'Tiếng Uzbek',
 				'vai' => 'Tiếng Vai',
 				've' => 'Tiếng Venda',
 				'vi' => 'Tiếng Việt',
 				'vo' => 'Tiếng Volapük',
 				'vot' => 'Tiếng Votic',
 				'vun' => 'Tiếng Vunjo',
 				'wa' => 'Tiếng Walloon',
 				'wae' => 'Tiếng Walser',
 				'wal' => 'Tiếng Walamo',
 				'war' => 'Tiếng Waray',
 				'was' => 'Tiếng Washo',
 				'wbp' => 'Tiếng Warlpiri',
 				'wo' => 'Tiếng Wolof',
 				'wuu' => 'Tiếng Ngô',
 				'xal' => 'Tiếng Kalmyk',
 				'xh' => 'Tiếng Xhosa',
 				'xog' => 'Tiếng Soga',
 				'yao' => 'Tiếng Yao',
 				'yap' => 'Tiếng Yap',
 				'yav' => 'Tiếng Yangben',
 				'ybb' => 'Tiếng Yemba',
 				'yi' => 'Tiếng Yiddish',
 				'yo' => 'Tiếng Yoruba',
 				'yrl' => 'Tiếng Nheengatu',
 				'yue' => 'Tiếng Quảng Đông',
 				'yue@alt=menu' => 'Tiếng Trung (Tiếng Quảng Đông)',
 				'za' => 'Tiếng Choang',
 				'zap' => 'Tiếng Zapotec',
 				'zbl' => 'Ký hiệu Blissymbols',
 				'zen' => 'Tiếng Zenaga',
 				'zgh' => 'Tiếng Tamazight Chuẩn của Ma-rốc',
 				'zh' => 'Tiếng Trung',
 				'zh@alt=menu' => 'Tiếng Trung (Phổ thông)',
 				'zh_Hans@alt=long' => 'Tiếng Trung Phổ thông (Giản thể)',
 				'zh_Hant@alt=long' => 'Tiếng Trung Phổ thông (Phồn thể)',
 				'zu' => 'Tiếng Zulu',
 				'zun' => 'Tiếng Zuni',
 				'zxx' => 'Không có nội dung ngôn ngữ',
 				'zza' => 'Tiếng Zaza',

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
			'Adlm' => 'Chữ Adlam',
 			'Afak' => 'Chữ Afaka',
 			'Arab' => 'Chữ Ả Rập',
 			'Arab@alt=variant' => 'Chữ Ba Tư-Ả Rập',
 			'Aran' => 'Chữ Nastaliq',
 			'Armi' => 'Chữ Imperial Aramaic',
 			'Armn' => 'Chữ Armenia',
 			'Avst' => 'Chữ Avestan',
 			'Bali' => 'Chữ Bali',
 			'Bamu' => 'Chữ Bamum',
 			'Bass' => 'Chữ Bassa Vah',
 			'Batk' => 'Chữ Batak',
 			'Beng' => 'Chữ Bangla',
 			'Blis' => 'Chữ Blissymbols',
 			'Bopo' => 'Chữ Bopomofo',
 			'Brah' => 'Chữ Brahmi',
 			'Brai' => 'Chữ nổi Braille',
 			'Bugi' => 'Chữ Bugin',
 			'Buhd' => 'Chữ Buhid',
 			'Cakm' => 'Chữ Chakma',
 			'Cans' => 'Âm tiết Thổ dân Canada Hợp nhất',
 			'Cari' => 'Chữ Caria',
 			'Cham' => 'Chữ Chăm',
 			'Cher' => 'Chữ Cherokee',
 			'Cirt' => 'Chữ Cirth',
 			'Copt' => 'Chữ Coptic',
 			'Cprt' => 'Chứ Síp',
 			'Cyrl' => 'Chữ Kirin',
 			'Cyrs' => 'Chữ Kirin Slavơ Nhà thờ cổ',
 			'Deva' => 'Chữ Devanagari',
 			'Dsrt' => 'Chữ Deseret',
 			'Dupl' => 'Chữ tốc ký Duployan',
 			'Egyd' => 'Chữ Ai Cập bình dân',
 			'Egyh' => 'Chữ Ai Cập thày tu',
 			'Egyp' => 'Chữ tượng hình Ai Cập',
 			'Ethi' => 'Chữ Ethiopia',
 			'Geok' => 'Chữ Khutsuri Georgia',
 			'Geor' => 'Chữ Georgia',
 			'Glag' => 'Chữ Glagolitic',
 			'Goth' => 'Chữ Gô-tích',
 			'Gran' => 'Chữ Grantha',
 			'Grek' => 'Chữ Hy Lạp',
 			'Gujr' => 'Chữ Gujarati',
 			'Guru' => 'Chữ Gurmukhi',
 			'Hanb' => 'Chữ Hán có chú âm',
 			'Hang' => 'Chữ Hàn',
 			'Hani' => 'Chữ Hán',
 			'Hano' => 'Chữ Hanunoo',
 			'Hans' => 'Giản thể',
 			'Hans@alt=stand-alone' => 'Chữ Hán giản thể',
 			'Hant' => 'Phồn thể',
 			'Hant@alt=stand-alone' => 'Chữ Hán phồn thể',
 			'Hebr' => 'Chữ Do Thái',
 			'Hira' => 'Chữ Hiragana',
 			'Hluw' => 'Chữ tượng hình Anatolia',
 			'Hmng' => 'Chữ Pahawh Hmong',
 			'Hrkt' => 'Bảng ký hiệu âm tiết Tiếng Nhật',
 			'Hung' => 'Chữ Hungary cổ',
 			'Inds' => 'Chữ Indus',
 			'Ital' => 'Chữ Italic cổ',
 			'Jamo' => 'Chữ Jamo',
 			'Java' => 'Chữ Java',
 			'Jpan' => 'Chữ Nhật Bản',
 			'Jurc' => 'Chữ Jurchen',
 			'Kali' => 'Chữ Kayah Li',
 			'Kana' => 'Chữ Katakana',
 			'Khar' => 'Chữ Kharoshthi',
 			'Khmr' => 'Chữ Khơ-me',
 			'Khoj' => 'Chữ Khojki',
 			'Knda' => 'Chữ Kannada',
 			'Kore' => 'Chữ Hàn Quốc',
 			'Kpel' => 'Chữ Kpelle',
 			'Kthi' => 'Chữ Kaithi',
 			'Lana' => 'Chữ Lanna',
 			'Laoo' => 'Chữ Lào',
 			'Latf' => 'Chữ La-tinh Fraktur',
 			'Latg' => 'Chữ La-tinh Xcốt-len',
 			'Latn' => 'Chữ La tinh',
 			'Lepc' => 'Chữ Lepcha',
 			'Limb' => 'Chữ Limbu',
 			'Lina' => 'Chữ Linear A',
 			'Linb' => 'Chữ Linear B',
 			'Lisu' => 'Chữ Fraser',
 			'Loma' => 'Chữ Loma',
 			'Lyci' => 'Chữ Lycia',
 			'Lydi' => 'Chữ Lydia',
 			'Mand' => 'Chữ Mandaean',
 			'Mani' => 'Chữ Manichaean',
 			'Maya' => 'Chữ tượng hình Maya',
 			'Mend' => 'Chữ Mende',
 			'Merc' => 'Chữ Meroitic Nét thảo',
 			'Mero' => 'Chữ Meroitic',
 			'Mlym' => 'Chữ Malayalam',
 			'Mong' => 'Chữ Mông Cổ',
 			'Moon' => 'Chữ nổi Moon',
 			'Mroo' => 'Chữ Mro',
 			'Mtei' => 'Chữ Meitei Mayek',
 			'Mymr' => 'Chữ Myanmar',
 			'Narb' => 'Chữ Bắc Ả Rập cổ',
 			'Nbat' => 'Chữ Nabataean',
 			'Nkgb' => 'Chữ Naxi Geba',
 			'Nkoo' => 'Chữ N’Ko',
 			'Nshu' => 'Chữ Nüshu',
 			'Ogam' => 'Chữ Ogham',
 			'Olck' => 'Chữ Ol Chiki',
 			'Orkh' => 'Chữ Orkhon',
 			'Orya' => 'Chữ Odia',
 			'Osma' => 'Chữ Osmanya',
 			'Palm' => 'Chữ Palmyrene',
 			'Perm' => 'Chữ Permic cổ',
 			'Phag' => 'Chữ Phags-pa',
 			'Phli' => 'Chữ Pahlavi Văn bia',
 			'Phlp' => 'Chữ Pahlavi Thánh ca',
 			'Phlv' => 'Chữ Pahlavi Sách',
 			'Phnx' => 'Chữ Phoenicia',
 			'Plrd' => 'Ngữ âm Pollard',
 			'Prti' => 'Chữ Parthia Văn bia',
 			'Qaag' => 'Chữ Zawgyi',
 			'Rjng' => 'Chữ Rejang',
 			'Rohg' => 'Chữ Hanifi',
 			'Roro' => 'Chữ Rongorongo',
 			'Runr' => 'Chữ Runic',
 			'Samr' => 'Chữ Samaritan',
 			'Sara' => 'Chữ Sarati',
 			'Sarb' => 'Chữ Nam Ả Rập cổ',
 			'Saur' => 'Chữ Saurashtra',
 			'Sgnw' => 'Chữ viết Ký hiệu',
 			'Shaw' => 'Chữ Shavian',
 			'Shrd' => 'Chữ Sharada',
 			'Sind' => 'Chữ Khudawadi',
 			'Sinh' => 'Chữ Sinhala',
 			'Sora' => 'Chữ Sora Sompeng',
 			'Sund' => 'Chữ Xu-đăng',
 			'Sylo' => 'Chữ Syloti Nagri',
 			'Syrc' => 'Chữ Syria',
 			'Syre' => 'Chữ Estrangelo Syriac',
 			'Syrj' => 'Chữ Tây Syria',
 			'Syrn' => 'Chữ Đông Syria',
 			'Tagb' => 'Chữ Tagbanwa',
 			'Takr' => 'Chữ Takri',
 			'Tale' => 'Chữ Thái Na',
 			'Talu' => 'Chữ Thái Lặc mới',
 			'Taml' => 'Chữ Tamil',
 			'Tang' => 'Chữ Tangut',
 			'Tavt' => 'Chữ Thái Việt',
 			'Telu' => 'Chữ Telugu',
 			'Teng' => 'Chữ Tengwar',
 			'Tfng' => 'Chữ Tifinagh',
 			'Tglg' => 'Chữ Tagalog',
 			'Thaa' => 'Chữ Thaana',
 			'Thai' => 'Chữ Thái',
 			'Tibt' => 'Chữ Tây Tạng',
 			'Tirh' => 'Chữ Tirhuta',
 			'Ugar' => 'Chữ Ugarit',
 			'Vaii' => 'Chữ Vai',
 			'Visp' => 'Tiếng nói Nhìn thấy được',
 			'Wara' => 'Chữ Varang Kshiti',
 			'Wole' => 'Chữ Woleai',
 			'Xpeo' => 'Chữ Ba Tư cổ',
 			'Xsux' => 'Chữ hình nêm Sumero-Akkadian',
 			'Yiii' => 'Chữ Di',
 			'Zinh' => 'Chữ Kế thừa',
 			'Zmth' => 'Ký hiệu Toán học',
 			'Zsye' => 'Biểu tượng',
 			'Zsym' => 'Ký hiệu',
 			'Zxxx' => 'Chưa có chữ viết',
 			'Zyyy' => 'Chung',
 			'Zzzz' => 'Chữ viết không xác định',

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
			'001' => 'Thế giới',
 			'002' => 'Châu Phi',
 			'003' => 'Bắc Mỹ',
 			'005' => 'Nam Mỹ',
 			'009' => 'Châu Đại Dương',
 			'011' => 'Tây Phi',
 			'013' => 'Trung Mỹ',
 			'014' => 'Đông Phi',
 			'015' => 'Bắc Phi',
 			'017' => 'Trung Phi',
 			'018' => 'Miền Nam Châu Phi',
 			'019' => 'Châu Mỹ',
 			'021' => 'Miền Bắc Châu Mỹ',
 			'029' => 'Ca-ri-bê',
 			'030' => 'Đông Á',
 			'034' => 'Nam Á',
 			'035' => 'Đông Nam Á',
 			'039' => 'Nam Âu',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Vùng Micronesia',
 			'061' => 'Polynesia',
 			'142' => 'Châu Á',
 			'143' => 'Trung Á',
 			'145' => 'Tây Á',
 			'150' => 'Châu Âu',
 			'151' => 'Đông Âu',
 			'154' => 'Bắc Âu',
 			'155' => 'Tây Âu',
 			'202' => 'Châu Phi hạ Sahara',
 			'419' => 'Châu Mỹ La-tinh',
 			'AC' => 'Đảo Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Các Tiểu Vương quốc Ả Rập Thống nhất',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua và Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Nam Cực',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa thuộc Mỹ',
 			'AT' => 'Áo',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Quần đảo Åland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia và Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bỉ',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Ca-ri-bê Hà Lan',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Đảo Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Quần đảo Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Cộng hòa Dân chủ Congo',
 			'CF' => 'Cộng hòa Trung Phi',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Cộng hòa Congo',
 			'CH' => 'Thụy Sĩ',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Bờ Biển Ngà',
 			'CK' => 'Quần đảo Cook',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'Trung Quốc',
 			'CO' => 'Colombia',
 			'CP' => 'Đảo Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Đảo Giáng Sinh',
 			'CY' => 'Síp',
 			'CZ' => 'Séc',
 			'CZ@alt=variant' => 'Cộng hòa Séc',
 			'DE' => 'Đức',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Đan Mạch',
 			'DM' => 'Dominica',
 			'DO' => 'Cộng hòa Dominica',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta và Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Ai Cập',
 			'EH' => 'Tây Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Tây Ban Nha',
 			'ET' => 'Ethiopia',
 			'EU' => 'Liên Minh Châu Âu',
 			'EZ' => 'Khu vực đồng Euro',
 			'FI' => 'Phần Lan',
 			'FJ' => 'Fiji',
 			'FK' => 'Quần đảo Falkland',
 			'FK@alt=variant' => 'Quần đảo Falkland (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Quần đảo Faroe',
 			'FR' => 'Pháp',
 			'GA' => 'Gabon',
 			'GB' => 'Vương quốc Anh',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guiana thuộc Pháp',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinea Xích Đạo',
 			'GR' => 'Hy Lạp',
 			'GS' => 'Nam Georgia & Quần đảo Nam Sandwich',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Đặc khu Hành chính Hồng Kông, Trung Quốc',
 			'HK@alt=short' => 'Hồng Kông',
 			'HM' => 'Quần đảo Heard và McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungary',
 			'IC' => 'Quần đảo Canary',
 			'ID' => 'Indonesia',
 			'IE' => 'Ireland',
 			'IL' => 'Israel',
 			'IM' => 'Đảo Man',
 			'IN' => 'Ấn Độ',
 			'IO' => 'Lãnh thổ Ấn Độ Dương thuộc Anh',
 			'IO@alt=chagos' => 'Quần đảo Chagos',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Italy',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Nhật Bản',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Campuchia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'St. Kitts và Nevis',
 			'KP' => 'Triều Tiên',
 			'KR' => 'Hàn Quốc',
 			'KW' => 'Kuwait',
 			'KY' => 'Quần đảo Cayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Lào',
 			'LB' => 'Li-băng',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litva',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Ma-rốc',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Quần đảo Marshall',
 			'MK' => 'Bắc Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Miến Điện)',
 			'MN' => 'Mông Cổ',
 			'MO' => 'Đặc khu Hành chính Macao, Trung Quốc',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Quần đảo Bắc Mariana',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Đảo Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Hà Lan',
 			'NO' => 'Na Uy',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polynesia thuộc Pháp',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Philippines',
 			'PK' => 'Pakistan',
 			'PL' => 'Ba Lan',
 			'PM' => 'Saint Pierre và Miquelon',
 			'PN' => 'Quần đảo Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Lãnh thổ Palestine',
 			'PS@alt=short' => 'Palestine',
 			'PT' => 'Bồ Đào Nha',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Vùng xa xôi thuộc Châu Đại Dương',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Nga',
 			'RW' => 'Rwanda',
 			'SA' => 'Ả Rập Xê-út',
 			'SB' => 'Quần đảo Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Thụy Điển',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard và Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Nam Sudan',
 			'ST' => 'São Tomé và Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Quần đảo Turks và Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Lãnh thổ phía Nam Thuộc Pháp',
 			'TG' => 'Togo',
 			'TH' => 'Thái Lan',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Đông Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Thổ Nhĩ Kỳ',
 			'TT' => 'Trinidad và Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Đài Loan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Các tiểu đảo xa của Hoa Kỳ',
 			'UN' => 'Liên hiệp quốc',
 			'US' => 'Hoa Kỳ',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Thành Vatican',
 			'VC' => 'St. Vincent và Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Quần đảo Virgin thuộc Anh',
 			'VI' => 'Quần đảo Virgin thuộc Hoa Kỳ',
 			'VN' => 'Việt Nam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis và Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-Accents',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Nam Phi',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Vùng không xác định',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Phép chính tả Tiếng Đức Truyền thống',
 			'1994' => 'Phép chính tả Resian Chuẩn hóa',
 			'1996' => 'Phép chính tả Tiếng Đức năm 1996',
 			'1606NICT' => 'Tiếng Pháp từ Cuối thời Trung cổ đến 1606',
 			'1694ACAD' => 'Tiếng Pháp Hiện đại Thời kỳ đầu',
 			'1959ACAD' => 'Hàn lâm',
 			'ALALC97' => 'La Mã hóa ALA-LC, ấn bản năm 1997',
 			'ALUKU' => 'Phương ngữ Aluku',
 			'AREVELA' => 'Tiếng Armenia Miền Đông',
 			'AREVMDA' => 'Tiếng Armenia Miền Tây',
 			'BAKU1926' => 'Bảng chữ cái La-tinh Tiếng Turk Hợp nhất',
 			'BISKE' => 'Phương ngữ San Giorgio/Bila',
 			'BOHORIC' => 'Bảng chữ cái Bohorič',
 			'BOONT' => 'Tiếng Boontling',
 			'DAJNKO' => 'Bảng chữ cái Dajnko',
 			'EMODENG' => 'Tiếng Anh Hiện đại Thời kỳ đầu',
 			'FONIPA' => 'Ngữ âm học IPA',
 			'FONUPA' => 'Ngữ âm học UPA',
 			'HEPBURN' => 'La mã hóa Hepburn',
 			'KKCOR' => 'Phép chính tả Chung',
 			'KSCOR' => 'Phép chính tả Chuẩn',
 			'LIPAW' => 'Phương ngữ Lipovaz của người Resian',
 			'METELKO' => 'Bảng chữ cái Metelko',
 			'MONOTON' => 'Đơn âm',
 			'NDYUKA' => 'Phương ngữ Ndyuka',
 			'NEDIS' => 'Phương ngữ Natisone',
 			'NJIVA' => 'Phương ngữ Gniva/Njiva',
 			'NULIK' => 'Tiếng Volapük Hiện đại',
 			'OSOJS' => 'Phương ngữ Oseacco/Osojane',
 			'PAMAKA' => 'Phương ngữ Pamaka',
 			'PINYIN' => 'La Mã hóa Bính âm',
 			'POLYTON' => 'Đa âm',
 			'POSIX' => 'Máy tính',
 			'REVISED' => 'Phép chính tả Sửa đổi',
 			'RIGIK' => 'Tiếng Volapük Cổ điển',
 			'ROZAJ' => 'Tiếng Resian',
 			'SAAHO' => 'Tiếng Saho',
 			'SCOTLAND' => 'Tiếng Anh chuẩn tại Scotland',
 			'SCOUSE' => 'Phương ngữ Liverpool',
 			'SOLBA' => 'Phương ngữ Stolvizza/Solbica',
 			'TARASK' => 'Phép chính tả Taraskievica',
 			'UCCOR' => 'Phép chính tả Hợp nhất',
 			'UCRCOR' => 'Phép chính tả Sửa đổi Hợp nhất',
 			'VALENCIA' => 'Tiếng Valencia',
 			'WADEGILE' => 'La Mã hóa Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Lịch',
 			'cf' => 'Định dạng tiền tệ',
 			'colalternate' => 'Bỏ qua sắp xếp biểu tượng',
 			'colbackwards' => 'Sắp xếp dấu trọng âm đảo ngược',
 			'colcasefirst' => 'Sắp xếp chữ hoa/chữ thường',
 			'colcaselevel' => 'Sắp xếp phân biệt chữ hoa/chữ thường',
 			'collation' => 'Thứ tự sắp xếp',
 			'colnormalization' => 'Sắp xếp theo chuẩn hóa',
 			'colnumeric' => 'Sắp xếp theo số',
 			'colstrength' => 'Cường độ sắp xếp',
 			'currency' => 'Tiền tệ',
 			'hc' => 'Chu kỳ giờ (12 với 24)',
 			'lb' => 'Kiểu xuống dòng',
 			'ms' => 'Hệ thống đo lường',
 			'numbers' => 'Số',
 			'timezone' => 'Múi giờ',
 			'va' => 'Biến thể ngôn ngữ',
 			'x' => 'Sử dụng cá nhân',

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
 				'buddhist' => q{Lịch Phật Giáo},
 				'chinese' => q{Lịch Trung Quốc},
 				'coptic' => q{Lịch Copts},
 				'dangi' => q{Lịch Dangi},
 				'ethiopic' => q{Lịch Ethiopia},
 				'ethiopic-amete-alem' => q{Lịch Ethiopic Amete Alem},
 				'gregorian' => q{Lịch Gregory},
 				'hebrew' => q{Lịch Do Thái},
 				'indian' => q{Lịch Quốc gia Ấn Độ},
 				'islamic' => q{Lịch Hồi Giáo},
 				'islamic-civil' => q{Lịch Hồi Giáo (dạng bảng, kỷ nguyên dân sự)},
 				'islamic-rgsa' => q{Lịch Hồi Giáo - Ả Rập Xê-út},
 				'islamic-tbla' => q{Lịch Hồi Giáo - Thiên văn},
 				'islamic-umalqura' => q{Lịch Hồi Giáo (Umm al-Qura)},
 				'iso8601' => q{Lịch ISO-8601},
 				'japanese' => q{Lịch Nhật Bản},
 				'persian' => q{Lịch Ba Tư},
 				'roc' => q{Lịch Trung Hoa Dân Quốc},
 			},
 			'cf' => {
 				'account' => q{Định dạng tiền tệ kế toán},
 				'standard' => q{Định dạng tiền tệ chuẩn},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sắp xếp biểu tượng},
 				'shifted' => q{Sắp xếp biểu tượng bỏ qua},
 			},
 			'colbackwards' => {
 				'no' => q{Sắp xếp dấu trọng âm bình thường},
 				'yes' => q{Sắp xếp dấu trọng âm đảo ngược},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sắp xếp chữ thường đầu tiên},
 				'no' => q{Sắp xếp thứ tự chữ cái bình thường},
 				'upper' => q{Sắp xếp chữ hoa đầu tiên},
 			},
 			'colcaselevel' => {
 				'no' => q{Sắp xếp không phân biệt chữ hoa/chữ thường},
 				'yes' => q{Sắp xếp phân biệt chữ hoa/chữ thường},
 			},
 			'collation' => {
 				'big5han' => q{Thứ tự sắp xếp theo tiếng Trung phồn thể - Big5},
 				'compat' => q{Thứ tự sắp xếp trước đây, để tương thích},
 				'dictionary' => q{Thứ tự sắp xếp theo từ điển},
 				'ducet' => q{Thứ tự sắp xếp unicode mặc định},
 				'emoji' => q{Thứ tự sắp xếp biểu tượng},
 				'eor' => q{Quy tắc sắp xếp Châu Âu},
 				'gb2312han' => q{Thứ tự sắp xếp theo tiếng Trung giản thể - GB2312},
 				'phonebook' => q{Thứ tự sắp xếp theo danh bạ điện thoại},
 				'phonetic' => q{Thứ tự sắp xếp theo ngữ âm},
 				'pinyin' => q{Thứ tự sắp xếp theo bính âm},
 				'reformed' => q{Thứ tự sắp xếp đã sửa đổi},
 				'search' => q{Tìm kiếm mục đích chung},
 				'searchjl' => q{Tìm kiếm theo Phụ âm Đầu Hangul},
 				'standard' => q{Thứ tự sắp xếp chuẩn},
 				'stroke' => q{Thứ tự sắp xếp theo nét chữ},
 				'traditional' => q{Thứ tự sắp xếp truyền thống},
 				'unihan' => q{Trình tự sắp xếp theo bộ-nét},
 				'zhuyin' => q{Thứ tự sắp xếp theo chú âm phù hiệu},
 			},
 			'colnormalization' => {
 				'no' => q{Sắp xếp không theo chuẩn hóa},
 				'yes' => q{Sắp xếp unicode được chuẩn hóa},
 			},
 			'colnumeric' => {
 				'no' => q{Sắp xếp từng chữ số},
 				'yes' => q{Sắp xếp chữ số theo số},
 			},
 			'colstrength' => {
 				'identical' => q{Sắp xếp tất cả},
 				'primary' => q{Chỉ sắp xếp chữ cái cơ sở},
 				'quaternary' => q{Sắp xếp dấu trọng âm/chữ cái/độ rộng/chữ Kana},
 				'secondary' => q{Sắp xếp dấu trọng âm},
 				'tertiary' => q{Sắp xếp dấu trọng âm/chữ cái/độ rộng},
 			},
 			'd0' => {
 				'fwidth' => q{Độ rộng tối đa},
 				'hwidth' => q{Nửa độ rộng},
 				'npinyin' => q{Số},
 			},
 			'hc' => {
 				'h11' => q{Hệ thống 12 giờ (0–11)},
 				'h12' => q{Hệ thống 12 giờ (1–12)},
 				'h23' => q{Hệ thống 24 giờ (0–23)},
 				'h24' => q{Hệ thống 24 giờ (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Kiểu xuống dòng thoáng},
 				'normal' => q{Kiểu xuống dòng thường},
 				'strict' => q{Kiểu xuống dòng hẹp},
 			},
 			'm0' => {
 				'bgn' => q{Chuyển tự US BGN},
 				'ungegn' => q{Chuyển tự UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{Hệ mét},
 				'uksystem' => q{Hệ đo lường Anh},
 				'ussystem' => q{Hệ đo lường Mỹ},
 			},
 			'numbers' => {
 				'ahom' => q{Chữ số Ahom},
 				'arab' => q{Chữ số Ả Rập - Ấn Độ},
 				'arabext' => q{Chữ số Ả Rập - Ấn Độ mở rộng},
 				'armn' => q{Chữ số Armenia},
 				'armnlow' => q{Chữ số Armenia viết thường},
 				'bali' => q{Chữ số Bali},
 				'beng' => q{Chữ số Bangladesh},
 				'brah' => q{Chữ số Brahmi},
 				'cakm' => q{Chữ số Chakma},
 				'cham' => q{Chữ số Chăm},
 				'cyrl' => q{Số Kirin},
 				'deva' => q{Chữ số Devanagari},
 				'ethi' => q{Chữ số Ethiopia},
 				'finance' => q{Chữ số dùng trong tài chính},
 				'fullwide' => q{Chữ số có độ rộng đầy đủ},
 				'geor' => q{Chữ số Georgia},
 				'gong' => q{Chữ số Gong},
 				'gonm' => q{Chữ số Gonm},
 				'grek' => q{Chữ số Hy Lạp},
 				'greklow' => q{Chữ số Hy Lạp viết thường},
 				'gujr' => q{Chữ số Gujarati},
 				'guru' => q{Chữ số Gurmukhi},
 				'hanidec' => q{Chữ số thập phân Trung Quốc},
 				'hans' => q{Chữ số của tiếng Trung giản thể},
 				'hansfin' => q{Chữ số dùng trong tài chính của tiếng Trung giản thể},
 				'hant' => q{Chữ số tiếng Trung phồn thể},
 				'hantfin' => q{Chữ số dùng trong tài chính của tiếng Trung phồn thể},
 				'hebr' => q{Chữ số Do Thái},
 				'hmng' => q{Chữ số Hmng},
 				'hmnp' => q{Chữ số Hmnp},
 				'java' => q{Chữ số Java},
 				'jpan' => q{Chữ số Nhật Bản},
 				'jpanfin' => q{Chữ số dùng trong tài chính của tiếng Nhật},
 				'kali' => q{Chữ số Kayah Li},
 				'khmr' => q{Chữ số Khơ-me},
 				'knda' => q{Chữ số Kannada},
 				'lana' => q{Chữ số Hora Thái Đam},
 				'lanatham' => q{Chữ số Tham Thái Đam},
 				'laoo' => q{Chữ số Lào},
 				'latn' => q{Chữ số phương Tây},
 				'lepc' => q{Chữ số Lepcha},
 				'limb' => q{Chữ số Limbu},
 				'mathbold' => q{Chữ số Mathbold},
 				'mathdbl' => q{Chữ số Mathdbl},
 				'mathmono' => q{Chữ số Mathmono},
 				'mathsanb' => q{Chữ số Mathsanb},
 				'mathsans' => q{Chữ số Mathsans},
 				'mlym' => q{Chữ số Malayalam},
 				'modi' => q{Chữ số Modi},
 				'mong' => q{Chữ số Mông Cổ},
 				'mroo' => q{Chữ số Mroo},
 				'mtei' => q{Chữ số Meetei Mayek},
 				'mymr' => q{Chữ số Myanma},
 				'mymrshan' => q{Chữ số Myanmar Shan},
 				'mymrtlng' => q{Chữ số Mymrtlng},
 				'native' => q{Chữ số tự nhiên},
 				'nkoo' => q{Chữ số N’Ko},
 				'olck' => q{Chữ số Ol Chiki},
 				'orya' => q{Chữ số Odia},
 				'osma' => q{Chữ số Osmanya},
 				'rohg' => q{Chữ số Rohg},
 				'roman' => q{Chữ số La mã},
 				'romanlow' => q{Chữ số La Mã viết thường},
 				'saur' => q{Chữ số Saurashtra},
 				'shrd' => q{Chữ số Sharada},
 				'sind' => q{Chữ số Sind},
 				'sinh' => q{Chữ số Sinh},
 				'sora' => q{Chữ số Sora Sompeng},
 				'sund' => q{Chữ số Sudan},
 				'takr' => q{Chữ số Takri},
 				'talu' => q{Chữ số Thái Lặc mới},
 				'taml' => q{Chữ số Tamil Truyền thống},
 				'tamldec' => q{Chữ số Tamil},
 				'telu' => q{Chữ số Telugu},
 				'thai' => q{Chữ số Thái},
 				'tibt' => q{Chữ số Tây Tạng},
 				'tirh' => q{Chữ số Tirh},
 				'traditional' => q{Số truyền thống},
 				'vaii' => q{Chữ số Vai},
 				'wara' => q{Chữ số Wara},
 				'wcho' => q{Chữ số Wancho},
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
			'metric' => q{Hệ mét},
 			'UK' => q{Hệ Anh},
 			'US' => q{Hệ Mỹ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Ngôn ngữ: {0}',
 			'script' => 'Chữ viết: {0}',
 			'region' => 'Vùng: {0}',

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
			auxiliary => qr{[f j w z]},
			index => ['A', 'Ă', 'Â', 'B', 'C', 'D', 'Đ', 'E', 'Ê', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Ô', 'Ơ', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ư', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aàảãáạ ăằẳẵắặ âầẩẫấậ b c d đ eèẻẽéẹ êềểễếệ g h iìỉĩíị k l m n oòỏõóọ ôồổỗốộ ơờởỡớợ p q r s t uùủũúụ ưừửữứự v x yỳỷỹýỵ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Ă', 'Â', 'B', 'C', 'D', 'Đ', 'E', 'Ê', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Ô', 'Ơ', 'P', 'Q', 'R', 'S', 'T', 'U', 'Ư', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(phương trời),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(phương trời),
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
						'1' => q(đềxi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(đềxi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(picô{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(picô{0}),
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
						'1' => q(xenti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(xenti{0}),
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
						'1' => q(micrô{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micrô{0}),
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
						'1' => q(kilô{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilô{0}),
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
						'other' => q({0} lực g),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} lực g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mét/giây bình phương),
						'other' => q({0} mét/giây bình phương),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mét/giây bình phương),
						'other' => q({0} mét/giây bình phương),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'other' => q({0} phút),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'other' => q({0} phút),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'other' => q({0} giây),
					},
					# Core Unit Identifier
					'arc-second' => {
						'other' => q({0} giây),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0} độ),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0} độ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(héc-ta),
						'other' => q({0} héc-ta),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(héc-ta),
						'other' => q({0} héc-ta),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(xentimét vuông),
						'other' => q({0} xentimét vuông),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(xentimét vuông),
						'other' => q({0} xentimét vuông),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(feet vuông),
						'other' => q({0} feet vuông),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(feet vuông),
						'other' => q({0} feet vuông),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inch vuông),
						'other' => q({0} inch vuông),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inch vuông),
						'other' => q({0} inch vuông),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilômét vuông),
						'other' => q({0} kilômét vuông),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilômét vuông),
						'other' => q({0} kilômét vuông),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mét vuông),
						'other' => q({0} mét vuông),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mét vuông),
						'other' => q({0} mét vuông),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(dặm vuông),
						'other' => q({0} dặm vuông),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(dặm vuông),
						'other' => q({0} dặm vuông),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard vuông),
						'other' => q({0} yard vuông),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard vuông),
						'other' => q({0} yard vuông),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(carat),
						'other' => q({0} carat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(carat),
						'other' => q({0} carat),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q({0} phần vạn),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q({0} phần vạn),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(lít/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(lít/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lít/km),
						'other' => q({0} lít/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lít/km),
						'other' => q({0} lít/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(dặm/gallon),
						'other' => q({0} dặm/gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(dặm/gallon),
						'other' => q({0} dặm/gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(dặm/galông Anh),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(dặm/galông Anh),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Đông),
						'north' => q({0} Bắc),
						'south' => q({0} Nam),
						'west' => q({0} Tây),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Đông),
						'north' => q({0} Bắc),
						'south' => q({0} Nam),
						'west' => q({0} Tây),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte),
						'other' => q({0} gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobyte),
						'other' => q({0} kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampe),
						'other' => q({0} ampe),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampe),
						'other' => q({0} ampe),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mili ampe),
						'other' => q({0} mili ampe),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mili ampe),
						'other' => q({0} mili ampe),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ôm),
						'other' => q({0} ôm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ôm),
						'other' => q({0} ôm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(vôn),
						'other' => q({0} vôn),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(vôn),
						'other' => q({0} vôn),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(đơn vị nhiệt Anh),
						'other' => q({0} đơn vị nhiệt Anh),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(đơn vị nhiệt Anh),
						'other' => q({0} đơn vị nhiệt Anh),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calo),
						'other' => q({0} calo),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calo),
						'other' => q({0} calo),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q({0} electronvôn),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q({0} electronvôn),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Calo),
						'other' => q({0} Calo),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Calo),
						'other' => q({0} Calo),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jun),
						'other' => q({0} jun),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jun),
						'other' => q({0} jun),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilôcalo),
						'other' => q({0} kilôcalo),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilôcalo),
						'other' => q({0} kilôcalo),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilô jun),
						'other' => q({0} kilô jun),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilô jun),
						'other' => q({0} kilô jun),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilôoát giờ),
						'other' => q({0} kilôoát giờ),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilôoát giờ),
						'other' => q({0} kilôoát giờ),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(đơn vị nhiệt Mỹ),
						'other' => q({0} đơn vị nhiệt Mỹ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(đơn vị nhiệt Mỹ),
						'other' => q({0} đơn vị nhiệt Mỹ),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound lực),
						'other' => q({0} pound lực),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound lực),
						'other' => q({0} pound lực),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(chấm/xentimét),
						'other' => q({0} chấm/xentimét),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(chấm/xentimét),
						'other' => q({0} chấm/xentimét),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(chấm/inch),
						'other' => q({0} chấm/inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(chấm/inch),
						'other' => q({0} chấm/inch),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0} megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0} megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixel/xentimét),
						'other' => q({0} pixel/xentimét),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixel/xentimét),
						'other' => q({0} pixel/xentimét),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(đơn vị thiên văn),
						'other' => q({0} đơn vị thiên văn),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(đơn vị thiên văn),
						'other' => q({0} đơn vị thiên văn),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(xentimét),
						'other' => q({0} xentimét),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(xentimét),
						'other' => q({0} xentimét),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(đềximét),
						'other' => q({0} đềximét),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(đềximét),
						'other' => q({0} đềximét),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(bán kính trái đất),
						'other' => q({0} bán kính trái đất),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(bán kính trái đất),
						'other' => q({0} bán kính trái đất),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(sải),
						'other' => q({0} sải),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(sải),
						'other' => q({0} sải),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(feet),
						'other' => q({0} feet),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(feet),
						'other' => q({0} feet),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fulông),
						'other' => q({0} fulông),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fulông),
						'other' => q({0} fulông),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0}/inch),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0}/inch),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilômét),
						'other' => q({0} kilômét),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilômét),
						'other' => q({0} kilômét),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(năm ánh sáng),
						'other' => q({0} năm ánh sáng),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(năm ánh sáng),
						'other' => q({0} năm ánh sáng),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mét),
						'other' => q({0} mét),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mét),
						'other' => q({0} mét),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrômét),
						'other' => q({0} micrômét),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrômét),
						'other' => q({0} micrômét),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(dặm scandinavia),
						'other' => q({0} dặm scandinavia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(dặm scandinavia),
						'other' => q({0} dặm scandinavia),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimét),
						'other' => q({0} milimét),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimét),
						'other' => q({0} milimét),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomét),
						'other' => q({0} nanomét),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomét),
						'other' => q({0} nanomét),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(hải lý),
						'other' => q({0} hải lý),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(hải lý),
						'other' => q({0} hải lý),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picômét),
						'other' => q({0} picômét),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picômét),
						'other' => q({0} picômét),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(điểm),
						'other' => q({0} điểm),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(điểm),
						'other' => q({0} điểm),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} bán kính mặt trời),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} bán kính mặt trời),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0} độ sáng của mặt trời),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0} độ sáng của mặt trời),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(carat),
						'other' => q({0} carat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(carat),
						'other' => q({0} carat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'other' => q({0} trọng lượng trái đất),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'other' => q({0} trọng lượng trái đất),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gam),
						'other' => q({0} gam),
						'per' => q({0}/gam),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gam),
						'other' => q({0} gam),
						'per' => q({0}/gam),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilôgam),
						'other' => q({0} kilôgam),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilôgam),
						'other' => q({0} kilôgam),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(micrôgam),
						'other' => q({0} micrôgam),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(micrôgam),
						'other' => q({0} micrôgam),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligam),
						'other' => q({0} miligam),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligam),
						'other' => q({0} miligam),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(aoxơ),
						'other' => q({0} aoxơ),
						'per' => q({0}/aoxơ),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(aoxơ),
						'other' => q({0} aoxơ),
						'per' => q({0}/aoxơ),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troi aoxơ),
						'other' => q({0} troi aoxơ),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troi aoxơ),
						'other' => q({0} troi aoxơ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} pao),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} pao),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'other' => q({0} trọng lượng mặt trời),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'other' => q({0} trọng lượng mặt trời),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tấn),
						'other' => q({0} tấn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tấn),
						'other' => q({0} tấn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tấn hệ mét),
						'other' => q({0} tấn hệ mét),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tấn hệ mét),
						'other' => q({0} tấn hệ mét),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigaoát),
						'other' => q({0} gigaoát),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigaoát),
						'other' => q({0} gigaoát),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(mã lực),
						'other' => q({0} mã lực),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(mã lực),
						'other' => q({0} mã lực),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilôoát),
						'other' => q({0} kilôoát),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilôoát),
						'other' => q({0} kilôoát),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(Megaoát),
						'other' => q({0} Megaoát),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(Megaoát),
						'other' => q({0} Megaoát),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milioát),
						'other' => q({0} milioát),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milioát),
						'other' => q({0} milioát),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(oát),
						'other' => q({0} oát),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(oát),
						'other' => q({0} oát),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} vuông),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} vuông),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} khối),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} khối),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(átmốtphe),
						'other' => q({0} átmốtphe),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(átmốtphe),
						'other' => q({0} átmốtphe),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(héctô pascal),
						'other' => q({0} héctô pascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(héctô pascal),
						'other' => q({0} héctô pascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inch thủy ngân),
						'other' => q({0} inch thủy ngân),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inch thủy ngân),
						'other' => q({0} inch thủy ngân),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilô pascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilô pascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(mêga pascal),
						'other' => q({0} mêga pascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(mêga pascal),
						'other' => q({0} mêga pascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimét thủy ngân),
						'other' => q({0} milimét thủy ngân),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimét thủy ngân),
						'other' => q({0} milimét thủy ngân),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pound/inch vuông),
						'other' => q({0} pound/inch vuông),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pound/inch vuông),
						'other' => q({0} pound/inch vuông),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilômét/giờ),
						'other' => q({0} kilômét/giờ),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilômét/giờ),
						'other' => q({0} kilômét/giờ),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(hải lý/giờ),
						'other' => q({0} hải lý/giờ),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(hải lý/giờ),
						'other' => q({0} hải lý/giờ),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mét/giây),
						'other' => q({0} mét/giây),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mét/giây),
						'other' => q({0} mét/giây),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(dặm/giờ),
						'other' => q({0} dặm/giờ),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(dặm/giờ),
						'other' => q({0} dặm/giờ),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(độ C),
						'other' => q({0} độ C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(độ C),
						'other' => q({0} độ C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(độ F),
						'other' => q({0} độ F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(độ F),
						'other' => q({0} độ F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(độ),
						'other' => q({0} độ),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(độ),
						'other' => q({0} độ),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(độ K),
						'other' => q({0} độ K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(độ K),
						'other' => q({0} độ K),
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
						'name' => q(newton-mét),
						'other' => q({0} newton-mét),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-mét),
						'other' => q({0} newton-mét),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'other' => q({0} pound-feet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'other' => q({0} pound-feet),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(xentilít),
						'other' => q({0} xentilít),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(xentilít),
						'other' => q({0} xentilít),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(xentimét khối),
						'other' => q({0} xentimét khối),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(xentimét khối),
						'other' => q({0} xentimét khối),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(foot khối),
						'other' => q({0} foot khối),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(foot khối),
						'other' => q({0} foot khối),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inch khối),
						'other' => q({0} inch khối),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inch khối),
						'other' => q({0} inch khối),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilômét khối),
						'other' => q({0} kilômét khối),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilômét khối),
						'other' => q({0} kilômét khối),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mét khối),
						'other' => q({0} mét khối),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mét khối),
						'other' => q({0} mét khối),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(dặm khối),
						'other' => q({0} dặm khối),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(dặm khối),
						'other' => q({0} dặm khối),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard khối),
						'other' => q({0} yard khối),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard khối),
						'other' => q({0} yard khối),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cup khối),
						'other' => q({0} cup khối),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cup khối),
						'other' => q({0} cup khối),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(đềxilít),
						'other' => q({0} đềxilít),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(đềxilít),
						'other' => q({0} đềxilít),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(aoxơ chất lỏng),
						'other' => q({0} aoxơ chất lỏng),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(aoxơ chất lỏng),
						'other' => q({0} aoxơ chất lỏng),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Aoxơ chất lỏng theo hệ đo lường Anh),
						'other' => q({0} Aoxơ chất lỏng theo hệ đo lường Anh),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Aoxơ chất lỏng theo hệ đo lường Anh),
						'other' => q({0} Aoxơ chất lỏng theo hệ đo lường Anh),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gallon Anh),
						'other' => q({0} gallon Anh),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gallon Anh),
						'other' => q({0} gallon Anh),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectôlít),
						'other' => q({0} hectôlít),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectôlít),
						'other' => q({0} hectôlít),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lít),
						'other' => q({0} lít),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lít),
						'other' => q({0} lít),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalít),
						'other' => q({0} megalít),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalít),
						'other' => q({0} megalít),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililít),
						'other' => q({0} mililít),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililít),
						'other' => q({0} mililít),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(panh),
						'other' => q({0} panh),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(panh),
						'other' => q({0} panh),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(panh khối),
						'other' => q({0} panh khối),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(panh khối),
						'other' => q({0} panh khối),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quart),
						'other' => q({0} quart),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0}ha),
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
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0}miligiây),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0}miligiây),
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
					'force-newton' => {
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
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
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q({0}'),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q({0}'),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0}"),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0}"),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'other' => q({0}pm),
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
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'other' => q({0}yd),
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
					'mass-dalton' => {
						'name' => q(Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'other' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'other' => q({0}" Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'other' => q({0}" Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'other' => q({0} fl ozIm),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'other' => q({0} fl ozIm),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0}L),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0}L),
						'per' => q({0}/l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(hướng),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(hướng),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(lực g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(lực g),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(phút),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(phút),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(giây),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(giây),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(độ),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(độ),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(vòng),
						'other' => q({0} vòng),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(vòng),
						'other' => q({0} vòng),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(mẫu),
						'other' => q({0} mẫu),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(mẫu),
						'other' => q({0} mẫu),
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
						'name' => q(mục),
						'other' => q({0} mục),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(mục),
						'other' => q({0} mục),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(phần vạn),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(phần vạn),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Đ),
						'north' => q({0}B),
						'south' => q({0}N),
						'west' => q({0}T),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Đ),
						'north' => q({0}B),
						'south' => q({0}N),
						'west' => q({0}T),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(thế kỷ),
						'other' => q({0} thế kỷ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(thế kỷ),
						'other' => q({0} thế kỷ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ngày),
						'other' => q({0} ngày),
						'per' => q({0}/ngày),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ngày),
						'other' => q({0} ngày),
						'per' => q({0}/ngày),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(thập kỷ),
						'other' => q({0} thập kỷ),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(thập kỷ),
						'other' => q({0} thập kỷ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(giờ),
						'other' => q({0} giờ),
						'per' => q({0}/giờ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(giờ),
						'other' => q({0} giờ),
						'per' => q({0}/giờ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(micrô giây),
						'other' => q({0} micrô giây),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(micrô giây),
						'other' => q({0} micrô giây),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mili giây),
						'other' => q({0} mili giây),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mili giây),
						'other' => q({0} mili giây),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(phút),
						'other' => q({0} phút),
						'per' => q({0}/phút),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(phút),
						'other' => q({0} phút),
						'per' => q({0}/phút),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(tháng),
						'other' => q({0} tháng),
						'per' => q({0}/tháng),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(tháng),
						'other' => q({0} tháng),
						'per' => q({0}/tháng),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nano giây),
						'other' => q({0} nano giây),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nano giây),
						'other' => q({0} nano giây),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(quý),
						'other' => q({0} quý),
						'per' => q({0}/quý),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(quý),
						'other' => q({0} quý),
						'per' => q({0}/quý),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(giây),
						'other' => q({0} giây),
						'per' => q({0}/giây),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(giây),
						'other' => q({0} giây),
						'per' => q({0}/giây),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(tuần),
						'other' => q({0} tuần),
						'per' => q({0}/tuần),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(tuần),
						'other' => q({0} tuần),
						'per' => q({0}/tuần),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(năm),
						'other' => q({0} năm),
						'per' => q({0}/năm),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(năm),
						'other' => q({0} năm),
						'per' => q({0}/năm),
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
						'name' => q(v),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(v),
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
						'name' => q(electronvôn),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvôn),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
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
						'name' => q(therm Mỹ),
						'other' => q({0} therm Mỹ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therm Mỹ),
						'other' => q({0} therm Mỹ),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound-lực),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound-lực),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(chấm),
						'other' => q({0} chấm),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(chấm),
						'other' => q({0} chấm),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel),
						'other' => q({0} pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel),
						'other' => q({0} pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixel/cm),
						'other' => q({0} pixel/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixel/cm),
						'other' => q({0} pixel/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixel/inch),
						'other' => q({0} pixel/inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixel/inch),
						'other' => q({0} pixel/inch),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inch),
						'other' => q({0} inch),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inch),
						'other' => q({0} inch),
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
						'name' => q(dặm),
						'other' => q({0} dặm),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(dặm),
						'other' => q({0} dặm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(đ),
						'other' => q({0} đ),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(đ),
						'other' => q({0} đ),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(bán kính mặt trời),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(bán kính mặt trời),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(độ sáng của mặt trời),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(độ sáng của mặt trời),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(cara),
						'other' => q({0} CT),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(cara),
						'other' => q({0} CT),
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
						'name' => q(Trọng lượng trái đất),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Trọng lượng trái đất),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gren),
						'other' => q({0} gren),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gren),
						'other' => q({0} gren),
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
					'mass-ounce-troy' => {
						'name' => q(ozt),
						'other' => q({0} ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ozt),
						'other' => q({0} ozt),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pao),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pao),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(trọng lượng mặt trời),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(trọng lượng mặt trời),
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
					'speed-mile-per-hour' => {
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(thùng),
						'other' => q({0} thùng),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(thùng),
						'other' => q({0} thùng),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tách),
						'other' => q({0} tách),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tách),
						'other' => q({0} tách),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(thìa tráng miệng),
						'other' => q({0} thìa tráng miệng),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(thìa tráng miệng),
						'other' => q({0} thìa tráng miệng),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(thìa tráng miệng Anh),
						'other' => q({0} thìa tráng miệng Anh),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(thìa tráng miệng Anh),
						'other' => q({0} thìa tráng miệng Anh),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram chất lỏng),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram chất lỏng),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(giọt),
						'other' => q({0} giọt),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(giọt),
						'other' => q({0} giọt),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz Anh),
						'other' => q({0} fl oz Anh),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz Anh),
						'other' => q({0} fl oz Anh),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal Mỹ),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal Mỹ),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal Anh),
						'other' => q({0} gal Anh),
						'per' => q({0}/gal Anh),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal Anh),
						'other' => q({0} gal Anh),
						'per' => q({0}/gal Anh),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(nhúm),
						'other' => q({0} nhúm),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(nhúm),
						'other' => q({0} nhúm),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(lít Anh),
						'other' => q({0} lít Anh),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(lít Anh),
						'other' => q({0} lít Anh),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(muỗng canh),
						'other' => q({0} muỗng canh),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(muỗng canh),
						'other' => q({0} muỗng canh),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(muỗng cà phê),
						'other' => q({0} muỗng cà phê),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(muỗng cà phê),
						'other' => q({0} muỗng cà phê),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:có|c|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:không|k|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} và {1}),
				2 => q({0} và {1}),
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
					'other' => '0 nghìn',
				},
				'10000' => {
					'other' => '00 nghìn',
				},
				'100000' => {
					'other' => '000 nghìn',
				},
				'1000000' => {
					'other' => '0 triệu',
				},
				'10000000' => {
					'other' => '00 triệu',
				},
				'100000000' => {
					'other' => '000 triệu',
				},
				'1000000000' => {
					'other' => '0 tỷ',
				},
				'10000000000' => {
					'other' => '00 tỷ',
				},
				'100000000000' => {
					'other' => '000 tỷ',
				},
				'1000000000000' => {
					'other' => '0 nghìn tỷ',
				},
				'10000000000000' => {
					'other' => '00 nghìn tỷ',
				},
				'100000000000000' => {
					'other' => '000 nghìn tỷ',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0 N',
				},
				'10000' => {
					'other' => '00 N',
				},
				'100000' => {
					'other' => '000 N',
				},
				'1000000' => {
					'other' => '0 Tr',
				},
				'10000000' => {
					'other' => '00 Tr',
				},
				'100000000' => {
					'other' => '000 Tr',
				},
				'1000000000' => {
					'other' => '0 T',
				},
				'10000000000' => {
					'other' => '00 T',
				},
				'100000000000' => {
					'other' => '000 T',
				},
				'1000000000000' => {
					'other' => '0 NT',
				},
				'10000000000000' => {
					'other' => '00 NT',
				},
				'100000000000000' => {
					'other' => '000 NT',
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
						'negative' => '(#,##0.00)',
						'positive' => '#,##0.00',
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
				'currency' => q(Đồng Peseta của Andora),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Dirham UAE),
				'other' => q(dirham UAE),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Đồng Afghani của Afghanistan \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Afghanistan),
				'other' => q(afghani Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Albania),
				'other' => q(lek Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Armenia),
				'other' => q(dram Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder Antille Hà Lan),
				'other' => q(guilder Antille Hà Lan),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angola),
				'other' => q(kwanza Angola),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Đồng Kwanza của Angola \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Đồng Kwanza Mới của Angola \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Đồng Kwanza Điều chỉnh lại của Angola \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Đồng Austral của Argentina),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Đồng Peso Ley của Argentina \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Đồng Peso Argentina \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Đồng Peso Argentina \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argentina),
				'other' => q(peso Argentina),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Đồng Schiling Áo),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Đô la Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Đồng Manat của Azerbaijan \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaijan),
				'other' => q(manat Azerbaijan),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Đồng Dinar của Bosnia-Herzegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark Bosnia-Herzegovina có thể chuyển đổi),
				'other' => q(mark Bosnia-Herzegovina có thể chuyển đổi),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Đồng Dinar Mới của Bosnia-Herzegovina \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Đô la Barbados),
				'other' => q(đô la Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangladesh),
				'other' => q(taka Bangladesh),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Đồng Franc Bỉ \(có thể chuyển đổi\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Đồng Franc Bỉ),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Đồng Franc Bỉ \(tài chính\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Đồng Lev Xu của Bun-ga-ri),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Đồng Lev Xã hội chủ nghĩa của Bun-ga-ri),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bulgaria),
				'other' => q(lev Bulgaria),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Đồng Lev của Bun-ga-ri \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bahrain),
				'other' => q(dinar Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc Burundi),
				'other' => q(franc Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Đô la Bermuda),
				'other' => q(đô la Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Đô la Brunei),
				'other' => q(đô la Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Bolivia),
				'other' => q(boliviano Bolivia),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Đồng Boliviano của Bolivia \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Đồng Peso Bolivia),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Đồng Mvdol Bolivia),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Đồng Cruzerio Mới của Braxin \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Đồng Cruzado của Braxin \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Đồng Cruzerio của Braxin \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Braxin),
				'other' => q(real Braxin),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Đồng Cruzado Mới của Braxin \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Đồng Cruzeiro của Braxin \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Đồng Cruzeiro của Braxin \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Đô la Bahamas),
				'other' => q(đô la Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Bhutan),
				'other' => q(ngultrum Bhutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Đồng Kyat Miến Điện),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botswana),
				'other' => q(pula Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Đồng Rúp Mới của Belarus \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rúp Belarus),
				'other' => q(rúp Belarus),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rúp Belarus \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Đô la Belize),
				'other' => q(đô la Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Đô la Canada),
				'other' => q(đô la Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Congo),
				'other' => q(franc Congo),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Đồng Euro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Thụy sĩ),
				'other' => q(franc Thụy sĩ),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Đồng France WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Đồng Escudo của Chile),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Đơn vị Kế toán của Chile \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Chile),
				'other' => q(peso Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Nhân dân tệ \(hải ngoại\)),
				'other' => q(nhân dân tệ \(hải ngoại\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Nhân dân tệ),
				'other' => q(nhân dân tệ),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Colombia),
				'other' => q(peso Colombia),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Đơn vị Giá trị Thực của Colombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón Costa Rica),
				'other' => q(colón Costa Rica),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Đồng Dinar của Serbia \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Đồng Koruna Xu của Czechoslovakia),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Cuba có thể chuyển đổi),
				'other' => q(peso Cuba có thể chuyển đổi),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Cuba),
				'other' => q(peso Cuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Cape Verde),
				'other' => q(escudo Cape Verde),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Đồng Bảng Síp),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Cộng hòa Séc),
				'other' => q(koruna Cộng hòa Séc),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Đồng Mark Đông Đức),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Đồng Mark Đức),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Djibouti),
				'other' => q(franc Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Đan Mạch),
				'other' => q(krone Đan Mạch),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominica),
				'other' => q(peso Dominica),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Algeria),
				'other' => q(dinar Algeria),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Đồng Scure Ecuador),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Đơn vị Giá trị Không đổi của Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Crun Extônia),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Bảng Ai Cập),
				'other' => q(bảng Ai Cập),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritrea),
				'other' => q(nakfa Eritrea),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Đồng Peseta Tây Ban Nha \(Tài khoản\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Đồng Peseta Tây Ban Nha \(tài khoản có thể chuyển đổi\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Đồng Peseta Tây Ban Nha),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Ethiopia),
				'other' => q(birr Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Đồng Markka Phần Lan),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Đô la Fiji),
				'other' => q(đô la Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Bảng Quần đảo Falkland),
				'other' => q(bảng Quần đảo Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franc Pháp),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Bảng Anh),
				'other' => q(bảng Anh),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Đồng Kupon Larit của Georgia),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgia),
				'other' => q(lari Georgia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi Ghana \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghana),
				'other' => q(cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Bảng Gibraltar),
				'other' => q(bảng Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gambia),
				'other' => q(dalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc Guinea),
				'other' => q(franc Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli Guinea),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Đồng Ekwele của Guinea Xích Đạo),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drachma Hy Lạp),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemala),
				'other' => q(quetzal Guatemala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Đồng Guinea Escudo Bồ Đào Nha),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Peso Guinea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Đô la Guyana),
				'other' => q(đô la Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Đô la Hồng Kông),
				'other' => q(đô la Hồng Kông),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Honduras),
				'other' => q(lempira Honduras),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Đồng Dinar Croatia),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Croatia),
				'other' => q(kuna Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
				'other' => q(gourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint Hungary),
				'other' => q(forint Hungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah Indonesia),
				'other' => q(rupiah Indonesia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Pao Ai-len),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Pao Ixraen),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Sheqel Israel mới),
				'other' => q(sheqel Israel mới),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee Ấn Độ),
				'other' => q(rupee Ấn Độ),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Iraq),
				'other' => q(dinar Iraq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iran),
				'other' => q(rial Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Króna Iceland),
				'other' => q(króna Iceland),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lia Ý),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Đô la Jamaica),
				'other' => q(đô la Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Jordan),
				'other' => q(dinar Jordan),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yên Nhật),
				'other' => q(yên Nhật),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling Kenya),
				'other' => q(shilling Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kyrgyzstan),
				'other' => q(som Kyrgyzstan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Campuchia),
				'other' => q(riel Campuchia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Comoros),
				'other' => q(franc Comoros),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Triều Tiên),
				'other' => q(won Triều Tiên),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Đồng Hwan Hàn Quốc \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Đồng Won Hàn Quốc \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Hàn Quốc),
				'other' => q(won Hàn Quốc),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwait),
				'other' => q(dinar Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Đô la Quần đảo Cayman),
				'other' => q(đô la Quần đảo Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Kazakhstan),
				'other' => q(tenge Kazakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Lào),
				'other' => q(kip Lào),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Bảng Li-băng),
				'other' => q(bảng Li-băng),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee Sri Lanka),
				'other' => q(rupee Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Đô la Liberia),
				'other' => q(đô la Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas Lít-va),
				'other' => q(litas Lít-va),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Đồng Talonas Litva),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Đồng Franc Luxembourg có thể chuyển đổi),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Đồng Franc Luxembourg),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Đồng Franc Luxembourg tài chính),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats Latvia),
				'other' => q(lats Lativia),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Đồng Rúp Latvia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libi),
				'other' => q(dinar Libi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Ma-rốc),
				'other' => q(dirham Ma-rốc),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Đồng Franc Ma-rốc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Đồng Franc Monegasque),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Đồng Cupon Moldova),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldova),
				'other' => q(leu Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Madagascar),
				'other' => q(ariary Madagascar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Đồng Franc Magalasy),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Macedonia),
				'other' => q(denar Macedonia),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Đồng Denar Macedonia \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Đồng Franc Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Myanma),
				'other' => q(kyat Myanma),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mông Cổ),
				'other' => q(tugrik Mông Cổ),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Ma Cao),
				'other' => q(pataca Ma Cao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'other' => q(ouguiya Mauritania),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Lia xứ Man-tơ),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Đồng Bảng Malta),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Mauritius),
				'other' => q(rupee Mauritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Maldives),
				'other' => q(rufiyaa Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malawi),
				'other' => q(kwacha Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Mexico),
				'other' => q(peso Mexico),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Đồng Peso Bạc Mê-hi-cô \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Đơn vị Đầu tư Mê-hi-cô),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malaysia),
				'other' => q(ringgit Malaysia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo Mozambique),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Đồng Metical Mozambique \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mozambique),
				'other' => q(metical Mozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Đô la Namibia),
				'other' => q(đô la Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeria),
				'other' => q(naira Nigeria),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Đồng Córdoba Nicaragua \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba Nicaragua),
				'other' => q(córdoba Nicaragua),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Đồng Guilder Hà Lan),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Na Uy),
				'other' => q(krone Na Uy),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Nepal),
				'other' => q(rupee Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Đô la New Zealand),
				'other' => q(đô la New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Oman),
				'other' => q(rial Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
				'other' => q(balboa Panama),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Đồng Inti Peru),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Peru),
				'other' => q(sol Peru),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Đồng Sol Peru \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua New Guinea),
				'other' => q(kina Papua New Guinea),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Philipin),
				'other' => q(peso Philipin),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee Pakistan),
				'other' => q(rupee Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty Ba Lan),
				'other' => q(zloty Ba Lan),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Đồng Zloty Ba Lan \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Đồng Escudo Bồ Đào Nha),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Paraguay),
				'other' => q(guarani Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial Qatar),
				'other' => q(rial Qatar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Đồng Đô la Rhode),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Đồng Leu Rumani \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Romania),
				'other' => q(leu Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Serbia),
				'other' => q(dinar Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rúp Nga),
				'other' => q(rúp Nga),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Đồng Rúp Nga \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rwanda),
				'other' => q(franc Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Ả Rập Xê-út),
				'other' => q(riyal Ả Rập Xê-út),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Đô la quần đảo Solomon),
				'other' => q(đô la Quần đảo Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupee Seychelles),
				'other' => q(rupee Seychelles),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Đồng Dinar Sudan \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Bảng Sudan),
				'other' => q(bảng Sudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Đồng Bảng Sudan \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Thụy Điển),
				'other' => q(krona Thụy Điển),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Đô la Singapore),
				'other' => q(đô la Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Bảng St. Helena),
				'other' => q(bảng St. Helena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tôla Xlôvênia),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Cuaron Xlôvác),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Sierra Leone),
				'other' => q(leone Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Sierra Leone \(1964—2022\)),
				'other' => q(leone Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilling Somali),
				'other' => q(shilling Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Đô la Suriname),
				'other' => q(đô la Suriname),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Đồng Guilder Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Bảng Nam Sudan),
				'other' => q(bảng Nam Sudan),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra São Tomé và Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra São Tomé và Príncipe),
				'other' => q(dobra São Tomé và Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Đồng Rúp Sô viết),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colón El Salvador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Bảng Syria),
				'other' => q(bảng Syria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Swaziland),
				'other' => q(lilangeni Swaziland),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Bạt Thái Lan),
				'other' => q(bạt Thái Lan),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Đồng Rúp Tajikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tajikistan),
				'other' => q(somoni Tajikistan),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Đồng Manat Turkmenistan \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turkmenistan),
				'other' => q(manat Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunisia),
				'other' => q(dinar Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Tonga),
				'other' => q(paʻanga Tonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Đồng Escudo Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Lia Thổ Nhĩ Kỳ \(1922–2005\)),
				'other' => q(lia Thổ Nhĩ Kỳ \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lia Thổ Nhĩ Kỳ),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Đô la Trinidad và Tobago),
				'other' => q(đô la Trinidad và Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Đô la Đài Loan mới),
				'other' => q(đô la Đài Loan mới),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling Tanzania),
				'other' => q(shilling Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ukraina),
				'other' => q(hryvnia Ukraina),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Đồng Karbovanets Ucraina),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Đồng Shilling Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling Uganda),
				'other' => q(shilling Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Đô la Mỹ),
				'other' => q(đô la Mỹ),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Đô la Mỹ \(Ngày tiếp theo\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Đô la Mỹ \(Cùng ngày\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Đồng Peso Uruguay \(Đơn vị Theo chỉ số\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Đồng Peso Uruguay \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguay),
				'other' => q(peso Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Uzbekistan),
				'other' => q(som Uzbekistan),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Đồng bolívar của Venezuela \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolívar Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar Venezuela),
				'other' => q(bolívar Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Đồng Việt Nam),
				'other' => q(đồng Việt Nam),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Đồng Việt Nam \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'other' => q(vatu Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samoa),
				'other' => q(tala Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franc CFA Trung Phi),
				'other' => q(franc CFA Trung Phi),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Bạc),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Vàng),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Đơn vị Tổng hợp Châu Âu),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Đơn vị Tiền tệ Châu Âu),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Đơn vị Kế toán Châu Âu \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Đơn vị Kế toán Châu Âu \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Đô la Đông Caribê),
				'other' => q(đô la Đông Caribê),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Quyền Rút vốn Đặc biệt),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Đơn vị Tiền Châu Âu),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Đồng France Pháp Vàng),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Đồng UIC-Franc Pháp),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franc CFA Tây Phi),
				'other' => q(franc CFA Tây Phi),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladi),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
				'other' => q(franc CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Bạch kim),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(Quỹ RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Mã Tiền tệ Kiểm tra),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Tiền tệ chưa biết),
				'other' => q(\(tiền tệ chưa biết\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Đồng Dinar Yemen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Yemen),
				'other' => q(rial Yemen),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Đồng Dinar Nam Tư Xu \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Đồng Dinar Nam Tư Mới \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Đồng Dinar Nam Tư Có thể chuyển đổi \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Đồng Dinar Nam Tư Tái cơ cấu \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Đồng Rand Nam Phi \(tài chính\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Nam Phi),
				'other' => q(rand Nam Phi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Đồng kwacha của Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha Zambia),
				'other' => q(kwacha Zambia),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Đồng Zaire Mới \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Đồng Zaire \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Đồng Đô la Zimbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Đồng Đô la Zimbabwe \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Đồng Đô la Zimbabwe \(2008\)),
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
					wide => {
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
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'thg 1',
							'thg 2',
							'thg 3',
							'thg 4',
							'thg 5',
							'thg 6',
							'thg 7',
							'thg 8',
							'thg 9',
							'thg 10',
							'thg 11',
							'thg 12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tháng 1',
							'tháng 2',
							'tháng 3',
							'tháng 4',
							'tháng 5',
							'tháng 6',
							'tháng 7',
							'tháng 8',
							'tháng 9',
							'tháng 10',
							'tháng 11',
							'tháng 12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tháng 1',
							'Tháng 2',
							'Tháng 3',
							'Tháng 4',
							'Tháng 5',
							'Tháng 6',
							'Tháng 7',
							'Tháng 8',
							'Tháng 9',
							'Tháng 10',
							'Tháng 11',
							'Tháng 12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Tháng 1',
							'Tháng 2',
							'Tháng 3',
							'Tháng 4',
							'Tháng 5',
							'Tháng 6',
							'Tháng 7',
							'Tháng 8',
							'Tháng 9',
							'Tháng 10',
							'Tháng 11',
							'Tháng 12'
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
						mon => 'Th 2',
						tue => 'Th 3',
						wed => 'Th 4',
						thu => 'Th 5',
						fri => 'Th 6',
						sat => 'Th 7',
						sun => 'CN'
					},
					short => {
						mon => 'T2',
						tue => 'T3',
						wed => 'T4',
						thu => 'T5',
						fri => 'T6',
						sat => 'T7',
						sun => 'CN'
					},
					wide => {
						mon => 'Thứ Hai',
						tue => 'Thứ Ba',
						wed => 'Thứ Tư',
						thu => 'Thứ Năm',
						fri => 'Thứ Sáu',
						sat => 'Thứ Bảy',
						sun => 'Chủ Nhật'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'T2',
						tue => 'T3',
						wed => 'T4',
						thu => 'T5',
						fri => 'T6',
						sat => 'T7',
						sun => 'CN'
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
					wide => {0 => 'Quý 1',
						1 => 'Quý 2',
						2 => 'Quý 3',
						3 => 'Quý 4'
					},
				},
				'stand-alone' => {
					wide => {0 => 'quý 1',
						1 => 'quý 2',
						2 => 'quý 3',
						3 => 'quý 4'
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
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 2100;
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
					'afternoon1' => q{chiều},
					'am' => q{SA},
					'evening1' => q{tối},
					'midnight' => q{nửa đêm},
					'morning1' => q{sáng},
					'night1' => q{đêm},
					'noon' => q{TR},
					'pm' => q{CH},
				},
				'narrow' => {
					'afternoon1' => q{chiều},
					'am' => q{s},
					'evening1' => q{tối},
					'midnight' => q{nửa đêm},
					'morning1' => q{sáng},
					'night1' => q{đêm},
					'noon' => q{tr},
					'pm' => q{c},
				},
				'wide' => {
					'afternoon1' => q{chiều},
					'evening1' => q{tối},
					'midnight' => q{nửa đêm},
					'morning1' => q{sáng},
					'night1' => q{đêm},
					'noon' => q{trưa},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'noon' => q{trưa},
				},
				'wide' => {
					'noon' => q{trưa},
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
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'TCN',
				'1' => 'SCN'
			},
			narrow => {
				'1' => 'CN'
			},
			wide => {
				'0' => 'Trước Chúa Giáng Sinh',
				'1' => 'Sau Công Nguyên'
			},
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
			abbreviated => {
				'0' => 'Trước R.O.C'
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
			'full' => q{EEEE, 'ngày' dd MMMM 'năm' y G},
		},
		'chinese' => {
			'full' => q{EEEE, 'ngày' dd MMMM 'năm' U},
			'long' => q{'Ngày' dd 'tháng' M 'năm' U},
			'medium' => q{dd-MM U},
			'short' => q{dd/MM/y},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, 'ngày' d 'tháng' M 'năm' y G},
			'long' => q{'ngày' d 'tháng' M 'năm' y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, 'ngày' dd MMMM 'năm' y G},
			'long' => q{'Ngày' dd 'tháng' M 'năm' y G},
			'medium' => q{dd-MM-y G},
			'short' => q{dd/MM/y G},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{EEEE, 'ngày' dd MMMM 'năm' y G},
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
		'chinese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{0} {1}},
			'long' => q{{0} {1}},
			'medium' => q{{0} {1}},
			'short' => q{{0} {1}},
		},
		'gregorian' => {
			'full' => q{{0} {1}},
			'long' => q{{0} {1}},
			'medium' => q{{0} {1}},
			'short' => q{{0} {1}},
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
		'buddhist' => {
			M => q{'tháng' L},
			MEd => q{E, dd-M},
			d => q{'Ngày' dd},
		},
		'chinese' => {
			Bh => q{h 'giờ' B},
			EBhm => q{h:mm B E},
			EBhms => q{h:mm:ss B E},
			Ed => q{E, 'ngày' d},
			Gy => q{U r},
			GyMMM => q{'tháng' M 'năm' U r},
			GyMMMEd => q{E, 'ngày' d 'tháng' M 'năm' r},
			GyMMMM => q{'tháng' M 'năm' U r},
			GyMMMMEd => q{E, 'ngày' d 'tháng' M 'năm' U r},
			GyMMMMd => q{'ngày' d 'tháng' M 'năm' U r},
			GyMMMd => q{'ngày' d 'tháng' M 'năm' r},
			H => q{HH 'giờ'},
			MEd => q{E, d/M},
			MMMEd => q{E, 'ngày' d 'tháng' M},
			MMMMd => q{'ngày' d 'tháng' M},
			MMMd => q{'ngày' d 'tháng' M},
			Md => q{d/M},
			UM => q{'tháng' M 'năm' U},
			UMMM => q{'tháng' M 'năm' U},
			UMMMd => q{'ngày' d 'tháng' M 'năm' U},
			UMd => q{d/M 'năm' U},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{U r},
			yMd => q{dd-MM-r},
			yyyy => q{U r},
			yyyyM => q{M/r},
			yyyyMEd => q{E, d/M/r},
			yyyyMMM => q{'tháng' M 'năm' r},
			yyyyMMMEd => q{E, 'ngày' d 'tháng' M 'năm' r},
			yyyyMMMM => q{'tháng' M 'năm' U r},
			yyyyMMMMEd => q{E, 'ngày' d 'tháng' M 'năm' U r},
			yyyyMMMMd => q{'ngày' d 'tháng' M 'năm' U r},
			yyyyMMMd => q{'ngày' d 'tháng' M 'năm' r},
			yyyyMd => q{d/M/r},
			yyyyQQQ => q{QQQ 'năm' U r},
			yyyyQQQQ => q{QQQQ 'năm' U r},
		},
		'generic' => {
			Bh => q{h 'giờ' B},
			EBhm => q{h:mm B E},
			EBhms => q{h:mm:ss B E},
			EHm => q{HH:mm E},
			EHms => q{HH:mm:ss E},
			Ed => q{E, 'ngày' d},
			Ehm => q{h:mm a E},
			Ehms => q{h:mm:ss a E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{d/M/y GGGGG},
			H => q{HH 'giờ'},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, dd MMMM},
			MMMMd => q{dd MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd-MM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMM => q{MM-y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{h 'giờ' B},
			EBhm => q{h:mm B E},
			EBhms => q{h:mm:ss B E},
			EHm => q{HH:mm E},
			EHms => q{HH:mm:ss E},
			Ed => q{E, 'ngày' d},
			Ehm => q{h:mm a E},
			Ehms => q{h:mm:ss a E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{d/M/y G},
			H => q{HH 'giờ'},
			Hm => q{H:mm},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'tuần' W 'của' 'tháng' M},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd-MM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMM => q{'tháng' MM, y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM 'năm' y},
			yMMMd => q{d MMM, y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'năm' y},
			yw => q{'tuần' w 'của' 'năm' Y},
		},
		'roc' => {
			M => q{'tháng' L},
			MEd => q{E, dd-M},
			Md => q{dd-M},
			d => q{'Ngày' dd},
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
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'chinese' => {
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
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
			MMM => {
				M => q{MMM – MMM},
			},
			d => {
				d => q{d – d},
			},
			h => {
				h => q{h – h a},
			},
			hm => {
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			y => {
				y => q{U – U},
			},
		},
		'coptic' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'dangi' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
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
			},
			hm => {
				a => q{h:mm a – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
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
		'ethiopic' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'generic' => {
			Bh => {
				B => q{h 'giờ' B – h 'giờ' B},
				h => q{h – h 'giờ' B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
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
				G => q{E, d/M/y GGGGG  –  E, d/M/y GGGGG},
				M => q{E, d/M/y  –  E, d/M/y GGGGG},
				d => q{E, d/M/y  –  E, d/M/y GGGGG},
				y => q{E, d/M/y  –  E, d/M/y GGGGG},
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
				G => q{d/M/y GGGGG  –  d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH'h' - HH'h'},
			},
			Hv => {
				H => q{HH'h'-HH'h' v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M  –  E, d/M},
				d => q{E, d/M  –  E, d/M},
			},
			MMM => {
				M => q{MMM  –  MMM},
			},
			MMMEd => {
				M => q{E, d MMM  –  E, d MMM},
				d => q{E, d MMM  –  E, d MMM},
			},
			MMMd => {
				M => q{d MMM  –  d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			h => {
				a => q{h'h' a – h'h' a},
				h => q{h'h' - h'h' a},
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
				a => q{h'h' a – h'h' a v},
				h => q{h'h'-h'h' a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y  –  E, d/M/y GGGGG},
				d => q{E, d/M/y  –  E, d/M/y GGGGG},
				y => q{E, d/M/y  –  E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM  –  MMM y G},
				y => q{MMM y  –  MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM  –  E, d MMM, y G},
				d => q{E, d MMM  –  E, d MMM, y G},
				y => q{E, d MMM, y  –  E, d MMM, y G},
			},
			yMMMM => {
				M => q{MMMM  –  MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM  –  d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y  –  d MMM, y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h 'giờ' B  –  h 'giờ' B},
				h => q{h – h 'giờ' B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y G  –  M/y G},
				M => q{M/y– M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, d/M/y G  –  E, d/M/y G},
				M => q{E, d/M/y  –  E, d/M/y G},
				d => q{E, d/M/y  –  E, d/M/y G},
				y => q{E, d/M/y  –  E, d/M/y G},
			},
			GyMMM => {
				G => q{MMM y G  –  MMM y G},
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
				G => q{d/M/y G  –  d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			M => {
				M => q{'Tháng' M – M},
			},
			MEd => {
				M => q{E, d/M  –  E, d/M},
				d => q{E, d/M  –  E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM  –  d MMM},
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
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y  –  E, d/M/y},
				d => q{E, d/M/y  –  E, d/M/y},
				y => q{E, d/M/y  –  E, d/M/y},
			},
			yMMM => {
				M => q{MMM  –  MMM y},
				y => q{MMM y  –  MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM  –  E, d MMM, y},
				d => q{E, d MMM  –  E, d MMM, y},
				y => q{E, d MMM, y  –  E, d MMM, y},
			},
			yMMMM => {
				M => q{MMMM  –  MMMM 'năm' y},
				y => q{MMMM 'năm' y  –  MMMM 'năm' y},
			},
			yMMMd => {
				M => q{d MMM  –  d MMM, y},
				d => q{d – d MMM, y},
				y => q{d MMM, y  –  d MMM, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'hebrew' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'indian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'islamic' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'persian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'roc' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGGG – E, dd-MM-y GGGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			GyMd => {
				G => q{dd-MM-y GGGGG – dd-MM-y GGGGG},
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
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
				'wide' => {
					'leap' => q{{0} Nhuận},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{{0} Nhuận},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'leap' => q{{0} Nhuận},
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
						0 => q(Tý),
						1 => q(Sửu),
						2 => q(Dần),
						3 => q(Mão),
						4 => q(Thìn),
						5 => q(Tỵ),
						6 => q(Ngọ),
						7 => q(Mùi),
						8 => q(Thân),
						9 => q(Dậu),
						10 => q(Tuất),
						11 => q(Hợi),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(Lập Xuân),
						1 => q(Vũ Thủy),
						2 => q(Kinh Trập),
						3 => q(Xuân Phân),
						4 => q(Thanh Minh),
						5 => q(Cốc Vũ),
						6 => q(Lập Hạ),
						7 => q(Tiểu Mãn),
						8 => q(Mang Chủng),
						9 => q(Hạ Chí),
						10 => q(Tiểu Thử),
						11 => q(Đại Thử),
						12 => q(Lập Thu),
						13 => q(Xử Thử),
						14 => q(Bạch Lộ),
						15 => q(Thu Phân),
						16 => q(Hàn Lộ),
						17 => q(Sương Giáng),
						18 => q(Lập Đông),
						19 => q(Tiểu Tuyết),
						20 => q(Đại Tuyết),
						21 => q(Đông Chí),
						22 => q(Tiểu Hàn),
						23 => q(Đại Hàn),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(Giáp Tý),
						1 => q(Ất Sửu),
						2 => q(Bính Dần),
						3 => q(Đinh Mão),
						4 => q(Mậu Thìn),
						5 => q(Kỷ Tỵ),
						6 => q(Canh Ngọ),
						7 => q(Tân Mùi),
						8 => q(Nhâm Thân),
						9 => q(Quý Dậu),
						10 => q(Giáp Tuất),
						11 => q(Ất Hợi),
						12 => q(Bính Tý),
						13 => q(Đinh Sửu),
						14 => q(Mậu Dần),
						15 => q(Kỷ Mão),
						16 => q(Canh Thìn),
						17 => q(Tân Tỵ),
						18 => q(Nhâm Ngọ),
						19 => q(Quý Mùi),
						20 => q(Giáp Thân),
						21 => q(Ất Dậu),
						22 => q(Bính Tuất),
						23 => q(Đinh Hợi),
						24 => q(Mậu Tý),
						25 => q(Kỷ Sửu),
						26 => q(Canh Dần),
						27 => q(Tân Mão),
						28 => q(Nhâm Thìn),
						29 => q(Quý Tỵ),
						30 => q(Giáp Ngọ),
						31 => q(Ất Mùi),
						32 => q(Bính Thân),
						33 => q(Đinh Dậu),
						34 => q(Mậu Tuất),
						35 => q(Kỷ Hợi),
						36 => q(Canh Tý),
						37 => q(Tân Sửu),
						38 => q(Nhâm Dần),
						39 => q(Quý Mão),
						40 => q(Giáp Thìn),
						41 => q(Ất Tỵ),
						42 => q(Bính Ngọ),
						43 => q(Đinh Mùi),
						44 => q(Mậu Thân),
						45 => q(Kỷ Dậu),
						46 => q(Canh Tuất),
						47 => q(Tân Hợi),
						48 => q(Nhâm Tý),
						49 => q(Quý Sửu),
						50 => q(Giáp Dần),
						51 => q(Ất Mão),
						52 => q(Bính Thìn),
						53 => q(Đinh Tỵ),
						54 => q(Mậu Ngọ),
						55 => q(Kỷ Mùi),
						56 => q(Canh Thân),
						57 => q(Tân Dậu),
						58 => q(Nhâm Tuất),
						59 => q(Quý Hợi),
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
		regionFormat => q(Giờ {0}),
		regionFormat => q(Giờ mùa hè {0}),
		regionFormat => q(Giờ chuẩn {0}),
		'Acre' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Acre#,
				'generic' => q#Giờ Acre#,
				'standard' => q#Giờ Chuẩn Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Giờ Afghanistan#,
			},
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Giờ Trung Phi#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Giờ Đông Phi#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Giờ Chuẩn Nam Phi#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Tây Phi#,
				'generic' => q#Giờ Tây Phi#,
				'standard' => q#Giờ Chuẩn Tây Phi#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Alaska#,
				'generic' => q#Giờ Alaska#,
				'standard' => q#Giờ Chuẩn Alaska#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Almaty#,
				'generic' => q#Giờ Almaty#,
				'standard' => q#Giờ Chuẩn Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Amazon#,
				'generic' => q#Giờ Amazon#,
				'standard' => q#Giờ Chuẩn Amazon#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Bắc Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Bắc Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Bắc Dakota#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Giờ mùa hè miền Trung#,
				'generic' => q#Giờ miền Trung#,
				'standard' => q#Giờ chuẩn miền Trung#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Giờ mùa hè miền Đông#,
				'generic' => q#Giờ miền Đông#,
				'standard' => q#Giờ chuẩn miền Đông#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Giờ mùa hè miền núi#,
				'generic' => q#Giờ miền núi#,
				'standard' => q#Giờ chuẩn miền núi#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Giờ mùa hè Thái Bình Dương#,
				'generic' => q#Giờ Thái Bình Dương#,
				'standard' => q#Giờ chuẩn Thái Bình Dương#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Giờ mùa hè Anadyr#,
				'generic' => q#Giờ Anadyr#,
				'standard' => q#Giờ Chuẩn Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Apia#,
				'generic' => q#Giờ Apia#,
				'standard' => q#Giờ Chuẩn Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Aqtau#,
				'generic' => q#Giờ Aqtau#,
				'standard' => q#Giờ Chuẩn Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Aqtobe#,
				'generic' => q#Giờ Aqtobe#,
				'standard' => q#Giờ Chuẩn Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Ả Rập#,
				'generic' => q#Giờ Ả Rập#,
				'standard' => q#Giờ chuẩn Ả Rập#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Argentina#,
				'generic' => q#Giờ Argentina#,
				'standard' => q#Giờ Chuẩn Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Giờ mùa hè miền tây Argentina#,
				'generic' => q#Giờ miền tây Argentina#,
				'standard' => q#Giờ chuẩn miền tây Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Armenia#,
				'generic' => q#Giờ Armenia#,
				'standard' => q#Giờ Chuẩn Armenia#,
			},
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hồng Kông#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Ma Cao#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Bình Nhưỡng#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#TP Hồ Chí Minh#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Thượng Hải#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Đài Bắc#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Viêng Chăn#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Giờ mùa hè Đại Tây Dương#,
				'generic' => q#Giờ Đại Tây Dương#,
				'standard' => q#Giờ Chuẩn Đại Tây Dương#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Nam Georgia#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Miền Trung Australia#,
				'generic' => q#Giờ Miền Trung Australia#,
				'standard' => q#Giờ Chuẩn Miền Trung Australia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Miền Trung Tây Australia#,
				'generic' => q#Giờ Miền Trung Tây Australia#,
				'standard' => q#Giờ Chuẩn Miền Trung Tây Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Miền Đông Australia#,
				'generic' => q#Giờ Miền Đông Australia#,
				'standard' => q#Giờ Chuẩn Miền Đông Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Miền Tây Australia#,
				'generic' => q#Giờ Miền Tây Australia#,
				'standard' => q#Giờ Chuẩn Miền Tây Australia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Azerbaijan#,
				'generic' => q#Giờ Azerbaijan#,
				'standard' => q#Giờ Chuẩn Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Giờ mùa hè Azores#,
				'generic' => q#Giờ Azores#,
				'standard' => q#Giờ chuẩn Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Bangladesh#,
				'generic' => q#Giờ Bangladesh#,
				'standard' => q#Giờ Chuẩn Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Giờ Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Giờ Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Brasilia#,
				'generic' => q#Giờ Brasilia#,
				'standard' => q#Giờ Chuẩn Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Giờ Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Cape Verde#,
				'generic' => q#Giờ Cape Verde#,
				'standard' => q#Giờ Chuẩn Cape Verde#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Giờ Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Giờ Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Chatham#,
				'generic' => q#Giờ Chatham#,
				'standard' => q#Giờ Chuẩn Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Chile#,
				'generic' => q#Giờ Chile#,
				'standard' => q#Giờ Chuẩn Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Trung Quốc#,
				'generic' => q#Giờ Trung Quốc#,
				'standard' => q#Giờ Chuẩn Trung Quốc#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Choibalsan#,
				'generic' => q#Giờ Choibalsan#,
				'standard' => q#Giờ Chuẩn Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Giờ Đảo Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Giờ Quần Đảo Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Colombia#,
				'generic' => q#Giờ Colombia#,
				'standard' => q#Giờ Chuẩn Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Giờ Nửa Mùa Hè Quần Đảo Cook#,
				'generic' => q#Giờ Quần Đảo Cook#,
				'standard' => q#Giờ Chuẩn Quần Đảo Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Cuba#,
				'generic' => q#Giờ Cuba#,
				'standard' => q#Giờ Chuẩn Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Giờ Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Giờ Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Giờ Đông Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Đảo Phục Sinh#,
				'generic' => q#Giờ Đảo Phục Sinh#,
				'standard' => q#Giờ Chuẩn Đảo Phục Sinh#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Giờ Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Giờ Phối hợp Quốc tế#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Thành phố không xác định#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Giờ chuẩn Ai-len#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Đảo Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Anh#,
			},
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mát-xcơ-va#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Giờ mùa hè Trung Âu#,
				'generic' => q#Giờ Trung Âu#,
				'standard' => q#Giờ chuẩn Trung Âu#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Giờ mùa hè Đông Âu#,
				'generic' => q#Giờ Đông Âu#,
				'standard' => q#Giờ chuẩn Đông Âu#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Giờ Viễn đông Châu Âu#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Giờ mùa hè Tây Âu#,
				'generic' => q#Giờ Tây Âu#,
				'standard' => q#Giờ Chuẩn Tây Âu#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Quần Đảo Falkland#,
				'generic' => q#Giờ Quần Đảo Falkland#,
				'standard' => q#Giờ Chuẩn Quần Đảo Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Fiji#,
				'generic' => q#Giờ Fiji#,
				'standard' => q#Giờ Chuẩn Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Giờ Guiana thuộc Pháp#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Giờ Nam Cực và Nam Nước Pháp#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Giờ Trung bình Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Giờ Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Giờ Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Georgia#,
				'generic' => q#Giờ Georgia#,
				'standard' => q#Giờ Chuẩn Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Giờ Quần Đảo Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Miền Đông Greenland#,
				'generic' => q#Giờ Miền Đông Greenland#,
				'standard' => q#Giờ Chuẩn Miền Đông Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Miền Tây Greenland#,
				'generic' => q#Giờ Miền Tây Greenland#,
				'standard' => q#Giờ Chuẩn Miền Tây Greenland#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Giờ Chuẩn Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Giờ Chuẩn Vùng Vịnh#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Giờ Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Hawaii-Aleut#,
				'generic' => q#Giờ Hawaii-Aleut#,
				'standard' => q#Giờ Chuẩn Hawaii-Aleut#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Hồng Kông#,
				'generic' => q#Giờ Hồng Kông#,
				'standard' => q#Giờ Chuẩn Hồng Kông#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Hovd#,
				'generic' => q#Giờ Hovd#,
				'standard' => q#Giờ Chuẩn Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Giờ Chuẩn Ấn Độ#,
			},
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Giờ Ấn Độ Dương#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Giờ Đông Dương#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Giờ Miền Trung Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Giờ Miền Đông Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Giờ Miền Tây Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Iran#,
				'generic' => q#Giờ Iran#,
				'standard' => q#Giờ Chuẩn Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Irkutsk#,
				'generic' => q#Giờ Irkutsk#,
				'standard' => q#Giờ Chuẩn Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Israel#,
				'generic' => q#Giờ Israel#,
				'standard' => q#Giờ Chuẩn Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Nhật Bản#,
				'generic' => q#Giờ Nhật Bản#,
				'standard' => q#Giờ Chuẩn Nhật Bản#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Giờ mùa hè Petropavlovsk-Kamchatski#,
				'generic' => q#Giờ Petropavlovsk-Kamchatski#,
				'standard' => q#Giờ chuẩn Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Giờ Miền Đông Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Giờ Miền Tây Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Hàn Quốc#,
				'generic' => q#Giờ Hàn Quốc#,
				'standard' => q#Giờ Chuẩn Hàn Quốc#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Giờ Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Krasnoyarsk#,
				'generic' => q#Giờ Krasnoyarsk#,
				'standard' => q#Giờ Chuẩn Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Giờ Kyrgystan#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Giờ Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Giờ Quần Đảo Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Lord Howe#,
				'generic' => q#Giờ Lord Howe#,
				'standard' => q#Giờ Chuẩn Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Ma Cao#,
				'generic' => q#Giờ Ma Cao#,
				'standard' => q#Giờ Chuẩn Ma Cao#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Giờ đảo Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Giờ mùa hè Magadan#,
				'generic' => q#Giờ Magadan#,
				'standard' => q#Giờ Chuẩn Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Giờ Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Giờ Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Giờ Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Giờ Quần Đảo Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Mauritius#,
				'generic' => q#Giờ Mauritius#,
				'standard' => q#Giờ Chuẩn Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Giờ Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Tây Bắc Mexico#,
				'generic' => q#Giờ Tây Bắc Mexico#,
				'standard' => q#Giờ Chuẩn Tây Bắc Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Thái Bình Dương Mexico#,
				'generic' => q#Giờ Thái Bình Dương Mexico#,
				'standard' => q#Giờ Chuẩn Thái Bình Dương Mexico#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Giờ mùa hè Ulan Bator#,
				'generic' => q#Giờ Ulan Bator#,
				'standard' => q#Giờ chuẩn Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Matxcơva#,
				'generic' => q#Giờ Matxcơva#,
				'standard' => q#Giờ Chuẩn Matxcơva#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Giờ Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Giờ Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Giờ Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Giờ Mùa Hè New Caledonia#,
				'generic' => q#Giờ New Caledonia#,
				'standard' => q#Giờ Chuẩn New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Giờ Mùa Hè New Zealand#,
				'generic' => q#Giờ New Zealand#,
				'standard' => q#Giờ Chuẩn New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Newfoundland#,
				'generic' => q#Giờ Newfoundland#,
				'standard' => q#Giờ Chuẩn Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Giờ Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Đảo Norfolk#,
				'generic' => q#Giờ Đảo Norfolk#,
				'standard' => q#Giờ Chuẩn Đảo Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Fernando de Noronha#,
				'generic' => q#Giờ Fernando de Noronha#,
				'standard' => q#Giờ Chuẩn Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Giờ Quần Đảo Bắc Mariana#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Giờ mùa hè Novosibirsk#,
				'generic' => q#Giờ Novosibirsk#,
				'standard' => q#Giờ chuẩn Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Giờ mùa hè Omsk#,
				'generic' => q#Giờ Omsk#,
				'standard' => q#Giờ chuẩn Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#Giờ HST#,
				'standard' => q#HST#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Pakistan#,
				'generic' => q#Giờ Pakistan#,
				'standard' => q#Giờ Chuẩn Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Giờ Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Giờ Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Paraguay#,
				'generic' => q#Giờ Paraguay#,
				'standard' => q#Giờ Chuẩn Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Peru#,
				'generic' => q#Giờ Peru#,
				'standard' => q#Giờ Chuẩn Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Philippin#,
				'generic' => q#Giờ Philippin#,
				'standard' => q#Giờ Chuẩn Philippin#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Giờ Quần Đảo Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Saint Pierre và Miquelon#,
				'generic' => q#Giờ St. Pierre và Miquelon#,
				'standard' => q#Giờ Chuẩn St. Pierre và Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Giờ Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Giờ Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Giờ Bình Nhưỡng#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Qyzylorda#,
				'generic' => q#Giờ Qyzylorda#,
				'standard' => q#Giờ Chuẩn Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Giờ Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Giờ Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Giờ mùa hè Sakhalin#,
				'generic' => q#Giờ Sakhalin#,
				'standard' => q#Giờ Chuẩn Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Giờ mùa hè Samara#,
				'generic' => q#Giờ Samara#,
				'standard' => q#Giờ Chuẩn Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Giờ ban ngày Samoa#,
				'generic' => q#Giờ Samoa#,
				'standard' => q#Giờ Chuẩn Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Giờ Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Giờ Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Giờ Quần Đảo Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Giờ Nam Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Giờ Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Giờ Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Giờ Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Đài Bắc#,
				'generic' => q#Giờ Đài Bắc#,
				'standard' => q#Giờ Chuẩn Đài Bắc#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Giờ Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Giờ Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Tonga#,
				'generic' => q#Giờ Tonga#,
				'standard' => q#Giờ Chuẩn Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Giờ Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Turkmenistan#,
				'generic' => q#Giờ Turkmenistan#,
				'standard' => q#Giờ Chuẩn Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Giờ Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Uruguay#,
				'generic' => q#Giờ Uruguay#,
				'standard' => q#Giờ Chuẩn Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Uzbekistan#,
				'generic' => q#Giờ Uzbekistan#,
				'standard' => q#Giờ Chuẩn Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Vanuatu#,
				'generic' => q#Giờ Vanuatu#,
				'standard' => q#Giờ Chuẩn Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Giờ Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Giờ mùa hè Vladivostok#,
				'generic' => q#Giờ Vladivostok#,
				'standard' => q#Giờ Chuẩn Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Giờ Mùa Hè Volgograd#,
				'generic' => q#Giờ Volgograd#,
				'standard' => q#Giờ Chuẩn Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Giờ Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Giờ Đảo Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Giờ Wallis và Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Giờ mùa hè Yakutsk#,
				'generic' => q#Giờ Yakutsk#,
				'standard' => q#Giờ Chuẩn Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Giờ mùa hè Yekaterinburg#,
				'generic' => q#Giờ Yekaterinburg#,
				'standard' => q#Giờ Chuẩn Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Giờ Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
