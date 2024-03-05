=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Az - Package for language Azerbaijani

=cut

package Locale::CLDR::Locales::Az;
# This file auto generated from Data\common\main\az.xml
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
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator=),
				},
			},
		},
		'digits-ordinal-indicator' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(''inci),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(''inci),
				},
			},
		},
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
					rule => q(əksi →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sıfır),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← tam →→),
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
					rule => q(dörd),
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
					rule => q(yeddi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(səkkiz),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(doqquz),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(on[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(iyirmi[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(otuz[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(qırx[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(əlli[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(atmış[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(yetmiş[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(səqsən[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(doxsan[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← yüz[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← min[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← milyon[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← milyard[ →→]),
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
					rule => q(əksi →→),
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
					rule => q(yeddinci),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(səkkizinci),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(doqquzuncu),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(on→%%uncu→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(iyirmi→%%nci→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(otuz→%%uncu→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(qırx→%%inci2→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(əlli→%%nci→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(altmış→%%inci2→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(yetmiş→%%inci2→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(səqsən→%%inci2→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(doxsan→%%inci2→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering← yüz→%%uncu2→),
				},
				'1000' => {
					base_value => q(1000),
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
				'aa' => 'afar',
 				'ab' => 'abxaz',
 				'ace' => 'akin',
 				'ach' => 'akoli',
 				'ada' => 'adanqme',
 				'ady' => 'adıgey',
 				'ae' => 'avestan',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aqhem',
 				'ain' => 'aynu',
 				'ak' => 'akan',
 				'akk' => 'akkad',
 				'ale' => 'aleut',
 				'alt' => 'cənubi altay',
 				'am' => 'amhar',
 				'an' => 'araqon',
 				'ang' => 'qədim ingilis',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'ərəb',
 				'ar_001' => 'müasir standart ərəb',
 				'arc' => 'aramik',
 				'arn' => 'mapuçe',
 				'arp' => 'arapaho',
 				'ars' => 'Nəcd ərəbcəsi',
 				'arw' => 'aravak',
 				'as' => 'assam',
 				'asa' => 'asu',
 				'ast' => 'asturiya',
 				'atj' => 'Atikamek',
 				'av' => 'avar',
 				'awa' => 'avadhi',
 				'ay' => 'aymara',
 				'az' => 'azərbaycan',
 				'az@alt=short' => 'azəri',
 				'az_Arab' => 'cənubi azərbaycan',
 				'ba' => 'başqırd',
 				'bal' => 'baluc',
 				'ban' => 'bali',
 				'bas' => 'basa',
 				'be' => 'belarus',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bolqar',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'qərbi bəluc',
 				'bho' => 'bxoçpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bla' => 'siksikə',
 				'bm' => 'bambara',
 				'bn' => 'benqal',
 				'bo' => 'tibet',
 				'br' => 'breton',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosniya',
 				'bua' => 'buryat',
 				'bug' => 'bugin',
 				'byn' => 'blin',
 				'ca' => 'katalan',
 				'cad' => 'keddo',
 				'car' => 'karib',
 				'cay' => 'Kayuqa',
 				'cch' => 'atsam',
 				'ccp' => 'Çakma',
 				'ce' => 'çeçen',
 				'ceb' => 'sebuan',
 				'cgg' => 'çiqa',
 				'ch' => 'çamoro',
 				'chb' => 'çibça',
 				'chg' => 'çağatay',
 				'chk' => 'çukiz',
 				'chm' => 'mari',
 				'chn' => 'çinuk ləhçəsi',
 				'cho' => 'çoktau',
 				'chp' => 'çipevyan',
 				'chr' => 'çeroki',
 				'chy' => 'çeyen',
 				'ckb' => 'Mərkəzi kürdcə',
 				'ckb@alt=menu' => 'Kürdcə, mərkəzi',
 				'ckb@alt=variant' => 'Kürdcə, sorani',
 				'clc' => 'Çilotin',
 				'co' => 'korsika',
 				'cop' => 'kopt',
 				'cr' => 'kri',
 				'crg' => 'miçif',
 				'crh' => 'krım türkcəsi',
 				'crj' => 'cənub-şərqi kri',
 				'crk' => 'ova kricəsi',
 				'crl' => 'şimal-şəqri kri',
 				'crm' => 'muz kri',
 				'crr' => 'Karolina alonkincəsi',
 				'crs' => 'Seyşel kreol fransızcası',
 				'cs' => 'çex',
 				'csb' => 'kaşubyan',
 				'csw' => 'bataqlıq kricəsi',
 				'cu' => 'slavyan',
 				'cv' => 'çuvaş',
 				'cy' => 'uels',
 				'da' => 'danimarka',
 				'dak' => 'dakota',
 				'dar' => 'darqva',
 				'dav' => 'taita',
 				'de' => 'alman',
 				'de_AT' => 'Avstriya almancası',
 				'de_CH' => 'İsveçrə yüksək almancası',
 				'del' => 'delaver',
 				'den' => 'slavey',
 				'dgr' => 'doqrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'doqri',
 				'dsb' => 'aşağı sorb',
 				'dua' => 'duala',
 				'dum' => 'orta holland',
 				'dv' => 'maldiv',
 				'dyo' => 'diola',
 				'dyu' => 'dyula',
 				'dz' => 'dzonqxa',
 				'dzg' => 'dazaqa',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efik',
 				'egy' => 'qədim misir',
 				'eka' => 'ekacuk',
 				'el' => 'yunan',
 				'elx' => 'elamit',
 				'en' => 'ingilis',
 				'en_AU' => 'Avstraliya ingiliscəsi',
 				'en_CA' => 'Kanada ingiliscəsi',
 				'en_GB' => 'Britaniya ingiliscəsi',
 				'en_GB@alt=short' => 'ingilis (BK)',
 				'en_US' => 'Amerika ingiliscəsi',
 				'en_US@alt=short' => 'ingilis (ABŞ)',
 				'enm' => 'orta ingilis',
 				'eo' => 'esperanto',
 				'es' => 'ispan',
 				'es_419' => 'Latın Amerikası ispancası',
 				'es_ES' => 'Kastiliya ispancası',
 				'es_MX' => 'Meksika ispancası',
 				'et' => 'eston',
 				'eu' => 'bask',
 				'ewo' => 'evondo',
 				'fa' => 'fars',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'fin',
 				'fil' => 'filippin',
 				'fj' => 'fici',
 				'fo' => 'farer',
 				'fon' => 'fon',
 				'fr' => 'fransız',
 				'fr_CA' => 'Kanada fransızcası',
 				'fr_CH' => 'İsveçrə fransızcası',
 				'frc' => 'Kacun fransızcası',
 				'frm' => 'orta fransız',
 				'fro' => 'qədim fransız',
 				'frr' => 'şimali fris',
 				'fur' => 'friul',
 				'fy' => 'qərbi friz',
 				'ga' => 'irland',
 				'gaa' => 'qa',
 				'gag' => 'qaqauz',
 				'gan' => 'qan',
 				'gay' => 'qayo',
 				'gba' => 'qabaya',
 				'gd' => 'Şotlandiya keltcəsi',
 				'gez' => 'qez',
 				'gil' => 'qilbert',
 				'gl' => 'qalisiya',
 				'gmh' => 'orta yüksək alman',
 				'gn' => 'quarani',
 				'goh' => 'qədim alman',
 				'gon' => 'qondi',
 				'gor' => 'qorontalo',
 				'got' => 'qotika',
 				'grb' => 'qrebo',
 				'grc' => 'qədim yunan',
 				'gsw' => 'İsveçrə almancası',
 				'gu' => 'qucarat',
 				'guz' => 'qusi',
 				'gv' => 'manks',
 				'gwi' => 'qviçin',
 				'ha' => 'hausa',
 				'hai' => 'hayda',
 				'hak' => 'hakka',
 				'haw' => 'havay',
 				'hax' => 'cənubi haida',
 				'he' => 'ivrit',
 				'hi' => 'hind',
 				'hi_Latn' => 'Hindi (latın)',
 				'hil' => 'hiliqaynon',
 				'hit' => 'hittit',
 				'hmn' => 'monq',
 				'ho' => 'hiri motu',
 				'hr' => 'xorvat',
 				'hsb' => 'yuxarı sorb',
 				'hsn' => 'syan',
 				'ht' => 'haiti kreol',
 				'hu' => 'macar',
 				'hup' => 'hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'erməni',
 				'hz' => 'herero',
 				'ia' => 'interlinqua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indoneziya',
 				'ie' => 'interlinqve',
 				'ig' => 'iqbo',
 				'ii' => 'siçuan yi',
 				'ik' => 'inupiaq',
 				'ikt' => 'qərbi Kanada inuktitutu',
 				'ilo' => 'iloko',
 				'inh' => 'inquş',
 				'io' => 'ido',
 				'is' => 'island',
 				'it' => 'italyan',
 				'iu' => 'inuktitut',
 				'ja' => 'yapon',
 				'jbo' => 'loğban',
 				'jgo' => 'nqomba',
 				'jmc' => 'maçam',
 				'jpr' => 'ivrit-fars',
 				'jrb' => 'ivrit-ərəb',
 				'jv' => 'yava',
 				'ka' => 'gürcü',
 				'kaa' => 'qaraqalpaq',
 				'kab' => 'kabile',
 				'kac' => 'kaçin',
 				'kaj' => 'ju',
 				'kam' => 'kamba',
 				'kaw' => 'kavi',
 				'kbd' => 'kabarda-çərkəz',
 				'kcg' => 'tiyap',
 				'kde' => 'makond',
 				'kea' => 'kabuverdian',
 				'kfo' => 'koro',
 				'kg' => 'konqo',
 				'kgp' => 'kaiqanq',
 				'kha' => 'xazi',
 				'kho' => 'xotan',
 				'khq' => 'koyra çiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'qazax',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalencin',
 				'km' => 'kxmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreya',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkani',
 				'kos' => 'kosreyan',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'qaraçay-balkar',
 				'krl' => 'karel',
 				'kru' => 'kurux',
 				'ks' => 'kəşmir',
 				'ksb' => 'şambala',
 				'ksf' => 'bafia',
 				'ksh' => 'köln',
 				'ku' => 'kürd',
 				'kum' => 'kumık',
 				'kut' => 'kutenay',
 				'kv' => 'komi',
 				'kw' => 'korn',
 				'kwk' => 'Kvakvala',
 				'ky' => 'qırğız',
 				'la' => 'latın',
 				'lad' => 'sefard',
 				'lag' => 'langi',
 				'lah' => 'qərbi pəncab',
 				'lam' => 'lamba',
 				'lb' => 'lüksemburq',
 				'lez' => 'ləzgi',
 				'lg' => 'qanda',
 				'li' => 'limburq',
 				'lil' => 'Liluet',
 				'lkt' => 'lakota',
 				'ln' => 'linqala',
 				'lo' => 'laos',
 				'lol' => 'monqo',
 				'lou' => 'Luiziana kreolu',
 				'loz' => 'lozi',
 				'lrc' => 'şimali luri',
 				'lsm' => 'saamia',
 				'lt' => 'litva',
 				'lu' => 'luba-katanqa',
 				'lua' => 'luba-lulua',
 				'lui' => 'luyseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'latış',
 				'mad' => 'maduriz',
 				'mag' => 'maqahi',
 				'mai' => 'maitili',
 				'mak' => 'makasar',
 				'man' => 'məndinqo',
 				'mas' => 'masay',
 				'mdf' => 'mokşa',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisien',
 				'mg' => 'malaqas',
 				'mga' => 'orta irland',
 				'mgh' => 'maxuva-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marşal',
 				'mi' => 'māori',
 				'mic' => 'mikmak',
 				'min' => 'minanqkaban',
 				'mk' => 'makedon',
 				'ml' => 'malayalam',
 				'mn' => 'monqol',
 				'mnc' => 'mançu',
 				'mni' => 'manipüri',
 				'moe' => 'İnnu-aimun',
 				'moh' => 'mohavk',
 				'mos' => 'mosi',
 				'mr' => 'marathi',
 				'ms' => 'malay',
 				'mt' => 'malta',
 				'mua' => 'mundanq',
 				'mul' => 'çoxsaylı dillər',
 				'mus' => 'krik',
 				'mwl' => 'mirand',
 				'mwr' => 'maruari',
 				'my' => 'birman',
 				'myv' => 'erzya',
 				'mzn' => 'mazandaran',
 				'na' => 'nauru',
 				'nan' => 'Min Nan',
 				'nap' => 'neapolitan',
 				'naq' => 'nama',
 				'nb' => 'bokmal norveç',
 				'nd' => 'şimali ndebele',
 				'nds' => 'aşağı alman',
 				'nds_NL' => 'aşağı sakson',
 				'ne' => 'nepal',
 				'new' => 'nevari',
 				'ng' => 'ndonqa',
 				'nia' => 'nias',
 				'niu' => 'niyuan',
 				'nl' => 'holland',
 				'nl_BE' => 'flamand',
 				'nmg' => 'kvasio',
 				'nn' => 'nünorsk norveç',
 				'nnh' => 'ngiemboon',
 				'no' => 'norveç',
 				'nog' => 'noqay',
 				'non' => 'qədim nors',
 				'nqo' => 'nko',
 				'nr' => 'cənubi ndebele',
 				'nso' => 'şimal soto',
 				'nus' => 'nuer',
 				'nv' => 'navayo',
 				'ny' => 'nyanca',
 				'nym' => 'nyamvezi',
 				'nyn' => 'nyankol',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitan',
 				'oj' => 'ocibva',
 				'ojb' => 'şimal-qərbi ocibva',
 				'ojc' => 'Mərkəzi ocibva',
 				'ojs' => 'ocikri',
 				'ojw' => 'qərbi ocibva',
 				'oka' => 'okanaqan',
 				'om' => 'oromo',
 				'or' => 'odiya',
 				'os' => 'osetin',
 				'osa' => 'osage',
 				'ota' => 'osman',
 				'pa' => 'pəncab',
 				'pag' => 'panqasinan',
 				'pal' => 'pəhləvi',
 				'pam' => 'pampanqa',
 				'pap' => 'papyamento',
 				'pau' => 'palayan',
 				'pcm' => 'niger kreol',
 				'peo' => 'qədim fars',
 				'phn' => 'foyenik',
 				'pi' => 'pali',
 				'pis' => 'picin',
 				'pl' => 'polyak',
 				'pon' => 'ponpey',
 				'pqm' => 'malesit-passamakvodi',
 				'prg' => 'pruss',
 				'pro' => 'qədim provansal',
 				'ps' => 'puştu',
 				'pt' => 'portuqal',
 				'pt_BR' => 'Braziliya portuqalcası',
 				'pt_PT' => 'Portuqaliya portuqalcası',
 				'qu' => 'keçua',
 				'quc' => 'kiçe',
 				'raj' => 'racastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonqan',
 				'rhg' => 'Rohinca',
 				'rm' => 'romanş',
 				'rn' => 'rundi',
 				'ro' => 'rumın',
 				'ro_MD' => 'moldav',
 				'rof' => 'rombo',
 				'rom' => 'roman',
 				'ru' => 'rus',
 				'rup' => 'aroman',
 				'rw' => 'kinyarvanda',
 				'rwk' => 'rua',
 				'sa' => 'sanskrit',
 				'sad' => 'sandave',
 				'sah' => 'saxa',
 				'sam' => 'samaritan',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santal',
 				'sba' => 'nqambay',
 				'sbp' => 'sanqu',
 				'sc' => 'sardin',
 				'scn' => 'siciliya',
 				'sco' => 'skots',
 				'sd' => 'sindhi',
 				'sdh' => 'cənubi kürd',
 				'se' => 'şimali sami',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sanqo',
 				'sga' => 'qədim irland',
 				'sh' => 'serb-xorvat',
 				'shi' => 'taçelit',
 				'shn' => 'şan',
 				'si' => 'sinhala',
 				'sid' => 'sidamo',
 				'sk' => 'slovak',
 				'sl' => 'sloven',
 				'slh' => 'cənubi luşusid',
 				'sm' => 'samoa',
 				'sma' => 'cənubi sami',
 				'smj' => 'lule sami',
 				'smn' => 'inari sami',
 				'sms' => 'skolt sami',
 				'sn' => 'şona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'soqdiyen',
 				'sq' => 'alban',
 				'sr' => 'serb',
 				'srn' => 'sranan tonqo',
 				'srr' => 'serer',
 				'ss' => 'svati',
 				'ssy' => 'saho',
 				'st' => 'sesoto',
 				'str' => 'streyts saliş',
 				'su' => 'sundan',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeryan',
 				'sv' => 'isveç',
 				'sw' => 'suahili',
 				'sw_CD' => 'Konqo suahilicəsi',
 				'swb' => 'komor',
 				'syr' => 'suriya',
 				'ta' => 'tamil',
 				'tce' => 'cənubi tuçon',
 				'te' => 'teluqu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tacik',
 				'tgx' => 'taq',
 				'th' => 'tay',
 				'tht' => 'taltan',
 				'ti' => 'tiqrin',
 				'tig' => 'tiqre',
 				'tiv' => 'tiv',
 				'tk' => 'türkmən',
 				'tkl' => 'tokelay',
 				'tl' => 'taqaloq',
 				'tlh' => 'klinqon',
 				'tli' => 'tlinqit',
 				'tmh' => 'tamaşek',
 				'tn' => 'svana',
 				'to' => 'tonqa',
 				'tog' => 'nyasa tonqa',
 				'tok' => 'tokipona',
 				'tpi' => 'tok pisin',
 				'tr' => 'türk',
 				'trv' => 'taroko',
 				'ts' => 'sonqa',
 				'tsi' => 'simşyan',
 				'tt' => 'tatar',
 				'ttm' => 'şimali tuçon',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'tvi',
 				'twq' => 'tasavaq',
 				'ty' => 'taxiti',
 				'tyv' => 'tuvinyan',
 				'tzm' => 'Mərkəzi Atlas tamazicəsi',
 				'udm' => 'udmurt',
 				'ug' => 'uyğur',
 				'uga' => 'uqarit',
 				'uk' => 'ukrayna',
 				'umb' => 'umbundu',
 				'und' => 'naməlum dil',
 				'ur' => 'urdu',
 				'uz' => 'özbək',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vyetnam',
 				'vo' => 'volapük',
 				'vot' => 'votik',
 				'vun' => 'vunyo',
 				'wa' => 'valun',
 				'wae' => 'valles',
 				'wal' => 'valamo',
 				'war' => 'varay',
 				'was' => 'vaşo',
 				'wbp' => 'valpiri',
 				'wo' => 'volof',
 				'wuu' => 'vu',
 				'xal' => 'kalmık',
 				'xh' => 'xosa',
 				'xog' => 'soqa',
 				'yao' => 'yao',
 				'yap' => 'yapiz',
 				'yav' => 'yanqben',
 				'ybb' => 'yemba',
 				'yi' => 'idiş',
 				'yo' => 'yoruba',
 				'yrl' => 'nyenqatu',
 				'yue' => 'kanton',
 				'yue@alt=menu' => 'Çin, kanton',
 				'za' => 'çjuan',
 				'zap' => 'zapotek',
 				'zbl' => 'blisimbols',
 				'zen' => 'zenaqa',
 				'zgh' => 'tamazi',
 				'zh' => 'çin',
 				'zh@alt=menu' => 'Çin, mandarin',
 				'zh_Hans' => 'sadələşmiş çin',
 				'zh_Hans@alt=long' => 'sadələşmiş mandarin çincəsi',
 				'zh_Hant' => 'ənənəvi çin',
 				'zh_Hant@alt=long' => 'ənənəvi mandarin çincəsi',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'dil məzmunu yoxdur',
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
 			'Arab' => 'ərəb',
 			'Aran' => 'aran',
 			'Armi' => 'armi',
 			'Armn' => 'erməni',
 			'Avst' => 'avestan',
 			'Bali' => 'bali',
 			'Batk' => 'batak',
 			'Beng' => 'benqal',
 			'Blis' => 'blissymbols',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'brayl',
 			'Bugi' => 'buqin',
 			'Buhd' => 'buhid',
 			'Cakm' => 'çakma',
 			'Cans' => 'birləşmiş kanada yerli yazısı',
 			'Cari' => 'kariyan',
 			'Cham' => 'çam',
 			'Cher' => 'çiroki',
 			'Cirt' => 'sirt',
 			'Copt' => 'koptik',
 			'Cprt' => 'kipr',
 			'Cyrl' => 'kiril',
 			'Cyrs' => 'qədimi kilsa kirili',
 			'Deva' => 'devanaqari',
 			'Dsrt' => 'deseret',
 			'Egyd' => 'misir demotik',
 			'Egyh' => 'misir hiyeratik',
 			'Egyp' => 'misir hiyeroqlif',
 			'Ethi' => 'efiop',
 			'Geok' => 'gürcü xutsuri',
 			'Geor' => 'gürcü',
 			'Glag' => 'qlaqolitik',
 			'Goth' => 'qotik',
 			'Grek' => 'yunan',
 			'Gujr' => 'qucarat',
 			'Guru' => 'qurmuxi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hanqıl',
 			'Hani' => 'han',
 			'Hano' => 'hanunu',
 			'Hans' => 'sadələşmiş',
 			'Hans@alt=stand-alone' => 'Sadələşmiş Han',
 			'Hant' => 'ənənəvi',
 			'Hant@alt=stand-alone' => 'Ənənəvi Han',
 			'Hebr' => 'ibrani',
 			'Hira' => 'iraqana',
 			'Hmng' => 'pahav monq',
 			'Hrkt' => 'hecalı yapon əlifbası',
 			'Hung' => 'qədimi macar',
 			'Inds' => 'hindistan',
 			'Ital' => 'qədimi italyalı',
 			'Jamo' => 'jamo',
 			'Java' => 'cava',
 			'Jpan' => 'yapon',
 			'Kali' => 'kayax li',
 			'Kana' => 'katakana',
 			'Khar' => 'xaroşti',
 			'Khmr' => 'kxmer',
 			'Knda' => 'kannada',
 			'Kore' => 'koreya',
 			'Kthi' => 'kti',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'fraktur latını',
 			'Latg' => 'gael latını',
 			'Latn' => 'latın',
 			'Lepc' => 'lepçə',
 			'Limb' => 'limbu',
 			'Lyci' => 'lusian',
 			'Lydi' => 'ludian',
 			'Mand' => 'mandayen',
 			'Mani' => 'maniçayen',
 			'Maya' => 'maya hiyeroqlifi',
 			'Mero' => 'meroytik',
 			'Mlym' => 'malayalam',
 			'Mong' => 'monqol',
 			'Moon' => 'mun',
 			'Mtei' => 'meytey mayek',
 			'Mymr' => 'myanmar',
 			'Nkoo' => 'nko',
 			'Ogam' => 'oğam',
 			'Olck' => 'ol çiki',
 			'Orkh' => 'orxon',
 			'Orya' => 'oriya',
 			'Osma' => 'osmanya',
 			'Perm' => 'qədimi permik',
 			'Phag' => 'faqs-pa',
 			'Phli' => 'fli',
 			'Phlp' => 'flp',
 			'Phlv' => 'kitab paxlavi',
 			'Phnx' => 'foenik',
 			'Plrd' => 'polard fonetik',
 			'Prti' => 'prti',
 			'Rjng' => 'recəng',
 			'Rohg' => 'hanifi',
 			'Roro' => 'ronqoronqo',
 			'Runr' => 'runik',
 			'Samr' => 'samaritan',
 			'Sara' => 'sarati',
 			'Saur' => 'saurastra',
 			'Sgnw' => 'işarət yazısı',
 			'Shaw' => 'şavyan',
 			'Sinh' => 'sinhal',
 			'Sund' => 'sundan',
 			'Sylo' => 'siloti nəqri',
 			'Syrc' => 'siryak',
 			'Syre' => 'estrangela süryanice',
 			'Tagb' => 'taqbanva',
 			'Tale' => 'tay le',
 			'Talu' => 'təzə tay lu',
 			'Taml' => 'tamil',
 			'Tavt' => 'tavt',
 			'Telu' => 'teluqu',
 			'Teng' => 'tengvar',
 			'Tfng' => 'tifinaq',
 			'Tglg' => 'taqaloq',
 			'Thaa' => 'thana',
 			'Thai' => 'tay',
 			'Tibt' => 'tibet',
 			'Ugar' => 'uqarit',
 			'Vaii' => 'vay',
 			'Visp' => 'danışma səsləri',
 			'Xpeo' => 'qədimi fars',
 			'Xsux' => 'sumer-akadyan kuneyform',
 			'Yiii' => 'yi',
 			'Zmth' => 'riyazi notasiya',
 			'Zsye' => 'emoji',
 			'Zsym' => 'simvollar',
 			'Zxxx' => 'yazısız',
 			'Zyyy' => 'ümumi yazı',
 			'Zzzz' => 'tanınmayan yazı',

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
 			'003' => 'Şimali Amerika',
 			'005' => 'Cənubi Amerika',
 			'009' => 'Okeaniya',
 			'011' => 'Qərbi Afrika',
 			'013' => 'Mərkəzi Amerika',
 			'014' => 'Şərqi Afrika',
 			'015' => 'Şimali Afrika',
 			'017' => 'Mərkəzi Afrika',
 			'018' => 'Cənubi Afrika',
 			'019' => 'Amerika',
 			'021' => 'Şimal Amerikası',
 			'029' => 'Karib',
 			'030' => 'Şərqi Asiya',
 			'034' => 'Cənubi Asiya',
 			'035' => 'Cənub-Şərqi Asiya',
 			'039' => 'Cənubi Avropa',
 			'053' => 'Avstralaziya',
 			'054' => 'Melaneziya',
 			'057' => 'Mikroneziya Regionu',
 			'061' => 'Polineziya',
 			'142' => 'Asiya',
 			'143' => 'Mərkəzi Asiya',
 			'145' => 'Qərbi Asiya',
 			'150' => 'Avropa',
 			'151' => 'Şərqi Avropa',
 			'154' => 'Şimali Avropa',
 			'155' => 'Qərbi Avropa',
 			'202' => 'Saharadan cənub',
 			'419' => 'Latın Amerikası',
 			'AC' => 'Askenson adası',
 			'AD' => 'Andorra',
 			'AE' => 'Birləşmiş Ərəb Əmirlikləri',
 			'AF' => 'Əfqanıstan',
 			'AG' => 'Antiqua və Barbuda',
 			'AI' => 'Angilya',
 			'AL' => 'Albaniya',
 			'AM' => 'Ermənistan',
 			'AO' => 'Anqola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentina',
 			'AS' => 'Amerika Samoası',
 			'AT' => 'Avstriya',
 			'AU' => 'Avstraliya',
 			'AW' => 'Aruba',
 			'AX' => 'Aland adaları',
 			'AZ' => 'Azərbaycan',
 			'BA' => 'Bosniya və Herseqovina',
 			'BB' => 'Barbados',
 			'BD' => 'Banqladeş',
 			'BE' => 'Belçika',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bolqarıstan',
 			'BH' => 'Bəhreyn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sent-Bartelemi',
 			'BM' => 'Bermud adaları',
 			'BN' => 'Bruney',
 			'BO' => 'Boliviya',
 			'BQ' => 'Karib Niderlandı',
 			'BR' => 'Braziliya',
 			'BS' => 'Baham adaları',
 			'BT' => 'Butan',
 			'BV' => 'Buve adası',
 			'BW' => 'Botsvana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CC' => 'Kokos (Kilinq) adaları',
 			'CD' => 'Konqo - Kinşasa',
 			'CD@alt=variant' => 'Konqo (KDR)',
 			'CF' => 'Mərkəzi Afrika Respublikası',
 			'CG' => 'Konqo - Brazzavil',
 			'CG@alt=variant' => 'Konqo (Respublika)',
 			'CH' => 'İsveçrə',
 			'CI' => 'Kotd’ivuar',
 			'CI@alt=variant' => 'Fil Dişi Sahili',
 			'CK' => 'Kuk adaları',
 			'CL' => 'Çili',
 			'CM' => 'Kamerun',
 			'CN' => 'Çin',
 			'CO' => 'Kolumbiya',
 			'CP' => 'Klipperton adası',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabo-Verde',
 			'CW' => 'Kurasao',
 			'CX' => 'Milad adası',
 			'CY' => 'Kipr',
 			'CZ' => 'Çexiya',
 			'CZ@alt=variant' => 'Çex Respublikası',
 			'DE' => 'Almaniya',
 			'DG' => 'Dieqo Qarsiya',
 			'DJ' => 'Cibuti',
 			'DK' => 'Danimarka',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikan Respublikası',
 			'DZ' => 'Əlcəzair',
 			'EA' => 'Seuta və Melilya',
 			'EC' => 'Ekvador',
 			'EE' => 'Estoniya',
 			'EG' => 'Misir',
 			'EH' => 'Qərbi Saxara',
 			'ER' => 'Eritreya',
 			'ES' => 'İspaniya',
 			'ET' => 'Efiopiya',
 			'EU' => 'Avropa Birliyi',
 			'EZ' => 'Avrozona',
 			'FI' => 'Finlandiya',
 			'FJ' => 'Fici',
 			'FK' => 'Folklend adaları',
 			'FK@alt=variant' => 'Folklend adaları (Malvin adaları)',
 			'FM' => 'Mikroneziya',
 			'FO' => 'Farer adaları',
 			'FR' => 'Fransa',
 			'GA' => 'Qabon',
 			'GB' => 'Birləşmiş Krallıq',
 			'GB@alt=short' => 'BK',
 			'GD' => 'Qrenada',
 			'GE' => 'Gürcüstan',
 			'GF' => 'Fransa Qvianası',
 			'GG' => 'Gernsi',
 			'GH' => 'Qana',
 			'GI' => 'Cəbəllütariq',
 			'GL' => 'Qrenlandiya',
 			'GM' => 'Qambiya',
 			'GN' => 'Qvineya',
 			'GP' => 'Qvadelupa',
 			'GQ' => 'Ekvatorial Qvineya',
 			'GR' => 'Yunanıstan',
 			'GS' => 'Cənubi Corciya və Cənubi Sendviç adaları',
 			'GT' => 'Qvatemala',
 			'GU' => 'Quam',
 			'GW' => 'Qvineya-Bisau',
 			'GY' => 'Qayana',
 			'HK' => 'Honq Konq Xüsusi İnzibati Rayonu Çin',
 			'HK@alt=short' => 'Honq Konq',
 			'HM' => 'Herd və Makdonald adaları',
 			'HN' => 'Honduras',
 			'HR' => 'Xorvatiya',
 			'HT' => 'Haiti',
 			'HU' => 'Macarıstan',
 			'IC' => 'Kanar adaları',
 			'ID' => 'İndoneziya',
 			'IE' => 'İrlandiya',
 			'IL' => 'İsrail',
 			'IM' => 'Men adası',
 			'IN' => 'Hindistan',
 			'IO' => 'Britaniyanın Hind Okeanı Ərazisi',
 			'IO@alt=chagos' => 'Çaqos arxipelaqı',
 			'IQ' => 'İraq',
 			'IR' => 'İran',
 			'IS' => 'İslandiya',
 			'IT' => 'İtaliya',
 			'JE' => 'Cersi',
 			'JM' => 'Yamayka',
 			'JO' => 'İordaniya',
 			'JP' => 'Yaponiya',
 			'KE' => 'Keniya',
 			'KG' => 'Qırğızıstan',
 			'KH' => 'Kamboca',
 			'KI' => 'Kiribati',
 			'KM' => 'Komor adaları',
 			'KN' => 'Sent-Kits və Nevis',
 			'KP' => 'Şimali Koreya',
 			'KR' => 'Cənubi Koreya',
 			'KW' => 'Küveyt',
 			'KY' => 'Kayman adaları',
 			'KZ' => 'Qazaxıstan',
 			'LA' => 'Laos',
 			'LB' => 'Livan',
 			'LC' => 'Sent-Lusiya',
 			'LI' => 'Lixtenşteyn',
 			'LK' => 'Şri-Lanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litva',
 			'LU' => 'Lüksemburq',
 			'LV' => 'Latviya',
 			'LY' => 'Liviya',
 			'MA' => 'Mərakeş',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Monteneqro',
 			'MF' => 'Sent Martin',
 			'MG' => 'Madaqaskar',
 			'MH' => 'Marşal adaları',
 			'MK' => 'Şimali Makedoniya',
 			'ML' => 'Mali',
 			'MM' => 'Myanma',
 			'MN' => 'Monqolustan',
 			'MO' => 'Makao XİR Çin',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Şimali Marian adaları',
 			'MQ' => 'Martinik',
 			'MR' => 'Mavritaniya',
 			'MS' => 'Monserat',
 			'MT' => 'Malta',
 			'MU' => 'Mavriki',
 			'MV' => 'Maldiv adaları',
 			'MW' => 'Malavi',
 			'MX' => 'Meksika',
 			'MY' => 'Malayziya',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibiya',
 			'NC' => 'Yeni Kaledoniya',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk adası',
 			'NG' => 'Nigeriya',
 			'NI' => 'Nikaraqua',
 			'NL' => 'Niderland',
 			'NO' => 'Norveç',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Yeni Zelandiya',
 			'NZ@alt=variant' => 'Aotearoa Yeni Zelandiya',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransa Polineziyası',
 			'PG' => 'Papua-Yeni Qvineya',
 			'PH' => 'Filippin',
 			'PK' => 'Pakistan',
 			'PL' => 'Polşa',
 			'PM' => 'Müqəddəs Pyer və Mikelon',
 			'PN' => 'Pitkern adaları',
 			'PR' => 'Puerto Riko',
 			'PS' => 'Fələstin Əraziləri',
 			'PS@alt=short' => 'Fələstin',
 			'PT' => 'Portuqaliya',
 			'PW' => 'Palau',
 			'PY' => 'Paraqvay',
 			'QA' => 'Qətər',
 			'QO' => 'Uzaq Okeaniya',
 			'RE' => 'Reyunyon',
 			'RO' => 'Rumıniya',
 			'RS' => 'Serbiya',
 			'RU' => 'Rusiya',
 			'RW' => 'Ruanda',
 			'SA' => 'Səudiyyə Ərəbistanı',
 			'SB' => 'Solomon adaları',
 			'SC' => 'Seyşel adaları',
 			'SD' => 'Sudan',
 			'SE' => 'İsveç',
 			'SG' => 'Sinqapur',
 			'SH' => 'Müqəddəs Yelena',
 			'SI' => 'Sloveniya',
 			'SJ' => 'Svalbard və Yan-Mayen',
 			'SK' => 'Slovakiya',
 			'SL' => 'Syerra-Leone',
 			'SM' => 'San-Marino',
 			'SN' => 'Seneqal',
 			'SO' => 'Somali',
 			'SR' => 'Surinam',
 			'SS' => 'Cənubi Sudan',
 			'ST' => 'San-Tome və Prinsipi',
 			'SV' => 'Salvador',
 			'SX' => 'Sint-Marten',
 			'SY' => 'Suriya',
 			'SZ' => 'Esvatini',
 			'SZ@alt=variant' => 'Svazilend',
 			'TA' => 'Tristan da Kunya',
 			'TC' => 'Törks və Kaykos adaları',
 			'TD' => 'Çad',
 			'TF' => 'Fransanın Cənub Əraziləri',
 			'TG' => 'Toqo',
 			'TH' => 'Tailand',
 			'TJ' => 'Tacikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Şərqi Timor',
 			'TM' => 'Türkmənistan',
 			'TN' => 'Tunis',
 			'TO' => 'Tonqa',
 			'TR' => 'Türkiyə',
 			'TT' => 'Trinidad və Tobaqo',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayvan',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Ukrayna',
 			'UG' => 'Uqanda',
 			'UM' => 'ABŞ-a bağlı kiçik adacıqlar',
 			'UN' => 'Birləşmiş Millətlər Təşkilatı',
 			'UN@alt=short' => 'BMT',
 			'US' => 'Amerika Birləşmiş Ştatları',
 			'US@alt=short' => 'ABŞ',
 			'UY' => 'Uruqvay',
 			'UZ' => 'Özbəkistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Sent-Vinsent və Qrenadinlər',
 			'VE' => 'Venesuela',
 			'VG' => 'Britaniyanın Virgin adaları',
 			'VI' => 'ABŞ Virgin adaları',
 			'VN' => 'Vyetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Uollis və Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Psevdo-Aksent',
 			'XB' => 'Psevdo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yəmən',
 			'YT' => 'Mayot',
 			'ZA' => 'Cənub Afrika',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Naməlum Region',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Təqvim',
 			'cf' => 'Valyuta Formatı',
 			'collation' => 'Sıralama',
 			'currency' => 'Valyuta',
 			'hc' => 'Saat Sikli (12 / 24)',
 			'lb' => 'Sətirdən sətrə keçirmə üslubu',
 			'ms' => 'Ölçü Sistemi',
 			'numbers' => 'Rəqəmlər',

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
 				'buddhist' => q{Buddist təqvimi},
 				'chinese' => q{Çin təqvimi},
 				'coptic' => q{Kopt təqvimi},
 				'dangi' => q{Dangi təqvimi},
 				'ethiopic' => q{Efiop təqvimi},
 				'ethiopic-amete-alem' => q{Efiop amet-alem təqvimi},
 				'gregorian' => q{Qreqorian təqvimi},
 				'hebrew' => q{Yəhudi Təqvimi},
 				'indian' => q{Hindi təqvimi},
 				'islamic' => q{Hicri təqvimi},
 				'islamic-civil' => q{Hicri təqvimi (tabulyar, vətəndaşlıq dövrü)},
 				'islamic-tbla' => q{Hicri təqvim (tabulyar, astromonik dövr)},
 				'islamic-umalqura' => q{Hicri təqvim (Umm əl-Qura)},
 				'iso8601' => q{ISO-8601 Təqvimi},
 				'japanese' => q{Yapon Təqvimi},
 				'persian' => q{İran Təqvimi},
 				'roc' => q{Minquo Təqvimi},
 			},
 			'cf' => {
 				'account' => q{Uçot Valyuta Formatı},
 				'standard' => q{Standart Valyuta Formatı},
 			},
 			'collation' => {
 				'ducet' => q{Standart Unicode Sıralama},
 				'pinyin' => q{Pinyin təqvimi},
 				'search' => q{Ümumi Məqsədli Axtarış},
 				'standard' => q{Standart Sıralama},
 			},
 			'hc' => {
 				'h11' => q{12 Saatlıq Sistem (0–11)},
 				'h12' => q{12 Saatlıq Sistem (0–12)},
 				'h23' => q{24 Saatlıq Sistem (0–23)},
 				'h24' => q{24 Saatlıq Sistem (0–23)},
 			},
 			'lb' => {
 				'loose' => q{Sərbəst sətirdən sətrə keçirmə üslubu},
 				'normal' => q{Normal sətirdən sətrə keçirmə üslubu},
 				'strict' => q{Sərt sətirdən sətrə keçirmə üslubu},
 			},
 			'ms' => {
 				'metric' => q{Metrik Sistem},
 				'uksystem' => q{İmperial Ölçü Sistemi},
 				'ussystem' => q{ABŞ Ölçü Sistemi},
 			},
 			'numbers' => {
 				'arab' => q{Ərəb-Hind Rəqəmləri},
 				'arabext' => q{Genişlənmiş Ərəb-Hind Rəqəmləri},
 				'armn' => q{Erməni Rəqəmləri},
 				'armnlow' => q{Kiçik Erməni Rəqəmləri},
 				'beng' => q{Benqal Rəqəmləri},
 				'cakm' => q{Çakma rəqəmləri},
 				'deva' => q{Devanaqari Rəqəmləri},
 				'ethi' => q{Efiop Rəqəmləri},
 				'fullwide' => q{Tam Geniş Rəqəmlər},
 				'geor' => q{Gürcü Rəqəmləri},
 				'grek' => q{Yunan Rəqəmləri},
 				'greklow' => q{Kiçik Yunan Rəqəmləri},
 				'gujr' => q{Qucarat Rəqəmləri},
 				'guru' => q{Qurmuxi Rəqəmləri},
 				'hanidec' => q{Onluq Çin Rəqəmləri},
 				'hans' => q{Sadələşmiş Çin Rəqəmləri},
 				'hansfin' => q{Sadələşmiş Çin Maliyyə Rəqəmləri},
 				'hant' => q{Ənənəvi Çin Rəqəmləri},
 				'hantfin' => q{Ənənəvi Çin Maliyyə Rəqəmləri},
 				'hebr' => q{İvrit Rəqəmləri},
 				'java' => q{Cava rəqəmləri},
 				'jpan' => q{Yapon Rəqəmləri},
 				'jpanfin' => q{Yapon Maliyyə Rəqəmləri},
 				'khmr' => q{Kxmer Rəqəmləri},
 				'knda' => q{Kannada Rəqəmləri},
 				'laoo' => q{Lao Rəqəmləri},
 				'latn' => q{Qərb Rəqəmləri},
 				'mlym' => q{Malayalam Rəqəmləri},
 				'mtei' => q{Mitei Mayek rəqəmləri},
 				'mymr' => q{Myanma Rəqəmləri},
 				'olck' => q{Ol Çiki rəqəmləri},
 				'orya' => q{Oriya Rəqəmləri},
 				'roman' => q{Rum Rəqəmləri},
 				'romanlow' => q{Kiçik Rum Rəqəmləri},
 				'taml' => q{Ənənəvi Tamil Rəqəmləri},
 				'tamldec' => q{Tamil Rəqəmləri},
 				'telu' => q{Teluqu Rəqəmləri},
 				'thai' => q{Tay Rəqəmləri},
 				'tibt' => q{Tibet Rəqəmləri},
 				'vaii' => q{Vai rəqəmləri},
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
 			'UK' => q{Britaniya},
 			'US' => q{ABŞ},

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
 			'script' => 'Skript: {0}',
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
			auxiliary => qr{[w]},
			index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ə', 'F', 'G', 'Ğ', 'H', 'X', 'I', 'İ', 'J', 'K', 'Q', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z', 'W'],
			main => qr{[a b c ç d e ə f g ğ h x ı iİ j k q l m n o ö p r s ş t u ü v y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ə', 'F', 'G', 'Ğ', 'H', 'X', 'I', 'İ', 'J', 'K', 'Q', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z', 'W'], };
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
						'name' => q(kardinal istiqamət),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kardinal istiqamət),
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
						'1' => q(ronto {0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto {0}),
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
						'1' => q(kvekto {0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kvekto {0}),
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
						'1' => q(ronna {0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna {0}),
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
						'1' => q(kvetta {0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kvetta {0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(meqa{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(meqa{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giqa{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giqa{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} g qüvvəsi),
						'other' => q({0} g qüvvəsi),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g qüvvəsi),
						'other' => q({0} g qüvvəsi),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metr kvadrat saniyə),
						'one' => q({0} metr kvadrat saniyə),
						'other' => q({0} metr kvadrat saniyə),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metr kvadrat saniyə),
						'one' => q({0} metr kvadrat saniyə),
						'other' => q({0} metr kvadrat saniyə),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} dəqiqə),
						'other' => q({0} dəqiqə),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} dəqiqə),
						'other' => q({0} dəqiqə),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} saniyə),
						'other' => q({0} saniyə),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} saniyə),
						'other' => q({0} saniyə),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} dərəcə),
						'other' => q({0} dərəcə),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} dərəcə),
						'other' => q({0} dərəcə),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(dövrə),
						'one' => q({0} dövrə),
						'other' => q({0} dövrə),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(dövrə),
						'one' => q({0} dövrə),
						'other' => q({0} dövrə),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} akr),
						'other' => q({0} akr),
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
						'name' => q(kvadrat santimetr),
						'one' => q({0} kvadrat santimetr),
						'other' => q({0} kvadrat santimetr),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(kvadrat santimetr),
						'one' => q({0} kvadrat santimetr),
						'other' => q({0} kvadrat santimetr),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} kvadrat fut),
						'other' => q({0} kvadrat fut),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} kvadrat fut),
						'other' => q({0} kvadrat fut),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrat düym),
						'one' => q({0} kvadrat düym),
						'other' => q({0} kvadrat düym),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrat düym),
						'one' => q({0} kvadrat düym),
						'other' => q({0} kvadrat düym),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} kvadrat kilometr),
						'other' => q({0} kvadrat kilometr),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} kvadrat kilometr),
						'other' => q({0} kvadrat kilometr),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} kvadrat metr),
						'other' => q({0} kvadrat metr),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} kvadrat metr),
						'other' => q({0} kvadrat metr),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} kvadrat mil),
						'other' => q({0} kvadrat mil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} kvadrat mil),
						'other' => q({0} kvadrat mil),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milliqram/desilitr),
						'one' => q({0} milliqram/desilitr),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milliqram/desilitr),
						'one' => q({0} milliqram/desilitr),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} faiz),
						'other' => q({0} faiz),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} faiz),
						'other' => q({0} faiz),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} promil),
						'other' => q({0} promil),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} promil),
						'other' => q({0} promil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(milyonda hissəcik),
						'one' => q({0} milyonda hissəcik),
						'other' => q({0} milyonda hissəcik),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(milyonda hissəcik),
						'one' => q({0} milyonda hissəcik),
						'other' => q({0} milyonda hissəcik),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} permiriada),
						'other' => q({0} permiriada),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} permiriada),
						'other' => q({0} permiriada),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(100 kilometrə litr),
						'one' => q(100 kilometrə {0} litr),
						'other' => q(100 kilometrə {0} litr),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(100 kilometrə litr),
						'one' => q(100 kilometrə {0} litr),
						'other' => q(100 kilometrə {0} litr),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(qallona mil),
						'one' => q(qallona {0} mil),
						'other' => q(qallona {0} mil),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(qallona mil),
						'one' => q(qallona {0} mil),
						'other' => q(qallona {0} mil),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(imp. qallona mil),
						'one' => q(imp. qallona {0} mil),
						'other' => q(imp. qallona {0} mil),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(imp. qallona mil),
						'one' => q(imp. qallona {0} mil),
						'other' => q(imp. qallona {0} mil),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(giqabit),
						'one' => q({0} giqabit),
						'other' => q({0} giqabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(giqabit),
						'one' => q({0} giqabit),
						'other' => q({0} giqabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(giqabayt),
						'one' => q({0} giqabayt),
						'other' => q({0} giqabayt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(giqabayt),
						'one' => q({0} giqabayt),
						'other' => q({0} giqabayt),
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
						'name' => q(meqabit),
						'one' => q({0} meqabit),
						'other' => q({0} meqabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(meqabit),
						'one' => q({0} meqabit),
						'other' => q({0} meqabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(meqabayt),
						'one' => q({0} meqabayt),
						'other' => q({0} meqabayt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(meqabayt),
						'one' => q({0} meqabayt),
						'other' => q({0} meqabayt),
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
					'duration-decade' => {
						'name' => q(dekada),
						'one' => q({0} dekada),
						'other' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekada),
						'one' => q({0} dekada),
						'other' => q({0} dek),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosaniyə),
						'one' => q({0} mikrosaniyə),
						'other' => q({0} mikrosaniyə),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosaniyə),
						'one' => q({0} mikrosaniyə),
						'other' => q({0} mikrosaniyə),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} millisaniyə),
						'other' => q({0} millisaniyə),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} millisaniyə),
						'other' => q({0} millisaniyə),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} dəqiqə),
						'other' => q({0} dəqiqə),
						'per' => q({0}/dəqiqə),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} dəqiqə),
						'other' => q({0} dəqiqə),
						'per' => q({0}/dəqiqə),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosaniyə),
						'one' => q({0} nanosaniyə),
						'other' => q({0} nanosaniyə),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosaniyə),
						'one' => q({0} nanosaniyə),
						'other' => q({0} nanosaniyə),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} saniyə),
						'other' => q({0} saniyə),
						'per' => q({0}/saniyə),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} saniyə),
						'other' => q({0} saniyə),
						'per' => q({0}/saniyə),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} həftə),
						'other' => q({0} həftə),
						'per' => q({0}/həftə),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} həftə),
						'other' => q({0} həftə),
						'per' => q({0}/həftə),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} om),
						'other' => q({0} om),
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
						'name' => q(Britaniya termal vahidi),
						'one' => q({0} Britaniya terman vahidi),
						'other' => q({0} Britaniya terman vahidi),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Britaniya termal vahidi),
						'one' => q({0} Britaniya terman vahidi),
						'other' => q({0} Britaniya terman vahidi),
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
						'name' => q(Kalori),
						'one' => q({0} Kalori),
						'other' => q({0} Kalori),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kalori),
						'one' => q({0} Kalori),
						'other' => q({0} Kalori),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} coul),
						'other' => q({0} coul),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} coul),
						'other' => q({0} coul),
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
						'name' => q(kilocoul),
						'one' => q({0} kilocoul),
						'other' => q({0} kilocoul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilocoul),
						'one' => q({0} kilocoul),
						'other' => q({0} kilocoul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovatt-saat),
						'one' => q({0} kilovatt-saat),
						'other' => q({0} kilovatt-saat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovatt-saat),
						'one' => q({0} kilovatt-saat),
						'other' => q({0} kilovatt-saat),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ABŞ termal vahidi),
						'one' => q({0} ABŞ termal vahidi),
						'other' => q({0} ABŞ termal vahidi),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ABŞ termal vahidi),
						'one' => q({0} ABŞ termal vahidi),
						'other' => q({0} ABŞ termal vahidi),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kVtst/100km),
						'other' => q({0} kVtst/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kVtst/100km),
						'other' => q({0} kVtst/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} nyuton),
						'other' => q({0} nyuton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} nyuton),
						'other' => q({0} nyuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} güc funtu),
						'other' => q({0} güc funtu),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} güc funtu),
						'other' => q({0} güc funtu),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(giqahers),
						'one' => q({0} giqahers),
						'other' => q({0} giqahers),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(giqahers),
						'one' => q({0} giqahers),
						'other' => q({0} giqahers),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hers),
						'one' => q({0} hers),
						'other' => q({0} hers),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hers),
						'one' => q({0} hers),
						'other' => q({0} hers),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohers),
						'one' => q({0} kilohers),
						'other' => q({0} kilohers),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohers),
						'one' => q({0} kilohers),
						'other' => q({0} kilohers),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(meqahers),
						'one' => q({0} meqahers),
						'other' => q({0} meqahers),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(meqahers),
						'one' => q({0} meqahers),
						'other' => q({0} meqahers),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nöqtə / santimetr),
						'one' => q({0} nöqtə / santimetr),
						'other' => q({0} nöqtə / santimetr),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nöqtə / santimetr),
						'one' => q({0} nöqtə / santimetr),
						'other' => q({0} nöqtə / santimetr),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nöqtə / düym),
						'one' => q({0} nöqtə / düym),
						'other' => q({0} nöqtə / düym),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nöqtə / düym),
						'one' => q({0} nöqtə / düym),
						'other' => q({0} nöqtə / düym),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipoqraf emi),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipoqraf emi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} meqapiksel),
						'other' => q({0} meqapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} meqapiksel),
						'other' => q({0} meqapiksel),
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
						'name' => q(piksel / santimetr),
						'one' => q({0} piksel / santimetr),
						'other' => q({0} piksel / santimetr),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel / santimetr),
						'one' => q({0} piksel / santimetr),
						'other' => q({0} piksel / santimetr),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel / düym),
						'one' => q({0} piksel / düym),
						'other' => q({0} piksel / düym),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel / düym),
						'one' => q({0} piksel / düym),
						'other' => q({0} piksel / düym),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomik vahid),
						'one' => q({0} astronomik vahid),
						'other' => q({0} astronomik vahid),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomik vahid),
						'one' => q({0} astronomik vahid),
						'other' => q({0} astronomik vahid),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0} yer radiusu),
						'other' => q({0} yer radiusu),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0} yer radiusu),
						'other' => q({0} yer radiusu),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fatom),
						'other' => q({0} fatom),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fatom),
						'other' => q({0} fatom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} fut),
						'other' => q({0} fut),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} fut),
						'other' => q({0} fut),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} düym),
						'other' => q({0} düym),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} düym),
						'other' => q({0} düym),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} işıq ili),
						'other' => q({0} işıq ili),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} işıq ili),
						'other' => q({0} işıq ili),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} metr),
						'other' => q({0} metr),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} metr),
						'other' => q({0} metr),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Günəş radiusu),
						'one' => q({0} günəş radiusu),
						'other' => q({0} günəş radiusu),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Günəş radiusu),
						'one' => q({0} günəş radiusu),
						'other' => q({0} günəş radiusu),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yard),
						'other' => q({0} yard),
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
						'one' => q({0} gün işığı),
						'other' => q({0} gün işığı),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} gün işığı),
						'other' => q({0} gün işığı),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
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
						'one' => q({0} yer kütləsi),
						'other' => q({0} yer kütləsi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} yer kütləsi),
						'other' => q({0} yer kütləsi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} qram),
						'other' => q({0} qram),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} qram),
						'other' => q({0} qram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kiloqram),
						'other' => q({0} kiloqram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kiloqram),
						'other' => q({0} kiloqram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikroqram),
						'one' => q({0} mikroqram),
						'other' => q({0} mikroqram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikroqram),
						'one' => q({0} mikroqram),
						'other' => q({0} mikroqram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milliqram),
						'one' => q({0} milliqram),
						'other' => q({0} milliqram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milliqram),
						'one' => q({0} milliqram),
						'other' => q({0} milliqram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy unsiyası),
						'one' => q({0} troy unsiyası),
						'other' => q({0} troy unsiyası),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy unsiyası),
						'one' => q({0} troy unsiyası),
						'other' => q({0} troy unsiyası),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} funt),
						'other' => q({0} funt),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} funt),
						'other' => q({0} funt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} günəş kütləsi),
						'other' => q({0} günəş kütləsi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} günəş kütləsi),
						'other' => q({0} günəş kütləsi),
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
					'mass-tonne' => {
						'name' => q(metrik ton),
						'one' => q({0} metrik ton),
						'other' => q({0} metrik ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrik ton),
						'one' => q({0} metrik ton),
						'other' => q({0} metrik ton),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(giqavatt),
						'one' => q({0} giqavatt),
						'other' => q({0} giqavatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(giqavatt),
						'one' => q({0} giqavatt),
						'other' => q({0} giqavatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} at gücü),
						'other' => q({0} at gücü),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} at gücü),
						'other' => q({0} at gücü),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(meqavatt),
						'one' => q({0} meqavatt),
						'other' => q({0} meqavatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(meqavatt),
						'one' => q({0} meqavatt),
						'other' => q({0} meqavatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(millivatt),
						'one' => q({0} millivatt),
						'other' => q({0} millivatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(millivatt),
						'one' => q({0} millivatt),
						'other' => q({0} millivatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} vatt),
						'other' => q({0} vatt),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} vatt),
						'other' => q({0} vatt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(kvadrat{0}),
						'one' => q(kvadrat {0}),
						'other' => q(kvadrat {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(kvadrat{0}),
						'one' => q(kvadrat {0}),
						'other' => q(kvadrat {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kub {0}),
						'one' => q(kub {0}),
						'other' => q(kub {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kub {0}),
						'one' => q(kub {0}),
						'other' => q(kub {0}),
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
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
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
						'name' => q(meqapaskal),
						'one' => q({0} meqapaskal),
						'other' => q({0} meqapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(meqapaskal),
						'one' => q({0} meqapaskal),
						'other' => q({0} meqapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimetr civə sütunu),
						'one' => q({0} millimetr civə sütunu),
						'other' => q({0} millimetr civə sütunu),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetr civə sütunu),
						'one' => q({0} millimetr civə sütunu),
						'other' => q({0} millimetr civə sütunu),
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
						'name' => q(funt/kvadrat düym),
						'one' => q({0} funt/kvadrat düym),
						'other' => q({0} funt/kvadrat düym),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(funt/kvadrat düym),
						'one' => q({0} funt/kvadrat düym),
						'other' => q({0} funt/kvadrat düym),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q(Bofor {0}),
						'other' => q(Bofor {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(Bofor {0}),
						'other' => q(Bofor {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} kilometr/saat),
						'other' => q({0} kilometr/saat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} kilometr/saat),
						'other' => q({0} kilometr/saat),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} metr/saniyə),
						'other' => q({0} metr/saniyə),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} metr/saniyə),
						'other' => q({0} metr/saniyə),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} dərəcə Selsi),
						'other' => q({0} dərəcə Selsi),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} dərəcə Selsi),
						'other' => q({0} dərəcə Selsi),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} dərəcə Farengeyt),
						'other' => q({0} dərəcə Farengeyt),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} dərəcə Farengeyt),
						'other' => q({0} dərəcə Farengeyt),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(dərəcə Kelvin),
						'one' => q({0} dərəcə Kelvin),
						'other' => q({0} dərəcə Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(dərəcə Kelvin),
						'one' => q({0} dərəcə Kelvin),
						'other' => q({0} dərəcə Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(nyuton-metr),
						'one' => q({0} nyuton-metr),
						'other' => q({0} nyuton-metr),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(nyuton-metr),
						'one' => q({0} nyuton-metr),
						'other' => q({0} nyuton-metr),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(funt-fut),
						'one' => q({0} funt-fut),
						'other' => q({0} funt-fut),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(funt-fut),
						'one' => q({0} funt-fut),
						'other' => q({0} funt-fut),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akr-fut),
						'one' => q({0} akr-fut),
						'other' => q({0} akr-fut),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akr-fut),
						'one' => q({0} akr-fut),
						'other' => q({0} akr-fut),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kub düym),
						'one' => q({0} kub düym),
						'other' => q({0} kub düym),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kub düym),
						'one' => q({0} kub düym),
						'other' => q({0} kub düym),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} kub yard),
						'other' => q({0} kub yard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} kub yard),
						'other' => q({0} kub yard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(stəkan),
						'one' => q({0} stəkan),
						'other' => q({0} stəkan),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(stəkan),
						'one' => q({0} stəkan),
						'other' => q({0} stəkan),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitr),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitr),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dessert qaşığı),
						'one' => q({0} dessert qaşığı),
						'other' => q({0} dessert qaşığı),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessert qaşığı),
						'one' => q({0} dessert qaşığı),
						'other' => q({0} dessert qaşığı),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(İmp. dessert qaşığı),
						'one' => q({0} İmp. dessert qaşığı),
						'other' => q({0} İmp. dessert qaşığı),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(İmp. dessert qaşığı),
						'one' => q({0} İmp. dessert qaşığı),
						'other' => q({0} İmp. dessert qaşığı),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(maye unsiyası),
						'one' => q({0} maye unsiyası),
						'other' => q({0} maye unsiyası),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(maye unsiyası),
						'one' => q({0} maye unsiyası),
						'other' => q({0} maye unsiyası),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(İmp. maye unsiyası),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(İmp. maye unsiyası),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(qallon),
						'one' => q({0} qallon),
						'other' => q({0} qallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(qallon),
						'one' => q({0} qallon),
						'other' => q({0} qallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(İmp. qallon),
						'one' => q({0} imp. qallon),
						'other' => q({0} imp. qallon),
						'per' => q({0}/imp. qallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(İmp. qallon),
						'one' => q({0} imp. qallon),
						'other' => q({0} imp. qallon),
						'per' => q({0}/imp. qallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitr),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitr),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitr),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitr),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litr),
						'other' => q({0} litr),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litr),
						'other' => q({0} litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(meqalitr),
						'one' => q({0} meqalitr),
						'other' => q({0} meqalitr),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(meqalitr),
						'one' => q({0} meqalitr),
						'other' => q({0} meqalitr),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
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
					'volume-quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(İmp. kvarta),
						'one' => q({0} İmp. kvarta),
						'other' => q({0} İmp. kvarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(İmp. kvarta),
						'one' => q({0} İmp. kvarta),
						'other' => q({0} İmp. kvarta),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(xörək qaşığı),
						'one' => q({0} xörək qaşığı),
						'other' => q({0} xörək qaşığı),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(xörək qaşığı),
						'one' => q({0} xörək qaşığı),
						'other' => q({0} xörək qaşığı),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(çay qaşığı),
						'one' => q({0} çay qaşığı),
						'other' => q({0} çay qaşığı),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(çay qaşığı),
						'one' => q({0} çay qaşığı),
						'other' => q({0} çay qaşığı),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}dəq),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}dəq),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metr²),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metr²),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil²),
						'one' => q({0} mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil²),
						'one' => q({0} mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
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
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0} hs/mln),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0} hs/mln),
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
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} mil/imq),
						'other' => q({0} mil/imq),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} mil/imq),
						'other' => q({0} mil/imq),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msan),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msan),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(dəq),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(dəq),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(san),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(san),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hft),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hft),
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
					'energy-kilowatt-hour' => {
						'name' => q(kVt/saat),
						'one' => q({0} kVt/saat),
						'other' => q({0} kVt/saat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kVt/saat),
						'one' => q({0} kVt/saat),
						'other' => q({0} kVt/saat),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kVts/100km),
						'other' => q({0} kVts/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kVts/100km),
						'other' => q({0} kVts/100km),
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
					'graphics-dot' => {
						'name' => q(nöqtə),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(nöqtə),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(p/sm),
						'one' => q({0} p/sm),
						'other' => q({0} p/sm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(p/sm),
						'one' => q({0} p/sm),
						'other' => q({0} p/sm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(p/i),
						'one' => q({0} p/i),
						'other' => q({0} p/i),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(p/i),
						'one' => q({0} p/i),
						'other' => q({0} p/i),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(R⊕),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} far),
						'other' => q({0} far),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} far),
						'other' => q({0} far),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ii),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ii),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ps),
						'one' => q({0} ps),
						'other' => q({0} ps),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ps),
						'one' => q({0} ps),
						'other' => q({0} ps),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
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
					'mass-carat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
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
					'mass-solar-mass' => {
						'name' => q(M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stoun),
						'one' => q({0} stoun),
						'other' => q({0} stoun),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stoun),
						'one' => q({0} stoun),
						'other' => q({0} stoun),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GVt),
						'one' => q({0} GVt),
						'other' => q({0} GVt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GVt),
						'one' => q({0} GVt),
						'other' => q({0} GVt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ag),
						'one' => q({0} ag),
						'other' => q({0} ag),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ag),
						'one' => q({0} ag),
						'other' => q({0} ag),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kVt),
						'one' => q({0} kVt),
						'other' => q({0} kVt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kVt),
						'one' => q({0} kVt),
						'other' => q({0} kVt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MVt),
						'one' => q({0} MVt),
						'other' => q({0} MVt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MVt),
						'one' => q({0} MVt),
						'other' => q({0} MVt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mVt),
						'one' => q({0} mVt),
						'other' => q({0} mVt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mVt),
						'one' => q({0} mVt),
						'other' => q({0} mVt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Vt),
						'one' => q({0} Vt),
						'other' => q({0} Vt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Vt),
						'one' => q({0} Vt),
						'other' => q({0} Vt),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
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
					'speed-meter-per-second' => {
						'name' => q(m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ak-ft),
						'one' => q({0} ak-ft),
						'other' => q({0} ak-ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ak-ft),
						'one' => q({0} ak-ft),
						'other' => q({0} ak-ft),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil³),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mfincan),
						'one' => q({0} mf),
						'other' => q({0} mf),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mfincan),
						'one' => q({0} mf),
						'other' => q({0} mf),
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
						'name' => q(dsp),
						'one' => q({0} dsp),
						'other' => q({0} dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0} dsp),
						'other' => q({0} dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dc),
						'one' => q({0} dc),
						'other' => q({0} dc),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dc),
						'one' => q({0} dc),
						'other' => q({0} dc),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0} imp.qal),
						'other' => q({0} imp.qal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0} imp.qal),
						'other' => q({0} imp.qal),
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
					'volume-pint-metric' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(istiqamət),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(istiqamət),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(ki{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(ti{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(ti{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ei{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ei{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yi{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(s{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(s{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(k {0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(k {0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kq{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kq{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(K {0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(K {0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g qüvvəsi),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g qüvvəsi),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metr/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metr/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(dəqiqə),
						'one' => q({0}dəq),
						'other' => q({0}dəq),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(dəqiqə),
						'one' => q({0}dəq),
						'other' => q({0}dəq),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(saniyə),
						'one' => q({0}san),
						'other' => q({0}san),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(saniyə),
						'one' => q({0}san),
						'other' => q({0}san),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(dərəcə),
						'one' => q({0} dər),
						'other' => q({0} dər),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(dərəcə),
						'one' => q({0} dər),
						'other' => q({0} dər),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(döv),
						'one' => q({0} döv),
						'other' => q({0} döv),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(döv),
						'one' => q({0} döv),
						'other' => q({0} döv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akr),
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akr),
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dönüm),
						'one' => q({0} dönüm),
						'other' => q({0} dönüm),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dönüm),
						'one' => q({0} dönüm),
						'other' => q({0} dönüm),
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
					'area-square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kv ft),
						'other' => q({0} kv ft),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kv ft),
						'other' => q({0} kv ft),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kv km),
						'other' => q({0} kv km),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kv km),
						'other' => q({0} kv km),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kv m),
						'other' => q({0} kv m),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kv m),
						'other' => q({0} kv m),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kv mil),
						'other' => q({0} kv mil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kv mil),
						'other' => q({0} kv mil),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} element),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} element),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/litr),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/litr),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(faiz),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(faiz),
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
					'concentr-permillion' => {
						'name' => q(hissəcik/milyon),
						'one' => q({0} hs/mln),
						'other' => q({0} hs/mln),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(hissəcik/milyon),
						'one' => q({0} hs/mln),
						'other' => q({0} hs/mln),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permiriada),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permiriada),
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
						'name' => q(mil/qal),
						'one' => q({0} mil/qal),
						'other' => q({0} mil/qal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/qal),
						'one' => q({0} mil/qal),
						'other' => q({0} mil/qal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/imp. qal),
						'one' => q({0} m/q imp),
						'other' => q({0} m/q imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. qal),
						'one' => q({0} m/q imp),
						'other' => q({0} m/q imp),
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
					'digital-petabyte' => {
						'name' => q(PBayt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBayt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(əsr),
						'one' => q({0} əsr),
						'other' => q({0} əsr),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(əsr),
						'one' => q({0} əsr),
						'other' => q({0} əsr),
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
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saat),
						'one' => q({0} saat),
						'other' => q({0} saat),
						'per' => q({0}/saat),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saat),
						'one' => q({0} saat),
						'other' => q({0} saat),
						'per' => q({0}/saat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsan),
						'one' => q({0} μsan),
						'other' => q({0} μsan),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsan),
						'one' => q({0} μsan),
						'other' => q({0} μsan),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisaniyə),
						'one' => q({0} msan),
						'other' => q({0} msan),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisaniyə),
						'one' => q({0} msan),
						'other' => q({0} msan),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(dəqiqə),
						'one' => q({0} dəq),
						'other' => q({0} dəq),
						'per' => q({0}/dəq),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(dəqiqə),
						'one' => q({0} dəq),
						'other' => q({0} dəq),
						'per' => q({0}/dəq),
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
						'name' => q(nsan),
						'one' => q({0} nsan),
						'other' => q({0} nsan),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nsan),
						'one' => q({0} nsan),
						'other' => q({0} nsan),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(rüb),
						'one' => q({0} r),
						'other' => q({0} r),
						'per' => q({0}/r),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(rüb),
						'one' => q({0} r),
						'other' => q({0} r),
						'per' => q({0}/r),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(saniyə),
						'one' => q({0} san),
						'other' => q({0} san),
						'per' => q({0}/san),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(saniyə),
						'one' => q({0} san),
						'other' => q({0} san),
						'per' => q({0}/san),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(həftə),
						'one' => q({0} hft),
						'other' => q({0} hft),
						'per' => q({0}/hft),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(həftə),
						'one' => q({0} hft),
						'other' => q({0} hft),
						'per' => q({0}/hft),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(il),
						'one' => q({0} il),
						'other' => q({0} il),
						'per' => q({0}/il),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(il),
						'one' => q({0} il),
						'other' => q({0} il),
						'per' => q({0}/il),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(om),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(om),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTV),
						'one' => q({0} Btv),
						'other' => q({0} Btv),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTV),
						'one' => q({0} Btv),
						'other' => q({0} Btv),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
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
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(coul),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(coul),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kc),
						'one' => q({0} kc),
						'other' => q({0} kc),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kc),
						'one' => q({0} kc),
						'other' => q({0} kc),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ABŞ tv),
						'one' => q({0} ABŞ tv),
						'other' => q({0} ABŞ tv),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ABŞ tv),
						'one' => q({0} ABŞ tv),
						'other' => q({0} ABŞ tv),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kVtst/100km),
						'one' => q({0} kWh/100km),
						'other' => q({0} kVtst/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kVtst/100km),
						'one' => q({0} kWh/100km),
						'other' => q({0} kVtst/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(nyuton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(nyuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(güc funtu),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(güc funtu),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(nöqtələr),
						'one' => q({0} nöqtə),
						'other' => q({0} nöqtə),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(nöqtələr),
						'one' => q({0} nöqtə),
						'other' => q({0} nöqtə),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nöq / sm),
						'one' => q({0} nöq/sm),
						'other' => q({0} nöq/sm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nöq / sm),
						'one' => q({0} nöq/sm),
						'other' => q({0} nöq/sm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nöq/düym),
						'one' => q({0} nöq/düym),
						'other' => q({0} nöq/düym),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nöq/düym),
						'one' => q({0} nöq/düym),
						'other' => q({0} nöq/düym),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(meqapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(meqapiksel),
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
						'name' => q(av),
						'one' => q({0} av),
						'other' => q({0} av),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(av),
						'one' => q({0} av),
						'other' => q({0} av),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(yer radiusu),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(yer radiusu),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fut),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fut),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(farlonq),
						'one' => q({0} farlonq),
						'other' => q({0} farlonq),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(farlonq),
						'one' => q({0} farlonq),
						'other' => q({0} farlonq),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(düym),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(düym),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometr),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometr),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(işıq ili),
						'one' => q({0} ii),
						'other' => q({0} ii),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(işıq ili),
						'one' => q({0} ii),
						'other' => q({0} ii),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metr),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metr),
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
					'length-millimeter' => {
						'name' => q(millimetr),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetr),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometr),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometr),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(xal),
						'one' => q({0} xal),
						'other' => q({0} xal),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(xal),
						'one' => q({0} xal),
						'other' => q({0} xal),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(günəş radiusu),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(günəş radiusu),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kd),
						'one' => q({0} kd),
						'other' => q({0} kd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kd),
						'one' => q({0} kd),
						'other' => q({0} kd),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(gün işığı),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(gün işığı),
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
						'name' => q(yer kütləsi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(yer kütləsi),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(qranul),
						'one' => q({0} qranul),
						'other' => q({0} qranul),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(qranul),
						'one' => q({0} qranul),
						'other' => q({0} qranul),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(qram),
						'one' => q({0} q),
						'other' => q({0} q),
						'per' => q({0}/q),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(qram),
						'one' => q({0} q),
						'other' => q({0} q),
						'per' => q({0}/q),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kiloqram),
						'one' => q({0} kq),
						'other' => q({0} kq),
						'per' => q({0}/kq),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kiloqram),
						'one' => q({0} kq),
						'other' => q({0} kq),
						'per' => q({0}/kq),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μq),
						'one' => q({0} μq),
						'other' => q({0} μq),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μq),
						'one' => q({0} μq),
						'other' => q({0} μq),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mq),
						'one' => q({0} mq),
						'other' => q({0} mq),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mq),
						'one' => q({0} mq),
						'other' => q({0} mq),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unsiya),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unsiya),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(funt),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(funt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(günəş kütləsi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(günəş kütləsi),
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
					'power-horsepower' => {
						'name' => q(at gücü),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(at gücü),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilovatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilovatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vatt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vatt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(civə düymü),
						'one' => q({0} civə düymü),
						'other' => q({0} civə düymü),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(civə düymü),
						'one' => q({0} civə düymü),
						'other' => q({0} civə düymü),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Bofor),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bofor),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometr/saat),
						'one' => q({0} km/saat),
						'other' => q({0} km/saat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometr/saat),
						'one' => q({0} km/saat),
						'other' => q({0} km/saat),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metr/saniyə),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metr/saniyə),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/saat),
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/saat),
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(dərəcə Selsi),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(dərəcə Selsi),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(dərəcə Farengeyt),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(dərəcə Farengeyt),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(buşel),
						'one' => q({0} buşel),
						'other' => q({0} buşel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(buşel),
						'one' => q({0} buşel),
						'other' => q({0} buşel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} mil³),
						'other' => q({0} mil³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} mil³),
						'other' => q({0} mil³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(des.qaş.),
						'one' => q({0} des.qaş.),
						'other' => q({0} des.qaş.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(des.qaş.),
						'one' => q({0} des.qaş.),
						'other' => q({0} des.qaş.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(des.qaş. İmp.),
						'one' => q({0} des.qaş. İmp),
						'other' => q({0} des.qaş. İmp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(des.qaş. İmp.),
						'one' => q({0} des.qaş. İmp),
						'other' => q({0} des.qaş. İmp.),
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
					'volume-drop' => {
						'name' => q(damcı),
						'one' => q({0} damcı),
						'other' => q({0} damcı),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(damcı),
						'one' => q({0} damcı),
						'other' => q({0} damcı),
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
						'name' => q(İmp. fl oz),
						'one' => q({0} fl oz İmp.),
						'other' => q({0} fl oz İmp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(İmp. fl oz),
						'one' => q({0} fl oz İmp.),
						'other' => q({0} fl oz İmp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(qal),
						'one' => q({0} qal),
						'other' => q({0} qal),
						'per' => q({0}/qal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(qal),
						'one' => q({0} qal),
						'other' => q({0} qal),
						'per' => q({0}/qal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(İmp. qal),
						'one' => q({0} imp. qal),
						'other' => q({0} imp. qal),
						'per' => q({0}/imp. qal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(İmp. qal),
						'one' => q({0} imp. qal),
						'other' => q({0} imp. qal),
						'per' => q({0}/imp. qal),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litr),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litr),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(çimdik),
						'one' => q({0} çimdik),
						'other' => q({0} çimdik),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(çimdik),
						'one' => q({0} çimdik),
						'other' => q({0} çimdik),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kvarta İmp.),
						'one' => q({0} kvarta İmp.),
						'other' => q({0} kvarta İmp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kvarta İmp.),
						'one' => q({0} kvarta İmp.),
						'other' => q({0} kvarta İmp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(xrqş),
						'one' => q({0} xrqş),
						'other' => q({0} xrqş),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(xrqş),
						'one' => q({0} xrqş),
						'other' => q({0} xrqş),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(çyqş),
						'one' => q({0} çyqş),
						'other' => q({0} çyqş),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(çyqş),
						'one' => q({0} çyqş),
						'other' => q({0} çyqş),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hə|h)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yox|y|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} və {1}),
				2 => q({0} və {1}),
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
					'one' => '0 min',
					'other' => '0 min',
				},
				'10000' => {
					'one' => '00 min',
					'other' => '00 min',
				},
				'100000' => {
					'one' => '000 min',
					'other' => '000 min',
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
					'one' => '0 milyard',
					'other' => '0 milyard',
				},
				'10000000000' => {
					'one' => '00 milyard',
					'other' => '00 milyard',
				},
				'100000000000' => {
					'one' => '000 milyard',
					'other' => '000 milyard',
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
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mlrd',
					'other' => '0 mlrd',
				},
				'10000000000' => {
					'one' => '00 mlrd',
					'other' => '00 mlrd',
				},
				'100000000000' => {
					'one' => '000 mlrd',
					'other' => '000 mlrd',
				},
				'1000000000000' => {
					'one' => '0 trln',
					'other' => '0 trln',
				},
				'10000000000000' => {
					'one' => '00 trln',
					'other' => '00 trln',
				},
				'100000000000000' => {
					'one' => '000 trln',
					'other' => '000 trln',
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
				'currency' => q(Andora Pesetası),
				'one' => q(Andora pesetası),
				'other' => q(Andora pesetası),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Birləşmiş Ərəb Əmirlikləri Dirhəmi),
				'one' => q(BƏƏ dirhəmi),
				'other' => q(BƏƏ dirhəmi),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Əfqanıstan Əfqanisi \(1927–2002\)),
				'one' => q(Əfqanıstan əfqanisi \(1927–2002\)),
				'other' => q(Əfqanıstan əfqanisi \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Əfqanıstan Əfqanisi),
				'one' => q(Əfqanıstan əfqanisi),
				'other' => q(Əfqanıstan əfqanisi),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albaniya Leki \(1946–1965\)),
				'one' => q(Albaniya leki \(1946–1965\)),
				'other' => q(Albaniya leki \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albaniya Leki),
				'one' => q(Albaniya leki),
				'other' => q(Albaniya leki),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Ermənistan Dramı),
				'one' => q(Ermənistan dramı),
				'other' => q(Ermənistan dramı),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Niderland Antilyası Gilderi),
				'one' => q(Niderland Antilyası gilderi),
				'other' => q(Niderland Antilya gilderi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Anqola Kvanzası),
				'one' => q(Anqola kvanzası),
				'other' => q(Anqola kvanzası),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Anqola Kvanzasi \(1977–1990\)),
				'one' => q(Anqola kvanzasi \(1977–1990\)),
				'other' => q(Anqola kvanzasi \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Anqola Yeni Kvanzası \(1990–2000\)),
				'one' => q(Anqola yeni kvanzası \(1990–2000\)),
				'other' => q(Anqola yeni kvanzası \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Anqola Kvanzası \(1995–1999\)),
				'one' => q(Anqola kvanzası \(1995–1999\)),
				'other' => q(Anqola kvanzası \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentina avstralı),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentina pesosu \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentina Pesosu),
				'one' => q(Argentina pesosu),
				'other' => q(Argentina pesosu),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Avstriya Şillinqi),
				'one' => q(Avstriya şillinqi),
				'other' => q(Avstriya şillinqi),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Avstraliya Dolları),
				'one' => q(Avstraliya dolları),
				'other' => q(Avstraliya dolları),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba Florini),
				'one' => q(Aruba florini),
				'other' => q(Aruba florini),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azərbaycan Manatı \(1993–2006\)),
				'one' => q(Azərbaycan manatı \(1993–2006\)),
				'other' => q(Azərbaycan manatı \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => '₼',
			display_name => {
				'currency' => q(Azərbaycan Manatı),
				'one' => q(Azərbaycan manatı),
				'other' => q(Azərbaycan manatı),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosniya-Herseqovina Dinarı),
				'one' => q(Bosniya-Herseqovina dinarı),
				'other' => q(Bosniya-Herseqovina dinarı),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosniya-Herseqovina Markası),
				'one' => q(Bosniya-Herseqovina markası),
				'other' => q(Bosniya-Herseqovina markası),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados Dolları),
				'one' => q(Barbados dolları),
				'other' => q(Barbados dolları),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Banqladeş Takası),
				'one' => q(Banqladeş takası),
				'other' => q(Banqladeş takası),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belçika Frankı \(deyşirik\)),
				'one' => q(Belçika frankı \(deyşirik\)),
				'other' => q(Belçika frankı \(deyşirik\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belçika Frankı),
				'one' => q(Belçika frankı),
				'other' => q(Belçika frankı),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belçika Frankı \(finans\)),
				'one' => q(Belçika frankı \(finans\)),
				'other' => q(Belçika frankı \(finans\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bolqarıstan Levası),
				'one' => q(Bolqarıstan levası),
				'other' => q(Bolqarıstan levası),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bolqarıstan Levi),
				'one' => q(Bolqarıstan levi),
				'other' => q(Bolqarıstan levi),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bəhreyn Dinarı),
				'one' => q(Bəhreyn dinarı),
				'other' => q(Bəhreyn dinarı),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi Frankı),
				'one' => q(Burundi frankı),
				'other' => q(Burundi frankı),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda Dolları),
				'one' => q(Bermuda dolları),
				'other' => q(Bermuda dolları),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Bruney Dolları),
				'one' => q(Bruney dolları),
				'other' => q(Bruney dolları),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviya Bolivianosu),
				'one' => q(Boliviya bolivianosu),
				'other' => q(Boliviya bolivianosu),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Boliviya pesosu),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Boliviya mvdolı),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Braziliya kruzeyro novası),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Braziliya kruzadosu),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Braziliya kruzeyrosu \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Braziliya Realı),
				'one' => q(Braziliya realı),
				'other' => q(Braziliya realı),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Braziliya kruzado novası),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Braziliya kruzeyrosu),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Baham Dolları),
				'one' => q(Baham dolları),
				'other' => q(Baham dolları),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butan Nqultrumu),
				'one' => q(Butan nqultrumu),
				'other' => q(Butan nqultrumu),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmis Kyatı),
				'one' => q(Burmis kyatı),
				'other' => q(Burmis kyatı),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botsvana Pulası),
				'one' => q(Botsvana pulası),
				'other' => q(Botsvana pulası),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Belarus Yeni Rublu \(1994–1999\)),
				'one' => q(Belarus yeni rublu \(1994–1999\)),
				'other' => q(Belarus yeni rublu \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Belarus Rublu),
				'one' => q(Belarus rublu),
				'other' => q(Belarus rublu),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarus Rublu \(2000–2016\)),
				'one' => q(Belarus rublu \(2000–2016\)),
				'other' => q(Belarus rublu \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Beliz Dolları),
				'one' => q(Beliz dolları),
				'other' => q(Beliz dolları),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada Dolları),
				'one' => q(Kanada dolları),
				'other' => q(Kanada dolları),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Konqo Frankı),
				'one' => q(Konqo frankı),
				'other' => q(Konqo frankı),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR Avro),
				'one' => q(WIR avro),
				'other' => q(WIR avro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(İsveçrə Frankı),
				'one' => q(İsveçrə frankı),
				'other' => q(İsveçrə frankı),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR Frankası),
				'one' => q(WIR frankası),
				'other' => q(WIR frankası),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Çili Pesosu),
				'one' => q(Çili pesosu),
				'other' => q(Çili pesosu),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Çin Yuanı \(ofşor\)),
				'one' => q(Çin yuanı \(ofşor\)),
				'other' => q(Çin yuanı \(ofşor\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Çin Yuanı),
				'one' => q(Çin yuanı),
				'other' => q(Çin yuanı),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbiya Pesosu),
				'one' => q(Kolombiya pesosu),
				'other' => q(Kolombiya pesosu),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kosta Rika Kolonu),
				'one' => q(Kosta Rika kolonu),
				'other' => q(Kosta Rika kolonu),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbiya Dinarı \(2002–2006\)),
				'one' => q(Serbiya dinarı \(2002–2006\)),
				'other' => q(Serbiya dinarı \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Çexoslavakiya Korunası),
				'one' => q(Çexoslavakiya korunası),
				'other' => q(Çexoslavakiya korunası),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kuba Çevrilən Pesosu),
				'one' => q(Kuba çevrilən pesosu),
				'other' => q(Kuba çevrilən pesosu),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kuba Pesosu),
				'one' => q(Kuba pesosu),
				'other' => q(Kuba pesosu),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kape Verde Eskudosu),
				'one' => q(Kape Verde eskudosu),
				'other' => q(Kape Verde eskudosu),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kipr Paundu),
				'one' => q(Kipr paundu),
				'other' => q(Kipr paundu),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Çexiya Korunası),
				'one' => q(Çexiya korunası),
				'other' => q(Çexiya korunası),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Şərq Almaniya Ostmarkı),
				'one' => q(Şərq Almaniya ostmarkı),
				'other' => q(Şərq Almaniya ostmarkı),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Alman Markası),
				'one' => q(Alman markası),
				'other' => q(Alman markası),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Cibuti Frankı),
				'one' => q(Cibuti frankı),
				'other' => q(Cibuti frankı),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danimarka Kronu),
				'one' => q(Danimarka kronu),
				'other' => q(Danimarka kronu),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominika Pesosu),
				'one' => q(Dominika pesosu),
				'other' => q(Dominika pesosu),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Əlcəzair Dinarı),
				'one' => q(Əlcəzair dinarı),
				'other' => q(Əlcəzair dinarı),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ekvador Sukresi),
				'one' => q(Ekvador sukresi),
				'other' => q(Ekvador sukresi),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estoniya Krunu),
				'one' => q(Estoniya krunu),
				'other' => q(Estoniya krunu),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Misir Funtu),
				'one' => q(Misir funtu),
				'other' => q(Misir funtu),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreya Nakfası),
				'one' => q(Eritreya nakfası),
				'other' => q(Eritreya nakfası),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(İspan Pesetası \(A account\)),
				'one' => q(İspan pesetası \(A account\)),
				'other' => q(İspan pesetası \(A account\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(İspan Pesetası \(dəyşirik\)),
				'one' => q(İspan pesetası \(dəyşirik\)),
				'other' => q(İspan pesetası \(dəyşirik\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(İspan Pesetası),
				'one' => q(İspan pesetası),
				'other' => q(İspan pesetası),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Efiopiya Bırrı),
				'one' => q(Efiopiya bırrı),
				'other' => q(Efiopiya bırrı),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Avro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Fin Markası),
				'one' => q(Fin markası),
				'other' => q(Fin markası),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fici Dolları),
				'one' => q(Fici dolları),
				'other' => q(Fici dolları),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Folklend Adaları Funtu),
				'one' => q(Folklend Adaları funtu),
				'other' => q(Folklend Adaları funtu),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Fransız Markası),
				'one' => q(Fransız markası),
				'other' => q(Fransız markası),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britaniya Funtu),
				'one' => q(Britaniya funtu),
				'other' => q(Britaniya funtu),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Gürcüstan Kupon Lariti),
				'one' => q(Gürcüstan kupon lariti),
				'other' => q(Gürcüstan kupon lariti),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Gürcüstan Larisi),
				'one' => q(Gürcüstan larisi),
				'other' => q(Gürcüstan larisi),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Qana Sedisi \(1979–2007\)),
				'one' => q(Qana sedisi \(1979–2007\)),
				'other' => q(Qana sedisi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Qana Sedisi),
				'one' => q(Qana sedisi),
				'other' => q(Qana sedisi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Cəbəli-Tariq Funtu),
				'one' => q(Cəbəli-Tariq funtu),
				'other' => q(Cəbəli-Tariq funtu),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Qambiya Dalasisi),
				'one' => q(Qambiya dalasisi),
				'other' => q(Qambiya dalasisi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Qvineya Frankı),
				'one' => q(Qvineya frankı),
				'other' => q(Qvineya frankı),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Qvineya Sulisi),
				'one' => q(Qvineya sulisi),
				'other' => q(Qvineya sulisi),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekvatoriya Gvineya Ekvele Quneanası),
				'one' => q(Ekvatoriya Gvineya ekvele quneanası),
				'other' => q(Ekvatoriya Gvineya ekvele quneanası),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Yunan Draçması),
				'one' => q(Yunan draxması),
				'other' => q(Yunan draxması),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Qvatemala Küetzalı),
				'one' => q(Qvatemala küetzalı),
				'other' => q(Qvatemala küetzalı),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugal Qvineya Eskudosu),
				'one' => q(Portugal Qvineya eskudosu),
				'other' => q(Portugal Qvineya eskudosu),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Qvineya-Bisau Pesosu),
				'one' => q(Qvineya-Bisau pesosu),
				'other' => q(Qvineya-Bisau pesosu),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Qayana Dolları),
				'one' => q(Qayana dolları),
				'other' => q(Qayana dolları),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Honq Konq Dolları),
				'one' => q(Honq Konq dolları),
				'other' => q(Honq Konq dolları),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduras Lempirası),
				'one' => q(Honduras lempirası),
				'other' => q(Honduras lempirası),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Xorvatiya Dinarı),
				'one' => q(Xorvatiya dinarı),
				'other' => q(Xorvatiya dinarı),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Xorvatiya Kunası),
				'one' => q(Xorvatiya kunası),
				'other' => q(Xorvatiya kunası),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haiti Qourdu),
				'one' => q(Haiti qourdu),
				'other' => q(Haiti qourdu),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Macarıstan Forinti),
				'one' => q(Macarıstan forinti),
				'other' => q(Macarıstan forinti),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(İndoneziya Rupisi),
				'one' => q(İndoneziya rupisi),
				'other' => q(İndoneziya rupisi),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(İrlandiya Paundu),
				'one' => q(İrlandiya paundu),
				'other' => q(İrlandiya paundu),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(İzrail Paundu),
				'one' => q(İzrail paundu),
				'other' => q(İzrail paundu),
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
				'currency' => q(İsrail Yeni Şekeli),
				'one' => q(İsrail yeni şekeli),
				'other' => q(İsrail yeni şekeli),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Hindistan Rupisi),
				'one' => q(Hindistan rupisi),
				'other' => q(Hindistan rupisi),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(İraq Dinarı),
				'one' => q(İraq dinarı),
				'other' => q(İraq dinarı),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(İran Rialı),
				'one' => q(İran rialı),
				'other' => q(İran rialı),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(İslandiya Kronu \(1918–1981\)),
				'one' => q(İslandiya kronu \(1918–1981\)),
				'other' => q(İslandiya kronu \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(İslandiya Kronu),
				'one' => q(İslandiya kronu),
				'other' => q(İslandiya kronu),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(İtaliya Lirası),
				'one' => q(İtaliya lirası),
				'other' => q(İtaliya lirası),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Yamayka Dolları),
				'one' => q(Yamayka dolları),
				'other' => q(Yamayka dolları),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(İordaniya Dinarı),
				'one' => q(İordaniya dinarı),
				'other' => q(İordaniya dinarı),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yaponiya Yeni),
				'one' => q(Yaponiya yeni),
				'other' => q(Yaponiya yeni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniya Şillinqi),
				'one' => q(Keniya şillinqi),
				'other' => q(Keniya şillinqi),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Qırğızıstan Somu),
				'one' => q(Qırğızıstan somu),
				'other' => q(Qırğızıstan somu),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kamboca Rieli),
				'one' => q(Kamboca rieli),
				'other' => q(Kamboca rieli),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komor Frankı),
				'one' => q(Komor frankı),
				'other' => q(Komor frankı),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Şimali Koreya Vonu),
				'one' => q(Şimali Koreya vonu),
				'other' => q(Şimali Koreya vonu),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Cənubi Koreya Vonu),
				'one' => q(Cənubi Koreya vonu),
				'other' => q(Cənubi Koreya vonu),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Küveyt Dinarı),
				'one' => q(Küveyt dinarı),
				'other' => q(Küveyt dinarı),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kayman Adaları Dolları),
				'one' => q(Kayman Adaları dolları),
				'other' => q(Kayman Adaları dolları),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Qazaxıstan Tengesi),
				'one' => q(Qazaxıstan tengesi),
				'other' => q(Qazaxıstan tengesi),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laos Kipi),
				'one' => q(Laos kipi),
				'other' => q(Laos kipi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Livan Funtu),
				'one' => q(Livan funtu),
				'other' => q(Livan funtu),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Şri Lanka Rupisi),
				'one' => q(Şri Lanka rupisi),
				'other' => q(Şri Lanka rupisi),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiya Dolları),
				'one' => q(Liberiya dolları),
				'other' => q(Liberiya dolları),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto Lotisi),
				'one' => q(Lesoto lotisi),
				'other' => q(Lesoto lotisi),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litva Liti),
				'one' => q(Litva liti),
				'other' => q(Litva liti),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litva Talonası),
				'one' => q(Litva talonası),
				'other' => q(Litva talonası),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luksemburq Frankası \(dəyişik\)),
				'one' => q(Luksemburq dəyişik frankası),
				'other' => q(Luksemburq dəyişik frankası),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luksemburq Frankası),
				'one' => q(Luksemburq frankası),
				'other' => q(Luksemburq frankası),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luksemburq Frankası \(finans\)),
				'one' => q(Luksemburq finans frankası),
				'other' => q(Luksemburq finans frankası),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Latviya Latı),
				'one' => q(Latviya latı),
				'other' => q(Latviya latı),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latviya Rublu),
				'one' => q(Latviya rublu),
				'other' => q(Latviya rublu),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Liviya Dinarı),
				'one' => q(Liviya dinarı),
				'other' => q(Liviya dinarı),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Mərakeş Dirhəmi),
				'one' => q(Mərakeş dirhəmi),
				'other' => q(Mərakeş dirhəmi),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Mərakeş Frankası),
				'one' => q(Mərakeş frankası),
				'other' => q(Mərakeş frankası),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldova Leyi),
				'one' => q(Moldova leyi),
				'other' => q(Moldova leyi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madaqaskar Ariarisi),
				'one' => q(Madaqaskar ariarisi),
				'other' => q(Madaqaskar ariarisi),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madaqaskar Frankası),
				'one' => q(Madaqaskar frankası),
				'other' => q(Madaqaskar frankası),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedoniya Dinarı),
				'one' => q(Makedoniya dinarı),
				'other' => q(Makedoniya dinarı),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Makedoniya Dinarı \(1992–1993\)),
				'one' => q(Makedoniya dinarı \(1992–1993\)),
				'other' => q(Makedoniya dinarı \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mali Frankı),
				'one' => q(Mali frankı),
				'other' => q(Mali frankı),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanma Kiyatı),
				'one' => q(Myanmar kiyatı),
				'other' => q(Myanmar kiyatı),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Monqoliya Tuqriki),
				'one' => q(Monqoliya tuqriki),
				'other' => q(Monqoliya tuqriki),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makao Patakası),
				'one' => q(Makao patakası),
				'other' => q(Makao patakası),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mavritaniya Ugiyası \(1973–2017\)),
				'one' => q(Mavritaniya ugiyası \(1973–2017\)),
				'other' => q(Mavritaniya ugiyası \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mavritaniya Ugiyası),
				'one' => q(Mavritaniya ugiyası),
				'other' => q(Mavritaniya ugiyası),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltiz Paundu),
				'one' => q(Maltiz paundu),
				'other' => q(Maltiz paundu),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mavriki Rupisi),
				'one' => q(Mavriki rupisi),
				'other' => q(Mavriki rupisi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldiv Rufiyası),
				'one' => q(Maldiv rufiyası),
				'other' => q(Maldiv rufiyası),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malavi Kvaçası),
				'one' => q(Malavi kvaçası),
				'other' => q(Malavi kvaçası),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksika Pesosu),
				'one' => q(Meksika pesosu),
				'other' => q(Meksika pesosu),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Meksika gümüş pesosu),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malayziya Ringiti),
				'one' => q(Malayziya ringiti),
				'other' => q(Malayziya ringiti),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambik Eskudosu),
				'one' => q(Mozambik eskudosu),
				'other' => q(Mozambik eskudosu),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambik Metikalı \(1980–2006\)),
				'one' => q(Mozambik metikalı \(1980–2006\)),
				'other' => q(Mozambik metikalı \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambik Metikalı),
				'one' => q(Mozambik metikalı),
				'other' => q(Mozambik metikalı),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibiya Dolları),
				'one' => q(Namibiya dolları),
				'other' => q(Namibiya dolları),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriya Nairası),
				'one' => q(Nigeriya nairası),
				'other' => q(Nigeriya nairası),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nikaraqua kordobu),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaraqua Kordobası),
				'one' => q(Nikaraqua kordobası),
				'other' => q(Nikaraqua kordobası),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollandiya Gilderi),
				'one' => q(Hollandiya gilderi),
				'other' => q(Hollandiya gilderi),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norveç Kronu),
				'one' => q(Norveç kronu),
				'other' => q(Norveç kronu),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepal Rupisi),
				'one' => q(Nepal rupisi),
				'other' => q(Nepal rupisi),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Yeni Zelandiya Dolları),
				'one' => q(Yeni Zelandiya dolları),
				'other' => q(Yeni Zelandiya dolları),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Oman Rialı),
				'one' => q(Oman rialı),
				'other' => q(Oman rialı),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama Balboası),
				'one' => q(Panama balboası),
				'other' => q(Panama balboası),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peru Inti),
				'one' => q(Peru inti),
				'other' => q(Peru inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru Solu),
				'one' => q(Peru solu),
				'other' => q(Peru solu),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peru Solu \(1863–1965\)),
				'one' => q(Peru solu \(1863–1965\)),
				'other' => q(Peru solu \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua Yeni Qvineya Kinası),
				'one' => q(Papua Yeni Qvineya kinası),
				'other' => q(Papua Yeni Qvineya kinası),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippin Pesosu),
				'one' => q(Filippin pesosu),
				'other' => q(Filippin pesosu),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistan Rupisi),
				'one' => q(Pakistan rupisi),
				'other' => q(Pakistan rupisi),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polşa Zlotısı),
				'one' => q(Polşa zlotısı),
				'other' => q(Polşa zlotısı),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polşa Zlotısı \(1950–1995\)),
				'one' => q(Polşa zlotısı \(1950–1995\)),
				'other' => q(Polşa zlotısı \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portuqal Eskudosu),
				'one' => q(Portuqal eskudosu),
				'other' => q(Portuqal eskudosu),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraqvay Quaranisi),
				'one' => q(Paraqvay quaranisi),
				'other' => q(Paraqvay quaranisi),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatar Rialı),
				'one' => q(Qatar rialı),
				'other' => q(Qatar rialı),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rodezian Dolları),
				'one' => q(Rodezian dolları),
				'other' => q(Rodezian dolları),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumıniya Leyi \(1952–2006\)),
				'one' => q(Rumıniya leyi \(1952–2006\)),
				'other' => q(Rumıniya leyi \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'ley',
			display_name => {
				'currency' => q(Rumıniya Leyi),
				'one' => q(Rumıniya leyi),
				'other' => q(Rumıniya leyi),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbiya Dinarı),
				'one' => q(Serbiya dinarı),
				'other' => q(Serbiya dinarı),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rusiya Rublu),
				'one' => q(Rusiya rublu),
				'other' => q(Rusiya rublu),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Rusiya Rublu \(1991–1998\)),
				'one' => q(Rusiya rublu \(1991–1998\)),
				'other' => q(Rusiya rublu \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda Frankı),
				'one' => q(Ruanda frankı),
				'other' => q(Ruanda frankı),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Səudiyyə Riyalı),
				'one' => q(Səudiyyə riyalı),
				'other' => q(Səudiyyə riyalı),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon Adaları Dolları),
				'one' => q(Solomon Adaları dolları),
				'other' => q(Solomon Adaları dolları),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seyşel Rupisi),
				'one' => q(Seyşel rupisi),
				'other' => q(Seyşel rupisi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan Funtu),
				'one' => q(Sudan funtu),
				'other' => q(Sudan funtu),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(İsveç Kronu),
				'one' => q(İsveç kronu),
				'other' => q(İsveç kronu),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Sinqapur Dolları),
				'one' => q(Sinqapur dolları),
				'other' => q(Sinqapur dolları),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Müqəddəs Yelena Funtu),
				'one' => q(Müqəddəs Yelena funtu),
				'other' => q(Müqəddəs Yelena funtu),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Sloveniya Toları),
				'one' => q(Sloveniya toları),
				'other' => q(Sloveniya toları),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovak Korunası),
				'one' => q(Slovak korunası),
				'other' => q(Slovak korunası),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leon Leonu),
				'one' => q(Sierra Leon leonu),
				'other' => q(Sierra Leon leonu),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leon Leonu \(1964—2022\)),
				'one' => q(Sierra Leon leonu \(1964—2022\)),
				'other' => q(Sierra Leon leonu \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Şillinqi),
				'one' => q(Somali şillinqi),
				'other' => q(Somali şillinqi),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam Dolları),
				'one' => q(Surinam dolları),
				'other' => q(Surinam dolları),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Cənubi Sudan Funtu),
				'one' => q(Cənubi Sudan funtu),
				'other' => q(Cənubi Sudan funtu),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(San Tom və Prinsip Dobrası \(1977–2017\)),
				'one' => q(San Tom və Prinsip dobrası \(1977–2017\)),
				'other' => q(San Tom və Prinsip dobrası \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(San Tom və Prinsip Dobrası),
				'one' => q(San Tom və Prinsip dobrası),
				'other' => q(San Tom və Prinsip dobrası),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovet Rublu),
				'one' => q(Sovet rublu),
				'other' => q(Sovet rublu),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El Salvador kolonu),
			},
		},
		'SYP' => {
			symbol => 'S£',
			display_name => {
				'currency' => q(Suriya Funtu),
				'one' => q(Suriya funtu),
				'other' => q(Suriya funtu),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Svazilend Lilangenini),
				'one' => q(Svazilend lilangenini),
				'other' => q(Svazilend emalangenini),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Tayland Batı),
				'one' => q(Tayland batı),
				'other' => q(Tayland batı),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tacikistan Rublu),
				'one' => q(Tacikistan rublu),
				'other' => q(Tacikistan rublu),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tacikistan Somonisi),
				'one' => q(Tacikistan somonisi),
				'other' => q(Tacikistan somonisi),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Türkmənistan Manatı \(1993–2009\)),
				'one' => q(Türkmənistan manatı \(1993–2009\)),
				'other' => q(Türkmənistan manatı \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Türkmənistan Manatı),
				'one' => q(Türkmənistan manatı),
				'other' => q(Türkmənistan manatı),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunis Dinarı),
				'one' => q(Tunis dinarı),
				'other' => q(Tunis dinarı),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonqa Panqası),
				'one' => q(Tonqa panqası),
				'other' => q(Tonqa panqası),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor Eskudu),
				'one' => q(Timor eskudu),
				'other' => q(Timor eskudu),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Türkiyə Lirəsi \(1922–2005\)),
				'one' => q(Türkiyə lirəsi \(1922–2005\)),
				'other' => q(Türkiyə lirəsi \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Türkiyə Lirəsi),
				'one' => q(Türkiyə lirəsi),
				'other' => q(Türkiyə lirəsi),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad və Tobaqo Dolları),
				'one' => q(Trinidad və Tobaqo dolları),
				'other' => q(Trinidad və Tobaqo dolları),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Tayvan Yeni Dolları),
				'one' => q(Tayvan yeni dolları),
				'other' => q(Tayvan yeni dolları),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniya Şillinqi),
				'one' => q(Tanzaniya şillinqi),
				'other' => q(Tanzaniya şillinqi),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrayna Qrivnası),
				'one' => q(Ukrayna qrivnası),
				'other' => q(Ukrayna qrivnası),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrayna Karbovenesası),
				'one' => q(Ukrayna karbovenesası),
				'other' => q(Ukrayna karbovenesası),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uqanda Şillinqi \(1966–1987\)),
				'one' => q(Uqanda şillinqi \(1966–1987\)),
				'other' => q(Uqanda şillinqi \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uqanda Şillinqi),
				'one' => q(Uqanda şillinqi),
				'other' => q(Uqanda şillinqi),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ABŞ Dolları),
				'one' => q(ABŞ dolları),
				'other' => q(ABŞ dolları),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(ABŞ dolları \(yeni gün\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(ABŞ dolları \(həmin gün\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruqvay pesosu Unidades Indexadas),
				'one' => q(Uruqvay pesosu unidades indexadas),
				'other' => q(Uruqvay pesosu unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruqvay Pesosu \(1975–1993\)),
				'one' => q(Uruqvay pesosu \(1975–1993\)),
				'other' => q(Uruqvay pesosu \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruqvay Pesosu),
				'one' => q(Uruqvay pesosu),
				'other' => q(Uruqvay pesosu),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Özbəkistan Somu),
				'one' => q(Özbəkistan somu),
				'other' => q(Özbəkistan somu),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venesuela Bolivarı \(1871–2008\)),
				'one' => q(Venesuela bolivarı \(1871–2008\)),
				'other' => q(Venesuela bolivarı \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venesuela Bolivarı \(2008–2018\)),
				'one' => q(Venesuela bolivarı \(2008–2018\)),
				'other' => q(Venesuela bolivarı \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venesuela Bolivarı),
				'one' => q(Venesuela bolivarı),
				'other' => q(Venesuela bolivarı),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vyetnam Donqu),
				'one' => q(Vyetnam donqu),
				'other' => q(Vyetnam donqu),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vyetnam Donqu \(1978–1985\)),
				'one' => q(Vyetnam donqu \(1978–1985\)),
				'other' => q(Vyetnam donqu \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu Vatusu),
				'one' => q(Vanuatu vatusu),
				'other' => q(Vanuatu vatusu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa Talası),
				'one' => q(Samoa talası),
				'other' => q(Samoa talası),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Kamerun Frankı),
				'one' => q(Kamerun frankı),
				'other' => q(Kamerun frankı),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(gümüş),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(qızıl),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Şərqi Karib Dolları),
				'one' => q(Şərqi Karib dolları),
				'other' => q(Şərqi Karib dolları),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Fransız Gızıl Frankı),
				'one' => q(Fransız gızıl frankı),
				'other' => q(Fransız gızıl frankı),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Fransız UİC Frankı),
				'one' => q(Fransız UİC frankı),
				'other' => q(Fransız UİC frankı),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Fil Dişi Sahili Frankı),
				'one' => q(Fil Dişi Sahili frankı),
				'other' => q(Fil Dişi Sahili frankı),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Fransız Polineziyası Frankı),
				'one' => q(Fransız Polineziyası frankı),
				'other' => q(Fransız Polineziyası frankı),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platinum),
				'one' => q(platinum),
				'other' => q(platinum),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Naməlum Valyuta),
				'one' => q(\(naməlum valyuta vahidi\)),
				'other' => q(\(naməlum valyuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Yəmən Dinarı),
				'one' => q(Yəmən dinarı),
				'other' => q(Yəmən dinarı),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yəmən Rialı),
				'one' => q(Yəmən rialı),
				'other' => q(Yəmən rialı),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Yuqoslaviya Dinarı \(1966–1990\)),
				'one' => q(Yuqoslaviya dinarı \(1966–1990\)),
				'other' => q(Yuqoslaviya dinarı \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Yuqoslaviya Yeni Dinarı \(1994–2002\)),
				'one' => q(Yuqoslaviya yeni dinarı \(1994–2002\)),
				'other' => q(Yuqoslaviya yeni dinarı \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Yuqoslaviya Dinarı \(1990–1992\)),
				'one' => q(Yuqoslaviya dinarı \(1990–1992\)),
				'other' => q(Yuqoslaviya dinarı \(1990–1992\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Cənubi Afrika Randı \(finans\)),
				'one' => q(Cənubi Afrika randı \(finans\)),
				'other' => q(Cənubi Afrika randı \(finans\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Cənubi Afrika Randı),
				'one' => q(Cənubi Afrika randı),
				'other' => q(Cənubi Afrika randı),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiya Kvaçası \(1968–2012\)),
				'one' => q(Zambiya kvaçası \(1968–2012\)),
				'other' => q(Zambiya kvaçası \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambiya Kvaçası),
				'one' => q(Zambiya kvaçası),
				'other' => q(Zambiya kvaçası),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zair Yeni Zairi \(1993–1998\)),
				'one' => q(Zair yeni zairi \(1993–1998\)),
				'other' => q(Zair yeni zairi \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zair Zairi \(1971–1993\)),
				'one' => q(Zair zairi \(1971–1993\)),
				'other' => q(Zair zairi \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabve Dolları \(1980–2008\)),
				'one' => q(Zimbabve dolları \(1980–2008\)),
				'other' => q(Zimbabve dolları \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabve Dolları \(2009\)),
				'one' => q(Zimbabve dolları \(2009\)),
				'other' => q(Zimbabve dolları \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabve Dolları \(2008\)),
				'one' => q(Zimbabve dolları \(2008\)),
				'other' => q(Zimbabve dolları \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'yan',
							'fev',
							'mar',
							'apr',
							'may',
							'iyn',
							'iyl',
							'avq',
							'sen',
							'okt',
							'noy',
							'dek'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'yanvar',
							'fevral',
							'mart',
							'aprel',
							'may',
							'iyun',
							'iyul',
							'avqust',
							'sentyabr',
							'oktyabr',
							'noyabr',
							'dekabr'
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
							'Məh.',
							'Səf.',
							'Rəb. I',
							'Rəb. II',
							'Cəm. I',
							'Cəm. II',
							'Rəc.',
							'Şab.',
							'Ram.',
							'Şəv.',
							'Zilq.',
							'Zilh.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Məhərrəm',
							'Səfər',
							'Rəbiüləvvəl',
							'Rəbiülaxır',
							'Cəmadiyələvvəl',
							'Cəmadiyəlaxır',
							'Rəcəb',
							'Şaban',
							'Ramazan',
							'Şəvval',
							'Zilqədə',
							'Zilhiccə'
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
							'fərvərdin',
							'ordibeheşt',
							'xordəd',
							'tir',
							'mordəd',
							'şəhrivar',
							'mehr',
							'abən',
							'azər',
							'dey',
							'bəhmən',
							'isfənd'
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
						mon => 'B.e.',
						tue => 'Ç.a.',
						wed => 'Ç.',
						thu => 'C.a.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					short => {
						mon => 'B.E.',
						tue => 'Ç.A.',
						wed => 'Ç.',
						thu => 'C.A.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					wide => {
						mon => 'bazar ertəsi',
						tue => 'çərşənbə axşamı',
						wed => 'çərşənbə',
						thu => 'cümə axşamı',
						fri => 'cümə',
						sat => 'şənbə',
						sun => 'bazar'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'B.E.',
						tue => 'Ç.A.',
						wed => 'Ç.',
						thu => 'C.A.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					narrow => {
						mon => '1',
						tue => '2',
						wed => '3',
						thu => '4',
						fri => '5',
						sat => '6',
						sun => '7'
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
					abbreviated => {0 => '1-ci kv.',
						1 => '2-ci kv.',
						2 => '3-cü kv.',
						3 => '4-cü kv.'
					},
					wide => {0 => '1-ci kvartal',
						1 => '2-ci kvartal',
						2 => '3-cü kvartal',
						3 => '4-cü kvartal'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
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
					'afternoon1' => q{gündüz},
					'evening1' => q{axşamüstü},
					'midnight' => q{gecəyarı},
					'morning1' => q{sübh},
					'morning2' => q{səhər},
					'night1' => q{axşam},
					'night2' => q{gecə},
					'noon' => q{günorta},
				},
				'narrow' => {
					'afternoon1' => q{gündüz},
					'am' => q{a},
					'evening1' => q{axşamüstü},
					'midnight' => q{gecəyarı},
					'morning1' => q{sübh},
					'morning2' => q{səhər},
					'night1' => q{axşam},
					'night2' => q{gecə},
					'noon' => q{g},
					'pm' => q{p},
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'e.ə.',
				'1' => 'y.e.'
			},
			wide => {
				'0' => 'eramızdan əvvəl',
				'1' => 'yeni era'
			},
		},
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{G d MMMM y, EEEE},
			'long' => q{G d MMMM, y},
			'medium' => q{G d MMM y},
			'short' => q{GGGGG dd.MM.y},
		},
		'gregorian' => {
			'full' => q{d MMMM y, EEEE},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.yy},
		},
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			GyMd => q{GGGGG d M y},
			MEd => q{dd.MM, E},
			MMMEd => q{d MMM, E},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yyyyM => q{GGGGG MM y},
			yyyyMEd => q{GGGGG dd.MM.y, E},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G d MMM y, E},
			yyyyMMMM => q{G MMMM y},
			yyyyMMMd => q{G d MMM y},
			yyyyMd => q{GGGGG dd.MM.y},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			GyMd => q{GGGGG d MMM y},
			MEd => q{dd.MM, E},
			MMMEd => q{d MMM, E},
			MMMMW => q{MMMM, W 'həftə'},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM.y},
			yMEd => q{dd.MM.y, E},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y, E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yw => q{Y, w 'həftə'},
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
			GyM => {
				G => q{GGGGG MM/y– GGGGG MM/y},
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			GyMEd => {
				G => q{GGGGG dd/MM/y, E – GGGGG dd/MM/y, E},
				M => q{GGGGG dd/MM/y, E – dd/MM/y, E},
				d => q{GGGGG dd/MM/y, E – dd/MM/y, E},
				y => q{GGGGG dd/MM/y, E – dd/MM/y, E},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM – MMM y},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G d MMM y, E – G d MMM y, E},
				M => q{G d MMM, E – d MMM y, E},
				d => q{G d MMM, E – d MMM y, E},
				y => q{G d MMM y, E – d MMM y, E},
			},
			GyMMMd => {
				G => q{G d MMM y – G d MMM y},
				M => q{G d MMM – d MMM y},
				d => q{G d – d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			GyMd => {
				G => q{GGGGG dd/MM/y – GGGGG dd/MM/y},
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
			MEd => {
				M => q{dd.MM, E – dd.MM, E},
				d => q{dd.MM, E – dd.MM, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
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
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			yMEd => {
				M => q{GGGGG dd/MM/y , E – dd/MM/y, E},
				d => q{GGGGG dd/MM/y , E – dd/MM/y, E},
				y => q{GGGGG dd/MM/y , E – dd/MM/y, E},
			},
			yMMM => {
				M => q{G MMM–MMM y},
				y => q{G MMM y – MMM y},
			},
			yMMMEd => {
				M => q{G d MMM y, E – d MMM, E},
				d => q{G d MMM y, E – d MMM, E},
				y => q{G d MMM y, E – d MMM y, E},
			},
			yMMMM => {
				M => q{G MMMM y –MMMM},
				y => q{G MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{G d MMM y – d MMM},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			yMd => {
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
		},
		'gregorian' => {
			GyM => {
				G => q{GGGGG MM.y – GGGGG MM.y},
				M => q{GGGGG MM.y – MM.y},
				y => q{GGGGG MM.y – MM.y},
			},
			GyMEd => {
				G => q{GGGGG dd.MM.y, E – GGGGG dd.MM.y, E},
				M => q{GGGGG dd.MM.y, E – dd.MM.y, E},
				d => q{GGGGG dd.MM.y, E – dd.MM.y, E},
				y => q{GGGGG dd.MM.y, E – dd.MM.y, E},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM – MMM y},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G d MMM y, E – d MMM y, E},
				M => q{G d MMM, E – d MMM y, E},
				d => q{G d MMM, E – d MMM y, E},
				y => q{G d MMM y, E – d MMM y, E},
			},
			GyMMMd => {
				G => q{G d MMM y – G d MMM y},
				M => q{G d MMM – d MMM y},
				d => q{G d – d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			GyMd => {
				G => q{GGGGG dd.MM.y – GGGGG dd.MM.y},
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
			MEd => {
				M => q{dd.MM, E – dd.MM, E},
				d => q{dd.MM, E – dd.MM, E},
			},
			MMMEd => {
				M => q{d MMM, E – d MMM, E},
				d => q{d MMM, E – d MMM, E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
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
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y, E – dd.MM.y, E},
				d => q{dd.MM.y, E – dd.MM.y, E},
				y => q{dd.MM.y, E – dd.MM.y, E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y, E – d MMM, E},
				d => q{d MMM y, E – d MMM, E},
				y => q{d MMM y, E – d MMM y, E},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM y – d MMM},
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
		regionFormat => q({0} Vaxtı),
		regionFormat => q({0} Yay Vaxtı),
		regionFormat => q({0} Standart Vaxtı),
		'Afghanistan' => {
			long => {
				'standard' => q#Əfqanıstan Vaxtı#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abican#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Əddis Əbəbə#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Əlcəzair#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Əsmərə#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Banqui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bancul#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantir#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzavil#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Qahirə#,
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
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Cibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Əl Əyun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Qaboron#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yohanesburq#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Xartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kiqali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinşasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Laqos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaşi#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Moqadişu#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ncamena#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakşot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uqaduqu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#San Tom#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vindhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Mərkəzi Afrika Vaxtı#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Şərqi Afrika Vaxtı#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Cənubi Afrika Vaxtı#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Qərbi Afrika Yay Vaxtı#,
				'generic' => q#Qərbi Afrika Vaxtı#,
				'standard' => q#Qərbi Afrika Standart Vaxtı#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alyaska Yay Vaxtı#,
				'generic' => q#Alyaska Vaxtı#,
				'standard' => q#Alyaska Standart Vaxtı#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon Yay Vaxtı#,
				'generic' => q#Amazon Vaxtı#,
				'standard' => q#Amazon Standart Vaxtı#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankorac#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angilya#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antiqua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguayna#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Rioxa#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Qalyeqos#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Xuan#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Uşuaya#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahiya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Bogota' => {
			exemplarCity => q#Boqota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boyse#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Ayres#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembric Körfəzi#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Qrande#,
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
			exemplarCity => q#Kayen#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Çikaqo#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Çihuahua#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuyaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkşavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Douson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Douson Krik#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroyt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmondton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#İrunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Qleys Körfəzi#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Quz Körfəzi#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Qrand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Qrenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Qvadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Qvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Quayakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Qayana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaks#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosilo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Noks#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marenqo#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pitersburq#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vivey#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsen#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Vinamak#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#İndianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#İnuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#İqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Yamayka#,
		},
		'America/Juneau' => {
			exemplarCity => q#Cuno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montiçello#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendik#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Pas#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Anceles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luisvil#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Aşağı Prins Kvartalı#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maseyo#,
		},
		'America/Managua' => {
			exemplarCity => q#Manaqua#,
		},
		'America/Marigot' => {
			exemplarCity => q#Mariqot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazaltan#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterey#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Monserat#,
		},
		'America/New_York' => {
			exemplarCity => q#Nyu York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipiqon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronya#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Şimali Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Mərkəz, Şimal Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nyu Salem#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ocinaqa#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Panqnirtanq#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Feniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-o-Prins#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#İspan Limanı#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velyo#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reyni Çayı#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Girişi#,
		},
		'America/Recife' => {
			exemplarCity => q#Resif#,
		},
		'America/Regina' => {
			exemplarCity => q#Recina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rezolyut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa İzabel#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santyaqo#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Dominqo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Skoresbisund#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sent-Bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent Cons#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#San Lüsiya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#San Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Vinsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Svift Kurent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tequsiqalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tul#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#İldırım Körfəzi#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tixuana#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Uaythors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vinnipeq#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellounayf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Şimali Mərkəzi Amerika Yay Vaxtı#,
				'generic' => q#Şimali Mərkəzi Amerika Vaxtı#,
				'standard' => q#Şimali Mərkəzi Amerika Standart Vaxtı#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Şimali Şərqi Amerika Yay Vaxtı#,
				'generic' => q#Şimali Şərqi Amerika Vaxtı#,
				'standard' => q#Şimali Şərqi Amerika Standart Vaxtı#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Şimali Dağlıq Amerika Yay Vaxtı#,
				'generic' => q#Şimali Dağlıq Amerika Vaxtı#,
				'standard' => q#Şimali Dağlıq Amerika Standart Vaxtı#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Şimali Amerika Sakit Okean Yay Vaxtı#,
				'generic' => q#Şimali Amerika Sakit Okean Vaxtı#,
				'standard' => q#Şimali Amerika Sakit Okean Standart Vaxtı#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keysi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Deyvis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urvil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makuari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mouson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Mak Murdo#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syova#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Yay Vaxtı#,
				'generic' => q#Apia Vaxtı#,
				'standard' => q#Apia Standart Vaxtı#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ərəbistan Yay Vaxtı#,
				'generic' => q#Ərəbistan Vaxtı#,
				'standard' => q#Ərəbistan Standart Vaxtı#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Lonqyir#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina Yay Vaxtı#,
				'generic' => q#Argentina Vaxtı#,
				'standard' => q#Argentina Standart Vaxtı#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Qərbi Argentina Yay Vaxtı#,
				'generic' => q#Qərbi Argentina Vaxtı#,
				'standard' => q#Qərbi Argentina Standart Vaxtı#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ermənistan Yay Vaxtı#,
				'generic' => q#Ermənistan Vaxtı#,
				'standard' => q#Ermənistan Standart Vaxtı#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatı#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadır#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşqabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atırau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bağdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bəhreyn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakı#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Banqkok#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bişkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruney#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kəlkətə#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Çita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Çoybalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Dəməşq#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dəkkə#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Düşənbə#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famaqusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Qəza#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Honq Konq#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#İrkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Cakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Cayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusəlim#,
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
			exemplarCity => q#Xandıqa#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuçinq#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Küveyt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Maqadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnom Pen#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pxenyan#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qızılorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ranqun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Şi Min#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Saxalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Səmərqənd#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Şanxay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sinqapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolımsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taybey#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Daşkənd#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumçi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vyentyan#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburq#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik Yay Vaxtı#,
				'generic' => q#Atlantik Vaxt#,
				'standard' => q#Atlantik Standart Vaxt#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azor#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermud adaları#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanar#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Farer#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeyra#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykyavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Cənubi Corciya#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Müqəddəs Yelena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbeyn#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kuriye#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darvin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yukla#,
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
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Mərkəzi Avstraliya Yay Vaxtı#,
				'generic' => q#Mərkəzi Avstraliya Vaxtı#,
				'standard' => q#Mərkəzi Avstraliya Standart Vaxtı#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Mərkəzi Qərbi Avstraliya Yay Vaxtı#,
				'generic' => q#Mərkəzi Qərbi Avstraliya Vaxtı#,
				'standard' => q#Mərkəzi Qərbi Avstraliya Standart Vaxtı#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Şərqi Avstraliya Yay Vaxtı#,
				'generic' => q#Şərqi Avstraliya Vaxtı#,
				'standard' => q#Şərqi Avstraliya Standart Vaxtı#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Qərbi Avstraliya Yay Vaxtı#,
				'generic' => q#Qərbi Avstraliya Vaxtı#,
				'standard' => q#Qərbi Avstraliya Standart Vaxtı#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azərbaycan Yay Vaxtı#,
				'generic' => q#Azərbaycan Vaxtı#,
				'standard' => q#Azərbaycan Standart Vaxtı#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azor Yay Vaxtı#,
				'generic' => q#Azor Vaxtı#,
				'standard' => q#Azor Standart Vaxtı#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Banqladeş Yay Vaxtı#,
				'generic' => q#Banqladeş Vaxtı#,
				'standard' => q#Banqladeş Standart Vaxtı#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan Vaxtı#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliviya Vaxtı#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Braziliya Yay Vaxtı#,
				'generic' => q#Braziliya Vaxtı#,
				'standard' => q#Braziliya Standart Vaxtı#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam vaxtı#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kape Verde Yay Vaxtı#,
				'generic' => q#Kape Verde Vaxtı#,
				'standard' => q#Kape Verde Standart Vaxtı#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Çamorro Vaxtı#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Çatham Yay Vaxtı#,
				'generic' => q#Çatham Vaxtı#,
				'standard' => q#Çatham Standart Vaxtı#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Çili Yay Vaxtı#,
				'generic' => q#Çili Vaxtı#,
				'standard' => q#Çili Standart Vaxtı#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Çin Yay Vaxtı#,
				'generic' => q#Çin Vaxtı#,
				'standard' => q#Çin Standart Vaxtı#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Çoybalsan Yay Vaxtı#,
				'generic' => q#Çoybalsan Vaxtı#,
				'standard' => q#Çoybalsan Standart Vaxtı#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Milad Adası Vaxtı#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokos Adaları Vaxtı#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbiya Yay Vaxtı#,
				'generic' => q#Kolumbiya Vaxtı#,
				'standard' => q#Kolumbiya Standart Vaxtı#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kuk Adaları Yarım Yay Vaxtı#,
				'generic' => q#Kuk Adaları Vaxtı#,
				'standard' => q#Kuk Adaları Standart Vaxtı#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba Yay Vaxtı#,
				'generic' => q#Kuba Vaxtı#,
				'standard' => q#Kuba Standart Vaxtı#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Devis Vaxtı#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dümon-d’Ürvil Vaxtı#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Şərqi Timor Vaxtı#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Pasxa Adası Yay Vaxtı#,
				'generic' => q#Pasxa Adası Vaxtı#,
				'standard' => q#Pasxa Adası Standart Vaxtı#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvador Vaxtı#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinasiya edilmiş ümumdünya vaxtı#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Naməlum Şəhər#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Həştərxan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Afina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belqrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Buxarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeşt#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kişinyov#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#İrlandiya Yay Vaxtı#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Cəbəli-Tariq#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernzey#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Men Adası#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#İstanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Cersi#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalininqrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lyublyana#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britaniya Yay Vaxtı#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lüksemburq#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariham#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podqoritsa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praqa#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riqa#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayevo#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopye#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ujqorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduts#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vyana#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnüs#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volqoqrad#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varşava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zaqreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporojye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Sürix#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Mərkəzi Avropa Yay Vaxtı#,
				'generic' => q#Mərkəzi Avropa Vaxtı#,
				'standard' => q#Mərkəzi Avropa Standart Vaxtı#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Şərqi Avropa Yay Vaxtı#,
				'generic' => q#Şərqi Avropa Vaxtı#,
				'standard' => q#Şərqi Avropa Standart Vaxtı#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kənar Şərqi Avropa Vaxtı#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Qərbi Avropa Yay Vaxtı#,
				'generic' => q#Qərbi Avropa Vaxtı#,
				'standard' => q#Qərbi Avropa Standart Vaxtı#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklend Adaları Yay Vaxtı#,
				'generic' => q#Folklend Adaları Vaxtı#,
				'standard' => q#Folklend Adaları Standart Vaxtı#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fici Yay Vaxtı#,
				'generic' => q#Fici Vaxtı#,
				'standard' => q#Fici Standart Vaxtı#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Fransız Qvianası Vaxtı#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Fransız Cənubi və Antarktik Vaxtı#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Qrinviç Orta Vaxtı#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Qalapaqos Vaxtı#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Qambier Vaxtı#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gurcüstan Yay Vaxtı#,
				'generic' => q#Gurcüstan Vaxtı#,
				'standard' => q#Gurcüstan Standart Vaxtı#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Adaları Vaxtı#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Şərqi Qrenlandiya Yay Vaxtı#,
				'generic' => q#Şərqi Qrenlandiya Vaxtı#,
				'standard' => q#Şərqi Qrenlandiya Standart Vaxtı#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Qərbi Qrenlandiya Yay Vaxtı#,
				'generic' => q#Qərbi Qrenlandiya Vaxtı#,
				'standard' => q#Qərbi Qrenlandiya Standart Vaxtı#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Körfəz Vaxtı#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Qayana Vaxtı#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Havay-Aleut Yay Vaxtı#,
				'generic' => q#Havay-Aleut Vaxtı#,
				'standard' => q#Havay-Aleut Standart Vaxtı#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Honq Konq Yay Vaxtı#,
				'generic' => q#Honq Konq Vaxtı#,
				'standard' => q#Honq Konq Standart Vaxtı#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Yay Vaxtı#,
				'generic' => q#Hovd Vaxtı#,
				'standard' => q#Hovd Standart Vaxtı#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hindistan Vaxtı#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Çaqos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Milad#,
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
		'Indian/Maldives' => {
			exemplarCity => q#Maldiv#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mavriki#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayot#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hind Okeanı Vaxtı#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hindçin Vaxtı#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Mərkəzi İndoneziya Vaxtı#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Şərqi İndoneziya Vaxtı#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Qərbi İndoneziya Vaxtı#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#İran Yay Vaxtı#,
				'generic' => q#İran Vaxtı#,
				'standard' => q#İran Standart Vaxtı#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#İrkutsk Yay Vaxtı#,
				'generic' => q#İrkutsk Vaxtı#,
				'standard' => q#İrkutsk Standart Vaxtı#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#İsrail Yay Vaxtı#,
				'generic' => q#İsrail Vaxtı#,
				'standard' => q#İsrail Standart Vaxtı#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Yaponiya Yay Vaxtı#,
				'generic' => q#Yaponiya Vaxtı#,
				'standard' => q#Yaponiya Standart Vaxtı#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Şərqi Qazaxıstan Vaxtı#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Qərbi Qazaxıstan Vaxtı#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreya Yay Vaxtı#,
				'generic' => q#Koreya Vaxtı#,
				'standard' => q#Koreya Standart Vaxtı#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Korse Vaxtı#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk Yay Vaxtı#,
				'generic' => q#Krasnoyarsk Vaxtı#,
				'standard' => q#Krasnoyarsk Standart Vaxtı#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Qırğızıstan Vaxtı#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Layn Adaları Vaxtı#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Hau Yay vaxtı#,
				'generic' => q#Lord Hau Vaxtı#,
				'standard' => q#Lord Hau Standart Vaxtı#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Makari Adası Vaxtı#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Maqadan Yay Vaxtı#,
				'generic' => q#Maqadan Vaxtı#,
				'standard' => q#Maqadan Standart Vaxtı#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malayziya Vaxtı#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldiv Vaxtı#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markesas Vaxtı#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marşal Adaları Vaxtı#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mavriki Yay Vaxtı#,
				'generic' => q#Mavriki Vaxtı#,
				'standard' => q#Mavriki Standart Vaxtı#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mouson Vaxtı#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Şimal-Qərbi Meksika Yay Vaxtı#,
				'generic' => q#Şimal-Qərbi Meksika Vaxtı#,
				'standard' => q#Şimal-Qərbi Meksika Standart Vaxtı#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksika Sakit Okean Yay Vaxtı#,
				'generic' => q#Meksika Sakit Okean Vaxtı#,
				'standard' => q#Meksika Sakit Okean Standart Vaxtı#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulanbator Yay Vaxtı#,
				'generic' => q#Ulanbator Vaxtı#,
				'standard' => q#Ulanbator Standart Vaxtı#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva Yay vaxtı#,
				'generic' => q#Moskva Vaxtı#,
				'standard' => q#Moskva Standart Vaxtı#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanma Vaxtı#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Vaxtı#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal vaxtı#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Yeni Kaledoniya Yay Vaxtı#,
				'generic' => q#Yeni Kaledoniya Vaxtı#,
				'standard' => q#Yeni Kaledoniya Standart Vaxtı#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Yeni Zelandiya Yay Vaxtı#,
				'generic' => q#Yeni Zelandiya Vaxtı#,
				'standard' => q#Yeni Zelandiya Standart Vaxtı#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nyufaundlend Yay Vaxtı#,
				'generic' => q#Nyufaundlend Vaxtı#,
				'standard' => q#Nyufaundlend Standart Vaxtı#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Vaxtı#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Adası Yay Vaxtı#,
				'generic' => q#Norfolk Adası Vaxtı#,
				'standard' => q#Norfolk Adası Standart Vaxtı#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronya Yay Vaxtı#,
				'generic' => q#Fernando de Noronya Vaxtı#,
				'standard' => q#Fernando de Noronya Standart Vaxtı#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk Yay Vaxtı#,
				'generic' => q#Novosibirsk Vaxtı#,
				'standard' => q#Novosibirsk Standart Vaxtı#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Yay Vaxtı#,
				'generic' => q#Omsk Vaxtı#,
				'standard' => q#Omsk Standart Vaxtı#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Oklənd#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Buqanvil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Çatam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasxa#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderböri#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fici#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Qalapaqos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Qambiyer#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Quadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Quam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Conston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kirimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosraye#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kvajaleyn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Macuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvey#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Paqo Paqo#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonqa#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saypan#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarava#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tonqapatu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Çuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Veyk#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Uollis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan Yay Vaxtı#,
				'generic' => q#Pakistan Vaxtı#,
				'standard' => q#Pakistan Standart vaxtı#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Vaxtı#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Yeni Qvineya Vaxtı#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraqvay Yay Vaxtı#,
				'generic' => q#Paraqvay Vaxtı#,
				'standard' => q#Paraqvay Standart Vaxtı#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Yay Vaxtı#,
				'generic' => q#Peru Vaxtı#,
				'standard' => q#Peru Standart Vaxtı#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippin Yay Vaxtı#,
				'generic' => q#Filippin Vaxtı#,
				'standard' => q#Filippin Standart Vaxtı#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Feniks Adaları Vaxtı#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Müqəddəs Pyer və Mikelon Yay Vaxtı#,
				'generic' => q#Müqəddəs Pyer və Mikelon Vaxtı#,
				'standard' => q#Müqəddəs Pyer və Mikelon Standart Vaxtı#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkern Vaxtı#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Vaxtı#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pxenyan Vaxtı#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reyunyon#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera Vaxtı#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Saxalin Yay Vaxtı#,
				'generic' => q#Saxalin Vaxtı#,
				'standard' => q#Saxalin Standart Vaxtı#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara yay vaxtı#,
				'generic' => q#Samara vaxtı#,
				'standard' => q#Samara standart vaxtı#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Yay Vaxtı#,
				'generic' => q#Samoa Vaxtı#,
				'standard' => q#Samoa Standart Vaxtı#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seyşel Adaları Vaxtı#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Sinqapur Vaxtı#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Adaları Vaxtı#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Cənubi Corciya Vaxtı#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam Vaxtı#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syova Vaxtı#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Vaxtı#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taybey Yay Vaxtı#,
				'generic' => q#Taybey Vaxtı#,
				'standard' => q#Taybey Standart Vaxtı#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tacikistan Vaxtı#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Vaxtı#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonqa Yay Vaxtı#,
				'generic' => q#Tonqa Vaxtı#,
				'standard' => q#Tonqa Standart Vaxtı#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Çuuk Vaxtı#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Türkmənistan Yay Vaxtı#,
				'generic' => q#Türkmənistan Vaxtı#,
				'standard' => q#Türkmənistan Standart Vaxtı#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu Vaxtı#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruqvay Yay Vaxtı#,
				'generic' => q#Uruqvay Vaxtı#,
				'standard' => q#Uruqvay Standart Vaxtı#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Özbəkistan Yay Vaxtı#,
				'generic' => q#Özbəkistan Vaxtı#,
				'standard' => q#Özbəkistan Standart Vaxtı#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vaunatu Yay Vaxtı#,
				'generic' => q#Vanuatu Vaxtı#,
				'standard' => q#Vanuatu Standart Vaxtı#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venesuela Vaxtı#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Yay Vaxtı#,
				'generic' => q#Vladivostok Vaxtı#,
				'standard' => q#Vladivostok Standart Vaxtı#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volqoqrad Yay Vaxtı#,
				'generic' => q#Volqoqrad Vaxtı#,
				'standard' => q#Volqoqrad Standart Vaxtı#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok Vaxtı#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ueyk Vaxtı#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Uollis və Futuna Vaxtı#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk Yay Vaxtı#,
				'generic' => q#Yakutsk Vaxtı#,
				'standard' => q#Yakutsk Standart Vaxtı#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburq Yay Vaxtı#,
				'generic' => q#Yekaterinburq Vaxtı#,
				'standard' => q#Yekaterinburq Standart Vaxtı#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Vaxtı#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
