=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Cy - Package for language Welsh

=cut

package Locale::CLDR::Locales::Cy;
# This file auto generated from Data\common\main\cy.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-masculine-before-consonant','spellout-cardinal-feminine','spellout-cardinal-feminine-before-consonant' ]},
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
					rule => q(minws →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(dim),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pwynt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dwy),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tair),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(pedair),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pump),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(chwech),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(saith),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(wyth),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naw),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(un deg[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dau ddeg[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine-before-consonant← deg[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine-before-consonant← cant[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← miliwn[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← biliwn[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← triliwn[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← kwadriliwn[ →→]),
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
		'spellout-cardinal-feminine-before-consonant' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minws →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(dim),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pwynt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dwy),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tair),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(pedair),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pum),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(chwe),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(saith),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(wyth),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naw),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(un deg[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dau ddeg[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine-before-consonant← deg[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine-before-consonant← cant[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← miliwn[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← biliwn[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← triliwn[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← kwadriliwn[ →→]),
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
					rule => q(minws →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(dim),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pwynt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dau),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(pedwar),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pump),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(chwech),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(saith),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(wyth),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naw),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(un deg[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dau ddeg[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine-before-consonant← deg[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine-before-consonant← cant[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← miliwn[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← biliwn[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← triliwn[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← kwadriliwn[ →→]),
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
		'spellout-cardinal-masculine-before-consonant' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minws →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(dim),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pwynt →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dau),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(pedwar),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(pum),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(chwe),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(saith),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(wyth),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naw),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(un deg[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dau ddeg[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine-before-consonant← deg[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine-before-consonant← cant[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← miliwn[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← biliwn[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← triliwn[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-before-consonant← kwadriliwn[ →→]),
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
				'aa' => 'Affareg',
 				'ab' => 'Abchaseg',
 				'ace' => 'Acehneg',
 				'ach' => 'Acoli',
 				'ada' => 'Adangmeg',
 				'ady' => 'Circaseg Gorllewinol',
 				'ae' => 'Afestaneg',
 				'aeb' => 'Arabeg Tunisia',
 				'af' => 'Affricaneg',
 				'afh' => 'Affrihili',
 				'agq' => 'Aghemeg',
 				'ain' => 'Ainŵeg',
 				'ak' => 'Acaneg',
 				'akk' => 'Acadeg',
 				'akz' => 'Alabamäeg',
 				'ale' => 'Alewteg',
 				'aln' => 'Ghegeg Albania',
 				'alt' => 'Altäeg Deheuol',
 				'am' => 'Amhareg',
 				'an' => 'Aragoneg',
 				'ang' => 'Hen Saesneg',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Arabeg',
 				'ar_001' => 'Arabeg Modern Safonol',
 				'arc' => 'Aramaeg',
 				'arn' => 'Arawcaneg',
 				'aro' => 'Araonaeg',
 				'arp' => 'Arapaho',
 				'arq' => 'Arabeg Algeria',
 				'ars' => 'Arabeg Najdi',
 				'arw' => 'Arawaceg',
 				'ary' => 'Arabeg Moroco',
 				'arz' => 'Arabeg yr Aifft',
 				'as' => 'Asameg',
 				'asa' => 'Asw',
 				'ase' => 'Iaith Arwyddion America',
 				'ast' => 'Astwrianeg',
 				'atj' => 'Atikamekw',
 				'av' => 'Afareg',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymareg',
 				'az' => 'Aserbaijaneg',
 				'az@alt=short' => 'Aseri',
 				'az_Arab' => 'Aserbaijaneg Deheuol',
 				'ba' => 'Bashcorteg',
 				'bal' => 'Balwtsi',
 				'ban' => 'Balïeg',
 				'bas' => 'Basâeg',
 				'bax' => 'Bamwmeg',
 				'be' => 'Belarwseg',
 				'bej' => 'Bejäeg',
 				'bem' => 'Bembeg',
 				'bez' => 'Bena',
 				'bfd' => 'Baffwteg',
 				'bfq' => 'Badaga',
 				'bg' => 'Bwlgareg',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'Balochi Gorllewinol',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bkm' => 'Comeg',
 				'bla' => 'Siksika',
 				'bm' => 'Bambareg',
 				'bn' => 'Bengaleg',
 				'bo' => 'Tibeteg',
 				'br' => 'Llydaweg',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnieg',
 				'bss' => 'Acwseg',
 				'bua' => 'Bwriateg',
 				'bug' => 'Bwginaeg',
 				'bum' => 'Bwlw',
 				'byn' => 'Blin',
 				'ca' => 'Catalaneg',
 				'cad' => 'Cado',
 				'car' => 'Caribeg',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsameg',
 				'ccp' => 'Tsiacma',
 				'ce' => 'Tsietsieneg',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Tsiga',
 				'ch' => 'Tsiamorro',
 				'chk' => 'Chuukaeg',
 				'chm' => 'Marieg',
 				'cho' => 'Siocto',
 				'chp' => 'Chipewyan',
 				'chr' => 'Tsierocî',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Cwrdeg Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Corseg',
 				'cop' => 'Copteg',
 				'cr' => 'Cri',
 				'crg' => 'Michif',
 				'crh' => 'Tyrceg y Crimea',
 				'crj' => 'Cree De Ddwyrain',
 				'crk' => 'Plains Cree',
 				'crl' => 'Gogledd Dwyrain Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonquian',
 				'crs' => 'Ffrangeg Seselwa Creole',
 				'cs' => 'Tsieceg',
 				'csw' => 'Swampy Cree',
 				'cu' => 'Hen Slafoneg',
 				'cv' => 'Tshwfasheg',
 				'cy' => 'Cymraeg',
 				'da' => 'Daneg',
 				'dak' => 'Dacotaeg',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Almaeneg',
 				'de_AT' => 'Almaeneg Awstria',
 				'de_CH' => 'Almaeneg Safonol y Swistir',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinca',
 				'dje' => 'Sarmaeg',
 				'doi' => 'Dogri',
 				'dsb' => 'Sorbeg Isaf',
 				'dua' => 'Diwaleg',
 				'dum' => 'Iseldireg Canol',
 				'dv' => 'Difehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embw',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Hen Eiffteg',
 				'eka' => 'Ekajuk',
 				'el' => 'Groeg',
 				'elx' => 'Elameg',
 				'en' => 'Saesneg',
 				'en_AU' => 'Saesneg Awstralia',
 				'en_CA' => 'Saesneg Canada',
 				'en_GB' => 'Saesneg Prydain',
 				'en_GB@alt=short' => 'Saesneg (DU)',
 				'en_US' => 'Saesneg America',
 				'en_US@alt=short' => 'Saesneg (UDA)',
 				'enm' => 'Saesneg Canol',
 				'eo' => 'Esperanto',
 				'es' => 'Sbaeneg',
 				'es_419' => 'Sbaeneg America Ladin',
 				'es_ES' => 'Sbaeneg Ewrop',
 				'es_MX' => 'Sbaeneg Mecsico',
 				'et' => 'Estoneg',
 				'eu' => 'Basgeg',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremadureg',
 				'fa' => 'Perseg',
 				'fa_AF' => 'Dari',
 				'fat' => 'Ffanti',
 				'ff' => 'Ffwla',
 				'fi' => 'Ffinneg',
 				'fil' => 'Ffilipineg',
 				'fit' => 'Ffinneg Tornedal',
 				'fj' => 'Ffijïeg',
 				'fo' => 'Ffaröeg',
 				'fon' => 'Fon',
 				'fr' => 'Ffrangeg',
 				'fr_CA' => 'Ffrangeg Canada',
 				'fr_CH' => 'Ffrangeg y Swistir',
 				'frc' => 'Ffrangeg Cajwn',
 				'frm' => 'Ffrangeg Canol',
 				'fro' => 'Hen Ffrangeg',
 				'frp' => 'Arpitaneg',
 				'frr' => 'Ffriseg Gogleddol',
 				'frs' => 'Ffriseg y Dwyrain',
 				'fur' => 'Ffriwleg',
 				'fy' => 'Ffriseg y Gorllewin',
 				'ga' => 'Gwyddeleg',
 				'gaa' => 'Ga',
 				'gag' => 'Gagauz',
 				'gay' => 'Gaio',
 				'gba' => 'Gbaia',
 				'gbz' => 'Dareg y Zoroastriaid',
 				'gd' => 'Gaeleg yr Alban',
 				'gez' => 'Geez',
 				'gil' => 'Gilberteg',
 				'gl' => 'Galisieg',
 				'gmh' => 'Almaeneg Uchel Canol',
 				'gn' => 'Guaraní',
 				'goh' => 'Hen Almaeneg Uchel',
 				'gor' => 'Gorontalo',
 				'got' => 'Gotheg',
 				'grc' => 'Hen Roeg',
 				'gsw' => 'Almaeneg y Swistir',
 				'gu' => 'Gwjarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manaweg',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hawsa',
 				'hai' => 'Haida',
 				'haw' => 'Hawäieg',
 				'hax' => 'Haida Deheuol',
 				'he' => 'Hebraeg',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hetheg',
 				'hmn' => 'Hmongeg',
 				'hr' => 'Croateg',
 				'hsb' => 'Sorbeg Uchaf',
 				'ht' => 'Creol Haiti',
 				'hu' => 'Hwngareg',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armeneg',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Ibaneg',
 				'ibb' => 'Ibibio',
 				'id' => 'Indoneseg',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Nwosw',
 				'ik' => 'Inwpiaceg',
 				'ikt' => 'Inuktitut Canadaidd Gorllewinol',
 				'ilo' => 'Ilocaneg',
 				'inh' => 'Ingwsieg',
 				'io' => 'Ido',
 				'is' => 'Islandeg',
 				'it' => 'Eidaleg',
 				'iu' => 'Inwctitwt',
 				'ja' => 'Japaneeg',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Matsiame',
 				'jpr' => 'Iddew-Bersieg',
 				'jrb' => 'Iddew-Arabeg',
 				'jv' => 'Jafanaeg',
 				'ka' => 'Georgeg',
 				'kaa' => 'Cara-Calpaceg',
 				'kab' => 'Cabileg',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Camba',
 				'kbd' => 'Cabardieg',
 				'kcg' => 'Tyapeg',
 				'kde' => 'Macondeg',
 				'kea' => 'Caboferdianeg',
 				'kfo' => 'Koro',
 				'kg' => 'Congo',
 				'kgp' => 'Kaingang',
 				'kha' => 'Càseg',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Chowareg',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Casacheg',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Chmereg',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Coreeg',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Concani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Canwri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Careleg',
 				'kru' => 'Kurukh',
 				'ks' => 'Cashmireg',
 				'ksb' => 'Shambala',
 				'ksf' => 'Baffia',
 				'ksh' => 'Cwleneg',
 				'ku' => 'Cwrdeg',
 				'kum' => 'Cwmiceg',
 				'kv' => 'Comi',
 				'kw' => 'Cernyweg',
 				'kwk' => 'Kwakʼwala',
 				'ky' => 'Cirgiseg',
 				'la' => 'Lladin',
 				'lad' => 'Iddew-Sbaeneg',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Lwcsembwrgeg',
 				'lez' => 'Lezgheg',
 				'lg' => 'Ganda',
 				'li' => 'Limbwrgeg',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombardeg',
 				'ln' => 'Lingala',
 				'lo' => 'Laoeg',
 				'lol' => 'Mongo',
 				'lou' => 'Louisiana Creole',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Gogleddol',
 				'lsm' => 'Saamia',
 				'lt' => 'Lithwaneg',
 				'ltg' => 'Latgaleg',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lwnda',
 				'luo' => 'Lŵo',
 				'lus' => 'Lwshaieg',
 				'luy' => 'Lwyia',
 				'lv' => 'Latfieg',
 				'mad' => 'Madwreg',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Macasareg',
 				'man' => 'Mandingo',
 				'mas' => 'Masai',
 				'mdf' => 'Mocsia',
 				'mdr' => 'Mandareg',
 				'men' => 'Mendeg',
 				'mer' => 'Mêrw',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagaseg',
 				'mga' => 'Gwyddeleg Canol',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta',
 				'mh' => 'Marsialeg',
 				'mi' => 'Māori',
 				'mic' => 'Micmaceg',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedoneg',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoleg',
 				'mnc' => 'Manshw',
 				'mni' => 'Manipwri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohoceg',
 				'mos' => 'Mosi',
 				'mr' => 'Marathi',
 				'mrj' => 'Mari Gorllewinol',
 				'ms' => 'Maleieg',
 				'mt' => 'Malteg',
 				'mua' => 'Mundang',
 				'mul' => 'Mwy nag un iaith',
 				'mus' => 'Creek',
 				'mwl' => 'Mirandeg',
 				'mwr' => 'Marwari',
 				'my' => 'Byrmaneg',
 				'myv' => 'Erzya',
 				'mzn' => 'Masanderani',
 				'na' => 'Nawrŵeg',
 				'nap' => 'Naplieg',
 				'naq' => 'Nama',
 				'nb' => 'Norwyeg Bokmål',
 				'nd' => 'Ndebele Gogleddol',
 				'nds' => 'Almaeneg Isel',
 				'nds_NL' => 'Sacsoneg Isel',
 				'ne' => 'Nepaleg',
 				'new' => 'Newaeg',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuean',
 				'njo' => 'Ao Naga',
 				'nl' => 'Iseldireg',
 				'nl_BE' => 'Fflemeg',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norwyeg Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwyeg',
 				'nog' => 'Nogai',
 				'non' => 'Hen Norseg',
 				'nqo' => 'N’Ko',
 				'nr' => 'Ndebele Deheuol',
 				'nso' => 'Sotho Gogleddol',
 				'nus' => 'Nŵereg',
 				'nv' => 'Nafaho',
 				'nwc' => 'Hen Newari',
 				'ny' => 'Nianja',
 				'nym' => 'Niamwezi',
 				'nyn' => 'Niancole',
 				'nyo' => 'Nioro',
 				'nzi' => 'Nzimeg',
 				'oc' => 'Ocsitaneg',
 				'oj' => 'Ojibwa',
 				'ojb' => 'Ojibwa gogledd-orllewin',
 				'ojc' => 'Ojibwa Canolog',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Ojibwa Gorllewinol',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Oseteg',
 				'osa' => 'Osageg',
 				'ota' => 'Tyrceg Otoman',
 				'pa' => 'Pwnjabeg',
 				'pag' => 'Pangasineg',
 				'pal' => 'Pahlafi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palawan',
 				'pcd' => 'Picardeg',
 				'pcm' => 'Pidgin Nigeria',
 				'pdc' => 'Almaeneg Pensylfania',
 				'peo' => 'Hen Bersieg',
 				'pfl' => 'Almaeneg Palatin',
 				'phn' => 'Phoeniceg',
 				'pi' => 'Pali',
 				'pis' => 'Pijin',
 				'pl' => 'Pwyleg',
 				'pms' => 'Piedmonteg',
 				'pnt' => 'Ponteg',
 				'pon' => 'Pohnpeianeg',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Prwseg',
 				'pro' => 'Hen Brofensaleg',
 				'ps' => 'Pashto',
 				'pt' => 'Portiwgaleg',
 				'pt_BR' => 'Portiwgaleg Brasil',
 				'pt_PT' => 'Portiwgaleg Ewrop',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'raj' => 'Rajasthaneg',
 				'rap' => 'Rapanŵi',
 				'rar' => 'Raratongeg',
 				'rhg' => 'Rohingya',
 				'rm' => 'Románsh',
 				'rn' => 'Rwndi',
 				'ro' => 'Rwmaneg',
 				'ro_MD' => 'Moldofeg',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
 				'rtm' => 'Rotumaneg',
 				'ru' => 'Rwseg',
 				'rup' => 'Aromaneg',
 				'rw' => 'Ciniarŵandeg',
 				'rwk' => 'Rwa',
 				'sa' => 'Sansgrit',
 				'sad' => 'Sandäweg',
 				'sah' => 'Sakha',
 				'sam' => 'Aramaeg Samaria',
 				'saq' => 'Sambŵrw',
 				'sas' => 'Sasaceg',
 				'sat' => 'Santali',
 				'sba' => 'Ngambeieg',
 				'sbp' => 'Sangw',
 				'sc' => 'Sardeg',
 				'scn' => 'Sisileg',
 				'sco' => 'Sgoteg',
 				'sd' => 'Sindhi',
 				'sdc' => 'Sasareseg Sardinia',
 				'sdh' => 'Cwrdeg Deheuol',
 				'se' => 'Sami Gogleddol',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selcypeg',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Hen Wyddeleg',
 				'sgs' => 'Samogiteg',
 				'sh' => 'Serbo-Croateg',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'shu' => 'Arabeg Chad',
 				'si' => 'Sinhaleg',
 				'sid' => 'Sidamo',
 				'sk' => 'Slofaceg',
 				'sl' => 'Slofeneg',
 				'slh' => 'Lushootseed Deheuol',
 				'sli' => 'Is-silesieg',
 				'sm' => 'Samöeg',
 				'sma' => 'Sami Deheuol',
 				'smj' => 'Sami Lwle',
 				'smn' => 'Inari Sami',
 				'sms' => 'Sami Scolt',
 				'sn' => 'Shona',
 				'snk' => 'Soninceg',
 				'so' => 'Somaleg',
 				'sog' => 'Sogdeg',
 				'sq' => 'Albaneg',
 				'sr' => 'Serbeg',
 				'srn' => 'Sranan Tongo',
 				'srr' => 'Serereg',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Sesotheg Deheuol',
 				'stq' => 'Ffriseg Saterland',
 				'str' => 'Straits Salish',
 				'su' => 'Swndaneg',
 				'suk' => 'Swcwma',
 				'sus' => 'Swsŵeg',
 				'sux' => 'Swmereg',
 				'sv' => 'Swedeg',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Swahili’r Congo',
 				'swb' => 'Comoreg',
 				'syc' => 'Hen Syrieg',
 				'syr' => 'Syrieg',
 				'szl' => 'Silesieg',
 				'ta' => 'Tamileg',
 				'tce' => 'Tutchone Deheuol',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timneg',
 				'teo' => 'Teso',
 				'ter' => 'Terena',
 				'tet' => 'Tetumeg',
 				'tg' => 'Tajiceg',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigreg',
 				'tiv' => 'Tifeg',
 				'tk' => 'Tyrcmeneg',
 				'tkl' => 'Tocelaweg',
 				'tkr' => 'Tsakhureg',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tly' => 'Talysheg',
 				'tmh' => 'Tamasheceg',
 				'tn' => 'Tswana',
 				'to' => 'Tongeg',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Tyrceg',
 				'trv' => 'Taroko',
 				'ts' => 'Tsongaeg',
 				'tsd' => 'Tsaconeg',
 				'tt' => 'Tatareg',
 				'ttm' => 'Tutchone gogleddol',
 				'tum' => 'Twmbwca',
 				'tvl' => 'Twfalweg',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitïeg',
 				'tyv' => 'Twfwnieg',
 				'tzm' => 'Tamazight Canol yr Atlas',
 				'udm' => 'Fotiaceg',
 				'ug' => 'Uighur',
 				'uga' => 'Wgariteg',
 				'uk' => 'Wcreineg',
 				'umb' => 'Umbundu',
 				'und' => 'Iaith anhysbys',
 				'ur' => 'Wrdw',
 				'uz' => 'Wsbeceg',
 				'vai' => 'Faieg',
 				've' => 'Fendeg',
 				'vec' => 'Feniseg',
 				'vep' => 'Feps',
 				'vi' => 'Fietnameg',
 				'vls' => 'Fflemeg Gorllewinol',
 				'vo' => 'Folapük',
 				'vot' => 'Foteg',
 				'vun' => 'Funjo',
 				'wa' => 'Walwneg',
 				'wae' => 'Walsereg',
 				'wal' => 'Walamo',
 				'war' => 'Winarayeg',
 				'was' => 'Washo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Woloff',
 				'wuu' => 'Wu Tsieineaidd',
 				'xal' => 'Calmyceg',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yav' => 'Iangben',
 				'ybb' => 'Iembaeg',
 				'yi' => 'Iddew-Almaeneg',
 				'yo' => 'Iorwba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Cantoneeg',
 				'yue@alt=menu' => 'Tsieinëeg, Cantoneg',
 				'zap' => 'Zapoteceg',
 				'zbl' => 'Blisssymbols',
 				'zea' => 'Zêlandeg',
 				'zgh' => 'Tamaseit Moroco Safonol',
 				'zh' => 'Tsieinëeg',
 				'zh@alt=menu' => 'Tsieinëeg, Mandarin',
 				'zh_Hans' => 'Tsieinëeg Symledig',
 				'zh_Hans@alt=long' => 'Tsieinëeg Mandarin Symledig',
 				'zh_Hant' => 'Tsieinëeg Traddodiadol',
 				'zh_Hant@alt=long' => 'Tsieinëeg Mandarin Traddodiadol',
 				'zu' => 'Swlw',
 				'zun' => 'Swni',
 				'zxx' => 'Dim cynnwys ieithyddol',
 				'zza' => 'Sasäeg',

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
 			'Arab' => 'Arabaidd',
 			'Aran' => 'Nastaliq',
 			'Armn' => 'Armenaidd',
 			'Beng' => 'Bangla',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Meysydd Llafur Cynfrodorol Unedig Canada',
 			'Cher' => 'Cherokee',
 			'Cyrl' => 'Cyrilig',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopig',
 			'Geor' => 'Georgaidd',
 			'Grek' => 'Groegaidd',
 			'Gujr' => 'Gwjarataidd',
 			'Guru' => 'Gwrmwci',
 			'Hanb' => 'Han gyda Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Symledig',
 			'Hans@alt=stand-alone' => 'Han symledig',
 			'Hant' => 'Traddodiadol',
 			'Hant@alt=stand-alone' => 'Han traddodiadol',
 			'Hebr' => 'Hebreig',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Syllwyddor Japaneaidd',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Japaneaidd',
 			'Kana' => 'Catacana',
 			'Khmr' => 'Chmeraidd',
 			'Knda' => 'Canaraidd',
 			'Kore' => 'Coreaidd',
 			'Laoo' => 'Laoaidd',
 			'Latn' => 'Lladin',
 			'Mlym' => 'Malayalamaidd',
 			'Mong' => 'Mongolaidd',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Myanmaraidd',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Ol Chiki',
 			'Orya' => 'Orïaidd',
 			'Rohg' => 'Hanifi',
 			'Sinh' => 'Sinhanaidd',
 			'Sund' => 'Swndaneg',
 			'Syrc' => 'Syrieg',
 			'Taml' => 'Tamilaidd',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Tifinagh',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Tai',
 			'Tibt' => 'Tibetaidd',
 			'Vaii' => 'Vai',
 			'Yiii' => 'Yi',
 			'Zmth' => 'Nodiant Mathemategol',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Symbolau',
 			'Zxxx' => 'Anysgrifenedig',
 			'Zyyy' => 'Cyffredin',
 			'Zzzz' => 'Sgript anhysbys',

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
			'001' => 'Y Byd',
 			'002' => 'Affrica',
 			'003' => 'Gogledd America',
 			'005' => 'De America',
 			'009' => 'Oceania',
 			'011' => 'Gorllewin Affrica',
 			'013' => 'Canolbarth America',
 			'014' => 'Dwyrain Affrica',
 			'015' => 'Gogledd Affrica',
 			'017' => 'Canol Affrica',
 			'018' => 'Deheudir Affrica',
 			'019' => 'Yr Amerig',
 			'021' => 'America i’r Gogledd o Fecsico',
 			'029' => 'Y Caribî',
 			'030' => 'Dwyrain Asia',
 			'034' => 'De Asia',
 			'035' => 'De-Ddwyrain Asia',
 			'039' => 'De Ewrop',
 			'053' => 'Awstralasia',
 			'054' => 'Melanesia',
 			'057' => 'Rhanbarth Micronesia',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Canol Asia',
 			'145' => 'Gorllewin Asia',
 			'150' => 'Ewrop',
 			'151' => 'Dwyrain Ewrop',
 			'154' => 'Gogledd Ewrop',
 			'155' => 'Gorllewin Ewrop',
 			'202' => 'Affrica Is-Sahara',
 			'419' => 'America Ladin',
 			'AC' => 'Ynys Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Emiradau Arabaidd Unedig',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Yr Ariannin',
 			'AS' => 'Samoa America',
 			'AT' => 'Awstria',
 			'AU' => 'Awstralia',
 			'AW' => 'Aruba',
 			'AX' => 'Ynysoedd Åland',
 			'AZ' => 'Aserbaijan',
 			'BA' => 'Bosnia a Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Gwlad Belg',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bwlgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolifia',
 			'BQ' => 'Antilles yr Iseldiroedd',
 			'BR' => 'Brasil',
 			'BS' => 'Y Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Ynys Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarws',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Ynysoedd Cocos (Keeling)',
 			'CD' => 'Y Congo - Kinshasa',
 			'CD@alt=variant' => 'Y Congo (G.Dd.C.)',
 			'CF' => 'Gweriniaeth Canolbarth Affrica',
 			'CG' => 'Y Congo - Brazzaville',
 			'CG@alt=variant' => 'Y Congo (Gweriniaeth)',
 			'CH' => 'Y Swistir',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Arfordir Ifori',
 			'CK' => 'Ynysoedd Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerŵn',
 			'CN' => 'Tsieina',
 			'CO' => 'Colombia',
 			'CP' => 'Ynys Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Ciwba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Ynys y Nadolig',
 			'CY' => 'Cyprus',
 			'CZ' => 'Tsiecia',
 			'CZ@alt=variant' => 'Gweriniaeth Tsiec',
 			'DE' => 'Yr Almaen',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmarc',
 			'DM' => 'Dominica',
 			'DO' => 'Gweriniaeth Dominica',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Yr Aifft',
 			'EH' => 'Gorllewin Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Sbaen',
 			'ET' => 'Ethiopia',
 			'EU' => 'Yr Undeb Ewropeaidd',
 			'EZ' => 'Ardal yr Ewro',
 			'FI' => 'Y Ffindir',
 			'FJ' => 'Fiji',
 			'FK' => 'Ynysoedd y Falkland/Malvinas',
 			'FK@alt=variant' => 'Ynysoedd y Falkland (Ynysoedd y Malfinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Ynysoedd Ffaro',
 			'FR' => 'Ffrainc',
 			'GA' => 'Gabon',
 			'GB' => 'Y Deyrnas Unedig',
 			'GB@alt=short' => 'DU',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guyane Ffrengig',
 			'GG' => 'Ynys y Garn',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Yr Ynys Las',
 			'GM' => 'Gambia',
 			'GN' => 'Gini',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Gini Gyhydeddol',
 			'GR' => 'Gwlad Groeg',
 			'GS' => 'De Georgia ac Ynysoedd Sandwich y De',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guiné-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR Tsieina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ynys Heard ac Ynysoedd McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hwngari',
 			'IC' => 'Yr Ynysoedd Dedwydd',
 			'ID' => 'Indonesia',
 			'IE' => 'Iwerddon',
 			'IL' => 'Israel',
 			'IM' => 'Ynys Manaw',
 			'IN' => 'India',
 			'IO' => 'Tiriogaeth Brydeinig Cefnfor India',
 			'IO@alt=chagos' => 'Ynysfor Chagos',
 			'IQ' => 'Irac',
 			'IR' => 'Iran',
 			'IS' => 'Gwlad yr Iâ',
 			'IT' => 'Yr Eidal',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Gwlad Iorddonen',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Saint Kitts a Nevis',
 			'KP' => 'Gogledd Corea',
 			'KR' => 'De Corea',
 			'KW' => 'Kuwait',
 			'KY' => 'Ynysoedd Cayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanus',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithwania',
 			'LU' => 'Lwcsembwrg',
 			'LV' => 'Latfia',
 			'LY' => 'Libya',
 			'MA' => 'Moroco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldofa',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Ynysoedd Marshall',
 			'MK' => 'Gogledd Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau SAR Tsieina',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Ynysoedd Gogledd Mariana',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Y Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mecsico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Caledonia Newydd',
 			'NE' => 'Niger',
 			'NF' => 'Ynys Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Yr Iseldiroedd',
 			'NO' => 'Norwy',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Seland Newydd',
 			'NZ@alt=variant' => 'Aotearoa Seland Newydd',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Periw',
 			'PF' => 'Polynesia Ffrengig',
 			'PG' => 'Papua Guinea Newydd',
 			'PH' => 'Y Philipinau',
 			'PK' => 'Pakistan',
 			'PL' => 'Gwlad Pwyl',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PN' => 'Ynysoedd Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Tiriogaethau Palesteinaidd',
 			'PS@alt=short' => 'Palesteina',
 			'PT' => 'Portiwgal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceania Bellennig',
 			'RE' => 'Réunion',
 			'RO' => 'Rwmania',
 			'RS' => 'Serbia',
 			'RU' => 'Rwsia',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Ynysoedd Solomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Swdan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slofenia',
 			'SJ' => 'Svalbard a Jan Mayen',
 			'SK' => 'Slofacia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'De Swdan',
 			'ST' => 'São Tomé a Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Gwlad Swazi',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Ynysoedd Turks a Caicos',
 			'TD' => 'Tsiad',
 			'TF' => 'Tiroedd Deheuol ac Antarctig Ffrainc',
 			'TG' => 'Togo',
 			'TH' => 'Gwlad Thai',
 			'TJ' => 'Tajicistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Dwyrain Timor',
 			'TM' => 'Tyrcmenistan',
 			'TN' => 'Tiwnisia',
 			'TO' => 'Tonga',
 			'TR' => 'Twrci',
 			'TR@alt=variant' => 'Türkiye',
 			'TT' => 'Trinidad a Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Wcráin',
 			'UG' => 'Uganda',
 			'UM' => 'Ynysoedd Pellennig UDA',
 			'UN' => 'Y Cenhedloedd Unedig',
 			'UN@alt=short' => 'CU',
 			'US' => 'Yr Unol Daleithiau',
 			'US@alt=short' => 'UDA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Y Fatican',
 			'VC' => 'Saint Vincent a’r Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Ynysoedd Gwyryf Prydain',
 			'VI' => 'Ynysoedd Gwyryf yr Unol Daleithiau',
 			'VN' => 'Fietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Acenion Ffug',
 			'XB' => 'Bidi Ffug',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'De Affrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Rhanbarth Anhysbys',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'orgraff draddodiadol yr Almaeneg',
 			'1606NICT' => 'Ffrangeg Canol Diweddar hyd at 1606',
 			'1694ACAD' => 'Ffrangeg Modern Cynnar',
 			'1959ACAD' => 'Academig',
 			'ALUKU' => 'tafodiaith Aluku',
 			'AREVELA' => 'Armeneg Dwyreiniol',
 			'AREVMDA' => 'Armeneg Gorllewinol',
 			'BOHORIC' => 'Gwyddor Bohorič',
 			'DAJNKO' => 'gwyddor Dajnko',
 			'EMODENG' => 'Saesneg Modern Cynnar',
 			'FONIPA' => 'Seineg IPA',
 			'FONUPA' => 'Seineg UPA',
 			'KKCOR' => 'yr Orgraff Gyffredin',
 			'KSCOR' => 'yr Orgraff Safonol',
 			'METELKO' => 'gwyddor Metelko',
 			'NDYUKA' => 'tafodiaith Ndyuka',
 			'NEDIS' => 'tafodiaith Natisone',
 			'NJIVA' => 'tafodiaith Gniva/Njiva',
 			'OSOJS' => 'tafodiaith Oseacco/Osojane',
 			'PAMAKA' => 'tafodiaith Pamaka',
 			'POSIX' => 'Cyfrifiadur',
 			'SCOTLAND' => 'Saesneg Safonol yr Alban',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Calendr',
 			'cf' => 'Fformat Arian',
 			'collation' => 'Trefn',
 			'currency' => 'Math o Arian',
 			'hc' => 'Cylched Awr (12 vs 24)',
 			'lb' => 'Arddull Toriad Llinell',
 			'ms' => 'System Fesur',
 			'numbers' => 'Rhifau',

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
 				'buddhist' => q{Calendr Bwdaidd},
 				'chinese' => q{Calendr Tseina},
 				'coptic' => q{Calendr y Coptiaid},
 				'dangi' => q{Calendr Dangi},
 				'ethiopic' => q{Calendr Ethiopia},
 				'ethiopic-amete-alem' => q{Calendr Amete Alem Ethiopia},
 				'gregorian' => q{Calendr Gregori},
 				'hebrew' => q{Calendr Hebreaidd},
 				'indian' => q{Calendr Cenedlaethol India},
 				'islamic' => q{Calendr Hijri},
 				'islamic-civil' => q{Calendr Hijri (tabl, cyfnod sifil)},
 				'islamic-umalqura' => q{Calendr Hijri (Umm al-Qura)},
 				'iso8601' => q{Calendr ISO-8601},
 				'japanese' => q{Calendr Japan},
 				'persian' => q{Calendr Persia},
 				'roc' => q{Calendr Gweriniaeth Tseina},
 			},
 			'cf' => {
 				'account' => q{Fformat Arian Cyfrifeg},
 				'standard' => q{Fformat Arian Safonol},
 			},
 			'collation' => {
 				'big5han' => q{Trefn Traddodiadol Tsieina - Big5},
 				'dictionary' => q{Trefn Geiriadur},
 				'ducet' => q{Trefn Rhagosodedig Unicode},
 				'eor' => q{Rheolau trefnu Ewropeaidd},
 				'gb2312han' => q{Trefn Symledig Tsieina - GB2312},
 				'phonebook' => q{Trefn Llyfr Ffôn},
 				'pinyin' => q{Trefn Pinyin},
 				'reformed' => q{Trefn Diwygiedig},
 				'search' => q{Chwilio at Ddibenion Cyffredinol},
 				'standard' => q{Trefn Safonol},
 				'traditional' => q{Trefn Traddodiadol},
 				'zhuyin' => q{Trefn Zhuyin},
 			},
 			'hc' => {
 				'h11' => q{System 12 Awr (0–11)},
 				'h12' => q{System 12 Awr (1–12)},
 				'h23' => q{System 24 Awr (0–23)},
 				'h24' => q{System 24 Awr (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Arddull Toriad Llinell Rhydd},
 				'normal' => q{Arddull Toriad Llinell Arferol},
 				'strict' => q{Arddull Torriad Llinell Caeth},
 			},
 			'ms' => {
 				'metric' => q{System Fetrig},
 				'uksystem' => q{System Fesur Imperialaidd},
 				'ussystem' => q{System Fesur UDA},
 			},
 			'numbers' => {
 				'arab' => q{Digidau Arabig-Indig},
 				'arabext' => q{Digidau Arabig-Indig Estynedig},
 				'armn' => q{Rhifolion Armenaidd},
 				'armnlow' => q{Rhifolion Armenaidd mewn Llythrennau Bychain},
 				'beng' => q{Digidau Bengalaidd},
 				'cakm' => q{Digidau Chakma},
 				'deva' => q{Digidau Devanagarig},
 				'ethi' => q{Rhifolion Ethiopig},
 				'fullwide' => q{Digidau Lled Llawn},
 				'geor' => q{Rhifolion Georgaidd},
 				'grek' => q{Rhifolion Groegaidd},
 				'greklow' => q{Rhifolion Groegaidd mewn Llythrennau Bychain},
 				'gujr' => q{Digidau Gwjarataidd},
 				'guru' => q{Digidau Gwrmwcaidd},
 				'hanidec' => q{Rhifolion Degol Tsieineaidd},
 				'hans' => q{Rhifolion Tsieineaidd Symledig},
 				'hansfin' => q{Rhifolion Ariannol Tsieineaidd Symledig},
 				'hant' => q{Rhifolion Tsieineaidd Traddodiadol},
 				'hantfin' => q{Rhifolion Ariannol Tsieineaidd Traddodiadol},
 				'hebr' => q{Rhifolion Hebreig},
 				'java' => q{Digidau Jafanaidd},
 				'jpan' => q{Rhifolion Japaneaidd},
 				'jpanfin' => q{Rhifolion Ariannol Japaneaidd},
 				'khmr' => q{Digidau Chmeraidd},
 				'knda' => q{Digidau Kannaraidd},
 				'laoo' => q{Digidau Laoaidd},
 				'latn' => q{Digidau Gorllewinol},
 				'mlym' => q{Digidau Malayalamaidd},
 				'mong' => q{Digidau Mongolia},
 				'mtei' => q{Digidau Meetei Mayek},
 				'mymr' => q{Digidau Myanmar},
 				'olck' => q{Ol Chiki Digidau},
 				'orya' => q{Digidau Orïaidd},
 				'roman' => q{Rhifolion Rhufeinig},
 				'romanlow' => q{Rhifolion Rhufeinig mewn Llythrennau Bychain},
 				'takr' => q{Digidau Takri},
 				'taml' => q{Rhifolion Tamilaidd Traddodiadol},
 				'tamldec' => q{Digidau Tamilaidd},
 				'telu' => q{Digidau Telugu},
 				'thai' => q{Digidau Thai},
 				'tibt' => q{Digidau Tibetaidd},
 				'vaii' => q{Digidau Vai},
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
			'metric' => q{Metrig},
 			'UK' => q{DU},
 			'US' => q{UDA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Iaith: {0}',
 			'script' => 'Sgript: {0}',
 			'region' => 'Rhanbarth: {0}',

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
			auxiliary => qr{[ăåãā æ ç ĕē ĭī k ñ ŏøō œ q ŭū v x z]},
			index => ['A', 'B', 'C', '{CH}', 'D', '{DD}', 'E', 'F', '{FF}', 'G', '{NG}', 'H', 'I', 'J', 'K', 'L', '{LL}', 'M', 'N', 'O', 'P', '{PH}', 'Q', 'R', '{RH}', 'S', 'T', '{TH}', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aáàâä b c {ch} d {dd} eéèêë f {ff} g {ng} h iíìîï j l {ll} m n oóòôö p {ph} r {rh} s t {th} uúùûü wẃẁŵẅ yýỳŷÿ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', '{CH}', 'D', '{DD}', 'E', 'F', '{FF}', 'G', '{NG}', 'H', 'I', 'J', 'K', 'L', '{LL}', 'M', 'N', 'O', 'P', '{PH}', 'Q', 'R', '{RH}', 'S', 'T', '{TH}', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(cyfeiriad cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(cyfeiriad cardinal),
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
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ffemto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ffemto{0}),
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
						'1' => q(cilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(cilo{0}),
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
						'few' => q({0} G),
						'many' => q({0} G),
						'one' => q({0} grym disgyrchedd),
						'other' => q({0} grym disgyrchedd),
						'two' => q({0} G),
						'zero' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} G),
						'many' => q({0} G),
						'one' => q({0} grym disgyrchedd),
						'other' => q({0} grym disgyrchedd),
						'two' => q({0} G),
						'zero' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} m/eil²),
						'many' => q({0} m/eil²),
						'name' => q(metrau yr eiliad sgwâr),
						'one' => q({0} metr yr eiliad sgwâr),
						'other' => q({0} metr yr eiliad sgwâr),
						'two' => q({0} m/eil²),
						'zero' => q({0} m/eil²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} m/eil²),
						'many' => q({0} m/eil²),
						'name' => q(metrau yr eiliad sgwâr),
						'one' => q({0} metr yr eiliad sgwâr),
						'other' => q({0} metr yr eiliad sgwâr),
						'two' => q({0} m/eil²),
						'zero' => q({0} m/eil²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} archfunud),
						'many' => q({0} archfunud),
						'one' => q({0} archfunud),
						'other' => q({0} archfunud),
						'two' => q({0} archfunud),
						'zero' => q({0} archfunud),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} archfunud),
						'many' => q({0} archfunud),
						'one' => q({0} archfunud),
						'other' => q({0} archfunud),
						'two' => q({0} archfunud),
						'zero' => q({0} archfunud),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} gradd),
						'many' => q({0} gradd),
						'name' => q(graddau),
						'one' => q({0} radd),
						'other' => q({0} gradd),
						'two' => q({0} radd),
						'zero' => q({0} gradd),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} gradd),
						'many' => q({0} gradd),
						'name' => q(graddau),
						'one' => q({0} radd),
						'other' => q({0} gradd),
						'two' => q({0} radd),
						'zero' => q({0} gradd),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} radian),
						'many' => q({0} rad),
						'one' => q({0} radian),
						'other' => q({0} radian),
						'two' => q({0} radian),
						'zero' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} radian),
						'many' => q({0} rad),
						'one' => q({0} radian),
						'other' => q({0} radian),
						'two' => q({0} radian),
						'zero' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} cylchdro),
						'many' => q({0} cylchdro),
						'name' => q(cylchdroeon),
						'one' => q({0} cylchdro),
						'other' => q({0} cylchdro),
						'two' => q({0} gylchdro),
						'zero' => q({0} cylchdro),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} cylchdro),
						'many' => q({0} cylchdro),
						'name' => q(cylchdroeon),
						'one' => q({0} cylchdro),
						'other' => q({0} cylchdro),
						'two' => q({0} gylchdro),
						'zero' => q({0} cylchdro),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} ha),
						'many' => q({0} ha),
						'one' => q({0} hectar),
						'other' => q({0} hectar),
						'two' => q({0} ha),
						'zero' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} ha),
						'many' => q({0} ha),
						'one' => q({0} hectar),
						'other' => q({0} hectar),
						'two' => q({0} ha),
						'zero' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} cm²),
						'many' => q({0} cm²),
						'name' => q(centimetrau sgwâr),
						'one' => q({0} centimetr sgwâr),
						'other' => q({0} centimetr sgwâr),
						'per' => q({0} y centimetr sgwâr),
						'two' => q({0} cm²),
						'zero' => q({0} cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} cm²),
						'many' => q({0} cm²),
						'name' => q(centimetrau sgwâr),
						'one' => q({0} centimetr sgwâr),
						'other' => q({0} centimetr sgwâr),
						'per' => q({0} y centimetr sgwâr),
						'two' => q({0} cm²),
						'zero' => q({0} cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} troedfedd sgwâr),
						'many' => q({0} throedfedd sgwâr),
						'name' => q(troedfeddi sgwâr),
						'one' => q({0} droedfedd sgwâr),
						'other' => q({0} troedfedd sgwâr),
						'two' => q({0} droedfedd sgwâr),
						'zero' => q({0} troedfedd sgwâr),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} troedfedd sgwâr),
						'many' => q({0} throedfedd sgwâr),
						'name' => q(troedfeddi sgwâr),
						'one' => q({0} droedfedd sgwâr),
						'other' => q({0} troedfedd sgwâr),
						'two' => q({0} droedfedd sgwâr),
						'zero' => q({0} troedfedd sgwâr),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} modfedd sgwâr),
						'many' => q({0} modfedd sgwâr),
						'name' => q(modfeddi sgwâr),
						'one' => q({0} modfedd sgwâr),
						'other' => q({0} modfedd sgwâr),
						'per' => q({0} y modfedd sgwâr),
						'two' => q({0} fodfedd sgwâr),
						'zero' => q({0} modfedd sgwâr),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} modfedd sgwâr),
						'many' => q({0} modfedd sgwâr),
						'name' => q(modfeddi sgwâr),
						'one' => q({0} modfedd sgwâr),
						'other' => q({0} modfedd sgwâr),
						'per' => q({0} y modfedd sgwâr),
						'two' => q({0} fodfedd sgwâr),
						'zero' => q({0} modfedd sgwâr),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} km²),
						'many' => q({0} km²),
						'name' => q(cilometrau sgwâr),
						'one' => q({0} km²),
						'other' => q({0} cilometr sgwâr),
						'per' => q({0} y cilometr sgwâr),
						'two' => q({0} km²),
						'zero' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} km²),
						'many' => q({0} km²),
						'name' => q(cilometrau sgwâr),
						'one' => q({0} km²),
						'other' => q({0} cilometr sgwâr),
						'per' => q({0} y cilometr sgwâr),
						'two' => q({0} km²),
						'zero' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} m²),
						'many' => q({0} m²),
						'name' => q(metrau sgwâr),
						'one' => q({0} metr sgwâr),
						'other' => q({0} metr sgwâr),
						'per' => q({0} y metr sgwâr),
						'two' => q({0} m²),
						'zero' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} m²),
						'many' => q({0} m²),
						'name' => q(metrau sgwâr),
						'one' => q({0} metr sgwâr),
						'other' => q({0} metr sgwâr),
						'per' => q({0} y metr sgwâr),
						'two' => q({0} m²),
						'zero' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} milltir sgwâr),
						'many' => q({0} milltir sgwâr),
						'name' => q(milltiroedd sgwâr),
						'one' => q({0} filltir sgwâr),
						'other' => q({0} milltir sgwâr),
						'two' => q({0} filltir sgwâr),
						'zero' => q({0} milltir sgwâr),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} milltir sgwâr),
						'many' => q({0} milltir sgwâr),
						'name' => q(milltiroedd sgwâr),
						'one' => q({0} filltir sgwâr),
						'other' => q({0} milltir sgwâr),
						'two' => q({0} filltir sgwâr),
						'zero' => q({0} milltir sgwâr),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} llath sgwâr),
						'many' => q({0} llath sgwâr),
						'name' => q(llathenni sgwâr),
						'one' => q({0} llath sgwâr),
						'other' => q({0} llath sgwâr),
						'two' => q({0} lath sgwâr),
						'zero' => q({0} llath sgwâr),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} llath sgwâr),
						'many' => q({0} llath sgwâr),
						'name' => q(llathenni sgwâr),
						'one' => q({0} llath sgwâr),
						'other' => q({0} llath sgwâr),
						'two' => q({0} lath sgwâr),
						'zero' => q({0} llath sgwâr),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'one' => q({0} karat),
						'other' => q({0} karat),
						'two' => q({0} kt),
						'zero' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'one' => q({0} karat),
						'other' => q({0} karat),
						'two' => q({0} kt),
						'zero' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dL),
						'many' => q({0} mg/dL),
						'name' => q(miligramau y declilitr),
						'one' => q({0} miligram y decilitr),
						'other' => q({0} miligram y decilitr),
						'two' => q({0} mg/dL),
						'zero' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dL),
						'many' => q({0} mg/dL),
						'name' => q(miligramau y declilitr),
						'one' => q({0} miligram y decilitr),
						'other' => q({0} miligram y decilitr),
						'two' => q({0} mg/dL),
						'zero' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/L),
						'many' => q({0} mmol/L),
						'name' => q(milimolau y litr),
						'one' => q({0} milimôl y litr),
						'other' => q({0} milimôl y litr),
						'two' => q({0} mmol/L),
						'zero' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/L),
						'many' => q({0} mmol/L),
						'name' => q(milimolau y litr),
						'one' => q({0} milimôl y litr),
						'other' => q({0} milimôl y litr),
						'two' => q({0} mmol/L),
						'zero' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(molau),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(molau),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'one' => q({0} y cant),
						'other' => q({0} y cant),
						'two' => q({0}%),
						'zero' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'one' => q({0} y cant),
						'other' => q({0} y cant),
						'two' => q({0}%),
						'zero' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'one' => q({0} permille),
						'other' => q({0} permille),
						'two' => q({0}‰),
						'zero' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'one' => q({0} permille),
						'other' => q({0} permille),
						'two' => q({0}‰),
						'zero' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} rhan pob miliwn),
						'many' => q({0} rhan pob miliwn),
						'name' => q(rhannau pob miliwn),
						'one' => q({0} rhan pob miliwn),
						'other' => q({0} rhan pob miliwn),
						'two' => q({0} ran pob miliwn),
						'zero' => q({0} rhan pob miliwn),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} rhan pob miliwn),
						'many' => q({0} rhan pob miliwn),
						'name' => q(rhannau pob miliwn),
						'one' => q({0} rhan pob miliwn),
						'other' => q({0} rhan pob miliwn),
						'two' => q({0} ran pob miliwn),
						'zero' => q({0} rhan pob miliwn),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0}‱),
						'many' => q({0}‱),
						'one' => q({0} permyriad),
						'other' => q({0} permyriad),
						'two' => q({0}‱),
						'zero' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0}‱),
						'many' => q({0}‱),
						'one' => q({0} permyriad),
						'other' => q({0} permyriad),
						'two' => q({0}‱),
						'zero' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} L/100km),
						'many' => q({0} L/100km),
						'name' => q(litrau y 100 cilometr),
						'one' => q({0} litr y 100 cilometr),
						'other' => q({0} litr y 100 cilometr),
						'two' => q({0} L/100km),
						'zero' => q({0} L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} L/100km),
						'many' => q({0} L/100km),
						'name' => q(litrau y 100 cilometr),
						'one' => q({0} litr y 100 cilometr),
						'other' => q({0} litr y 100 cilometr),
						'two' => q({0} L/100km),
						'zero' => q({0} L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} L/km),
						'many' => q({0} L/km),
						'name' => q(litrau y cilometr),
						'one' => q({0} litr y cilometr),
						'other' => q({0} litr y cilometr),
						'two' => q({0} L/km),
						'zero' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} L/km),
						'many' => q({0} L/km),
						'name' => q(litrau y cilometr),
						'one' => q({0} litr y cilometr),
						'other' => q({0} litr y cilometr),
						'two' => q({0} L/km),
						'zero' => q({0} L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(milltiroedd y galwyn),
						'one' => q({0} filltir y galwyn),
						'other' => q({0} milltir y galwyn),
						'two' => q({0} mpg),
						'zero' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(milltiroedd y galwyn),
						'one' => q({0} filltir y galwyn),
						'other' => q({0} milltir y galwyn),
						'two' => q({0} mpg),
						'zero' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp.),
						'many' => q({0} mpg Imp.),
						'name' => q(milltiroedd y galwyn Imp.),
						'one' => q({0} milltir y galwyn Imp.),
						'other' => q({0} milltir y galwyn Imp.),
						'two' => q({0} mpg Imp.),
						'zero' => q({0} mpg Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp.),
						'many' => q({0} mpg Imp.),
						'name' => q(milltiroedd y galwyn Imp.),
						'one' => q({0} milltir y galwyn Imp.),
						'other' => q({0} milltir y galwyn Imp.),
						'two' => q({0} mpg Imp.),
						'zero' => q({0} mpg Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} i’r dwyrain),
						'north' => q({0} i’r gogledd),
						'south' => q({0} i’r de),
						'west' => q({0} i’r gorllewin),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} i’r dwyrain),
						'north' => q({0} i’r gogledd),
						'south' => q({0} i’r de),
						'west' => q({0} i’r gorllewin),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(didau),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(didau),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(beitiau),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(beitiau),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} Gb),
						'many' => q({0} Gb),
						'name' => q(gigadidau),
						'one' => q({0} gigadid),
						'other' => q({0} gigadid),
						'two' => q({0} Gb),
						'zero' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} Gb),
						'many' => q({0} Gb),
						'name' => q(gigadidau),
						'one' => q({0} gigadid),
						'other' => q({0} gigadid),
						'two' => q({0} Gb),
						'zero' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} GB),
						'many' => q({0} GB),
						'name' => q(gigabeitiau),
						'one' => q({0} gigabeit),
						'other' => q({0} gigabeit),
						'two' => q({0} GB),
						'zero' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} GB),
						'many' => q({0} GB),
						'name' => q(gigabeitiau),
						'one' => q({0} gigabeit),
						'other' => q({0} gigabeit),
						'two' => q({0} GB),
						'zero' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(cilodidau),
						'one' => q({0} cilodid),
						'other' => q({0} cilodid),
						'two' => q({0} kb),
						'zero' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(cilodidau),
						'one' => q({0} cilodid),
						'other' => q({0} cilodid),
						'two' => q({0} kb),
						'zero' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'name' => q(cilobeitiau),
						'one' => q({0} cilobeit),
						'other' => q({0} cilobeit),
						'two' => q({0} kB),
						'zero' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'name' => q(cilobeitiau),
						'one' => q({0} cilobeit),
						'other' => q({0} cilobeit),
						'two' => q({0} kB),
						'zero' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'name' => q(megadidau),
						'one' => q({0} megadid),
						'other' => q({0} megadid),
						'two' => q({0} Mb),
						'zero' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'name' => q(megadidau),
						'one' => q({0} megadid),
						'other' => q({0} megadid),
						'two' => q({0} Mb),
						'zero' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(megabeitiau),
						'one' => q({0} megabeit),
						'other' => q({0} megabeit),
						'two' => q({0} MB),
						'zero' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(megabeitiau),
						'one' => q({0} megabeit),
						'other' => q({0} megabeit),
						'two' => q({0} MB),
						'zero' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} PB),
						'many' => q({0} PB),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
						'two' => q({0} PB),
						'zero' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} PB),
						'many' => q({0} PB),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
						'two' => q({0} PB),
						'zero' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(teradidau),
						'one' => q({0} teradid),
						'other' => q({0} teradid),
						'two' => q({0} Tb),
						'zero' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(teradidau),
						'one' => q({0} teradid),
						'other' => q({0} teradid),
						'two' => q({0} Tb),
						'zero' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(terabeitiau),
						'one' => q({0} terabeit),
						'other' => q({0} terabeit),
						'two' => q({0} TB),
						'zero' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(terabeitiau),
						'one' => q({0} terabeit),
						'other' => q({0} terabeit),
						'two' => q({0} TB),
						'zero' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} canrif),
						'many' => q({0} canrif),
						'name' => q(canrifoedd),
						'one' => q({0} canrif),
						'other' => q({0} canrif),
						'two' => q({0} ganrif),
						'zero' => q({0} canrif),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} canrif),
						'many' => q({0} canrif),
						'name' => q(canrifoedd),
						'one' => q({0} canrif),
						'other' => q({0} canrif),
						'two' => q({0} ganrif),
						'zero' => q({0} canrif),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} y diwrnod),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} y diwrnod),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} degawd),
						'many' => q({0} degawd),
						'name' => q(degawdau),
						'one' => q({0} degawd),
						'other' => q({0} degawd),
						'two' => q({0} degawd),
						'zero' => q({0} degawd),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} degawd),
						'many' => q({0} degawd),
						'name' => q(degawdau),
						'one' => q({0} degawd),
						'other' => q({0} degawd),
						'two' => q({0} degawd),
						'zero' => q({0} degawd),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} yr awr),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} yr awr),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} microeiliadau),
						'many' => q({0} microeiliadau),
						'name' => q(microeiliadau),
						'one' => q({0} microeiliadau),
						'other' => q({0} microeiliadau),
						'two' => q({0} microeiliadau),
						'zero' => q({0} microeiliadau),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} microeiliadau),
						'many' => q({0} microeiliadau),
						'name' => q(microeiliadau),
						'one' => q({0} microeiliadau),
						'other' => q({0} microeiliadau),
						'two' => q({0} microeiliadau),
						'zero' => q({0} microeiliadau),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} milieiliad),
						'many' => q({0} milieiliad),
						'one' => q({0} milieiliad),
						'other' => q({0} milieiliad),
						'two' => q({0} filieiliad),
						'zero' => q({0} milieiliad),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} milieiliad),
						'many' => q({0} milieiliad),
						'one' => q({0} milieiliad),
						'other' => q({0} milieiliad),
						'two' => q({0} filieiliad),
						'zero' => q({0} milieiliad),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} munud),
						'many' => q({0} munud),
						'name' => q(munudau),
						'one' => q({0} munud),
						'other' => q({0} munud),
						'per' => q({0} y munud),
						'two' => q({0} funud),
						'zero' => q({0} munud),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} munud),
						'many' => q({0} munud),
						'name' => q(munudau),
						'one' => q({0} munud),
						'other' => q({0} munud),
						'per' => q({0} y munud),
						'two' => q({0} funud),
						'zero' => q({0} munud),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} y mis),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} y mis),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nanoeiliadau),
						'many' => q({0} nanoeiliadau),
						'name' => q(nanoeiliadau),
						'one' => q({0} nanoeiliadau),
						'other' => q({0} nanoeiliadau),
						'two' => q({0} nanoeiliadau),
						'zero' => q({0} nanoeiliadau),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nanoeiliadau),
						'many' => q({0} nanoeiliadau),
						'name' => q(nanoeiliadau),
						'one' => q({0} nanoeiliadau),
						'other' => q({0} nanoeiliadau),
						'two' => q({0} nanoeiliadau),
						'zero' => q({0} nanoeiliadau),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} chw),
						'many' => q({0} chw),
						'name' => q(chwarteri),
						'one' => q({0} chwateri),
						'other' => q({0} chwater),
						'two' => q({0} chw),
						'zero' => q({0} chw),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} chw),
						'many' => q({0} chw),
						'name' => q(chwarteri),
						'one' => q({0} chwateri),
						'other' => q({0} chwater),
						'two' => q({0} chw),
						'zero' => q({0} chw),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} eiliad),
						'many' => q({0} eiliad),
						'one' => q({0} eiliad),
						'other' => q({0} eiliad),
						'per' => q({0} yr eiliad),
						'two' => q({0} eiliad),
						'zero' => q({0} eiliad),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} eiliad),
						'many' => q({0} eiliad),
						'one' => q({0} eiliad),
						'other' => q({0} eiliad),
						'per' => q({0} yr eiliad),
						'two' => q({0} eiliad),
						'zero' => q({0} eiliad),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} wythnos),
						'many' => q({0} wythnos),
						'one' => q({0} wythnos),
						'other' => q({0} wythnos),
						'per' => q({0} yr wythnos),
						'two' => q({0} wythnos),
						'zero' => q({0} wythnos),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} wythnos),
						'many' => q({0} wythnos),
						'one' => q({0} wythnos),
						'other' => q({0} wythnos),
						'per' => q({0} yr wythnos),
						'two' => q({0} wythnos),
						'zero' => q({0} wythnos),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} blynedd),
						'many' => q({0} blynedd),
						'one' => q({0} flwyddyn),
						'other' => q({0} mlynedd),
						'per' => q({0} y flwyddyn),
						'two' => q({0} flynedd),
						'zero' => q({0} mlynedd),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} blynedd),
						'many' => q({0} blynedd),
						'one' => q({0} flwyddyn),
						'other' => q({0} mlynedd),
						'per' => q({0} y flwyddyn),
						'two' => q({0} flynedd),
						'zero' => q({0} mlynedd),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(amperau),
						'one' => q({0} amper),
						'other' => q({0} amper),
						'two' => q({0} A),
						'zero' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(amperau),
						'one' => q({0} amper),
						'other' => q({0} amper),
						'two' => q({0} A),
						'zero' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} mA),
						'many' => q({0} mA),
						'name' => q(miliamperau),
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
						'two' => q({0} mA),
						'zero' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} mA),
						'many' => q({0} mA),
						'name' => q(miliamperau),
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
						'two' => q({0} mA),
						'zero' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} Ω),
						'many' => q({0} Ω),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
						'two' => q({0} Ω),
						'zero' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} Ω),
						'many' => q({0} Ω),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
						'two' => q({0} Ω),
						'zero' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} V),
						'many' => q({0} V),
						'one' => q({0} folt),
						'other' => q({0} folt),
						'two' => q({0} V),
						'zero' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} V),
						'many' => q({0} V),
						'one' => q({0} folt),
						'other' => q({0} folt),
						'two' => q({0} V),
						'zero' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} Btu),
						'many' => q({0} Btu),
						'name' => q(unedau thermol Prydain),
						'one' => q({0} uned thermol Prydain),
						'other' => q({0} uned thermol Prydain),
						'two' => q({0} Btu),
						'zero' => q({0} Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} Btu),
						'many' => q({0} Btu),
						'name' => q(unedau thermol Prydain),
						'one' => q({0} uned thermol Prydain),
						'other' => q({0} uned thermol Prydain),
						'two' => q({0} Btu),
						'zero' => q({0} Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(calorïau),
						'one' => q({0} calori),
						'other' => q({0} calori),
						'two' => q({0} cal),
						'zero' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(calorïau),
						'one' => q({0} calori),
						'other' => q({0} calori),
						'two' => q({0} cal),
						'zero' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} eV),
						'many' => q({0} eV),
						'name' => q(electronfoltiau),
						'one' => q({0} electronfolt),
						'other' => q({0} electronfolt),
						'two' => q({0} eV),
						'zero' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} eV),
						'many' => q({0} eV),
						'name' => q(electronfoltiau),
						'one' => q({0} electronfolt),
						'other' => q({0} electronfolt),
						'two' => q({0} eV),
						'zero' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(Calorïau),
						'one' => q({0} Calori),
						'other' => q({0} Calori),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(Calorïau),
						'one' => q({0} Calori),
						'other' => q({0} Calori),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} J),
						'many' => q({0} J),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} J),
						'zero' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} J),
						'many' => q({0} J),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} J),
						'zero' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(cilocalorïau),
						'one' => q({0} cilocalori),
						'other' => q({0} cilocalori),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(cilocalorïau),
						'one' => q({0} cilocalori),
						'other' => q({0} cilocalori),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kJ),
						'many' => q({0} kJ),
						'one' => q({0} cilojoule),
						'other' => q({0} cilojoule),
						'two' => q({0} kJ),
						'zero' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kJ),
						'many' => q({0} kJ),
						'one' => q({0} cilojoule),
						'other' => q({0} cilojoule),
						'two' => q({0} kJ),
						'zero' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} kW-awr),
						'many' => q({0} kW-awr),
						'name' => q(cilowat oriau),
						'one' => q({0} cilowat awr),
						'other' => q({0} cilowat awr),
						'two' => q({0} kW-awr),
						'zero' => q({0} kW-awr),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} kW-awr),
						'many' => q({0} kW-awr),
						'name' => q(cilowat oriau),
						'one' => q({0} cilowat awr),
						'other' => q({0} cilowat awr),
						'two' => q({0} kW-awr),
						'zero' => q({0} kW-awr),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'many' => q({0} kWh/100km),
						'name' => q(cilowat-awr fesul 100 cilomedr),
						'one' => q({0} cilowat-awr fesul 100 cilomedr),
						'other' => q({0} cilowat-awr fesul 100 cilomedr),
						'two' => q({0} kWh/100km),
						'zero' => q({0} kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'many' => q({0} kWh/100km),
						'name' => q(cilowat-awr fesul 100 cilomedr),
						'one' => q({0} cilowat-awr fesul 100 cilomedr),
						'other' => q({0} cilowat-awr fesul 100 cilomedr),
						'two' => q({0} kWh/100km),
						'zero' => q({0} kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} N),
						'many' => q({0} N),
						'name' => q(newtonau),
						'one' => q({0} newton),
						'other' => q({0} newton),
						'two' => q({0} N),
						'zero' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} N),
						'many' => q({0} N),
						'name' => q(newtonau),
						'one' => q({0} newton),
						'other' => q({0} newton),
						'two' => q({0} N),
						'zero' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} lbf),
						'many' => q({0} lbf),
						'name' => q(pwysau o rym),
						'one' => q({0} pwys o rym),
						'other' => q({0} pwysau o rym),
						'two' => q({0} lbf),
						'zero' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} lbf),
						'many' => q({0} lbf),
						'name' => q(pwysau o rym),
						'one' => q({0} pwys o rym),
						'other' => q({0} pwysau o rym),
						'two' => q({0} lbf),
						'zero' => q({0} lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} GHz),
						'many' => q({0} GHz),
						'name' => q(gigaherts),
						'one' => q({0} gigaherts),
						'other' => q({0} gigaherts),
						'two' => q({0} GHz),
						'zero' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} GHz),
						'many' => q({0} GHz),
						'name' => q(gigaherts),
						'one' => q({0} gigaherts),
						'other' => q({0} gigaherts),
						'two' => q({0} GHz),
						'zero' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} Hz),
						'many' => q({0} Hz),
						'name' => q(herts),
						'one' => q({0} herts),
						'other' => q({0} herts),
						'two' => q({0} Hz),
						'zero' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} Hz),
						'many' => q({0} Hz),
						'name' => q(herts),
						'one' => q({0} herts),
						'other' => q({0} herts),
						'two' => q({0} Hz),
						'zero' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} kHz),
						'many' => q({0} kHz),
						'name' => q(ciloherts),
						'one' => q({0} ciloherts),
						'other' => q({0} ciloherts),
						'two' => q({0} kHz),
						'zero' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} kHz),
						'many' => q({0} kHz),
						'name' => q(ciloherts),
						'one' => q({0} ciloherts),
						'other' => q({0} ciloherts),
						'two' => q({0} kHz),
						'zero' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} MHz),
						'many' => q({0} MHz),
						'name' => q(megaherts),
						'one' => q({0} megaherts),
						'other' => q({0} megaherts),
						'two' => q({0} MHz),
						'zero' => q({0} megaherts),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} MHz),
						'many' => q({0} MHz),
						'name' => q(megaherts),
						'one' => q({0} megaherts),
						'other' => q({0} megaherts),
						'two' => q({0} MHz),
						'zero' => q({0} megaherts),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'many' => q({0} ppcm),
						'name' => q(dotiau mewn centimedr),
						'one' => q({0} dot mewn centimedr),
						'other' => q({0} dot mewn centimedr),
						'two' => q({0} ppcm),
						'zero' => q({0} ppcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'many' => q({0} ppcm),
						'name' => q(dotiau mewn centimedr),
						'one' => q({0} dot mewn centimedr),
						'other' => q({0} dot mewn centimedr),
						'two' => q({0} ppcm),
						'zero' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ppi),
						'many' => q({0} ppi),
						'name' => q(dotiau mewn modfedd),
						'one' => q({0} dot mewn modfedd),
						'other' => q({0} dot mewn modfedd),
						'two' => q({0} ppi),
						'zero' => q({0} ppi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ppi),
						'many' => q({0} ppi),
						'name' => q(dotiau mewn modfedd),
						'one' => q({0} dot mewn modfedd),
						'other' => q({0} dot mewn modfedd),
						'two' => q({0} ppi),
						'zero' => q({0} ppi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em argraffyddol),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em argraffyddol),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} MP),
						'many' => q({0} MP),
						'one' => q({0} megapicsel),
						'other' => q({0} megapicsel),
						'two' => q({0} MP),
						'zero' => q({0} MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} MP),
						'many' => q({0} MP),
						'one' => q({0} megapicsel),
						'other' => q({0} megapicsel),
						'two' => q({0} MP),
						'zero' => q({0} MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} px),
						'many' => q({0} px),
						'one' => q({0} picsel),
						'other' => q({0} picsel),
						'two' => q({0} px),
						'zero' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} px),
						'many' => q({0} px),
						'one' => q({0} picsel),
						'other' => q({0} picsel),
						'two' => q({0} px),
						'zero' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'many' => q({0} ppcm),
						'name' => q(picseli mewn centimedr),
						'one' => q({0} picsel mewn centimedr),
						'other' => q({0} picsel mewn centimedr),
						'two' => q({0} ppcm),
						'zero' => q({0} ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} ppcm),
						'many' => q({0} ppcm),
						'name' => q(picseli mewn centimedr),
						'one' => q({0} picsel mewn centimedr),
						'other' => q({0} picsel mewn centimedr),
						'two' => q({0} ppcm),
						'zero' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} ppi),
						'many' => q({0} ppi),
						'name' => q(picseli mewn modfedd),
						'one' => q({0} picsel mewn modfedd),
						'other' => q({0} picsel mewn modfedd),
						'two' => q({0} ppi),
						'zero' => q({0} ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} ppi),
						'many' => q({0} ppi),
						'name' => q(picseli mewn modfedd),
						'one' => q({0} picsel mewn modfedd),
						'other' => q({0} picsel mewn modfedd),
						'two' => q({0} ppi),
						'zero' => q({0} ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} uned seryddol),
						'many' => q({0} uned seryddol),
						'name' => q(unedau seryddol),
						'one' => q({0} uned seryddol),
						'other' => q({0} uned seryddol),
						'two' => q({0} uned seryddol),
						'zero' => q({0} uned seryddol),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} uned seryddol),
						'many' => q({0} uned seryddol),
						'name' => q(unedau seryddol),
						'one' => q({0} uned seryddol),
						'other' => q({0} uned seryddol),
						'two' => q({0} uned seryddol),
						'zero' => q({0} uned seryddol),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} cm),
						'many' => q({0} cm),
						'name' => q(centimetrau),
						'one' => q({0} centimetr),
						'other' => q({0} centimetr),
						'per' => q({0} y centimetr),
						'two' => q({0} cm),
						'zero' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} cm),
						'many' => q({0} cm),
						'name' => q(centimetrau),
						'one' => q({0} centimetr),
						'other' => q({0} centimetr),
						'per' => q({0} y centimetr),
						'two' => q({0} cm),
						'zero' => q({0} cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} dm),
						'many' => q({0} dm),
						'name' => q(decimetrau),
						'one' => q({0} decimetr),
						'other' => q({0} decimetr),
						'two' => q({0} dm),
						'zero' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} dm),
						'many' => q({0} dm),
						'name' => q(decimetrau),
						'one' => q({0} decimetr),
						'other' => q({0} decimetr),
						'two' => q({0} dm),
						'zero' => q({0} dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} R⊕),
						'many' => q({0} R⊕),
						'name' => q(radiws y Ddaear),
						'one' => q({0} radiws y Ddaear),
						'other' => q({0} radiws y Ddaear),
						'two' => q({0} R⊕),
						'zero' => q({0} R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} R⊕),
						'many' => q({0} R⊕),
						'name' => q(radiws y Ddaear),
						'one' => q({0} radiws y Ddaear),
						'other' => q({0} radiws y Ddaear),
						'two' => q({0} R⊕),
						'zero' => q({0} R⊕),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} troedfedd),
						'many' => q({0} throedfedd),
						'one' => q({0} droedfedd),
						'other' => q({0} troedfedd),
						'per' => q({0} y droedfedd),
						'two' => q({0} droedfedd),
						'zero' => q({0} troedfedd),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} troedfedd),
						'many' => q({0} throedfedd),
						'one' => q({0} droedfedd),
						'other' => q({0} troedfedd),
						'per' => q({0} y droedfedd),
						'two' => q({0} droedfedd),
						'zero' => q({0} troedfedd),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} ystaden),
						'many' => q({0} ystaden),
						'one' => q({0} ystaden),
						'other' => q({0} ystaden),
						'two' => q({0} ystaden),
						'zero' => q({0} ystaden),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} ystaden),
						'many' => q({0} ystaden),
						'one' => q({0} ystaden),
						'other' => q({0} ystaden),
						'two' => q({0} ystaden),
						'zero' => q({0} ystaden),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0} y fodfedd),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0} y fodfedd),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} km),
						'many' => q({0} km),
						'name' => q(cilometrau),
						'one' => q({0} cilometr),
						'other' => q({0} cilometr),
						'per' => q({0} y cilometr),
						'two' => q({0} km),
						'zero' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} km),
						'many' => q({0} km),
						'name' => q(cilometrau),
						'one' => q({0} cilometr),
						'other' => q({0} cilometr),
						'per' => q({0} y cilometr),
						'two' => q({0} km),
						'zero' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} blwyddyn golau),
						'many' => q({0} blwyddyn golau),
						'name' => q(blynyddoedd golau),
						'one' => q({0} flwyddyn golau),
						'other' => q({0} blwyddyn golau),
						'two' => q({0} flwyddyn golau),
						'zero' => q({0} blwyddyn golau),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} blwyddyn golau),
						'many' => q({0} blwyddyn golau),
						'name' => q(blynyddoedd golau),
						'one' => q({0} flwyddyn golau),
						'other' => q({0} blwyddyn golau),
						'two' => q({0} flwyddyn golau),
						'zero' => q({0} blwyddyn golau),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(metrau),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0} y metr),
						'two' => q({0} m),
						'zero' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(metrau),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0} y metr),
						'two' => q({0} m),
						'zero' => q({0} m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} μm),
						'many' => q({0} μm),
						'name' => q(micrometrau),
						'one' => q({0} micrometr),
						'other' => q({0} micrometr),
						'two' => q({0} μm),
						'zero' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} μm),
						'many' => q({0} μm),
						'name' => q(micrometrau),
						'one' => q({0} micrometr),
						'other' => q({0} micrometr),
						'two' => q({0} μm),
						'zero' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} milltir),
						'many' => q({0} milltir),
						'one' => q({0} filltir),
						'other' => q({0} milltir),
						'two' => q({0} filltir),
						'zero' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} milltir),
						'many' => q({0} milltir),
						'one' => q({0} filltir),
						'other' => q({0} milltir),
						'two' => q({0} filltir),
						'zero' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} milltir Sgandinafia),
						'many' => q({0} milltir Sgandinafia),
						'name' => q(milltiroedd Sgandinafia),
						'one' => q({0} filltir Sgandinafia),
						'other' => q({0} milltir Sgandinafia),
						'two' => q({0} filltir Sgandinafia),
						'zero' => q({0} milltir Sgandinafia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} milltir Sgandinafia),
						'many' => q({0} milltir Sgandinafia),
						'name' => q(milltiroedd Sgandinafia),
						'one' => q({0} filltir Sgandinafia),
						'other' => q({0} milltir Sgandinafia),
						'two' => q({0} filltir Sgandinafia),
						'zero' => q({0} milltir Sgandinafia),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} mm),
						'many' => q({0} mm),
						'name' => q(milimetrau),
						'one' => q({0} milimetr),
						'other' => q({0} milimetr),
						'two' => q({0} filimetr),
						'zero' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} mm),
						'many' => q({0} mm),
						'name' => q(milimetrau),
						'one' => q({0} milimetr),
						'other' => q({0} milimetr),
						'two' => q({0} filimetr),
						'zero' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nm),
						'many' => q({0} nm),
						'name' => q(nanometrau),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
						'two' => q({0} nm),
						'zero' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nm),
						'many' => q({0} nm),
						'name' => q(nanometrau),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
						'two' => q({0} nm),
						'zero' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} milltir fôr),
						'many' => q({0} milltir fôr),
						'name' => q(milltiroedd môr),
						'one' => q({0} filltir fôr),
						'other' => q({0} milltir fôr),
						'two' => q({0} filltir fôr),
						'zero' => q({0} milltir fôr),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} milltir fôr),
						'many' => q({0} milltir fôr),
						'name' => q(milltiroedd môr),
						'one' => q({0} filltir fôr),
						'other' => q({0} milltir fôr),
						'two' => q({0} filltir fôr),
						'zero' => q({0} milltir fôr),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} pc),
						'many' => q({0} pc),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} pc),
						'zero' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} pc),
						'many' => q({0} pc),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} pc),
						'zero' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} pm),
						'many' => q({0} pm),
						'name' => q(picometrau),
						'one' => q({0} picometr),
						'other' => q({0} picometr),
						'two' => q({0} pm),
						'zero' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} pm),
						'many' => q({0} pm),
						'name' => q(picometrau),
						'one' => q({0} picometr),
						'other' => q({0} picometr),
						'two' => q({0} pm),
						'zero' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pwyntiau),
						'one' => q({0} pwynt),
						'other' => q({0} pwynt),
						'two' => q({0} bwynt),
						'zero' => q({0} pwynt),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pwyntiau),
						'one' => q({0} pwynt),
						'other' => q({0} pwynt),
						'two' => q({0} bwynt),
						'zero' => q({0} pwynt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} R☉),
						'many' => q({0} R☉),
						'one' => q({0} radiws solar),
						'other' => q({0} radiws solar),
						'two' => q({0} R☉),
						'zero' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} R☉),
						'many' => q({0} R☉),
						'one' => q({0} radiws solar),
						'other' => q({0} radiws solar),
						'two' => q({0} R☉),
						'zero' => q({0} R☉),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lwmen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lwmen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'one' => q({0} lwcs),
						'other' => q({0} lwcs),
						'two' => q({0} lx),
						'zero' => q({0} lwcs),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'one' => q({0} lwcs),
						'other' => q({0} lwcs),
						'two' => q({0} lx),
						'zero' => q({0} lwcs),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} L☉),
						'many' => q({0} L☉),
						'one' => q({0} goleuedd solar),
						'other' => q({0} goleueddau solar),
						'two' => q({0} L☉),
						'zero' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} L☉),
						'many' => q({0} L☉),
						'one' => q({0} goleuedd solar),
						'other' => q({0} goleueddau solar),
						'two' => q({0} L☉),
						'zero' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} CD),
						'many' => q({0} CD),
						'one' => q({0} carat),
						'other' => q({0} carat),
						'two' => q({0} CD),
						'zero' => q({0} carat),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} CD),
						'many' => q({0} CD),
						'one' => q({0} carat),
						'other' => q({0} carat),
						'two' => q({0} CD),
						'zero' => q({0} carat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} Da),
						'many' => q({0} Da),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
						'two' => q({0} Da),
						'zero' => q({0} Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} Da),
						'many' => q({0} Da),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
						'two' => q({0} Da),
						'zero' => q({0} Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} M⊕),
						'many' => q({0} M⊕),
						'one' => q({0} más ddaear),
						'other' => q({0} más ddaear),
						'two' => q({0} M⊕),
						'zero' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} M⊕),
						'many' => q({0} M⊕),
						'one' => q({0} más ddaear),
						'other' => q({0} más ddaear),
						'two' => q({0} M⊕),
						'zero' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} y gram),
						'two' => q({0} g),
						'zero' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} y gram),
						'two' => q({0} g),
						'zero' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'name' => q(cilogramau),
						'one' => q({0} cilogram),
						'other' => q({0} cilogram),
						'per' => q({0} y cilogram),
						'two' => q({0} kg),
						'zero' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'name' => q(cilogramau),
						'one' => q({0} cilogram),
						'other' => q({0} cilogram),
						'per' => q({0} y cilogram),
						'two' => q({0} kg),
						'zero' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} μg),
						'many' => q({0} μg),
						'name' => q(microgramau),
						'one' => q({0} microgram),
						'other' => q({0} microgram),
						'two' => q({0} μg),
						'zero' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} μg),
						'many' => q({0} μg),
						'name' => q(microgramau),
						'one' => q({0} microgram),
						'other' => q({0} microgram),
						'two' => q({0} μg),
						'zero' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} mg),
						'many' => q({0} mg),
						'name' => q(miligramau),
						'one' => q({0} miligram),
						'other' => q({0} miligram),
						'two' => q({0} filigram),
						'zero' => q({0} miligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} mg),
						'many' => q({0} mg),
						'name' => q(miligramau),
						'one' => q({0} miligram),
						'other' => q({0} miligram),
						'two' => q({0} filigram),
						'zero' => q({0} miligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ownsys),
						'per' => q({0} yr owns),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ownsys),
						'per' => q({0} yr owns),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} owns pwysau aur),
						'many' => q({0} owns pwysau aur),
						'name' => q(ownsiau pwysau aur),
						'one' => q({0} owns pwysau aur),
						'other' => q({0} owns pwysau aur),
						'two' => q({0} owns pwysau aur),
						'zero' => q({0} owns pwysau aur),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} owns pwysau aur),
						'many' => q({0} owns pwysau aur),
						'name' => q(ownsiau pwysau aur),
						'one' => q({0} owns pwysau aur),
						'other' => q({0} owns pwysau aur),
						'two' => q({0} owns pwysau aur),
						'zero' => q({0} owns pwysau aur),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} y pwys),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} y pwys),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} M☉),
						'many' => q({0} M☉),
						'one' => q({0} más solar),
						'other' => q({0} más solar),
						'two' => q({0} M☉),
						'zero' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} M☉),
						'many' => q({0} M☉),
						'one' => q({0} más solar),
						'other' => q({0} más solar),
						'two' => q({0} M☉),
						'zero' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} stôn),
						'many' => q({0} stôn),
						'one' => q({0} stôn),
						'other' => q({0} stôn),
						'two' => q({0} stôn),
						'zero' => q({0} stôn),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} stôn),
						'many' => q({0} stôn),
						'one' => q({0} stôn),
						'other' => q({0} stôn),
						'two' => q({0} stôn),
						'zero' => q({0} stôn),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} tunnell),
						'many' => q({0} tunnell),
						'name' => q(tunelli),
						'one' => q({0} dunnell),
						'other' => q({0} tunnell),
						'two' => q({0} dunnell),
						'zero' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} tunnell),
						'many' => q({0} tunnell),
						'name' => q(tunelli),
						'one' => q({0} dunnell),
						'other' => q({0} tunnell),
						'two' => q({0} dunnell),
						'zero' => q({0} tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'name' => q(tunelli metrig),
						'one' => q({0} dunnell fetrig),
						'other' => q({0} tunnell fetrig),
						'two' => q({0} t),
						'zero' => q({0} t),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'name' => q(tunelli metrig),
						'one' => q({0} dunnell fetrig),
						'other' => q({0} tunnell fetrig),
						'two' => q({0} t),
						'zero' => q({0} t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} gigawat),
						'many' => q({0} gigawat),
						'name' => q(gigawatiau),
						'one' => q({0} gigawat),
						'other' => q({0} gigawat),
						'two' => q({0} gigawat),
						'zero' => q({0} gigawat),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} gigawat),
						'many' => q({0} gigawat),
						'name' => q(gigawatiau),
						'one' => q({0} gigawat),
						'other' => q({0} gigawat),
						'two' => q({0} gigawat),
						'zero' => q({0} gigawat),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} hp),
						'many' => q({0} hp),
						'name' => q(marchnerth),
						'one' => q({0} marchnerth),
						'other' => q({0} marchnerth),
						'two' => q({0} hp),
						'zero' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} hp),
						'many' => q({0} hp),
						'name' => q(marchnerth),
						'one' => q({0} marchnerth),
						'other' => q({0} marchnerth),
						'two' => q({0} hp),
						'zero' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} kW),
						'many' => q({0} kW),
						'name' => q(cilowatiau),
						'one' => q({0} cilowat),
						'other' => q({0} cilowat),
						'two' => q({0} kW),
						'zero' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} kW),
						'many' => q({0} kW),
						'name' => q(cilowatiau),
						'one' => q({0} cilowat),
						'other' => q({0} cilowat),
						'two' => q({0} kW),
						'zero' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} MW),
						'many' => q({0} MW),
						'name' => q(megawatiau),
						'one' => q({0} megawat),
						'other' => q({0} megawat),
						'two' => q({0} fegawat),
						'zero' => q({0} megawat),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} MW),
						'many' => q({0} MW),
						'name' => q(megawatiau),
						'one' => q({0} megawat),
						'other' => q({0} megawat),
						'two' => q({0} fegawat),
						'zero' => q({0} megawat),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} mW),
						'many' => q({0} mW),
						'name' => q(miliwatiau),
						'one' => q({0} miliwat),
						'other' => q({0} miliwat),
						'two' => q({0} mW),
						'zero' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} mW),
						'many' => q({0} mW),
						'name' => q(miliwatiau),
						'one' => q({0} miliwat),
						'other' => q({0} miliwat),
						'two' => q({0} mW),
						'zero' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} wat),
						'many' => q({0} wat),
						'one' => q({0} wat),
						'other' => q({0} wat),
						'two' => q({0} wat),
						'zero' => q({0} wat),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} wat),
						'many' => q({0} wat),
						'one' => q({0} wat),
						'other' => q({0} wat),
						'two' => q({0} wat),
						'zero' => q({0} wat),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} sgwâr),
						'few' => q({0} sgwâr),
						'many' => q({0} sgwâr),
						'one' => q({0} sgwâr),
						'other' => q({0} sgwâr),
						'two' => q({0} sgwâr),
						'zero' => q({0} sgwâr),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} sgwâr),
						'few' => q({0} sgwâr),
						'many' => q({0} sgwâr),
						'one' => q({0} sgwâr),
						'other' => q({0} sgwâr),
						'two' => q({0} sgwâr),
						'zero' => q({0} sgwâr),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} ciwbig),
						'few' => q({0} ciwbig),
						'many' => q({0} ciwbig),
						'one' => q({0} ciwbig),
						'other' => q({0} ciwbig),
						'two' => q({0} ciwbig),
						'zero' => q({0} ciwbig),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} ciwbig),
						'few' => q({0} ciwbig),
						'many' => q({0} ciwbig),
						'one' => q({0} ciwbig),
						'other' => q({0} ciwbig),
						'two' => q({0} ciwbig),
						'zero' => q({0} ciwbig),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atm),
						'many' => q({0} atm),
						'name' => q(atmosfferau),
						'one' => q({0} atmosffer),
						'other' => q({0} atmosffer),
						'two' => q({0} atm),
						'zero' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atm),
						'many' => q({0} atm),
						'name' => q(atmosfferau),
						'one' => q({0} atmosffer),
						'other' => q({0} atmosffer),
						'two' => q({0} atm),
						'zero' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hPa),
						'many' => q({0} hPa),
						'name' => q(hectopascalau),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal),
						'two' => q({0} hPa),
						'zero' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hPa),
						'many' => q({0} hPa),
						'name' => q(hectopascalau),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal),
						'two' => q({0} hPa),
						'zero' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} inHg),
						'many' => q({0} inHg),
						'name' => q(modfeddi o fercwri),
						'one' => q({0} fodfedd o fercwri),
						'other' => q({0} modfedd o fercwri),
						'two' => q({0} inHg),
						'zero' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} inHg),
						'many' => q({0} inHg),
						'name' => q(modfeddi o fercwri),
						'one' => q({0} fodfedd o fercwri),
						'other' => q({0} modfedd o fercwri),
						'two' => q({0} inHg),
						'zero' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} kPa),
						'many' => q({0} kPa),
						'name' => q(cilopascalau),
						'one' => q({0} cilopascal),
						'other' => q({0} cilopascalau),
						'two' => q({0} kPa),
						'zero' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} kPa),
						'many' => q({0} kPa),
						'name' => q(cilopascalau),
						'one' => q({0} cilopascal),
						'other' => q({0} cilopascalau),
						'two' => q({0} kPa),
						'zero' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} MPa),
						'many' => q({0} MPa),
						'name' => q(megapascalau),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalau),
						'two' => q({0} MPa),
						'zero' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} MPa),
						'many' => q({0} MPa),
						'name' => q(megapascalau),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalau),
						'two' => q({0} MPa),
						'zero' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} milibar),
						'many' => q({0} mbar),
						'name' => q(milibarau),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
						'two' => q({0} filibar),
						'zero' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} milibar),
						'many' => q({0} mbar),
						'name' => q(milibarau),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
						'two' => q({0} filibar),
						'zero' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(milimetrau o fercwri),
						'one' => q({0} milimetr o fercwri),
						'other' => q({0} milimetr o fercwri),
						'two' => q({0} mmHg),
						'zero' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(milimetrau o fercwri),
						'one' => q({0} milimetr o fercwri),
						'other' => q({0} milimetr o fercwri),
						'two' => q({0} mmHg),
						'zero' => q({0} mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} Pa),
						'many' => q({0} Pa),
						'name' => q(pascalau),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
						'two' => q({0} Pa),
						'zero' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} Pa),
						'many' => q({0} Pa),
						'name' => q(pascalau),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
						'two' => q({0} Pa),
						'zero' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} psi),
						'many' => q({0} psi),
						'name' => q(pwysau y fodfedd sgwar),
						'one' => q({0} pwys y fodfedd sgwar),
						'other' => q({0} pwys y fodfedd sgwar),
						'two' => q({0} psi),
						'zero' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} psi),
						'many' => q({0} psi),
						'name' => q(pwysau y fodfedd sgwar),
						'one' => q({0} pwys y fodfedd sgwar),
						'other' => q({0} pwys y fodfedd sgwar),
						'two' => q({0} psi),
						'zero' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'many' => q(B {0}),
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
						'two' => q(B {0}),
						'zero' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'many' => q(B {0}),
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
						'two' => q(B {0}),
						'zero' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} chilometr yr awr),
						'many' => q({0} chilometr yr awr),
						'name' => q(cilometrau yr awr),
						'one' => q({0} cilometr yr awr),
						'other' => q({0} cilometr yr awr),
						'two' => q({0} gilometr yr awr),
						'zero' => q({0} cilometr yr awr),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} chilometr yr awr),
						'many' => q({0} chilometr yr awr),
						'name' => q(cilometrau yr awr),
						'one' => q({0} cilometr yr awr),
						'other' => q({0} cilometr yr awr),
						'two' => q({0} gilometr yr awr),
						'zero' => q({0} cilometr yr awr),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} metr yr eiliad),
						'many' => q({0} metr yr eiliad),
						'name' => q(metrau yr eiliad),
						'one' => q({0} metr yr eiliad),
						'other' => q({0} metr yr eiliad),
						'two' => q({0} fetr yr eiliad),
						'zero' => q({0} metr yr eiliad),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} metr yr eiliad),
						'many' => q({0} metr yr eiliad),
						'name' => q(metrau yr eiliad),
						'one' => q({0} metr yr eiliad),
						'other' => q({0} metr yr eiliad),
						'two' => q({0} fetr yr eiliad),
						'zero' => q({0} metr yr eiliad),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} milltir yr awr),
						'many' => q({0} milltir yr awr),
						'name' => q(milltiroedd yr awr),
						'one' => q({0} filltir yr awr),
						'other' => q({0} milltir yr awr),
						'two' => q({0} filltir yr awr),
						'zero' => q({0} milltir yr awr),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} milltir yr awr),
						'many' => q({0} milltir yr awr),
						'name' => q(milltiroedd yr awr),
						'one' => q({0} filltir yr awr),
						'other' => q({0} milltir yr awr),
						'two' => q({0} filltir yr awr),
						'zero' => q({0} milltir yr awr),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0}°C),
						'many' => q({0}°C),
						'name' => q(graddau Celsius),
						'one' => q({0} radd Celsius),
						'other' => q({0} gradd Celsius),
						'two' => q({0}°C),
						'zero' => q({0} gradd Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0}°C),
						'many' => q({0}°C),
						'name' => q(graddau Celsius),
						'one' => q({0} radd Celsius),
						'other' => q({0} gradd Celsius),
						'two' => q({0}°C),
						'zero' => q({0} gradd Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0}°F),
						'many' => q({0}°F),
						'name' => q(gradd Fahrenheit),
						'one' => q({0} radd Fahrenheit),
						'other' => q({0} gradd Fahrenheit),
						'two' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0}°F),
						'many' => q({0}°F),
						'name' => q(gradd Fahrenheit),
						'one' => q({0} radd Fahrenheit),
						'other' => q({0} gradd Fahrenheit),
						'two' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} K),
						'many' => q({0} K),
						'name' => q(celfinau),
						'one' => q({0} celfin),
						'other' => q({0} celfin),
						'two' => q({0} K),
						'zero' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} K),
						'many' => q({0} K),
						'name' => q(celfinau),
						'one' => q({0} celfin),
						'other' => q({0} celfin),
						'two' => q({0} K),
						'zero' => q({0} K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} N⋅m),
						'many' => q({0} N⋅m),
						'name' => q(newton-metrau),
						'one' => q({0} newton-metr),
						'other' => q({0} newton-metrau),
						'two' => q({0} N⋅m),
						'zero' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} N⋅m),
						'many' => q({0} N⋅m),
						'name' => q(newton-metrau),
						'one' => q({0} newton-metr),
						'other' => q({0} newton-metrau),
						'two' => q({0} N⋅m),
						'zero' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'many' => q({0} lbf⋅ft),
						'name' => q(pwys-troedfeddi),
						'one' => q({0} pwys o rym⋅droedfedd),
						'other' => q({0} pwys-troedfeddi),
						'two' => q({0} lbf⋅ft),
						'zero' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'many' => q({0} lbf⋅ft),
						'name' => q(pwys-troedfeddi),
						'one' => q({0} pwys o rym⋅droedfedd),
						'other' => q({0} pwys-troedfeddi),
						'two' => q({0} lbf⋅ft),
						'zero' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} erw-droedfedd),
						'many' => q({0} erw-droedfedd),
						'name' => q(erw-droedfeddi),
						'one' => q({0} erw-droedfedd),
						'other' => q({0} erw-droedfedd),
						'two' => q({0} erw-droedfedd),
						'zero' => q({0} erw-droedfedd),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} erw-droedfedd),
						'many' => q({0} erw-droedfedd),
						'name' => q(erw-droedfeddi),
						'one' => q({0} erw-droedfedd),
						'other' => q({0} erw-droedfedd),
						'two' => q({0} erw-droedfedd),
						'zero' => q({0} erw-droedfedd),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} bbl),
						'many' => q({0} bbl),
						'name' => q(bareli),
						'one' => q({0} barel),
						'other' => q({0} barel),
						'two' => q({0} bbl),
						'zero' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} bbl),
						'many' => q({0} bbl),
						'name' => q(bareli),
						'one' => q({0} barel),
						'other' => q({0} barel),
						'two' => q({0} bbl),
						'zero' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bw),
						'many' => q({0} bw),
						'one' => q({0} bwsiel),
						'other' => q({0} bwsiel),
						'two' => q({0} bw),
						'zero' => q({0} bw),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bw),
						'many' => q({0} bw),
						'one' => q({0} bwsiel),
						'other' => q({0} bwsiel),
						'two' => q({0} bw),
						'zero' => q({0} bw),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cL),
						'many' => q({0} cL),
						'name' => q(centilitrau),
						'one' => q({0} centilitr),
						'other' => q({0} centilitr),
						'two' => q({0} gentilitr),
						'zero' => q({0} cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cL),
						'many' => q({0} cL),
						'name' => q(centilitrau),
						'one' => q({0} centilitr),
						'other' => q({0} centilitr),
						'two' => q({0} gentilitr),
						'zero' => q({0} cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} cm³),
						'many' => q({0} cm³),
						'name' => q(centimetrau ciwbig),
						'one' => q({0} centimetr ciwbig),
						'other' => q({0} chentimetr ciwbig),
						'per' => q({0} y centimetr ciwbig),
						'two' => q({0} cm³),
						'zero' => q({0} cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'many' => q({0} cm³),
						'name' => q(centimetrau ciwbig),
						'one' => q({0} centimetr ciwbig),
						'other' => q({0} chentimetr ciwbig),
						'per' => q({0} y centimetr ciwbig),
						'two' => q({0} cm³),
						'zero' => q({0} cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} tr³),
						'many' => q({0} tr³),
						'name' => q(troedfeddi ciwbig),
						'one' => q({0} droedfedd giwbig),
						'other' => q({0} troedfedd giwbig),
						'two' => q({0} tr³),
						'zero' => q({0} tr³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} tr³),
						'many' => q({0} tr³),
						'name' => q(troedfeddi ciwbig),
						'one' => q({0} droedfedd giwbig),
						'other' => q({0} troedfedd giwbig),
						'two' => q({0} tr³),
						'zero' => q({0} tr³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(modfeddi ciwbig),
						'one' => q({0} fodfedd giwbig),
						'other' => q({0} modfedd giwbig),
						'two' => q({0} in³),
						'zero' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(modfeddi ciwbig),
						'one' => q({0} fodfedd giwbig),
						'other' => q({0} modfedd giwbig),
						'two' => q({0} in³),
						'zero' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} km³),
						'many' => q({0} km³),
						'name' => q(cilometrau ciwbig),
						'one' => q({0} cilometr ciwbig),
						'other' => q({0} cilometr ciwbig),
						'two' => q({0} km³),
						'zero' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'many' => q({0} km³),
						'name' => q(cilometrau ciwbig),
						'one' => q({0} cilometr ciwbig),
						'other' => q({0} cilometr ciwbig),
						'two' => q({0} km³),
						'zero' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} m³),
						'many' => q({0} m³),
						'name' => q(metrau ciwbig),
						'one' => q({0} metr ciwbig),
						'other' => q({0} metr ciwbig),
						'per' => q({0} y metr ciwbig),
						'two' => q({0} m³),
						'zero' => q({0} m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} m³),
						'many' => q({0} m³),
						'name' => q(metrau ciwbig),
						'one' => q({0} metr ciwbig),
						'other' => q({0} metr ciwbig),
						'per' => q({0} y metr ciwbig),
						'two' => q({0} m³),
						'zero' => q({0} m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mi³),
						'many' => q({0} mi³),
						'name' => q(milltiroedd ciwbig),
						'one' => q({0} filltir giwbig),
						'other' => q({0} milltir giwbig),
						'two' => q({0} mi³),
						'zero' => q({0} milltir giwbig),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mi³),
						'many' => q({0} mi³),
						'name' => q(milltiroedd ciwbig),
						'one' => q({0} filltir giwbig),
						'other' => q({0} milltir giwbig),
						'two' => q({0} mi³),
						'zero' => q({0} milltir giwbig),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} llath³),
						'many' => q({0} llath³),
						'name' => q(llathenni ciwbig),
						'one' => q({0} llathen giwbig),
						'other' => q({0} llath giwbig),
						'two' => q({0} lath³),
						'zero' => q({0} llath³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} llath³),
						'many' => q({0} llath³),
						'name' => q(llathenni ciwbig),
						'one' => q({0} llathen giwbig),
						'other' => q({0} llath giwbig),
						'two' => q({0} lath³),
						'zero' => q({0} llath³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} cwpanaid),
						'many' => q({0} cwpanaid),
						'one' => q({0} cwpanaid),
						'other' => q({0} cwpanaid),
						'two' => q({0} gwpanaid),
						'zero' => q({0} cwpanaid),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} cwpanaid),
						'many' => q({0} cwpanaid),
						'one' => q({0} cwpanaid),
						'other' => q({0} cwpanaid),
						'two' => q({0} gwpanaid),
						'zero' => q({0} cwpanaid),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} mc),
						'many' => q({0} mc),
						'name' => q(cwpaneidiau metrig),
						'one' => q({0} cwpanaid metrig),
						'other' => q({0} cwpanaid metrig),
						'two' => q({0} mc),
						'zero' => q({0} mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} mc),
						'many' => q({0} mc),
						'name' => q(cwpaneidiau metrig),
						'one' => q({0} cwpanaid metrig),
						'other' => q({0} cwpanaid metrig),
						'two' => q({0} mc),
						'zero' => q({0} mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dL),
						'many' => q({0} dL),
						'name' => q(decilitrau),
						'one' => q({0} decilitr),
						'other' => q({0} decilitr),
						'two' => q({0} dL),
						'zero' => q({0} dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dL),
						'many' => q({0} dL),
						'name' => q(decilitrau),
						'one' => q({0} decilitr),
						'other' => q({0} decilitr),
						'two' => q({0} dL),
						'zero' => q({0} dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dstspn),
						'many' => q({0} dstspn),
						'name' => q(llond llwy bwdin),
						'one' => q({0} llond llwy bwdin),
						'other' => q({0} llond llwy bwdin),
						'two' => q({0} dstspn),
						'zero' => q({0} dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dstspn),
						'many' => q({0} dstspn),
						'name' => q(llond llwy bwdin),
						'one' => q({0} llond llwy bwdin),
						'other' => q({0} llond llwy bwdin),
						'two' => q({0} dstspn),
						'zero' => q({0} dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} dstspn Imp),
						'many' => q({0} dstspn Imp),
						'name' => q(llond llwy bwdin imp.),
						'one' => q({0} llond llwy bwdin imp.),
						'other' => q({0} llond llwy bwdin imp.),
						'two' => q({0} dstspn Imp),
						'zero' => q({0} dstspn Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} dstspn Imp),
						'many' => q({0} dstspn Imp),
						'name' => q(llond llwy bwdin imp.),
						'one' => q({0} llond llwy bwdin imp.),
						'other' => q({0} llond llwy bwdin imp.),
						'two' => q({0} dstspn Imp),
						'zero' => q({0} dstspn Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} owns hylifol),
						'many' => q({0} owns hylifol),
						'name' => q(ownsiau hylifol),
						'one' => q({0} owns hylifol),
						'other' => q({0} owns hylifol),
						'two' => q({0} owns hylifol),
						'zero' => q({0} owns hylifol),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} owns hylifol),
						'many' => q({0} owns hylifol),
						'name' => q(ownsiau hylifol),
						'one' => q({0} owns hylifol),
						'other' => q({0} owns hylifol),
						'two' => q({0} owns hylifol),
						'zero' => q({0} owns hylifol),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp.),
						'many' => q({0} fl oz Imp.),
						'name' => q(Ownsiau hylifol Imp.),
						'one' => q({0} owns hylifol Imp.),
						'other' => q({0} owns hylifol Imp.),
						'two' => q({0} fl oz Imp.),
						'zero' => q({0} fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp.),
						'many' => q({0} fl oz Imp.),
						'name' => q(Ownsiau hylifol Imp.),
						'one' => q({0} owns hylifol Imp.),
						'other' => q({0} owns hylifol Imp.),
						'two' => q({0} fl oz Imp.),
						'zero' => q({0} fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galwyn),
						'many' => q({0} galwyn),
						'name' => q(galwyni),
						'one' => q({0} galwyn),
						'other' => q({0} galwyn),
						'per' => q({0} y galwyn),
						'two' => q({0} alwyn),
						'zero' => q({0} galwyn),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galwyn),
						'many' => q({0} galwyn),
						'name' => q(galwyni),
						'one' => q({0} galwyn),
						'other' => q({0} galwyn),
						'per' => q({0} y galwyn),
						'two' => q({0} alwyn),
						'zero' => q({0} galwyn),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} galwyn Imp.),
						'many' => q({0} galwyn Imp.),
						'name' => q(Galwyni Imp.),
						'one' => q({0} galwyn Imp.),
						'other' => q({0} galwyn Imp.),
						'per' => q({0} y galwyn Imp.),
						'two' => q({0} galwyn Imp.),
						'zero' => q({0} galwyn Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} galwyn Imp.),
						'many' => q({0} galwyn Imp.),
						'name' => q(Galwyni Imp.),
						'one' => q({0} galwyn Imp.),
						'other' => q({0} galwyn Imp.),
						'per' => q({0} y galwyn Imp.),
						'two' => q({0} galwyn Imp.),
						'zero' => q({0} galwyn Imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hL),
						'many' => q({0} hL),
						'name' => q(hectolitrau),
						'one' => q({0} hectolitr),
						'other' => q({0} hectolitr),
						'two' => q({0} hL),
						'zero' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hL),
						'many' => q({0} hL),
						'name' => q(hectolitrau),
						'one' => q({0} hectolitr),
						'other' => q({0} hectolitr),
						'two' => q({0} hL),
						'zero' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} L),
						'many' => q({0} L),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} y litr),
						'two' => q({0} litr),
						'zero' => q({0} litr),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} L),
						'many' => q({0} L),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} y litr),
						'two' => q({0} litr),
						'zero' => q({0} litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} ML),
						'many' => q({0} ML),
						'name' => q(megalitrau),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
						'two' => q({0} ML),
						'zero' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} ML),
						'many' => q({0} ML),
						'name' => q(megalitrau),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
						'two' => q({0} ML),
						'zero' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mL),
						'many' => q({0} mL),
						'name' => q(mililitrau),
						'one' => q({0} mililitr),
						'other' => q({0} mililitr),
						'two' => q({0} mL),
						'zero' => q({0} mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mL),
						'many' => q({0} mL),
						'name' => q(mililitrau),
						'one' => q({0} mililitr),
						'other' => q({0} mililitr),
						'two' => q({0} mL),
						'zero' => q({0} mL),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pheint),
						'many' => q({0} pheint),
						'one' => q({0} peint),
						'other' => q({0} peint),
						'two' => q({0} beint),
						'zero' => q({0} peint),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pheint),
						'many' => q({0} pheint),
						'one' => q({0} peint),
						'other' => q({0} peint),
						'two' => q({0} beint),
						'zero' => q({0} peint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} mpt),
						'many' => q({0} mpt),
						'name' => q(peintiau metrig),
						'one' => q({0} peint metrig),
						'other' => q({0} peint metrig),
						'two' => q({0} mpt),
						'zero' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} mpt),
						'many' => q({0} mpt),
						'name' => q(peintiau metrig),
						'one' => q({0} peint metrig),
						'other' => q({0} peint metrig),
						'two' => q({0} mpt),
						'zero' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} chwart),
						'many' => q({0} chwart),
						'name' => q(chwartiau),
						'one' => q({0} chwart),
						'other' => q({0} chwart),
						'two' => q({0} gwart),
						'zero' => q({0} chwart),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} chwart),
						'many' => q({0} chwart),
						'name' => q(chwartiau),
						'one' => q({0} chwart),
						'other' => q({0} chwart),
						'two' => q({0} gwart),
						'zero' => q({0} chwart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(chwart Imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(chwart Imp),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} llond llwy fwrdd),
						'many' => q({0} llond llwy fwrdd),
						'name' => q(llond llwy fwrdd),
						'one' => q({0} llond llwy fwrdd),
						'other' => q({0} llond llwy fwrdd),
						'two' => q({0} lond llwy fwrdd),
						'zero' => q({0} llond llwy fwrdd),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} llond llwy fwrdd),
						'many' => q({0} llond llwy fwrdd),
						'name' => q(llond llwy fwrdd),
						'one' => q({0} llond llwy fwrdd),
						'other' => q({0} llond llwy fwrdd),
						'two' => q({0} lond llwy fwrdd),
						'zero' => q({0} llond llwy fwrdd),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} llond llwy de),
						'many' => q({0} llond llwy de),
						'name' => q(llond llwy de),
						'one' => q({0} llond llwy de),
						'other' => q({0} llond llwy de),
						'two' => q({0} lond llwy de),
						'zero' => q({0} llond llwy de),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} llond llwy de),
						'many' => q({0} llond llwy de),
						'name' => q(llond llwy de),
						'one' => q({0} llond llwy de),
						'other' => q({0} llond llwy de),
						'two' => q({0} lond llwy de),
						'zero' => q({0} llond llwy de),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
						'zero' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
						'zero' => q({0}G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} archfun),
						'many' => q({0} archfun),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0} archfun),
						'zero' => q({0} archfun),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} archfun),
						'many' => q({0} archfun),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0} archfun),
						'zero' => q({0} archfun),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(archeiliad),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
						'zero' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(archeiliad),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
						'zero' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} gradd),
						'many' => q({0} gradd),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0} radd),
						'zero' => q({0} gradd),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} gradd),
						'many' => q({0} gradd),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0} radd),
						'zero' => q({0} gradd),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} rad),
						'many' => q({0} rad),
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
						'two' => q({0} rad),
						'zero' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} rad),
						'many' => q({0} rad),
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
						'two' => q({0} rad),
						'zero' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} rev),
						'many' => q({0} rev),
						'name' => q(rev),
						'one' => q({0}rev),
						'other' => q({0}rev),
						'two' => q({0} rev),
						'zero' => q({0} rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} rev),
						'many' => q({0} rev),
						'name' => q(rev),
						'one' => q({0}rev),
						'other' => q({0}rev),
						'two' => q({0} rev),
						'zero' => q({0} rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0}erw),
						'many' => q({0}erw),
						'one' => q({0}erw),
						'other' => q({0}erw),
						'two' => q({0}erw),
						'zero' => q({0}erw),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0}erw),
						'many' => q({0}erw),
						'one' => q({0}erw),
						'other' => q({0}erw),
						'two' => q({0}erw),
						'zero' => q({0}erw),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0}ha),
						'many' => q({0}ha),
						'name' => q(hectar),
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
						'zero' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0}ha),
						'many' => q({0}ha),
						'name' => q(hectar),
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
						'zero' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0}cm²),
						'many' => q({0}cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
						'two' => q({0}cm²),
						'zero' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0}cm²),
						'many' => q({0}cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
						'two' => q({0}cm²),
						'zero' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0}ft²),
						'many' => q({0}ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'two' => q({0}ft²),
						'zero' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0}ft²),
						'many' => q({0}ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'two' => q({0}ft²),
						'zero' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0}km²),
						'many' => q({0}km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
						'zero' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0}km²),
						'many' => q({0}km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
						'zero' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0}m²),
						'many' => q({0}m²),
						'name' => q(metrau²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
						'two' => q({0}m²),
						'zero' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0}m²),
						'many' => q({0}m²),
						'name' => q(metrau²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
						'two' => q({0}m²),
						'zero' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0}mi²),
						'many' => q({0}mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'two' => q({0}mi²),
						'zero' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0}mi²),
						'many' => q({0}mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'two' => q({0}mi²),
						'zero' => q({0}mi²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(carat),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0} kt),
						'zero' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(carat),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0} kt),
						'zero' => q({0} kt),
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
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0}L/100km),
						'many' => q({0}L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
						'two' => q({0}L/100km),
						'zero' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0}L/100km),
						'many' => q({0}L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
						'two' => q({0}L/100km),
						'zero' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0}L/km),
						'many' => q({0}L/km),
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
						'two' => q({0}L/km),
						'zero' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0}L/km),
						'many' => q({0}L/km),
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
						'two' => q({0}L/km),
						'zero' => q({0}L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp.),
						'many' => q({0} mpg Imp.),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
						'two' => q({0} mpg Imp.),
						'zero' => q({0} mpg Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg Imp.),
						'many' => q({0} mpg Imp.),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
						'two' => q({0} mpg Imp.),
						'zero' => q({0} mpg Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}dn),
						'north' => q({0}g),
						'south' => q({0}d),
						'west' => q({0}gn),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}dn),
						'north' => q({0}g),
						'south' => q({0}d),
						'west' => q({0}gn),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0}did),
						'many' => q({0}did),
						'one' => q({0}did),
						'other' => q({0}did),
						'two' => q({0}ddid),
						'zero' => q({0}did),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0}did),
						'many' => q({0}did),
						'one' => q({0}did),
						'other' => q({0}did),
						'two' => q({0}ddid),
						'zero' => q({0}did),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} beit),
						'many' => q({0} beit),
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
						'two' => q({0} feit),
						'zero' => q({0} beit),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} beit),
						'many' => q({0} beit),
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
						'two' => q({0} feit),
						'zero' => q({0} beit),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0}Gb),
						'many' => q({0}Gb),
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
						'two' => q({0}Gb),
						'zero' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0}Gb),
						'many' => q({0}Gb),
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
						'two' => q({0}Gb),
						'zero' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0}GB),
						'many' => q({0}GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
						'two' => q({0}GB),
						'zero' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0}GB),
						'many' => q({0}GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
						'two' => q({0}GB),
						'zero' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
						'two' => q({0} kb),
						'zero' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
						'two' => q({0} kb),
						'zero' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
						'two' => q({0} kB),
						'zero' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
						'two' => q({0} kB),
						'zero' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
						'two' => q({0} MB),
						'zero' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
						'two' => q({0} MB),
						'zero' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0}TB),
						'many' => q({0}TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
						'two' => q({0}TB),
						'zero' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0}TB),
						'many' => q({0}TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
						'two' => q({0}TB),
						'zero' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0}c),
						'many' => q({0}c),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0}c),
						'zero' => q({0}c),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0}c),
						'many' => q({0}c),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0}c),
						'zero' => q({0}c),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0}d),
						'many' => q({0}d),
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
						'zero' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0}d),
						'many' => q({0}d),
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
						'zero' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(awr),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(awr),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'name' => q(milieiliad),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
						'zero' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'name' => q(milieiliad),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
						'zero' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0}mun),
						'many' => q({0}mun),
						'one' => q({0}mun),
						'other' => q({0}mun),
						'two' => q({0}mun),
						'zero' => q({0}mun),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0}mun),
						'many' => q({0}mun),
						'one' => q({0}mun),
						'other' => q({0}mun),
						'two' => q({0}mun),
						'zero' => q({0}mun),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'name' => q(mis),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
						'two' => q({0}m),
						'zero' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'name' => q(mis),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
						'two' => q({0}m),
						'zero' => q({0}m),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} chw),
						'many' => q({0} chw),
						'one' => q({0}chw),
						'other' => q({0} chw),
						'two' => q({0} chw),
						'zero' => q({0} chw),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} chw),
						'many' => q({0} chw),
						'one' => q({0}chw),
						'other' => q({0} chw),
						'two' => q({0} chw),
						'zero' => q({0} chw),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(eil),
						'per' => q({0}/e),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(eil),
						'per' => q({0}/e),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} ws),
						'many' => q({0} ws),
						'name' => q(ws),
						'one' => q({0}w),
						'other' => q({0}w),
						'per' => q({0}/w),
						'two' => q({0} ws),
						'zero' => q({0} ws),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} ws),
						'many' => q({0} ws),
						'name' => q(ws),
						'one' => q({0}w),
						'other' => q({0}w),
						'per' => q({0}/w),
						'two' => q({0} ws),
						'zero' => q({0} ws),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0}bl),
						'many' => q({0}bl),
						'name' => q(bl),
						'one' => q({0}bl),
						'other' => q({0}bl),
						'two' => q({0}bl),
						'zero' => q({0}bl),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0}bl),
						'many' => q({0}bl),
						'name' => q(bl),
						'one' => q({0}bl),
						'other' => q({0}bl),
						'two' => q({0}bl),
						'zero' => q({0}bl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0}A),
						'many' => q({0}A),
						'name' => q(amp),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
						'zero' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0}A),
						'many' => q({0}A),
						'name' => q(amp),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
						'zero' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0}mA),
						'many' => q({0}mA),
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0}mA),
						'zero' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0}mA),
						'many' => q({0}mA),
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0}mA),
						'zero' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0}Ω),
						'many' => q({0}Ω),
						'name' => q(ohm),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
						'zero' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0}Ω),
						'many' => q({0}Ω),
						'name' => q(ohm),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
						'zero' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0}V),
						'many' => q({0}V),
						'name' => q(folt),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
						'zero' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0}V),
						'many' => q({0}V),
						'name' => q(folt),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
						'zero' => q({0}V),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0}cal),
						'many' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
						'zero' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0}cal),
						'many' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
						'zero' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0}J),
						'many' => q({0}J),
						'name' => q(joule),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
						'zero' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0}J),
						'many' => q({0}J),
						'name' => q(joule),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
						'zero' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0}kcal),
						'many' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
						'zero' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0}kcal),
						'many' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
						'zero' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0}kj),
						'many' => q({0}kj),
						'name' => q(kJ),
						'one' => q({0}kj),
						'other' => q({0}kj),
						'two' => q({0}kj),
						'zero' => q({0}kj),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0}kj),
						'many' => q({0}kj),
						'name' => q(kJ),
						'one' => q({0}kj),
						'other' => q({0}kj),
						'two' => q({0}kj),
						'zero' => q({0}kj),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'many' => q({0} kWh/100km),
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
						'two' => q({0} kWh/100km),
						'zero' => q({0} kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'many' => q({0} kWh/100km),
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
						'two' => q({0} kWh/100km),
						'zero' => q({0} kWh/100km),
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
						'few' => q({0} lbf),
						'many' => q({0} lbf),
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
						'two' => q({0} lbf),
						'zero' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} lbf),
						'many' => q({0} lbf),
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
						'two' => q({0} lbf),
						'zero' => q({0} lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0}GHz),
						'many' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
						'zero' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0}GHz),
						'many' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
						'zero' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0}Hz),
						'many' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
						'zero' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0}Hz),
						'many' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
						'zero' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0}kHz),
						'many' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
						'zero' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0}kHz),
						'many' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
						'zero' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0}MHz),
						'many' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
						'zero' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0}MHz),
						'many' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
						'zero' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dot),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dot),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0}u.s.),
						'many' => q({0}u.s.),
						'one' => q({0}u.s.),
						'other' => q({0}u.s.),
						'two' => q({0}u.s.),
						'zero' => q({0}u.s.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0}u.s.),
						'many' => q({0}u.s.),
						'one' => q({0}u.s.),
						'other' => q({0}u.s.),
						'two' => q({0}u.s.),
						'zero' => q({0}u.s.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0}cm),
						'many' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
						'zero' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0}cm),
						'many' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
						'zero' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0}dm),
						'many' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
						'zero' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0}dm),
						'many' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
						'zero' => q({0}dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0}fth),
						'many' => q({0}fth),
						'one' => q({0}fth),
						'other' => q({0}fth),
						'two' => q({0}fth),
						'zero' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0}fth),
						'many' => q({0}fth),
						'one' => q({0}fth),
						'other' => q({0}fth),
						'two' => q({0}fth),
						'zero' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(troedfedd),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(troedfedd),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(modfedd),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/mod),
						'two' => q({0}″),
						'zero' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(modfedd),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/mod),
						'two' => q({0}″),
						'zero' => q({0}″),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0}km),
						'many' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
						'zero' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0}km),
						'many' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
						'zero' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0}ly),
						'many' => q({0}ly),
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
						'two' => q({0}ly),
						'zero' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0}ly),
						'many' => q({0}ly),
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
						'two' => q({0}ly),
						'zero' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
						'zero' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
						'zero' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0}μm),
						'many' => q({0}μm),
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
						'zero' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0}μm),
						'many' => q({0}μm),
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
						'zero' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0}mi),
						'many' => q({0}mi),
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
						'two' => q({0}mi),
						'zero' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0}mi),
						'many' => q({0}mi),
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
						'two' => q({0}mi),
						'zero' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} smi),
						'many' => q({0} smi),
						'name' => q(smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
						'two' => q({0} smi),
						'zero' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} smi),
						'many' => q({0} smi),
						'name' => q(smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
						'two' => q({0} smi),
						'zero' => q({0} smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0}mm),
						'many' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
						'zero' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0}mm),
						'many' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
						'zero' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0}nm),
						'many' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
						'zero' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0}nm),
						'many' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
						'zero' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} nmi),
						'many' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
						'two' => q({0} nmi),
						'zero' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} nmi),
						'many' => q({0} nmi),
						'name' => q(nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
						'two' => q({0} nmi),
						'zero' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0}pc),
						'many' => q({0}pc),
						'name' => q(pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
						'two' => q({0}pc),
						'zero' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0}pc),
						'many' => q({0}pc),
						'name' => q(pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
						'two' => q({0}pc),
						'zero' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
						'zero' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
						'zero' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0} pt),
						'zero' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0} pt),
						'zero' => q({0} pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} R☉),
						'many' => q({0} R☉),
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
						'two' => q({0} R☉),
						'zero' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} R☉),
						'many' => q({0} R☉),
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
						'two' => q({0} R☉),
						'zero' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0}llath),
						'many' => q({0}llath),
						'name' => q(llath),
						'one' => q({0}llath),
						'other' => q({0}llath),
						'two' => q({0}lath),
						'zero' => q({0}llath),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0}llath),
						'many' => q({0}llath),
						'name' => q(llath),
						'one' => q({0}llath),
						'other' => q({0}llath),
						'two' => q({0}lath),
						'zero' => q({0}llath),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} cd),
						'many' => q({0} cd),
						'one' => q({0}cd),
						'other' => q({0}cd),
						'two' => q({0} cd),
						'zero' => q({0} cd),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} cd),
						'many' => q({0} cd),
						'one' => q({0}cd),
						'other' => q({0}cd),
						'two' => q({0} cd),
						'zero' => q({0} cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lm),
						'many' => q({0} lm),
						'one' => q({0}lm),
						'other' => q({0}lm),
						'two' => q({0} lm),
						'zero' => q({0} lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lm),
						'many' => q({0} lm),
						'one' => q({0}lm),
						'other' => q({0}lm),
						'two' => q({0} lm),
						'zero' => q({0} lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0}lx),
						'many' => q({0}lx),
						'name' => q(lwcs),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
						'zero' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0}lx),
						'many' => q({0}lx),
						'name' => q(lwcs),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
						'zero' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} L☉),
						'many' => q({0} L☉),
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
						'two' => q({0} L☉),
						'zero' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} L☉),
						'many' => q({0} L☉),
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
						'two' => q({0} L☉),
						'zero' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0}CD),
						'many' => q({0}CD),
						'name' => q(carat),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
						'zero' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0}CD),
						'many' => q({0}CD),
						'name' => q(carat),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
						'zero' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0}g),
						'many' => q({0}g),
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
						'zero' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0}g),
						'many' => q({0}g),
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
						'zero' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'one' => q({0} kg),
						'other' => q({0}kg),
						'two' => q({0} kg),
						'zero' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'one' => q({0} kg),
						'other' => q({0}kg),
						'two' => q({0} kg),
						'zero' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0}μg),
						'many' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
						'zero' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0}μg),
						'many' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
						'zero' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0}mg),
						'many' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
						'zero' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0}mg),
						'many' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
						'zero' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0}owns),
						'many' => q({0}owns),
						'one' => q({0}owns),
						'other' => q({0}owns),
						'two' => q({0}owns),
						'zero' => q({0}owns),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0}owns),
						'many' => q({0}owns),
						'one' => q({0}owns),
						'other' => q({0}owns),
						'two' => q({0}owns),
						'zero' => q({0}owns),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0}phwys),
						'many' => q({0}phwys),
						'name' => q(pwys),
						'one' => q({0}pwys),
						'other' => q({0}pwys),
						'two' => q({0}bwys),
						'zero' => q({0}pwys),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0}phwys),
						'many' => q({0}phwys),
						'name' => q(pwys),
						'one' => q({0}pwys),
						'other' => q({0}pwys),
						'two' => q({0}bwys),
						'zero' => q({0}pwys),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0}st),
						'many' => q({0}st),
						'name' => q(stôn),
						'one' => q({0}st),
						'other' => q({0}st),
						'two' => q({0}st),
						'zero' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0}st),
						'many' => q({0}st),
						'name' => q(stôn),
						'one' => q({0}st),
						'other' => q({0}st),
						'two' => q({0}st),
						'zero' => q({0}st),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
						'zero' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
						'zero' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0}GW),
						'many' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
						'zero' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0}GW),
						'many' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
						'zero' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0}hp),
						'many' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
						'two' => q({0}hp),
						'zero' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0}hp),
						'many' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
						'two' => q({0}hp),
						'zero' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
						'zero' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
						'zero' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0}MW),
						'many' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
						'zero' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0}MW),
						'many' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
						'zero' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0}mW),
						'many' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
						'zero' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0}mW),
						'many' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
						'zero' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'name' => q(wat),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
						'zero' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'name' => q(wat),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
						'zero' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atm),
						'many' => q({0} atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
						'two' => q({0} atm),
						'zero' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atm),
						'many' => q({0} atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
						'two' => q({0} atm),
						'zero' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
						'zero' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
						'zero' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0}" Hg),
						'many' => q({0}" Hg),
						'name' => q(″ Hg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
						'two' => q({0}" Hg),
						'zero' => q({0}" Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0}" Hg),
						'many' => q({0}" Hg),
						'name' => q(″ Hg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
						'two' => q({0}" Hg),
						'zero' => q({0}" Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0}mb),
						'many' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
						'two' => q({0}mb),
						'zero' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0}mb),
						'many' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
						'two' => q({0}mb),
						'zero' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0}mmHg),
						'many' => q({0}mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
						'two' => q({0}mmHg),
						'zero' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0}mmHg),
						'many' => q({0}mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
						'two' => q({0}mmHg),
						'zero' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} Pa),
						'many' => q({0} Pa),
						'one' => q({0}Pa),
						'other' => q({0}Pa),
						'two' => q({0} Pa),
						'zero' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} Pa),
						'many' => q({0} Pa),
						'one' => q({0}Pa),
						'other' => q({0}Pa),
						'two' => q({0} Pa),
						'zero' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0}psi),
						'many' => q({0}psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
						'two' => q({0}psi),
						'zero' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0}psi),
						'many' => q({0}psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
						'two' => q({0}psi),
						'zero' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B {0}),
						'many' => q(B {0}),
						'one' => q(B{0}),
						'other' => q(B{0}),
						'two' => q(B {0}),
						'zero' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B {0}),
						'many' => q(B {0}),
						'one' => q(B{0}),
						'other' => q(B{0}),
						'two' => q(B {0}),
						'zero' => q(B {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0}km/h),
						'many' => q({0}km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
						'zero' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0}km/h),
						'many' => q({0}km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
						'zero' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0}not),
						'many' => q({0}not),
						'name' => q(not),
						'one' => q({0}not),
						'other' => q({0}not),
						'two' => q({0}not),
						'zero' => q({0}not),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0}not),
						'many' => q({0}not),
						'name' => q(not),
						'one' => q({0}not),
						'other' => q({0}not),
						'two' => q({0}not),
						'zero' => q({0}not),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0}m/s),
						'many' => q({0}m/s),
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
						'zero' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0}m/s),
						'many' => q({0}m/s),
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
						'zero' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0}m.y.a.),
						'many' => q({0}m.y.a.),
						'name' => q(m.y.a.),
						'one' => q({0}m.y.a.),
						'other' => q({0}m.y.a.),
						'two' => q({0}m.y.a.),
						'zero' => q({0}m.y.a.),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0}m.y.a.),
						'many' => q({0}m.y.a.),
						'name' => q(m.y.a.),
						'one' => q({0}m.y.a.),
						'other' => q({0}m.y.a.),
						'two' => q({0}m.y.a.),
						'zero' => q({0}m.y.a.),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0}°C),
						'many' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
						'zero' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0}°C),
						'many' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'two' => q({0}°C),
						'zero' => q({0}°),
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
					'temperature-kelvin' => {
						'few' => q({0}K),
						'many' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
						'zero' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0}K),
						'many' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
						'zero' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} N⋅m),
						'many' => q({0} N⋅m),
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
						'two' => q({0} N⋅m),
						'zero' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} N⋅m),
						'many' => q({0} N⋅m),
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
						'two' => q({0} N⋅m),
						'zero' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'many' => q({0} lbf⋅ft),
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
						'two' => q({0} lbf⋅ft),
						'zero' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'many' => q({0} lbf⋅ft),
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
						'two' => q({0} lbf⋅ft),
						'zero' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0}cL),
						'many' => q({0}cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
						'zero' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0}cL),
						'many' => q({0}cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
						'zero' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0}cm³),
						'many' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
						'zero' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0}cm³),
						'many' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
						'zero' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
						'two' => q({0} in³),
						'zero' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
						'two' => q({0} in³),
						'zero' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
						'zero' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
						'zero' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0}m³),
						'many' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
						'zero' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0}m³),
						'many' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
						'zero' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0}mi³),
						'many' => q({0}mi³),
						'one' => q({0}mi³),
						'other' => q({0}mi³),
						'two' => q({0}mi³),
						'zero' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0}mi³),
						'many' => q({0}mi³),
						'one' => q({0}mi³),
						'other' => q({0}mi³),
						'two' => q({0}mi³),
						'zero' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'name' => q(cwpan),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0} c),
						'zero' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'name' => q(cwpan),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0} c),
						'zero' => q({0} c),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0}dL),
						'many' => q({0}dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
						'zero' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0}dL),
						'many' => q({0}dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
						'zero' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} dstspn Imp),
						'many' => q({0} dstspn Imp),
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
						'two' => q({0} dstspn Imp),
						'zero' => q({0} dstspn Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} dstspn Imp),
						'many' => q({0} dstspn Imp),
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
						'two' => q({0} dstspn Imp),
						'zero' => q({0} dstspn Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dram fl),
						'many' => q({0} dram fl),
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
						'two' => q({0} dram fl),
						'zero' => q({0} dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dram fl),
						'many' => q({0} dram fl),
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
						'two' => q({0} dram fl),
						'zero' => q({0} dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} diferyn),
						'many' => q({0} diferyn),
						'name' => q(dr),
						'one' => q({0}dr),
						'other' => q({0}dr),
						'two' => q({0} diferyn),
						'zero' => q({0} diferyn),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} diferyn),
						'many' => q({0} diferyn),
						'name' => q(dr),
						'one' => q({0}dr),
						'other' => q({0}dr),
						'two' => q({0} diferyn),
						'zero' => q({0} diferyn),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp.),
						'many' => q({0} fl oz Imp.),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
						'two' => q({0} fl oz Imp.),
						'zero' => q({0} fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp.),
						'many' => q({0} fl oz Imp.),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
						'two' => q({0} fl oz Imp.),
						'zero' => q({0} fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0}gal),
						'many' => q({0}gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'two' => q({0}gal),
						'zero' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0}gal),
						'many' => q({0}gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'two' => q({0}gal),
						'zero' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'many' => q({0} gal Imp.),
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
						'two' => q({0} gal Imp.),
						'zero' => q({0} gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal Imp.),
						'many' => q({0} gal Imp.),
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
						'two' => q({0} gal Imp.),
						'zero' => q({0} gal Imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0}hL),
						'many' => q({0}hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
						'zero' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0}hL),
						'many' => q({0}hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
						'zero' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} joch),
						'many' => q({0} joch),
						'one' => q({0}joch),
						'other' => q({0}joch),
						'two' => q({0} joch),
						'zero' => q({0} joch),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} joch),
						'many' => q({0} joch),
						'one' => q({0}joch),
						'other' => q({0}joch),
						'two' => q({0} joch),
						'zero' => q({0} joch),
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
					'volume-megaliter' => {
						'few' => q({0}ML),
						'many' => q({0}ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
						'zero' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0}ML),
						'many' => q({0}ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
						'zero' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0}mL),
						'many' => q({0}mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
						'zero' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0}mL),
						'many' => q({0}mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
						'zero' => q({0}mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} phinsiad),
						'many' => q({0} pinsiad),
						'one' => q({0}pn),
						'other' => q({0}pn),
						'two' => q({0} binsiad),
						'zero' => q({0} pinsiad),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} phinsiad),
						'many' => q({0} pinsiad),
						'one' => q({0}pn),
						'other' => q({0}pn),
						'two' => q({0} binsiad),
						'zero' => q({0} pinsiad),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0} pt),
						'zero' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0} pt),
						'zero' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} qt),
						'many' => q({0} qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
						'two' => q({0} qt),
						'zero' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} qt),
						'many' => q({0} qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
						'two' => q({0} qt),
						'zero' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} qt Imp.),
						'many' => q({0} qt Imp.),
						'name' => q(qt Imp),
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
						'two' => q({0} qt Imp.),
						'zero' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} qt Imp.),
						'many' => q({0} qt Imp.),
						'name' => q(qt Imp),
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
						'two' => q({0} qt Imp.),
						'zero' => q({0} qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} tbsp),
						'many' => q({0} tbsp),
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
						'two' => q({0} tbsp),
						'zero' => q({0} tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} tbsp),
						'many' => q({0} tbsp),
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
						'two' => q({0} tbsp),
						'zero' => q({0} tbsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(cyfeiriad),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(cyfeiriad),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(grym disgyrchedd),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(grym disgyrchedd),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} m/eil²),
						'many' => q({0} m/eil²),
						'name' => q(metrau/eil²),
						'one' => q({0} m/eil²),
						'other' => q({0} m/eil²),
						'two' => q({0} m/eil²),
						'zero' => q({0} m/eil²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} m/eil²),
						'many' => q({0} m/eil²),
						'name' => q(metrau/eil²),
						'one' => q({0} m/eil²),
						'other' => q({0} m/eil²),
						'two' => q({0} m/eil²),
						'zero' => q({0} m/eil²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} archfun),
						'many' => q({0} archfun),
						'name' => q(archfunudau),
						'one' => q({0} archfun),
						'other' => q({0} archfun),
						'two' => q({0} archfun),
						'zero' => q({0} archfun),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} archfun),
						'many' => q({0} archfun),
						'name' => q(archfunudau),
						'one' => q({0} archfun),
						'other' => q({0} archfun),
						'two' => q({0} archfun),
						'zero' => q({0} archfun),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} archeiliad),
						'many' => q({0} archeiliad),
						'name' => q(archeiliadau),
						'one' => q({0} archeiliad),
						'other' => q({0} archeiliad),
						'two' => q({0} archeiliad),
						'zero' => q({0} archeiliad),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} archeiliad),
						'many' => q({0} archeiliad),
						'name' => q(archeiliadau),
						'one' => q({0} archeiliad),
						'other' => q({0} archeiliad),
						'two' => q({0} archeiliad),
						'zero' => q({0} archeiliad),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradd),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradd),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianau),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianau),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} chylchdro),
						'many' => q({0} cylchdro),
						'name' => q(cylchdro),
						'one' => q({0} cylchdro),
						'other' => q({0} cylchdro),
						'two' => q({0} gylchdro),
						'zero' => q({0} cylchdro),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} chylchdro),
						'many' => q({0} cylchdro),
						'name' => q(cylchdro),
						'one' => q({0} cylchdro),
						'other' => q({0} cylchdro),
						'two' => q({0} gylchdro),
						'zero' => q({0} cylchdro),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} erw),
						'many' => q({0} erw),
						'name' => q(erw),
						'one' => q({0} erw),
						'other' => q({0} erw),
						'two' => q({0} erw),
						'zero' => q({0} erw),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} erw),
						'many' => q({0} erw),
						'name' => q(erw),
						'one' => q({0} erw),
						'other' => q({0} erw),
						'two' => q({0} erw),
						'zero' => q({0} erw),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunam),
						'many' => q({0} dunam),
						'name' => q(dunamau),
						'one' => q({0} dunam),
						'other' => q({0} dunam),
						'two' => q({0} ddunam),
						'zero' => q({0} dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunam),
						'many' => q({0} dunam),
						'name' => q(dunamau),
						'one' => q({0} dunam),
						'other' => q({0} dunam),
						'two' => q({0} ddunam),
						'zero' => q({0} dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectarau),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectarau),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'per' => q({0} y cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0} y cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} tr²),
						'many' => q({0} tr²),
						'name' => q(troedfedd²),
						'one' => q({0} tr²),
						'other' => q({0} tr²),
						'two' => q({0} tr²),
						'zero' => q({0} tr²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} tr²),
						'many' => q({0} tr²),
						'name' => q(troedfedd²),
						'one' => q({0} tr²),
						'other' => q({0} tr²),
						'two' => q({0} tr²),
						'zero' => q({0} tr²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} mod²),
						'many' => q({0} mod²),
						'name' => q(modfedd²),
						'one' => q({0} mod²),
						'other' => q({0} mod²),
						'per' => q({0} y mod²),
						'two' => q({0} mod²),
						'zero' => q({0} mod²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} mod²),
						'many' => q({0} mod²),
						'name' => q(modfedd²),
						'one' => q({0} mod²),
						'other' => q({0} mod²),
						'per' => q({0} y mod²),
						'two' => q({0} mod²),
						'zero' => q({0} mod²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0} y m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0} y m²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} llath²),
						'many' => q({0} llath²),
						'name' => q(llath²),
						'one' => q({0} llath²),
						'other' => q({0} llath²),
						'two' => q({0} llath²),
						'zero' => q({0} llath²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} llath²),
						'many' => q({0} llath²),
						'name' => q(llath²),
						'one' => q({0} llath²),
						'other' => q({0} llath²),
						'two' => q({0} llath²),
						'zero' => q({0} llath²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} eitem),
						'many' => q({0} eitem),
						'name' => q(eitem),
						'one' => q({0} eitem),
						'other' => q({0} eitem),
						'two' => q({0} eitem),
						'zero' => q({0} eitem),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} eitem),
						'many' => q({0} eitem),
						'name' => q(eitem),
						'one' => q({0} eitem),
						'other' => q({0} eitem),
						'two' => q({0} eitem),
						'zero' => q({0} eitem),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karatau),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karatau),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimôl/litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimôl/litr),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} môl),
						'many' => q({0} môl),
						'name' => q(môl),
						'one' => q({0} môl),
						'other' => q({0} môl),
						'two' => q({0} môl),
						'zero' => q({0} môl),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} môl),
						'many' => q({0} môl),
						'name' => q(môl),
						'one' => q({0} môl),
						'other' => q({0} môl),
						'two' => q({0} môl),
						'zero' => q({0} môl),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(y cant),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(y cant),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(rhan/miliwn),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(rhan/miliwn),
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
					'consumption-liter-per-kilometer' => {
						'name' => q(litrau/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litrau/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
						'zero' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
						'zero' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milltir/gal Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milltir/gal Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} dn),
						'north' => q({0} g),
						'south' => q({0} d),
						'west' => q({0} gn),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} dn),
						'north' => q({0} g),
						'south' => q({0} d),
						'west' => q({0} gn),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} did),
						'many' => q({0} did),
						'name' => q(did),
						'one' => q({0} did),
						'other' => q({0} did),
						'two' => q({0} did),
						'zero' => q({0} did),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} did),
						'many' => q({0} did),
						'name' => q(did),
						'one' => q({0} did),
						'other' => q({0} did),
						'two' => q({0} did),
						'zero' => q({0} did),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} beit),
						'many' => q({0} beit),
						'name' => q(beit),
						'one' => q({0} beit),
						'other' => q({0} beit),
						'two' => q({0} feit),
						'zero' => q({0} beit),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} beit),
						'many' => q({0} beit),
						'name' => q(beit),
						'one' => q({0} beit),
						'other' => q({0} beit),
						'two' => q({0} feit),
						'zero' => q({0} beit),
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
					'digital-gigabyte' => {
						'name' => q(GBeit),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBeit),
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
					'digital-kilobyte' => {
						'name' => q(kBeit),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBeit),
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
					'digital-megabyte' => {
						'name' => q(MBeit),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBeit),
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
					'digital-terabyte' => {
						'name' => q(TBeit),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBeit),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} diwrnod),
						'many' => q({0} diwrnod),
						'name' => q(diwrnodau),
						'one' => q({0} diwrnod),
						'other' => q({0} diwrnod),
						'two' => q({0} ddiwrnod),
						'zero' => q({0} diwrnod),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} diwrnod),
						'many' => q({0} diwrnod),
						'name' => q(diwrnodau),
						'one' => q({0} diwrnod),
						'other' => q({0} diwrnod),
						'two' => q({0} ddiwrnod),
						'zero' => q({0} diwrnod),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} deg),
						'many' => q({0} deg),
						'name' => q(deg),
						'one' => q({0} deg),
						'other' => q({0} deg),
						'two' => q({0} degawd),
						'zero' => q({0} deg),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} deg),
						'many' => q({0} deg),
						'name' => q(deg),
						'one' => q({0} deg),
						'other' => q({0} deg),
						'two' => q({0} degawd),
						'zero' => q({0} deg),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} awr),
						'many' => q({0} awr),
						'name' => q(oriau),
						'one' => q({0} awr),
						'other' => q({0} awr),
						'per' => q({0}/a),
						'two' => q({0} awr),
						'zero' => q({0} awr),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} awr),
						'many' => q({0} awr),
						'name' => q(oriau),
						'one' => q({0} awr),
						'other' => q({0} awr),
						'per' => q({0}/a),
						'two' => q({0} awr),
						'zero' => q({0} awr),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(milieiliadau),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
						'zero' => q({0} milieil),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(milieiliadau),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'two' => q({0} ms),
						'zero' => q({0} milieil),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} mun),
						'many' => q({0} mun),
						'name' => q(mun),
						'one' => q({0} mun),
						'other' => q({0} mun),
						'per' => q({0}/mun),
						'two' => q({0} mun),
						'zero' => q({0} mun),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} mun),
						'many' => q({0} mun),
						'name' => q(mun),
						'one' => q({0} mun),
						'other' => q({0} mun),
						'per' => q({0}/mun),
						'two' => q({0} mun),
						'zero' => q({0} mun),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mis),
						'many' => q({0} mis),
						'name' => q(misoedd),
						'one' => q({0} mis),
						'other' => q({0} mis),
						'per' => q({0}/mis),
						'two' => q({0} fis),
						'zero' => q({0} mis),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mis),
						'many' => q({0} mis),
						'name' => q(misoedd),
						'one' => q({0} mis),
						'other' => q({0} mis),
						'per' => q({0}/mis),
						'two' => q({0} fis),
						'zero' => q({0} mis),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} chw),
						'many' => q({0} chw),
						'name' => q(chw),
						'one' => q({0} chw),
						'other' => q({0} chw),
						'per' => q({0}/chw),
						'two' => q({0} chw),
						'zero' => q({0} chw),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} chw),
						'many' => q({0} chw),
						'name' => q(chw),
						'one' => q({0} chw),
						'other' => q({0} chw),
						'per' => q({0}/chw),
						'two' => q({0} chw),
						'zero' => q({0} chw),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} eil),
						'many' => q({0} eil),
						'name' => q(eiliadau),
						'one' => q({0} eil),
						'other' => q({0} eil),
						'per' => q({0}/eil),
						'two' => q({0} eil),
						'zero' => q({0} eil),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} eil),
						'many' => q({0} eil),
						'name' => q(eiliadau),
						'one' => q({0} eil),
						'other' => q({0} eil),
						'per' => q({0}/eil),
						'two' => q({0} eil),
						'zero' => q({0} eil),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} ws),
						'many' => q({0} ws),
						'name' => q(wythnosau),
						'one' => q({0} ws),
						'other' => q({0} ws),
						'per' => q({0}/ws),
						'two' => q({0} ws),
						'zero' => q({0} ws),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} ws),
						'many' => q({0} ws),
						'name' => q(wythnosau),
						'one' => q({0} ws),
						'other' => q({0} ws),
						'per' => q({0}/ws),
						'two' => q({0} ws),
						'zero' => q({0} ws),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} bl),
						'many' => q({0} bl),
						'name' => q(blynyddoedd),
						'one' => q({0} bl),
						'other' => q({0} bl),
						'per' => q({0}/bl),
						'two' => q({0} bl),
						'zero' => q({0} bl),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} bl),
						'many' => q({0} bl),
						'name' => q(blynyddoedd),
						'one' => q({0} bl),
						'other' => q({0} bl),
						'per' => q({0}/bl),
						'two' => q({0} bl),
						'zero' => q({0} bl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampau),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampau),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampau),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampau),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohmau),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohmau),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(foltiau),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(foltiau),
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
						'name' => q(electronfolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronfolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} kcal),
						'zero' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jouleau),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jouleau),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(cilojouleau),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(cilojouleau),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} kW-awr),
						'many' => q({0} kW-awr),
						'name' => q(kW-awr),
						'one' => q({0} kW-awr),
						'other' => q({0} kW-awr),
						'two' => q({0} kW-awr),
						'zero' => q({0} kW-awr),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} kW-awr),
						'many' => q({0} kW-awr),
						'name' => q(kW-awr),
						'one' => q({0} kW-awr),
						'other' => q({0} kW-awr),
						'two' => q({0} kW-awr),
						'zero' => q({0} kW-awr),
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
						'name' => q(pwys-grym),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pwys-grym),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} px),
						'many' => q({0} px),
						'name' => q(dotiau),
						'one' => q({0} dot),
						'other' => q({0} dot),
						'two' => q({0} px),
						'zero' => q({0} px),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} px),
						'many' => q({0} px),
						'name' => q(dotiau),
						'one' => q({0} dot),
						'other' => q({0} dot),
						'two' => q({0} px),
						'zero' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'many' => q({0} ppcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} ppcm),
						'two' => q({0} ppcm),
						'zero' => q({0} ppcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ppcm),
						'many' => q({0} ppcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} ppcm),
						'two' => q({0} ppcm),
						'zero' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapicseli),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapicseli),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(picseli),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(picseli),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} u.s.),
						'many' => q({0} u.s.),
						'name' => q(u.s.),
						'one' => q({0} u.s.),
						'other' => q({0} u.s.),
						'two' => q({0} u.s.),
						'zero' => q({0} u.s.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} u.s.),
						'many' => q({0} u.s.),
						'name' => q(u.s.),
						'one' => q({0} u.s.),
						'other' => q({0} u.s.),
						'two' => q({0} u.s.),
						'zero' => q({0} u.s.),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} gwryd),
						'many' => q({0} gwryd),
						'name' => q(gwrhydau),
						'one' => q({0} gwryd),
						'other' => q({0} gwryd),
						'two' => q({0} wryd),
						'zero' => q({0} gwryd),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} gwryd),
						'many' => q({0} gwryd),
						'name' => q(gwrhydau),
						'one' => q({0} gwryd),
						'other' => q({0} gwryd),
						'two' => q({0} wryd),
						'zero' => q({0} gwryd),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(troedfeddi),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/troedfedd),
						'two' => q({0}′),
						'zero' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(troedfeddi),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/troedfedd),
						'two' => q({0}′),
						'zero' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} yst),
						'many' => q({0} yst),
						'name' => q(ystadenni),
						'one' => q({0} yst),
						'other' => q({0} yst),
						'two' => q({0} yst),
						'zero' => q({0} yst),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} yst),
						'many' => q({0} yst),
						'name' => q(ystadenni),
						'one' => q({0} yst),
						'other' => q({0} yst),
						'two' => q({0} yst),
						'zero' => q({0} yst),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} modfedd),
						'many' => q({0} modfedd),
						'name' => q(modfeddi),
						'one' => q({0} fodfedd),
						'other' => q({0} modfedd),
						'per' => q({0}/fodfedd),
						'two' => q({0} fodfedd),
						'zero' => q({0} modfedd),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} modfedd),
						'many' => q({0} modfedd),
						'name' => q(modfeddi),
						'one' => q({0} fodfedd),
						'other' => q({0} modfedd),
						'per' => q({0}/fodfedd),
						'two' => q({0} fodfedd),
						'zero' => q({0} modfedd),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} bg),
						'many' => q({0} bg),
						'name' => q(bl golau),
						'one' => q({0} bg),
						'other' => q({0} bg),
						'two' => q({0} bg),
						'zero' => q({0} bg),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} bg),
						'many' => q({0} bg),
						'name' => q(bl golau),
						'one' => q({0} bg),
						'other' => q({0} bg),
						'two' => q({0} bg),
						'zero' => q({0} bg),
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
						'name' => q(μmetrau),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmetrau),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milltiroedd),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milltiroedd),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} mi Sgand.),
						'many' => q({0} mi Sgand.),
						'name' => q(mi Sgand.),
						'one' => q({0} mi Sgand.),
						'other' => q({0} mi Sgand.),
						'two' => q({0} mi Sgand.),
						'zero' => q({0} mi Sgand.),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} mi Sgand.),
						'many' => q({0} mi Sgand.),
						'name' => q(mi Sgand.),
						'one' => q({0} mi Sgand.),
						'other' => q({0} mi Sgand.),
						'two' => q({0} mi Sgand.),
						'zero' => q({0} mi Sgand.),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} mi fôr),
						'many' => q({0} mi fôr),
						'name' => q(mi fôr),
						'one' => q({0} mi fôr),
						'other' => q({0} mi fôr),
						'two' => q({0} mi fôr),
						'zero' => q({0} mi fôr),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} mi fôr),
						'many' => q({0} mi fôr),
						'name' => q(mi fôr),
						'one' => q({0} mi fôr),
						'other' => q({0} mi fôr),
						'two' => q({0} mi fôr),
						'zero' => q({0} mi fôr),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecau),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecau),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radiysau solar),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radiysau solar),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} llath),
						'many' => q({0} llath),
						'name' => q(llathenni),
						'one' => q({0} llath),
						'other' => q({0} llath),
						'two' => q({0} lath),
						'zero' => q({0} llath),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} llath),
						'many' => q({0} llath),
						'name' => q(llathenni),
						'one' => q({0} llath),
						'other' => q({0} llath),
						'two' => q({0} lath),
						'zero' => q({0} llath),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lycsau),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lycsau),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(goleueddau solar),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(goleueddau solar),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(caratau),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(caratau),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltonau),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltonau),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masau ddaear),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masau ddaear),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} graen),
						'many' => q({0} graen),
						'name' => q(graen),
						'one' => q({0} graen),
						'other' => q({0} graen),
						'two' => q({0} raen),
						'zero' => q({0} graen),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} graen),
						'many' => q({0} graen),
						'name' => q(graen),
						'one' => q({0} graen),
						'other' => q({0} graen),
						'two' => q({0} raen),
						'zero' => q({0} graen),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramau),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramau),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} owns),
						'many' => q({0} owns),
						'name' => q(owns),
						'one' => q({0} owns),
						'other' => q({0} owns),
						'per' => q({0}/owns),
						'two' => q({0} owns),
						'zero' => q({0} owns),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} owns),
						'many' => q({0} owns),
						'name' => q(owns),
						'one' => q({0} owns),
						'other' => q({0} owns),
						'per' => q({0}/owns),
						'two' => q({0} owns),
						'zero' => q({0} owns),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} phwys),
						'many' => q({0} phwys),
						'name' => q(pwysi),
						'one' => q({0} pwys),
						'other' => q({0} pwys),
						'per' => q({0}/pwys),
						'two' => q({0} bwys),
						'zero' => q({0} pwys),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} phwys),
						'many' => q({0} phwys),
						'name' => q(pwysi),
						'one' => q({0} pwys),
						'other' => q({0} pwys),
						'per' => q({0}/pwys),
						'two' => q({0} bwys),
						'zero' => q({0} pwys),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masau solar),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masau solar),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stonau),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stonau),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watiau),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watiau),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'two' => q({0} mmHg),
						'zero' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'two' => q({0} mmHg),
						'zero' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} not),
						'many' => q({0} not),
						'name' => q(notiau),
						'one' => q({0} not),
						'other' => q({0} not),
						'two' => q({0} not),
						'zero' => q({0} not),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} not),
						'many' => q({0} not),
						'name' => q(notiau),
						'one' => q({0} not),
						'other' => q({0} not),
						'two' => q({0} not),
						'zero' => q({0} not),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metrau/eil),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metrau/eil),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} m.y.a.),
						'many' => q({0} m.y.a.),
						'name' => q(milltir/awr),
						'one' => q({0} m.y.a.),
						'other' => q({0} m.y.a.),
						'two' => q({0} m.y.a.),
						'zero' => q({0} m.y.a.),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} m.y.a.),
						'many' => q({0} m.y.a.),
						'name' => q(milltir/awr),
						'one' => q({0} m.y.a.),
						'other' => q({0} m.y.a.),
						'two' => q({0} m.y.a.),
						'zero' => q({0} m.y.a.),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(gradd C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(gradd C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(gradd F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(gradd F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} erw tr),
						'many' => q({0} erw tr),
						'name' => q(erw tr),
						'one' => q({0} erw tr),
						'other' => q({0} erw tr),
						'two' => q({0} erw tr),
						'zero' => q({0} erw tr),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} erw tr),
						'many' => q({0} erw tr),
						'name' => q(erw tr),
						'one' => q({0} erw tr),
						'other' => q({0} erw tr),
						'two' => q({0} erw tr),
						'zero' => q({0} erw tr),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bw),
						'many' => q({0} bw),
						'name' => q(bwsielau),
						'one' => q({0} bw),
						'other' => q({0} bw),
						'two' => q({0} bw),
						'zero' => q({0} bw),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bw),
						'many' => q({0} bw),
						'name' => q(bwsielau),
						'one' => q({0} bw),
						'other' => q({0} bw),
						'two' => q({0} bw),
						'zero' => q({0} bw),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} tr³),
						'many' => q({0} tr³),
						'name' => q(troedfedd³),
						'one' => q({0} tr³),
						'other' => q({0} tr³),
						'two' => q({0} tr³),
						'zero' => q({0} tr³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} tr³),
						'many' => q({0} tr³),
						'name' => q(troedfedd³),
						'one' => q({0} tr³),
						'other' => q({0} tr³),
						'two' => q({0} tr³),
						'zero' => q({0} tr³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(modfeddi³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(modfeddi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} llath³),
						'many' => q({0} llath³),
						'name' => q(llathenni³),
						'one' => q({0} llathen³),
						'other' => q({0} llath³),
						'two' => q({0} lath³),
						'zero' => q({0} llath³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} llath³),
						'many' => q({0} llath³),
						'name' => q(llathenni³),
						'one' => q({0} llathen³),
						'other' => q({0} llath³),
						'two' => q({0} lath³),
						'zero' => q({0} llath³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cwpaneidiau),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cwpaneidiau),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cwpanaid metrig),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cwpanaid metrig),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dracmon hy),
						'many' => q({0} dracmon hy),
						'name' => q(dracmon hylifol),
						'one' => q({0} dracmon hy),
						'other' => q({0} dracmon hy),
						'two' => q({0} ddracmon hy),
						'zero' => q({0} dracmon hy),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dracmon hy),
						'many' => q({0} dracmon hy),
						'name' => q(dracmon hylifol),
						'one' => q({0} dracmon hy),
						'other' => q({0} dracmon hy),
						'two' => q({0} ddracmon hy),
						'zero' => q({0} dracmon hy),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} diferyn),
						'many' => q({0} diferyn),
						'name' => q(diferyn),
						'one' => q({0} diferyn),
						'other' => q({0} diferyn),
						'two' => q({0} ddiferyn),
						'zero' => q({0} diferyn),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} diferyn),
						'many' => q({0} diferyn),
						'name' => q(diferyn),
						'one' => q({0} diferyn),
						'other' => q({0} diferyn),
						'two' => q({0} ddiferyn),
						'zero' => q({0} diferyn),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
						'zero' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
						'zero' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
						'zero' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
						'zero' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Gal Imp.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} joch),
						'many' => q({0} joch),
						'name' => q(joch),
						'one' => q({0} joch),
						'other' => q({0} joch),
						'two' => q({0} joch),
						'zero' => q({0} joch),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} joch),
						'many' => q({0} joch),
						'name' => q(joch),
						'one' => q({0} joch),
						'other' => q({0} joch),
						'two' => q({0} joch),
						'zero' => q({0} joch),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} L),
						'many' => q({0} L),
						'name' => q(litrau),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
						'two' => q({0} L),
						'zero' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} L),
						'many' => q({0} L),
						'name' => q(litrau),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
						'two' => q({0} L),
						'zero' => q({0} L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} phinsiad),
						'many' => q({0} pinsiad),
						'name' => q(pinsiad),
						'one' => q({0} pinsiad),
						'other' => q({0} pinsiad),
						'two' => q({0} binsiad),
						'zero' => q({0} pinsiad),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} phinsiad),
						'many' => q({0} pinsiad),
						'name' => q(pinsiad),
						'one' => q({0} pinsiad),
						'other' => q({0} pinsiad),
						'two' => q({0} binsiad),
						'zero' => q({0} pinsiad),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(peintiau),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(peintiau),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} cht Imp.),
						'many' => q({0} cht Imp.),
						'name' => q(cht Imp.),
						'one' => q({0} cht Imp.),
						'other' => q({0} cht Imp.),
						'two' => q({0} cht Imp.),
						'zero' => q({0} cht Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} cht Imp.),
						'many' => q({0} cht Imp.),
						'name' => q(cht Imp.),
						'one' => q({0} cht Imp.),
						'other' => q({0} cht Imp.),
						'two' => q({0} cht Imp.),
						'zero' => q({0} cht Imp.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ie|i|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:na|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, a(c) {1}),
				2 => q({0} a(c) {1}),
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
					'few' => '0K',
					'many' => '0K',
					'one' => '0 mil',
					'other' => '0 mil',
					'two' => '0K',
					'zero' => '0 mil',
				},
				'10000' => {
					'few' => '00K',
					'many' => '00K',
					'one' => '00 mil',
					'other' => '00 mil',
					'two' => '00K',
					'zero' => '00K',
				},
				'100000' => {
					'few' => '000K',
					'many' => '000K',
					'one' => '000 mil',
					'other' => '000 mil',
					'two' => '000K',
					'zero' => '000K',
				},
				'1000000' => {
					'one' => '0 miliwn',
					'other' => '0 miliwn',
				},
				'10000000' => {
					'one' => '00 miliwn',
					'other' => '00 miliwn',
				},
				'100000000' => {
					'one' => '000 miliwn',
					'other' => '000 miliwn',
				},
				'1000000000' => {
					'one' => '0 biliwn',
					'other' => '0 biliwn',
				},
				'10000000000' => {
					'one' => '00 biliwn',
					'other' => '00 biliwn',
				},
				'100000000000' => {
					'one' => '000 biliwn',
					'other' => '000 biliwn',
				},
				'1000000000000' => {
					'one' => '0 triliwn',
					'other' => '0 triliwn',
				},
				'10000000000000' => {
					'one' => '00 triliwn',
					'other' => '00 triliwn',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000 triliwn',
				},
			},
			'short' => {
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
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
		'AED' => {
			display_name => {
				'currency' => q(Dirham Yr Emiradau Arabaidd Unedig),
				'few' => q(dirham yr Emiradau Arabaidd Unedig),
				'many' => q(dirham yr Emiradau Arabaidd Unedig),
				'one' => q(dirham yr Emiradau Arabaidd Unedig),
				'other' => q(dirham yr Emiradau Arabaidd Unedig),
				'two' => q(dirham yr Emiradau Arabaidd Unedig),
				'zero' => q(dirham yr Emiradau Arabaidd Unedig),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghani Afghanistan \(1927–2002\)),
				'few' => q(afghani Afghanistan \(1927–2002\)),
				'many' => q(afghani Afghanistan \(1927–2002\)),
				'one' => q(afghani Afghanistan \(1927–2002\)),
				'other' => q(afghani Afghanistan \(1927–2002\)),
				'two' => q(afghani Afghanistan \(1927–2002\)),
				'zero' => q(afghani Afghanistan \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Afghanistan),
				'few' => q(afghani Afghanistan),
				'many' => q(afghani Afghanistan),
				'one' => q(afghani Afghanistan),
				'other' => q(afghani Afghanistan),
				'two' => q(afghani Afghanistan),
				'zero' => q(afghani Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Albania),
				'few' => q(lek Albania),
				'many' => q(lek Albania),
				'one' => q(lek Albania),
				'other' => q(lek Albania),
				'two' => q(lek Albania),
				'zero' => q(lek Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Armenia),
				'few' => q(dram Armenia),
				'many' => q(dram Armenia),
				'one' => q(dram Armenia),
				'other' => q(dram Armenia),
				'two' => q(dram Armenia),
				'zero' => q(dram Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder Antilles yr Iseldiroedd),
				'few' => q(guilder Antilles yr Iseldiroedd),
				'many' => q(guilder Antilles yr Iseldiroedd),
				'one' => q(guilder Antilles yr Iseldiroedd),
				'other' => q(guilder Antilles yr Iseldiroedd),
				'two' => q(guilder Antilles yr Iseldiroedd),
				'zero' => q(guilder Antilles yr Iseldiroedd),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angola),
				'few' => q(kwanza Angola),
				'many' => q(kwanza Angola),
				'one' => q(kwanza Angola),
				'other' => q(kwanza Angola),
				'two' => q(kwanza Angola),
				'zero' => q(kwanza Angola),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Kwanza Angola \(1977–1991\)),
				'few' => q(kwanza Angola \(1977 – 1991\)),
				'many' => q(kwanza Angola \(1977 – 1991\)),
				'one' => q(kwanza Angola \(1977 – 1991\)),
				'other' => q(kwanza Angola \(1977 – 1991\)),
				'two' => q(kwanza Angola \(1977 – 1991\)),
				'zero' => q(kwanza Angola \(1977 – 1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Kwanza Newydd Angola \(1990–2000\)),
				'few' => q(kwanza newydd Angola \(1999 – 2000\)),
				'many' => q(kwanza newydd Angola \(1999 – 2000\)),
				'one' => q(kwanza newydd Angola \(1999 – 2000\)),
				'other' => q(kwanza newydd Angola \(1999 – 2000\)),
				'two' => q(kwanza newydd Angola \(1999 – 2000\)),
				'zero' => q(kwanza newydd Angola \(1999 – 2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kwanza Ailgymhwysedig Angola \(1995–1999\)),
				'few' => q(kwanza ailgymhwysedig Angola \(1995 – 1999\)),
				'many' => q(kwanza ailgymhwysedig Angola \(1995 – 1999\)),
				'one' => q(kwanza ailgymhwysedig Angola \(1995 – 1999\)),
				'other' => q(kwanza ailgymhwysedig Angola \(1995 – 1999\)),
				'two' => q(kwanza ailgymhwysedig Angola \(1995 – 1999\)),
				'zero' => q(kwanza ailgymhwysedig Angola \(1995 – 1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austral yr Ariannin),
				'few' => q(austral yr Ariannin),
				'many' => q(austral yr Ariannin),
				'one' => q(austral yr Ariannin),
				'other' => q(austral yr Ariannin),
				'two' => q(austral yr Ariannin),
				'zero' => q(austral yr Ariannin),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Peso Ley yr Ariannin \(1970–1983\)),
				'few' => q(peso ley yr Ariannin \(1970–1983\)),
				'many' => q(peso ley yr Ariannin \(1970–1983\)),
				'one' => q(peso ley yr Ariannin \(1970–1983\)),
				'other' => q(peso ley yr Ariannin \(1970–1983\)),
				'two' => q(peso ley yr Ariannin \(1970–1983\)),
				'zero' => q(peso ley yr Ariannin \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Peso yr Ariannin \(1881–1970\)),
				'few' => q(peso yr Ariannin \(1881–1970\)),
				'many' => q(peso yr Ariannin \(1881–1970\)),
				'one' => q(peso yr Ariannin \(1881–1970\)),
				'other' => q(peso yr Ariannin \(1881–1970\)),
				'two' => q(peso yr Ariannin \(1881–1970\)),
				'zero' => q(peso yr Ariannin \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Peso yr Ariannin \(1983–1985\)),
				'few' => q(peso yr Ariannin \(1983–1985\)),
				'many' => q(peso yr Ariannin \(1983–1985\)),
				'one' => q(peso yr Ariannin \(1983–1985\)),
				'other' => q(peso yr Ariannin \(1983–1985\)),
				'two' => q(peso yr Ariannin \(1983–1985\)),
				'zero' => q(peso yr Ariannin \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso yr Ariannin),
				'few' => q(peso yr Ariannin),
				'many' => q(peso yr Ariannin),
				'one' => q(peso yr Ariannin),
				'other' => q(peso yr Ariannin),
				'two' => q(peso yr Ariannin),
				'zero' => q(peso yr Ariannin),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Swllt Awstria),
				'few' => q(swllt Awstria),
				'many' => q(swllt Awstria),
				'one' => q(swllt Awstria),
				'other' => q(swllt Awstria),
				'two' => q(swllt Awstria),
				'zero' => q(swllt Awstria),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Doler Awstralia),
				'few' => q(doler Awstralia),
				'many' => q(doler Awstralia),
				'one' => q(doler Awstralia),
				'other' => q(doler Awstralia),
				'two' => q(ddoler Awstralia),
				'zero' => q(doler Awstralia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Fflorin Aruba),
				'few' => q(fflorin Aruba),
				'many' => q(fflorin Aruba),
				'one' => q(fflorin Aruba),
				'other' => q(fflorin Aruba),
				'two' => q(fflorin Aruba),
				'zero' => q(fflorin Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Manat Azerbaijan \(1993–2006\)),
				'few' => q(manat Azerbaijan \(1993–2006\)),
				'many' => q(manat Azerbaijan \(1993–2006\)),
				'one' => q(manat Azerbaijan \(1993–2006\)),
				'other' => q(manat Azerbaijan \(1993–2006\)),
				'two' => q(manat Azerbaijan \(1993–2006\)),
				'zero' => q(manat Azerbaijan \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaijan),
				'few' => q(manat Azerbaijan),
				'many' => q(manat Azerbaijan),
				'one' => q(manat Azerbaijan),
				'other' => q(manat Azerbaijan),
				'two' => q(manat Azerbaijan),
				'zero' => q(manat Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marc Trosadwy Bosnia a Hercegovina),
				'few' => q(marc trosadwy Bosnia a Hercegovina),
				'many' => q(marc trosadwy Bosnia a Hercegovina),
				'one' => q(marc trosadwy Bosnia a Hercegovina),
				'other' => q(marc trosadwy Bosnia a Hercegovina),
				'two' => q(farc trosiadwy Bosnia a Hercegovina),
				'zero' => q(marc trosadwy Bosnia a Hercegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Doler Barbados),
				'few' => q(doler Barbados),
				'many' => q(doler Barbados),
				'one' => q(ddoler Barbados),
				'other' => q(doler Barbados),
				'two' => q(ddoler Barbados),
				'zero' => q(doler Barbados),
			},
		},
		'BDT' => {
			symbol => 'TK',
			display_name => {
				'currency' => q(Taka Bangladesh),
				'few' => q(taka Bangladesh),
				'many' => q(taka Bangladesh),
				'one' => q(taka Bangladesh),
				'other' => q(taka Bangladesh),
				'two' => q(taka Bangladesh),
				'zero' => q(taka Bangladesh),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Ffranc Gwlad Belg \(arnewidiol\)),
				'few' => q(ffranc Gwlad Belg \(arnewidiol\)),
				'many' => q(ffranc Gwlad Belg \(arnewidiol\)),
				'one' => q(ffranc Gwlad Belg \(arnewidiol\)),
				'other' => q(ffranc Gwlad Belg \(arnewidiol\)),
				'two' => q(ffranc Gwlad Belg \(arnewidiol\)),
				'zero' => q(ffranc Gwlad Belg \(arnewidiol\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Ffranc Gwlad Belg),
				'few' => q(ffranc Gwlad Belg),
				'many' => q(ffranc Gwlad Belg),
				'one' => q(ffranc Gwlad Belg),
				'other' => q(ffranc Gwlad Belg),
				'two' => q(ffranc Gwlad Belg),
				'zero' => q(ffranc Gwlad Belg),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Ffranc Gwlad Belg \(ariannol\)),
				'few' => q(ffranc Gwlad Belg \(ariannol\)),
				'many' => q(ffranc Gwlad Belg \(ariannol\)),
				'one' => q(ffranc Gwlad Belg \(ariannol\)),
				'other' => q(ffranc Gwlad Belg \(ariannol\)),
				'two' => q(ffranc Gwlad Belg \(ariannol\)),
				'zero' => q(ffranc Gwlad Belg \(ariannol\)),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Lev Sosialaidd Bwlgaria),
				'few' => q(lev sosialaidd Bwlgaria),
				'many' => q(lev sosialaidd Bwlgaria),
				'one' => q(lev sosialaidd Bwlgaria),
				'other' => q(lev sosialaidd Bwlgaria),
				'two' => q(lev sosialaidd Bwlgaria),
				'zero' => q(lev sosialaidd Bwlgaria),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bwlgaria),
				'few' => q(lev Bwlgaria),
				'many' => q(lev Bwlgaria),
				'one' => q(lev Bwlgaria),
				'other' => q(lev Bwlgaria),
				'two' => q(lev Bwlgaria),
				'zero' => q(lev Bwlgaria),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Lev Bwlgaria \(1879–1952\)),
				'few' => q(lev Bwlgaria \(1879 – 1952\)),
				'many' => q(lev Bwlgaria \(1879 – 1952\)),
				'one' => q(lev Bwlgaria \(1879 – 1952\)),
				'other' => q(lev Bwlgaria \(1879 – 1952\)),
				'two' => q(lev Bwlgaria \(1879 – 1952\)),
				'zero' => q(lev Bwlgaria \(1879 – 1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bahrain),
				'few' => q(dinar Bahrain),
				'many' => q(dinar Bahrain),
				'one' => q(dinar Bahrain),
				'other' => q(dinar Bahrain),
				'two' => q(dinar Bahrain),
				'zero' => q(dinar Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Ffranc Burundi),
				'few' => q(ffranc Burundi),
				'many' => q(ffranc Burundi),
				'one' => q(ffranc Burundi),
				'other' => q(ffranc Burundi),
				'two' => q(ffranc Burundi),
				'zero' => q(ffranc Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Doler Bermuda),
				'few' => q(doler Bermuda),
				'many' => q(doler Bermuda),
				'one' => q(doler Bermuda),
				'other' => q(doler Bermuda),
				'two' => q(ddoler Bermuda),
				'zero' => q(doler Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Doler Brunei),
				'few' => q(doler Brunei),
				'many' => q(doler Brunei),
				'one' => q(doler Brunei),
				'other' => q(doler Brunei),
				'two' => q(ddoler Brunei),
				'zero' => q(doler Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Bolifia),
				'few' => q(boliviano Bolifia),
				'many' => q(boliviano Bolifia),
				'one' => q(boliviano Bolifia),
				'other' => q(boliviano Bolifia),
				'two' => q(boliviano Bolifia),
				'zero' => q(boliviano Bolifia),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliviano Bolifia \(1863–1963\)),
				'few' => q(boliviano Bolifia \(1863–1963\)),
				'many' => q(boliviano Bolifia \(1863–1963\)),
				'one' => q(boliviano Bolifia \(1863–1963\)),
				'other' => q(boliviano Bolifia \(1863–1963\)),
				'two' => q(boliviano Bolifia \(1863–1963\)),
				'zero' => q(boliviano Bolifia \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Peso Bolifia),
				'few' => q(peso Bolifia),
				'many' => q(peso Bolifia),
				'one' => q(peso Bolifia),
				'other' => q(peso Bolifia),
				'two' => q(peso Bolifia),
				'zero' => q(peso Bolifia),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Mvdol Bolifia),
				'few' => q(mvdol Bolifia),
				'many' => q(mvdol Bolifia),
				'one' => q(mvdol Bolifia),
				'other' => q(mvdol Bolifia),
				'two' => q(mvdol Bolifia),
				'zero' => q(mvdol Bolifia),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Cruzeiro Newydd Brasil \(1967–1986\)),
				'few' => q(cruzeiro newydd Brasil \(1967–1986\)),
				'many' => q(cruzeiro newydd Brasil \(1967–1986\)),
				'one' => q(cruzeiro newydd Brasil \(1967–1986\)),
				'other' => q(cruzeiro newydd Brasil \(1967–1986\)),
				'two' => q(cruzeiro newydd Brasil \(1967–1986\)),
				'zero' => q(cruzeiro newydd Brasil \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Cruzado Brasil \(1986–1989\)),
				'few' => q(cruzado Brasil \(1986–1989\)),
				'many' => q(cruzado Brasil \(1986–1989\)),
				'one' => q(cruzado Brasil \(1986–1989\)),
				'other' => q(cruzado Brasil \(1986–1989\)),
				'two' => q(cruzado Brasil \(1986–1989\)),
				'zero' => q(cruzado Brasil \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1990–1993\)),
				'few' => q(cruzeiro Brasil \(1990–1993\)),
				'many' => q(cruzeiro Brasil \(1990–1993\)),
				'one' => q(cruzeiro Brasil \(1990–1993\)),
				'other' => q(cruzeiro Brasil \(1990–1993\)),
				'two' => q(cruzeiro Brasil \(1990–1993\)),
				'zero' => q(cruzeiro Brasil \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasil),
				'few' => q(real Brasil),
				'many' => q(real Brasil),
				'one' => q(real Brasil),
				'other' => q(real Brasil),
				'two' => q(real Brasil),
				'zero' => q(real Brasil),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Cruzado Newydd Brasil \(1989–1990\)),
				'few' => q(cruzado newydd Brasil \(1989–1990\)),
				'many' => q(cruzado newydd Brasil \(1989–1990\)),
				'one' => q(cruzado newydd Brasil \(1989–1990\)),
				'other' => q(cruzado newydd Brasil \(1989–1990\)),
				'two' => q(cruzado newydd Brasil \(1989–1990\)),
				'zero' => q(cruzado newydd Brasil \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1993–1994\)),
				'few' => q(cruzeiro Brasil \(1993–1994\)),
				'many' => q(cruzeiro Brasil \(1993–1994\)),
				'one' => q(cruzeiro Brasil \(1993–1994\)),
				'other' => q(cruzeiro Brasil \(1993–1994\)),
				'two' => q(cruzeiro Brasil \(1993–1994\)),
				'zero' => q(cruzeiro Brasil \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Cruzeiro Brasil \(1942–1967\)),
				'few' => q(cruzeiro Brasil \(1942–1967\)),
				'many' => q(cruzeiro Brasil \(1942–1967\)),
				'one' => q(cruzeiro Brasil \(1942–1967\)),
				'other' => q(cruzeiro Brasil \(1942–1967\)),
				'two' => q(cruzeiro Brasil \(1942–1967\)),
				'zero' => q(cruzeiro Brasil \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Doler y Bahamas),
				'few' => q(doler y Bahamas),
				'many' => q(doler y Bahamas),
				'one' => q(doler y Bahamas),
				'other' => q(doler y Bahamas),
				'two' => q(ddoler y Bahamas),
				'zero' => q(doler y Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Bhutan),
				'few' => q(ngultrum Bhutan),
				'many' => q(ngultrum Bhutan),
				'one' => q(ngultrum Bhutan),
				'other' => q(ngultrum Bhutan),
				'two' => q(ngultrum Bhutan),
				'zero' => q(ngultrum Bhutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kyat Byrma),
				'few' => q(kyat Byrma),
				'many' => q(kyat Byrma),
				'one' => q(kyat Byrma),
				'other' => q(kyat Byrma),
				'two' => q(kyat Byrma),
				'zero' => q(kyat Byrma),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula Botswana),
				'few' => q(pula Botswana),
				'many' => q(pula Botswana),
				'one' => q(pula Botswana),
				'other' => q(pula Botswana),
				'two' => q(pula Botswana),
				'zero' => q(pula Botswana),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rwbl Belarws),
				'few' => q(rwbl Belarws),
				'many' => q(rwbl Belarws),
				'one' => q(rwbl Belarws),
				'other' => q(rwbl Belarws),
				'two' => q(rwbl Belarws),
				'zero' => q(rwbl Belarws),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rwbl Belarws \(2000–2016\)),
				'few' => q(rwbl Belarws \(2000–2016\)),
				'many' => q(rwbl Belarws \(2000–2016\)),
				'one' => q(rwbl Belarws \(2000–2016\)),
				'other' => q(rwbl Belarws \(2000–2016\)),
				'two' => q(rwbl Belarws \(2000–2016\)),
				'zero' => q(rwbl Belarws \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Doler Belize),
				'few' => q(doler Belize),
				'many' => q(doler Belize),
				'one' => q(doler Belize),
				'other' => q(doler Belize),
				'two' => q(ddoler Belize),
				'zero' => q(doler Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Doler Canada),
				'few' => q(doler Canada),
				'many' => q(doler Canada),
				'one' => q(doler Canada),
				'other' => q(doler Canada),
				'two' => q(doler Canada),
				'zero' => q(doler Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Ffranc Congo),
				'few' => q(ffranc Congo),
				'many' => q(ffranc Congo),
				'one' => q(ffranc Congo),
				'other' => q(ffranc Congo),
				'two' => q(ffranc Congo),
				'zero' => q(ffranc Congo),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Ewro WIR),
				'few' => q(ewro WIR),
				'many' => q(ewro WIR),
				'one' => q(ewro WIR),
				'other' => q(ewro WIR),
				'two' => q(ewro WIR),
				'zero' => q(ewro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Ffranc y Swistir),
				'few' => q(ffranc y Swistir),
				'many' => q(ffranc y Swistir),
				'one' => q(ffranc y Swistir),
				'other' => q(ffranc y Swistir),
				'two' => q(ffranc y Swistir),
				'zero' => q(ffranc y Swistir),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Ffranc WIR),
				'few' => q(ffranc WIR),
				'many' => q(ffranc WIR),
				'one' => q(ffranc WIR),
				'other' => q(ffranc WIR),
				'two' => q(ffranc WIR),
				'zero' => q(ffranc WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Escudo Chile),
				'few' => q(escudo Chile),
				'many' => q(escudo Chile),
				'one' => q(escudo Chile),
				'other' => q(escudo Chile),
				'two' => q(escudo Chile),
				'zero' => q(escudo Chile),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Uned Cyfrifo Chile \(UF\)),
				'few' => q(uned cyfrifo Chile \(UF\)),
				'many' => q(uned cyfrifo Chile \(UF\)),
				'one' => q(uned cyfrifo Chile \(UF\)),
				'other' => q(uned cyfrifo Chile \(UF\)),
				'two' => q(uned cyfrifo Chile \(UF\)),
				'zero' => q(uned cyfrifo Chile \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Chile),
				'few' => q(peso Chile),
				'many' => q(peso Chile),
				'one' => q(peso Chile),
				'other' => q(peso Chile),
				'two' => q(peso Chile),
				'zero' => q(peso Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Tsieina \(ar y môr\)),
				'few' => q(yuan Tsieina \(ar y môr\)),
				'many' => q(yuan Tsieina \(ar y môr\)),
				'one' => q(yuan Tsieina \(ar y môr\)),
				'other' => q(yuan Tsieina \(ar y môr\)),
				'two' => q(yuan Tsieina \(ar y môr\)),
				'zero' => q(yuan Tsieina \(ar y môr\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Doler Banc Pobl Tsieina),
				'few' => q(doler Banc Pobl Tsieina),
				'many' => q(doler Banc Pobl Tsieina),
				'one' => q(ddoler Banc Pobl Tsieina),
				'other' => q(doler Banc Pobl Tsieina),
				'two' => q(ddoler Banc Pobl Tsieina),
				'zero' => q(doler Banc Pobl Tsieina),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Tsieina),
				'few' => q(yuan Tsieina),
				'many' => q(yuan Tsieina),
				'one' => q(yuan Tsieina),
				'other' => q(yuan Tsieina),
				'two' => q(yuan Tsieina),
				'zero' => q(yuan Tsieina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Colombia),
				'few' => q(peso Colombia),
				'many' => q(peso Colombia),
				'one' => q(peso Colombia),
				'other' => q(peso Colombia),
				'two' => q(peso Colombia),
				'zero' => q(peso Colombia),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Uned Gwir Werth Colombia),
				'few' => q(uned gwir werth Colombia),
				'many' => q(uned gwir werth Colombia),
				'one' => q(uned gwir werth Colombia),
				'other' => q(uned gwir werth Colombia),
				'two' => q(uned gwir werth Colombia),
				'zero' => q(uned gwir werth Colombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón Costa Rica),
				'few' => q(colón Costa Rica),
				'many' => q(colón Costa Rica),
				'one' => q(colón Costa Rica),
				'other' => q(colón Costa Rica),
				'two' => q(colón Costa Rica),
				'zero' => q(colón Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Trosadwy Ciwba),
				'few' => q(peso trosadwy Ciwba),
				'many' => q(peso trosadwy Ciwba),
				'one' => q(peso trosadwy Ciwba),
				'other' => q(peso trosadwy Ciwba),
				'two' => q(peso trosadwy Ciwba),
				'zero' => q(peso trosadwy Ciwba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Ciwba),
				'few' => q(peso Ciwba),
				'many' => q(peso Ciwba),
				'one' => q(peso Ciwba),
				'other' => q(peso Ciwba),
				'two' => q(peso Ciwba),
				'zero' => q(peso Ciwba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esgwdo Cabo Verde),
				'few' => q(esgwdo Cabo Verde),
				'many' => q(esgwdo Cabo Verde),
				'one' => q(esgwdo Cabo Verde),
				'other' => q(esgwdo Cabo Verde),
				'two' => q(esgwdo Cabo Verde),
				'zero' => q(esgwdo Cabo Verde),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Punt Cyprus),
				'few' => q(punt Cyprus),
				'many' => q(punt Cyprus),
				'one' => q(bunt Cyprus),
				'other' => q(punt Cyprus),
				'two' => q(bunt Cyprus),
				'zero' => q(punt Cyprus),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna’r Weriniaeth Tsiec),
				'few' => q(koruna’r Weriniaeth Tsiec),
				'many' => q(koruna’r Weriniaeth Tsiec),
				'one' => q(koruna’r Weriniaeth Tsiec),
				'other' => q(koruna’r Weriniaeth Tsiec),
				'two' => q(koruna’r Weriniaeth Tsiec),
				'zero' => q(koruna’r Weriniaeth Tsiec),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Marc Dwyrain yr Almaen),
				'few' => q(marc Dwyrain yr Almaen),
				'many' => q(marc Dwyrain yr Almaen),
				'one' => q(marc Dwyrain yr Almaen),
				'other' => q(marc Dwyrain yr Almaen),
				'two' => q(marc Dwyrain yr Almaen),
				'zero' => q(marc Dwyrain yr Almaen),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Marc yr Almaen),
				'few' => q(marc yr Almaen),
				'many' => q(marc yr Almaen),
				'one' => q(marc yr Almaen),
				'other' => q(marc yr Almaen),
				'two' => q(marc yr Almaen),
				'zero' => q(marc yr Almaen),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Ffranc Djibouti),
				'few' => q(ffranc Djibouti),
				'many' => q(ffranc Djibouti),
				'one' => q(ffranc Djibouti),
				'other' => q(ffranc Djibouti),
				'two' => q(ffranc Djibouti),
				'zero' => q(ffranc Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Denmarc),
				'few' => q(krone Denmarc),
				'many' => q(krone Denmarc),
				'one' => q(krone Denmarc),
				'other' => q(krone Denmarc),
				'two' => q(krone Denmarc),
				'zero' => q(krone Denmarc),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Gweriniaeth Dominica),
				'few' => q(peso Gweriniaeth Dominica),
				'many' => q(peso Gweriniaeth Dominica),
				'one' => q(peso Gweriniaeth Dominica),
				'other' => q(peso Gweriniaeth Dominica),
				'two' => q(peso Gweriniaeth Dominica),
				'zero' => q(peso Gweriniaeth Dominica),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Algeria),
				'few' => q(dinar Algeria),
				'many' => q(dinar Algeria),
				'one' => q(dinar Algeria),
				'other' => q(dinar Algeria),
				'two' => q(dinar Algeria),
				'zero' => q(dinar Algeria),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre Ecuador),
				'few' => q(sucre Ecuador),
				'many' => q(sucre Ecuador),
				'one' => q(sucre Ecuador),
				'other' => q(sucre Ecuador),
				'two' => q(sucre Ecuador),
				'zero' => q(sucre Ecuador),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Uned Gwerth Gyson Ecuador),
				'few' => q(uned gwerth gyson Ecuador),
				'many' => q(uned gwerth gyson Ecuador),
				'one' => q(uned gwerth gyson Ecuador),
				'other' => q(uned gwerth gyson Ecuador),
				'two' => q(uned gwerth gyson Ecuador),
				'zero' => q(uned gwerth gyson Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Kroon Estonia),
				'few' => q(kroon Estonia),
				'many' => q(kroon Estonia),
				'one' => q(kroon Estonia),
				'other' => q(kroon Estonia),
				'two' => q(kroon Estonia),
				'zero' => q(kroon Estonia),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Punt Yr Aifft),
				'few' => q(punt yr Aifft),
				'many' => q(punt yr Aifft),
				'one' => q(punt yr Aifft),
				'other' => q(punt yr Aifft),
				'two' => q(bunt yr Aifft),
				'zero' => q(punt yr Aifft),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritrea),
				'few' => q(nakfa Eritrea),
				'many' => q(nakfa Eritrea),
				'one' => q(nakfa Eritrea),
				'other' => q(nakfa Eritrea),
				'two' => q(nakfa Eritrea),
				'zero' => q(nakfa Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Ethiopia),
				'few' => q(birr Ethiopia),
				'many' => q(birr Ethiopia),
				'one' => q(birr Ethiopia),
				'other' => q(birr Ethiopia),
				'two' => q(birr Ethiopia),
				'zero' => q(birr Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Ewro),
				'few' => q(ewro),
				'many' => q(ewro),
				'one' => q(ewro),
				'other' => q(ewro),
				'two' => q(ewro),
				'zero' => q(ewro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Markka’r Ffindir),
				'few' => q(markka’r Ffindir),
				'many' => q(markka’r Ffindir),
				'one' => q(markka’r Ffindir),
				'other' => q(markka’r Ffindir),
				'two' => q(markka’r Ffindir),
				'zero' => q(markka’r Ffindir),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Doler Ffiji),
				'few' => q(doler Ffiji),
				'many' => q(doler Ffiji),
				'one' => q(doler Ffiji),
				'other' => q(doler Ffiji),
				'two' => q(ddoler Ffiji),
				'zero' => q(doler Ffiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Punt Ynysoedd Falkland/Malvinas),
				'few' => q(punt Ynysoedd Falkland/Malvinas),
				'many' => q(punt Ynysoedd Falkland/Malvinas),
				'one' => q(punt Ynysoedd Falkland/Malvinas),
				'other' => q(punt Ynysoedd Falkland/Malvinas),
				'two' => q(bunt Ynysoedd Falkland/Malvinas),
				'zero' => q(punt Ynysoedd Falkland/Malvinas),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Ffranc Ffrainc),
				'few' => q(ffranc Ffrainc),
				'many' => q(ffranc Ffrainc),
				'one' => q(ffranc Ffrainc),
				'other' => q(ffranc Ffrainc),
				'two' => q(ffranc Ffrainc),
				'zero' => q(ffranc Ffrainc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Punt Prydain),
				'few' => q(punt Prydain),
				'many' => q(punt Prydain),
				'one' => q(bunt Prydain),
				'other' => q(punt Prydain),
				'two' => q(bunt Prydain),
				'zero' => q(punt Prydain),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Kupon Larit Georgia),
				'few' => q(kupon larit Georgia),
				'many' => q(kupon larit Georgia),
				'one' => q(kupon larit Georgia),
				'other' => q(kupon larit Georgia),
				'two' => q(kupon larit Georgia),
				'zero' => q(kupon larit Georgia),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgia),
				'few' => q(lari Georgia),
				'many' => q(lari Georgia),
				'one' => q(lari Georgia),
				'other' => q(lari Georgia),
				'two' => q(lari Georgia),
				'zero' => q(lari Georgia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi Ghana \(1979–2007\)),
				'few' => q(cedi Ghana \(1979–2007\)),
				'many' => q(cedi Ghana \(1979–2007\)),
				'one' => q(cedi Ghana \(1979–2007\)),
				'other' => q(cedi Ghana \(1979–2007\)),
				'two' => q(cedi Ghana \(1979–2007\)),
				'zero' => q(cedi Ghana \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghana),
				'few' => q(cedi Ghana),
				'many' => q(cedi Ghana),
				'one' => q(cedi Ghana),
				'other' => q(cedi Ghana),
				'two' => q(cedi Ghana),
				'zero' => q(cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Punt Gibraltar),
				'few' => q(punt Gibraltar),
				'many' => q(punt Gibraltar),
				'one' => q(punt Gibraltar),
				'other' => q(punt Gibraltar),
				'two' => q(bunt Gibraltar),
				'zero' => q(punt Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gambia),
				'few' => q(dalasi Gambia),
				'many' => q(dalasi Gambia),
				'one' => q(dalasi Gambia),
				'other' => q(dalasi Gambia),
				'two' => q(dalasi Gambia),
				'zero' => q(dalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Ffranc Guinée),
				'few' => q(ffranc Guinée),
				'many' => q(ffranc Guinée),
				'one' => q(ffranc Guinée),
				'other' => q(ffranc Guinée),
				'two' => q(ffranc Guinée),
				'zero' => q(ffranc Guinée),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli Guinée),
				'few' => q(syli Guinée),
				'many' => q(syli Guinée),
				'one' => q(syli Guinée),
				'other' => q(syli Guinée),
				'two' => q(syli Guinée),
				'zero' => q(syli Guinée),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekwele Guinea Gyhydeddol),
				'few' => q(ekwele Guinea Gyhydeddol),
				'many' => q(ekwele Guinea Gyhydeddol),
				'one' => q(ekwele Guinea Gyhydeddol),
				'other' => q(ekwele Guinea Gyhydeddol),
				'two' => q(ekwele Guinea Gyhydeddol),
				'zero' => q(ekwele Guinea Gyhydeddol),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemala),
				'few' => q(quetzal Guatemala),
				'many' => q(quetzal Guatemala),
				'one' => q(quetzal Guatemala),
				'other' => q(quetzal Guatemala),
				'two' => q(quetzal Guatemala),
				'zero' => q(quetzal Guatemala),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Peso Guiné-Bissau),
				'few' => q(peso Guiné-Bissau),
				'many' => q(peso Guiné-Bissau),
				'one' => q(peso Guiné-Bissau),
				'other' => q(peso Guiné-Bissau),
				'two' => q(peso Guiné-Bissau),
				'zero' => q(peso Guiné-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Doler Guyana),
				'few' => q(doler Guyana),
				'many' => q(doler Guyana),
				'one' => q(doler Guyana),
				'other' => q(doler Guyana),
				'two' => q(ddoler Guyana),
				'zero' => q(doler Guyana),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Doler Hong Kong),
				'few' => q(doler Hong Kong),
				'many' => q(doler Hong Kong),
				'one' => q(doler Hong Kong),
				'other' => q(doler Hong Kong),
				'two' => q(ddoler Hong Kong),
				'zero' => q(doler Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Honduras),
				'few' => q(lempira Honduras),
				'many' => q(lempira Honduras),
				'one' => q(lempira Honduras),
				'other' => q(lempira Honduras),
				'two' => q(lempira Honduras),
				'zero' => q(lempira Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Croatia),
				'few' => q(kuna Croatia),
				'many' => q(kuna Croatia),
				'one' => q(kuna Croatia),
				'other' => q(kuna Croatia),
				'two' => q(kuna Croatia),
				'zero' => q(kuna Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
				'few' => q(gourde Haiti),
				'many' => q(gourde Haiti),
				'one' => q(gourde Haiti),
				'other' => q(gourde Haiti),
				'two' => q(gourde Haiti),
				'zero' => q(gourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Fforint Hwngari),
				'few' => q(fforint Hwngari),
				'many' => q(fforint Hwngari),
				'one' => q(fforint Hwngari),
				'other' => q(fforint Hwngari),
				'two' => q(fforint Hwngari),
				'zero' => q(fforint Hwngari),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah Indonesia),
				'few' => q(rupiah Indonesia),
				'many' => q(rupiah Indonesia),
				'one' => q(rupiah Indonesia),
				'other' => q(rupiah Indonesia),
				'two' => q(rupiah Indonesia),
				'zero' => q(rupiah Indonesia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Punt Iwerddon),
				'few' => q(punt Iwerddon),
				'many' => q(phunt Iwerddon),
				'one' => q(bunt Iwerddon),
				'other' => q(punt Iwerddon),
				'two' => q(bunt Iwerddon),
				'zero' => q(punt Iwerddon),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Punt Israel),
				'few' => q(punt Israel),
				'many' => q(phunt Israel),
				'one' => q(bunt Israel),
				'other' => q(punt Israel),
				'two' => q(bunt Israel),
				'zero' => q(punt Israel),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Shegel Israel \(1980–1985\)),
				'few' => q(shegel Israel \(1980–1985\)),
				'many' => q(shegel Israel \(1980–1985\)),
				'one' => q(shegel Israel \(1980–1985\)),
				'other' => q(shegel Israel \(1980–1985\)),
				'two' => q(shegel Israel \(1980–1985\)),
				'zero' => q(shegel Israel \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Shegel Newydd Israel),
				'few' => q(shegel newydd Israel),
				'many' => q(shegel newydd Israel),
				'one' => q(shegel newydd Israel),
				'other' => q(shegel newydd Israel),
				'two' => q(shegel newydd Israel),
				'zero' => q(shegel newydd Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rwpî India),
				'few' => q(rwpî India),
				'many' => q(rwpî India),
				'one' => q(rwpî India),
				'other' => q(rwpî India),
				'two' => q(rwpî India),
				'zero' => q(rwpî India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Irac),
				'few' => q(dinar Irac),
				'many' => q(dinar Irac),
				'one' => q(dinar Irac),
				'other' => q(dinar Irac),
				'two' => q(dinar Irac),
				'zero' => q(dinar Irac),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iran),
				'few' => q(rial Iran),
				'many' => q(rial Iran),
				'one' => q(rial Iran),
				'other' => q(rial Iran),
				'two' => q(rial Iran),
				'zero' => q(rial Iran),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Króna Gwlad yr Iâ \(1918 – 1981\)),
				'few' => q(króna Gwlad yr Iâ \(1918 – 1981\)),
				'many' => q(króna Gwlad yr Iâ \(1918 – 1981\)),
				'one' => q(króna Gwlad yr Iâ \(1918 – 1981\)),
				'other' => q(króna Gwlad yr Iâ \(1918 – 1981\)),
				'two' => q(króna Gwlad yr Iâ \(1918 – 1981\)),
				'zero' => q(króna Gwlad yr Iâ \(1918 – 1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Króna Gwlad yr Iâ),
				'few' => q(króna Gwlad yr Iâ),
				'many' => q(króna Gwlad yr Iâ),
				'one' => q(króna Gwlad yr Iâ),
				'other' => q(króna Gwlad yr Iâ),
				'two' => q(króna Gwlad yr Iâ),
				'zero' => q(króna Gwlad yr Iâ),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Doler Jamaica),
				'few' => q(doler Jamaica),
				'many' => q(doler Jamaica),
				'one' => q(doler Jamaica),
				'other' => q(doler Jamaica),
				'two' => q(ddoler Jamaica),
				'zero' => q(doler Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Gwlad yr Iorddonen),
				'few' => q(dinar Gwlad yr Iorddonen),
				'many' => q(dinar Gwlad yr Iorddonen),
				'one' => q(dinar Gwlad yr Iorddonen),
				'other' => q(dinar Gwlad yr Iorddonen),
				'two' => q(dinar Gwlad yr Iorddonen),
				'zero' => q(dinar Gwlad yr Iorddonen),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Japan),
				'few' => q(yen Japan),
				'many' => q(yen Japan),
				'one' => q(yen Japan),
				'other' => q(yen Japan),
				'two' => q(yen Japan),
				'zero' => q(yen Japan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Swllt Kenya),
				'few' => q(swllt Kenya),
				'many' => q(swllt Kenya),
				'one' => q(swllt Kenya),
				'other' => q(swllt Kenya),
				'two' => q(swllt Kenya),
				'zero' => q(swllt Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kyrgyzstan),
				'few' => q(som Kyrgyzstan),
				'many' => q(som Kyrgyzstan),
				'one' => q(som Kyrgyzstan),
				'other' => q(som Kyrgyzstan),
				'two' => q(som Kyrgyzstan),
				'zero' => q(som Kyrgyzstan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Cambodia),
				'few' => q(riel Cambodia),
				'many' => q(riel Cambodia),
				'one' => q(riel Cambodia),
				'other' => q(riel Cambodia),
				'two' => q(riel Cambodia),
				'zero' => q(riel Cambodia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Ffranc Comoros),
				'few' => q(ffranc Comoros),
				'many' => q(ffranc Comoros),
				'one' => q(ffranc Comoros),
				'other' => q(ffranc Comoros),
				'two' => q(ffranc Comoros),
				'zero' => q(ffranc Comoros),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Gogledd Corea),
				'few' => q(won Gogledd Corea),
				'many' => q(won Gogledd Corea),
				'one' => q(won Gogledd Corea),
				'other' => q(won Gogledd Corea),
				'two' => q(won Gogledd Corea),
				'zero' => q(won Gogledd Corea),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Hwan De Corea \(1953–1962\)),
				'few' => q(hwan De Corea \(1953–1962\)),
				'many' => q(hwan De Corea \(1953–1962\)),
				'one' => q(hwan De Corea \(1953–1962\)),
				'other' => q(hwan De Corea \(1953–1962\)),
				'two' => q(hwan De Corea \(1953–1962\)),
				'zero' => q(hwan De Corea \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Won De Corea \(1945–1953\)),
				'few' => q(won De Corea \(1945–1953\)),
				'many' => q(won De Corea \(1945–1953\)),
				'one' => q(won De Corea \(1945–1953\)),
				'other' => q(won De Corea \(1945–1953\)),
				'two' => q(won De Corea \(1945–1953\)),
				'zero' => q(won De Corea \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(Won De Corea),
				'few' => q(won De Corea),
				'many' => q(won De Corea),
				'one' => q(won De Corea),
				'other' => q(won De Corea),
				'two' => q(won De Corea),
				'zero' => q(won De Corea),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwait),
				'few' => q(dinar Kuwait),
				'many' => q(dinar Kuwait),
				'one' => q(dinar Kuwait),
				'other' => q(dinar Kuwait),
				'two' => q(dinar Kuwait),
				'zero' => q(dinar Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Doler Ynysoedd Cayman),
				'few' => q(doler Ynysoedd Cayman),
				'many' => q(doler Ynysoedd Cayman),
				'one' => q(doler Ynysoedd Cayman),
				'other' => q(doler Ynysoedd Cayman),
				'two' => q(ddoler Ynysoedd Cayman),
				'zero' => q(doler Ynysoedd Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Kazakstan),
				'few' => q(tenge Kazakstan),
				'many' => q(tenge Kazakstan),
				'one' => q(tenge Kazakstan),
				'other' => q(tenge Kazakstan),
				'two' => q(tenge Kazakstan),
				'zero' => q(tenge Kazakstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laos),
				'few' => q(kip Laos),
				'many' => q(kip Laos),
				'one' => q(kip Laos),
				'other' => q(kip Laos),
				'two' => q(kip Laos),
				'zero' => q(kip Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Punt Libanus),
				'few' => q(punt Libanus),
				'many' => q(punt Libanus),
				'one' => q(punt Libanus),
				'other' => q(punt Libanus),
				'two' => q(bunt Libanus),
				'zero' => q(punt Libanus),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rwpî Sri Lanka),
				'few' => q(rwpî Sri Lanka),
				'many' => q(rwpî Sri Lanka),
				'one' => q(rwpî Sri Lanka),
				'other' => q(rwpî Sri Lanka),
				'two' => q(rwpî Sri Lanka),
				'zero' => q(rwpî Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Doler Liberia),
				'few' => q(doler Liberia),
				'many' => q(doler Liberia),
				'one' => q(ddoler Liberia),
				'other' => q(doler Liberia),
				'two' => q(ddoler Liberia),
				'zero' => q(doler Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Lesotho),
				'few' => q(loti Lesotho),
				'many' => q(loti Lesotho),
				'one' => q(loti Lesotho),
				'other' => q(loti Lesotho),
				'two' => q(loti Lesotho),
				'zero' => q(loti Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas Lithwania),
				'few' => q(litas Lithwania),
				'many' => q(litas Lithwania),
				'one' => q(litas Lithwania),
				'other' => q(litas Lithwania),
				'two' => q(litas Lithwania),
				'zero' => q(litas Lithwania),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Talonas Lithwania),
				'few' => q(talonas Lithwania),
				'many' => q(talonas Lithwania),
				'one' => q(talonas Lithwania),
				'other' => q(talonas Lithwania),
				'two' => q(talonas Lithwania),
				'zero' => q(talonas Lithwania),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Ffranc Lwcsembwrg),
				'few' => q(ffranc Lwcsembwrg),
				'many' => q(ffranc Lwcsembwrg),
				'one' => q(ffranc Lwcsembwrg),
				'other' => q(ffranc Lwcsembwrg),
				'two' => q(ffranc Lwcsembwrg),
				'zero' => q(ffranc Lwcsembwrg),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats Latfia),
				'few' => q(lats Latfia),
				'many' => q(lats Latfia),
				'one' => q(lats Latfia),
				'other' => q(lats Latfia),
				'two' => q(lats Latfia),
				'zero' => q(lats Latfia),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rwbl Latfia),
				'few' => q(rwbl Latfia),
				'many' => q(rwbl Latfia),
				'one' => q(rwbl Latfia),
				'other' => q(rwbl Latfia),
				'two' => q(rwbl Latfia),
				'zero' => q(rwbl Latfia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libya),
				'few' => q(dinar Libya),
				'many' => q(dinar Libya),
				'one' => q(dinar Libya),
				'other' => q(dinar Libya),
				'two' => q(dinar Libya),
				'zero' => q(dinar Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Moroco),
				'few' => q(dirham Moroco),
				'many' => q(dirham Moroco),
				'one' => q(dirham Moroco),
				'other' => q(dirham Moroco),
				'two' => q(dirham Moroco),
				'zero' => q(dirham Moroco),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Ffranc Moroco),
				'few' => q(ffranc Moroco),
				'many' => q(ffranc Moroco),
				'one' => q(ffranc Moroco),
				'other' => q(ffranc Moroco),
				'two' => q(ffranc Moroco),
				'zero' => q(ffranc Moroco),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Ffranc Monaco),
				'few' => q(ffranc Monaco),
				'many' => q(ffranc Monaco),
				'one' => q(ffranc Monaco),
				'other' => q(ffranc Monaco),
				'two' => q(ffranc Monaco),
				'zero' => q(ffranc Monaco),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldofa),
				'few' => q(leu Moldofa),
				'many' => q(leu Moldofa),
				'one' => q(leu Moldofa),
				'other' => q(leu Moldofa),
				'two' => q(leu Moldofa),
				'zero' => q(leu Moldofa),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Madagascar),
				'few' => q(ariary Madagascar),
				'many' => q(ariary Madagascar),
				'one' => q(ariary Madagascar),
				'other' => q(ariary Madagascar),
				'two' => q(ariary Madagascar),
				'zero' => q(ariary Madagascar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Ffranc Madagascar),
				'few' => q(ffranc Madagascar),
				'many' => q(ffranc Madagascar),
				'one' => q(ffranc Madagascar),
				'other' => q(ffranc Madagascar),
				'two' => q(ffranc Madagascar),
				'zero' => q(ffranc Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Macedonia),
				'few' => q(denar Macedonia),
				'many' => q(denar Macedonia),
				'one' => q(denar Macedonia),
				'other' => q(denar Macedonia),
				'two' => q(denar Macedonia),
				'zero' => q(denar Macedonia),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Ffranc Mali),
				'few' => q(ffranc Mali),
				'many' => q(ffranc Mali),
				'one' => q(ffranc Mali),
				'other' => q(ffranc Mali),
				'two' => q(ffranc Mali),
				'zero' => q(ffranc Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Myanmar),
				'few' => q(kyat Myanmar),
				'many' => q(kyat Myanmar),
				'one' => q(kyat Myanmar),
				'other' => q(kyat Myanmar),
				'two' => q(kyat Myanmar),
				'zero' => q(kyat Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongolia),
				'few' => q(tugrik Mongolia),
				'many' => q(tugrik Mongolia),
				'one' => q(tugrik Mongolia),
				'other' => q(tugrik Mongolia),
				'two' => q(tugrik Mongolia),
				'zero' => q(tugrik Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania \(1973–2017\)),
				'few' => q(ouguiya Mauritania \(1973–2017\)),
				'many' => q(ouguiya Mauritania \(1973–2017\)),
				'one' => q(ouguiya Mauritania \(1973–2017\)),
				'other' => q(ouguiya Mauritania \(1973–2017\)),
				'two' => q(ouguiya Mauritania \(1973–2017\)),
				'zero' => q(ouguiya Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania),
				'few' => q(ouguiya Mauritania),
				'many' => q(ouguiya Mauritania),
				'one' => q(ouguiya Mauritania),
				'other' => q(ouguiya Mauritania),
				'two' => q(ouguiya Mauritania),
				'zero' => q(ouguiya Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rwpî Mauritius),
				'few' => q(rwpî Mauritius),
				'many' => q(rwpî Mauritius),
				'one' => q(rwpî Mauritius),
				'other' => q(rwpî Mauritius),
				'two' => q(rwpî Mauritius),
				'zero' => q(rwpî Mauritius),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Rwpî’r Maldives \(1947–1981\)),
				'few' => q(rwpî’r Maldives \(1947–1981\)),
				'many' => q(rwpî’r Maldives \(1947–1981\)),
				'one' => q(rwpî’r Maldives \(1947–1981\)),
				'other' => q(rwpî’r Maldives \(1947–1981\)),
				'two' => q(rwpî’r Maldives \(1947–1981\)),
				'zero' => q(rwpî’r Maldives \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa’r Maldives),
				'few' => q(rufiyaa’r Maldives),
				'many' => q(rufiyaa’r Maldives),
				'one' => q(rufiyaa’r Maldives),
				'other' => q(rufiyaa’r Maldives),
				'two' => q(rufiyaa’r Maldives),
				'zero' => q(rufiyaa’r Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malawi),
				'few' => q(kwacha Malawi),
				'many' => q(kwacha Malawi),
				'one' => q(kwacha Malawi),
				'other' => q(kwacha Malawi),
				'two' => q(kwacha Malawi),
				'zero' => q(kwacha Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Mecsico),
				'few' => q(peso Mecsico),
				'many' => q(peso Mecsico),
				'one' => q(peso Mecsico),
				'other' => q(peso Mecsico),
				'two' => q(peso Mecsico),
				'zero' => q(peso Mecsico),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso Arian México \(1861–1992\)),
				'few' => q(peso arian México \(1861–1992\)),
				'many' => q(peso arian México \(1861–1992\)),
				'one' => q(peso arian México \(1861–1992\)),
				'other' => q(peso arian México \(1861–1992\)),
				'two' => q(peso arian México \(1861–1992\)),
				'zero' => q(peso arian México \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Uned Fuddsoddi México),
				'few' => q(uned fuddsoddi México),
				'many' => q(uned fuddsoddi México),
				'one' => q(uned fuddsoddi México),
				'other' => q(uned fuddsoddi México),
				'two' => q(uned fuddsoddi México),
				'zero' => q(uned fuddsoddi México),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malaysia),
				'few' => q(ringgit Malaysia),
				'many' => q(ringgit Malaysia),
				'one' => q(ringgit Malaysia),
				'other' => q(ringgit Malaysia),
				'two' => q(ringgit Malaysia),
				'zero' => q(ringgit Malaysia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo Mozambique),
				'few' => q(escudo Mozambique),
				'many' => q(escudo Mozambique),
				'one' => q(escudo Mozambique),
				'other' => q(escudo Mozambique),
				'two' => q(escudo Mozambique),
				'zero' => q(escudo Mozambique),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical Mozambique \(1980–2006\)),
				'few' => q(metical Mozambique \(1980–2006\)),
				'many' => q(metical Mozambique \(1980–2006\)),
				'one' => q(metical Mozambique \(1980–2006\)),
				'other' => q(metical Mozambique \(1980–2006\)),
				'two' => q(metical Mozambique \(1980–2006\)),
				'zero' => q(metical Mozambique \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mozambique),
				'few' => q(metical Mozambique),
				'many' => q(metical Mozambique),
				'one' => q(metical Mozambique),
				'other' => q(metical Mozambique),
				'two' => q(metical Mozambique),
				'zero' => q(metical Mozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Doler Namibia),
				'few' => q(doler Namibia),
				'many' => q(doler Namibia),
				'one' => q(doler Namibia),
				'other' => q(doler Namibia),
				'two' => q(ddoler Namibia),
				'zero' => q(doler Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeria),
				'few' => q(naira Nigeria),
				'many' => q(naira Nigeria),
				'one' => q(naira Nigeria),
				'other' => q(naira Nigeria),
				'two' => q(naira Nigeria),
				'zero' => q(naira Nigeria),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Córdoba Nicaragua \(1988–1991\)),
				'few' => q(córdoba Nicaragua \(1988–1991\)),
				'many' => q(córdoba Nicaragua \(1988–1991\)),
				'one' => q(córdoba Nicaragua \(1988–1991\)),
				'other' => q(córdoba Nicaragua \(1988–1991\)),
				'two' => q(córdoba Nicaragua \(1988–1991\)),
				'zero' => q(córdoba Nicaragua \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba Nicaragwa),
				'few' => q(cordoba Nicaragwa),
				'many' => q(cordoba Nicaragwa),
				'one' => q(cordoba Nicaragwa),
				'other' => q(cordoba Nicaragwa),
				'two' => q(cordoba Nicaragwa),
				'zero' => q(cordoba Nicaragwa),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Guilder yr Iseldiroedd),
				'few' => q(guilder yr Iseldiroedd),
				'many' => q(guilder yr Iseldiroedd),
				'one' => q(guilder yr Iseldiroedd),
				'other' => q(guilder yr Iseldiroedd),
				'two' => q(guilder yr Iseldiroedd),
				'zero' => q(guilder yr Iseldiroedd),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Norwy),
				'few' => q(krone Norwy),
				'many' => q(krone Norwy),
				'one' => q(krone Norwy),
				'other' => q(krone Norwy),
				'two' => q(krone Norwy),
				'zero' => q(krone Norwy),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rwpî Nepal),
				'few' => q(rwpî Nepal),
				'many' => q(rwpî Nepal),
				'one' => q(rwpî Nepal),
				'other' => q(rwpî Nepal),
				'two' => q(rwpî Nepal),
				'zero' => q(rwpî Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Doler Seland Newydd),
				'few' => q(doler Seland Newydd),
				'many' => q(doler Seland Newydd),
				'one' => q(doler Seland Newydd),
				'other' => q(doler Seland Newydd),
				'two' => q(ddoler Seland Newydd),
				'zero' => q(doler Seland Newydd),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Oman),
				'few' => q(rial Oman),
				'many' => q(rial Oman),
				'one' => q(rial Oman),
				'other' => q(rial Oman),
				'two' => q(rial Oman),
				'zero' => q(rial Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
				'few' => q(balboa Panama),
				'many' => q(balboa Panama),
				'one' => q(balboa Panama),
				'other' => q(balboa Panama),
				'two' => q(balboa Panama),
				'zero' => q(balboa Panama),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Inti Periw),
				'few' => q(inti Periw),
				'many' => q(inti Periw),
				'one' => q(inti Periw),
				'other' => q(inti Periw),
				'two' => q(inti Periw),
				'zero' => q(inti Periw),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Periw),
				'few' => q(sol Periw),
				'many' => q(sol Periw),
				'one' => q(sol Periw),
				'other' => q(sol Periw),
				'two' => q(sol Periw),
				'zero' => q(sol Periw),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol Periw \(1863–1965\)),
				'few' => q(sol Periw \(1863–1965\)),
				'many' => q(sol Periw \(1863–1965\)),
				'one' => q(sol Periw \(1863–1965\)),
				'other' => q(sol Periw \(1863–1965\)),
				'two' => q(sol Periw \(1863–1965\)),
				'zero' => q(sol Periw \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua Guinea Newydd),
				'few' => q(kina Papua Guinea Newydd),
				'many' => q(kina Papua Guinea Newydd),
				'one' => q(kina Papua Guinea Newydd),
				'other' => q(kina Papua Guinea Newydd),
				'two' => q(kina Papua Guinea Newydd),
				'zero' => q(kina Papua Guinea Newydd),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Philipinas),
				'few' => q(peso Philipinas),
				'many' => q(peso Philipinas),
				'one' => q(peso Philipinas),
				'other' => q(peso Philipinas),
				'two' => q(peso Philipinas),
				'zero' => q(peso Philipinas),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rwpî Pacistan),
				'few' => q(rwpî Pacistan),
				'many' => q(rwpî Pacistan),
				'one' => q(rwpî Pacistan),
				'other' => q(rwpî Pacistan),
				'two' => q(rwpî Pacistan),
				'zero' => q(rwpî Pacistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty Gwlad Pwyl),
				'few' => q(zloty Gwlad Pwyl),
				'many' => q(zloty Gwlad Pwyl),
				'one' => q(zloty Gwlad Pwyl),
				'other' => q(zloty Gwlad Pwyl),
				'two' => q(zloty Gwlad Pwyl),
				'zero' => q(zloty Gwlad Pwyl),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Paraguay),
				'few' => q(guarani Paraguay),
				'many' => q(guarani Paraguay),
				'one' => q(guarani Paraguay),
				'other' => q(guarani Paraguay),
				'two' => q(guarani Paraguay),
				'zero' => q(guarani Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial Qatar),
				'few' => q(rial Qatar),
				'many' => q(rial Qatar),
				'one' => q(rial Qatar),
				'other' => q(rial Qatar),
				'two' => q(rial Qatar),
				'zero' => q(rial Qatar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Doler Rhodesia),
				'few' => q(doler Rhodesia),
				'many' => q(doler Rhodesia),
				'one' => q(ddoler Rhodesia),
				'other' => q(doler Rhodesia),
				'two' => q(ddoler Rhodesia),
				'zero' => q(doler Rhodesia),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Rwmania),
				'few' => q(leu Rwmania),
				'many' => q(leu Rwmania),
				'one' => q(leu Rwmania),
				'other' => q(leu Rwmania),
				'two' => q(leu Rwmania),
				'zero' => q(leu Rwmania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Serbia),
				'few' => q(dinar Serbia),
				'many' => q(dinar Serbia),
				'one' => q(dinar Serbia),
				'other' => q(dinar Serbia),
				'two' => q(dinar Serbia),
				'zero' => q(dinar Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rwbl Rwsia),
				'few' => q(rwbl Rwsia),
				'many' => q(rwbl Rwsia),
				'one' => q(rwbl Rwsia),
				'other' => q(rwbl Rwsia),
				'two' => q(rwbl Rwsia),
				'zero' => q(rwbl Rwsia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ffranc Rwanda),
				'few' => q(ffranc Rwanda),
				'many' => q(ffranc Rwanda),
				'one' => q(ffranc Rwanda),
				'other' => q(ffranc Rwanda),
				'two' => q(ffranc Rwanda),
				'zero' => q(ffranc Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Saudi Arabia),
				'few' => q(riyal Saudi Arabia),
				'many' => q(riyal Saudi Arabia),
				'one' => q(riyal Saudi Arabia),
				'other' => q(riyal Saudi Arabia),
				'two' => q(riyal Saudi Arabia),
				'zero' => q(riyal Saudi Arabia),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Doler Ynysoedd Solomon),
				'few' => q(doler Ynysoedd Solomon),
				'many' => q(doler Ynysoedd Solomon),
				'one' => q(doler Ynysoedd Solomon),
				'other' => q(doler Ynysoedd Solomon),
				'two' => q(ddoler Ynysoedd Solomon),
				'zero' => q(doler Ynysoedd Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rwpî Seychelles),
				'few' => q(rwpî Seychelles),
				'many' => q(rwpî Seychelles),
				'one' => q(rwpî Seychelles),
				'other' => q(rwpî Seychelles),
				'two' => q(rwpî Seychelles),
				'zero' => q(rwpî Seychelles),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Dinar Sudan \(1992–2007\)),
				'few' => q(dinar Sudan \(1992–2007\)),
				'many' => q(dinar Sudan \(1992–2007\)),
				'one' => q(dinar Sudan \(1992–2007\)),
				'other' => q(dinar Sudan \(1992–2007\)),
				'two' => q(dinar Sudan \(1992–2007\)),
				'zero' => q(dinar Sudan \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Punt Sudan),
				'few' => q(punt Sudan),
				'many' => q(punt Sudan),
				'one' => q(punt Sudan),
				'other' => q(punt Sudan),
				'two' => q(bunt Sudan),
				'zero' => q(punt Sudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Punt Sudan \(1957–1998\)),
				'few' => q(punt Sudan \(1957–1998\)),
				'many' => q(phunt Sudan \(1957–1998\)),
				'one' => q(bunt Sudan \(1957–1998\)),
				'other' => q(punt Sudan \(1957–1998\)),
				'two' => q(bunt Sudan \(1957–1998\)),
				'zero' => q(punt Sudan \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Sweden),
				'few' => q(krona Sweden),
				'many' => q(krona Sweden),
				'one' => q(krona Sweden),
				'other' => q(krona Sweden),
				'two' => q(krona Sweden),
				'zero' => q(krona Sweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Doler Singapore),
				'few' => q(doler Singapore),
				'many' => q(doler Singapore),
				'one' => q(doler Singapore),
				'other' => q(doler Singapore),
				'two' => q(ddoler Singapore),
				'zero' => q(doler Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Punt St Helena),
				'few' => q(punt St. Helena),
				'many' => q(punt St. Helena),
				'one' => q(punt St. Helena),
				'other' => q(punt St. Helena),
				'two' => q(bunt St. Helena),
				'zero' => q(punt St. Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Sierra Leone),
				'few' => q(leone Sierra Leone),
				'many' => q(leone Sierra Leone),
				'one' => q(leone Sierra Leone),
				'other' => q(leone Sierra Leone),
				'two' => q(leone Sierra Leone),
				'zero' => q(leone Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Sierra Leone \(1964—2022\)),
				'few' => q(leone Sierra Leone \(1964—2022\)),
				'many' => q(leone Sierra Leone \(1964—2022\)),
				'one' => q(leone Sierra Leone \(1964—2022\)),
				'other' => q(leone Sierra Leone \(1964—2022\)),
				'two' => q(leone Sierra Leone \(1964—2022\)),
				'zero' => q(leone Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Swllt Somalia),
				'few' => q(swllt Somalia),
				'many' => q(swllt Somalia),
				'one' => q(swllt Somalia),
				'other' => q(swllt Somalia),
				'two' => q(swllt Somalia),
				'zero' => q(swllt Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Doler Surinam),
				'few' => q(doler Surinam),
				'many' => q(doler Surinam),
				'one' => q(doler Surinam),
				'other' => q(doler Surinam),
				'two' => q(ddoler Surinam),
				'zero' => q(doler Surinam),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Guilder Surinam),
				'few' => q(guilder Surinam),
				'many' => q(guilder Surinam),
				'one' => q(guilder Surinam),
				'other' => q(guilder Surinam),
				'two' => q(guilder Surinam),
				'zero' => q(guilder Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Punt De Sudan),
				'few' => q(punt De Sudan),
				'many' => q(punt De Sudan),
				'one' => q(punt De Sudan),
				'other' => q(punt De Sudan),
				'two' => q(bunt De Sudan),
				'zero' => q(punt De Sudan),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra São Tomé a Príncipe \(1977–2017\)),
				'few' => q(dobra São Tomé a Príncipe \(1977–2017\)),
				'many' => q(dobra São Tomé a Príncipe \(1977–2017\)),
				'one' => q(dobra São Tomé a Príncipe \(1977–2017\)),
				'other' => q(dobra São Tomé a Príncipe \(1977–2017\)),
				'two' => q(dobra São Tomé a Príncipe \(1977–2017\)),
				'zero' => q(dobra São Tomé a Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra São Tomé a Príncipe),
				'few' => q(dobra São Tomé a Príncipe),
				'many' => q(dobra São Tomé a Príncipe),
				'one' => q(dobra São Tomé a Príncipe),
				'other' => q(dobra São Tomé a Príncipe),
				'two' => q(dobra São Tomé a Príncipe),
				'zero' => q(dobra São Tomé a Príncipe),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colón El Salvador),
				'few' => q(colón El Salvador),
				'many' => q(colón El Salvador),
				'one' => q(colón El Salvador),
				'other' => q(colón El Salvador),
				'two' => q(colón El Salvador),
				'zero' => q(colón El Salvador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Punt Syria),
				'few' => q(punt Syria),
				'many' => q(punt Syria),
				'one' => q(punt Syria),
				'other' => q(punt Syria),
				'two' => q(bunt Syria),
				'zero' => q(punt Syria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Gwlad Swazi),
				'few' => q(lilangeni Gwlad Swazi),
				'many' => q(lilangeni Gwlad Swazi),
				'one' => q(lilangeni Gwlad Swazi),
				'other' => q(lilangeni Gwlad Swazi),
				'two' => q(lilangeni Gwlad Swazi),
				'zero' => q(lilangeni Gwlad Swazi),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht Gwlad Thai),
				'few' => q(baht Gwlad Thai),
				'many' => q(baht Gwlad Thai),
				'one' => q(baht Gwlad Thai),
				'other' => q(baht Gwlad Thai),
				'two' => q(baht Gwlad Thai),
				'zero' => q(baht Gwlad Thai),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Rwbl Tajikistan),
				'few' => q(rwbl Tajikistan),
				'many' => q(rwbl Tajikistan),
				'one' => q(rwbl Tajikistan),
				'other' => q(rwbl Tajikistan),
				'two' => q(rwbl Tajikistan),
				'zero' => q(rwbl Tajikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tajikistan),
				'few' => q(somoni Tajikstan),
				'many' => q(somoni Tajikstan),
				'one' => q(somoni Tajikstan),
				'other' => q(somoni Tajikstan),
				'two' => q(somoni Tajikstan),
				'zero' => q(somoni Tajikstan),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Manat Turkmenistan \(1993–2009\)),
				'few' => q(manat Turkmenistan \(1993–2009\)),
				'many' => q(manat Turkmenistan \(1993–2009\)),
				'one' => q(manat Turkmenistan \(1993–2009\)),
				'other' => q(manat Turkmenistan \(1993–2009\)),
				'two' => q(manat Turkmenistan \(1993–2009\)),
				'zero' => q(manat Turkmenistan \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turkmenistan),
				'few' => q(manat Turkmenistan),
				'many' => q(manat Turkmenistan),
				'one' => q(manat Turkmenistan),
				'other' => q(manat Turkmenistan),
				'two' => q(manat Turkmenistan),
				'zero' => q(manat Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunisia),
				'few' => q(dinar Tunisia),
				'many' => q(dinar Tunisia),
				'one' => q(dinar Tunisia),
				'other' => q(dinar Tunisia),
				'two' => q(dinar Tunisia),
				'zero' => q(dinar Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Tonga),
				'few' => q(paʻanga Tonga),
				'many' => q(paʻanga Tonga),
				'one' => q(paʻanga Tonga),
				'other' => q(paʻanga Tonga),
				'two' => q(paʻanga Tonga),
				'zero' => q(paʻanga Tonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Escudo Timor),
				'few' => q(escudo Timor),
				'many' => q(escudo Timor),
				'one' => q(escudo Timor),
				'other' => q(escudo Timor),
				'two' => q(escudo Timor),
				'zero' => q(escudo Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Lira Twrci \(1922–2005\)),
				'few' => q(lira Twrci \(1922–2005\)),
				'many' => q(lira Twrci \(1922–2005\)),
				'one' => q(lira Twrci \(1922–2005\)),
				'other' => q(lira Twrci \(1922–2005\)),
				'two' => q(lira Twrci \(1922–2005\)),
				'zero' => q(lira Twrci \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Twrci),
				'few' => q(lira Twrci),
				'many' => q(lira Twrci),
				'one' => q(lira Twrci),
				'other' => q(lira Twrci),
				'two' => q(lira Twrci),
				'zero' => q(lira Twrci),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Doler Trinidad a Tobago),
				'few' => q(doler Trinidad a Tobago),
				'many' => q(doler Trinidad a Tobago),
				'one' => q(doler Trinidad a Tobago),
				'other' => q(doler Trinidad a Tobago),
				'two' => q(ddoler Trinidad a Tobago),
				'zero' => q(doler Trinidad a Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Doler Newydd Taiwan),
				'few' => q(doler newydd Taiwan),
				'many' => q(doler newydd Taiwan),
				'one' => q(doler newydd Taiwan),
				'other' => q(doler newydd Taiwan),
				'two' => q(ddoler newydd Taiwan),
				'zero' => q(doler newydd Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Swllt Tanzania),
				'few' => q(swllt Tanzania),
				'many' => q(swllt Tanzania),
				'one' => q(swllt Tanzania),
				'other' => q(swllt Tanzania),
				'two' => q(swllt Tanzania),
				'zero' => q(swllt Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Wcráin),
				'few' => q(hryvnia Wcráin),
				'many' => q(hryvnia Wcráin),
				'one' => q(hryvnia Wcráin),
				'other' => q(hryvnia Wcráin),
				'two' => q(hryvnia Wcráin),
				'zero' => q(hryvnia Wcráin),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Swllt Uganda \(1966–1987\)),
				'few' => q(swllt Uganda \(1966–1987\)),
				'many' => q(swllt Uganda \(1966–1987\)),
				'one' => q(swllt Uganda \(1966–1987\)),
				'other' => q(swllt Uganda \(1966–1987\)),
				'two' => q(swllt Uganda \(1966–1987\)),
				'zero' => q(swllt Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Swllt Uganda),
				'few' => q(swllt Uganda),
				'many' => q(swllt Uganda),
				'one' => q(swllt Uganda),
				'other' => q(swllt Uganda),
				'two' => q(swllt Uganda),
				'zero' => q(swllt Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Doler UDA),
				'few' => q(doler UDA),
				'many' => q(doler UDA),
				'one' => q(doler UDA),
				'other' => q(doler UDA),
				'two' => q(ddoler UDA),
				'zero' => q(doler UDA),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Doler UDA \(y diwrnod nesaf\)),
				'few' => q(doler UDA \(y diwrnod nesaf\)),
				'many' => q(doler UDA \(y diwrnod nesaf\)),
				'one' => q(ddoler UDA \(y diwrnod nesaf\)),
				'other' => q(doler UDA \(y diwrnod nesaf\)),
				'two' => q(ddoler UDA \(y diwrnod nesaf\)),
				'zero' => q(doler UDA \(y diwrnod nesaf\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Doler UDA \(yr un diwrnod\)),
				'few' => q(doler UDA \(yr un diwrnod\)),
				'many' => q(doler UDA \(yr un diwrnod\)),
				'one' => q(ddoler UDA \(yr un diwrnod\)),
				'other' => q(doler UDA \(yr un diwrnod\)),
				'two' => q(ddoler UDA \(yr un diwrnod\)),
				'zero' => q(doler UDA \(yr un diwrnod\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Peso Uruguay \(1975–1993\)),
				'few' => q(peso Uruguay \(1975–1993\)),
				'many' => q(peso Uruguay \(1975–1993\)),
				'one' => q(peso Uruguay \(1975–1993\)),
				'other' => q(peso Uruguay \(1975–1993\)),
				'two' => q(peso Uruguay \(1975–1993\)),
				'zero' => q(peso Uruguay \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguay),
				'few' => q(peso Uruguay),
				'many' => q(peso Uruguay),
				'one' => q(peso Uruguay),
				'other' => q(peso Uruguay),
				'two' => q(peso Uruguay),
				'zero' => q(peso Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Uzbekistan),
				'few' => q(som Uzbekistan),
				'many' => q(som Uzbekistan),
				'one' => q(som Uzbekistan),
				'other' => q(som Uzbekistan),
				'two' => q(som Uzbekistan),
				'zero' => q(som Uzbekistan),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolívar Venezuela \(1871–2008\)),
				'few' => q(bolívar Venezuela \(1871–2008\)),
				'many' => q(bolívar Venezuela \(1871–2008\)),
				'one' => q(bolívar Venezuela \(1871–2008\)),
				'other' => q(bolívar Venezuela \(1871–2008\)),
				'two' => q(bolívar Venezuela \(1871–2008\)),
				'zero' => q(bolívar Venezuela \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolívar Venezuela \(2008–2018\)),
				'few' => q(bolívar Venezuela \(2008–2018\)),
				'many' => q(bolívar Venezuela \(2008–2018\)),
				'one' => q(bolívar Venezuela \(2008–2018\)),
				'other' => q(bolívar Venezuela \(2008–2018\)),
				'two' => q(bolívar Venezuela \(2008–2018\)),
				'zero' => q(bolívar Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar Venezuela),
				'few' => q(bolívar Venezuela),
				'many' => q(bolívar Venezuela),
				'one' => q(bolívar Venezuela),
				'other' => q(bolívar Venezuela),
				'two' => q(bolívar Venezuela),
				'zero' => q(bolívar Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Fietnam),
				'few' => q(dong Fietnam),
				'many' => q(dong Fietnam),
				'one' => q(dong Fietnam),
				'other' => q(dong Fietnam),
				'two' => q(dong Fietnam),
				'zero' => q(dong Fietnam),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Dong Fietnam \(1978–1985\)),
				'few' => q(dong Fietnam \(1978–1985\)),
				'many' => q(dong Fietnam \(1978–1985\)),
				'one' => q(dong Fietnam \(1978–1985\)),
				'other' => q(dong Fietnam \(1978–1985\)),
				'two' => q(dong Fietnam \(1978–1985\)),
				'zero' => q(dong Fietnam \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'few' => q(vatu Vanuatu),
				'many' => q(vatu Vanuatu),
				'one' => q(vatu Vanuatu),
				'other' => q(vatu Vanuatu),
				'two' => q(vatu Vanuatu),
				'zero' => q(vatu Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samoa),
				'few' => q(tala Samoa),
				'many' => q(tala Samoa),
				'one' => q(tala Samoa),
				'other' => q(tala Samoa),
				'two' => q(tala Samoa),
				'zero' => q(tala Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Ffranc CFA Canol Affrica),
				'few' => q(ffranc CFA Canol Affrica),
				'many' => q(ffranc CFA Canol Affrica),
				'one' => q(ffranc CFA Canol Affrica),
				'other' => q(ffranc CFA Canol Affrica),
				'two' => q(ffranc CFA Canol Affrica),
				'zero' => q(ffranc CFA Canol Affrica),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Arian),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Aur),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Uned Cyfansawdd Ewropeaidd),
				'few' => q(uned cyfansawdd Ewropeaidd),
				'many' => q(uned cyfansawdd Ewropeaidd),
				'one' => q(uned cyfansawdd Ewropeaidd),
				'other' => q(uned cyfansawdd Ewropeaidd),
				'two' => q(uned cyfansawdd Ewropeaidd),
				'zero' => q(uned cyfansawdd Ewropeaidd),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Uned Ariannol Ewropeaidd),
				'few' => q(uned ariannol Ewropeaidd),
				'many' => q(uned ariannol Ewropeaidd),
				'one' => q(uned ariannol Ewropeaidd),
				'other' => q(uned ariannol Ewropeaidd),
				'two' => q(uned ariannol Ewropeaidd),
				'zero' => q(uned ariannol Ewropeaidd),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Doler Dwyrain y Caribî),
				'few' => q(doler Dwyrain y Caribî),
				'many' => q(doler Dwyrain y Caribî),
				'one' => q(doler Dwyrain y Caribî),
				'other' => q(doler Dwyrain y Caribî),
				'two' => q(ddoler Dwyrain y Caribî),
				'zero' => q(doler Dwyrain y Caribî),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Uned Arian Cyfred Ewropeaidd),
				'few' => q(uned arian cyfred Ewropeaidd),
				'many' => q(uned arian cyfred Ewropeaidd),
				'one' => q(uned arian cyfred Ewropeaidd),
				'other' => q(uned arian cyfred Ewropeaidd),
				'two' => q(uned arian cyfred Ewropeaidd),
				'zero' => q(uned arian cyfred Ewropeaidd),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Ffranc CFA Gorllewin Affrica),
				'few' => q(ffranc CFA Gorllewin Affrica),
				'many' => q(ffranc CFA Gorllewin Affrica),
				'one' => q(ffranc CFA Gorllewin Affrica),
				'other' => q(ffranc CFA Gorllewin Affrica),
				'two' => q(ffranc CFA Gorllewin Affrica),
				'zero' => q(ffranc CFA Gorllewin Affrica),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paladiwm),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Ffranc CFP),
				'few' => q(ffranc CPF),
				'many' => q(ffranc CPF),
				'one' => q(ffranc CPF),
				'other' => q(ffranc CPF),
				'two' => q(ffranc CPF),
				'zero' => q(ffranc CPF),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platinwm),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(Sucre),
				'few' => q(sucre),
				'many' => q(sucre),
				'one' => q(sucre),
				'other' => q(sucre),
				'two' => q(sucre),
				'zero' => q(sucre),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Arian Cyfred Anhysbys),
				'few' => q(\(arian cyfred anhysbys\)),
				'many' => q(\(arian cyfred anhysbys\)),
				'one' => q(\(arian cyfred anhysbys\)),
				'other' => q(\(arian cyfred anhysbys\)),
				'two' => q(\(arian cyfred anhysbys\)),
				'zero' => q(\(arian cyfred anhysbys\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Dinar Yemen),
				'few' => q(dinar Yemen),
				'many' => q(dinar Yemen),
				'one' => q(dinar Yemen),
				'other' => q(dinar Yemen),
				'two' => q(dinar Yemen),
				'zero' => q(dinar Yemen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Yemen),
				'few' => q(rial Yemen),
				'many' => q(rial Yemen),
				'one' => q(rial Yemen),
				'other' => q(rial Yemen),
				'two' => q(rial Yemen),
				'zero' => q(rial Yemen),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rand \(ariannol\) De Affrica),
				'few' => q(rand \(ariannol\) De Affrica),
				'many' => q(rand \(ariannol\) De Affrica),
				'one' => q(rand \(ariannol\) De Affrica),
				'other' => q(rand \(ariannol\) De Affrica),
				'two' => q(rand \(ariannol\) De Affrica),
				'zero' => q(rand \(ariannol\) De Affrica),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand De Affrica),
				'few' => q(rand De Affrica),
				'many' => q(rand De Affrica),
				'one' => q(rand De Affrica),
				'other' => q(rand De Affrica),
				'two' => q(rand De Affrica),
				'zero' => q(rand De Affrica),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha Zambia \(1968–2012\)),
				'few' => q(kwacha Zambia \(1968–2012\)),
				'many' => q(kwacha Zambia \(1968–2012\)),
				'one' => q(kwacha Zambia \(1968–2012\)),
				'other' => q(kwacha Zambia \(1968–2012\)),
				'two' => q(kwacha Zambia \(1968–2012\)),
				'zero' => q(kwacha Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha Zambia),
				'few' => q(kwacha Zambia),
				'many' => q(kwacha Zambia),
				'one' => q(kwacha Zambia),
				'other' => q(kwacha Zambia),
				'two' => q(kwacha Zambia),
				'zero' => q(kwacha Zambia),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaire Newydd Zaire \(1993–1998\)),
				'few' => q(zaire newydd Zaire \(1993 – 1998\)),
				'many' => q(zaire newydd Zaire \(1993 – 1998\)),
				'one' => q(zaire newydd Zaire \(1993 – 1998\)),
				'other' => q(zaire newydd Zaire \(1993 – 1998\)),
				'two' => q(zaire newydd Zaire \(1993 – 1998\)),
				'zero' => q(zaire newydd Zaire \(1993 – 1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire Zaire \(1971–1993\)),
				'few' => q(zaire Zaire \(1971 – 1993\)),
				'many' => q(zaire Zaire \(1971 – 1993\)),
				'one' => q(zaire Zaire \(1971 – 1993\)),
				'other' => q(zaire Zaire \(1971 – 1993\)),
				'two' => q(zaire Zaire \(1971 – 1993\)),
				'zero' => q(zaire Zaire \(1971 – 1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Doler Zimbabwe \(1980–2008\)),
				'few' => q(doler Zimbabwe \(1980–2008\)),
				'many' => q(doler Zimbabwe \(1980–2008\)),
				'one' => q(ddoler Zimbabwe \(1980–2008\)),
				'other' => q(doler Zimbabwe \(1980–2008\)),
				'two' => q(ddoler Zimbabwe \(1980–2008\)),
				'zero' => q(doler Zimbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Doler Zimbabwe \(2009\)),
				'few' => q(doler Zimbabwe \(2009\)),
				'many' => q(doler Zimbabwe \(2009\)),
				'one' => q(ddoler Zimbabwe \(2009\)),
				'other' => q(doler Zimbabwe \(2009\)),
				'two' => q(ddoler Zimbabwe \(2009\)),
				'zero' => q(doler Zimbabwe \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Doler Zimbabwe \(2008\)),
				'few' => q(doler Zimbabwe \(2008\)),
				'many' => q(doler Zimbabwe \(2008\)),
				'one' => q(ddoler Zimbabwe \(2008\)),
				'other' => q(doler Zimbabwe \(2008\)),
				'two' => q(ddoler Zimbabwe \(2008\)),
				'zero' => q(doler Zimbabwe \(2008\)),
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
							'Ion',
							'Chwef',
							'Maw',
							'Ebr',
							'Mai',
							'Meh',
							'Gorff',
							'Awst',
							'Medi',
							'Hyd',
							'Tach',
							'Rhag'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ionawr',
							'Chwefror',
							'Mawrth',
							'Ebrill',
							'Mai',
							'Mehefin',
							'Gorffennaf',
							'Awst',
							'Medi',
							'Hydref',
							'Tachwedd',
							'Rhagfyr'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ion',
							'Chw',
							'Maw',
							'Ebr',
							'Mai',
							'Meh',
							'Gor',
							'Awst',
							'Medi',
							'Hyd',
							'Tach',
							'Rhag'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'I',
							'Ch',
							'M',
							'E',
							'M',
							'M',
							'G',
							'A',
							'M',
							'H',
							'T',
							'Rh'
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
						mon => 'Llun',
						tue => 'Maw',
						wed => 'Mer',
						thu => 'Iau',
						fri => 'Gwen',
						sat => 'Sad',
						sun => 'Sul'
					},
					short => {
						mon => 'Ll',
						tue => 'Ma',
						wed => 'Me',
						thu => 'Ia',
						fri => 'Gw',
						sat => 'Sa',
						sun => 'Su'
					},
					wide => {
						mon => 'Dydd Llun',
						tue => 'Dydd Mawrth',
						wed => 'Dydd Mercher',
						thu => 'Dydd Iau',
						fri => 'Dydd Gwener',
						sat => 'Dydd Sadwrn',
						sun => 'Dydd Sul'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Llun',
						tue => 'Maw',
						wed => 'Mer',
						thu => 'Iau',
						fri => 'Gwe',
						sat => 'Sad',
						sun => 'Sul'
					},
					narrow => {
						mon => 'Ll',
						tue => 'M',
						wed => 'M',
						thu => 'I',
						fri => 'G',
						sat => 'S',
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
					abbreviated => {0 => 'Ch1',
						1 => 'Ch2',
						2 => 'Ch3',
						3 => 'Ch4'
					},
					wide => {0 => 'chwarter 1af',
						1 => '2il chwarter',
						2 => '3ydd chwarter',
						3 => '4ydd chwarter'
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
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
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
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
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
					'afternoon1' => q{y prynhawn},
					'evening1' => q{yr hwyr},
					'midnight' => q{canol nos},
					'morning1' => q{y bore},
					'noon' => q{canol dydd},
				},
				'narrow' => {
					'afternoon1' => q{yn y prynhawn},
					'am' => q{b},
					'evening1' => q{min nos},
					'midnight' => q{canol nos},
					'morning1' => q{yn y bore},
					'noon' => q{canol dydd},
					'pm' => q{h},
				},
				'wide' => {
					'am' => q{yb},
					'pm' => q{yh},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{prynhawn},
					'evening1' => q{yr hwyr},
					'morning1' => q{bore},
				},
				'narrow' => {
					'afternoon1' => q{prynhawn},
					'evening1' => q{min nos},
					'morning1' => q{bore},
				},
				'wide' => {
					'afternoon1' => q{y prynhawn},
					'evening1' => q{yr hwyr},
					'morning1' => q{y bore},
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
				'0' => 'CC',
				'1' => 'OC'
			},
			narrow => {
				'0' => 'C',
				'1' => 'O'
			},
			wide => {
				'0' => 'Cyn Crist',
				'1' => 'Oed Crist'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/yy},
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
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
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
		'generic' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{'wythnos' W 'o' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQ => q{Q y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'wythnos' w 'o' Y},
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
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d MMM – d MMM},
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
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM, y – E, d MMM y G},
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
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
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
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM, y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Amser {0}),
		regionFormat => q(Amser Haf {0}),
		regionFormat => q(Amser Safonol {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Amser Afghanistan#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Amser Canolbarth Affrica#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Amser Dwyrain Affrica#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Amser Safonol De Affrica#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Amser Haf Gorllewin Affrica#,
				'generic' => q#Amser Gorllewin Affrica#,
				'standard' => q#Amser Safonol Gorllewin Affrica#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Amser Haf Alaska#,
				'generic' => q#Amser Alaska#,
				'standard' => q#Amser Safonol Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amser Haf Amazonas#,
				'generic' => q#Amser Amazonas#,
				'standard' => q#Amser Safonol Amazonas#,
			},
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bae Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Bae Cambridge#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Dinas Tell, Indiana#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Dinas Mecsico#,
		},
		'America/New_York' => {
			exemplarCity => q#Efrog Newydd#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Gogledd Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Gogledd Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Gogledd Dakota#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Amser Haf Canolbarth Gogledd America#,
				'generic' => q#Amser Canolbarth Gogledd America#,
				'standard' => q#Amser Safonol Canolbarth Gogledd America#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Amser Haf Dwyrain Gogledd America#,
				'generic' => q#Amser Dwyrain Gogledd America#,
				'standard' => q#Amser Safonol Dwyrain Gogledd America#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Amser Haf Mynyddoedd Gogledd America#,
				'generic' => q#Amser Mynyddoedd Gogledd America#,
				'standard' => q#Amser Safonol Mynyddoedd Gogledd America#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Amser Haf Cefnfor Tawel Gogledd America#,
				'generic' => q#Amser Cefnfor Tawel Gogledd America#,
				'standard' => q#Amser Safonol Cefnfor Tawel Gogledd America#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Amser Haf Apia#,
				'generic' => q#Amser Apia#,
				'standard' => q#Amser Safonol Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Amser Haf Arabaidd#,
				'generic' => q#Amser Arabaidd#,
				'standard' => q#Amser Safonol Arabaidd#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Amser Haf Ariannin#,
				'generic' => q#Amser yr Ariannin#,
				'standard' => q#Amser Safonol Ariannin#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Amser Haf Gorllewin Ariannin#,
				'generic' => q#Amser Gorllewin Ariannin#,
				'standard' => q#Amser Safonol Gorllewin Ariannin#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Amser Haf Armenia#,
				'generic' => q#Amser Armenia#,
				'standard' => q#Amser Safonol Armenia#,
			},
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gasa#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerwsalem#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Dinas Hô Chi Minh#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Amser Haf Cefnfor yr Iwerydd#,
				'generic' => q#Amser Cefnfor yr Iwerydd#,
				'standard' => q#Amser Safonol Cefnfor yr Iwerydd#,
			},
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Yr Ynysoedd Dedwydd#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ffaro#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#De Georgia#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Amser Haf Canolbarth Awstralia#,
				'generic' => q#Amser Canolbarth Awstralia#,
				'standard' => q#Amser Safonol Canolbarth Awstralia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Amser Haf Canolbarth Gorllewin Awstralia#,
				'generic' => q#Amser Canolbarth Gorllewin Awstralia#,
				'standard' => q#Amser Safonol Canolbarth Gorllewin Awstralia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Amser Haf Dwyrain Awstralia#,
				'generic' => q#Amser Dwyrain Awstralia#,
				'standard' => q#Amser Safonol Dwyrain Awstralia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Amser Haf Gorllewin Awstralia#,
				'generic' => q#Amser Gorllewin Awstralia#,
				'standard' => q#Amser Safonol Gorllewin Awstralia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Amser Haf Aserbaijan#,
				'generic' => q#Amser Aserbaijan#,
				'standard' => q#Amser Safonol Aserbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Amser Haf yr Azores#,
				'generic' => q#Amser yr Azores#,
				'standard' => q#Amser Safonol yr Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Amser Haf Bangladesh#,
				'generic' => q#Amser Bangladesh#,
				'standard' => q#Amser Safonol Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Amser Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Amser Bolifia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Amser Haf Brasília#,
				'generic' => q#Amser Brasília#,
				'standard' => q#Amser Safonol Brasília#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Amser Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Amser Haf Cabo Verde#,
				'generic' => q#Amser Cabo Verde#,
				'standard' => q#Amser Safonol Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Amser Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Amser Haf Chatham#,
				'generic' => q#Amser Chatham#,
				'standard' => q#Amser Safonol Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Amser Haf Chile#,
				'generic' => q#Amser Chile#,
				'standard' => q#Amser Safonol Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Amser Haf Tsieina#,
				'generic' => q#Amser Tsieina#,
				'standard' => q#Amser Safonol Tsieina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Amser Haf Choibalsan#,
				'generic' => q#Amser Choibalsan#,
				'standard' => q#Amser Safonol Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Amser Ynys Y Nadolig#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Amser Ynysoedd Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Amser Haf Colombia#,
				'generic' => q#Amser Colombia#,
				'standard' => q#Amser Safonol Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Amser Hanner Haf Ynysoedd Cook#,
				'generic' => q#Amser Ynysoedd Cook#,
				'standard' => q#Amser Safonol Ynysoedd Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Amser Haf Ciwa#,
				'generic' => q#Amser Ciwba#,
				'standard' => q#Amser Safonol Ciwba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Amser Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Amser Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Amser Dwyrain Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Amser Haf Ynys y Pasg#,
				'generic' => q#Amser Ynys y Pasg#,
				'standard' => q#Amser Safonol Ynys y Pasg#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Amser Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Amser Cyffredniol Cydlynol#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Dinas Anhysbys#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brwsel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bwcarést#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dulyn#,
			long => {
				'daylight' => q#Amser Safonol Iwerddon#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Ynys y Garn#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ynys Manaw#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Caergystennin#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			exemplarCity => q#Llundain#,
			long => {
				'daylight' => q#Amser Haf Prydain#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lwcsembwrg#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rhufain#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Y Fatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Fienna#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Amser Haf Canolbarth Ewrop#,
				'generic' => q#Amser Canolbarth Ewrop#,
				'standard' => q#Amser Safonol Canolbarth Ewrop#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Amser Haf Dwyrain Ewrop#,
				'generic' => q#Amser Dwyrain Ewrop#,
				'standard' => q#Amser Safonol Dwyrain Ewrop#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Amser Dwyrain Pell Ewrop#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Amser Haf Gorllewin Ewrop#,
				'generic' => q#Amser Gorllewin Ewrop#,
				'standard' => q#Amser Safonol Gorllewin Ewrop#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Amser Haf Ynysoedd Falklands/Malvinas#,
				'generic' => q#Amser Ynysoedd Falklands/Malvinas#,
				'standard' => q#Amser Safonol Ynysoedd Falklands/Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Amser Haf Fiji#,
				'generic' => q#Amser Fiji#,
				'standard' => q#Amser Safonol Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Amser Guyane Ffrengig#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Amser Tiroedd Ffrainc yn y De a’r Antarctig#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Amser Safonol Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Amser Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Amser Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Amser Haf Georgia#,
				'generic' => q#Amser Georgia#,
				'standard' => q#Amser Safonol Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Amser Ynysoedd Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Amser Haf Dwyrain yr Ynys Las#,
				'generic' => q#Amser Dwyrain yr Ynys Las#,
				'standard' => q#Amser Safonol Dwyrain yr Ynys Las#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Amser Haf Gorllewin yr Ynys Las#,
				'generic' => q#Amser Gorllewin yr Ynys Las#,
				'standard' => q#Amser Safonol Gorllewin yr Ynys Las#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Amser Safonol y Gwlff#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Amser Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Amser Haf Hawaii-Aleutian#,
				'generic' => q#Amser Hawaii-Aleutian#,
				'standard' => q#Amser Safonol Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Amser Haf Hong Kong#,
				'generic' => q#Amser Hong Kong#,
				'standard' => q#Amser Safonol Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Amser Haf Hovd#,
				'generic' => q#Amser Hovd#,
				'standard' => q#Amser Safonol Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Amser India#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Ynys y Nadolig#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Amser Cefnfor India#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Amser Indo-Tsieina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Amser Canolbarth Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Amser Dwyrain Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Amser Gorllewin Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Amser Haf Iran#,
				'generic' => q#Amser Iran#,
				'standard' => q#Amser Safonol Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Amser Haf Irkutsk#,
				'generic' => q#Amser Irkutsk#,
				'standard' => q#Amser Safonol Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Amser Haf Israel#,
				'generic' => q#Amser Israel#,
				'standard' => q#Amser Safonol Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Amser Haf Japan#,
				'generic' => q#Amser Japan#,
				'standard' => q#Amser Safonol Japan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Amser Dwyrain Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Amser Gorllewin Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Amser Haf Corea#,
				'generic' => q#Amser Corea#,
				'standard' => q#Amser Safonol Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Amser Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Amser Haf Krasnoyarsk#,
				'generic' => q#Amser Krasnoyarsk#,
				'standard' => q#Amser Safonol Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Amser Kyrgyzstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Amser Ynysoedd Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Amser Haf yr Arglwydd Howe#,
				'generic' => q#Amser yr Arglwydd Howe#,
				'standard' => q#Amser Safonol yr Arglwydd Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Amser Ynys Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Amser Haf Magadan#,
				'generic' => q#Amser Magadan#,
				'standard' => q#Amser Safonol Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Amser Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Amser Y Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Amser Marquises#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Amser Ynysoedd Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Amser Haf Mauritius#,
				'generic' => q#Amser Mauritius#,
				'standard' => q#Amser Safonol Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Amser Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Amser Haf Gogledd Orllewin Mecsico#,
				'generic' => q#Amser Gogledd Orllewin Mecsico#,
				'standard' => q#Amser Safonol Gogledd Orllewin Mecsico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Amser Haf Pasiffig Mecsico#,
				'generic' => q#Amser Pasiffig Mecsico#,
				'standard' => q#Amser Safonol Pasiffig Mecsico#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Amser Haf Ulan Bator#,
				'generic' => q#Amser Ulan Bator#,
				'standard' => q#Amser Safonol Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Amser Haf Moscfa#,
				'generic' => q#Amser Moscfa#,
				'standard' => q#Amser Safonol Moscfa#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Amser Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Amser Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Amser Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Amser Haf Caledonia Newydd#,
				'generic' => q#Amser Caledonia Newydd#,
				'standard' => q#Amser Safonol Caledonia Newydd#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Amser Haf Seland Newydd#,
				'generic' => q#Amser Seland Newydd#,
				'standard' => q#Amser Safonol Seland Newydd#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Amser Haf Newfoundland#,
				'generic' => q#Amser Newfoundland#,
				'standard' => q#Amser Safonol Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Amser Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Amser Haf Ynys Norfolk#,
				'generic' => q#Amser Ynys Norfolk#,
				'standard' => q#Amser Safonol Ynys Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Amser Haf Fernando de Noronha#,
				'generic' => q#Amser Fernando de Noronha#,
				'standard' => q#Amser Safonol Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Amser Haf Novosibirsk#,
				'generic' => q#Amser Novosibirsk#,
				'standard' => q#Amser Safonol Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Amser Haf Omsk#,
				'generic' => q#Amser Omsk#,
				'standard' => q#Amser Safonol Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ynys y Pasg#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Amser Haf Pakistan#,
				'generic' => q#Amser Pakistan#,
				'standard' => q#Amser Safonol Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Amser Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Amser Papua Guinea Newydd#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Amser Haf Paraguay#,
				'generic' => q#Amser Paraguay#,
				'standard' => q#Amser Safonol Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Amser Haf Periw#,
				'generic' => q#Amser Periw#,
				'standard' => q#Amser Safonol Periw#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Amser Haf Pilipinas#,
				'generic' => q#Amser Pilipinas#,
				'standard' => q#Amser Safonol Pilipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Amser Ynysoedd Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Amser Haf Saint-Pierre-et-Miquelon#,
				'generic' => q#Amser Saint-Pierre-et-Miquelon#,
				'standard' => q#Amser Safonol Saint-Pierre-et-Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Amser Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Amser Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Amser Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Amser Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Amser Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Amser Haf Sakhalin#,
				'generic' => q#Amser Sakhalin#,
				'standard' => q#Amser Safonol Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Amser Haf Samara#,
				'generic' => q#Amser Samara#,
				'standard' => q#Amser Safonol Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Amser Haf Samoa#,
				'generic' => q#Amser Samoa#,
				'standard' => q#Amser Safonol Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Amser Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Amser Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Amser Ynysoedd Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Amser De Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Amser Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Amser Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Amser Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Amser Haf Taipei#,
				'generic' => q#Amser Taipei#,
				'standard' => q#Amser Safonol Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Amser Tajicistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Amser Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Amser Haf Tonga#,
				'generic' => q#Amser Tonga#,
				'standard' => q#Amser Safonol Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Amser Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Amser Haf Tyrcmenistan#,
				'generic' => q#Amser Tyrcmenistan#,
				'standard' => q#Amser Safonol Tyrcmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Amser Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Amser Haf Uruguay#,
				'generic' => q#Amser Uruguay#,
				'standard' => q#Amser Safonol Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Amser Haf Uzbekistan#,
				'generic' => q#Amser Uzbekistan#,
				'standard' => q#Amser Safonol Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Amser Haf Vanuatu#,
				'generic' => q#Amser Vanuatu#,
				'standard' => q#Amser Safonol Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Amser Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Amser Haf Vladivostok#,
				'generic' => q#Amser Vladivostok#,
				'standard' => q#Amser Safonol Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Amser Haf Volgograd#,
				'generic' => q#Amser Volgograd#,
				'standard' => q#Amser Safonol Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Amser Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Amser Ynys Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Amser Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Amser Haf Yakutsk#,
				'generic' => q#Amser Yakutsk#,
				'standard' => q#Amser Safonol Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Amser Haf Yekaterinburg#,
				'generic' => q#Amser Yekaterinburg#,
				'standard' => q#Amser Safonol Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Amser Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
