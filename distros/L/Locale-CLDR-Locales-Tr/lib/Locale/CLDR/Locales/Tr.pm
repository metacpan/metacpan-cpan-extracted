=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tr - Package for language Turkish

=cut

package Locale::CLDR::Locales::Tr;
# This file auto generated from Data\common\main\tr.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
		'inci' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(inci),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'inci2' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ıncı),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'nci' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nci),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(eksi →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sıfır),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgül →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(bir),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(iki),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(üç),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(dört),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(beş),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(altı),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(yedi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(sekiz),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(dokuz),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(on[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(yirmi[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(otuz[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(kırk[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(elli[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(altmış[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(yetmiş[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(seksen[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(doksan[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(yüz[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←← yüz[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(bin[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← bin[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← milyon[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← milyar[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trilyon[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← katrilyon[ →→]),
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
				'-x' => {
					divisor => q(1),
					rule => q(eksi →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sıfırıncı),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(birinci),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ikinci),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(üçüncü),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(dördüncü),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(beşinci),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(altıncı),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(yedinci),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(sekizinci),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(dokuzuncu),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(on→%%uncu→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(yirmi→%%nci→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(otuz→%%uncu→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(kırk→%%inci2→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(elli→%%nci→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(altmış→%%inci2→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(yetmiş→%%inci→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(seksen→%%inci→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(doksan→%%inci2→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(yüz→%%uncu2→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-numbering← yüz→%%uncu2→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(bin→%%inci→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← bin→%%inci→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-numbering← milyon→%%uncu→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-numbering← milyar→%%inci2→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering← trilyon→%%uncu→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-numbering← katrilyon→%%uncu→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0='inci),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0='inci),
				},
			},
		},
		'uncu' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(uncu),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'uncu2' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(üncü),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
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
 				'ab' => 'Abhazca',
 				'ace' => 'Açece',
 				'ach' => 'Acoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adigece',
 				'ae' => 'Avestçe',
 				'aeb' => 'Tunus Arapçası',
 				'af' => 'Afrikaanca',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Aynuca',
 				'ak' => 'Akan',
 				'akk' => 'Akad Dili',
 				'akz' => 'Alabamaca',
 				'ale' => 'Aleut dili',
 				'aln' => 'Gheg Arnavutçası',
 				'alt' => 'Güney Altayca',
 				'am' => 'Amharca',
 				'an' => 'Aragonca',
 				'ang' => 'Eski İngilizce',
 				'ann' => 'Obolo dili',
 				'anp' => 'Angika',
 				'ar' => 'Arapça',
 				'ar_001' => 'Modern Standart Arapça',
 				'arc' => 'Aramice',
 				'arn' => 'Mapuçe dili',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho dili',
 				'arq' => 'Cezayir Arapçası',
 				'ars' => 'Necd Arapçası',
 				'ars@alt=menu' => 'Arapça, Necd',
 				'arw' => 'Arawak Dili',
 				'ary' => 'Fas Arapçası',
 				'arz' => 'Mısır Arapçası',
 				'as' => 'Assamca',
 				'asa' => 'Asu',
 				'ase' => 'Amerikan İşaret Dili',
 				'ast' => 'Asturyasça',
 				'atj' => 'Atikamekçe',
 				'av' => 'Avar dili',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaycan dili',
 				'az_Arab' => 'Güney Azerice',
 				'ba' => 'Başkırtça',
 				'bal' => 'Beluçça',
 				'ban' => 'Bali dili',
 				'bar' => 'Bavyera dili',
 				'bas' => 'Basa Dili',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala',
 				'be' => 'Belarusça',
 				'bej' => 'Beja dili',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgarca',
 				'bgc' => 'Haryanvi dili',
 				'bgn' => 'Batı Balochi',
 				'bho' => 'Arayanice',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bjn' => 'Banjar Dili',
 				'bkm' => 'Kom',
 				'bla' => 'Karaayak dili',
 				'blo' => 'Aniice',
 				'bm' => 'Bambara',
 				'bn' => 'Bengalce',
 				'bo' => 'Tibetçe',
 				'bpy' => 'Bishnupriya',
 				'bqi' => 'Bahtiyari',
 				'br' => 'Bretonca',
 				'bra' => 'Braj',
 				'brh' => 'Brohice',
 				'brx' => 'Bodo',
 				'bs' => 'Boşnakça',
 				'bss' => 'Akoose',
 				'bua' => 'Buryatça',
 				'bug' => 'Bugis',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Katalanca',
 				'cad' => 'Kado dili',
 				'car' => 'Carib',
 				'cay' => 'Kayuga dili',
 				'cch' => 'Atsam',
 				'ccp' => 'Chakma',
 				'ce' => 'Çeçence',
 				'ceb' => 'Sebuano dili',
 				'cgg' => 'Kiga',
 				'ch' => 'Çamorro dili',
 				'chb' => 'Çibça dili',
 				'chg' => 'Çağatayca',
 				'chk' => 'Chuukese',
 				'chm' => 'Mari dili',
 				'chn' => 'Çinuk dili',
 				'cho' => 'Çoktav dili',
 				'chp' => 'Çipevya dili',
 				'chr' => 'Çerokice',
 				'chy' => 'Şayence',
 				'ckb' => 'Orta Kürtçe',
 				'ckb@alt=menu' => 'Kürtçe, Orta',
 				'ckb@alt=variant' => 'Kürtçe, Sorani',
 				'clc' => 'Çilkotince',
 				'co' => 'Korsikaca',
 				'cop' => 'Kıptice',
 				'cps' => 'Capiznon',
 				'cr' => 'Krice',
 				'crg' => 'Michif dili',
 				'crh' => 'Kırım Tatarcası',
 				'crj' => 'Güney Doğu Kricesi',
 				'crk' => 'Ova Kricesi',
 				'crl' => 'Kuzey Doğu Kricesi',
 				'crm' => 'Moose Kricesi',
 				'crr' => 'Carolina Algonkin dili',
 				'crs' => 'Seselwa Kreole Fransızcası',
 				'cs' => 'Çekçe',
 				'csb' => 'Kashubian',
 				'csw' => 'Bataklık Kricesi',
 				'cu' => 'Kilise Slavcası',
 				'cv' => 'Çuvaşça',
 				'cy' => 'Galce',
 				'da' => 'Danca',
 				'dak' => 'Dakotaca',
 				'dar' => 'Dargince',
 				'dav' => 'Taita',
 				'de' => 'Almanca',
 				'de_AT' => 'Avusturya Almancası',
 				'de_CH' => 'İsviçre Yüksek Almancası',
 				'del' => 'Delaware',
 				'den' => 'Slavey dili',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka dili',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Aşağı Sorbça',
 				'dtp' => 'Orta Kadazan',
 				'dua' => 'Duala',
 				'dum' => 'Ortaçağ Felemenkçesi',
 				'dv' => 'Divehi dili',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egl' => 'Emilia Dili',
 				'egy' => 'Eski Mısır Dili',
 				'eka' => 'Ekajuk',
 				'el' => 'Yunanca',
 				'elx' => 'Elam',
 				'en' => 'İngilizce',
 				'en_AU' => 'Avustralya İngilizcesi',
 				'en_CA' => 'Kanada İngilizcesi',
 				'en_GB' => 'İngiliz İngilizcesi',
 				'en_GB@alt=short' => 'Birleşik Krallık İngilizcesi',
 				'en_US' => 'Amerikan İngilizcesi',
 				'en_US@alt=short' => 'ABD İngilizcesi',
 				'enm' => 'Ortaçağ İngilizcesi',
 				'eo' => 'Esperanto',
 				'es' => 'İspanyolca',
 				'es_419' => 'Latin Amerika İspanyolcası',
 				'es_ES' => 'Avrupa İspanyolcası',
 				'es_MX' => 'Meksika İspanyolcası',
 				'esu' => 'Merkezi Yupikçe',
 				'et' => 'Estonca',
 				'eu' => 'Baskça',
 				'ewo' => 'Ewondo',
 				'ext' => 'Ekstremadura Dili',
 				'fa' => 'Farsça',
 				'fa_AF' => 'Darice',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fula dili',
 				'fi' => 'Fince',
 				'fil' => 'Filipince',
 				'fit' => 'Tornedalin Fincesi',
 				'fj' => 'Fiji dili',
 				'fo' => 'Faroe dili',
 				'fon' => 'Fon',
 				'fr' => 'Fransızca',
 				'fr_CA' => 'Kanada Fransızcası',
 				'fr_CH' => 'İsviçre Fransızcası',
 				'frc' => 'Cajun Fransızcası',
 				'frm' => 'Ortaçağ Fransızcası',
 				'fro' => 'Eski Fransızca',
 				'frp' => 'Arpitanca',
 				'frr' => 'Kuzey Frizce',
 				'frs' => 'Doğu Frizcesi',
 				'fur' => 'Friuli dili',
 				'fy' => 'Batı Frizcesi',
 				'ga' => 'İrlandaca',
 				'gaa' => 'Ga dili',
 				'gag' => 'Gagavuzca',
 				'gan' => 'Gan Çincesi',
 				'gay' => 'Gayo dili',
 				'gba' => 'Gbaya',
 				'gbz' => 'Zerdüşt Daricesi',
 				'gd' => 'İskoç Gaelcesi',
 				'gez' => 'Geez',
 				'gil' => 'Kiribatice',
 				'gl' => 'Galiçyaca',
 				'glk' => 'Gilanice',
 				'gmh' => 'Ortaçağ Yüksek Almancası',
 				'gn' => 'Guarani dili',
 				'goh' => 'Eski Yüksek Almanca',
 				'gon' => 'Gondi dili',
 				'gor' => 'Gorontalo dili',
 				'got' => 'Gotça',
 				'grb' => 'Grebo dili',
 				'grc' => 'Antik Yunanca',
 				'gsw' => 'İsviçre Almancası',
 				'gu' => 'Güceratça',
 				'guc' => 'Wayuu dili',
 				'gur' => 'Frafra',
 				'guz' => 'Gusii',
 				'gv' => 'Man dili',
 				'gwi' => 'Guçince',
 				'ha' => 'Hausa dili',
 				'hai' => 'Haydaca',
 				'hak' => 'Hakka Çincesi',
 				'haw' => 'Hawaii dili',
 				'hax' => 'Güney Haydaca',
 				'he' => 'İbranice',
 				'hi' => 'Hintçe',
 				'hi_Latn@alt=variant' => 'Hindilizce',
 				'hif' => 'Fiji Hintçesi',
 				'hil' => 'Hiligaynon dili',
 				'hit' => 'Hititçe',
 				'hmn' => 'Hmong',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Hırvatça',
 				'hsb' => 'Yukarı Sorbça',
 				'hsn' => 'Xiang Çincesi',
 				'ht' => 'Haiti Kreyolu',
 				'hu' => 'Macarca',
 				'hup' => 'Hupaca',
 				'hur' => 'Halkomelemce',
 				'hy' => 'Ermenice',
 				'hz' => 'Herero dili',
 				'ia' => 'İnterlingua',
 				'iba' => 'Iban',
 				'ibb' => 'İbibio dili',
 				'id' => 'Endonezce',
 				'ie' => 'Interlingue',
 				'ig' => 'İbo dili',
 				'ii' => 'Sichuan Yi',
 				'ik' => 'İnyupikçe',
 				'ikt' => 'Batı Kanada İnuktitut dili',
 				'ilo' => 'Iloko',
 				'inh' => 'İnguşça',
 				'io' => 'Ido',
 				'is' => 'İzlandaca',
 				'it' => 'İtalyanca',
 				'iu' => 'İnuktitut dili',
 				'izh' => 'İngriya Dili',
 				'ja' => 'Japonca',
 				'jam' => 'Jamaika Patois Dili',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Yahudi Farsçası',
 				'jrb' => 'Yahudi Arapçası',
 				'jut' => 'Yutland Dili',
 				'jv' => 'Cava dili',
 				'ka' => 'Gürcüce',
 				'kaa' => 'Karakalpakça',
 				'kab' => 'Kabiliyece',
 				'kac' => 'Kaçin dili',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardeyce',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo dili',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi dili',
 				'kho' => 'Hotanca',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Çitral Dili',
 				'ki' => 'Kikuyu',
 				'kiu' => 'Kırmançça',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazakça',
 				'kkj' => 'Kako',
 				'kl' => 'Grönland dili',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer dili',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada dili',
 				'ko' => 'Korece',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Konkani dili',
 				'kos' => 'Kosraean',
 				'kpe' => 'Kpelle dili',
 				'kr' => 'Kanuri dili',
 				'krc' => 'Karaçay-Balkarca',
 				'kri' => 'Krio',
 				'krj' => 'Kinaray-a',
 				'krl' => 'Karelyaca',
 				'kru' => 'Kurukh dili',
 				'ks' => 'Keşmir dili',
 				'ksb' => 'Şambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Köln lehçesi',
 				'ku' => 'Kürtçe',
 				'kum' => 'Kumukça',
 				'kut' => 'Kutenai dili',
 				'kv' => 'Komi',
 				'kw' => 'Kernevekçe',
 				'kwk' => 'Kwakʼwala dili',
 				'kxv' => 'Kuvi',
 				'ky' => 'Kırgızca',
 				'la' => 'Latince',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba dili',
 				'lb' => 'Lüksemburgca',
 				'lez' => 'Lezgice',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'Ganda',
 				'li' => 'Limburgca',
 				'lij' => 'Ligurca',
 				'lil' => 'Lillooet dili',
 				'liv' => 'Livonca',
 				'lkt' => 'Lakotaca',
 				'lmo' => 'Lombardça',
 				'ln' => 'Lingala',
 				'lo' => 'Lao dili',
 				'lol' => 'Mongo',
 				'lou' => 'Louisiana Kreolcesi',
 				'loz' => 'Lozi',
 				'lrc' => 'Kuzey Luri',
 				'lsm' => 'Samia dili',
 				'lt' => 'Litvanca',
 				'ltg' => 'Latgalian',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Lushai',
 				'luy' => 'Luyia',
 				'lv' => 'Letonca',
 				'lzh' => 'Edebi Çince',
 				'lzz' => 'Lazca',
 				'mad' => 'Madura Dili',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'man' => 'Mandingo',
 				'mas' => 'Masai',
 				'mde' => 'Maba',
 				'mdf' => 'Mokşa dili',
 				'mdr' => 'Mandar',
 				'men' => 'Mende dili',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malgaşça',
 				'mga' => 'Ortaçağ İrlandacası',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshall Adaları dili',
 				'mi' => 'Maori dili',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Makedonca',
 				'ml' => 'Malayalam dili',
 				'mn' => 'Moğolca',
 				'mnc' => 'Mançurya dili',
 				'mni' => 'Manipuri dili',
 				'moe' => 'Doğu İnnucası',
 				'moh' => 'Mohavk dili',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi dili',
 				'mrj' => 'Ova Çirmişçesi',
 				'ms' => 'Malayca',
 				'mt' => 'Maltaca',
 				'mua' => 'Mundang',
 				'mul' => 'Birden Fazla Dil',
 				'mus' => 'Krikçe',
 				'mwl' => 'Miranda dili',
 				'mwr' => 'Marvari',
 				'mwv' => 'Mentawai',
 				'my' => 'Birman dili',
 				'mye' => 'Myene',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazenderanca',
 				'na' => 'Nauru dili',
 				'nan' => 'Min Nan Çincesi',
 				'nap' => 'Napolice',
 				'naq' => 'Nama',
 				'nb' => 'Norveççe Bokmål',
 				'nd' => 'Kuzey Ndebele',
 				'nds' => 'Aşağı Almanca',
 				'nds_NL' => 'Aşağı Saksonca',
 				'ne' => 'Nepalce',
 				'new' => 'Nevari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niue dili',
 				'njo' => 'Ao Naga',
 				'nl' => 'Felemenkçe',
 				'nl_BE' => 'Flamanca',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norveççe Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norveççe',
 				'nog' => 'Nogayca',
 				'non' => 'Eski Nors dili',
 				'nov' => 'Novial',
 				'nqo' => 'N’Ko',
 				'nr' => 'Güney Ndebele',
 				'nso' => 'Kuzey Sotho dili',
 				'nus' => 'Nuer',
 				'nv' => 'Navaho dili',
 				'nwc' => 'Klasik Nevari',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamvezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima dili',
 				'oc' => 'Oksitan dili',
 				'oj' => 'Ojibva dili',
 				'ojb' => 'Kuzeybatı Ojibwe dili',
 				'ojc' => 'Orta Ojibwe dili',
 				'ojs' => 'Anişininice',
 				'ojw' => 'Batı Ojibwe dili',
 				'oka' => 'Okanagan dili',
 				'om' => 'Oromo dili',
 				'or' => 'Oriya dili',
 				'os' => 'Osetçe',
 				'osa' => 'Osage',
 				'ota' => 'Osmanlı Türkçesi',
 				'pa' => 'Pencapça',
 				'pag' => 'Pangasinan dili',
 				'pal' => 'Pehlevi Dili',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palau dili',
 				'pcd' => 'Picard Dili',
 				'pcm' => 'Nijerya Pidgin dili',
 				'pdc' => 'Pensilvanya Almancası',
 				'pdt' => 'Plautdietsch',
 				'peo' => 'Eski Farsça',
 				'pfl' => 'Palatin Almancası',
 				'phn' => 'Fenike dili',
 				'pi' => 'Pali',
 				'pis' => 'Pijin dili',
 				'pl' => 'Lehçe',
 				'pms' => 'Piyemontece',
 				'pnt' => 'Kuzeybatı Kafkasya',
 				'pon' => 'Pohnpeian',
 				'pqm' => 'Malisetçe-Passamaquoddy',
 				'prg' => 'Prusyaca',
 				'pro' => 'Eski Provensal',
 				'ps' => 'Peştuca',
 				'pt' => 'Portekizce',
 				'pt_BR' => 'Brezilya Portekizcesi',
 				'pt_PT' => 'Avrupa Portekizcesi',
 				'qu' => 'Keçuva dili',
 				'quc' => 'Kiçece',
 				'qug' => 'Chimborazo Highland Quichua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui dili',
 				'rar' => 'Rarotongan',
 				'rgn' => 'Romanyolca',
 				'rhg' => 'Rohingya dili',
 				'rif' => 'Rif Berbericesi',
 				'rm' => 'Romanşça',
 				'rn' => 'Kirundi',
 				'ro' => 'Rumence',
 				'ro_MD' => 'Moldovaca',
 				'rof' => 'Rombo',
 				'rom' => 'Romanca',
 				'rtm' => 'Rotuman',
 				'ru' => 'Rusça',
 				'rue' => 'Rusince',
 				'rug' => 'Roviana',
 				'rup' => 'Ulahça',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandave',
 				'sah' => 'Yakutça',
 				'sam' => 'Samarit Aramcası',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'saz' => 'Saurashtra',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardunya dili',
 				'scn' => 'Sicilyaca',
 				'sco' => 'İskoçça',
 				'sd' => 'Sindhi dili',
 				'sdc' => 'Sassari Sarduca',
 				'sdh' => 'Güney Kürtçesi',
 				'se' => 'Kuzey Laponcası',
 				'see' => 'Seneca dili',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkup dili',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Eski İrlandaca',
 				'sgs' => 'Samogitçe',
 				'sh' => 'Sırp-Hırvat Dili',
 				'shi' => 'Taşelit',
 				'shn' => 'Shan dili',
 				'shu' => 'Çad Arapçası',
 				'si' => 'Sinhali dili',
 				'sid' => 'Sidamo dili',
 				'sk' => 'Slovakça',
 				'sl' => 'Slovence',
 				'slh' => 'Güney Lushootseed',
 				'sli' => 'Aşağı Silezyaca',
 				'sly' => 'Selayar',
 				'sm' => 'Samoa dili',
 				'sma' => 'Güney Laponcası',
 				'smj' => 'Lule Laponcası',
 				'smn' => 'İnari Laponcası',
 				'sms' => 'Skolt Laponcası',
 				'sn' => 'Şona dili',
 				'snk' => 'Soninke',
 				'so' => 'Somalice',
 				'sog' => 'Sogdiana Dili',
 				'sq' => 'Arnavutça',
 				'sr' => 'Sırpça',
 				'srn' => 'Sranan Tongo',
 				'srr' => 'Serer dili',
 				'ss' => 'Sisvati',
 				'ssy' => 'Saho',
 				'st' => 'Güney Sotho dili',
 				'stq' => 'Saterland Frizcesi',
 				'str' => 'Boğazlar Saliş dili',
 				'su' => 'Sunda dili',
 				'suk' => 'Sukuma dili',
 				'sus' => 'Susu',
 				'sux' => 'Sümerce',
 				'sv' => 'İsveççe',
 				'sw' => 'Svahili dili',
 				'sw_CD' => 'Kongo Svahili',
 				'swb' => 'Komorca',
 				'syc' => 'Klasik Süryanice',
 				'syr' => 'Süryanice',
 				'szl' => 'Silezyaca',
 				'ta' => 'Tamilce',
 				'tce' => 'Güney Tuçoncası',
 				'tcy' => 'Tuluca',
 				'te' => 'Telugu dili',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetum',
 				'tg' => 'Tacikçe',
 				'tgx' => 'Tagişçe',
 				'th' => 'Tayca',
 				'tht' => 'Tahltanca',
 				'ti' => 'Tigrinya dili',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Türkmence',
 				'tkl' => 'Tokelau dili',
 				'tkr' => 'Sahurca',
 				'tl' => 'Tagalogca',
 				'tlh' => 'Klingonca',
 				'tli' => 'Tlingitçe',
 				'tly' => 'Talışça',
 				'tmh' => 'Tamaşek',
 				'tn' => 'Setsvana',
 				'to' => 'Tonga dili',
 				'tog' => 'Nyasa Tonga',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Türkçe',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonca',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tatarca',
 				'ttm' => 'Kuzey Tuçoncası',
 				'ttt' => 'Tatça',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalyanca',
 				'tw' => 'Tvi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahiti dili',
 				'tyv' => 'Tuvaca',
 				'tzm' => 'Orta Atlas Tamazigti',
 				'udm' => 'Udmurtça',
 				'ug' => 'Uygurca',
 				'uga' => 'Ugarit dili',
 				'uk' => 'Ukraynaca',
 				'umb' => 'Umbundu',
 				'und' => 'Bilinmeyen Dil',
 				'ur' => 'Urduca',
 				'uz' => 'Özbekçe',
 				'vai' => 'Vai',
 				've' => 'Venda dili',
 				'vec' => 'Venedikçe',
 				'vep' => 'Veps dili',
 				'vi' => 'Vietnamca',
 				'vls' => 'Batı Flamanca',
 				'vmf' => 'Main Frankonya Dili',
 				'vmw' => 'Makuaca',
 				'vo' => 'Volapük',
 				'vot' => 'Votça',
 				'vro' => 'Võro',
 				'vun' => 'Vunjo',
 				'wa' => 'Valonca',
 				'wae' => 'Walser',
 				'wal' => 'Valamo',
 				'war' => 'Varay',
 				'was' => 'Vaşo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Volofça',
 				'wuu' => 'Wu Çincesi',
 				'xal' => 'Kalmıkça',
 				'xh' => 'Zosa dili',
 				'xmf' => 'Megrelce',
 				'xnr' => 'Kangrice',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapça',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yidiş',
 				'yo' => 'Yorubaca',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonca',
 				'yue@alt=menu' => 'Çince, Kantonca',
 				'za' => 'Zhuangca',
 				'zap' => 'Zapotek dili',
 				'zbl' => 'Blis Sembolleri',
 				'zea' => 'Zelandaca',
 				'zen' => 'Zenaga dili',
 				'zgh' => 'Standart Fas Tamazigti',
 				'zh' => 'Çince',
 				'zh@alt=menu' => 'Çince, Mandarin',
 				'zh_Hans' => 'Basitleştirilmiş Çince',
 				'zh_Hans@alt=long' => 'Basitleştirilmiş Çince (Mandarin)',
 				'zh_Hant' => 'Geleneksel Çince',
 				'zh_Hant@alt=long' => 'Geleneksel Çince (Mandarin)',
 				'zu' => 'Zuluca',
 				'zun' => 'Zunice',
 				'zxx' => 'Dilbilim içeriği yok',
 				'zza' => 'Zazaca',

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
 			'Afak' => 'Afaka',
 			'Aghb' => 'Kafkas Albanyası',
 			'Arab' => 'Arap',
 			'Arab@alt=variant' => 'Fars-Arap',
 			'Aran' => 'Nestâlik',
 			'Armi' => 'İmparatorluk Aramicesi',
 			'Armn' => 'Ermeni',
 			'Avst' => 'Avesta',
 			'Bali' => 'Bali Dili',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bengal',
 			'Blis' => 'Blis Sembolleri',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Bugis',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'UCAS',
 			'Cari' => 'Karya',
 			'Cher' => 'Çeroki',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Kıpti',
 			'Cprt' => 'Kıbrıs',
 			'Cyrl' => 'Kiril',
 			'Cyrs' => 'Eski Kilise Slavcası Kiril',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployé Stenografi',
 			'Egyd' => 'Demotik Mısır',
 			'Egyh' => 'Hiyeratik Mısır',
 			'Egyp' => 'Mısır Hiyeroglifleri',
 			'Elba' => 'Elbasan',
 			'Ethi' => 'Etiyopya',
 			'Geok' => 'Hutsuri Gürcü',
 			'Geor' => 'Gürcü',
 			'Glag' => 'Glagolit',
 			'Goth' => 'Gotik',
 			'Gran' => 'Grantha',
 			'Grek' => 'Yunan',
 			'Gujr' => 'Gücerat',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han - Bopomofo',
 			'Hang' => 'Hangıl',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Basitleştirilmiş',
 			'Hans@alt=stand-alone' => 'Basitleştirilmiş Han',
 			'Hant' => 'Geleneksel',
 			'Hant@alt=stand-alone' => 'Geleneksel Han',
 			'Hebr' => 'İbrani',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Anadolu Hiyeroglifleri',
 			'Hmng' => 'Pahavh Hmong',
 			'Hrkt' => 'Japon hece alfabeleri',
 			'Hung' => 'Eski Macar',
 			'Inds' => 'Indus',
 			'Ital' => 'Eski İtalyan',
 			'Java' => 'Cava Dili',
 			'Jpan' => 'Japon',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Kmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korece',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Lao',
 			'Latf' => 'Fraktur Latin',
 			'Latg' => 'Gael Latin',
 			'Latn' => 'Latin',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Lineer A',
 			'Linb' => 'Lineer B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Likya',
 			'Lydi' => 'Lidya',
 			'Mahj' => 'Mahajani',
 			'Mand' => 'Manden',
 			'Mani' => 'Maniheist',
 			'Maya' => 'Maya Hiyeroglifleri',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitik El Yazısı',
 			'Mero' => 'Meroitik',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Moğol',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Burma',
 			'Narb' => 'Eski Kuzey Arap',
 			'Nbat' => 'Nebati',
 			'Nkgb' => 'Naksi Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orhun',
 			'Orya' => 'Oriya',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmira',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Eski Permik',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Pehlevi Kitabe Dili',
 			'Phlp' => 'Psalter Pehlevi',
 			'Phlv' => 'Kitap Pehlevi Dili',
 			'Phnx' => 'Fenike',
 			'Plrd' => 'Pollard Fonetik',
 			'Prti' => 'Partça Kitabe Dili',
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runik',
 			'Samr' => 'Samarit',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Eski Güney Arap',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'İşaret Dili',
 			'Shaw' => 'Shavian',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudabadi',
 			'Sinh' => 'Seylan',
 			'Sora' => 'Sora Sompeng',
 			'Sund' => 'Sunda',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Süryani',
 			'Syre' => 'Estrangela Süryani',
 			'Syrj' => 'Batı Süryani',
 			'Syrn' => 'Doğu Süryani',
 			'Tagb' => 'Tagbanva',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'New Tai Lue',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengvar',
 			'Tfng' => 'Tifinag',
 			'Tglg' => 'Takalot',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Tay',
 			'Tibt' => 'Tibet',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugarit Çivi Yazısı',
 			'Vaii' => 'Vai',
 			'Visp' => 'Konuşma Sesleri Çizimlemesi',
 			'Wara' => 'Varang Kshiti',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Eski Fars',
 			'Xsux' => 'Sümer-Akad Çivi Yazısı',
 			'Yiii' => 'Yi',
 			'Zinh' => 'Kalıtsal',
 			'Zmth' => 'Matematiksel Gösterim',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Sembol',
 			'Zxxx' => 'Yazılı Olmayan',
 			'Zyyy' => 'Ortak',
 			'Zzzz' => 'Bilinmeyen Alfabe',

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
			'001' => 'Dünya',
 			'002' => 'Afrika',
 			'003' => 'Kuzey Amerika',
 			'005' => 'Güney Amerika',
 			'009' => 'Okyanusya',
 			'011' => 'Batı Afrika',
 			'013' => 'Orta Amerika',
 			'014' => 'Doğu Afrika',
 			'015' => 'Kuzey Afrika',
 			'017' => 'Orta Afrika',
 			'018' => 'Afrika’nın Güneyi',
 			'019' => 'Amerika',
 			'021' => 'Amerika’nın Kuzeyi',
 			'029' => 'Karayipler',
 			'030' => 'Doğu Asya',
 			'034' => 'Güney Asya',
 			'035' => 'Güneydoğu Asya',
 			'039' => 'Güney Avrupa',
 			'053' => 'Avustralasya',
 			'054' => 'Melanezya',
 			'057' => 'Mikronezya Bölgesi',
 			'061' => 'Polinezya',
 			'142' => 'Asya',
 			'143' => 'Orta Asya',
 			'145' => 'Batı Asya',
 			'150' => 'Avrupa',
 			'151' => 'Doğu Avrupa',
 			'154' => 'Kuzey Avrupa',
 			'155' => 'Batı Avrupa',
 			'202' => 'Sahra Altı Afrika',
 			'419' => 'Latin Amerika',
 			'AC' => 'Ascension Adası',
 			'AD' => 'Andorra',
 			'AE' => 'Birleşik Arap Emirlikleri',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua ve Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Arnavutluk',
 			'AM' => 'Ermenistan',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Arjantin',
 			'AS' => 'Amerikan Samoası',
 			'AT' => 'Avusturya',
 			'AU' => 'Avustralya',
 			'AW' => 'Aruba',
 			'AX' => 'Åland Adaları',
 			'AZ' => 'Azerbaycan',
 			'BA' => 'Bosna-Hersek',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeş',
 			'BE' => 'Belçika',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaristan',
 			'BH' => 'Bahreyn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthelemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivya',
 			'BQ' => 'Karayip Hollandası',
 			'BR' => 'Brezilya',
 			'BS' => 'Bahamalar',
 			'BT' => 'Butan',
 			'BV' => 'Bouvet Adası',
 			'BW' => 'Botsvana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Cocos (Keeling) Adaları',
 			'CD' => 'Kongo - Kinşasa',
 			'CD@alt=variant' => 'Kongo Demokratik Cumhuriyeti',
 			'CF' => 'Orta Afrika Cumhuriyeti',
 			'CG' => 'Kongo - Brazavil',
 			'CG@alt=variant' => 'Kongo Cumhuriyeti',
 			'CH' => 'İsviçre',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Fildişi Sahili',
 			'CK' => 'Cook Adaları',
 			'CL' => 'Şili',
 			'CM' => 'Kamerun',
 			'CN' => 'Çin',
 			'CO' => 'Kolombiya',
 			'CP' => 'Clipperton Adası',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Küba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmas Adası',
 			'CY' => 'Kıbrıs',
 			'CZ' => 'Çekya',
 			'CZ@alt=variant' => 'Çek Cumhuriyeti',
 			'DE' => 'Almanya',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Cibuti',
 			'DK' => 'Danimarka',
 			'DM' => 'Dominika',
 			'DO' => 'Dominik Cumhuriyeti',
 			'DZ' => 'Cezayir',
 			'EA' => 'Ceuta ve Melilla',
 			'EC' => 'Ekvador',
 			'EE' => 'Estonya',
 			'EG' => 'Mısır',
 			'EH' => 'Batı Sahra',
 			'ER' => 'Eritre',
 			'ES' => 'İspanya',
 			'ET' => 'Etiyopya',
 			'EU' => 'Avrupa Birliği',
 			'EZ' => 'Euro Bölgesi',
 			'FI' => 'Finlandiya',
 			'FJ' => 'Fiji',
 			'FK' => 'Falkland Adaları',
 			'FK@alt=variant' => 'Falkland Adaları (Malvinas Adaları)',
 			'FM' => 'Mikronezya',
 			'FO' => 'Faroe Adaları',
 			'FR' => 'Fransa',
 			'GA' => 'Gabon',
 			'GB' => 'Birleşik Krallık',
 			'GB@alt=short' => 'BK',
 			'GD' => 'Grenada',
 			'GE' => 'Gürcistan',
 			'GF' => 'Fransız Guyanası',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Cebelitarık',
 			'GL' => 'Grönland',
 			'GM' => 'Gambiya',
 			'GN' => 'Gine',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvator Ginesi',
 			'GR' => 'Yunanistan',
 			'GS' => 'Güney Georgia ve Güney Sandwich Adaları',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gine-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Çin Hong Kong ÖİB',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard Adası ve McDonald Adaları',
 			'HN' => 'Honduras',
 			'HR' => 'Hırvatistan',
 			'HT' => 'Haiti',
 			'HU' => 'Macaristan',
 			'IC' => 'Kanarya Adaları',
 			'ID' => 'Endonezya',
 			'IE' => 'İrlanda',
 			'IL' => 'İsrail',
 			'IM' => 'Man Adası',
 			'IN' => 'Hindistan',
 			'IO' => 'Britanya Hint Okyanusu Toprakları',
 			'IO@alt=chagos' => 'Chagos Takımadaları',
 			'IQ' => 'Irak',
 			'IR' => 'İran',
 			'IS' => 'İzlanda',
 			'IT' => 'İtalya',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Ürdün',
 			'JP' => 'Japonya',
 			'KE' => 'Kenya',
 			'KG' => 'Kırgızistan',
 			'KH' => 'Kamboçya',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorlar',
 			'KN' => 'Saint Kitts ve Nevis',
 			'KP' => 'Kuzey Kore',
 			'KR' => 'Güney Kore',
 			'KW' => 'Kuveyt',
 			'KY' => 'Cayman Adaları',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Laos',
 			'LB' => 'Lübnan',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberya',
 			'LS' => 'Lesotho',
 			'LT' => 'Litvanya',
 			'LU' => 'Lüksemburg',
 			'LV' => 'Letonya',
 			'LY' => 'Libya',
 			'MA' => 'Fas',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Karadağ',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshall Adaları',
 			'MK' => 'Kuzey Makedonya',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Moğolistan',
 			'MO' => 'Çin Makao ÖİB',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Kuzey Mariana Adaları',
 			'MQ' => 'Martinik',
 			'MR' => 'Moritanya',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivler',
 			'MW' => 'Malavi',
 			'MX' => 'Meksika',
 			'MY' => 'Malezya',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibya',
 			'NC' => 'Yeni Kaledonya',
 			'NE' => 'Nijer',
 			'NF' => 'Norfolk Adası',
 			'NG' => 'Nijerya',
 			'NI' => 'Nikaragua',
 			'NL' => 'Hollanda',
 			'NO' => 'Norveç',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Yeni Zelanda',
 			'NZ@alt=variant' => 'Aotearoa Yeni Zelanda',
 			'OM' => 'Umman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransız Polinezyası',
 			'PG' => 'Papua Yeni Gine',
 			'PH' => 'Filipinler',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonya',
 			'PM' => 'Saint Pierre ve Miquelon',
 			'PN' => 'Pitcairn Adaları',
 			'PR' => 'Porto Riko',
 			'PS' => 'Filistin Bölgeleri',
 			'PS@alt=short' => 'Filistin',
 			'PT' => 'Portekiz',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Uzak Okyanusya',
 			'RE' => 'Reunion',
 			'RO' => 'Romanya',
 			'RS' => 'Sırbistan',
 			'RU' => 'Rusya',
 			'RW' => 'Ruanda',
 			'SA' => 'Suudi Arabistan',
 			'SB' => 'Solomon Adaları',
 			'SC' => 'Seyşeller',
 			'SD' => 'Sudan',
 			'SE' => 'İsveç',
 			'SG' => 'Singapur',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenya',
 			'SJ' => 'Svalbard ve Jan Mayen',
 			'SK' => 'Slovakya',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somali',
 			'SR' => 'Surinam',
 			'SS' => 'Güney Sudan',
 			'ST' => 'Sao Tome ve Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Suriye',
 			'SZ' => 'Esvatini',
 			'SZ@alt=variant' => 'Svaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks ve Caicos Adaları',
 			'TD' => 'Çad',
 			'TF' => 'Fransız Güney Toprakları',
 			'TG' => 'Togo',
 			'TH' => 'Tayland',
 			'TJ' => 'Tacikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Doğu Timor',
 			'TM' => 'Türkmenistan',
 			'TN' => 'Tunus',
 			'TO' => 'Tonga',
 			'TR' => 'Türkiye',
 			'TT' => 'Trinidad ve Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayvan',
 			'TZ' => 'Tanzanya',
 			'UA' => 'Ukrayna',
 			'UG' => 'Uganda',
 			'UM' => 'ABD Küçük Harici Adaları',
 			'UN' => 'Birleşmiş Milletler',
 			'UN@alt=short' => 'BM',
 			'US' => 'Amerika Birleşik Devletleri',
 			'US@alt=short' => 'ABD',
 			'UY' => 'Uruguay',
 			'UZ' => 'Özbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Saint Vincent ve Grenadinler',
 			'VE' => 'Venezuela',
 			'VG' => 'Britanya Virjin Adaları',
 			'VI' => 'ABD Virjin Adaları',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ve Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Psödo Aksanlar',
 			'XB' => 'Psödo Bidi',
 			'XK' => 'Kosova',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Güney Afrika',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Bilinmeyen Bölge',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Geleneksel Almanca Yazım Kuralları',
 			'1994' => 'Standart Resia Yazım Kuralları',
 			'1996' => '1996 Almanca Yazım Kuralları',
 			'1606NICT' => '1606‘ya Dek Geç Ortaçağ Fransızcası',
 			'1694ACAD' => 'Erken Modern Fransızca',
 			'1959ACAD' => 'Akademik',
 			'AREVELA' => 'Doğu Ermenicesi',
 			'AREVMDA' => 'Batı Ermenicesi',
 			'BAKU1926' => 'Birleştirilmiş Yeni Türk Alfabesi',
 			'BISKE' => 'San Giorgio/Bila Lehçesi',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'IPA Ses Bilimi',
 			'FONUPA' => 'UPA Ses Bilimi',
 			'KKCOR' => 'Ortak Yazım Kuralları',
 			'LIPAW' => 'Resia Lipovaz Lehçesi',
 			'MONOTON' => 'Monotonik',
 			'NEDIS' => 'Natisone Lehçesi',
 			'NJIVA' => 'Gniva/Njiva Lehçesi',
 			'OSOJS' => 'Oseacco/Osojane Lehçesi',
 			'PINYIN' => 'Pinyin (Latin Alfabesinde Yazımı)',
 			'POLYTON' => 'Politonik',
 			'POSIX' => 'Bilgisayar',
 			'REVISED' => 'Gözden Geçirilmiş Yazım Kuralları',
 			'ROZAJ' => 'Resia Lehçesi',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Standart İskoç İngilizcesi',
 			'SCOUSE' => 'Scouse',
 			'SOLBA' => 'Stolvizza/Solbica Lehçesi',
 			'TARASK' => 'Taraskievica Yazım Kuralları',
 			'UCCOR' => 'Birleştirilmiş Yazım Kuralları',
 			'UCRCOR' => 'Gözden Geçirilmiş Birleştirilmiş Yazım Kuralları',
 			'VALENCIA' => 'Valensiyaca',
 			'WADEGILE' => 'Wade-Giles (Latin Alfabesinde Yazımı)',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Takvim',
 			'cf' => 'Para Birimi Biçimi',
 			'colalternate' => 'Sembolleri Sıralamayı Yoksayma',
 			'colbackwards' => 'Ters Aksan Sıralama',
 			'colcasefirst' => 'Büyük/Küçük Harf Sıralama',
 			'colcaselevel' => 'Büyük/Küçük Harfe Duyarlı Sıralama',
 			'collation' => 'Sıralama Düzeni',
 			'colnormalization' => 'Normalleştirilmiş Sıralama',
 			'colnumeric' => 'Sayısal Sıralama',
 			'colstrength' => 'Sıralama Gücü',
 			'currency' => 'Para Birimi',
 			'hc' => 'Saat Sistemi (12 - 24)',
 			'lb' => 'Satır Sonu Stili',
 			'ms' => 'Ölçü Sistemi',
 			'numbers' => 'Rakamlar',
 			'timezone' => 'Saat Dilimi',
 			'va' => 'Yerel Varyant',
 			'x' => 'Özel Kullanım',

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
 				'buddhist' => q{Budist Takvimi},
 				'chinese' => q{Çin Takvimi},
 				'coptic' => q{Kıpti Takvim},
 				'dangi' => q{Dangi Takvimi},
 				'ethiopic' => q{Etiyopik Takvim},
 				'ethiopic-amete-alem' => q{Etiyopik Amete Alem Takvimi},
 				'gregorian' => q{Miladi Takvim},
 				'hebrew' => q{İbrani Takvimi},
 				'indian' => q{Ulusal Hint Takvimi},
 				'islamic' => q{Hicri Takvim},
 				'islamic-civil' => q{Hicri Takvim (16 Temmuz 622)},
 				'islamic-rgsa' => q{Hicri Takvim (Suudi)},
 				'islamic-tbla' => q{Hicri Takvim (15 Temmuz 622)},
 				'islamic-umalqura' => q{Hicri Takvim (Ümmü-l Kurra Takvimi)},
 				'iso8601' => q{ISO-8601 Takvimi},
 				'japanese' => q{Japon Takvimi},
 				'persian' => q{İran Takvimi},
 				'roc' => q{Çin Cumhuriyeti Takvimi},
 			},
 			'cf' => {
 				'account' => q{Muhasebe Para Biçimi},
 				'standard' => q{Standart Para Biçimi},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sembolleri Sıralama},
 				'shifted' => q{Sembolleri Yoksayarak Sıralama},
 			},
 			'colbackwards' => {
 				'no' => q{Aksanları Normal Olarak Sıralama},
 				'yes' => q{Aksanları Ters Sıralama},
 			},
 			'colcasefirst' => {
 				'lower' => q{Önce Küçük Harfleri Sıralama},
 				'no' => q{Normal Büyük/Küçük Harf Düzeninde Sıralama},
 				'upper' => q{Önce Büyük Harfleri Sıralama},
 			},
 			'colcaselevel' => {
 				'no' => q{Büyük/Küçük Harfe Duyarlı Olmadan Sıralama},
 				'yes' => q{Büyük/Küçük Harfe Duyarla Sıralama},
 			},
 			'collation' => {
 				'big5han' => q{Geleneksel Çince Sıralama Düzeni - Big5},
 				'compat' => q{Önceki Sıralama Düzeni (uyumluluk için)},
 				'dictionary' => q{Sözlük Sıralama Düzeni},
 				'ducet' => q{Saptanmış Unicode Sıralama Düzeni},
 				'emoji' => q{Emoji Sıralama Düzeni},
 				'eor' => q{Avrupa Sıralama Kuralları},
 				'gb2312han' => q{Basitleştirilmiş Çince Sıralama Düzeni - GB2312},
 				'phonebook' => q{Telefon Defteri Sıralama Düzeni},
 				'phonetic' => q{Fonetik Sıralama Düzeni},
 				'pinyin' => q{Pinyin Sıralama Düzeni},
 				'search' => q{Genel Amaçlı Arama},
 				'searchjl' => q{Hangul İlk Sessiz Harfe Göre Arama},
 				'standard' => q{Standart Sıralama Düzeni},
 				'stroke' => q{Vuruş Sıralama Düzeni},
 				'traditional' => q{Geleneksel Sıralama Düzeni},
 				'unihan' => q{Radikal-Vuruş Sıralama Düzeni},
 				'zhuyin' => q{Zhuyin Sıralama Düzeni},
 			},
 			'colnormalization' => {
 				'no' => q{Normalleştirme Olmadan Sıralama},
 				'yes' => q{Unicode Normalleştirilmiş Olarak Sıralama},
 			},
 			'colnumeric' => {
 				'no' => q{Rakamları Ayrı Sıralama},
 				'yes' => q{Rakamları Sayısal Olarak Sıralama},
 			},
 			'colstrength' => {
 				'identical' => q{Tümünü Sıralama},
 				'primary' => q{Yalnızca Taban Harflerini Sıralama},
 				'quaternary' => q{Aksanları/Büyük-Küçük Harfleri/Genişliği/Kana’yı Sıralama},
 				'secondary' => q{Aksanları Sıralama},
 				'tertiary' => q{Aksanları/Büyük-Küçük Harfleri/Genişliği Sıralama},
 			},
 			'd0' => {
 				'fwidth' => q{Tam Genişlik},
 				'hwidth' => q{Yarım genişlik},
 				'npinyin' => q{Rakam},
 			},
 			'hc' => {
 				'h11' => q{12 Saat Sistemi (0–11)},
 				'h12' => q{12 Saat Sistemi (1–12)},
 				'h23' => q{24 Saat Sistemi (0–23)},
 				'h24' => q{24 Saat Sistemi (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Serbest Satır Sonu Stili},
 				'normal' => q{Normal Satır Sonu Stili},
 				'strict' => q{Katı Satır Sonu Stili},
 			},
 			'm0' => {
 				'bgn' => q{US BGN Transliterasyon},
 				'ungegn' => q{UN GEGN Transliterasyon},
 			},
 			'ms' => {
 				'metric' => q{Metrik Sistem},
 				'uksystem' => q{İngiliz Ölçü Sistemi},
 				'ussystem' => q{ABD Ölçü Sistemi},
 			},
 			'numbers' => {
 				'ahom' => q{Ahom Rakamları},
 				'arab' => q{Hint-Arap Rakamları},
 				'arabext' => q{Genişletilmiş Hint-Arap Rakamları},
 				'armn' => q{Ermeni Rakamları},
 				'armnlow' => q{Küçük Harf Ermeni Rakamları},
 				'bali' => q{Bali Rakamları},
 				'beng' => q{Bengal Rakamları},
 				'brah' => q{Brahmi Rakamları},
 				'cakm' => q{Chakma Rakamları},
 				'cham' => q{Cham Rakamları},
 				'cyrl' => q{Kiril Rakamları},
 				'deva' => q{Devanagari Rakamları},
 				'ethi' => q{Ge’ez Rakamları},
 				'finance' => q{Finansal Sayılar},
 				'fullwide' => q{Tam Genişlikte Rakamlar},
 				'geor' => q{Gürcü Rakamları},
 				'gonm' => q{Masaram Gondi Rakamları},
 				'grek' => q{Yunan Rakamları},
 				'greklow' => q{Küçük Harf Yunan Rakamları},
 				'gujr' => q{Gücerat Rakamları},
 				'guru' => q{Gurmukhi Rakamları},
 				'hanidec' => q{Çin Ondalık Rakamları},
 				'hans' => q{Basitleştirilmiş Çin Rakamları},
 				'hansfin' => q{Finansal Basitleştirilmiş Çin Rakamları},
 				'hant' => q{Geleneksel Çin Rakamları},
 				'hantfin' => q{Finansal Geleneksel Çin Rakamları},
 				'hebr' => q{İbrani Rakamları},
 				'hmng' => q{Pahawh Hmong Rakamları},
 				'java' => q{Cava Rakamları},
 				'jpan' => q{Japon Rakamları},
 				'jpanfin' => q{Finansal Japon Rakamları},
 				'kali' => q{Kayah Li Rakamları},
 				'khmr' => q{Kmer Rakamları},
 				'knda' => q{Kannada Rakamları},
 				'lana' => q{Tai Tham Hora Rakamları},
 				'lanatham' => q{Tai Tham Tham Rakamları},
 				'laoo' => q{Lao Rakamları},
 				'latn' => q{Batı Rakamları},
 				'lepc' => q{Lepça Rakamları},
 				'limb' => q{Limbu Rakamları},
 				'mathbold' => q{Kalın Matematiksel Rakamlar},
 				'mathdbl' => q{Çift Çizgili Matematiksel Rakamlar},
 				'mathmono' => q{Eşit Aralıklı Matematiksel Rakamlar},
 				'mathsanb' => q{Kalın Sans Serif Matematiksel Rakamlar},
 				'mathsans' => q{Sans Serif Matematiksel Rakamlar},
 				'mlym' => q{Malayalam Rakamları},
 				'modi' => q{Modi Rakamları},
 				'mong' => q{Moğolca Rakamlar},
 				'mroo' => q{Mro Rakamları},
 				'mtei' => q{Meetei Mayek Rakamları},
 				'mymr' => q{Myanmar Rakamları},
 				'mymrshan' => q{Myanmar Shan Rakamları},
 				'mymrtlng' => q{Myanmar Tai Laing Rakamları},
 				'native' => q{Yerel Rakamlar},
 				'nkoo' => q{N’Ko Rakamları},
 				'olck' => q{Ol Chiki Rakamları},
 				'orya' => q{Oriya Rakamları},
 				'osma' => q{Osmanya Rakamları},
 				'roman' => q{Roma Rakamları},
 				'romanlow' => q{Küçük Harf Roma Rakamları},
 				'saur' => q{Saurashtra Rakamları},
 				'shrd' => q{Sharada Rakamları},
 				'sind' => q{Khudawadi Rakamları},
 				'sinh' => q{Sinhala Lith Rakamları},
 				'sora' => q{Sora Sompeng Rakamları},
 				'sund' => q{Sunda Rakamları},
 				'takr' => q{Takri Basamakları},
 				'talu' => q{New Tai Lue Rakamları},
 				'taml' => q{Geleneksel Tamil Rakamları},
 				'tamldec' => q{Tamil Rakamları},
 				'telu' => q{Telugu Rakamları},
 				'thai' => q{Tay Rakamları},
 				'tibt' => q{Tibet Rakamları},
 				'tirh' => q{Tirhuta Rakamları},
 				'traditional' => q{Geleneksel Rakamlar},
 				'vaii' => q{Vai Rakamları},
 				'wara' => q{Warang Citi Rakamları},
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
			'metric' => q{Metrik},
 			'UK' => q{İngiliz},
 			'US' => q{Amerikan},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Dil: {0}',
 			'script' => 'Alfabe: {0}',
 			'region' => 'Bölge: {0}',

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
			auxiliary => qr{[áàăâåäãā æ éèĕêëē íìĭîïī ñ óòŏôøō œ q ß úùŭûū w x ÿ]},
			index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'H', 'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c ç d e f g ğ h ı iİ j k l m n o ö p r s ş t u ü v y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'H', 'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(ana yön),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ana yön),
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
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
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
						'1' => q(santi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(santi{0}),
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
						'one' => q({0} g kuvveti),
						'other' => q({0} g kuvveti),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g kuvveti),
						'other' => q({0} g kuvveti),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metre/saniye²),
						'one' => q({0} metre/saniye²),
						'other' => q({0} metre/saniye²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metre/saniye²),
						'one' => q({0} metre/saniye²),
						'other' => q({0} metre/saniye²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(açısal dakika),
						'one' => q({0} açısal dakika),
						'other' => q({0} açısal dakika),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(açısal dakika),
						'one' => q({0} açısal dakika),
						'other' => q({0} açısal dakika),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(açısal saniye),
						'one' => q({0} açısal saniye),
						'other' => q({0} açısal saniye),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(açısal saniye),
						'one' => q({0} açısal saniye),
						'other' => q({0} açısal saniye),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} derece),
						'other' => q({0} derece),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} derece),
						'other' => q({0} derece),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radyan),
						'other' => q({0} radyan),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radyan),
						'other' => q({0} radyan),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(devir),
						'one' => q({0} devir),
						'other' => q({0} devir),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(devir),
						'one' => q({0} devir),
						'other' => q({0} devir),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(santimetrekare),
						'one' => q({0} santimetrekare),
						'other' => q({0} santimetrekare),
						'per' => q({0}/santimetrekare),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(santimetrekare),
						'one' => q({0} santimetrekare),
						'other' => q({0} santimetrekare),
						'per' => q({0}/santimetrekare),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(fit kare),
						'one' => q({0} fit kare),
						'other' => q({0} fit kare),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fit kare),
						'one' => q({0} fit kare),
						'other' => q({0} fit kare),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inç kare),
						'one' => q({0} inç kare),
						'other' => q({0} inç kare),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inç kare),
						'one' => q({0} inç kare),
						'other' => q({0} inç kare),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometrekare),
						'one' => q({0} kilometrekare),
						'other' => q({0} kilometrekare),
						'per' => q({0}/kilometrekare),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometrekare),
						'one' => q({0} kilometrekare),
						'other' => q({0} kilometrekare),
						'per' => q({0}/kilometrekare),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metrekare),
						'one' => q({0} metrekare),
						'other' => q({0} metrekare),
						'per' => q({0}/metrekare),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metrekare),
						'one' => q({0} metrekare),
						'other' => q({0} metrekare),
						'per' => q({0}/metrekare),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil kare),
						'one' => q({0} mil kare),
						'other' => q({0} mil kare),
						'per' => q({0}/mil kare),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil kare),
						'one' => q({0} mil kare),
						'other' => q({0} mil kare),
						'per' => q({0}/mil kare),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda kare),
						'one' => q({0} yarda kare),
						'other' => q({0} yarda kare),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda kare),
						'one' => q({0} yarda kare),
						'other' => q({0} yarda kare),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram/desilitre),
						'one' => q({0} miligram/desilitre),
						'other' => q({0} miligram/desilitre),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram/desilitre),
						'one' => q({0} miligram/desilitre),
						'other' => q({0} miligram/desilitre),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol/litre),
						'one' => q({0} milimol/litre),
						'other' => q({0} milimol/litre),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/litre),
						'one' => q({0} milimol/litre),
						'other' => q({0} milimol/litre),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(yüzde),
						'one' => q(yüzde {0}),
						'other' => q(yüzde {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(yüzde),
						'one' => q(yüzde {0}),
						'other' => q(yüzde {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(binde),
						'one' => q(binde {0}),
						'other' => q(binde {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(binde),
						'one' => q(binde {0}),
						'other' => q(binde {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parça/milyon),
						'one' => q({0} parça/milyon),
						'other' => q({0} parça/milyon),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parça/milyon),
						'one' => q({0} parça/milyon),
						'other' => q({0} parça/milyon),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(onbinde {0}),
						'other' => q(onbinde {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(onbinde {0}),
						'other' => q(onbinde {0}),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(parça/milyar),
						'one' => q({0} parça/milyar),
						'other' => q({0} parça/milyar),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(parça/milyar),
						'one' => q({0} parça/milyar),
						'other' => q({0} parça/milyar),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litre/100 kilometre),
						'one' => q({0} litre/100 kilometre),
						'other' => q({0} litre/100 kilometre),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litre/100 kilometre),
						'one' => q({0} litre/100 kilometre),
						'other' => q({0} litre/100 kilometre),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litre/kilometre),
						'one' => q({0} litre/kilometre),
						'other' => q({0} litre/kilometre),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litre/kilometre),
						'one' => q({0} litre/kilometre),
						'other' => q({0} litre/kilometre),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/galon),
						'one' => q({0} mil/galon),
						'other' => q({0} mil/galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/galon),
						'one' => q({0} mil/galon),
						'other' => q({0} mil/galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/İng. galonu),
						'one' => q({0} mil/İng. galonu),
						'other' => q({0} mil/İng. galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/İng. galonu),
						'one' => q({0} mil/İng. galonu),
						'other' => q({0} mil/İng. galonu),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Doğu),
						'north' => q({0}Kuzey),
						'south' => q({0}Güney),
						'west' => q({0}Batı),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Doğu),
						'north' => q({0}Kuzey),
						'south' => q({0}Güney),
						'west' => q({0}Batı),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabayt),
						'one' => q({0} gigabayt),
						'other' => q({0} gigabayt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabayt),
						'one' => q({0} gigabayt),
						'other' => q({0} gigabayt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobayt),
						'one' => q({0} kilobayt),
						'other' => q({0} kilobayt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobayt),
						'one' => q({0} kilobayt),
						'other' => q({0} kilobayt),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabayt),
						'one' => q({0} megabayt),
						'other' => q({0} megabayt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabayt),
						'one' => q({0} megabayt),
						'other' => q({0} megabayt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabayt),
						'one' => q({0} petabayt),
						'other' => q({0} petabayt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabayt),
						'one' => q({0} petabayt),
						'other' => q({0} petabayt),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabayt),
						'one' => q({0} terabayt),
						'other' => q({0} terabayt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabayt),
						'one' => q({0} terabayt),
						'other' => q({0} terabayt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(yüzyıl),
						'one' => q({0} yüzyıl),
						'other' => q({0} yüzyıl),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(yüzyıl),
						'one' => q({0} yüzyıl),
						'other' => q({0} yüzyıl),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} saat),
						'other' => q({0} saat),
						'per' => q({0}/saat),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} saat),
						'other' => q({0} saat),
						'per' => q({0}/saat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosaniye),
						'one' => q({0} mikrosaniye),
						'other' => q({0} mikrosaniye),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosaniye),
						'one' => q({0} mikrosaniye),
						'other' => q({0} mikrosaniye),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} milisaniye),
						'other' => q({0} milisaniye),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} milisaniye),
						'other' => q({0} milisaniye),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} dakika),
						'other' => q({0} dakika),
						'per' => q({0}/dakika),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} dakika),
						'other' => q({0} dakika),
						'per' => q({0}/dakika),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} nanosaniye),
						'other' => q({0} nanosaniye),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} nanosaniye),
						'other' => q({0} nanosaniye),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(gece),
						'one' => q({0} gece),
						'other' => q({0} gece),
						'per' => q({0}/gece),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gece),
						'one' => q({0} gece),
						'other' => q({0} gece),
						'per' => q({0}/gece),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0} çeyrek),
						'other' => q({0} çeyrek),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0} çeyrek),
						'other' => q({0} çeyrek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} saniye),
						'other' => q({0} saniye),
						'per' => q({0}/saniye),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} saniye),
						'other' => q({0} saniye),
						'per' => q({0}/saniye),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} hafta),
						'other' => q({0} hafta),
						'per' => q({0}/hafta),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} hafta),
						'other' => q({0} hafta),
						'per' => q({0}/hafta),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0}/yıl),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0}/yıl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(İngiliz ısı birimi),
						'one' => q({0} İngiliz ısı birimi),
						'other' => q({0} İngiliz ısı birimi),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(İngiliz ısı birimi),
						'one' => q({0} İngiliz ısı birimi),
						'other' => q({0} İngiliz ısı birimi),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'one' => q({0} kalori),
						'other' => q({0} kalori),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'one' => q({0} kalori),
						'other' => q({0} kalori),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} jul),
						'other' => q({0} jul),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} jul),
						'other' => q({0} jul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojul),
						'one' => q({0} kilojul),
						'other' => q({0} kilojul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojul),
						'one' => q({0} kilojul),
						'other' => q({0} kilojul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovatsaat),
						'one' => q({0} kilovatsaat),
						'other' => q({0} kilovatsaat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovatsaat),
						'one' => q({0} kilovatsaat),
						'other' => q({0} kilovatsaat),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(100 kilometre / kilowatt-saat),
						'one' => q(100 kilometre/{0} kilowatt-saat),
						'other' => q(100 kilometre/{0} kilowatt-saat),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(100 kilometre / kilowatt-saat),
						'one' => q(100 kilometre/{0} kilowatt-saat),
						'other' => q(100 kilometre/{0} kilowatt-saat),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} pound kuvvet),
						'other' => q({0} pound kuvvet),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} pound kuvvet),
						'other' => q({0} pound kuvvet),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nokta/santimetre),
						'one' => q({0} nokta/santimetre),
						'other' => q({0} nokta/santimetre),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nokta/santimetre),
						'one' => q({0} nokta/santimetre),
						'other' => q({0} nokta/santimetre),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nokta/inç),
						'one' => q({0} nokta/inç),
						'other' => q({0} nokta/inç),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nokta/inç),
						'one' => q({0} nokta/inç),
						'other' => q({0} nokta/inç),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografik em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografik em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksel/santimetre),
						'one' => q({0} piksel/santimetre),
						'other' => q({0} piksel/santimetre),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel/santimetre),
						'one' => q({0} piksel/santimetre),
						'other' => q({0} piksel/santimetre),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel/inç),
						'one' => q({0} piksel/inç),
						'other' => q({0} piksel/inç),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel/inç),
						'one' => q({0} piksel/inç),
						'other' => q({0} piksel/inç),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomik birim),
						'one' => q({0} astronomik birim),
						'other' => q({0} astronomik birim),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomik birim),
						'one' => q({0} astronomik birim),
						'other' => q({0} astronomik birim),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santimetre),
						'one' => q({0} santimetre),
						'other' => q({0} santimetre),
						'per' => q({0}/santimetre),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santimetre),
						'one' => q({0} santimetre),
						'other' => q({0} santimetre),
						'per' => q({0}/santimetre),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimetre),
						'one' => q({0} desimetre),
						'other' => q({0} desimetre),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimetre),
						'one' => q({0} desimetre),
						'other' => q({0} desimetre),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Dünya yarıçapı),
						'one' => q({0} Dünya yarıçapı),
						'other' => q({0} Dünya yarıçapı),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Dünya yarıçapı),
						'one' => q({0} Dünya yarıçapı),
						'other' => q({0} Dünya yarıçapı),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fathom),
						'other' => q({0} fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fathom),
						'other' => q({0} fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0}/fit),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0}/fit),
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
						'per' => q({0}/inç),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0}/inç),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometre),
						'one' => q({0} kilometre),
						'other' => q({0} kilometre),
						'per' => q({0}/kilometre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometre),
						'one' => q({0} kilometre),
						'other' => q({0} kilometre),
						'per' => q({0}/kilometre),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} ışık yılı),
						'other' => q({0} ışık yılı),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} ışık yılı),
						'other' => q({0} ışık yılı),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} metre),
						'other' => q({0} metre),
						'per' => q({0}/metre),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} metre),
						'other' => q({0} metre),
						'per' => q({0}/metre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometre),
						'one' => q({0} mikrometre),
						'other' => q({0} mikrometre),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometre),
						'one' => q({0} mikrometre),
						'other' => q({0} mikrometre),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimetre),
						'one' => q({0} milimetre),
						'other' => q({0} milimetre),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimetre),
						'one' => q({0} milimetre),
						'other' => q({0} milimetre),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometre),
						'one' => q({0} nanometre),
						'other' => q({0} nanometre),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometre),
						'one' => q({0} nanometre),
						'other' => q({0} nanometre),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(deniz mili),
						'one' => q({0} deniz mili),
						'other' => q({0} deniz mili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(deniz mili),
						'one' => q({0} deniz mili),
						'other' => q({0} deniz mili),
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
						'name' => q(pikometre),
						'one' => q({0} pikometre),
						'other' => q({0} pikometre),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometre),
						'one' => q({0} pikometre),
						'other' => q({0} pikometre),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} punto),
						'other' => q({0} punto),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} punto),
						'other' => q({0} punto),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} Güneş yarıçapı),
						'other' => q({0} Güneş yarıçapı),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} Güneş yarıçapı),
						'other' => q({0} Güneş yarıçapı),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yarda),
						'other' => q({0} yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yarda),
						'other' => q({0} yarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lümen),
						'one' => q({0} lümen),
						'other' => q({0} lümen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lümen),
						'one' => q({0} lümen),
						'other' => q({0} lümen),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} Güneş parlaklığı),
						'other' => q({0} Güneş parlaklığı),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} Güneş parlaklığı),
						'other' => q({0} Güneş parlaklığı),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
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
						'one' => q({0} Dünya kütlesi),
						'other' => q({0} Dünya kütlesi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} Dünya kütlesi),
						'other' => q({0} Dünya kütlesi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0}/gram),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0}/gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligram),
						'one' => q({0} miligram),
						'other' => q({0} miligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligram),
						'one' => q({0} miligram),
						'other' => q({0} miligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ons),
						'one' => q({0} ons),
						'other' => q({0} ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ons),
						'one' => q({0} ons),
						'other' => q({0} ons),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} troy ons),
						'other' => q({0} troy ons),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} troy ons),
						'other' => q({0} troy ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} libre),
						'other' => q({0} libre),
						'per' => q({0}/libre),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} libre),
						'other' => q({0} libre),
						'per' => q({0}/libre),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} Güneş kütlesi),
						'other' => q({0} Güneş kütlesi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} Güneş kütlesi),
						'other' => q({0} Güneş kütlesi),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} Amerikan tonu),
						'other' => q({0} Amerikan tonu),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} Amerikan tonu),
						'other' => q({0} Amerikan tonu),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigavat),
						'one' => q({0} gigavat),
						'other' => q({0} gigavat),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigavat),
						'one' => q({0} gigavat),
						'other' => q({0} gigavat),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(beygir gücü),
						'one' => q({0} beygir gücü),
						'other' => q({0} beygir gücü),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(beygir gücü),
						'one' => q({0} beygir gücü),
						'other' => q({0} beygir gücü),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilovat),
						'one' => q({0} kilovat),
						'other' => q({0} kilovat),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilovat),
						'one' => q({0} kilovat),
						'other' => q({0} kilovat),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megavat),
						'one' => q({0} megavat),
						'other' => q({0} megavat),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megavat),
						'one' => q({0} megavat),
						'other' => q({0} megavat),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milivat),
						'one' => q({0} milivat),
						'other' => q({0} milivat),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milivat),
						'one' => q({0} milivat),
						'other' => q({0} milivat),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} vat),
						'other' => q({0} vat),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} vat),
						'other' => q({0} vat),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}kare),
						'one' => q({0}kare),
						'other' => q({0}kare),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}kare),
						'one' => q({0}kare),
						'other' => q({0}kare),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}küp),
						'one' => q({0}küp),
						'other' => q({0}küp),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}küp),
						'one' => q({0}küp),
						'other' => q({0}küp),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfer),
						'one' => q({0} atmosfer),
						'other' => q({0} atmosfer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfer),
						'one' => q({0} atmosfer),
						'other' => q({0} atmosfer),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskal),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskal),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inç cıva),
						'one' => q({0} inç cıva),
						'other' => q({0} inç cıva),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inç cıva),
						'one' => q({0} inç cıva),
						'other' => q({0} inç cıva),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibar),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibar),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimetre cıva),
						'one' => q({0} milimetre cıva),
						'other' => q({0} milimetre cıva),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimetre cıva),
						'one' => q({0} milimetre cıva),
						'other' => q({0} milimetre cıva),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskal),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskal),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libre/inç kare),
						'one' => q({0} libre/inç kare),
						'other' => q({0} libre/inç kare),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libre/inç kare),
						'one' => q({0} libre/inç kare),
						'other' => q({0} libre/inç kare),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometre/saat),
						'one' => q({0} kilometre/saat),
						'other' => q({0} kilometre/saat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometre/saat),
						'one' => q({0} kilometre/saat),
						'other' => q({0} kilometre/saat),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'one' => q({0} knot),
						'other' => q({0} knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'one' => q({0} knot),
						'other' => q({0} knot),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ışık),
						'one' => q({0} ışık),
						'other' => q({0} ışık),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ışık),
						'one' => q({0} ışık),
						'other' => q({0} ışık),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metre/saniye),
						'one' => q({0} metre/saniye),
						'other' => q({0} metre/saniye),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metre/saniye),
						'one' => q({0} metre/saniye),
						'other' => q({0} metre/saniye),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(santigrat derece),
						'one' => q({0} santigrat derece),
						'other' => q({0} santigrat derece),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(santigrat derece),
						'one' => q({0} santigrat derece),
						'other' => q({0} santigrat derece),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(fahrenhayt derece),
						'one' => q({0} fahrenhayt derece),
						'other' => q({0} fahrenhayt derece),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(fahrenhayt derece),
						'one' => q({0} fahrenhayt derece),
						'other' => q({0} fahrenhayt derece),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} derece),
						'other' => q({0} derece),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} derece),
						'other' => q({0} derece),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton metre),
						'one' => q({0} newton metre),
						'other' => q({0} newton metre),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton metre),
						'one' => q({0} newton metre),
						'other' => q({0} newton metre),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound fit),
						'one' => q({0} pound fit),
						'other' => q({0} pound fit),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound fit),
						'one' => q({0} pound fit),
						'other' => q({0} pound fit),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} varil),
						'other' => q({0} varil),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} varil),
						'other' => q({0} varil),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} buşel),
						'other' => q({0} buşel),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} buşel),
						'other' => q({0} buşel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(santilitre),
						'one' => q({0} santilitre),
						'other' => q({0} santilitre),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(santilitre),
						'one' => q({0} santilitre),
						'other' => q({0} santilitre),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(santimetreküp),
						'one' => q({0} santimetreküp),
						'other' => q({0} santimetreküp),
						'per' => q({0} /santimetreküp),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(santimetreküp),
						'one' => q({0} santimetreküp),
						'other' => q({0} santimetreküp),
						'per' => q({0} /santimetreküp),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(fit küp),
						'one' => q({0} fit küp),
						'other' => q({0} fit küp),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fit küp),
						'one' => q({0} fit küp),
						'other' => q({0} fit küp),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inç küp),
						'one' => q({0} inç küp),
						'other' => q({0} inç küp),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inç küp),
						'one' => q({0} inç küp),
						'other' => q({0} inç küp),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometreküp),
						'one' => q({0} kilometreküp),
						'other' => q({0} kilometreküp),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometreküp),
						'one' => q({0} kilometreküp),
						'other' => q({0} kilometreküp),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metreküp),
						'one' => q({0} metreküp),
						'other' => q({0} metreküp),
						'per' => q({0}/metreküp),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metreküp),
						'one' => q({0} metreküp),
						'other' => q({0} metreküp),
						'per' => q({0}/metreküp),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil küp),
						'one' => q({0} mil küp),
						'other' => q({0} mil küp),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil küp),
						'one' => q({0} mil küp),
						'other' => q({0} mil küp),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yarda küp),
						'one' => q({0} yarda küp),
						'other' => q({0} yarda küp),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yarda küp),
						'one' => q({0} yarda küp),
						'other' => q({0} yarda küp),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(su bardağı),
						'one' => q({0} su bardağı),
						'other' => q({0} su bardağı),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(su bardağı),
						'one' => q({0} su bardağı),
						'other' => q({0} su bardağı),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik su bardağı),
						'one' => q({0} metrik su bardağı),
						'other' => q({0} metrik su bardağı),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik su bardağı),
						'one' => q({0} metrik su bardağı),
						'other' => q({0} metrik su bardağı),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitre),
						'one' => q({0} desilitre),
						'other' => q({0} desilitre),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitre),
						'one' => q({0} desilitre),
						'other' => q({0} desilitre),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(tatlı kaşığı),
						'one' => q({0} tatlı kaşığı),
						'other' => q({0} tatlı kaşığı),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(tatlı kaşığı),
						'one' => q({0} tatlı kaşığı),
						'other' => q({0} tatlı kaşığı),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(İng. tatlı kaşığı),
						'one' => q({0} İng. tatlı kaşığı),
						'other' => q({0} İng. tatlı kaşığı),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(İng. tatlı kaşığı),
						'one' => q({0} İng. tatlı kaşığı),
						'other' => q({0} İng. tatlı kaşığı),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'one' => q({0} galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'one' => q({0} galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(İng. galonu),
						'one' => q({0} İng. galonu),
						'other' => q({0} İng. galonu),
						'per' => q({0}/İng. galonu),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(İng. galonu),
						'one' => q({0} İng. galonu),
						'other' => q({0} İng. galonu),
						'per' => q({0}/İng. galonu),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitre),
						'one' => q({0} hektolitre),
						'other' => q({0} hektolitre),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitre),
						'one' => q({0} hektolitre),
						'other' => q({0} hektolitre),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litre),
						'other' => q({0} litre),
						'per' => q({0}/litre),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litre),
						'other' => q({0} litre),
						'per' => q({0}/litre),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitre),
						'one' => q({0} megalitre),
						'other' => q({0} megalitre),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitre),
						'one' => q({0} megalitre),
						'other' => q({0} megalitre),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitre),
						'one' => q({0} mililitre),
						'other' => q({0} mililitre),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitre),
						'one' => q({0} mililitre),
						'other' => q({0} mililitre),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik pint),
						'one' => q({0} metrik pint),
						'other' => q({0} metrik pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik pint),
						'one' => q({0} metrik pint),
						'other' => q({0} metrik pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(İng. quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(İng. quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(yemek kaşığı),
						'one' => q({0} yemek kaşığı),
						'other' => q({0} yemek kaşığı),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(yemek kaşığı),
						'one' => q({0} yemek kaşığı),
						'other' => q({0} yemek kaşığı),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(çay kaşığı),
						'one' => q({0} çay kaşığı),
						'other' => q({0} çay kaşığı),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(çay kaşığı),
						'one' => q({0} çay kaşığı),
						'other' => q({0} çay kaşığı),
					},
				},
				'narrow' => {
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
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
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
					'duration-day' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sa),
						'one' => q({0} sa),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sa),
						'one' => q({0} sa),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msn),
						'one' => q({0}msn),
						'other' => q({0}msn),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msn),
						'one' => q({0}msn),
						'other' => q({0}msn),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(dk),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(dk),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nsn),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nsn),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(gece),
						'one' => q({0} gece),
						'other' => q({0} gece),
						'per' => q({0}/gece),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gece),
						'one' => q({0} gece),
						'other' => q({0} gece),
						'per' => q({0}/gece),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çey.),
						'per' => q({0}/çey.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çey.),
						'per' => q({0}/çey.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sn),
						'one' => q({0}sn),
						'other' => q({0}sn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sn),
						'one' => q({0}sn),
						'other' => q({0}sn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}y),
						'other' => q({0}y),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}y),
						'other' => q({0}y),
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
					'length-foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(Iy),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(Iy),
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
						'name' => q(μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
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
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
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
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
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
					'pressure-millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ışık),
						'one' => q({0} ışık),
						'other' => q({0} ışık),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ışık),
						'one' => q({0} ışık),
						'other' => q({0} ışık),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/sa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/sa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(tk),
						'one' => q({0} tk),
						'other' => q({0} tk),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(tk),
						'one' => q({0} tk),
						'other' => q({0} tk),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(İng. tk),
						'one' => q({0} İng. tk),
						'other' => q({0} İng. tk),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(İng. tk),
						'one' => q({0} İng. tk),
						'other' => q({0} İng. tk),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0} galon),
						'other' => q({0} galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0} galon),
						'other' => q({0} galon),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(İng. qt),
						'one' => q({0} İng. qt.),
						'other' => q({0} İng. qt.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(İng. qt),
						'one' => q({0} İng. qt.),
						'other' => q({0} İng. qt.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(yön),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(yön),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g kuvveti),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g kuvveti),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/sn²),
						'one' => q({0} m/sn²),
						'other' => q({0} m/sn²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/sn²),
						'one' => q({0} m/sn²),
						'other' => q({0} m/sn²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(açısal dk.),
						'one' => q({0} açısal dk.),
						'other' => q({0} açısal dk.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(açısal dk.),
						'one' => q({0} açısal dk.),
						'other' => q({0} açısal dk.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(açısal sn.),
						'one' => q({0} açısal sn.),
						'other' => q({0} açısal sn.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(açısal sn.),
						'one' => q({0} açısal sn.),
						'other' => q({0} açısal sn.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derece),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derece),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radyan),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radyan),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(dev),
						'one' => q({0} dev),
						'other' => q({0} dev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(dev),
						'one' => q({0} dev),
						'other' => q({0} dev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(öğe),
						'one' => q({0} öğe),
						'other' => q({0} öğe),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(öğe),
						'one' => q({0} öğe),
						'other' => q({0} öğe),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ayar),
						'one' => q({0} ayar),
						'other' => q({0} ayar),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ayar),
						'one' => q({0} ayar),
						'other' => q({0} ayar),
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
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q(‰{0}),
						'other' => q(‰{0}),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q(‰{0}),
						'other' => q(‰{0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(onbinde),
						'one' => q(‱{0}),
						'other' => q(‱{0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(onbinde),
						'one' => q(‱{0}),
						'other' => q(‱{0}),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(parça/milyar),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(parça/milyar),
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
						'name' => q(mil/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/İng. gal),
						'one' => q({0} mil/İng. gal),
						'other' => q({0} mil/İng. gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/İng. gal),
						'one' => q({0} mil/İng. gal),
						'other' => q({0} mil/İng. gal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}D),
						'north' => q({0}K),
						'south' => q({0}G),
						'west' => q({0}B),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}D),
						'north' => q({0}K),
						'south' => q({0}G),
						'west' => q({0}B),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(yy),
						'one' => q({0} yy),
						'other' => q({0} yy),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(yy),
						'one' => q({0} yy),
						'other' => q({0} yy),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(on yıl),
						'one' => q({0} on yıl),
						'other' => q({0} on yıl),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(on yıl),
						'one' => q({0} on yıl),
						'other' => q({0} on yıl),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saat),
						'one' => q({0} sa.),
						'other' => q({0} sa.),
						'per' => q({0}/sa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saat),
						'one' => q({0} sa.),
						'other' => q({0} sa.),
						'per' => q({0}/sa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsn),
						'one' => q({0} μsn),
						'other' => q({0} μsn),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsn),
						'one' => q({0} μsn),
						'other' => q({0} μsn),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisaniye),
						'one' => q({0} msn),
						'other' => q({0} msn),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisaniye),
						'one' => q({0} msn),
						'other' => q({0} msn),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(dakika),
						'one' => q({0} dk.),
						'other' => q({0} dk.),
						'per' => q({0}/dk.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(dakika),
						'one' => q({0} dk.),
						'other' => q({0} dk.),
						'per' => q({0}/dk.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
						'per' => q({0}/ay),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
						'per' => q({0}/ay),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosaniye),
						'one' => q({0} nsn),
						'other' => q({0} nsn),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosaniye),
						'one' => q({0} nsn),
						'other' => q({0} nsn),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(gece),
						'one' => q({0} gece),
						'other' => q({0} gece),
						'per' => q({0}/gece),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gece),
						'one' => q({0} gece),
						'other' => q({0} gece),
						'per' => q({0}/gece),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çeyrek),
						'one' => q({0} çey.),
						'other' => q({0} çey.),
						'per' => q({0}/çeyrek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çeyrek),
						'one' => q({0} çey.),
						'other' => q({0} çey.),
						'per' => q({0}/çeyrek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(saniye),
						'one' => q({0} sn.),
						'other' => q({0} sn.),
						'per' => q({0}/sn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(saniye),
						'one' => q({0} sn.),
						'other' => q({0} sn.),
						'per' => q({0}/sn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hafta),
						'one' => q({0} hf.),
						'other' => q({0} hf.),
						'per' => q({0}/hf.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hafta),
						'one' => q({0} hf.),
						'other' => q({0} hf.),
						'per' => q({0}/hf.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(yıl),
						'one' => q({0} yıl),
						'other' => q({0} yıl),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(yıl),
						'one' => q({0} yıl),
						'other' => q({0} yıl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamper),
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
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jul),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jul),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ABD ısı birimi),
						'one' => q({0} ABD ısı birimi),
						'other' => q({0} ABD ısı birimi),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ABD ısı birimi),
						'one' => q({0} ABD ısı birimi),
						'other' => q({0} ABD ısı birimi),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
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
						'name' => q(pound kuvvet),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound kuvvet),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(nokta),
						'one' => q({0} nokta),
						'other' => q({0} nokta),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(nokta),
						'one' => q({0} nokta),
						'other' => q({0} nokta),
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
						'name' => q(megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fit),
						'one' => q({0} fit),
						'other' => q({0} fit),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fit),
						'one' => q({0} fit),
						'other' => q({0} fit),
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
						'name' => q(inç),
						'one' => q({0} inç),
						'other' => q({0} inç),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inç),
						'one' => q({0} inç),
						'other' => q({0} inç),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ışık yılı),
						'one' => q({0} IY),
						'other' => q({0} IY),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ışık yılı),
						'one' => q({0} IY),
						'other' => q({0} IY),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metre),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikron),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikron),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
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
						'name' => q(punto),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Güneş yarıçapı),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Güneş yarıçapı),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lüks),
						'one' => q({0} lüks),
						'other' => q({0} lüks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lüks),
						'one' => q({0} lüks),
						'other' => q({0} lüks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(Güneş parlaklığı),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Güneş parlaklığı),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q({0} ct),
						'other' => q({0} ct),
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
						'name' => q(Dünya kütlesi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Dünya kütlesi),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(tane),
						'one' => q({0} tane),
						'other' => q({0} tane),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(tane),
						'one' => q({0} tane),
						'other' => q({0} tane),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ons),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libre),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libre),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(Güneş kütlesi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(Güneş kütlesi),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(Amerikan tonu),
						'one' => q({0} kısa ton),
						'other' => q({0} kısa ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(Amerikan tonu),
						'one' => q({0} kısa ton),
						'other' => q({0} kısa ton),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(bg),
						'one' => q({0} bg),
						'other' => q({0} bg),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(bg),
						'one' => q({0} bg),
						'other' => q({0} bg),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vat),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vat),
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
					'pressure-pound-force-per-square-inch' => {
						'name' => q(lb/in²),
						'one' => q({0} lb/in²),
						'other' => q({0} lb/in²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(lb/in²),
						'one' => q({0} lb/in²),
						'other' => q({0} lb/in²),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/sa),
						'one' => q({0} km/sa),
						'other' => q({0} km/sa),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/sa),
						'one' => q({0} km/sa),
						'other' => q({0} km/sa),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ışık),
						'one' => q({0} ışık),
						'other' => q({0} ışık),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ışık),
						'one' => q({0} ışık),
						'other' => q({0} ışık),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/sn),
						'one' => q({0} m/sn),
						'other' => q({0} m/sn),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/sn),
						'one' => q({0} m/sn),
						'other' => q({0} m/sn),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/saat),
						'one' => q({0} mil/sa),
						'other' => q({0} mil/sa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/saat),
						'one' => q({0} mil/sa),
						'other' => q({0} mil/sa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akre fit),
						'one' => q({0} akre fit),
						'other' => q({0} akre fit),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akre fit),
						'one' => q({0} akre fit),
						'other' => q({0} akre fit),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(varil),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(varil),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(buşel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(buşel),
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
						'name' => q(fit³),
						'one' => q({0} fit³),
						'other' => q({0} fit³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fit³),
						'one' => q({0} fit³),
						'other' => q({0} fit³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inç³),
						'one' => q({0} inç³),
						'other' => q({0} inç³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inç³),
						'one' => q({0} inç³),
						'other' => q({0} inç³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil³),
						'one' => q({0} mil³),
						'other' => q({0} mil³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil³),
						'one' => q({0} mil³),
						'other' => q({0} mil³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yarda³),
						'one' => q({0} yarda³),
						'other' => q({0} yarda³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yarda³),
						'one' => q({0} yarda³),
						'other' => q({0} yarda³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(su b.),
						'one' => q({0} sb),
						'other' => q({0} sb),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(su b.),
						'one' => q({0} sb),
						'other' => q({0} sb),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(msub),
						'one' => q({0} msb),
						'other' => q({0} msb),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(msub),
						'one' => q({0} msb),
						'other' => q({0} msb),
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
						'name' => q(tat. kaşığı),
						'one' => q({0} tat. kaşığı),
						'other' => q({0} tat. kaşığı),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(tat. kaşığı),
						'one' => q({0} tat. kaşığı),
						'other' => q({0} tat. kaşığı),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(İng. tat. kaşığı),
						'one' => q({0} İng. tat. kaşığı),
						'other' => q({0} İng. tat. kaşığı),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(İng. tat. kaşığı),
						'one' => q({0} İng. tat. kaşığı),
						'other' => q({0} İng. tat. kaşığı),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(sıvı dram),
						'one' => q({0} sıvı dram),
						'other' => q({0} sıvı dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(sıvı dram),
						'one' => q({0} sıvı dram),
						'other' => q({0} sıvı dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(damla),
						'one' => q({0} damla),
						'other' => q({0} damla),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(damla),
						'one' => q({0} damla),
						'other' => q({0} damla),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(sıvı ons),
						'one' => q({0} sıvı ons),
						'other' => q({0} sıvı ons),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(sıvı ons),
						'one' => q({0} sıvı ons),
						'other' => q({0} sıvı ons),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(İng. sıvı ons),
						'one' => q({0} İng. sıvı ons),
						'other' => q({0} İng. sıvı ons),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(İng. sıvı ons),
						'one' => q({0} İng. sıvı ons),
						'other' => q({0} İng. sıvı ons),
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
						'name' => q(İng. gal),
						'one' => q({0} İng. gal),
						'other' => q({0} İng. gal),
						'per' => q({0}/İng. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(İng. gal),
						'one' => q({0} İng. gal),
						'other' => q({0} İng. gal),
						'per' => q({0}/İng. gal),
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
						'name' => q(litre),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litre),
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
						'name' => q(tutam),
						'one' => q({0} tutam),
						'other' => q({0} tutam),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(tutam),
						'one' => q({0} tutam),
						'other' => q({0} tutam),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(İng quart),
						'one' => q({0} İng. quart),
						'other' => q({0} İng. quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(İng quart),
						'one' => q({0} İng. quart),
						'other' => q({0} İng. quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(yk),
						'one' => q({0} yk),
						'other' => q({0} yk),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(yk),
						'one' => q({0} yk),
						'other' => q({0} yk),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(çk),
						'one' => q({0} çk),
						'other' => q({0} çk),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(çk),
						'one' => q({0} çk),
						'other' => q({0} çk),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:evet|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hayir|h|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} ve {1}),
				2 => q({0} ve {1}),
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
					'one' => '0 bin',
					'other' => '0 bin',
				},
				'10000' => {
					'one' => '00 bin',
					'other' => '00 bin',
				},
				'100000' => {
					'one' => '000 bin',
					'other' => '000 bin',
				},
				'1000000' => {
					'one' => '0 milyon',
					'other' => '0 milyon',
				},
				'10000000' => {
					'one' => '00 milyon',
					'other' => '00 milyon',
				},
				'100000000' => {
					'one' => '000 milyon',
					'other' => '000 milyon',
				},
				'1000000000' => {
					'one' => '0 milyar',
					'other' => '0 milyar',
				},
				'10000000000' => {
					'one' => '00 milyar',
					'other' => '00 milyar',
				},
				'100000000000' => {
					'one' => '000 milyar',
					'other' => '000 milyar',
				},
				'1000000000000' => {
					'one' => '0 trilyon',
					'other' => '0 trilyon',
				},
				'10000000000000' => {
					'one' => '00 trilyon',
					'other' => '00 trilyon',
				},
				'100000000000000' => {
					'one' => '000 trilyon',
					'other' => '000 trilyon',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
				'1000000' => {
					'one' => '0 Mn',
					'other' => '0 Mn',
				},
				'10000000' => {
					'one' => '00 Mn',
					'other' => '00 Mn',
				},
				'100000000' => {
					'one' => '000 Mn',
					'other' => '000 Mn',
				},
				'1000000000' => {
					'one' => '0 Mr',
					'other' => '0 Mr',
				},
				'10000000000' => {
					'one' => '00 Mr',
					'other' => '00 Mr',
				},
				'100000000000' => {
					'one' => '000 Mr',
					'other' => '000 Mr',
				},
				'1000000000000' => {
					'one' => '0 Tn',
					'other' => '0 Tn',
				},
				'10000000000000' => {
					'one' => '00 Tn',
					'other' => '00 Tn',
				},
				'100000000000000' => {
					'one' => '000 Tn',
					'other' => '000 Tn',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '%#,##0',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(Andorra Pezetası),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Birleşik Arap Emirlikleri dirhemi),
				'one' => q(BAE dirhemi),
				'other' => q(BAE dirhemi),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afganistan Afganisi \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afganistan afganisi),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Arnavutluk Leki \(1946–1965\)),
				'one' => q(Arnavutluk leki \(1946–1965\)),
				'other' => q(Arnavutluk leki \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Arnavutluk leki),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Ermenistan dramı),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Hollanda Antilleri guldeni),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola kvanzası),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angola Kvanzası \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Yeni Angola Kvanzası \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angola Kvanzası Reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Arjantin Australi),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Arjantin Peso Leyi \(1970–1983\)),
				'one' => q(Arjantin peso leyi \(1970–1983\)),
				'other' => q(Arjantin peso leyi \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Arjantin Pesosu \(1881–1970\)),
				'one' => q(Arjantin pesosu \(1881–1970\)),
				'other' => q(Arjantin pesosu \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Arjantin Pezosu \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Arjantin pesosu),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Avusturya Şilini),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Avustralya doları),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba florini),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbaycan Manatı \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaycan manatı),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosna Hersek Dinarı),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Konvertibl Bosna Hersek markı),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Yeni Bosna Hersek Dinarı \(1994–1997\)),
				'one' => q(Yeni Bosna Hersek dinarı \(1994–1997\)),
				'other' => q(Yeni Bosna Hersek dinarı \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados doları),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeş takası),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belçika Frangı \(konvertibl\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belçika Frangı),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belçika Frangı \(finansal\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgar Levası \(Hard\)),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Sosyalist Bulgaristan Levası),
				'one' => q(Sosyalist Bulgaristan levası),
				'other' => q(Sosyalist Bulgaristan levası),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgar levası),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bulgar Levası \(1879–1952\)),
				'one' => q(Bulgar levası \(1879–1952\)),
				'other' => q(Bulgar levası \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreyn dinarı),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi frangı),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda doları),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei doları),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivya bolivyanosu),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Bolivya Bolivyanosu \(1863–1963\)),
				'one' => q(Bolivya bolivyanosu \(1863–1963\)),
				'other' => q(Bolivya bolivyanosu \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivya Pezosu),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivya Mvdolu),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Yeni Brezilya Kruzeirosu \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brezilya Kruzadosu),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brezilya Kruzeirosu \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brezilya reali),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Yeni Brezilya Kruzadosu),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brezilya Kruzeirosu),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brezilya Kruzeirosu \(1942–1967\)),
				'one' => q(Brezilya kruzeirosu \(1942–1967\)),
				'other' => q(Brezilya kruzeirosu \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahama doları),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butan ngultrumu),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burma Kyatı),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botsvana pulası),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Yeni Beyaz Rusya Rublesi \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Belarus rublesi),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Beyaz Rusya Rublesi \(2000–2016\)),
				'one' => q(Beyaz Rusya rublesi \(2000–2016\)),
				'other' => q(Beyaz Rusya rublesi \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize doları),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada doları),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo frangı),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR Avrosu),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(İsviçre frangı),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR Frangı),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Şili Esküdosu),
				'one' => q(Şili esküdosu),
				'other' => q(Şili esküdosu),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Şili Unidades de Fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Şili pesosu),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Çin yuanı \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Çin Halk Cumhuriyeti Merkez Bankası Doları),
				'one' => q(Çin Halk Cumhuriyeti Merkez Bankası doları),
				'other' => q(Çin Halk Cumhuriyeti Merkez Bankası doları),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Çin yuanı),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolombiya pesosu),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidad de Valor Real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kosta Rika kolonu),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Eski Sırbistan Dinarı),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Çekoslavak Korunası \(Hard\)),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Konvertibl Küba pesosu),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Küba pesosu),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cape Verde esküdosu),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Güney Kıbrıs Lirası),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Çek korunası),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Doğu Alman Markı),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Alman Markı),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Cibuti frangı),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danimarka kronu),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominik pesosu),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Cezayir dinarı),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ekvador Sukresi),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ekvador Unidad de Valor Constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estonya Krunu),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Mısır lirası),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritre nakfası),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(İspanyol Pezetası \(A hesabı\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(İspanyol Pezetası \(konvertibl hesap\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(İspanyol Pezetası),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etiyopya birri),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Fin Markkası),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fiji doları),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland Adaları lirası),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Fransız Frangı),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(İngiliz sterlini),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Gürcistan Kupon Larisi),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Gürcistan larisi),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Gana Sedisi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Gana sedisi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Cebelitarık lirası),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiya dalasisi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Gine frangı),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Gine Sylisi),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekvator Ginesi Ekuelesi),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Yunan Drahmisi),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemala quetzalı),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portekiz Ginesi Esküdosu),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Gine-Bissau Pezosu),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyana doları),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kong doları),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduras lempirası),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Hırvatistan Dinarı),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Hırvatistan kunası),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti gurdu),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Macar forinti),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Endonezya rupisi),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(İrlanda Lirası),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(İsrail Lirası),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(İsrail Şekeli \(1980–1985\)),
				'one' => q(İsrail şekeli \(1980–1985\)),
				'other' => q(İsrail şekeli \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Yeni İsrail şekeli),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Hindistan rupisi),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irak dinarı),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(İran riyali),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(İzlanda Kronu \(1918–1981\)),
				'one' => q(İzlanda kronu \(1918–1981\)),
				'other' => q(İzlanda kronu \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(İzlanda kronu),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(İtalyan Lireti),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaika doları),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Ürdün dinarı),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japon yeni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenya şilini),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kırgızistan somu),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kamboçya rieli),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komorlar frangı),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Kuzey Kore wonu),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Güney Kore Hwanı \(1953–1962\)),
				'one' => q(Güney Kore hwanı \(1953–1962\)),
				'other' => q(Güney Kore hwanı \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Güney Kore Wonu \(1945–1953\)),
				'one' => q(Güney Kore wonu \(1945–1953\)),
				'other' => q(Güney Kore wonu \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Güney Kore wonu),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuveyt dinarı),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman Adaları doları),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazakistan tengesi),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laos kipi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Lübnan lirası),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lanka rupisi),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberya doları),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho lotisi),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litvanya Litası),
				'one' => q(Litvanya litası),
				'other' => q(Litvanya litası),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litvanya Talonu),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Konvertibl Lüksemburg Frangı),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Lüksemburg Frangı),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Finansal Lüksemburg Frangı),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Letonya Latı),
				'one' => q(Letonya latı),
				'other' => q(Letonya latı),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Letonya Rublesi),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libya dinarı),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Fas dirhemi),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Fas Frangı),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monako Frangı),
				'one' => q(Monako frangı),
				'other' => q(Monako frangı),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldova Kuponu),
				'one' => q(Moldova kuponu),
				'other' => q(Moldova kuponu),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldova leyi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskar ariarisi),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskar Frangı),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedonya dinarı),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Makedonya Dinarı \(1992–1993\)),
				'one' => q(Makedonya dinarı \(1992–1993\)),
				'other' => q(Makedonya dinarı \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mali Frangı),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmar kyatı),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Moğolistan tugriki),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makao patakası),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Moritanya Ugiyası \(1973–2017\)),
				'one' => q(Moritanya ugiyası \(1973–2017\)),
				'other' => q(Moritanya ugiyası \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Moritanya ugiyası),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Malta Lirası),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Malta Sterlini),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritius rupisi),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Maldiv Rupisi),
				'one' => q(Maldiv rupisi),
				'other' => q(Maldiv rupisi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldiv rufiyaası),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malavi kvaçası),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksika pesosu),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Gümüş Meksika Pezosu \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Meksika Unidad de Inversion \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malezya ringgiti),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambik Esküdosu),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Eski Mozambik Metikali),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambik metikali),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibya doları),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nijerya nairası),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nikaragua Kordobası \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragua kordobası),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollanda Florini),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norveç kronu),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepal rupisi),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Yeni Zelanda doları),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Umman riyali),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama balboası),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peru İnti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru solü),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peru Solü \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua Yeni Gine kinası),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipinler pesosu),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistan rupisi),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polonya zlotisi),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polonya Zlotisi \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portekiz Esküdosu),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguay guaranisi),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar riyali),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rodezya Doları),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Eski Romen Leyi),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(Romen leyi),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Sırp dinarı),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rus rublesi),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rus Rublesi \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda frangı),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Suudi Arabistan riyali),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon Adaları doları),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seyşeller rupisi),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Eski Sudan Dinarı),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan lirası),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Eski Sudan Lirası),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(İsveç kronu),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapur doları),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Saint Helena lirası),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovenya Toları),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovak Korunası),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leone leonesi),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leone leonesi \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali şilini),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam doları),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinam Guldeni),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Güney Sudan lirası),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomé ve Príncipe Dobrası \(1977–2017\)),
				'one' => q(São Tomé ve Príncipe dobrası \(1977–2017\)),
				'other' => q(São Tomé ve Príncipe dobrası \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome ve Principe dobrası),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovyet Rublesi),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El Salvador Kolonu),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Suriye lirası),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Svaziland lilangenisi),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Tayland bahtı),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tacikistan Rublesi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tacikistan somonisi),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Türkmenistan Manatı \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Türkmenistan manatı),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunus dinarı),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonga paʻangası),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor Esküdosu),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Eski Türk Lirası),
			},
		},
		'TRY' => {
			symbol => '₺',
			display_name => {
				'currency' => q(Türk lirası),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad ve Tobago doları),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Yeni Tayvan doları),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzanya şilini),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrayna grivnası),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrayna Karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uganda Şilini \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda şilini),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ABD doları),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(ABD Doları \(Ertesi gün\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(ABD Doları \(Aynı gün\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguay Peso en Unidades Indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguay Pezosu \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguay pesosu),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Özbekistan somu),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuela Bolivarı \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezuela Bolivarı \(2008–2018\)),
				'one' => q(Venezuela bolivarı \(2008–2018\)),
				'other' => q(Venezuela bolivarı \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuela bolivarı),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnam dongu),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vietnam Dongu \(1978–1985\)),
				'one' => q(Vietnam dongu \(1978–1985\)),
				'other' => q(Vietnam dongu \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu vatusu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa talası),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Orta Afrika CFA frangı),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Gümüş),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Altın),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Birleşik Avrupa Birimi),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Avrupa Para Birimi \(EMU\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Avrupa Hesap Birimi \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Avrupa Hesap Birimi \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Doğu Karayip doları),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Özel Çekme Hakkı \(SDR\)),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Avrupa Para Birimi),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Fransız Altın Frangı),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Fransız UIC-Frangı),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Batı Afrika CFA frangı),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladyum),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP frangı),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET Fonları),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(Sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Test Para Birimi Kodu),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(ADB Hesap Birimi),
				'one' => q(ADB hesap birimi),
				'other' => q(ADB hesap birimi),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Bilinmeyen Para Birimi),
				'one' => q(\(bilinmeyen para birimi\)),
				'other' => q(\(bilinmeyen para birimi\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Yemen Dinarı),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yemen riyali),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Yugoslav Dinarı \(Hard\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Yeni Yugoslav Dinarı),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Konvertibl Yugoslav Dinarı),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(İyileştirilmiş Yugoslav Dinarı \(1992–1993\)),
				'one' => q(İyileştirilmiş Yugoslav dinarı \(1992–1993\)),
				'other' => q(İyileştirilmiş Yugoslav dinarı \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Güney Afrika Randı \(finansal\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Güney Afrika randı),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiya Kvaçası \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambiya kvaçası),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Yeni Zaire Zairesi),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire Zairesi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabve Doları),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabve Doları \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabve Doları \(2008\)),
				'one' => q(Zimbabve doları \(2008\)),
				'other' => q(Zimbabve doları \(2008\)),
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
							'Tût',
							'Bâbe',
							'Hatur',
							'Keyhek',
							'Tûbe',
							'Imşir',
							'Bermuhat',
							'Bermude',
							'Peyştes',
							'Bune',
							'Ebip',
							'Mısrî',
							'Nesî'
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
							'Tikimt',
							'Hidar',
							'Tahsas',
							'Tir',
							'Yakatit',
							'Magabit',
							'Miyazya',
							'Ginbot',
							'Sene',
							'Hamle',
							'Nehasa',
							'Pagumiene'
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
							'Oca',
							'Şub',
							'Mar',
							'Nis',
							'May',
							'Haz',
							'Tem',
							'Ağu',
							'Eyl',
							'Eki',
							'Kas',
							'Ara'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ocak',
							'Şubat',
							'Mart',
							'Nisan',
							'Mayıs',
							'Haziran',
							'Temmuz',
							'Ağustos',
							'Eylül',
							'Ekim',
							'Kasım',
							'Aralık'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'O',
							'Ş',
							'M',
							'N',
							'M',
							'H',
							'T',
							'A',
							'E',
							'E',
							'K',
							'A'
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
							'Tişri',
							'Heşvan',
							'Kislev',
							'Tevet',
							'Şevat',
							'Adar Rişon',
							'Adar',
							'Nisan',
							'İyar',
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
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muhar.',
							'Safer',
							'R.evvel',
							'R.ahir',
							'C.evvel',
							'C.ahir',
							'Recep',
							'Şaban',
							'Ram.',
							'Şevval',
							'Zilkade',
							'Zilhicce'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharrem',
							'Safer',
							'Rebiülevvel',
							'Rebiülahir',
							'Cemaziyelevvel',
							'Cemaziyelahir',
							'Recep',
							'Şaban',
							'Ramazan',
							'Şevval',
							'Zilkade',
							'Zilhicce'
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
							'Ferverdin',
							'Ordibeheşt',
							'Hordad',
							'Tir',
							'Mordad',
							'Şehriver',
							'Mehr',
							'Aban',
							'Azer',
							'Dey',
							'Behmen',
							'Esfend'
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
						mon => 'Pzt',
						tue => 'Sal',
						wed => 'Çar',
						thu => 'Per',
						fri => 'Cum',
						sat => 'Cmt',
						sun => 'Paz'
					},
					short => {
						mon => 'Pt',
						tue => 'Sa',
						wed => 'Ça',
						thu => 'Pe',
						fri => 'Cu',
						sat => 'Ct',
						sun => 'Pa'
					},
					wide => {
						mon => 'Pazartesi',
						tue => 'Salı',
						wed => 'Çarşamba',
						thu => 'Perşembe',
						fri => 'Cuma',
						sat => 'Cumartesi',
						sun => 'Pazar'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'P',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'C',
						sat => 'C',
						sun => 'P'
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
					abbreviated => {0 => 'Ç1',
						1 => 'Ç2',
						2 => 'Ç3',
						3 => 'Ç4'
					},
					wide => {0 => '1. çeyrek',
						1 => '2. çeyrek',
						2 => '3. çeyrek',
						3 => '4. çeyrek'
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
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'afternoon2' if $time >= 1800
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'morning2' if $time >= 1100
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
					'afternoon1' => q{öğleden sonra},
					'afternoon2' => q{akşamüstü},
					'am' => q{ÖÖ},
					'evening1' => q{akşam},
					'midnight' => q{gece yarısı},
					'morning1' => q{sabah},
					'morning2' => q{öğleden önce},
					'night1' => q{gece},
					'noon' => q{öğle},
					'pm' => q{ÖS},
				},
				'narrow' => {
					'afternoon1' => q{öğleden sonra},
					'afternoon2' => q{akşamüstü},
					'am' => q{öö},
					'evening1' => q{akşam},
					'midnight' => q{gece},
					'morning1' => q{sabah},
					'morning2' => q{öğleden önce},
					'night1' => q{gece},
					'noon' => q{ö},
					'pm' => q{ös},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'MÖ',
				'1' => 'MS'
			},
			wide => {
				'0' => 'Milattan Önce',
				'1' => 'Milattan Sonra'
			},
		},
		'hebrew' => {
		},
		'islamic' => {
			abbreviated => {
				'0' => 'Hicri'
			},
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'R.O.C. Öncesi'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{G d MMMM y EEEE},
			'long' => q{G d MMMM y},
			'medium' => q{G d MMM y},
			'short' => q{GGGGG d.MM.y},
		},
		'gregorian' => {
			'full' => q{d MMMM y EEEE},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d.MM.y},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{d MMMM y G EEEE},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d.MM.y G},
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
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{d E},
			Ehm => q{E a h:mm},
			Ehms => q{E a h:mm:ss},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y E},
			GyMMMd => q{G d MMM y},
			GyMd => q{d/M/y GGGGG},
			MEd => q{dd/MM E},
			MMMEd => q{d MMM E},
			MMMMEd => q{dd MMMM E},
			MMMMd => q{dd MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			yyyyM => q{GGGGG M/y},
			yyyyMEd => q{GGGGG dd.MM.y E},
			yyyyMM => q{MM.y G},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G d MMM y E},
			yyyyMMMM => q{G MMMM y},
			yyyyMMMd => q{G dd MMM y},
			yyyyMd => q{GGGGG dd.MM.y},
			yyyyQQQ => q{G y/QQQ},
			yyyyQQQQ => q{G y/QQQQ},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{d E},
			Ehm => q{E a h:mm},
			Ehms => q{E a h:mm:ss},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y E},
			GyMMMd => q{G d MMM y},
			GyMd => q{GGGGG dd.MM.y},
			MEd => q{d/MM E},
			MMMEd => q{d MMM E},
			MMMMEd => q{d MMMM E},
			MMMMW => q{MMMM 'ayının' W. 'haftası'},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{a h},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{a h:mm:ss v},
			hmv => q{a h:mm v},
			mmss => q{mm:ss},
			yM => q{MM/y},
			yMEd => q{d.M.y E},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yw => q{Y 'yılının' w. 'haftası'},
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
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			GyM => {
				G => q{GGGGG MM.y – GGGGG MM.y},
				M => q{GGGGG MM.y – MM.y},
				y => q{GGGGG MM.y – MM.y},
			},
			GyMEd => {
				G => q{GGGGG dd.MM.y E – GGGGG dd.MM.y E},
				M => q{GGGGG dd.MM.y E – dd.MM.y E},
				d => q{GGGGG dd.MM.y E – dd.MM.y E},
				y => q{GGGGG dd.MM.y E – dd.MM.y E},
			},
			GyMMM => {
				G => q{G MMM y G – G MMM y},
				M => q{G MMM – MMM y},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G d MMM y E – G d MMM y E},
				M => q{G d MMM E – d MMM E y},
				d => q{G d MMM E – d MMM E y},
				y => q{G d MMM y E – d MMM y E},
			},
			GyMMMd => {
				G => q{G d MMM y – G d MMM y},
				M => q{G d MMM – d MMM y},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			GyMd => {
				G => q{GGGGG dd.MM.y GGGGG – dd.MM.y},
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
			MEd => {
				M => q{dd/MM E – dd/MM E},
				d => q{dd/MM E – dd/MM E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d MMM E – d MMM E},
				d => q{d MMM E – d MMM E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
				M => q{GGGGG M/y – M/y},
				y => q{GGGGG M/y – M/y},
			},
			yMEd => {
				M => q{GGGGG dd.MM.y E – dd.MM.y E},
				d => q{GGGGG dd.MM.y E – dd.MM.y E},
				y => q{GGGGG dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{G MMM–MMM y},
				y => q{G MMM y – MMM y},
			},
			yMMMEd => {
				M => q{G d MMM y E – d MMM y E},
				d => q{G d MMM y E – d MMM y E},
				y => q{G d MMM y E – d MMM y E},
			},
			yMMMM => {
				M => q{G MMMM – MMMM y},
				y => q{G MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{G d MMM – d MMM y},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			yMd => {
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			GyM => {
				G => q{GGGGG MM.y – GGGGG MM.y},
				M => q{GGGGG MM.y – MM.y},
				y => q{GGGGG MM.y – MM.y},
			},
			GyMEd => {
				G => q{GGGGG dd.MM.y E – GGGGG dd.MM.y E},
				M => q{GGGGG dd.MM.y E – dd.MM.y E},
				d => q{GGGGG dd.MM.y E – dd.MM.y E},
				y => q{GGGGG dd.MM.y E – dd.MM.y E},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM–MMM y},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G d MMM y E – G d MMM y E},
				M => q{G d MMM E – d MMM E y},
				d => q{G d MMM E – d MMM E y},
				y => q{G d MMM y E – d MMM y E},
			},
			GyMMMd => {
				G => q{G d MMM y – G d MMM y},
				M => q{G d MMM – d MMM y},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			GyMd => {
				G => q{GGGGG dd.MM.y – GGGGG dd.MM.y},
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{d.M E – d.M E},
				d => q{d.M E – d.M E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d MMM E – d MMM E},
				d => q{d MMM E – d MMM E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			h => {
				a => q{a h – a h},
				h => q{a h–h},
			},
			hm => {
				a => q{a h:mm – a h:mm},
				h => q{a h:mm–h:mm},
				m => q{a h:mm–h:mm},
			},
			hmv => {
				a => q{a h:mm – a h:mm v},
				h => q{a h:mm–h:mm v},
				m => q{a h:mm–h:mm v},
			},
			hv => {
				a => q{a h – a h v},
				h => q{a h–h v},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y E – dd.MM.y E},
				d => q{dd.MM.y E – dd.MM.y E},
				y => q{dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y E – d MMM y E},
				d => q{d MMM y E – d MMM y E},
				y => q{d MMM y E – d MMM y E},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Saati),
		regionFormat => q({0} Yaz Saati),
		regionFormat => q({0} Standart Saati),
		'Acre' => {
			long => {
				'daylight' => q#Acre Yaz Saati#,
				'generic' => q#Acre Saati#,
				'standard' => q#Acre Standart Saati#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan Saati#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Cezayir#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzavil#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kahire#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kazablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Septe#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Darüsselam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Cibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Layun#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Cuba#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Hartum#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinşasa#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadişu#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trablus#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunus#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Orta Afrika Saati#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Doğu Afrika Saati#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Güney Afrika Standart Saati#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Batı Afrika Yaz Saati#,
				'generic' => q#Batı Afrika Saati#,
				'standard' => q#Batı Afrika Standart Saati#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Yaz Saati#,
				'generic' => q#Alaska Saati#,
				'standard' => q#Alaska Standart Saati#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatı Yaz Saati#,
				'generic' => q#Almatı Saati#,
				'standard' => q#Almatı Standart Saati#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon Yaz Saati#,
				'generic' => q#Amazon Saati#,
				'standard' => q#Amazon Standart Saati#,
			},
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Kuzey Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Merkez, Kuzey Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Kuzey Dakota#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Riko#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthelemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Kuzey Amerika Merkezi Yaz Saati#,
				'generic' => q#Kuzey Amerika Merkezi Saati#,
				'standard' => q#Kuzey Amerika Merkezi Standart Saati#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Kuzey Amerika Doğu Yaz Saati#,
				'generic' => q#Kuzey Amerika Doğu Saati#,
				'standard' => q#Kuzey Amerika Doğu Standart Saati#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Kuzey Amerika Dağ Yaz Saati#,
				'generic' => q#Kuzey Amerika Dağ Saati#,
				'standard' => q#Kuzey Amerika Dağ Standart Saati#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Kuzey Amerika Pasifik Yaz Saati#,
				'generic' => q#Kuzey Amerika Pasifik Saati#,
				'standard' => q#Kuzey Amerika Pasifik Standart Saati#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadır Yaz Saati#,
				'generic' => q#Anadyr Saati#,
				'standard' => q#Anadır Standart Saati#,
			},
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Showa#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Yaz Saati#,
				'generic' => q#Apia Saati#,
				'standard' => q#Apia Standart Saati#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aktav Yaz Saati#,
				'generic' => q#Aktav Saati#,
				'standard' => q#Aktav Standart Saati#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aktöbe Yaz Saati#,
				'generic' => q#Aktöbe Saati#,
				'standard' => q#Aktöbe Standart Saati#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabistan Yaz Saati#,
				'generic' => q#Arabistan Saati#,
				'standard' => q#Arabistan Standart Saati#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Arjantin Yaz Saati#,
				'generic' => q#Arjantin Saati#,
				'standard' => q#Arjantin Standart Saati#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Batı Arjantin Yaz Saati#,
				'generic' => q#Batı Arjantin Saati#,
				'standard' => q#Batı Arjantin Standart Saati#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ermenistan Yaz Saati#,
				'generic' => q#Ermenistan Saati#,
				'standard' => q#Ermenistan Standart Saati#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatı#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadır#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktav#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşkabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atırav#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bağdat#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahreyn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakü#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bişkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalküta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Çita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Şam#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dakka#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duşanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Gazimağusa#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gazze#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#El Halil#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#İrkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Cakarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Kudüs#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabil#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamçatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaçi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuçing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuveyt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Lefkoşa#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kızılorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh Kenti#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Semerkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Şanghay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taşkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tahran#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Batur#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumçi#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erivan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik Yaz Saati#,
				'generic' => q#Atlantik Saati#,
				'standard' => q#Atlantik Standart Saati#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azor Adaları#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarya Adaları#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira Adaları#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Güney Georgia#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Orta Avustralya Yaz Saati#,
				'generic' => q#Orta Avustralya Saati#,
				'standard' => q#Orta Avustralya Standart Saati#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#İç Batı Avustralya Yaz Saati#,
				'generic' => q#İç Batı Avustralya Saati#,
				'standard' => q#İç Batı Avustralya Standart Saati#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Doğu Avustralya Yaz Saati#,
				'generic' => q#Doğu Avustralya Saati#,
				'standard' => q#Doğu Avustralya Standart Saati#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Batı Avustralya Yaz Saati#,
				'generic' => q#Batı Avustralya Saati#,
				'standard' => q#Batı Avustralya Standart Saati#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaycan Yaz Saati#,
				'generic' => q#Azerbaycan Saati#,
				'standard' => q#Azerbaycan Standart Saati#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azorlar Yaz Saati#,
				'generic' => q#Azorlar Saati#,
				'standard' => q#Azorlar Standart Saati#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeş Yaz Saati#,
				'generic' => q#Bangladeş Saati#,
				'standard' => q#Bangladeş Standart Saati#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan Saati#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivya Saati#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia Yaz Saati#,
				'generic' => q#Brasilia Saati#,
				'standard' => q#Brasilia Standart Saati#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darü’s-Selam Saati#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cape Verde Yaz Saati#,
				'generic' => q#Cape Verde Saati#,
				'standard' => q#Cape Verde Standart Saati#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Casey Saati#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro Saati#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham Yaz Saati#,
				'generic' => q#Chatham Saati#,
				'standard' => q#Chatham Standart Saati#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Şili Yaz Saati#,
				'generic' => q#Şili Saati#,
				'standard' => q#Şili Standart Saati#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Çin Yaz Saati#,
				'generic' => q#Çin Saati#,
				'standard' => q#Çin Standart Saati#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmas Adası Saati#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos Adaları Saati#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolombiya Yaz Saati#,
				'generic' => q#Kolombiya Saati#,
				'standard' => q#Kolombiya Standart Saati#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Adaları Yarı Yaz Saati#,
				'generic' => q#Cook Adaları Saati#,
				'standard' => q#Cook Adaları Standart Saati#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Küba Yaz Saati#,
				'generic' => q#Küba Saati#,
				'standard' => q#Küba Standart Saati#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis Saati#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Saati#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Doğu Timor Saati#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Paskalya Adası Yaz Saati#,
				'generic' => q#Paskalya Adası Saati#,
				'standard' => q#Paskalya Adası Standart Saati#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvador Saati#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Eş Güdümlü Evrensel Zaman#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Bilinmeyen Şehir#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüksel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bükreş#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeşte#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kişinev#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhag#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#İrlanda Standart Saati#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Cebelitarık#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man Adası#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#İstanbul#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lizbon#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#İngiltere Yaz Saati#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lüksemburg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskova#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Saraybosna#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Üsküp#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholm#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiran#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viyana#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varşova#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürih#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Orta Avrupa Yaz Saati#,
				'generic' => q#Orta Avrupa Saati#,
				'standard' => q#Orta Avrupa Standart Saati#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Doğu Avrupa Yaz Saati#,
				'generic' => q#Doğu Avrupa Saati#,
				'standard' => q#Doğu Avrupa Standart Saati#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#İleri Doğu Avrupa Saati#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Batı Avrupa Yaz Saati#,
				'generic' => q#Batı Avrupa Saati#,
				'standard' => q#Batı Avrupa Standart Saati#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falkland Adaları Yaz Saati#,
				'generic' => q#Falkland Adaları Saati#,
				'standard' => q#Falkland Adaları Standart Saati#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji Yaz Saati#,
				'generic' => q#Fiji Saati#,
				'standard' => q#Fiji Standart Saati#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Fransız Guyanası Saati#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Fransız Güney ve Antarktika Saati#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Ortalama Saati#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos Saati#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier Saati#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gürcistan Yaz Saati#,
				'generic' => q#Gürcistan Saati#,
				'standard' => q#Gürcistan Standart Saati#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Adaları Saati#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Doğu Grönland Yaz Saati#,
				'generic' => q#Doğu Grönland Saati#,
				'standard' => q#Doğu Grönland Standart Saati#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Batı Grönland Yaz Saati#,
				'generic' => q#Batı Grönland Saati#,
				'standard' => q#Batı Grönland Standart Saati#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam Standart Saati#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Körfez Saati#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana Saati#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleut Yaz Saati#,
				'generic' => q#Hawaii-Aleut Saati#,
				'standard' => q#Hawaii-Aleut Standart Saati#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong Yaz Saati#,
				'generic' => q#Hong Kong Saati#,
				'standard' => q#Hong Kong Standart Saati#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Yaz Saati#,
				'generic' => q#Hovd Saati#,
				'standard' => q#Hovd Standart Saati#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hindistan Standart Saati#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komor#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivler#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hint Okyanusu Saati#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hindiçin Saati#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Orta Endonezya Saati#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Doğu Endonezya Saati#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Batı Endonezya Saati#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#İran Yaz Saati#,
				'generic' => q#İran Saati#,
				'standard' => q#İran Standart Saati#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#İrkutsk Yaz Saati#,
				'generic' => q#İrkutsk Saati#,
				'standard' => q#İrkutsk Standart Saati#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#İsrail Yaz Saati#,
				'generic' => q#İsrail Saati#,
				'standard' => q#İsrail Standart Saati#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japonya Yaz Saati#,
				'generic' => q#Japonya Saati#,
				'standard' => q#Japonya Standart Saati#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamçatski Yaz Saati#,
				'generic' => q#Petropavlovsk-Kamçatski Saati#,
				'standard' => q#Petropavlovsk-Kamçatski Standart Saati#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kazakistan Saati#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Doğu Kazakistan Saati#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Batı Kazakistan Saati#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Kore Yaz Saati#,
				'generic' => q#Kore Saati#,
				'standard' => q#Kore Standart Saati#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae Saati#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk Yaz Saati#,
				'generic' => q#Krasnoyarsk Saati#,
				'standard' => q#Krasnoyarsk Standart Saati#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kırgızistan Saati#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lanka Saati#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Adaları Saati#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe Yaz Saati#,
				'generic' => q#Lord Howe Saati#,
				'standard' => q#Lord Howe Standart Saati#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Makao Yaz Saati#,
				'generic' => q#Makao Saati#,
				'standard' => q#Makao Standart Saati#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan Yaz Saati#,
				'generic' => q#Magadan Saati#,
				'standard' => q#Magadan Standart Saati#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malezya Saati#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivler Saati#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markiz Adaları Saati#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Adaları Saati#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius Yaz Saati#,
				'generic' => q#Mauritius Saati#,
				'standard' => q#Mauritius Standart Saati#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson Saati#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksika Pasifik Kıyısı Yaz Saati#,
				'generic' => q#Meksika Pasifik Kıyısı Saati#,
				'standard' => q#Meksika Pasifik Kıyısı Standart Saati#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Batur Yaz Saati#,
				'generic' => q#Ulan Batur Saati#,
				'standard' => q#Ulan Batur Standart Saati#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskova Yaz Saati#,
				'generic' => q#Moskova Saati#,
				'standard' => q#Moskova Standart Saati#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar Saati#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Saati#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal Saati#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Yeni Kaledonya Yaz Saati#,
				'generic' => q#Yeni Kaledonya Saati#,
				'standard' => q#Yeni Kaledonya Standart Saati#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Yeni Zelanda Yaz Saati#,
				'generic' => q#Yeni Zelanda Saati#,
				'standard' => q#Yeni Zelanda Standart Saati#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland Yaz Saati#,
				'generic' => q#Newfoundland Saati#,
				'standard' => q#Newfoundland Standart Saati#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Saati#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Adası Yaz Saati#,
				'generic' => q#Norfolk Adası Saati#,
				'standard' => q#Norfolk Adası Standart Saati#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha Yaz Saati#,
				'generic' => q#Fernando de Noronha Saati#,
				'standard' => q#Fernando de Noronha Standart Saati#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Kuzey Mariana Adaları Saati#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk Yaz Saati#,
				'generic' => q#Novosibirsk Saati#,
				'standard' => q#Novosibirsk Standart Saati#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Yaz Saati#,
				'generic' => q#Omsk Saati#,
				'standard' => q#Omsk Standart Saati#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Paskalya Adası#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz Adaları#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan Yaz Saati#,
				'generic' => q#Pakistan Saati#,
				'standard' => q#Pakistan Standart Saati#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Saati#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Yeni Gine Saati#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay Yaz Saati#,
				'generic' => q#Paraguay Saati#,
				'standard' => q#Paraguay Standart Saati#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Yaz Saati#,
				'generic' => q#Peru Saati#,
				'standard' => q#Peru Standart Saati#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipinler Yaz Saati#,
				'generic' => q#Filipinler Saati#,
				'standard' => q#Filipinler Standart Saati#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix Adaları Saati#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint Pierre ve Miquelon Yaz Saati#,
				'generic' => q#Saint Pierre ve Miquelon Saati#,
				'standard' => q#Saint Pierre ve Miquelon Standart Saati#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn Saati#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Saati#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang Saati#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kızılorda Yaz Saati#,
				'generic' => q#Kızılorda Saati#,
				'standard' => q#Kızılorda Standart Saati#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunion Saati#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera Saati#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalin Yaz Saati#,
				'generic' => q#Sahalin Saati#,
				'standard' => q#Sahalin Standart Saati#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara Yaz Saati#,
				'generic' => q#Samara Saati#,
				'standard' => q#Samara Standart Saati#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Yaz Saati#,
				'generic' => q#Samoa Saati#,
				'standard' => q#Samoa Standart Saati#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seyşeller Saati#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur Standart Saati#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Adaları Saati#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Güney Georgia Saati#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam Saati#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Showa Saati#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Saati#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Yaz Saati#,
				'generic' => q#Taipei Saati#,
				'standard' => q#Taipei Standart Saati#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tacikistan Saati#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Saati#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga Yaz Saati#,
				'generic' => q#Tonga Saati#,
				'standard' => q#Tonga Standart Saati#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk Saati#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Türkmenistan Yaz Saati#,
				'generic' => q#Türkmenistan Saati#,
				'standard' => q#Türkmenistan Standart Saati#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu Saati#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay Yaz Saati#,
				'generic' => q#Uruguay Saati#,
				'standard' => q#Uruguay Standart Saati#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Özbekistan Yaz Saati#,
				'generic' => q#Özbekistan Saati#,
				'standard' => q#Özbekistan Standart Saati#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu Yaz Saati#,
				'generic' => q#Vanuatu Saati#,
				'standard' => q#Vanuatu Standart Saati#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela Saati#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Yaz Saati#,
				'generic' => q#Vladivostok Saati#,
				'standard' => q#Vladivostok Standart Saati#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd Yaz Saati#,
				'generic' => q#Volgograd Saati#,
				'standard' => q#Volgograd Standart Saati#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok Saati#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Adası Saati#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis ve Futuna Saati#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk Yaz Saati#,
				'generic' => q#Yakutsk Saati#,
				'standard' => q#Yakutsk Standart Saati#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg Yaz Saati#,
				'generic' => q#Yekaterinburg Saati#,
				'standard' => q#Yekaterinburg Standart Saati#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Saati#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
