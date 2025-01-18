=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Blo - Package for language Anii

=cut

package Locale::CLDR::Locales::Blo;
# This file auto generated from Data\common\main\blo.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'gɩlaaribuja',
 				'ar_001' => 'gɩlaaribuja ŋgɩɖee kǝ ba na fʊba na',
 				'blo' => 'anii kagɩja',
 				'bn' => 'baŋglaa kagɩja',
 				'de' => 'gɩjaamaja',
 				'en' => 'gɛɛshɩ',
 				'en_US' => 'gɛɛshɩ (Ganɔ gaɖɔŋkɔnɔ kabʊtǝna Amalɩka nɩ)',
 				'en_US@alt=short' => 'gɛɛshɩ (GKA)',
 				'es' => 'gɩspaŋja',
 				'es_419' => 'gɩspaŋja (latɛŋ kaAmalɩkatǝna)',
 				'fr' => 'gɩfɔnɔ',
 				'hi_Latn' => 'hinɖii kagɩja (latɛŋ kʊja)',
 				'hi_Latn@alt=variant' => 'hiŋgliishɩ kagɩja',
 				'id' => 'Ɛnɖonosii kagɩja',
 				'it' => 'gɩtaliija',
 				'ja' => 'gɩjapaŋja',
 				'ko' => 'Koree kagɩja',
 				'nl' => 'Holanɖ kagɩja',
 				'pl' => 'Polanɖ kagɩja',
 				'pt' => 'gɩpɔrtigalja',
 				'ru' => 'gɩrɔɔshɩyaja',
 				'th' => 'taɩ kagɩja',
 				'tr' => 'gɩturkiija',
 				'und' => 'gɩkrǝ ŋgɩɖee kʊyɔʊ ʊ mana ma',
 				'zh' => 'gɩcaɩnaja manɖarɛŋ',
 				'zh@alt=menu' => 'gɩcaɩnaja, manɖarɛŋ',
 				'zh_Hans' => 'gɩcaɩnaja gɩburoka',
 				'zh_Hans@alt=long' => 'gɩcaɩnaja manɖarɛŋ gɩburoka',
 				'zh_Hant' => 'gɩcaɩnaja tututu',
 				'zh_Hant@alt=long' => 'gɩcaɩnaja manɖarɛŋ tututu',

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
			'Arab' => 'laaribu kʊja',
 			'Cyrl' => 'Siril kʊja',
 			'Deva' => 'defanagari kʊja',
 			'Hans' => 'aburoka',
 			'Hans@alt=stand-alone' => 'Han (aburoka)',
 			'Hant' => 'tututu',
 			'Hant@alt=stand-alone' => 'Han (tututu)',
 			'Jpan' => 'Japaŋ kʊja',
 			'Kore' => 'Koree kʊja',
 			'Latn' => 'latɛŋ kʊja',
 			'Zsym' => 'ɩlamba',
 			'Zxxx' => 'kǝ ba ŋɔn na',
 			'Zzzz' => 'ʊŋɔn nɖee kʊyɔʊ ʊ mana ma',

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
			'001' => 'nɖulinya',
 			'002' => 'Garɩɖontǝna',
 			'003' => 'Gamalɩkatǝna gʊnyɩpɛnɛlaŋ',
 			'005' => 'Gamalɩkatǝna gʊnyɩsonolaŋ',
 			'009' => 'Oseyanii',
 			'011' => 'Garɩɖontǝna gɩteŋshilelaŋ',
 			'013' => 'Gamalɩkatǝna gɩcɩɩca',
 			'014' => 'Garɩɖontǝna gajakalaŋ',
 			'015' => 'Garɩɖontǝna gʊnyɩpɛnɛlaŋ',
 			'017' => 'Garɩɖontǝna gɩcɩɩca',
 			'018' => 'Garɩɖontǝna gʊnyɩsonolaŋ',
 			'019' => 'Gamalɩkatǝna',
 			'021' => 'Gamalɩkatǝna kagʊnyɩpɛnɛlaŋ',
 			'029' => 'Karayiib',
 			'030' => 'Gacǝlǝŋtǝna gajakalaŋ',
 			'034' => 'Gacǝlǝŋtǝna gʊnyɩsonolaŋ',
 			'035' => 'Gacǝlǝŋtǝna gʊsono na gajakayɛlaŋ kʊfɔɔ nɩ',
 			'039' => 'Garɩfɔntǝna gʊnyɩsonolaŋ',
 			'053' => 'Ɔstracǝlǝŋtǝna',
 			'054' => 'Melanesiya',
 			'057' => 'Mikronesiya kagʊsaʊ',
 			'061' => 'Polinesiya',
 			'142' => 'Gacǝlǝŋtǝna',
 			'143' => 'Gacǝlǝŋtǝna gɩcɩɩca',
 			'145' => 'Gacǝlǝŋtǝna gɩteŋshilelaŋ',
 			'150' => 'Garɩfɔntǝna',
 			'151' => 'Garɩfɔntǝna gajakalaŋ',
 			'154' => 'Garɩfɔntǝna gʊnyɩpɛnɛlaŋ',
 			'155' => 'Garɩfɔntǝna gɩteŋshilelaŋ',
 			'202' => 'Garɩɖontǝna Sahara katǝntǝn',
 			'419' => 'Latɛŋ kaAmalɩkatǝna',
 			'AC' => 'Asɛnsiyɔɔn kaAtukǝltǝna',
 			'AD' => 'Anɖɔraa',
 			'AE' => 'Emiir baGanɔ gaɖɔŋkɔnɔ kaAlaaributǝna',
 			'AF' => 'Afganistan',
 			'AG' => 'Antiguwaa na Barbuɖaa',
 			'AI' => 'Aŋguwilaa',
 			'AL' => 'Albanii',
 			'AM' => 'Armenii',
 			'AO' => 'Aŋgolaa',
 			'AQ' => 'Gatutaltǝna',
 			'AR' => 'Arjantin',
 			'AS' => 'Samowa Amalɩka kaja',
 			'AT' => 'Otrish',
 			'AU' => 'Ɔstraliya',
 			'AW' => 'Arubaa',
 			'AX' => 'Ɔɔlanɖ kaBʊtǝlǝltǝna',
 			'AZ' => 'Asɛrbaɩjaŋ',
 			'BA' => 'Bɔsniya na Hɛrsegɔfina',
 			'BB' => 'Barbaɖɔɔsɩ',
 			'BD' => 'Baŋglaɖɛɛshɩ',
 			'BE' => 'Bɛljiiki',
 			'BF' => 'Burkinaa',
 			'BG' => 'Bulgarii',
 			'BH' => 'Barɛɛn',
 			'BI' => 'Burunɖii',
 			'BJ' => 'Benɛɛ',
 			'BL' => 'Sɛŋ-Batolomayɔ',
 			'BM' => 'Bɛrmuɖaa',
 			'BN' => 'Brunɛɩ',
 			'BO' => 'Bolifiya',
 			'BQ' => 'Holanɖ kaKarayiib',
 			'BR' => 'Bresil',
 			'BS' => 'Bahamaasɩ',
 			'BT' => 'Butan',
 			'BV' => 'Bufee kaAtukǝltǝna',
 			'BW' => 'Bɔsʊwanaa',
 			'BY' => 'Belaruus',
 			'BZ' => 'Beliis',
 			'CA' => 'Kanaɖaa',
 			'CC' => 'Kokoos (Kiiliŋ) kaBʊtukǝltǝna',
 			'CD' => 'Koŋgoo Kinshasaa',
 			'CD@alt=variant' => 'Koŋgoo Sayiir',
 			'CF' => 'Santrafrika',
 			'CG' => 'Koŋgoo Brasafil',
 			'CG@alt=variant' => 'Koŋgoo kaRepibliiki',
 			'CH' => 'Suwis',
 			'CI' => 'Koɖifʊaa',
 			'CI@alt=variant' => 'Aɩfɔrɩ Kɔɔst',
 			'CK' => 'Kʊkʊ kaBʊtukǝltǝna',
 			'CL' => 'Shilii',
 			'CM' => 'Kamerun',
 			'CN' => 'Caɩna',
 			'CO' => 'Kolɔmbii',
 			'CP' => 'Klipɛɛtɔn kaAtukǝltǝna',
 			'CQ' => 'Sark',
 			'CR' => 'Kɔsta Rikaa',
 			'CU' => 'Kubaa',
 			'CV' => 'Kapfɛɛr',
 			'CW' => 'Kurasawuu',
 			'CX' => 'Nowɛl kaAtukǝltǝna',
 			'CY' => 'Ciprɔs',
 			'CZ' => 'Cɛk',
 			'CZ@alt=variant' => 'Cɛk kaRepibliiki',
 			'DE' => 'Gajaamatǝna',
 			'DG' => 'Ɖiyego Garsiya',
 			'DJ' => 'Jibutii',
 			'DK' => 'Ɖanǝmark',
 			'DM' => 'Ɖominikaa',
 			'DO' => 'Ɖominikaa kaRepibliiki',
 			'DZ' => 'Aljerii',
 			'EA' => 'Seyuta na Meliliya',
 			'EC' => 'Ekuwaɖɔɔr',
 			'EE' => 'Ɛstoniya',
 			'EG' => 'Ejipti',
 			'EH' => 'Sarawii',
 			'ER' => 'Eritree',
 			'ES' => 'Ɛspanyǝ',
 			'ET' => 'Etiyopii',
 			'EU' => 'Ganɔ gaɖɔŋkɔnɔ kaBʊtǝna Garɩfɔntǝna nɩ',
 			'EZ' => 'Eroo kaBʊtǝna',
 			'FI' => 'Fɛnlanɖ',
 			'FJ' => 'Fiji',
 			'FK' => 'Fɔklanɖ kaBʊtukǝltǝna',
 			'FK@alt=variant' => 'Fɔklanɖ kaBʊtukǝltǝna (Malfina kaBʊtukǝltǝna)',
 			'FM' => 'Mikronesiya',
 			'FO' => 'Faroi kaBʊtukǝltǝna',
 			'FR' => 'Gafɔntǝna',
 			'GA' => 'Gabɔŋ',
 			'GB' => 'Gagɛɛshɩtǝna',
 			'GB@alt=short' => 'GT',
 			'GD' => 'Grenaɖaa',
 			'GE' => 'Jɔrjiya',
 			'GF' => 'Guyanaa Gafɔntǝna kaja',
 			'GG' => 'Gǝrǝnsɛɩ',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltaa',
 			'GL' => 'Grinlanɖ',
 			'GM' => 'Gambii',
 			'GN' => 'Ginee',
 			'GP' => 'Guwaɖeluupu',
 			'GQ' => 'Ginee Malabo',
 			'GR' => 'Grɛs',
 			'GS' => 'Jɔrjiya gʊnyɩsonolaŋ kaja na Sanɖuush gʊnyɩsonolaŋ kaBʊtukǝltǝna',
 			'GT' => 'Guwatemalaa',
 			'GU' => 'Guwam',
 			'GW' => 'Ginee Bisoo',
 			'GY' => 'Guyanaa',
 			'HK' => 'Hɔŋ Kɔŋ Caɩna kaja',
 			'HK@alt=short' => 'Hɔŋ Kɔŋ',
 			'HM' => 'Hɛɛrɖ na Mɛkɖɔnalɖ kaBʊtukǝltǝna',
 			'HN' => 'Hɔnɖuraasɩ',
 			'HR' => 'Krowasii',
 			'HT' => 'Hayitii',
 			'HU' => 'Ɔŋgrii',
 			'IC' => 'Kanarii kaBʊtukǝltǝna',
 			'ID' => 'Ɛnɖonosii',
 			'IE' => 'Irlanɖ',
 			'IL' => 'Yishraɛl',
 			'IM' => 'Man kaAtukǝltǝna',
 			'IN' => 'Inɖiya',
 			'IO' => 'Gɛɛshɩ kaAtǝna Inɖiya kaTeŋku nɩ',
 			'IO@alt=chagos' => 'Cagɔɔsɩ kaBʊtukǝltǝna',
 			'IQ' => 'Ɩraakɩ',
 			'IR' => 'Iraŋ',
 			'IS' => 'Islanɖ',
 			'IT' => 'Italii',
 			'JE' => 'Jersei',
 			'JM' => 'Jamaɩka',
 			'JO' => 'Jɔrɖanii',
 			'JP' => 'Japaŋ',
 			'KE' => 'Keniya',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kamboɖiya',
 			'KI' => 'Kiribatii',
 			'KM' => 'Komɔɔr',
 			'KN' => 'Sɛŋ Kits na Nefis',
 			'KP' => 'Koree gʊnyɩpɛnɛlaŋ',
 			'KR' => 'Koree gʊnyɩsonolaŋ',
 			'KW' => 'Koweeti',
 			'KY' => 'Kayimaan kaBʊtukǝltǝna',
 			'KZ' => 'Kasastan',
 			'LA' => 'Lawɔs',
 			'LB' => 'Liibaaŋ',
 			'LC' => 'Sɛŋ Lusiya',
 			'LI' => 'Liishtɛntaɩn',
 			'LK' => 'Siri Laŋkaa',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesotoo',
 			'LT' => 'Lituwaniya',
 			'LU' => 'Lusɛmbuur',
 			'LV' => 'Lɛtfiya',
 			'LY' => 'Libii',
 			'MA' => 'Morooko',
 			'MC' => 'Monakoo',
 			'MD' => 'Mɔlɖafiya',
 			'ME' => 'Mɔntenegroo',
 			'MF' => 'Sɛŋ Martɛɛŋ',
 			'MG' => 'Maɖagaskaa',
 			'MH' => 'Marshal kaBʊtukǝltǝna',
 			'MK' => 'Maseɖoniya gʊnyɩpɛnɛlaŋ kaja',
 			'ML' => 'Malii',
 			'MM' => 'Miyanmaa (Birmanii)',
 			'MN' => 'Mɔŋgolii',
 			'MO' => 'Makawoo Caɩna kaja',
 			'MO@alt=short' => 'Makawoo',
 			'MP' => 'Mariyan kaBʊtukǝltǝna gʊnyɩpɛnɛlaŋ',
 			'MQ' => 'Martiniiki',
 			'MR' => 'Moritanii',
 			'MS' => 'Mɔnsɛraatɩ',
 			'MT' => 'Malta',
 			'MU' => 'Imoris',
 			'MV' => 'Malɖiifu',
 			'MW' => 'Malawii',
 			'MX' => 'Mɛsik',
 			'MY' => 'Malɛsii',
 			'MZ' => 'Mosambii',
 			'NA' => 'Namibii',
 			'NC' => 'Kaleɖonii afɔlɩ',
 			'NE' => 'Nijɛr',
 			'NF' => 'Nɔrfook kaAtukǝltǝna',
 			'NG' => 'Nanjiiriya',
 			'NI' => 'Nikaraguwaa',
 			'NL' => 'Holanɖ',
 			'NO' => 'Nɔrfɛsh',
 			'NP' => 'Neepal',
 			'NR' => 'Nawuru',
 			'NU' => 'Niwuye',
 			'NZ' => 'Selanɖ afɔlɩ',
 			'NZ@alt=variant' => 'Awoteyarowa Selanɖ afɔlɩ',
 			'OM' => 'Oman',
 			'PA' => 'Panamaa',
 			'PE' => 'Peruu',
 			'PF' => 'Polinesiya Gafɔntǝna kaja',
 			'PG' => 'Papuasii Ginee afɔlɩ',
 			'PH' => 'Filipiin',
 			'PK' => 'Pakistan',
 			'PL' => 'Polanɖ',
 			'PM' => 'Sɛŋ-Petrɔs na Mikelɔŋ',
 			'PN' => 'Pɩtkɛɛn kaBʊtukǝltǝna',
 			'PR' => 'Pɔrto Rikoo',
 			'PS' => 'Palɛstiin kAsàʊ',
 			'PS@alt=short' => 'Palɛstiin',
 			'PT' => 'Pɔrtigal',
 			'PW' => 'Palawoo',
 			'PY' => 'Paraguwee',
 			'QA' => 'Kataa',
 			'QO' => 'Oseyanii kasaʊlǝŋka',
 			'RE' => 'Reeniyɔŋ',
 			'RO' => 'Romanii',
 			'RS' => 'Sɛrbii',
 			'RU' => 'Rɔɔshɩya',
 			'RW' => 'Rʊwanɖaa',
 			'SA' => 'Sauɖiya',
 			'SB' => 'Salomɔɔn kaBʊtukǝltǝna',
 			'SC' => 'Seshɛl',
 			'SD' => 'Suɖaŋ',
 			'SE' => 'Sʊwɛɖ',
 			'SG' => 'Siŋgapuur',
 			'SH' => 'Sɛŋ Elenaa (kaAtukǝltǝna)',
 			'SI' => 'Slofeniya',
 			'SJ' => 'Sǝfalbaaɖ na Yan Mayɛn',
 			'SK' => 'Slofakii',
 			'SL' => 'Seraleyɔn',
 			'SM' => 'Sɛŋ Marinoo',
 			'SN' => 'Senegal',
 			'SO' => 'Somalii',
 			'SR' => 'Surinam',
 			'SS' => 'Suɖaŋ gʊnyɩsonolaŋ',
 			'ST' => 'Saotomee',
 			'SV' => 'Ɛl Salfaɖɔɔr',
 			'SX' => 'Sɛŋ Martɛɛŋ (Holanɖ kaja)',
 			'SY' => 'Sirii',
 			'SZ' => 'Ɛsʊwatinii',
 			'SZ@alt=variant' => 'Sʊwasilanɖ',
 			'TA' => 'Tristan ɖa Kuna',
 			'TC' => 'Turkisii na Kayɩkɔɔsɩ kaBʊtukǝltǝna',
 			'TD' => 'Caɖ',
 			'TF' => 'Gafɔntǝna kaBʊtǝna gʊnyɩsonolaŋ kabʊja',
 			'TG' => 'Togoo',
 			'TH' => 'Taɩlanɖ',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelaʊ',
 			'TL' => 'Timɔɔ gajakalaŋ',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisii',
 			'TO' => 'Tɔŋga',
 			'TR' => 'Turkii',
 			'TT' => 'Triniɖaaɖ na Tobagoo',
 			'TV' => 'Tufalu',
 			'TW' => 'Taɩwan',
 			'TZ' => 'Taŋsanii',
 			'UA' => 'Ikrɛɛn',
 			'UG' => 'Uganɖaa',
 			'UM' => 'Ganɔ gaɖɔŋkɔnɔ kaBʊtǝna Amalɩka nɩ kaBʊtukǝltǝna bʊlǝŋka',
 			'UN' => 'Ganɔ gaɖɔŋkɔnɔ kaBʊtǝna nɖulinya nɩ',
 			'US' => 'Ganɔ gaɖɔŋkɔnɔ kaBʊtǝna Amalɩka nɩ',
 			'US@alt=short' => 'GKA',
 			'UY' => 'Uruguwee',
 			'UZ' => 'Usbeekistan',
 			'VA' => 'Fatikaŋ kaMpá',
 			'VC' => 'Sɛŋ Fɩnsaŋ na Grenaɖiniisi',
 			'VE' => 'Fenesuwelaa',
 			'VG' => 'Fɩrjɩɩn kǝBʊtukǝltǝna Gɛɛshɩ kabʊja',
 			'VI' => 'Fɩrjɩɩn kaBʊtukǝltǝna Amalɩka kabʊja',
 			'VN' => 'Fɛtnam',
 			'VU' => 'Fanuwatu',
 			'WF' => 'Walis na Futuna',
 			'WS' => 'Samowa',
 			'XA' => 'sǝɖoo-aksaŋ',
 			'XB' => 'sǝɖoo-biɖi',
 			'XK' => 'Kɔsofoo',
 			'YE' => 'Yemɛn',
 			'YT' => 'Mayɔɔtɩ',
 			'ZA' => 'Sautafrika',
 			'ZM' => 'Sambii',
 			'ZW' => 'Simbabʊwee',
 			'ZZ' => 'gʊsaʊɩ kʊyɔʊ ʊ mana ma',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ɩshilé n’ɩŋɔrɔ ɩtʊrka',
 			'currency' => 'gɩtanɩ',
 			'ms' => 'ʊfaŋʊ kayaashɩ',
 			'numbers' => 'ɩnɔmba',

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
 				'buddhist' => q{Buɖa kǝbaja bɩshilé na bɩŋɔrɔ ɩtʊrka},
 				'chinese' => q{Caɩna kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'coptic' => q{Kɔpǝt kǝbaja bɩshilé na bɩŋɔrɔ ɩtʊrka},
 				'dangi' => q{ɖaŋgi kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'ethiopic' => q{Etiyopii kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'ethiopic-amete-alem' => q{Etiyopii kɩshilé na kɩŋɔrɔ ɩtʊrka (Amete Alɛm)},
 				'gregorian' => q{Gregɔɔ ‘ɩshilé n’‘ɩŋɔrɔ ɩtʊrka},
 				'hebrew' => q{Yahuuɖi kǝbaja bɩshilé na bɩŋɔrɔ ɩtʊrka},
 				'indian' => q{Inɖiya kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'islamic' => q{gɩnǝma kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'islamic-civil' => q{gɩnǝma kɩshilé na kɩŋɔrɔ ɩtʊrka aɖʊ (gatǝna kʊsǝu katam)},
 				'islamic-rgsa' => q{gɩnǝma kɩshilé na kɩŋɔrɔ ɩtʊrka akʊn aŋɔrɔ (Sauɖiya)},
 				'islamic-tbla' => q{gɩnǝma kɩshilé na kɩŋɔrɔ ɩtʊrka aɖʊ (ɩŋɔripi ɩceuka katam)},
 				'islamic-umalqura' => q{gɩnǝma kɩshilé na kɩŋɔrɔ ɩtʊrka (Um al-Kra)},
 				'iso8601' => q{ISO-8601 kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'japanese' => q{Japaŋ kɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'persian' => q{Pɛrs kǝbaja bɩshilé na kɩŋɔrɔ ɩtʊrka},
 				'roc' => q{miŋguwo kɩshilé na kɩŋɔrɔ ɩtʊrka},
 			},
 			'collation' => {
 				'standard' => q{ɩbii kʊnyaʊ ɖeiɖei},
 			},
 			'ms' => {
 				'metric' => q{mɛta kʊfaŋʊ kayaashɩ},
 				'uksystem' => q{Gɛɛshɩ kʊfaŋʊ kayaashɩ},
 				'ussystem' => q{Amalɩka kʊfaŋʊ kayaashɩ},
 			},
 			'numbers' => {
 				'latn' => q{latɛŋ},
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
			'metric' => q{mɛta kʊfaŋʊ kayaashɩ},
 			'UK' => q{Gɛɛshɩ kʊfaŋʊ kayaashɩ},
 			'US' => q{Amalɩka kʊfaŋʊ kayaashɩ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'gɩkrǝ : {0}',
 			'script' => 'ʊŋɔn kagʊsʊ̀rá : {0}',
 			'region' => 'gʊsaʊ : {0}',

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
			auxiliary => qr{[ăǎåäãā{a̰} æ ɓ ćç d ɗ ĕěëẽēḛ {ǝ̃}{ǝ̄}{ǝ̰} {ə̌} {ɛ̌}{ɛ̃}{ɛ̄}{ɛ̰} ƒ ɣ {hw} ĭǐïĩīḭ ĳ {ɩ̃}{ɩ̄}{ɩ̰} {m̌}{m̄} ňñ{n̄} {ŋw} ŏǒöõøō{o̰} œ {ɔ̌}{ɔ̃}{ɔ̄}{ɔ̰} ř šſ ß ŭǔüūṵ {̃ũ} {ʊ̌}{ʊ̃}{ʊ̄}{ʊ̰} v ʋ x {xw} ÿ ƴ z ʒ {̃ʼ}]},
			main => qr{[aáàâ b c ɖ eéèê ǝ{ǝ́}{ǝ̀}{ǝ̂} ɛ{ɛ́}{ɛ̀}{ɛ̂} f g {gb} h iíìî ɩ{ɩ́}{ɩ̀}{ɩ̂} j k {kp} l mḿ{m̀} nńǹ {ny} ŋ{ŋ́}{ŋ̀} {ŋm} oóòô ɔ{ɔ́}{ɔ̀}{ɔ̂} p r s {sh} t uúùû ʊ{ʊ́}{ʊ̀}{ʊ̂} w y]},
			numbers => qr{[   \- ‑ , . % ‰ ‱ + 0 1 2² 3³ 4 5 6 7 8 9 {ʲᵃ} {ᵏᵃ}]},
			punctuation => qr{[_ \- ‐‑ – — ― , ; \: ! ? . … '‘’ ‹ › "“” « » ( ) \[ \] \{ \} § @ * / \\ \& # % ‰ ‱ † ‡ • ‣ ‧ ′ ″ ° < = > | ¦ ~]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
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
						'1' => q(jibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(jibi{0}),
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
						'1' => q(ɛsbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ɛsbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(sebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(sebi{0}),
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
						'1' => q(ɖesi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ɖesi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pikoo{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pikoo{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(fɛmtoo{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(fɛmtoo{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atoo{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atoo{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(sɛnti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(sɛnti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(sɛptoo{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(sɛptoo{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yɔktoo{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yɔktoo{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(rɔntoo{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(rɔntoo{0}),
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
						'1' => q(kwɛktoo{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kwɛktoo{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikroo{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikroo{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nanoo{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nanoo{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ɖeka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ɖeka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tɛraa{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tɛraa{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(petaa{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(petaa{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ɛsaa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ɛsaa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hɛktoo{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hɛktoo{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(sɛtaa{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(sɛtaa{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yɔta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yɔta{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(rɔnaa{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(rɔnaa{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kiloo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kiloo{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(kwɛtaa{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kwɛtaa{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(megaa{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(megaa{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(jigaa{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(jigaa{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(gatǝna kɩkashɩ bʊkɔ laŋ),
						'one' => q(gatǝna kɩkashɩ bʊkɔ laŋ {0}),
						'other' => q(gatǝna kɩkashɩ bʊkɔ laŋ {0}),
						'zero' => q(baa gatǝna kɩkashɩ bʊkɔ laŋ {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(gatǝna kɩkashɩ bʊkɔ laŋ),
						'one' => q(gatǝna kɩkashɩ bʊkɔ laŋ {0}),
						'other' => q(gatǝna kɩkashɩ bʊkɔ laŋ {0}),
						'zero' => q(baa gatǝna kɩkashɩ bʊkɔ laŋ {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ɩmɛta gɩpi bʊyɛ bʊyɛ nɩ),
						'one' => q(mɛta gɩpi bʊyɛ bʊyɛ nɩ {0}),
						'other' => q(ɩmɛta gɩpi bʊyɛ bʊyɛ nɩ {0}),
						'zero' => q(baa mɛta gɩpi bʊyɛ bʊyɛ nɩ {0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ɩmɛta gɩpi bʊyɛ bʊyɛ nɩ),
						'one' => q(mɛta gɩpi bʊyɛ bʊyɛ nɩ {0}),
						'other' => q(ɩmɛta gɩpi bʊyɛ bʊyɛ nɩ {0}),
						'zero' => q(baa mɛta gɩpi bʊyɛ bʊyɛ nɩ {0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(gʊta-kɩminti),
						'one' => q(gʊta-kaminti {0}),
						'other' => q(gʊta-kɩminti {0}),
						'zero' => q(baa gʊta-kaminti {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(gʊta-kɩminti),
						'one' => q(gʊta-kaminti {0}),
						'other' => q(gʊta-kɩminti {0}),
						'zero' => q(baa gʊta-kaminti {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(gʊta-kɩsǝmpi),
						'one' => q(gʊta-kagɩsǝmpi {0}),
						'other' => q(gʊta-kɩsǝmpi {0}),
						'zero' => q(baa gʊta-kagɩsǝmpi {0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(gʊta-kɩsǝmpi),
						'one' => q(gʊta-kagɩsǝmpi {0}),
						'other' => q(gʊta-kɩsǝmpi {0}),
						'zero' => q(baa gʊta-kagɩsǝmpi {0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ɩɖegre),
						'one' => q(ɖegre {0}),
						'other' => q(ɩɖegre {0}),
						'zero' => q(baa ɖegre {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ɩɖegre),
						'one' => q(ɖegre {0}),
						'other' => q(ɩɖegre {0}),
						'zero' => q(baa ɖegre {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ɩcǝpǝrʊ),
						'one' => q(ʊcǝpǝrʊ {0}),
						'other' => q(ɩcǝpǝrʊ {0}),
						'zero' => q(baa ʊcǝpǝrʊ {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ɩcǝpǝrʊ),
						'one' => q(ʊcǝpǝrʊ {0}),
						'other' => q(ɩcǝpǝrʊ {0}),
						'zero' => q(baa ʊcǝpǝrʊ {0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ɩɖunam),
						'one' => q(ɖunam {0}),
						'other' => q(ɩɖunam {0}),
						'zero' => q(baa ɖunam {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ɩɖunam),
						'one' => q(ɖunam {0}),
						'other' => q(ɩɖunam {0}),
						'zero' => q(baa ɖunam {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ɩlɔ),
						'one' => q(ʊlɔ {0}),
						'other' => q(ɩlɔ {0}),
						'zero' => q(baa ʊlɔ {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ɩlɔ),
						'one' => q(ʊlɔ {0}),
						'other' => q(ɩlɔ {0}),
						'zero' => q(baa ʊlɔ {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ɩsɛntimɛta bʊyɛ bʊyɛ),
						'one' => q(sɛntimɛta bʊyɛ bʊyɛ {0}),
						'other' => q(ɩsɛntimɛta bʊyɛ bʊyɛ {0}),
						'per' => q({0} sɛntimɛta bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa sɛntimɛta bʊyɛ bʊyɛ {0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ɩsɛntimɛta bʊyɛ bʊyɛ),
						'one' => q(sɛntimɛta bʊyɛ bʊyɛ {0}),
						'other' => q(ɩsɛntimɛta bʊyɛ bʊyɛ {0}),
						'per' => q({0} sɛntimɛta bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa sɛntimɛta bʊyɛ bʊyɛ {0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(anaŋcǝna bʊyɛ bʊyɛ),
						'one' => q(gʊnaŋcǝna bʊyɛ bʊyɛ {0}),
						'other' => q(anaŋcǝna bʊyɛ bʊyɛ {0}),
						'zero' => q(baa gʊnaŋcǝna bʊyɛ bʊyɛ {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(anaŋcǝna bʊyɛ bʊyɛ),
						'one' => q(gʊnaŋcǝna bʊyɛ bʊyɛ {0}),
						'other' => q(anaŋcǝna bʊyɛ bʊyɛ {0}),
						'zero' => q(baa gʊnaŋcǝna bʊyɛ bʊyɛ {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(asǝkǝmǝ bʊyɛ bʊyɛ),
						'one' => q(nsǝkǝmǝ bʊyɛ bʊyɛ {0}),
						'other' => q(asǝkǝmǝ bʊyɛ bʊyɛ {0}),
						'per' => q({0} nsǝkǝmǝ bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa nsǝkǝmǝ bʊyɛ bʊyɛ {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(asǝkǝmǝ bʊyɛ bʊyɛ),
						'one' => q(nsǝkǝmǝ bʊyɛ bʊyɛ {0}),
						'other' => q(asǝkǝmǝ bʊyɛ bʊyɛ {0}),
						'per' => q({0} nsǝkǝmǝ bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa nsǝkǝmǝ bʊyɛ bʊyɛ {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ɩkiloomɛta bʊyɛ bʊyɛ),
						'one' => q(kiloomɛta bʊyɛ bʊyɛ {0}),
						'other' => q(ɩkiloomɛta bʊyɛ bʊyɛ {0}),
						'per' => q({0} kiloomɛta bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa kiloomɛta bʊyɛ bʊyɛ {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ɩkiloomɛta bʊyɛ bʊyɛ),
						'one' => q(kiloomɛta bʊyɛ bʊyɛ {0}),
						'other' => q(ɩkiloomɛta bʊyɛ bʊyɛ {0}),
						'per' => q({0} kiloomɛta bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa kiloomɛta bʊyɛ bʊyɛ {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ɩmɛta bʊyɛ bʊyɛ),
						'one' => q(mɛta bʊyɛ bʊyɛ {0}),
						'other' => q(ɩmɛta bʊyɛ bʊyɛ {0}),
						'per' => q({0} mɛta bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa mɛta bʊyɛ bʊyɛ {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ɩmɛta bʊyɛ bʊyɛ),
						'one' => q(mɛta bʊyɛ bʊyɛ {0}),
						'other' => q(ɩmɛta bʊyɛ bʊyɛ {0}),
						'per' => q({0} mɛta bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa mɛta bʊyɛ bʊyɛ {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ɩmayɩl bʊyɛ bʊyɛ),
						'one' => q(mayɩl bʊyɛ bʊyɛ {0}),
						'other' => q(ɩmayɩl bʊyɛ bʊyɛ {0}),
						'per' => q({0} mayɩl bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa mayɩl bʊyɛ bʊyɛ {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ɩmayɩl bʊyɛ bʊyɛ),
						'one' => q(mayɩl bʊyɛ bʊyɛ {0}),
						'other' => q(ɩmayɩl bʊyɛ bʊyɛ {0}),
						'per' => q({0} mayɩl bʊyɛ bʊyɛ nɩ),
						'zero' => q(baa mayɩl bʊyɛ bʊyɛ {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ayɔkɔ),
						'one' => q(bʊkɔ {0}),
						'other' => q(ayɔkɔ {0}),
						'zero' => q(baa bʊkɔ {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ayɔkɔ),
						'one' => q(bʊkɔ {0}),
						'other' => q(ayɔkɔ {0}),
						'zero' => q(baa bʊkɔ {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ɩkaraatɩ),
						'one' => q(karaatɩ {0}),
						'other' => q(ɩkaraatɩ {0}),
						'zero' => q(baa karaatɩ {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ɩkaraatɩ),
						'one' => q(karaatɩ {0}),
						'other' => q(ɩkaraatɩ {0}),
						'zero' => q(baa karaatɩ {0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ɩmiligram ɖesilitri nɩ),
						'one' => q(miligram ɖesilitri nɩ {0}),
						'other' => q(ɩmiligram ɖesilitri nɩ {0}),
						'zero' => q(baa miligram ɖesilitri nɩ {0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ɩmiligram ɖesilitri nɩ),
						'one' => q(miligram ɖesilitri nɩ {0}),
						'other' => q(ɩmiligram ɖesilitri nɩ {0}),
						'zero' => q(baa miligram ɖesilitri nɩ {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ɩmilimol litri nɩ),
						'one' => q(milimol litri nɩ {0}),
						'other' => q(ɩmilimol litri nɩ {0}),
						'zero' => q(baa milimol litri nɩ {0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ɩmilimol litri nɩ),
						'one' => q(milimol litri nɩ {0}),
						'other' => q(ɩmilimol litri nɩ {0}),
						'zero' => q(baa milimol litri nɩ {0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ɩmol),
						'one' => q(mol {0}),
						'other' => q(ɩmol {0}),
						'zero' => q(baa mol {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ɩmol),
						'one' => q(mol {0}),
						'other' => q(ɩmol {0}),
						'zero' => q(baa mol {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ɩshɩnʊn nɩ),
						'one' => q(ɩshɩnʊn nɩ {0}),
						'other' => q(ɩshɩnʊn nɩ {0}),
						'zero' => q(ɩshɩnʊn nɩ {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ɩshɩnʊn nɩ),
						'one' => q(ɩshɩnʊn nɩ {0}),
						'other' => q(ɩshɩnʊn nɩ {0}),
						'zero' => q(ɩshɩnʊn nɩ {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(miili nɩ),
						'one' => q(miili nɩ {0}),
						'other' => q(miili nɩ {0}),
						'zero' => q(miili nɩ {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(miili nɩ),
						'one' => q(miili nɩ {0}),
						'other' => q(miili nɩ {0}),
						'zero' => q(miili nɩ {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ɩlitri ɩkiloomɛta 100 nɩ),
						'one' => q(litri ɩkiloomɛta 100 nɩ {0}),
						'other' => q(ɩlitri ɩkiloomɛta 100 nɩ {0}),
						'zero' => q(baa litri ɩkiloomɛta 100 nɩ {0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ɩlitri ɩkiloomɛta 100 nɩ),
						'one' => q(litri ɩkiloomɛta 100 nɩ {0}),
						'other' => q(ɩlitri ɩkiloomɛta 100 nɩ {0}),
						'zero' => q(baa litri ɩkiloomɛta 100 nɩ {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ɩlitri kiloomɛta nɩ),
						'one' => q(litri kiloomɛta nɩ {0}),
						'other' => q(litri kiloomɛta nɩ {0}),
						'zero' => q(baa litri kiloomɛta nɩ {0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ɩlitri kiloomɛta nɩ),
						'one' => q(litri kiloomɛta nɩ {0}),
						'other' => q(litri kiloomɛta nɩ {0}),
						'zero' => q(baa litri kiloomɛta nɩ {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ɩmayɩl gaalɔŋ nɩ),
						'one' => q(mayɩl gaalɔŋ nɩ {0}),
						'other' => q(ɩmayɩl gaalɔŋ nɩ {0}),
						'zero' => q(baa mayɩl gaalɔŋ nɩ {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ɩmayɩl gaalɔŋ nɩ),
						'one' => q(mayɩl gaalɔŋ nɩ {0}),
						'other' => q(ɩmayɩl gaalɔŋ nɩ {0}),
						'zero' => q(baa mayɩl gaalɔŋ nɩ {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ɩmayɩl gaalɔŋ Gɛɛshɩ kaja nɩ),
						'one' => q(mayɩl gaalɔŋ Gɛɛshɩ kaja nɩ {0}),
						'other' => q(ɩmayɩl gaalɔŋ Gɛɛshɩ kaja nɩ {0}),
						'zero' => q(baa mayɩl gaalɔŋ Gɛɛshɩ kaja nɩ {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ɩmayɩl gaalɔŋ Gɛɛshɩ kaja nɩ),
						'one' => q(mayɩl gaalɔŋ Gɛɛshɩ kaja nɩ {0}),
						'other' => q(ɩmayɩl gaalɔŋ Gɛɛshɩ kaja nɩ {0}),
						'zero' => q(baa mayɩl gaalɔŋ Gɛɛshɩ kaja nɩ {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} gajakalaŋ),
						'north' => q({0} gʊnyɩpɛnɛlaŋ),
						'south' => q({0} gʊnyɩsonolaŋ),
						'west' => q({0} gɩteŋshilelaŋ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} gajakalaŋ),
						'north' => q({0} gʊnyɩpɛnɛlaŋ),
						'south' => q({0} gʊnyɩsonolaŋ),
						'west' => q({0} gɩteŋshilelaŋ),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(bʊja-ɩshɩnʊn mána),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(bʊja-ɩshɩnʊn mána),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ɩshilé),
						'per' => q({0} ʊshilé nɩ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ɩshilé),
						'per' => q({0} ʊshilé nɩ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(bʊja-tǝb mána),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(bʊja-tǝb mána),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(bʊkɔŋkɔŋɔ̀),
						'per' => q({0} gakɔŋkɔŋɔ̀ nɩ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(bʊkɔŋkɔŋɔ̀),
						'per' => q({0} gakɔŋkɔŋɔ̀ nɩ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(ɩmikroosǝmpi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(ɩmikroosǝmpi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ɩsǝmpi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ɩsǝmpi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(anaŋa),
						'per' => q({0} gʊnaŋa nɩ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(anaŋa),
						'per' => q({0} gʊnaŋa nɩ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ɩŋɔrɔ),
						'per' => q({0} aŋɔrɔ nɩ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ɩŋɔrɔ),
						'per' => q({0} aŋɔrɔ nɩ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ɩnanoosǝmpi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ɩnanoosǝmpi),
					},
					# Long Unit Identifier
					'duration-night' => {
						'per' => q({0} gɩjibɔŋɔ nɩ),
					},
					# Core Unit Identifier
					'night' => {
						'per' => q({0} gɩjibɔŋɔ nɩ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ɩŋɔrɩriu mána),
						'per' => q({0} ɩŋɔrɩriu nɩ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ɩŋɔrɩriu mána),
						'per' => q({0} ɩŋɔrɩriu nɩ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ɩpi),
						'per' => q({0} gɩpi nɩ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ɩpi),
						'per' => q({0} gɩpi nɩ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ɩbɔkɔɩ),
						'per' => q({0} bɔkɔɩ nɩ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ɩbɔkɔɩ),
						'per' => q({0} bɔkɔɩ nɩ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(bʊja),
						'per' => q({0} gaja nɩ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(bʊja),
						'per' => q({0} gaja nɩ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(Ampɛɛr mána),
						'one' => q(Ampɛɛr {0}),
						'other' => q(Ampɛɛr mána {0}),
						'zero' => q(baa Ampɛɛr {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(Ampɛɛr mána),
						'one' => q(Ampɛɛr {0}),
						'other' => q(Ampɛɛr mána {0}),
						'zero' => q(baa Ampɛɛr {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mili-Ampɛɛr mána),
						'one' => q(mili-Ampɛɛr {0}),
						'other' => q(mili-Ampɛɛr {0} mána),
						'zero' => q(baa mili-Ampɛɛr {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mili-Ampɛɛr mána),
						'one' => q(mili-Ampɛɛr {0}),
						'other' => q(mili-Ampɛɛr {0} mána),
						'zero' => q(baa mili-Ampɛɛr {0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Om mána),
						'one' => q(Om {0}),
						'other' => q(Om mána {0}),
						'zero' => q(baa Om {0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Om mána),
						'one' => q(Om {0}),
						'other' => q(Om mána {0}),
						'zero' => q(baa Om {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ɩFɔltɩ),
						'one' => q(Fɔltɩ {0}),
						'other' => q(ɩFɔltɩ {0}),
						'zero' => q(baa Fɔltɩ {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ɩFɔltɩ),
						'one' => q(Fɔltɩ {0}),
						'other' => q(ɩFɔltɩ {0}),
						'zero' => q(baa Fɔltɩ {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(ɩkalorii),
						'one' => q(kalorii {0}),
						'other' => q(ɩkalorii {0}),
						'zero' => q(baa kalorii {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(ɩkalorii),
						'one' => q(kalorii {0}),
						'other' => q(ɩkalorii {0}),
						'zero' => q(baa kalorii {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elɛtrɔŋ-Fɔltɩ mána),
						'one' => q(elɛtrɔŋ-Fɔltɩ {0}),
						'other' => q(elɛtrɔŋ-Fɔltɩ mána {0}),
						'zero' => q(baa elɛtrɔŋ-Fɔltɩ {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elɛtrɔŋ-Fɔltɩ mána),
						'one' => q(elɛtrɔŋ-Fɔltɩ {0}),
						'other' => q(elɛtrɔŋ-Fɔltɩ mána {0}),
						'zero' => q(baa elɛtrɔŋ-Fɔltɩ {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ɩjul),
						'one' => q(jul {0}),
						'other' => q(ɩjul {0}),
						'zero' => q(baa jul {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ɩjul),
						'one' => q(jul {0}),
						'other' => q(ɩjul {0}),
						'zero' => q(baa jul {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(ɩkilookalorii),
						'one' => q(kilookalorii {0}),
						'other' => q(ɩkilookalorii {0}),
						'zero' => q(baa kilookalorii {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(ɩkilookalorii),
						'one' => q(kilookalorii {0}),
						'other' => q(ɩkilookalorii {0}),
						'zero' => q(baa kilookalorii {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ɩkiloojul),
						'one' => q(kiloojul {0}),
						'other' => q(ɩkiloojul {0}),
						'zero' => q(baa kiloojul {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ɩkiloojul),
						'one' => q(kiloojul {0}),
						'other' => q(ɩkiloojul {0}),
						'zero' => q(baa kiloojul {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀),
						'one' => q(kiloo-Waatɩ-gakɔŋkɔŋɔ̀ {0}),
						'other' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀ {0}),
						'zero' => q(baa kiloo-Waatɩ-gakɔŋkɔŋɔ̀ {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀),
						'one' => q(kiloo-Waatɩ-gakɔŋkɔŋɔ̀ {0}),
						'other' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀ {0}),
						'zero' => q(baa kiloo-Waatɩ-gakɔŋkɔŋɔ̀ {0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ),
						'one' => q(kiloo-Waatɩ-gakɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ {0}),
						'other' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ {0}),
						'zero' => q(baa kiloo-Waatɩ-gakɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ),
						'one' => q(kiloo-Waatɩ-gakɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ {0}),
						'other' => q(kiloo-Waatɩ-bʊkɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ {0}),
						'zero' => q(baa kiloo-Waatɩ-gakɔŋkɔŋɔ̀ ɩkilomɛta 100 nɩ {0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ɩNiutɔn),
						'one' => q(Niutɔn {0}),
						'other' => q(ɩNiutɔn {0}),
						'zero' => q(baa Niutɔn {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ɩNiutɔn),
						'one' => q(Niutɔn {0}),
						'other' => q(ɩNiutɔn {0}),
						'zero' => q(baa Niutɔn {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(ɩjigaa-Hɛrtɩ),
						'one' => q(jigaa-Hɛrtɩ {0}),
						'other' => q(ɩjigaa-Hɛrtɩ {0}),
						'zero' => q(baa jigaa-Hɛrtɩ {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(ɩjigaa-Hɛrtɩ),
						'one' => q(jigaa-Hɛrtɩ {0}),
						'other' => q(ɩjigaa-Hɛrtɩ {0}),
						'zero' => q(baa jigaa-Hɛrtɩ {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ɩHɛrtɩ),
						'one' => q(Hɛrtɩ {0}),
						'other' => q(ɩHɛrtɩ {0}),
						'zero' => q(baa Hɛrtɩ {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ɩHɛrtɩ),
						'one' => q(Hɛrtɩ {0}),
						'other' => q(ɩHɛrtɩ {0}),
						'zero' => q(baa Hɛrtɩ {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(ɩkiloo-Hɛrtɩ),
						'one' => q(kiloo-Hɛrtɩ {0}),
						'other' => q(ɩkiloo-Hɛrtɩ {0}),
						'zero' => q(baa kiloo-Hɛrtɩ {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(ɩkiloo-Hɛrtɩ),
						'one' => q(kiloo-Hɛrtɩ {0}),
						'other' => q(ɩkiloo-Hɛrtɩ {0}),
						'zero' => q(baa kiloo-Hɛrtɩ {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(ɩmegaa-Hɛrtɩ),
						'one' => q(megaa-Hɛrtɩ {0}),
						'other' => q(ɩmegaa-Hɛrtɩ {0}),
						'zero' => q(baa megaa-Hɛrtɩ {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(ɩmegaa-Hɛrtɩ),
						'one' => q(megaa-Hɛrtɩ {0}),
						'other' => q(ɩmegaa-Hɛrtɩ {0}),
						'zero' => q(baa megaa-Hɛrtɩ {0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ɩfɔɔ ɛm),
						'one' => q(ʊfɔɔ ɛm {0}),
						'other' => q(ɩfɔɔ ɛm {0}),
						'zero' => q(baa ʊfɔɔ ɛm),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ɩfɔɔ ɛm),
						'one' => q(ʊfɔɔ ɛm {0}),
						'other' => q(ɩfɔɔ ɛm {0}),
						'zero' => q(baa ʊfɔɔ ɛm),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ɩmegapisɛl),
						'one' => q(megapisɛl {0}),
						'other' => q(ɩmegapisɛl {0}),
						'zero' => q(baa megapisɛl),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ɩmegapisɛl),
						'one' => q(megapisɛl {0}),
						'other' => q(ɩmegapisɛl {0}),
						'zero' => q(baa megapisɛl),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ɩpisɛl),
						'one' => q(pisɛl {0}),
						'other' => q(ɩpisɛl {0}),
						'zero' => q(baa pisɛl),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ɩpisɛl),
						'one' => q(pisɛl {0}),
						'other' => q(ɩpisɛl {0}),
						'zero' => q(baa pisɛl),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ɩpisɛl sɛntimɛta bʊye bʊye nɩ),
						'one' => q(pisɛl {0} sɛntimɛta bʊye bʊye nɩ),
						'other' => q(ɩpisɛl {0} sɛntimɛta bʊye bʊye nɩ),
						'zero' => q(baa pisɛl sɛntimɛta bʊye bʊye nɩ),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ɩpisɛl sɛntimɛta bʊye bʊye nɩ),
						'one' => q(pisɛl {0} sɛntimɛta bʊye bʊye nɩ),
						'other' => q(ɩpisɛl {0} sɛntimɛta bʊye bʊye nɩ),
						'zero' => q(baa pisɛl sɛntimɛta bʊye bʊye nɩ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ɩpisɛl nsǝkǝmǝ bʊye bʊye nɩ),
						'one' => q(pisɛl {0} nsǝkǝmǝ bʊye bʊye nɩ),
						'other' => q(ɩpisɛl {0} nsǝkǝmǝ bʊye bʊye nɩ),
						'zero' => q(baa pisɛl nsǝkǝmǝ bʊye bʊye nɩ),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ɩpisɛl nsǝkǝmǝ bʊye bʊye nɩ),
						'one' => q(pisɛl {0} nsǝkǝmǝ bʊye bʊye nɩ),
						'other' => q(ɩpisɛl {0} nsǝkǝmǝ bʊye bʊye nɩ),
						'zero' => q(baa pisɛl nsǝkǝmǝ bʊye bʊye nɩ),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(atǝn-n’ʊshilè mána),
						'one' => q(atǝn-n’ʊshilè {0}),
						'other' => q(atǝn-n’ʊshilè mána {0}),
						'zero' => q(baa atǝn-n’ʊshilè {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(atǝn-n’ʊshilè mána),
						'one' => q(atǝn-n’ʊshilè {0}),
						'other' => q(atǝn-n’ʊshilè mána {0}),
						'zero' => q(baa atǝn-n’ʊshilè {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(ɩsɛntimɛta),
						'one' => q(sɛntimɛta {0}),
						'other' => q(ɩsɛntimɛta {0}),
						'per' => q({0} sɛntimɛta nɩ),
						'zero' => q(baa sɛntimɛta {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(ɩsɛntimɛta),
						'one' => q(sɛntimɛta {0}),
						'other' => q(ɩsɛntimɛta {0}),
						'per' => q({0} sɛntimɛta nɩ),
						'zero' => q(baa sɛntimɛta {0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ɩɖesimɛta),
						'one' => q(ɖesimɛta {0}),
						'other' => q(ɩɖesimɛta {0}),
						'zero' => q(baa ɖesimɛta {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ɩɖesimɛta),
						'one' => q(ɖesimɛta {0}),
						'other' => q(ɩɖesimɛta {0}),
						'zero' => q(baa ɖesimɛta {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(gatǝna gawalaka kʊfana),
						'one' => q(gatǝna gawalaka kʊfana {0}),
						'other' => q(gatǝna gawalaka kɩfana {0}),
						'zero' => q(baa gatǝna gawalaka kʊfana {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(gatǝna gawalaka kʊfana),
						'one' => q(gatǝna gawalaka kʊfana {0}),
						'other' => q(gatǝna gawalaka kɩfana {0}),
						'zero' => q(baa gatǝna gawalaka kʊfana {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(ɩfɛɛɖǝm),
						'one' => q(fɛɛɖǝm {0}),
						'other' => q(ɩfɛɛɖǝm {0}),
						'zero' => q(baa fɛɛɖǝm {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(ɩfɛɛɖǝm),
						'one' => q(fɛɛɖǝm {0}),
						'other' => q(ɩfɛɛɖǝm {0}),
						'zero' => q(baa fɛɛɖǝm {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(anaŋcǝna),
						'one' => q(gʊnaŋcǝna {0}),
						'other' => q(anaŋcǝna {0}),
						'per' => q({0}/gʊnaŋcǝna nɩ),
						'zero' => q(baa gʊnaŋcǝna {0}),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(anaŋcǝna),
						'one' => q(gʊnaŋcǝna {0}),
						'other' => q(anaŋcǝna {0}),
						'per' => q({0}/gʊnaŋcǝna nɩ),
						'zero' => q(baa gʊnaŋcǝna {0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(ɩfɛɛlɔŋ),
						'one' => q(fɛɛlɔŋ {0}),
						'other' => q(ɩfɛɛlɔŋ {0}),
						'zero' => q(baa fɛɛlɔŋ {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(ɩfɛɛlɔŋ),
						'one' => q(fɛɛlɔŋ {0}),
						'other' => q(ɩfɛɛlɔŋ {0}),
						'zero' => q(baa fɛɛlɔŋ {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(asǝkǝmǝ),
						'one' => q(nsǝkǝmǝ {0}),
						'other' => q(asǝkǝmǝ {0}),
						'per' => q({0} nsǝkǝmǝ nɩ),
						'zero' => q(baa nsǝkǝmǝ {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(asǝkǝmǝ),
						'one' => q(nsǝkǝmǝ {0}),
						'other' => q(asǝkǝmǝ {0}),
						'per' => q({0} nsǝkǝmǝ nɩ),
						'zero' => q(baa nsǝkǝmǝ {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ɩkiloomɛta),
						'one' => q(kiloomɛta {0}),
						'other' => q(ɩkiloomɛta {0}),
						'per' => q({0} kiloomɛta nɩ),
						'zero' => q(baa kiloomɛta {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ɩkiloomɛta),
						'one' => q(kiloomɛta {0}),
						'other' => q(ɩkiloomɛta {0}),
						'per' => q({0} kiloomɛta nɩ),
						'zero' => q(baa kiloomɛta {0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(pɔɩɩ-bʊja),
						'one' => q(pɔɩɩ-gaja {0}),
						'other' => q(pɔɩɩ-bʊja {0}),
						'zero' => q(baa pɔɩɩ-gaja {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(pɔɩɩ-bʊja),
						'one' => q(pɔɩɩ-gaja {0}),
						'other' => q(pɔɩɩ-bʊja {0}),
						'zero' => q(baa pɔɩɩ-gaja {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ɩmɛta),
						'one' => q(mɛta {0}),
						'other' => q(ɩmɛta {0}),
						'per' => q({0} mɛta nɩ),
						'zero' => q(baa mɛta {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ɩmɛta),
						'one' => q(mɛta {0}),
						'other' => q(ɩmɛta {0}),
						'per' => q({0} mɛta nɩ),
						'zero' => q(baa mɛta {0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(ɩmikroomɛta),
						'one' => q(mikroomɛta {0}),
						'other' => q(ɩmikroomɛta {0}),
						'zero' => q(baa mikroomɛta {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(ɩmikroomɛta),
						'one' => q(mikroomɛta {0}),
						'other' => q(ɩmikroomɛta {0}),
						'zero' => q(baa mikroomɛta {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ɩmayɩl),
						'one' => q(mayɩl {0}),
						'other' => q(ɩmayɩl {0}),
						'zero' => q(baa mayɩl {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ɩmayɩl),
						'one' => q(mayɩl {0}),
						'other' => q(ɩmayɩl {0}),
						'zero' => q(baa mayɩl {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sǝkanɖɩnaf kɩmayɩl),
						'one' => q(sǝkanɖɩnaf kamayɩl {0}),
						'other' => q(sǝkanɖɩnaf kɩmayɩl {0}),
						'zero' => q(baa sǝkanɖɩnaf kamayɩl {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sǝkanɖɩnaf kɩmayɩl),
						'one' => q(sǝkanɖɩnaf kamayɩl {0}),
						'other' => q(sǝkanɖɩnaf kɩmayɩl {0}),
						'zero' => q(baa sǝkanɖɩnaf kamayɩl {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ɩmilimɛta),
						'one' => q(milimɛta {0}),
						'other' => q(ɩmilimɛta {0}),
						'zero' => q(baa milimɛta {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ɩmilimɛta),
						'one' => q(milimɛta {0}),
						'other' => q(ɩmilimɛta {0}),
						'zero' => q(baa milimɛta {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(ɩnanoomɛta),
						'one' => q(nanoomɛta {0}),
						'other' => q(ɩnanoomɛta {0}),
						'zero' => q(baa nanoomɛta {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(ɩnanoomɛta),
						'one' => q(nanoomɛta {0}),
						'other' => q(ɩnanoomɛta {0}),
						'zero' => q(baa nanoomɛta {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(teŋku kɩmayɩl),
						'one' => q(teŋku kamayɩl {0}),
						'other' => q(teŋku kɩmayɩl {0}),
						'zero' => q(baa teŋku kamayɩl {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(teŋku kɩmayɩl),
						'one' => q(teŋku kamayɩl {0}),
						'other' => q(teŋku kɩmayɩl {0}),
						'zero' => q(baa teŋku kamayɩl {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ɩparsɛɛkɩ),
						'one' => q(parsɛɛkɩ {0}),
						'other' => q(ɩparsɛɛkɩ {0}),
						'zero' => q(baa parsɛɛkɩ {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ɩparsɛɛkɩ),
						'one' => q(parsɛɛkɩ {0}),
						'other' => q(ɩparsɛɛkɩ {0}),
						'zero' => q(baa parsɛɛkɩ {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(ɩpikoomɛta),
						'one' => q(pikoomɛta {0}),
						'other' => q(ɩpikoomɛta {0}),
						'zero' => q(baa pikoomɛta {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(ɩpikoomɛta),
						'one' => q(pikoomɛta {0}),
						'other' => q(ɩpikoomɛta {0}),
						'zero' => q(baa pikoomɛta {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ɩpipi),
						'one' => q(gɩpipi {0}),
						'other' => q(ɩpipi {0}),
						'zero' => q(baa gɩpipi {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ɩpipi),
						'one' => q(gɩpipi {0}),
						'other' => q(ɩpipi {0}),
						'zero' => q(baa gɩpipi {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ʊshilè kɩfana),
						'one' => q(ʊshilè kʊfana {0}),
						'other' => q(ʊshilè kɩfana {0}),
						'zero' => q(baa ʊshilè kʊfana),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ʊshilè kɩfana),
						'one' => q(ʊshilè kʊfana {0}),
						'other' => q(ʊshilè kɩfana {0}),
						'zero' => q(baa ʊshilè kʊfana),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ɩkanɖalaa),
						'one' => q(kanɖalaa {0}),
						'other' => q(ɩkanɖalaa {0}),
						'zero' => q(baa kanɖalaa {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ɩkanɖalaa),
						'one' => q(kanɖalaa {0}),
						'other' => q(ɩkanɖalaa {0}),
						'zero' => q(baa kanɖalaa {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(ɩlumɛn),
						'one' => q(lumɛn {0}),
						'other' => q(ɩlumɛn {0}),
						'zero' => q(baa lumɛn {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(ɩlumɛn),
						'one' => q(lumɛn {0}),
						'other' => q(ɩlumɛn {0}),
						'zero' => q(baa lumɛn {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(ɩlus),
						'one' => q(lus {0}),
						'other' => q(ɩlus {0}),
						'zero' => q(baa lus {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(ɩlus),
						'one' => q(lus {0}),
						'other' => q(ɩlus {0}),
						'zero' => q(baa lus {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(wʊra karaatɩ mána),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(wʊra karaatɩ mána),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ɩgram),
						'one' => q(gram {0}),
						'other' => q(ɩgram {0}),
						'per' => q({0} gram nɩ),
						'zero' => q(baa gram {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ɩgram),
						'one' => q(gram {0}),
						'other' => q(ɩgram {0}),
						'per' => q({0} gram nɩ),
						'zero' => q(baa gram {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(ɩkiloogram),
						'one' => q(kiloogram {0}),
						'other' => q(ɩkiloogram {0}),
						'per' => q({0} kiloogram nɩ),
						'zero' => q(baa kiloogram {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(ɩkiloogram),
						'one' => q(kiloogram {0}),
						'other' => q(ɩkiloogram {0}),
						'per' => q({0} kiloogram nɩ),
						'zero' => q(baa kiloogram {0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(ɩmikroogram),
						'one' => q(mikroogram {0}),
						'other' => q(ɩmikroogram {0}),
						'zero' => q(baa mikroogram {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(ɩmikroogram),
						'one' => q(mikroogram {0}),
						'other' => q(ɩmikroogram {0}),
						'zero' => q(baa mikroogram {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ɩmiligram),
						'one' => q(miligram {0}),
						'other' => q(ɩmiligram {0}),
						'zero' => q(baa miligram {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ɩmiligram),
						'one' => q(miligram {0}),
						'other' => q(ɩmiligram {0}),
						'zero' => q(baa miligram {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ɩpɔŋ),
						'one' => q(pɔŋ {0}),
						'other' => q(ɩpɔŋ {0}),
						'per' => q({0} pɔŋ nɩ),
						'zero' => q(baa pɔŋ {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ɩpɔŋ),
						'one' => q(pɔŋ {0}),
						'other' => q(ɩpɔŋ {0}),
						'per' => q({0} pɔŋ nɩ),
						'zero' => q(baa pɔŋ {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(atala),
						'one' => q(ntala {0}),
						'other' => q(atala {0}),
						'zero' => q(baa ntala {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(atala),
						'one' => q(ntala {0}),
						'other' => q(atala {0}),
						'zero' => q(baa ntala {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ɩtɔn Gɛɛshɩ kɩja),
						'one' => q(tɔn Gɛɛshɩ kaja {0}),
						'other' => q(tɔn Gɛɛshɩ kɩja {0}),
						'zero' => q(baa tɔn Gɛɛshɩ kaja {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ɩtɔn Gɛɛshɩ kɩja),
						'one' => q(tɔn Gɛɛshɩ kaja {0}),
						'other' => q(tɔn Gɛɛshɩ kɩja {0}),
						'zero' => q(baa tɔn Gɛɛshɩ kaja {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ɩtɔn mɛta kʊfaŋʊ kɩja),
						'one' => q(tɔn {0}),
						'other' => q(ɩtɔn {0}),
						'zero' => q(baa tɔn {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ɩtɔn mɛta kʊfaŋʊ kɩja),
						'one' => q(tɔn {0}),
						'other' => q(ɩtɔn {0}),
						'zero' => q(baa tɔn {0}),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} {1} nɩ),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} {1} nɩ),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(ɩjigaa-Waatɩ),
						'one' => q(jigaa-Waatɩ {0}),
						'other' => q(ɩjigaa-Waatɩ {0}),
						'zero' => q(baa jigaa-Waatɩ {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(ɩjigaa-Waatɩ),
						'one' => q(jigaa-Waatɩ {0}),
						'other' => q(ɩjigaa-Waatɩ {0}),
						'zero' => q(baa jigaa-Waatɩ {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(asuko-‘ɩkaŋkɩrɩ),
						'one' => q(asuko-‘ɩkaŋkɩrɩ {0}),
						'other' => q(asuko-‘ɩkaŋkɩrɩ {0}),
						'zero' => q(baa asuko-‘ɩkaŋkɩrɩ),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(asuko-‘ɩkaŋkɩrɩ),
						'one' => q(asuko-‘ɩkaŋkɩrɩ {0}),
						'other' => q(asuko-‘ɩkaŋkɩrɩ {0}),
						'zero' => q(baa asuko-‘ɩkaŋkɩrɩ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kiloo-Waatɩ),
						'one' => q(kiloo-Waatɩ {0}),
						'other' => q(ɩkiloo-Waatɩ {0}),
						'zero' => q(baa kiloo-Waatɩ {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kiloo-Waatɩ),
						'one' => q(kiloo-Waatɩ {0}),
						'other' => q(ɩkiloo-Waatɩ {0}),
						'zero' => q(baa kiloo-Waatɩ {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(ɩmegaa-Waatɩ),
						'one' => q(megaa-Waatɩ {0}),
						'other' => q(ɩmegaa-Waatɩ {0}),
						'zero' => q(baa megaa-Waatɩ {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(ɩmegaa-Waatɩ),
						'one' => q(megaa-Waatɩ {0}),
						'other' => q(ɩmegaa-Waatɩ {0}),
						'zero' => q(baa megaa-Waatɩ {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ɩmili-Waatɩ),
						'one' => q(mili-Waatɩ {0}),
						'other' => q(ɩmili-Waatɩ {0}),
						'zero' => q(baa mili-Waatɩ {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ɩmili-Waatɩ),
						'one' => q(mili-Waatɩ {0}),
						'other' => q(ɩmili-Waatɩ {0}),
						'zero' => q(baa mili-Waatɩ {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Waatɩ),
						'one' => q(Waatɩ {0}),
						'other' => q(ɩWaatɩ {0}),
						'zero' => q(baa Waatɩ {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Waatɩ),
						'one' => q(Waatɩ {0}),
						'other' => q(ɩWaatɩ {0}),
						'zero' => q(baa Waatɩ {0}),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q({0} bʊye bʊye),
						'other' => q({0} bʊye bʊye),
						'zero' => q({0} bʊye bʊye),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} bʊye bʊye),
						'other' => q({0} bʊye bʊye),
						'zero' => q({0} bʊye bʊye),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q({0} bʊye bʊriu),
						'other' => q({0} bʊye bʊriu),
						'zero' => q({0} bʊye bʊriu),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q({0} bʊye bʊriu),
						'other' => q({0} bʊye bʊriu),
						'zero' => q({0} bʊye bʊriu),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atǝmɔsfɛɛr mána),
						'one' => q(atǝmɔsfɛɛr {0}),
						'other' => q(atǝmɔsfɛɛr mána {0}),
						'zero' => q(baa atǝmɔsfɛɛr {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atǝmɔsfɛɛr mána),
						'one' => q(atǝmɔsfɛɛr {0}),
						'other' => q(atǝmɔsfɛɛr mána {0}),
						'zero' => q(baa atǝmɔsfɛɛr {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ɩbaar),
						'one' => q(baar {0}),
						'other' => q(ɩbaar {0}),
						'zero' => q(baa baar {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ɩbaar),
						'one' => q(baar {0}),
						'other' => q(ɩbaar {0}),
						'zero' => q(baa baar {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ɩhɛktoo-Paskal),
						'one' => q(hɛktoo-Paskal {0}),
						'other' => q(ɩhɛktoo-Paskal {0}),
						'zero' => q(baa hɛktoo-Paskal {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ɩhɛktoo-Paskal),
						'one' => q(hɛktoo-Paskal {0}),
						'other' => q(ɩhɛktoo-Paskal {0}),
						'zero' => q(baa hɛktoo-Paskal {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(mɛrkiir kasǝkǝmǝ),
						'one' => q(mɛrkiir kansǝkǝmǝ {0}),
						'other' => q(mɛrkiir kasǝkǝmǝ {0}),
						'zero' => q(baa mɛrkiir kansǝkǝmǝ {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(mɛrkiir kasǝkǝmǝ),
						'one' => q(mɛrkiir kansǝkǝmǝ {0}),
						'other' => q(mɛrkiir kasǝkǝmǝ {0}),
						'zero' => q(baa mɛrkiir kansǝkǝmǝ {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(ɩkiloo-Paskal),
						'one' => q(kiloo-Paskal {0}),
						'other' => q(ɩkiloo-Paskal {0}),
						'zero' => q(baa kiloo-Paskal {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(ɩkiloo-Paskal),
						'one' => q(kiloo-Paskal {0}),
						'other' => q(ɩkiloo-Paskal {0}),
						'zero' => q(baa kiloo-Paskal {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(ɩmegaa-Paskal),
						'one' => q(megaa-Paskal {0}),
						'other' => q(ɩmegaa-Paskal {0}),
						'zero' => q(baa megaa-Paskal {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(ɩmegaa-Paskal),
						'one' => q(megaa-Paskal {0}),
						'other' => q(ɩmegaa-Paskal {0}),
						'zero' => q(baa megaa-Paskal {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ɩmilibaar),
						'one' => q(milibaar {0}),
						'other' => q(ɩmilibaar {0}),
						'zero' => q(baa milibaar {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ɩmilibaar),
						'one' => q(milibaar {0}),
						'other' => q(ɩmilibaar {0}),
						'zero' => q(baa milibaar {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mɛrkiir kɩmilimɛta),
						'one' => q(mɛrkiir kamilimɛta {0}),
						'other' => q(mɛrkiir kɩmilimɛta {0}),
						'zero' => q(baa mɛrkiir kamilimɛta {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mɛrkiir kɩmilimɛta),
						'one' => q(mɛrkiir kamilimɛta {0}),
						'other' => q(mɛrkiir kɩmilimɛta {0}),
						'zero' => q(baa mɛrkiir kamilimɛta {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(ɩPaskal),
						'one' => q(Paskal {0}),
						'other' => q(ɩPaskal {0}),
						'zero' => q(baa Paskal {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(ɩPaskal),
						'one' => q(Paskal {0}),
						'other' => q(ɩPaskal {0}),
						'zero' => q(baa Paskal {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(ɩkiloomɛta gakɔŋkɔŋɔ̀ nɩ),
						'one' => q(kiloomɛta gakɔŋkɔŋɔ̀ nɩ {0}),
						'other' => q(ɩkiloomɛta gakɔŋkɔŋɔ̀ nɩ {0}),
						'zero' => q(baa kiloomɛta gakɔŋkɔŋɔ̀ nɩ {0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(ɩkiloomɛta gakɔŋkɔŋɔ̀ nɩ),
						'one' => q(kiloomɛta gakɔŋkɔŋɔ̀ nɩ {0}),
						'other' => q(ɩkiloomɛta gakɔŋkɔŋɔ̀ nɩ {0}),
						'zero' => q(baa kiloomɛta gakɔŋkɔŋɔ̀ nɩ {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(akʊra),
						'one' => q(ŋkʊra {0}),
						'other' => q(akʊra {0}),
						'zero' => q(baa ŋkʊra {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(akʊra),
						'one' => q(ŋkʊra {0}),
						'other' => q(akʊra {0}),
						'zero' => q(baa ŋkʊra {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(pɔɩɩ),
						'one' => q(pɔɩɩ {0}),
						'other' => q(pɔɩɩ {0}),
						'zero' => q(pɔɩɩ {0}),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(pɔɩɩ),
						'one' => q(pɔɩɩ {0}),
						'other' => q(pɔɩɩ {0}),
						'zero' => q(pɔɩɩ {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ɩmɛta gɩpi nɩ),
						'one' => q(mɛta gɩpi nɩ {0}),
						'other' => q(ɩmɛta gɩpi nɩ {0}),
						'zero' => q(baa mɛta gɩpi nɩ {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ɩmɛta gɩpi nɩ),
						'one' => q(mɛta gɩpi nɩ {0}),
						'other' => q(ɩmɛta gɩpi nɩ {0}),
						'zero' => q(baa mɛta gɩpi nɩ {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ɩmayɩl gakɔŋkɔŋɔ̀ nɩ),
						'one' => q(mayɩl gakɔŋkɔŋɔ̀ nɩ {0}),
						'other' => q(ɩmayɩl gakɔŋkɔŋɔ̀ nɩ {0}),
						'zero' => q(baa mayɩl gakɔŋkɔŋɔ̀ nɩ {0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ɩmayɩl gakɔŋkɔŋɔ̀ nɩ),
						'one' => q(mayɩl gakɔŋkɔŋɔ̀ nɩ {0}),
						'other' => q(ɩmayɩl gakɔŋkɔŋɔ̀ nɩ {0}),
						'zero' => q(baa mayɩl gakɔŋkɔŋɔ̀ nɩ {0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ɩɖegre Sɛlsus),
						'one' => q(ɖegre Sɛlsus {0}),
						'other' => q(ɩɖegre Sɛlsus {0}),
						'zero' => q(baa ɖegre Sɛlsus {0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ɩɖegre Sɛlsus),
						'one' => q(ɖegre Sɛlsus {0}),
						'other' => q(ɩɖegre Sɛlsus {0}),
						'zero' => q(baa ɖegre Sɛlsus {0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ɩɖegre Faranhaɩt),
						'one' => q(ɖegre Faranhaɩt {0}),
						'other' => q(ɩɖegre Faranhaɩt {0}),
						'zero' => q(baa ɖegre Faranhaɩt {0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ɩɖegre Faranhaɩt),
						'one' => q(ɖegre Faranhaɩt {0}),
						'other' => q(ɩɖegre Faranhaɩt {0}),
						'zero' => q(baa ɖegre Faranhaɩt {0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(kpaʊ-na-sarasara kɩɖegre),
						'one' => q(kpaʊ-na-sarasara kaɖegre {0}),
						'other' => q(kpaʊ-na-sarasara kɩɖegre {0}),
						'zero' => q(baa kpaʊ-na-sarasara kaɖegre {0}),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(kpaʊ-na-sarasara kɩɖegre),
						'one' => q(kpaʊ-na-sarasara kaɖegre {0}),
						'other' => q(kpaʊ-na-sarasara kɩɖegre {0}),
						'zero' => q(baa kpaʊ-na-sarasara kaɖegre {0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(ɩKɛlwin),
						'one' => q(Kɛlwin {0}),
						'other' => q(ɩKɛlwin {0}),
						'zero' => q(baa Kɛlwin {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(ɩKɛlwin),
						'one' => q(Kɛlwin {0}),
						'other' => q(ɩKɛlwin {0}),
						'zero' => q(baa Kɛlwin {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(ɩNiutɔn-mɛta),
						'one' => q(Niutɔn-mɛta {0}),
						'other' => q(ɩNiutɔn-mɛta {0}),
						'zero' => q(baa Niutɔn-mɛta {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(ɩNiutɔn-mɛta),
						'one' => q(Niutɔn-mɛta {0}),
						'other' => q(ɩNiutɔn-mɛta {0}),
						'zero' => q(baa Niutɔn-mɛta {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ɩsɛntilitri),
						'one' => q(sɛntilitri {0}),
						'other' => q(ɩsɛntilitri {0}),
						'zero' => q(baa sɛntilitri {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ɩsɛntilitri),
						'one' => q(sɛntilitri {0}),
						'other' => q(ɩsɛntilitri {0}),
						'zero' => q(baa sɛntilitri {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(ɩsɛntimɛta bʊye bʊriu),
						'one' => q(sɛntimɛta bʊye bʊriu {0}),
						'other' => q(ɩsɛntimɛta bʊye bʊriu {0}),
						'per' => q({0} ɩsɛntimɛta bʊye bʊriu nɩ),
						'zero' => q(baa sɛntimɛta bʊye bʊriu {0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(ɩsɛntimɛta bʊye bʊriu),
						'one' => q(sɛntimɛta bʊye bʊriu {0}),
						'other' => q(ɩsɛntimɛta bʊye bʊriu {0}),
						'per' => q({0} ɩsɛntimɛta bʊye bʊriu nɩ),
						'zero' => q(baa sɛntimɛta bʊye bʊriu {0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(anaŋcǝna bʊyɛ bʊriu),
						'one' => q(gʊnaŋcǝna bʊyɛ bʊriu {0}),
						'other' => q(anaŋcǝna bʊyɛ bʊriu {0}),
						'zero' => q(baa gʊnaŋcǝna bʊyɛ bʊriu {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(anaŋcǝna bʊyɛ bʊriu),
						'one' => q(gʊnaŋcǝna bʊyɛ bʊriu {0}),
						'other' => q(anaŋcǝna bʊyɛ bʊriu {0}),
						'zero' => q(baa gʊnaŋcǝna bʊyɛ bʊriu {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(asǝkǝmǝ bʊyɛ bʊriu),
						'one' => q(nsǝkǝmǝ bʊyɛ bʊriu {0}),
						'other' => q(asǝkǝmǝ bʊyɛ bʊriu {0}),
						'zero' => q(baa nsǝkǝmǝ bʊyɛ bʊriu {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(asǝkǝmǝ bʊyɛ bʊriu),
						'one' => q(nsǝkǝmǝ bʊyɛ bʊriu {0}),
						'other' => q(asǝkǝmǝ bʊyɛ bʊriu {0}),
						'zero' => q(baa nsǝkǝmǝ bʊyɛ bʊriu {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(ɩkiloomɛta bʊyɛ bʊriu),
						'one' => q(kiloomɛta bʊye bʊriu {0}),
						'other' => q(ɩkiloomɛta bʊye bʊriu {0}),
						'zero' => q(baa kiloomɛta bʊye bʊriu {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(ɩkiloomɛta bʊyɛ bʊriu),
						'one' => q(kiloomɛta bʊye bʊriu {0}),
						'other' => q(ɩkiloomɛta bʊye bʊriu {0}),
						'zero' => q(baa kiloomɛta bʊye bʊriu {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(ɩmɛta bʊyɛ bʊriu),
						'one' => q(mɛta bʊyɛ bʊriu {0}),
						'other' => q(ɩmɛta bʊyɛ bʊriu {0}),
						'per' => q({0} ɩmɛta bʊyɛ bʊriu nɩ),
						'zero' => q(baa mɛta bʊyɛ bʊriu {0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(ɩmɛta bʊyɛ bʊriu),
						'one' => q(mɛta bʊyɛ bʊriu {0}),
						'other' => q(ɩmɛta bʊyɛ bʊriu {0}),
						'per' => q({0} ɩmɛta bʊyɛ bʊriu nɩ),
						'zero' => q(baa mɛta bʊyɛ bʊriu {0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(ɩmayɩl bʊyɛ bʊriu),
						'one' => q(mayɩl bʊyɛ bʊriu {0}),
						'other' => q(ɩmayɩl bʊyɛ bʊriu {0}),
						'zero' => q(baa mayɩl bʊyɛ bʊriu {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ɩmayɩl bʊyɛ bʊriu),
						'one' => q(mayɩl bʊyɛ bʊriu {0}),
						'other' => q(ɩmayɩl bʊyɛ bʊriu {0}),
						'zero' => q(baa mayɩl bʊyɛ bʊriu {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ɩkɔɔpʊ),
						'one' => q(kɔɔpʊ {0}),
						'other' => q(ɩkɔɔpʊ {0}),
						'zero' => q(baa kɔɔpʊ {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ɩkɔɔpʊ),
						'one' => q(kɔɔpʊ {0}),
						'other' => q(ɩkɔɔpʊ {0}),
						'zero' => q(baa kɔɔpʊ {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ɩkɔɔpʊ mɛta kʊfaŋʊ kɩja),
						'one' => q(kɔɔpʊ mɛta kʊfaŋʊ kɩja {0}),
						'other' => q(ɩkɔɔpʊ mɛta kʊfaŋʊ kɩja {0}),
						'zero' => q(baa kɔɔpʊ mɛta kʊfaŋʊ kɩja {0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ɩkɔɔpʊ mɛta kʊfaŋʊ kɩja),
						'one' => q(kɔɔpʊ mɛta kʊfaŋʊ kɩja {0}),
						'other' => q(ɩkɔɔpʊ mɛta kʊfaŋʊ kɩja {0}),
						'zero' => q(baa kɔɔpʊ mɛta kʊfaŋʊ kɩja {0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ɩɖesilitri),
						'one' => q(ɖesilitri {0}),
						'other' => q(ɩɖesilitri {0}),
						'zero' => q(baa ɖesilitri {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ɩɖesilitri),
						'one' => q(ɖesilitri {0}),
						'other' => q(ɩɖesilitri {0}),
						'zero' => q(baa ɖesilitri {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ɩɖraam),
						'one' => q(ɖraam {0}),
						'other' => q(ɩɖraam {0}),
						'zero' => q(baa ɖraam {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ɩɖraam),
						'one' => q(ɖraam {0}),
						'other' => q(ɩɖraam {0}),
						'zero' => q(baa ɖraam {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ɩsɔr),
						'one' => q(ʊsɔr {0}),
						'other' => q(ɩsɔr {0}),
						'zero' => q(baa ʊsɔr {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ɩsɔr),
						'one' => q(ʊsɔr {0}),
						'other' => q(ɩsɔr {0}),
						'zero' => q(baa ʊsɔr {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(ɩgaalɔŋ Amalɩka kʊfaŋʊ kɩja),
						'one' => q(gaalɔŋ Amalɩka kʊfaŋʊ kaja {0}),
						'other' => q(ɩgaalɔŋ Amalɩka kʊfaŋʊ kɩja {0}),
						'per' => q({0} gaalɔŋ nɩ),
						'zero' => q(baa gaalɔŋ Amalɩka kʊfaŋʊ kaja {0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(ɩgaalɔŋ Amalɩka kʊfaŋʊ kɩja),
						'one' => q(gaalɔŋ Amalɩka kʊfaŋʊ kaja {0}),
						'other' => q(ɩgaalɔŋ Amalɩka kʊfaŋʊ kɩja {0}),
						'per' => q({0} gaalɔŋ nɩ),
						'zero' => q(baa gaalɔŋ Amalɩka kʊfaŋʊ kaja {0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ɩgaalɔŋ gɛɛshɩ kɩja),
						'one' => q(gaalɔŋ gɛɛshɩ kaja {0}),
						'other' => q(ɩgaalɔŋ gɛɛshɩ kɩja {0}),
						'per' => q({0} gaalɔŋ gɛɛshɩ kaja nɩ),
						'zero' => q(baa gaalɔŋ gɛɛshɩ kaja {0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ɩgaalɔŋ gɛɛshɩ kɩja),
						'one' => q(gaalɔŋ gɛɛshɩ kaja {0}),
						'other' => q(ɩgaalɔŋ gɛɛshɩ kɩja {0}),
						'per' => q({0} gaalɔŋ gɛɛshɩ kaja nɩ),
						'zero' => q(baa gaalɔŋ gɛɛshɩ kaja {0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ɩhɛktoolitri),
						'one' => q(hɛktoolitri {0}),
						'other' => q(ɩhɛktoolitri {0}),
						'zero' => q(baa hɛktoolitri {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ɩhɛktoolitri),
						'one' => q(hɛktoolitri {0}),
						'other' => q(ɩhɛktoolitri {0}),
						'zero' => q(baa hɛktoolitri {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(ɩjɩga),
						'one' => q(jɩga {0}),
						'other' => q(ɩjɩga {0}),
						'zero' => q(baa jɩga {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(ɩjɩga),
						'one' => q(jɩga {0}),
						'other' => q(ɩjɩga {0}),
						'zero' => q(baa jɩga {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ɩlitri),
						'one' => q(litri {0}),
						'other' => q(ɩlitri {0}),
						'per' => q({0} ɩlitri nɩ),
						'zero' => q(baa litri {0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ɩlitri),
						'one' => q(litri {0}),
						'other' => q(ɩlitri {0}),
						'per' => q({0} ɩlitri nɩ),
						'zero' => q(baa litri {0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ɩmegaalitri),
						'one' => q(megaalitri {0}),
						'other' => q(ɩmegaalitri {0}),
						'zero' => q(baa megaalitri {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ɩmegaalitri),
						'one' => q(megaalitri {0}),
						'other' => q(ɩmegaalitri {0}),
						'zero' => q(baa megaalitri {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ɩmililitri),
						'one' => q(mililitri {0}),
						'other' => q(ɩmililitri {0}),
						'zero' => q(baa mililitri {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ɩmililitri),
						'one' => q(mililitri {0}),
						'other' => q(ɩmililitri {0}),
						'zero' => q(baa mililitri {0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ɩkɩtɩʊ),
						'one' => q(ʊkɩtɩʊ {0}),
						'other' => q(ɩkɩtɩʊ {0}),
						'zero' => q(baa ʊkɩtɩʊ {0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ɩkɩtɩʊ),
						'one' => q(ʊkɩtɩʊ {0}),
						'other' => q(ɩkɩtɩʊ {0}),
						'zero' => q(baa ʊkɩtɩʊ {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(litri kasaʊ),
						'one' => q(litri kansaʊ {0}),
						'other' => q(litri kasaʊ {0}),
						'zero' => q(baa litri kansaʊ {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(litri kasaʊ),
						'one' => q(litri kansaʊ {0}),
						'other' => q(litri kasaʊ {0}),
						'zero' => q(baa litri kansaʊ {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ɩtɩrɩɩ ʊnyɩʊ kɩja),
						'one' => q(tɩrɩɩ ʊnyɩʊ kaja {0}),
						'other' => q(ɩtɩrɩɩ ʊnyɩʊ kɩja {0}),
						'zero' => q(baa tɩrɩɩ ʊnyɩʊ kaja {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ɩtɩrɩɩ ʊnyɩʊ kɩja),
						'one' => q(tɩrɩɩ ʊnyɩʊ kaja {0}),
						'other' => q(ɩtɩrɩɩ ʊnyɩʊ kɩja {0}),
						'zero' => q(baa tɩrɩɩ ʊnyɩʊ kaja {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ɩtɩrɩɩ kafee kɩja),
						'one' => q(tɩrɩɩ kafee kaja {0}),
						'other' => q(ɩtɩrɩɩ kafee kɩja {0}),
						'zero' => q(baa tɩrɩɩ kafee kaja {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ɩtɩrɩɩ kafee kɩja),
						'one' => q(tɩrɩɩ kafee kaja {0}),
						'other' => q(ɩtɩrɩɩ kafee kɩja {0}),
						'zero' => q(baa tɩrɩɩ kafee kaja {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q(G{0}),
						'other' => q(G{0}),
						'zero' => q(G{0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q(G{0}),
						'other' => q(G{0}),
						'zero' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q(m/s²{0}),
						'other' => q(m/s²{0}),
						'zero' => q(m/s²{0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q(m/s²{0}),
						'other' => q(m/s²{0}),
						'zero' => q(m/s²{0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q(′{0}),
						'other' => q(′{0}),
						'zero' => q(′{0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q(′{0}),
						'other' => q(′{0}),
						'zero' => q(′{0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q(″{0}),
						'other' => q(″{0}),
						'zero' => q(″{0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q(″{0}),
						'other' => q(″{0}),
						'zero' => q(″{0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q(rad{0}),
						'other' => q(rad{0}),
						'zero' => q(rad{0}),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q(rad{0}),
						'other' => q(rad{0}),
						'zero' => q(rad{0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q(rev{0}),
						'other' => q(rev{0}),
						'zero' => q(rev{0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q(rev{0}),
						'other' => q(rev{0}),
						'zero' => q(rev{0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ɖunam),
						'one' => q(ɖunam {0}),
						'other' => q(ɩɖunam {0}),
						'zero' => q(baa ɖunam{0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ɖunam),
						'one' => q(ɖunam {0}),
						'other' => q(ɩɖunam {0}),
						'zero' => q(baa ɖunam{0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ʊlɔ),
						'one' => q(ha{0}),
						'other' => q(ha{0}),
						'zero' => q(ha{0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ʊlɔ),
						'one' => q(ha{0}),
						'other' => q(ha{0}),
						'zero' => q(ha{0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q(cm²{0}),
						'other' => q(cm²{0}),
						'zero' => q(cm²{0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q(cm²{0}),
						'other' => q(cm²{0}),
						'zero' => q(cm²{0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q(ft²{0}),
						'other' => q(ft²{0}),
						'zero' => q(ft²{0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q(ft²{0}),
						'other' => q(ft²{0}),
						'zero' => q(ft²{0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q(in²{0}),
						'other' => q(in²{0}),
						'zero' => q(in²{0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q(in²{0}),
						'other' => q(in²{0}),
						'zero' => q(in²{0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q(km²{0}),
						'other' => q(km²{0}),
						'zero' => q(km²{0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q(km²{0}),
						'other' => q(km²{0}),
						'zero' => q(km²{0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ɩmɛta²),
						'one' => q(m²{0}),
						'other' => q(m²{0}),
						'zero' => q(m²{0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ɩmɛta²),
						'one' => q(m²{0}),
						'other' => q(m²{0}),
						'zero' => q(m²{0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q(mi²{0}),
						'other' => q(mi²{0}),
						'zero' => q(mi²{0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q(mi²{0}),
						'other' => q(mi²{0}),
						'zero' => q(mi²{0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q(yd²{0}),
						'other' => q(yd²{0}),
						'zero' => q(yd²{0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q(yd²{0}),
						'other' => q(yd²{0}),
						'zero' => q(yd²{0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q(item{0}),
						'other' => q(item{0}),
						'zero' => q(item{0}),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q(item{0}),
						'other' => q(item{0}),
						'zero' => q(item{0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q(kt{0}),
						'other' => q(kt{0}),
						'zero' => q(kt{0}),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q(kt{0}),
						'other' => q(kt{0}),
						'zero' => q(kt{0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL{0}),
						'other' => q(mg/dL{0}),
						'zero' => q(mg/dL{0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL{0}),
						'other' => q(mg/dL{0}),
						'zero' => q(mg/dL{0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q(mmol/L{0}),
						'other' => q(mmol/L{0}),
						'zero' => q(mmol/L{0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q(mmol/L{0}),
						'other' => q(mmol/L{0}),
						'zero' => q(mmol/L{0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q(mol{0}),
						'other' => q(mol{0}),
						'zero' => q(mol{0}),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q(mol{0}),
						'other' => q(mol{0}),
						'zero' => q(mol{0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
						'zero' => q(%{0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
						'zero' => q(%{0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q(‰{0}),
						'other' => q(‰{0}),
						'zero' => q(‰{0}),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q(‰{0}),
						'other' => q(‰{0}),
						'zero' => q(‰{0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q(ppm{0}),
						'other' => q(ppm{0}),
						'zero' => q(ppm{0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q(ppm{0}),
						'other' => q(ppm{0}),
						'zero' => q(ppm{0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(‱{0}),
						'other' => q(‱{0}),
						'zero' => q(‱{0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(‱{0}),
						'other' => q(‱{0}),
						'zero' => q(‱{0}),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'one' => q(ppb{0}),
						'other' => q(ppb{0}),
						'zero' => q(ppb{0}),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'one' => q(ppb{0}),
						'other' => q(ppb{0}),
						'zero' => q(ppb{0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q(L/100km{0}),
						'other' => q(L/100km{0}),
						'zero' => q(L/100km{0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q(L/100km{0}),
						'other' => q(L/100km{0}),
						'zero' => q(L/100km{0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q(L/km{0}),
						'other' => q(L/km{0}),
						'zero' => q(L/km{0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q(L/km{0}),
						'other' => q(L/km{0}),
						'zero' => q(L/km{0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q(mpg{0}),
						'other' => q(mpg{0}),
						'zero' => q(mpg{0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q(mpg{0}),
						'other' => q(mpg{0}),
						'zero' => q(mpg{0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q(mpg Imp.{0}),
						'other' => q(mpg Imp.{0}),
						'zero' => q(mpg Imp.{0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q(mpg Imp.{0}),
						'other' => q(mpg Imp.{0}),
						'zero' => q(mpg Imp.{0}),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q(A{0}),
						'other' => q(A{0}),
						'zero' => q(A{0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q(A{0}),
						'other' => q(A{0}),
						'zero' => q(A{0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q(mA{0}),
						'other' => q(mA{0}),
						'zero' => q(mA{0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q(mA{0}),
						'other' => q(mA{0}),
						'zero' => q(mA{0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q(Ω{0}),
						'other' => q(Ω{0}),
						'zero' => q(Ω{0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q(Ω{0}),
						'other' => q(Ω{0}),
						'zero' => q(Ω{0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q(V{0}),
						'other' => q(V{0}),
						'zero' => q(V{0}),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q(V{0}),
						'other' => q(V{0}),
						'zero' => q(V{0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q(Btu{0}),
						'other' => q(Btu{0}),
						'zero' => q(Btu{0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q(Btu{0}),
						'other' => q(Btu{0}),
						'zero' => q(Btu{0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q(cal{0}),
						'other' => q(cal{0}),
						'zero' => q(cal{0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q(cal{0}),
						'other' => q(cal{0}),
						'zero' => q(cal{0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q(eV{0}),
						'other' => q(eV{0}),
						'zero' => q(eV{0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q(eV{0}),
						'other' => q(eV{0}),
						'zero' => q(eV{0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(jul),
						'one' => q(J{0}),
						'other' => q(J{0}),
						'zero' => q(J{0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jul),
						'one' => q(J{0}),
						'other' => q(J{0}),
						'zero' => q(J{0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q(kcal{0}),
						'other' => q(kcal{0}),
						'zero' => q(kcal{0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q(kcal{0}),
						'other' => q(kcal{0}),
						'zero' => q(kcal{0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q(kJ{0}),
						'other' => q(kJ{0}),
						'zero' => q(kJ{0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q(kJ{0}),
						'other' => q(kJ{0}),
						'zero' => q(kJ{0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q(kWh{0}),
						'other' => q(kWh{0}),
						'zero' => q(kWh{0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q(kWh{0}),
						'other' => q(kWh{0}),
						'zero' => q(kWh{0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q(US therm{0}),
						'other' => q(US therm{0}),
						'zero' => q(US therm{0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q(US therm{0}),
						'other' => q(US therm{0}),
						'zero' => q(US therm{0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km{0}),
						'other' => q(kWh/100km{0}),
						'zero' => q(kWh/100km{0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km{0}),
						'other' => q(kWh/100km{0}),
						'zero' => q(kWh/100km{0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q(N{0}),
						'other' => q(N{0}),
						'zero' => q(N{0}),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q(N{0}),
						'other' => q(N{0}),
						'zero' => q(N{0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q(GHz{0}),
						'other' => q(GHz{0}),
						'zero' => q(GHz{0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q(GHz{0}),
						'other' => q(GHz{0}),
						'zero' => q(GHz{0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q(Hz{0}),
						'other' => q(Hz{0}),
						'zero' => q(Hz{0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q(Hz{0}),
						'other' => q(Hz{0}),
						'zero' => q(Hz{0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q(kHz{0}),
						'other' => q(kHz{0}),
						'zero' => q(kHz{0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q(kHz{0}),
						'other' => q(kHz{0}),
						'zero' => q(kHz{0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q(MHz{0}),
						'other' => q(MHz{0}),
						'zero' => q(MHz{0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q(MHz{0}),
						'other' => q(MHz{0}),
						'zero' => q(MHz{0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q(em {0}),
						'other' => q(em {0}),
						'zero' => q(em {0}),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q(em {0}),
						'other' => q(em {0}),
						'zero' => q(em {0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q(au{0}),
						'other' => q(au{0}),
						'zero' => q(au{0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q(au{0}),
						'other' => q(au{0}),
						'zero' => q(au{0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q(cm{0}),
						'other' => q(cm{0}),
						'zero' => q(cm{0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q(cm{0}),
						'other' => q(cm{0}),
						'zero' => q(cm{0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q(dm{0}),
						'other' => q(dm{0}),
						'zero' => q(dm{0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q(dm{0}),
						'other' => q(dm{0}),
						'zero' => q(dm{0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q(R⊕{0}),
						'other' => q(R⊕{0}),
						'zero' => q(R⊕{0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q(R⊕{0}),
						'other' => q(R⊕{0}),
						'zero' => q(R⊕{0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fɛɛɖǝm),
						'one' => q(fth{0}),
						'other' => q(fth{0}),
						'zero' => q(fth{0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fɛɛɖǝm),
						'one' => q(fth{0}),
						'other' => q(fth{0}),
						'zero' => q(fth{0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q(′{0}),
						'other' => q(′{0}),
						'zero' => q(′{0}),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q(′{0}),
						'other' => q(′{0}),
						'zero' => q(′{0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fɛɛlɔŋ),
						'one' => q(fur{0}),
						'other' => q(fur{0}),
						'zero' => q(fur{0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fɛɛlɔŋ),
						'one' => q(fur{0}),
						'other' => q(fur{0}),
						'zero' => q(fur{0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q(′′{0}),
						'other' => q(′′{0}),
						'zero' => q(′′{0}),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q(′′{0}),
						'other' => q(′′{0}),
						'zero' => q(′′{0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q(km{0}),
						'other' => q(km{0}),
						'zero' => q(km{0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q(km{0}),
						'other' => q(km{0}),
						'zero' => q(km{0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q(ly{0}),
						'other' => q(ly{0}),
						'zero' => q(ly{0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q(ly{0}),
						'other' => q(ly{0}),
						'zero' => q(ly{0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q(m{0}),
						'other' => q(m{0}),
						'zero' => q(m{0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q(m{0}),
						'other' => q(m{0}),
						'zero' => q(m{0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q(μm{0}),
						'other' => q(μm{0}),
						'zero' => q(μm{0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q(μm{0}),
						'other' => q(μm{0}),
						'zero' => q(μm{0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ɩmayɩl),
						'one' => q(mi{0}),
						'other' => q(mi{0}),
						'zero' => q(mi{0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ɩmayɩl),
						'one' => q(mi{0}),
						'other' => q(mi{0}),
						'zero' => q(mi{0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q(smi{0}),
						'other' => q(smi{0}),
						'zero' => q(smi{0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q(smi{0}),
						'other' => q(smi{0}),
						'zero' => q(smi{0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
						'zero' => q(mm{0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
						'zero' => q(mm{0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q(nm{0}),
						'other' => q(nm{0}),
						'zero' => q(nm{0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q(nm{0}),
						'other' => q(nm{0}),
						'zero' => q(nm{0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q(nmi{0}),
						'other' => q(nmi{0}),
						'zero' => q(nmi{0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q(nmi{0}),
						'other' => q(nmi{0}),
						'zero' => q(nmi{0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsɛɛkɩ),
						'one' => q(pc{0}),
						'other' => q(pc{0}),
						'zero' => q(pc{0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsɛɛkɩ),
						'one' => q(pc{0}),
						'other' => q(pc{0}),
						'zero' => q(pc{0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q(pm{0}),
						'other' => q(pm{0}),
						'zero' => q(pm{0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q(pm{0}),
						'other' => q(pm{0}),
						'zero' => q(pm{0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ɩpipi),
						'one' => q(pt{0}),
						'other' => q(pt{0}),
						'zero' => q(pt{0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ɩpipi),
						'one' => q(pt{0}),
						'other' => q(pt{0}),
						'zero' => q(pt{0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ʊshilè kɩfana),
						'one' => q(R☉{0}),
						'other' => q(R☉{0}),
						'zero' => q(R☉{0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ʊshilè kɩfana),
						'one' => q(R☉{0}),
						'other' => q(R☉{0}),
						'zero' => q(R☉{0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q(yd{0}),
						'other' => q(yd{0}),
						'zero' => q(yd{0}),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q(yd{0}),
						'other' => q(yd{0}),
						'zero' => q(yd{0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q(cd{0}),
						'other' => q(cd{0}),
						'zero' => q(cd{0}),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q(cd{0}),
						'other' => q(cd{0}),
						'zero' => q(cd{0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q(lm{0}),
						'other' => q(lm{0}),
						'zero' => q(lm{0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q(lm{0}),
						'other' => q(lm{0}),
						'zero' => q(lm{0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q(lx{0}),
						'other' => q(lx{0}),
						'zero' => q(lx{0}),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q(lx{0}),
						'other' => q(lx{0}),
						'zero' => q(lx{0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q(CD{0}),
						'other' => q(CD{0}),
						'zero' => q(CD{0}),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q(CD{0}),
						'other' => q(CD{0}),
						'zero' => q(CD{0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ɩgram),
						'one' => q(g{0}),
						'other' => q(g{0}),
						'zero' => q(g{0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ɩgram),
						'one' => q(g{0}),
						'other' => q(g{0}),
						'zero' => q(g{0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q(kg{0}),
						'other' => q(kg{0}),
						'zero' => q(kg{0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q(kg{0}),
						'other' => q(kg{0}),
						'zero' => q(kg{0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q(μg{0}),
						'other' => q(μg{0}),
						'zero' => q(μg{0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q(μg{0}),
						'other' => q(μg{0}),
						'zero' => q(μg{0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q(mg{0}),
						'other' => q(mg{0}),
						'zero' => q(mg{0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q(mg{0}),
						'other' => q(mg{0}),
						'zero' => q(mg{0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q(oz{0}),
						'other' => q(oz{0}),
						'zero' => q(oz{0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q(oz{0}),
						'other' => q(oz{0}),
						'zero' => q(oz{0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q(oz t{0}),
						'other' => q(oz t{0}),
						'zero' => q(oz t{0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q(oz t{0}),
						'other' => q(oz t{0}),
						'zero' => q(oz t{0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q(lb{0}),
						'other' => q(lb{0}),
						'zero' => q(lb{0}),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q(lb{0}),
						'other' => q(lb{0}),
						'zero' => q(lb{0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q(st{0}),
						'other' => q(st{0}),
						'zero' => q(st{0}),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q(st{0}),
						'other' => q(st{0}),
						'zero' => q(st{0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q(tn{0}),
						'other' => q(tn{0}),
						'zero' => q(tn{0}),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q(tn{0}),
						'other' => q(tn{0}),
						'zero' => q(tn{0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q(t{0}),
						'other' => q(t{0}),
						'zero' => q(t{0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q(t{0}),
						'other' => q(t{0}),
						'zero' => q(t{0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q(GW{0}),
						'other' => q(GW{0}),
						'zero' => q(GW{0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q(GW{0}),
						'other' => q(GW{0}),
						'zero' => q(GW{0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q(hp{0}),
						'other' => q(hp{0}),
						'zero' => q(hp{0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q(hp{0}),
						'other' => q(hp{0}),
						'zero' => q(hp{0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q(kW{0}),
						'other' => q(kW{0}),
						'zero' => q(kW{0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q(kW{0}),
						'other' => q(kW{0}),
						'zero' => q(kW{0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q(MW{0}),
						'other' => q(MW{0}),
						'zero' => q(MW{0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q(MW{0}),
						'other' => q(MW{0}),
						'zero' => q(MW{0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q(mW{0}),
						'other' => q(mW{0}),
						'zero' => q(mW{0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q(mW{0}),
						'other' => q(mW{0}),
						'zero' => q(mW{0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q(W{0}),
						'other' => q(W{0}),
						'zero' => q(W{0}),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q(W{0}),
						'other' => q(W{0}),
						'zero' => q(W{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q(atm{0}),
						'other' => q(atm{0}),
						'zero' => q(atm{0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q(atm{0}),
						'other' => q(atm{0}),
						'zero' => q(atm{0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q(bar{0}),
						'other' => q(bar{0}),
						'zero' => q(bar{0}),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q(bar{0}),
						'other' => q(bar{0}),
						'zero' => q(bar{0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q(hPa{0}),
						'other' => q(hPa{0}),
						'zero' => q(hPa{0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q(hPa{0}),
						'other' => q(hPa{0}),
						'zero' => q(hPa{0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q(inHg{0}),
						'other' => q(inHg{0}),
						'zero' => q(inHg{0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q(inHg{0}),
						'other' => q(inHg{0}),
						'zero' => q(inHg{0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q(kPa{0}),
						'other' => q(kPa{0}),
						'zero' => q(kPa{0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q(kPa{0}),
						'other' => q(kPa{0}),
						'zero' => q(kPa{0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q(MPa{0}),
						'other' => q(MPa{0}),
						'zero' => q(MPa{0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q(MPa{0}),
						'other' => q(MPa{0}),
						'zero' => q(MPa{0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q(mbar{0}),
						'other' => q(mbar{0}),
						'zero' => q(mbar{0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q(mbar{0}),
						'other' => q(mbar{0}),
						'zero' => q(mbar{0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(mmHg{0}),
						'other' => q(mmHg{0}),
						'zero' => q(mmHg{0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(mmHg{0}),
						'other' => q(mmHg{0}),
						'zero' => q(mmHg{0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa{0}),
						'other' => q(Pa{0}),
						'zero' => q(Pa{0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa{0}),
						'other' => q(Pa{0}),
						'zero' => q(Pa{0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q(psi{0}),
						'other' => q(psi{0}),
						'zero' => q(psi{0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q(psi{0}),
						'other' => q(psi{0}),
						'zero' => q(psi{0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q(km/h{0}),
						'other' => q(km/h{0}),
						'zero' => q(km/h{0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q(km/h{0}),
						'other' => q(km/h{0}),
						'zero' => q(km/h{0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q(kn{0}),
						'other' => q(kn{0}),
						'zero' => q(kn{0}),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q(kn{0}),
						'other' => q(kn{0}),
						'zero' => q(kn{0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(pɔɩɩ),
						'one' => q(light{0}),
						'other' => q(light{0}),
						'zero' => q(light{0}),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(pɔɩɩ),
						'one' => q(light{0}),
						'other' => q(light{0}),
						'zero' => q(light{0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q(m/s{0}),
						'other' => q(m/s{0}),
						'zero' => q(m/s{0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q(m/s{0}),
						'other' => q(m/s{0}),
						'zero' => q(m/s{0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q(mi/h{0}),
						'other' => q(mi/h{0}),
						'zero' => q(mi/h{0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q(mi/h{0}),
						'other' => q(mi/h{0}),
						'zero' => q(mi/h{0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q(°C{0}),
						'other' => q(°C{0}),
						'zero' => q(°C{0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q(°C{0}),
						'other' => q(°C{0}),
						'zero' => q(°C{0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q(°F{0}),
						'other' => q(°F{0}),
						'zero' => q(°F{0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q(°F{0}),
						'other' => q(°F{0}),
						'zero' => q(°F{0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q(K {0}),
						'other' => q(K {0}),
						'zero' => q(K {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q(K {0}),
						'other' => q(K {0}),
						'zero' => q(K {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q(N⋅m{0}),
						'other' => q(N⋅m{0}),
						'zero' => q(N⋅m{0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q(N⋅m{0}),
						'other' => q(N⋅m{0}),
						'zero' => q(N⋅m{0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q(ac ft{0}),
						'other' => q(ac ft{0}),
						'zero' => q(ac ft{0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q(ac ft{0}),
						'other' => q(ac ft{0}),
						'zero' => q(ac ft{0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q(bbl{0}),
						'other' => q(bbl{0}),
						'zero' => q(bbl{0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q(bbl{0}),
						'other' => q(bbl{0}),
						'zero' => q(bbl{0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q(bu{0}),
						'other' => q(bu{0}),
						'zero' => q(bu{0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q(bu{0}),
						'other' => q(bu{0}),
						'zero' => q(bu{0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q(cL{0}),
						'other' => q(cL{0}),
						'zero' => q(cL{0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q(cL{0}),
						'other' => q(cL{0}),
						'zero' => q(cL{0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q(cm³{0}),
						'other' => q(cm³{0}),
						'zero' => q(cm³{0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q(cm³{0}),
						'other' => q(cm³{0}),
						'zero' => q(cm³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q(ft³{0}),
						'other' => q(ft³{0}),
						'zero' => q(ft³{0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q(ft³{0}),
						'other' => q(ft³{0}),
						'zero' => q(ft³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q(in³{0}),
						'other' => q(in³{0}),
						'zero' => q(in³{0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q(in³{0}),
						'other' => q(in³{0}),
						'zero' => q(in³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q(km³{0}),
						'other' => q(km³{0}),
						'zero' => q(km³{0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q(km³{0}),
						'other' => q(km³{0}),
						'zero' => q(km³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q(m³{0}),
						'other' => q(m³{0}),
						'zero' => q(m³{0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q(m³{0}),
						'other' => q(m³{0}),
						'zero' => q(m³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q(mi³{0}),
						'other' => q(mi³{0}),
						'zero' => q(mi³{0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q(mi³{0}),
						'other' => q(mi³{0}),
						'zero' => q(mi³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q(yd³{0}),
						'other' => q(yd³{0}),
						'zero' => q(yd³{0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q(yd³{0}),
						'other' => q(yd³{0}),
						'zero' => q(yd³{0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kɔɔpʊ),
						'one' => q(c{0}),
						'other' => q(c{0}),
						'zero' => q(c{0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kɔɔpʊ),
						'one' => q(c{0}),
						'other' => q(c{0}),
						'zero' => q(c{0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q(mc{0}),
						'other' => q(mc{0}),
						'zero' => q(mc{0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q(mc{0}),
						'other' => q(mc{0}),
						'zero' => q(mc{0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q(dL{0}),
						'other' => q(dL{0}),
						'zero' => q(dL{0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q(dL{0}),
						'other' => q(dL{0}),
						'zero' => q(dL{0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q(dstspn{0}),
						'other' => q(dstspn{0}),
						'zero' => q(dstspn{0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q(dstspn{0}),
						'other' => q(dstspn{0}),
						'zero' => q(dstspn{0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q(dstspn Imp{0}),
						'other' => q(dstspn Imp{0}),
						'zero' => q(dstspn Imp{0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q(dstspn Imp{0}),
						'other' => q(dstspn Imp{0}),
						'zero' => q(dstspn Imp{0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q(fl.dr.{0}),
						'other' => q(fl.dr.{0}),
						'zero' => q(fl.dr.{0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q(fl.dr.{0}),
						'other' => q(fl.dr.{0}),
						'zero' => q(fl.dr.{0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ɩsɔr),
						'one' => q(dr{0}),
						'other' => q(dr{0}),
						'zero' => q(dr{0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ɩsɔr),
						'one' => q(dr{0}),
						'other' => q(dr{0}),
						'zero' => q(dr{0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q(fl oz{0}),
						'other' => q(fl oz{0}),
						'zero' => q(fl oz{0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q(fl oz{0}),
						'other' => q(fl oz{0}),
						'zero' => q(fl oz{0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q(fl oz Imp.{0}),
						'other' => q(fl oz Imp.{0}),
						'zero' => q(fl oz Imp.{0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q(fl oz Imp.{0}),
						'other' => q(fl oz Imp.{0}),
						'zero' => q(fl oz Imp.{0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q(gal{0}),
						'other' => q(gal{0}),
						'zero' => q(gal{0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q(gal{0}),
						'other' => q(gal{0}),
						'zero' => q(gal{0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q(gal Imp.{0}),
						'other' => q(gal Imp.{0}),
						'zero' => q(gal Imp.{0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q(gal Imp.{0}),
						'other' => q(gal Imp.{0}),
						'zero' => q(gal Imp.{0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q(hL{0}),
						'other' => q(hL{0}),
						'zero' => q(hL{0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q(hL{0}),
						'other' => q(hL{0}),
						'zero' => q(hL{0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(jɩga),
						'one' => q(jigger{0}),
						'other' => q(jigger{0}),
						'zero' => q(jigger{0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(jɩga),
						'one' => q(jigger{0}),
						'other' => q(jigger{0}),
						'zero' => q(jigger{0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litri),
						'one' => q(l{0}),
						'other' => q(l{0}),
						'zero' => q(l{0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litri),
						'one' => q(l{0}),
						'other' => q(l{0}),
						'zero' => q(l{0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q(ML{0}),
						'other' => q(ML{0}),
						'zero' => q(ML{0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q(ML{0}),
						'other' => q(ML{0}),
						'zero' => q(ML{0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q(mL{0}),
						'other' => q(mL{0}),
						'zero' => q(mL{0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q(mL{0}),
						'other' => q(mL{0}),
						'zero' => q(mL{0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ɩkɩtɩʊ),
						'one' => q(pn{0}),
						'other' => q(pn{0}),
						'zero' => q(pn{0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ɩkɩtɩʊ),
						'one' => q(pn{0}),
						'other' => q(pn{0}),
						'zero' => q(pn{0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pt),
						'one' => q(mpt{0}),
						'other' => q(mpt{0}),
						'zero' => q(mpt{0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
						'one' => q(mpt{0}),
						'other' => q(mpt{0}),
						'zero' => q(mpt{0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q(qt Imp.{0}),
						'other' => q(qt Imp.{0}),
						'zero' => q(qt Imp.{0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q(qt Imp.{0}),
						'other' => q(qt Imp.{0}),
						'zero' => q(qt Imp.{0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q(tbsp{0}),
						'other' => q(tbsp{0}),
						'zero' => q(tbsp{0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q(tbsp{0}),
						'other' => q(tbsp{0}),
						'zero' => q(tbsp{0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q(tsp{0}),
						'other' => q(tsp{0}),
						'zero' => q(tsp{0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q(tsp{0}),
						'other' => q(tsp{0}),
						'zero' => q(tsp{0}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ʊtǝŋu),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ʊtǝŋu),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q(G {0}),
						'other' => q(G {0}),
						'zero' => q(G {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q(G {0}),
						'other' => q(G {0}),
						'zero' => q(G {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q(m/s² {0}),
						'other' => q(m/s² {0}),
						'zero' => q(m/s² {0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q(m/s² {0}),
						'other' => q(m/s² {0}),
						'zero' => q(m/s² {0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q(′{0}),
						'other' => q(′{0}),
						'zero' => q(′{0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q(′{0}),
						'other' => q(′{0}),
						'zero' => q(′{0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q(″{0}),
						'other' => q(″{0}),
						'zero' => q(″{0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q(″{0}),
						'other' => q(″{0}),
						'zero' => q(″{0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q(rad {0}),
						'other' => q(rad {0}),
						'zero' => q(rad {0}),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q(rad {0}),
						'other' => q(rad {0}),
						'zero' => q(rad {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q(rev {0}),
						'other' => q(rev {0}),
						'zero' => q(rev {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q(rev {0}),
						'other' => q(rev {0}),
						'zero' => q(rev {0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ɩɖunam),
						'one' => q(ɖunam {0}),
						'other' => q(ɩɖunam {0}),
						'zero' => q(baa ɖunam {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ɩɖunam),
						'one' => q(ɖunam {0}),
						'other' => q(ɩɖunam {0}),
						'zero' => q(baa ɖunam {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ɩlɔ),
						'one' => q(ha {0}),
						'other' => q(ha {0}),
						'zero' => q(ha {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ɩlɔ),
						'one' => q(ha {0}),
						'other' => q(ha {0}),
						'zero' => q(ha {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
						'zero' => q(cm² {0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
						'zero' => q(cm² {0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
						'zero' => q(ft² {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q(ft² {0}),
						'other' => q(ft² {0}),
						'zero' => q(ft² {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q(in² {0}),
						'other' => q(in² {0}),
						'zero' => q(in² {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q(in² {0}),
						'other' => q(in² {0}),
						'zero' => q(in² {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q(km² {0}),
						'other' => q(km² {0}),
						'zero' => q(km² {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q(km² {0}),
						'other' => q(km² {0}),
						'zero' => q(km² {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ɩmɛta²),
						'one' => q(m² {0}),
						'other' => q(m² {0}),
						'zero' => q(m² {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ɩmɛta²),
						'one' => q(m² {0}),
						'other' => q(m² {0}),
						'zero' => q(m² {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q(mi² {0}),
						'other' => q(mi² {0}),
						'zero' => q(mi² {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q(mi² {0}),
						'other' => q(mi² {0}),
						'zero' => q(mi² {0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q(yd² {0}),
						'other' => q(yd² {0}),
						'zero' => q(yd² {0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q(yd² {0}),
						'other' => q(yd² {0}),
						'zero' => q(yd² {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q(item {0}),
						'other' => q(item {0}),
						'zero' => q(item {0}),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q(item {0}),
						'other' => q(item {0}),
						'zero' => q(item {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q(kt {0}),
						'other' => q(kt {0}),
						'zero' => q(kt {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q(kt {0}),
						'other' => q(kt {0}),
						'zero' => q(kt {0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL {0}),
						'other' => q(mg/dL {0}),
						'zero' => q(mg/dL {0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL {0}),
						'other' => q(mg/dL {0}),
						'zero' => q(mg/dL {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q(mmol/L {0}),
						'other' => q(mmol/L {0}),
						'zero' => q(mmol/L {0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q(mmol/L {0}),
						'other' => q(mmol/L {0}),
						'zero' => q(mmol/L {0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q(mol {0}),
						'other' => q(mol {0}),
						'zero' => q(mol {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q(mol {0}),
						'other' => q(mol {0}),
						'zero' => q(mol {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
						'zero' => q(%{0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
						'zero' => q(%{0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q(‰{0}),
						'other' => q(‰{0}),
						'zero' => q(‰{0}),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q(‰{0}),
						'other' => q(‰{0}),
						'zero' => q(‰{0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
						'zero' => q(ppm {0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
						'zero' => q(ppm {0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(‱{0}),
						'other' => q(‱{0}),
						'zero' => q(‱{0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(‱{0}),
						'other' => q(‱{0}),
						'zero' => q(‱{0}),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'one' => q(ppb {0}),
						'other' => q(ppb {0}),
						'zero' => q(ppb {0}),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'one' => q(ppb {0}),
						'other' => q(ppb {0}),
						'zero' => q(ppb {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q(L/100km {0}),
						'other' => q(L/100km {0}),
						'zero' => q(L/100km {0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q(L/100km {0}),
						'other' => q(L/100km {0}),
						'zero' => q(L/100km {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q(L/km {0}),
						'other' => q(L/km {0}),
						'zero' => q(L/km {0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q(L/km {0}),
						'other' => q(L/km {0}),
						'zero' => q(L/km {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q(mpg {0}),
						'other' => q(mpg {0}),
						'zero' => q(mpg {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q(mpg {0}),
						'other' => q(mpg {0}),
						'zero' => q(mpg {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q(mpg Imp. {0}),
						'other' => q(mpg Imp. {0}),
						'zero' => q(mpg Imp. {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q(mpg Imp. {0}),
						'other' => q(mpg Imp. {0}),
						'zero' => q(mpg Imp. {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} gjl),
						'north' => q({0} gpl),
						'south' => q({0} gsl),
						'west' => q({0} gshl),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} gjl),
						'north' => q({0} gpl),
						'south' => q({0} gsl),
						'west' => q({0} gshl),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(gɩjibɔŋɔ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gɩjibɔŋɔ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q(A {0}),
						'other' => q(A {0}),
						'zero' => q(A {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q(A {0}),
						'other' => q(A {0}),
						'zero' => q(A {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q(mA {0}),
						'other' => q(mA {0}),
						'zero' => q(mA {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q(mA {0}),
						'other' => q(mA {0}),
						'zero' => q(mA {0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q(Ω {0}),
						'other' => q(Ω {0}),
						'zero' => q(Ω {0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q(Ω {0}),
						'other' => q(Ω {0}),
						'zero' => q(Ω {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q(V {0}),
						'other' => q(V {0}),
						'zero' => q(V {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q(V {0}),
						'other' => q(V {0}),
						'zero' => q(V {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q(Btu {0}),
						'other' => q(Btu {0}),
						'zero' => q(Btu {0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q(Btu {0}),
						'other' => q(Btu {0}),
						'zero' => q(Btu {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q(cal {0}),
						'other' => q(cal {0}),
						'zero' => q(cal {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q(cal {0}),
						'other' => q(cal {0}),
						'zero' => q(cal {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q(eV {0}),
						'other' => q(eV {0}),
						'zero' => q(eV {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q(eV {0}),
						'other' => q(eV {0}),
						'zero' => q(eV {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ɩjul),
						'one' => q(J {0}),
						'other' => q(J {0}),
						'zero' => q(J {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ɩjul),
						'one' => q(J {0}),
						'other' => q(J {0}),
						'zero' => q(J {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q(kcal {0}),
						'other' => q(kcal {0}),
						'zero' => q(kcal {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q(kcal {0}),
						'other' => q(kcal {0}),
						'zero' => q(kcal {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q(kJ {0}),
						'other' => q(kJ {0}),
						'zero' => q(kJ {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q(kJ {0}),
						'other' => q(kJ {0}),
						'zero' => q(kJ {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q(kWh {0}),
						'other' => q(kWh {0}),
						'zero' => q(kWh {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q(kWh {0}),
						'other' => q(kWh {0}),
						'zero' => q(kWh {0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q(US therm {0}),
						'other' => q(US therm {0}),
						'zero' => q(US therm {0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q(US therm {0}),
						'other' => q(US therm {0}),
						'zero' => q(US therm {0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km {0}),
						'other' => q(kWh/100km {0}),
						'zero' => q(kWh/100km {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km {0}),
						'other' => q(kWh/100km {0}),
						'zero' => q(kWh/100km {0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q(N {0}),
						'other' => q(N {0}),
						'zero' => q(N {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q(N {0}),
						'other' => q(N {0}),
						'zero' => q(N {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q(GHz {0}),
						'other' => q(GHz {0}),
						'zero' => q(GHz {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q(GHz {0}),
						'other' => q(GHz {0}),
						'zero' => q(GHz {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q(Hz {0}),
						'other' => q(Hz {0}),
						'zero' => q(Hz {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q(Hz {0}),
						'other' => q(Hz {0}),
						'zero' => q(Hz {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q(kHz {0}),
						'other' => q(kHz {0}),
						'zero' => q(kHz {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q(kHz {0}),
						'other' => q(kHz {0}),
						'zero' => q(kHz {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q(MHz {0}),
						'other' => q(MHz {0}),
						'zero' => q(MHz {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q(MHz {0}),
						'other' => q(MHz {0}),
						'zero' => q(MHz {0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q(ʊfɔɔ ɛm {0}),
						'other' => q(ɩfɔɔ ɛm {0}),
						'zero' => q(baa ʊfɔɔ ɛm),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q(ʊfɔɔ ɛm {0}),
						'other' => q(ɩfɔɔ ɛm {0}),
						'zero' => q(baa ʊfɔɔ ɛm),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ɩmegapisɛl),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ɩmegapisɛl),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ɩpisɛl),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ɩpisɛl),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q(au {0}),
						'other' => q(au {0}),
						'zero' => q(au {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q(au {0}),
						'other' => q(au {0}),
						'zero' => q(au {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q(cm {0}),
						'other' => q(cm {0}),
						'zero' => q(cm {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q(cm {0}),
						'other' => q(cm {0}),
						'zero' => q(cm {0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q(dm {0}),
						'other' => q(dm {0}),
						'zero' => q(dm {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q(dm {0}),
						'other' => q(dm {0}),
						'zero' => q(dm {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(gatǝna gawalaka kʊfana),
						'one' => q(R⊕ {0}),
						'other' => q(R⊕ {0}),
						'zero' => q(R⊕ {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(gatǝna gawalaka kʊfana),
						'one' => q(R⊕ {0}),
						'other' => q(R⊕ {0}),
						'zero' => q(R⊕ {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(ɩfɛɛɖǝm),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'zero' => q(fth {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(ɩfɛɛɖǝm),
						'one' => q({0} fth),
						'other' => q({0} fth),
						'zero' => q(fth {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(anaŋcǝna),
						'one' => q(ft {0}),
						'other' => q(ft {0}),
						'zero' => q(ft {0}),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(anaŋcǝna),
						'one' => q(ft {0}),
						'other' => q(ft {0}),
						'zero' => q(ft {0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(ɩfɛɛlɔŋ),
						'one' => q(fur {0}),
						'other' => q(fur {0}),
						'zero' => q(fur {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(ɩfɛɛlɔŋ),
						'one' => q(fur {0}),
						'other' => q(fur {0}),
						'zero' => q(fur {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(asǝkǝmǝ),
						'one' => q(in {0}),
						'other' => q(in {0}),
						'zero' => q(in {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(asǝkǝmǝ),
						'one' => q(in {0}),
						'other' => q(in {0}),
						'zero' => q(in {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q(km {0}),
						'other' => q(km {0}),
						'zero' => q(km {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q(km {0}),
						'other' => q(km {0}),
						'zero' => q(km {0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q(ly {0}),
						'other' => q(ly {0}),
						'zero' => q(ly {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q(ly {0}),
						'other' => q(ly {0}),
						'zero' => q(ly {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q(m {0}),
						'other' => q(m {0}),
						'zero' => q(m {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q(m {0}),
						'other' => q(m {0}),
						'zero' => q(m {0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q(μm {0}),
						'other' => q(μm {0}),
						'zero' => q(μm {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q(μm {0}),
						'other' => q(μm {0}),
						'zero' => q(μm {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ɩmayɩl),
						'one' => q(mi {0}),
						'other' => q(mi {0}),
						'zero' => q(mi {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ɩmayɩl),
						'one' => q(mi {0}),
						'other' => q(mi {0}),
						'zero' => q(mi {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q(smi {0}),
						'other' => q(smi {0}),
						'zero' => q(smi {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q(smi {0}),
						'other' => q(smi {0}),
						'zero' => q(smi {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm {0}),
						'other' => q(mm {0}),
						'zero' => q(mm {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm {0}),
						'other' => q(mm {0}),
						'zero' => q(mm {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q(nm {0}),
						'other' => q(nm {0}),
						'zero' => q(nm {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q(nm {0}),
						'other' => q(nm {0}),
						'zero' => q(nm {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q(nmi {0}),
						'other' => q(nmi {0}),
						'zero' => q(nmi {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q(nmi {0}),
						'other' => q(nmi {0}),
						'zero' => q(nmi {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ɩparsɛɛkɩ),
						'one' => q(pc {0}),
						'other' => q(pc {0}),
						'zero' => q(pc {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ɩparsɛɛkɩ),
						'one' => q(pc {0}),
						'other' => q(pc {0}),
						'zero' => q(pc {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
						'zero' => q(pm {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
						'zero' => q(pm {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ɩpipi),
						'one' => q(pt {0}),
						'other' => q(pt {0}),
						'zero' => q(pt {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ɩpipi),
						'one' => q(pt {0}),
						'other' => q(pt {0}),
						'zero' => q(pt {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ʊshilè kɩfana),
						'one' => q(R☉ {0}),
						'other' => q(R☉ {0}),
						'zero' => q(R☉ {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ʊshilè kɩfana),
						'one' => q(R☉ {0}),
						'other' => q(R☉ {0}),
						'zero' => q(R☉ {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q(yd {0}),
						'other' => q(yd {0}),
						'zero' => q(yd {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q(yd {0}),
						'other' => q(yd {0}),
						'zero' => q(yd {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q(cd {0}),
						'other' => q(cd {0}),
						'zero' => q(cd {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q(cd {0}),
						'other' => q(cd {0}),
						'zero' => q(cd {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q(lm {0}),
						'other' => q(lm {0}),
						'zero' => q(lm {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q(lm {0}),
						'other' => q(lm {0}),
						'zero' => q(lm {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q(lx {0}),
						'other' => q(lx {0}),
						'zero' => q(lx {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q(lx {0}),
						'other' => q(lx {0}),
						'zero' => q(lx {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q(CD {0}),
						'other' => q(CD {0}),
						'zero' => q(CD {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q(CD {0}),
						'other' => q(CD {0}),
						'zero' => q(CD {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ɩgram),
						'one' => q(g {0}),
						'other' => q(g {0}),
						'zero' => q(g {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ɩgram),
						'one' => q(g {0}),
						'other' => q(g {0}),
						'zero' => q(g {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q(kg {0}),
						'other' => q(kg {0}),
						'zero' => q(kg {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q(kg {0}),
						'other' => q(kg {0}),
						'zero' => q(kg {0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q(μg {0}),
						'other' => q(μg {0}),
						'zero' => q(μg {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q(μg {0}),
						'other' => q(μg {0}),
						'zero' => q(μg {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q(mg {0}),
						'other' => q(mg {0}),
						'zero' => q(mg {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q(mg {0}),
						'other' => q(mg {0}),
						'zero' => q(mg {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q(oz {0}),
						'other' => q(oz {0}),
						'zero' => q(oz {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q(oz {0}),
						'other' => q(oz {0}),
						'zero' => q(oz {0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q(oz t {0}),
						'other' => q(oz t {0}),
						'zero' => q(oz t {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q(oz t {0}),
						'other' => q(oz t {0}),
						'zero' => q(oz t {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q(lb {0}),
						'other' => q(lb {0}),
						'zero' => q(lb {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q(lb {0}),
						'other' => q(lb {0}),
						'zero' => q(lb {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q(st {0}),
						'other' => q(st {0}),
						'zero' => q(st {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q(st {0}),
						'other' => q(st {0}),
						'zero' => q(st {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q(tn {0}),
						'other' => q(tn {0}),
						'zero' => q(tn {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q(tn {0}),
						'other' => q(tn {0}),
						'zero' => q(tn {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q(t {0}),
						'other' => q(t {0}),
						'zero' => q(t {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q(t {0}),
						'other' => q(t {0}),
						'zero' => q(t {0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q(GW {0}),
						'other' => q(GW {0}),
						'zero' => q(GW {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q(GW {0}),
						'other' => q(GW {0}),
						'zero' => q(GW {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q(hp {0}),
						'other' => q(hp {0}),
						'zero' => q(hp {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q(hp {0}),
						'other' => q(hp {0}),
						'zero' => q(hp {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
						'zero' => q(kW {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
						'zero' => q(kW {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q(MW {0}),
						'other' => q(MW {0}),
						'zero' => q(MW {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q(MW {0}),
						'other' => q(MW {0}),
						'zero' => q(MW {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q(mW {0}),
						'other' => q(mW {0}),
						'zero' => q(mW {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q(mW {0}),
						'other' => q(mW {0}),
						'zero' => q(mW {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q(W {0}),
						'other' => q(W {0}),
						'zero' => q(W {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q(W {0}),
						'other' => q(W {0}),
						'zero' => q(W {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q(atm {0}),
						'other' => q(atm {0}),
						'zero' => q(atm {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q(atm {0}),
						'other' => q(atm {0}),
						'zero' => q(atm {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q(bar {0}),
						'other' => q(bar {0}),
						'zero' => q(bar {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q(bar {0}),
						'other' => q(bar {0}),
						'zero' => q(bar {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
						'zero' => q(hPa {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
						'zero' => q(hPa {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q(inHg {0}),
						'other' => q(inHg {0}),
						'zero' => q(inHg {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q(inHg {0}),
						'other' => q(inHg {0}),
						'zero' => q(inHg {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q(kPa {0}),
						'other' => q(kPa {0}),
						'zero' => q(kPa {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q(kPa {0}),
						'other' => q(kPa {0}),
						'zero' => q(kPa {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q(MPa {0}),
						'other' => q(MPa {0}),
						'zero' => q(MPa {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q(MPa {0}),
						'other' => q(MPa {0}),
						'zero' => q(MPa {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
						'zero' => q(mbar {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
						'zero' => q(mbar {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(mmHg {0}),
						'other' => q(mmHg {0}),
						'zero' => q(mmHg {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(mmHg {0}),
						'other' => q(mmHg {0}),
						'zero' => q(mmHg {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
						'zero' => q(Pa {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
						'zero' => q(Pa {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q(psi {0}),
						'other' => q(psi {0}),
						'zero' => q(psi {0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q(psi {0}),
						'other' => q(psi {0}),
						'zero' => q(psi {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q(km/h {0}),
						'other' => q(km/h {0}),
						'zero' => q(km/h {0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q(km/h {0}),
						'other' => q(km/h {0}),
						'zero' => q(km/h {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q(kn {0}),
						'other' => q(kn {0}),
						'zero' => q(kn {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q(kn {0}),
						'other' => q(kn {0}),
						'zero' => q(kn {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(pɔɩɩ),
						'one' => q(light {0}),
						'other' => q(light {0}),
						'zero' => q(light {0}),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(pɔɩɩ),
						'one' => q(light {0}),
						'other' => q(light {0}),
						'zero' => q(light {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q(m/s {0}),
						'other' => q(m/s {0}),
						'zero' => q(m/s {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q(m/s {0}),
						'other' => q(m/s {0}),
						'zero' => q(m/s {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q(mi/h {0}),
						'other' => q(mi/h {0}),
						'zero' => q(mi/h {0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q(mi/h {0}),
						'other' => q(mi/h {0}),
						'zero' => q(mi/h {0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q(°C{0}),
						'other' => q(°C{0}),
						'zero' => q(°C{0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q(°C{0}),
						'other' => q(°C{0}),
						'zero' => q(°C{0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q(°F{0}),
						'other' => q(°F{0}),
						'zero' => q(°F{0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q(°F{0}),
						'other' => q(°F{0}),
						'zero' => q(°F{0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
						'zero' => q(°{0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q(K {0}),
						'other' => q(K {0}),
						'zero' => q(K {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q(K {0}),
						'other' => q(K {0}),
						'zero' => q(K {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q(N⋅m {0}),
						'other' => q(N⋅m {0}),
						'zero' => q(N⋅m {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q(N⋅m {0}),
						'other' => q(N⋅m {0}),
						'zero' => q(N⋅m {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q(ac ft {0}),
						'other' => q(ac ft {0}),
						'zero' => q(ac ft {0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q(ac ft {0}),
						'other' => q(ac ft {0}),
						'zero' => q(ac ft {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q(bbl {0}),
						'other' => q(bbl {0}),
						'zero' => q(bbl {0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q(bbl {0}),
						'other' => q(bbl {0}),
						'zero' => q(bbl {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q(bu {0}),
						'other' => q(bu {0}),
						'zero' => q(bu {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q(bu {0}),
						'other' => q(bu {0}),
						'zero' => q(bu {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q(cL {0}),
						'other' => q(cL {0}),
						'zero' => q(cL {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q(cL {0}),
						'other' => q(cL {0}),
						'zero' => q(cL {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
						'zero' => q(cm³ {0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
						'zero' => q(cm³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q(ft³ {0}),
						'other' => q(ft³ {0}),
						'zero' => q(ft³ {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q(ft³ {0}),
						'other' => q(ft³ {0}),
						'zero' => q(ft³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
						'zero' => q(in³ {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
						'zero' => q(in³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
						'zero' => q(km³ {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
						'zero' => q(km³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q(m³ {0}),
						'other' => q(m³ {0}),
						'zero' => q(m³ {0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q(m³ {0}),
						'other' => q(m³ {0}),
						'zero' => q(m³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
						'zero' => q(mi³ {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
						'zero' => q(mi³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
						'zero' => q(yd³ {0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
						'zero' => q(yd³ {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ɩkɔɔpʊ),
						'one' => q(c {0}),
						'other' => q(c {0}),
						'zero' => q(c {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ɩkɔɔpʊ),
						'one' => q(c {0}),
						'other' => q(c {0}),
						'zero' => q(c {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q(mc {0}),
						'other' => q(mc {0}),
						'zero' => q(mc {0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q(mc {0}),
						'other' => q(mc {0}),
						'zero' => q(mc {0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q(dL {0}),
						'other' => q(dL {0}),
						'zero' => q(dL {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q(dL {0}),
						'other' => q(dL {0}),
						'zero' => q(dL {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q(dstspn {0}),
						'other' => q(dstspn {0}),
						'zero' => q(dstspn {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q(dstspn {0}),
						'other' => q(dstspn {0}),
						'zero' => q(dstspn {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q(dstspn Imp {0}),
						'other' => q(dstspn Imp {0}),
						'zero' => q(dstspn Imp {0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q(dstspn Imp {0}),
						'other' => q(dstspn Imp {0}),
						'zero' => q(dstspn Imp {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ɩɖraam),
						'one' => q(dram {0}),
						'other' => q(dram {0}),
						'zero' => q(dram {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ɩɖraam),
						'one' => q(dram {0}),
						'other' => q(dram {0}),
						'zero' => q(dram {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ɩsɔr),
						'one' => q(drop {0}),
						'other' => q(drop {0}),
						'zero' => q(drop {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ɩsɔr),
						'one' => q(drop {0}),
						'other' => q(drop {0}),
						'zero' => q(drop {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q(fl oz US {0}),
						'other' => q(fl oz US {0}),
						'zero' => q(fl oz US {0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q(fl oz US {0}),
						'other' => q(fl oz US {0}),
						'zero' => q(fl oz US {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q(fl oz Imp. {0}),
						'other' => q(fl oz Imp. {0}),
						'zero' => q(fl oz Imp. {0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q(fl oz Imp. {0}),
						'other' => q(fl oz Imp. {0}),
						'zero' => q(fl oz Imp. {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q(gal US {0}),
						'other' => q(gal US {0}),
						'zero' => q(gal US {0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q(gal US {0}),
						'other' => q(gal US {0}),
						'zero' => q(gal US {0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q(gal Imp. {0}),
						'other' => q(gal Imp. {0}),
						'zero' => q(gal Imp. {0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q(gal Imp. {0}),
						'other' => q(gal Imp. {0}),
						'zero' => q(gal Imp. {0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q(hL {0}),
						'other' => q(hL {0}),
						'zero' => q(hL {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q(hL {0}),
						'other' => q(hL {0}),
						'zero' => q(hL {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(ɩjɩga),
						'one' => q(jigger {0}),
						'other' => q(jigger {0}),
						'zero' => q(jigger {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(ɩjɩga),
						'one' => q(jigger {0}),
						'other' => q(jigger {0}),
						'zero' => q(jigger {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ɩlitri),
						'one' => q(l {0}),
						'other' => q(l {0}),
						'zero' => q(l {0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ɩlitri),
						'one' => q(l {0}),
						'other' => q(l {0}),
						'zero' => q(l {0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q(ML {0}),
						'other' => q(ML {0}),
						'zero' => q(ML {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q(ML {0}),
						'other' => q(ML {0}),
						'zero' => q(ML {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q(mL {0}),
						'other' => q(mL {0}),
						'zero' => q(mL {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q(mL {0}),
						'other' => q(mL {0}),
						'zero' => q(mL {0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ɩkɩtɩʊ),
						'one' => q(pn {0}),
						'other' => q(pn {0}),
						'zero' => q(pn {0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ɩkɩtɩʊ),
						'one' => q(pn {0}),
						'other' => q(pn {0}),
						'zero' => q(pn {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
						'zero' => q(mpt {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
						'zero' => q(mpt {0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q(qt Imp. {0}),
						'other' => q(qt Imp. {0}),
						'zero' => q(qt Imp. {0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q(qt Imp. {0}),
						'other' => q(qt Imp. {0}),
						'zero' => q(qt Imp. {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q(tbsp {0}),
						'other' => q(tbsp {0}),
						'zero' => q(tbsp {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q(tbsp {0}),
						'other' => q(tbsp {0}),
						'zero' => q(tbsp {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q(tsp {0}),
						'other' => q(tsp {0}),
						'zero' => q(tsp {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q(tsp {0}),
						'other' => q(tsp {0}),
						'zero' => q(tsp {0}),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} na {1}),
				2 => q({0} na {1}),
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
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '% #,#0;% -#,#0',
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
		'AED' => {
			display_name => {
				'currency' => q(Emiir baGanɔ gaɖɔŋkɔnɔ kaAlaaributǝna kaɖiram),
				'one' => q(Emiir baGanɔ gaɖɔŋkɔnɔ kaAlaaributǝna kaɖiram),
				'other' => q(Emiir baGanɔ gaɖɔŋkɔnɔ kaAlaaributǝna kɩɖiram),
				'zero' => q(baa Emiir baGanɔ gaɖɔŋkɔnɔ kaAlaaributǝna kaɖiram),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afganistan kahafganii),
				'one' => q(Afganistan kahafganii),
				'other' => q(Afganistan kɩhafganii),
				'zero' => q(baa Afganistan kahafganii),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanii kalɛɛkɩ),
				'one' => q(Albanii kalɛɛkɩ),
				'other' => q(Albanii kɩlɛɛkɩ),
				'zero' => q(baa Albanii kalɛɛkɩ),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenii kaɖram),
				'one' => q(Armenii kaɖram),
				'other' => q(Armenii kɩɖram),
				'zero' => q(baa Armenii kaɖram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Holanɖ kaKarayiib kafɔlɔrɛŋ),
				'one' => q(Holanɖ kaKarayiib kafɔlɔrɛŋ),
				'other' => q(Holanɖ kaKarayiib kɩfɔlɔrɛŋ),
				'zero' => q(baa Holanɖ kaKarayiib kafɔlɔrɛŋ),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Aŋgolaa kakʊwansa),
				'one' => q(Aŋgolaa kakʊwansa),
				'other' => q(Aŋgolaa kɩkʊwansa),
				'zero' => q(baa Aŋgolaa kakʊwansa),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Arjantin kapɛsoo),
				'one' => q(Arjantin kapɛsoo),
				'other' => q(Arjantin kɩpɛsoo),
				'zero' => q(baa Arjantin kapɛsoo),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ɔstraliya kaɖala),
				'one' => q(Ɔstraliya kaɖala),
				'other' => q(Ɔstraliya kɩɖala),
				'zero' => q(baa Ɔstraliya kaɖala),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Arubaa kafɔlɔrɛŋ),
				'one' => q(Arubaa kafɔlɔrɛŋ),
				'other' => q(Arubaa kɩfɔlɔrɛŋ),
				'zero' => q(baa Arubaa kafɔlɔrɛŋ),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Asɛrbaɩjaŋ kamanaatɩ),
				'one' => q(Asɛrbaɩjaŋ kamanaatɩ),
				'other' => q(Asɛrbaɩjaŋ kɩmanaatɩ),
				'zero' => q(baa Asɛrbaɩjaŋ kamanaatɩ),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bɔsniya na Hɛrsegɔfina kamarkɩ),
				'one' => q(Bɔsniya na Hɛrsegɔfina kamarkɩ),
				'other' => q(Bɔsniya na Hɛrsegɔfina kɩmarkɩ),
				'zero' => q(baa Bɔsniya na Hɛrsegɔfina kamarkɩ),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbaɖɔɔsɩ kaɖala),
				'one' => q(Barbaɖɔɔsɩ kaɖala),
				'other' => q(Barbaɖɔɔsɩ kɩɖala),
				'zero' => q(baa Barbaɖɔɔsɩ kaɖala),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Baŋglaɖɛɛshɩ kataka),
				'one' => q(Baŋglaɖɛɛshɩ kataka),
				'other' => q(Baŋglaɖɛɛshɩ kɩtaka),
				'zero' => q(baa Baŋglaɖɛɛshɩ kataka),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarii kalɛɛfʊ),
				'one' => q(Bulgarii kalɛɛfʊ),
				'other' => q(Bulgarii kɩlɛɛfʊ),
				'zero' => q(baa Bulgarii kalɛɛfʊ),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Barɛɛn kaɖinaa),
				'one' => q(Barɛɛn kaɖinaa),
				'other' => q(Barɛɛn kɩɖinaa),
				'zero' => q(baa Barɛɛn kaɖinaa),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burunɖii kafaraŋ),
				'one' => q(Burunɖii kafaraŋ),
				'other' => q(Burunɖii kɩfaraŋ),
				'zero' => q(baa Burunɖii kafaraŋ),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bɛrmuɖaa kaɖala),
				'one' => q(Bɛrmuɖaa kaɖala),
				'other' => q(Bɛrmuɖaa kɩɖala),
				'zero' => q(baa Bɛrmuɖaa kaɖala),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunɛɩ kaɖala),
				'one' => q(Brunɛɩ kaɖala),
				'other' => q(Brunɛɩ kɩɖala),
				'zero' => q(baa Brunɛɩ kaɖala),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolifiya kabolifiyano),
				'one' => q(Bolifiya kabolifiyano),
				'other' => q(Bolifiya kɩbolifiyano),
				'zero' => q(baa Bolifiya kabolifiyano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Bresil kareyal),
				'one' => q(Bresil kareyal),
				'other' => q(Bresil kɩreyal),
				'zero' => q(baa Bresil kareyal),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamaasɩ kaɖala),
				'one' => q(Bahamaasɩ kaɖala),
				'other' => q(Bahamaasɩ kɩɖala),
				'zero' => q(baa Bahamaasɩ kaɖala),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butan kaŋgulturɔm),
				'one' => q(Butan kaŋgulturɔm),
				'other' => q(Butan kɩŋgulturɔm),
				'zero' => q(baa Butan kaŋgulturɔm),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Bɔsʊwanaa kapula),
				'one' => q(Bɔsʊwanaa kapula),
				'other' => q(Bɔsʊwanaa kɩpula),
				'zero' => q(baa Bɔsʊwanaa kapula),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belaruus karubǝl),
				'one' => q(Belaruus karubǝl),
				'other' => q(Belaruus kɩrubǝl),
				'zero' => q(baa Belaruus karubǝl),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Beliis kaɖala),
				'one' => q(Beliis kaɖala),
				'other' => q(Beliis kɩɖala),
				'zero' => q(baa Beliis kaɖala),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanaɖaa kaɖala),
				'one' => q(Kanaɖaa kaɖala),
				'other' => q(Kanaɖaa kɩɖala),
				'zero' => q(baa Kanaɖaa kaɖala),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Koŋgoo kafaraŋ),
				'one' => q(Koŋgoo kafaraŋ),
				'other' => q(Koŋgoo kɩfaraŋ),
				'zero' => q(baa Koŋgoo kafaraŋ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Suwis kafaraŋ),
				'one' => q(Suwis kafaraŋ),
				'other' => q(Suwis kɩfaraŋ),
				'zero' => q(baa Suwis kafaraŋ),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Shilii kapɛsoo),
				'one' => q(Shilii kapɛsoo),
				'other' => q(Shilii kɩpɛsoo),
				'zero' => q(baa Shilii kapɛsoo),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Caɩna kayuwan ba sǝ̂ra afʊba ma),
				'one' => q(Caɩna kayuwan ba sǝ̂ra afʊba ma),
				'other' => q(Caɩna kɩyuwan ba sǝ̂ra afʊba ma),
				'zero' => q(baa Caɩna kayuwan ba sǝ̂ra afʊba ma),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Caɩna kayuwan),
				'one' => q(Caɩna kayuwan),
				'other' => q(Caɩna kɩyuwan),
				'zero' => q(baa Caɩna kayuwan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolɔmbii kapɛsoo),
				'one' => q(Kolɔmbii kapɛsoo),
				'other' => q(Kolɔmbii kɩpɛsoo),
				'zero' => q(baa Kolɔmbii kapɛsoo),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kɔsta Rikaa kakolɔn),
				'one' => q(Kɔsta Rikaa kakolɔn),
				'other' => q(Kɔsta Rikaa kɩkolɔn),
				'zero' => q(baa Kɔsta Rikaa kakolɔn),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kubaa kapɛsoo ba sǝ̂ra afʊba ma),
				'one' => q(Kubaa kapɛsoo ba sǝ̂ra afʊba ma),
				'other' => q(Kubaa kɩpɛsoo ba sǝ̂ra afʊba ma),
				'zero' => q(baa Kubaa kapɛsoo ba sǝ̂ra afʊba ma),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubaa kapɛsoo),
				'one' => q(Kubaa kapɛsoo),
				'other' => q(Kubaa kɩpɛsoo),
				'zero' => q(baa Kubaa kapɛsoo),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kapfɛɛr kahɛskuɖoo),
				'one' => q(Kapfɛɛr kahɛskuɖoo),
				'other' => q(Kapfɛɛr kɩhɛskuɖoo),
				'zero' => q(baa Kapfɛɛr kahɛskuɖoo),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Cɛk kakrona),
				'one' => q(Cɛk kakrona),
				'other' => q(Cɛk kɩkrona),
				'zero' => q(baa Cɛk kakrona),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Jibutii kafaraŋ),
				'one' => q(Jibutii kafaraŋ),
				'other' => q(Jibutii kɩfaraŋ),
				'zero' => q(baa Jibutii kafaraŋ),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Ɖanǝmark kakrona),
				'one' => q(Ɖanǝmark kakrona),
				'other' => q(Ɖanǝmark kɩkrona),
				'zero' => q(baa Ɖanǝmark kakrona),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Ɖominikaa kapɛsoo),
				'one' => q(Ɖominikaa kapɛsoo),
				'other' => q(Ɖominikaa kɩpɛsoo),
				'zero' => q(baa Ɖominikaa kapɛsoo),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Aljerii kaɖinaa),
				'one' => q(Aljerii kaɖinaa),
				'other' => q(Aljerii kɩɖinaa),
				'zero' => q(baa Aljerii kaɖinaa),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ejipti kapɔŋ),
				'one' => q(Ejipti kapɔŋ),
				'other' => q(Ejipti kɩpɔŋ),
				'zero' => q(baa Ejipti kapɔŋ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritree kanafka),
				'one' => q(Eritree kanafka),
				'other' => q(Eritree kɩnafka),
				'zero' => q(baa Eritree kanafka),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etiyopii kabiir),
				'one' => q(Etiyopii kabiir),
				'other' => q(Etiyopii kɩbiir),
				'zero' => q(baa Etiyopii kabiir),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(eroo),
				'one' => q(eroo),
				'other' => q(eroo mána),
				'zero' => q(baa eroo),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fiji kaɖala),
				'one' => q(Fiji kaɖala),
				'other' => q(Fiji kɩɖala),
				'zero' => q(baa Fiji kaɖala),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Fɔklanɖ kaBʊtukǝltǝna kapɔŋ),
				'one' => q(Fɔklanɖ kaBʊtukǝltǝna kapɔŋ),
				'other' => q(Fɔklanɖ kaBʊtukǝltǝna kɩpɔŋ),
				'zero' => q(baa Fɔklanɖ kaBʊtukǝltǝna kapɔŋ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Gagɛɛshɩtǝna kapɔŋ),
				'one' => q(Gagɛɛshɩtǝna kapɔŋ),
				'other' => q(Gagɛɛshɩtǝna kɩpɔŋ),
				'zero' => q(baa Gagɛɛshɩtǝna kapɔŋ),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Jɔrjiya kalari),
				'one' => q(Jɔrjiya kalari),
				'other' => q(Jɔrjiya kɩlari),
				'zero' => q(baa Jɔrjiya kalari),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Gana kasiɖi),
				'one' => q(Gana kasiɖi),
				'other' => q(Gana kɩsiɖi),
				'zero' => q(baa Gana kasiɖi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltaa kapɔŋ),
				'one' => q(Gibraltaa kapɔŋ),
				'other' => q(Gibraltaa kɩpɔŋ),
				'zero' => q(baa Gibraltaa kapɔŋ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambii kaɖalaasi),
				'one' => q(Gambii kaɖalaasi),
				'other' => q(Gambii kɩɖalaasi),
				'zero' => q(baa Gambii kaɖalaasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Ginee kafaraŋ),
				'one' => q(Ginee kafaraŋ),
				'other' => q(Ginee kɩfaraŋ),
				'zero' => q(baa Ginee kafaraŋ),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guwatemalaa kakesaal),
				'one' => q(Guwatemalaa kakesaal),
				'other' => q(Guwatemalaa kɩkesaal),
				'zero' => q(baa Guwatemalaa kakesaal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyanaa kaɖala),
				'one' => q(Guyanaa kaɖala),
				'other' => q(Guyanaa kɩɖala),
				'zero' => q(baa Guyanaa kaɖala),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hɔŋ Kɔŋ kaɖala),
				'one' => q(Hɔŋ Kɔŋ kaɖala),
				'other' => q(Hɔŋ Kɔŋ kɩɖala),
				'zero' => q(baa Hɔŋ Kɔŋ kaɖala),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Hɔnɖuraasɩ kalampira),
				'one' => q(Hɔnɖuraasɩ kalampira),
				'other' => q(Hɔnɖuraasɩ kɩlampira),
				'zero' => q(baa Hɔnɖuraasɩ kalampira),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Krowasii kakuna),
				'one' => q(Krowasii kakuna),
				'other' => q(Krowasii kɩkuna),
				'zero' => q(baa Krowasii kakuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Hayitii kaguurɖi),
				'one' => q(Hayitii kaguurɖi),
				'other' => q(Hayitii kɩguurɖi),
				'zero' => q(baa Hayitii kaguurɖi),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ɔŋgrii kafɔrɩntɩ),
				'one' => q(Ɔŋgrii kafɔrɩntɩ),
				'other' => q(Ɔŋgrii kɩfɔrɩntɩ),
				'zero' => q(baa Ɔŋgrii kafɔrɩntɩ),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Ɛnɖonosii karupiyaa),
				'one' => q(Ɛnɖonosii karupiyaa),
				'other' => q(Ɛnɖonosii kɩrupiyaa),
				'zero' => q(baa Ɛnɖonosii karupiyaa),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Yishraɛl kashekɛl afɔlɩ),
				'one' => q(Yishraɛl kashekɛl afɔlɩ),
				'other' => q(Yishraɛl kɩshekɛl bafɔlɩ),
				'zero' => q(baa Yishraɛl kashekɛl afɔlɩ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Inɖiya karupii),
				'one' => q(Inɖiya karupii),
				'other' => q(Inɖiya kɩrupii),
				'zero' => q(baa Inɖiya karupii),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Ɩraakɩ kaɖinaa),
				'one' => q(Ɩraakɩ kaɖinaa),
				'other' => q(Ɩraakɩ kɩɖinaa),
				'zero' => q(baa Ɩraakɩ kaɖinaa),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iraŋ kariyal),
				'one' => q(Iraŋ kariyal),
				'other' => q(Iraŋ kɩriyal),
				'zero' => q(baa Iraŋ kariyal),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Islanɖ kakrona),
				'one' => q(Islanɖ kakrona),
				'other' => q(Islanɖ kɩkrona),
				'zero' => q(baa Islanɖ kakrona),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaɩka kaɖala),
				'one' => q(Jamaɩka kaɖala),
				'other' => q(Jamaɩka kɩɖala),
				'zero' => q(baa Jamaɩka kaɖala),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jɔrɖanii kaɖinaa),
				'one' => q(Jɔrɖanii kaɖinaa),
				'other' => q(Jɔrɖanii kɩɖinaa),
				'zero' => q(baa Jɔrɖanii kaɖinaa),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japaŋ kayɛn),
				'one' => q(Japaŋ kayɛn),
				'other' => q(Japaŋ kɩyɛn),
				'zero' => q(baa Japaŋ kayɛn),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniya kashílè),
				'one' => q(Keniya kashílè),
				'other' => q(Keniya kɩshílè),
				'zero' => q(baa Keniya kashílè),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgistan kasɔm),
				'one' => q(Kirgistan kasɔm),
				'other' => q(Kirgistan kɩsɔm),
				'zero' => q(baa Kirgistan kasɔm),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kamboɖiya kariyɛl),
				'one' => q(Kamboɖiya kariyɛl),
				'other' => q(Kamboɖiya kɩriyɛl),
				'zero' => q(baa Kamboɖiya kariyɛl),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komɔɔr kafaraŋ),
				'one' => q(Komɔɔr kafaraŋ),
				'other' => q(Komɔɔr kɩfaraŋ),
				'zero' => q(baa Komɔɔr kafaraŋ),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Koree gʊnyɩpɛnɛlaŋ kawɔn),
				'one' => q(Koree gʊnyɩpɛnɛlaŋ kawɔn),
				'other' => q(Koree gʊnyɩpɛnɛlaŋ kɩwɔn),
				'zero' => q(baa Koree gʊnyɩpɛnɛlaŋ kawɔn),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Koree gʊnyɩsonolaŋ kawɔn),
				'one' => q(Koree gʊnyɩsonolaŋ kawɔn),
				'other' => q(Koree gʊnyɩsonolaŋ kɩwɔn),
				'zero' => q(baa Koree gʊnyɩsonolaŋ kawɔn),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Koweeti kaɖinaa),
				'one' => q(Koweeti kaɖinaa),
				'other' => q(Koweeti kɩɖinaa),
				'zero' => q(baa Koweeti kaɖinaa),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kayimaan kaBʊtukǝltǝna kaɖala),
				'one' => q(Kayimaan kaBʊtukǝltǝna kaɖala),
				'other' => q(Kayimaan kaBʊtukǝltǝna kɩɖala),
				'zero' => q(baa Kayimaan kaBʊtukǝltǝna kaɖala),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kasastan katɛŋgɛ),
				'one' => q(Kasastan katɛŋgɛ),
				'other' => q(Kasastan kɩtɛŋgɛ),
				'zero' => q(baa Kasastan katɛŋgɛ),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Lawɔs kakip),
				'one' => q(Lawɔs kakip),
				'other' => q(Lawɔs kɩkip),
				'zero' => q(baa Lawɔs kakip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Liibaaŋ kapɔŋ),
				'one' => q(Liibaaŋ kapɔŋ),
				'other' => q(Liibaaŋ kɩpɔŋ),
				'zero' => q(baa Liibaaŋ kapɔŋ),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Siri Laŋkaa karupii),
				'one' => q(Siri Laŋkaa karupii),
				'other' => q(Siri Laŋkaa kɩrupii),
				'zero' => q(baa Siri Laŋkaa karupii),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiya kaɖala),
				'one' => q(Liberiya kaɖala),
				'other' => q(Liberiya kɩɖala),
				'zero' => q(baa Liberiya kaɖala),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotoo kaloti),
				'one' => q(Lesotoo kaloti),
				'other' => q(Lesotoo kɩloti),
				'zero' => q(baa Lesotoo kaloti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libii kaɖinaa),
				'one' => q(Libii kaɖinaa),
				'other' => q(Libii kɩɖinaa),
				'zero' => q(baa Libii kaɖinaa),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Morooko kaɖiram),
				'one' => q(Morooko kaɖiram),
				'other' => q(Morooko kɩɖiram),
				'zero' => q(baa Morooko kaɖiram),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Molɖafiya kalewu),
				'one' => q(Molɖafiya kalewu),
				'other' => q(Molɖafiya kɩlewu),
				'zero' => q(baa Molɖafiya kalewu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Maɖagaskaa kaharɩyaarɩ),
				'one' => q(Maɖagaskaa kaharɩyaarɩ),
				'other' => q(Maɖagaskaa kɩharɩyaarɩ),
				'zero' => q(baa Maɖagaskaa kaharɩyaarɩ),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Maseɖoniya kaɖenaa),
				'one' => q(Maseɖoniya kaɖenaa),
				'other' => q(Maseɖoniya kɩɖenaa),
				'zero' => q(baa Maseɖoniya kaɖenaa),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Miyanmaa kakiyaatɩ),
				'one' => q(Miyanmaa kakiyaatɩ),
				'other' => q(Miyanmaa kɩkiyaatɩ),
				'zero' => q(baa Miyanmaa kakiyaatɩ),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mɔŋgolii katugiriiki),
				'one' => q(Mɔŋgolii katugiriiki),
				'other' => q(Mɔŋgolii kɩtugiriiki),
				'zero' => q(baa Mɔŋgolii katugiriiki),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makawoo kapataka),
				'one' => q(Makawoo kapataka),
				'other' => q(Makawoo kɩpataka),
				'zero' => q(baa Makawoo kapataka),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Moritanii kahugiya),
				'one' => q(Moritanii kahugiya),
				'other' => q(Moritanii kɩhugiya),
				'zero' => q(baa Moritanii kahugiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Imoris karupii),
				'one' => q(Imoris karupii),
				'other' => q(Imoris kɩrupii),
				'zero' => q(baa Imoris karupii),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Malɖiifu karufiyaa),
				'one' => q(Malɖiifu karufiyaa),
				'other' => q(Malɖiifu kɩrufiyaa),
				'zero' => q(baa Malɖiifu karufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawii kakʊwaasha),
				'one' => q(Malawii kakʊwaasha),
				'other' => q(Malawii kɩkʊwaasha),
				'zero' => q(baa Malawii kakʊwaasha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mɛsik kapɛsoo),
				'one' => q(Mɛsik kapɛsoo),
				'other' => q(Mɛsik kɩpɛsoo),
				'zero' => q(baa Mɛsik kapɛsoo),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malɛsii kariŋgiiti),
				'one' => q(Malɛsii kariŋgiiti),
				'other' => q(Malɛsii kɩriŋgiiti),
				'zero' => q(baa Malɛsii kariŋgiiti),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambii kametikal),
				'one' => q(Mosambii kametikal),
				'other' => q(Mosambii kɩmetikal),
				'zero' => q(baa Mosambii kametikal),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibii kaɖala),
				'one' => q(Namibii kaɖala),
				'other' => q(Namibii kɩɖala),
				'zero' => q(baa Namibii kaɖala),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nanjiiriya kanɛɛra),
				'one' => q(Nanjiiriya kanɛɛra),
				'other' => q(Nanjiiriya kɩnɛɛra),
				'zero' => q(baa Nanjiiriya kanɛɛra),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaraguwaa kakɔrɖoba),
				'one' => q(Nikaraguwaa kakɔrɖoba),
				'other' => q(Nikaraguwaa kɩkɔrɖoba),
				'zero' => q(baa Nikaraguwaa kakɔrɖoba),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Nɔrfɛsh kakrona),
				'one' => q(Nɔrfɛsh kakrona),
				'other' => q(Nɔrfɛsh kɩkrona),
				'zero' => q(baa Nɔrfɛsh kakrona),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Neepal karupii),
				'one' => q(Neepal karupii),
				'other' => q(Neepal kɩrupii),
				'zero' => q(baa Neepal karupii),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Selanɖ afɔlɩ kaɖala),
				'one' => q(Selanɖ afɔlɩ kaɖala),
				'other' => q(Selanɖ afɔlɩ kɩɖala),
				'zero' => q(baa Selanɖ afɔlɩ kaɖala),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Oman kariyal),
				'one' => q(Oman kariyal),
				'other' => q(Oman kɩriyal),
				'zero' => q(baa Oman kariyal),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamaa kabalbowa),
				'one' => q(Panamaa kabalbowa),
				'other' => q(Panamaa kɩbalbowa),
				'zero' => q(baa Panamaa kabalbowa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruu kasol),
				'one' => q(Peruu kasol),
				'other' => q(Peruu kɩsol),
				'zero' => q(baa Peruu kasol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papuasii Ginee afɔlɩ kakina),
				'one' => q(Papuasii Ginee afɔlɩ kakina),
				'other' => q(Papuasii Ginee afɔlɩ kɩkina),
				'zero' => q(baa Papuasii Ginee afɔlɩ kakina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Filipiin kapɛsoo),
				'one' => q(Filipiin kapɛsoo),
				'other' => q(Filipiin kɩpɛsoo),
				'zero' => q(baa Filipiin kapɛsoo),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistan karupii),
				'one' => q(Pakistan karupii),
				'other' => q(Pakistan kɩrupii),
				'zero' => q(baa Pakistan karupii),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polanɖ kasǝlɔɔtɩ),
				'one' => q(Polanɖ kasǝlɔɔtɩ),
				'other' => q(Polanɖ kɩsǝlɔɔtɩ),
				'zero' => q(baa Polanɖ kasǝlɔɔtɩ),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguwee kaguwarani),
				'one' => q(Paraguwee kaguwarani),
				'other' => q(Paraguwee kɩguwarani),
				'zero' => q(baa Paraguwee kaguwarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Kataa kariyal),
				'one' => q(Kataa kariyal),
				'other' => q(Kataa kɩriyal),
				'zero' => q(baa Kataa kariyal),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Romanii kalewu),
				'one' => q(Romanii kalewu),
				'other' => q(Romanii kɩlewu),
				'zero' => q(baa Romanii kalewu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Sɛrbii kaɖinaa),
				'one' => q(Sɛrbii kaɖinaa),
				'other' => q(Sɛrbii kɩɖinaa),
				'zero' => q(baa Sɛrbii kaɖinaa),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rɔɔshɩya karubǝl),
				'one' => q(Rɔɔshɩya karubǝl),
				'other' => q(Rɔɔshɩya kɩrubǝl),
				'zero' => q(baa Rɔɔshɩya karubǝl),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rʊwanɖaa kafaraŋ),
				'one' => q(Rʊwanɖaa kafaraŋ),
				'other' => q(Rʊwanɖaa kɩfaraŋ),
				'zero' => q(baa Rʊwanɖaa kafaraŋ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Sauɖiya kariyal),
				'one' => q(Sauɖiya kariyal),
				'other' => q(Sauɖiya kɩriyal),
				'zero' => q(baa Sauɖiya kariyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomɔɔn kaBʊtukǝltǝna kaɖala),
				'one' => q(Salomɔɔn kaBʊtukǝltǝna kaɖala),
				'other' => q(Salomɔɔn kaBʊtukǝltǝna kɩɖala),
				'zero' => q(baa Salomɔɔn kaBʊtukǝltǝna kaɖala),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seshɛl karupii),
				'one' => q(Seshɛl karupii),
				'other' => q(Seshɛl kɩrupii),
				'zero' => q(baa Seshɛl karupii),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Suɖaŋ kapɔŋ),
				'one' => q(Suɖaŋ kapɔŋ),
				'other' => q(Suɖaŋ kɩpɔŋ),
				'zero' => q(baa Suɖaŋ kapɔŋ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sʊwɛɖ kakrona),
				'one' => q(Sʊwɛɖ kakrona),
				'other' => q(Sʊwɛɖ kɩkrona),
				'zero' => q(baa Sʊwɛɖ kakrona),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Siŋgapuur kaɖala),
				'one' => q(Siŋgapuur kaɖala),
				'other' => q(Siŋgapuur kɩɖala),
				'zero' => q(baa Siŋgapuur kaɖala),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Sɛŋ Elenaa kapɔŋ),
				'one' => q(Sɛŋ Elenaa kapɔŋ),
				'other' => q(Sɛŋ Elenaa kɩpɔŋ),
				'zero' => q(baa Sɛŋ Elenaa kapɔŋ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Seraleyɔn kaleyɔn),
				'one' => q(Seraleyɔn kaleyɔn),
				'other' => q(Seraleyɔn kɩleyɔn),
				'zero' => q(baa Seraleyɔn kaleyɔn),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Seraleyɔn kaleyɔn \(1964—2022\)),
				'one' => q(Seraleyɔn kaleyɔn \(1964—2022\)),
				'other' => q(Seraleyɔn kɩleyɔn \(1964—2022\)),
				'zero' => q(baa Seraleyɔn kaleyɔn \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalii kashílè),
				'one' => q(Somalii kashílè),
				'other' => q(Somalii kɩshílè),
				'zero' => q(baa Somalii kashílè),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam kaɖala),
				'one' => q(Surinam kaɖala),
				'other' => q(Surinam kɩɖala),
				'zero' => q(baa Surinam kaɖala),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Suɖaŋ gʊnyɩsonolaŋ kapɔŋ),
				'one' => q(Suɖaŋ gʊnyɩsonolaŋ kapɔŋ),
				'other' => q(Suɖaŋ gʊnyɩsonolaŋ kɩpɔŋ),
				'zero' => q(baa Suɖaŋ gʊnyɩsonolaŋ kapɔŋ),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Saotomee kaɖobra),
				'one' => q(Saotomee kaɖobra),
				'other' => q(Saotomee kɩɖobra),
				'zero' => q(baa Saotomee kaɖobra),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Sirii kapɔŋ),
				'one' => q(Sirii kapɔŋ),
				'other' => q(Sirii kɩpɔŋ),
				'zero' => q(baa Sirii kapɔŋ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Sʊwasilanɖ kalilaŋgenii),
				'one' => q(Sʊwasilanɖ kalilaŋgenii),
				'other' => q(Sʊwasilanɖ kɩlilaŋgenii),
				'zero' => q(baa Sʊwasilanɖ kalilaŋgenii),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Taɩlanɖ kabaatɩ),
				'one' => q(Taɩlanɖ kabaatɩ),
				'other' => q(Taɩlanɖ kɩbaatɩ),
				'zero' => q(baa Taɩlanɖ kabaatɩ),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tajikistan kasomooni),
				'one' => q(Tajikistan kasomooni),
				'other' => q(Tajikistan kɩsomooni),
				'zero' => q(baa Tajikistan kasomooni),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistan kamanaatɩ),
				'one' => q(Turkmenistan kamanaatɩ),
				'other' => q(Turkmenistan kɩmanaatɩ),
				'zero' => q(baa Turkmenistan kamanaatɩ),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisii kaɖinaa),
				'one' => q(Tunisii kaɖinaa),
				'other' => q(Tunisii kɩɖinaa),
				'zero' => q(baa Tunisii kaɖinaa),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tɔŋga kapaŋga),
				'one' => q(Tɔŋga kapaŋga),
				'other' => q(Tɔŋga kɩpaŋga),
				'zero' => q(baa Tɔŋga kapaŋga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkii kalira),
				'one' => q(Turkii kalira),
				'other' => q(Turkii kɩlira),
				'zero' => q(baa Turkii kalira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Triniɖaaɖ na Tobagoo kaɖala),
				'one' => q(Triniɖaaɖ na Tobagoo kaɖala),
				'other' => q(Triniɖaaɖ na Tobagoo kɩɖala),
				'zero' => q(baa Triniɖaaɖ na Tobagoo kaɖala),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Taɩwan kaɖala afɔlɩ),
				'one' => q(Taɩwan kaɖala afɔlɩ),
				'other' => q(Taɩwan kɩɖala bafɔlɩ),
				'zero' => q(baa Taɩwan kaɖala afɔlɩ),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Taŋsanii kashílè),
				'one' => q(Taŋsanii kashílè),
				'other' => q(Taŋsanii kɩshílè),
				'zero' => q(baa Taŋsanii kashílè),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ikrɛɛn karifniya),
				'one' => q(Ikrɛɛn karifniya),
				'other' => q(Ikrɛɛn kɩrifniya),
				'zero' => q(baa Ikrɛɛn karifniya),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganɖaa kashílè),
				'one' => q(Uganɖaa kashílè),
				'other' => q(Uganɖaa kɩshílè),
				'zero' => q(baa Uganɖaa kashílè),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Amalɩka kaɖala),
				'one' => q(Amalɩka kaɖala),
				'other' => q(Amalɩka kɩɖala),
				'zero' => q(baa Amalɩka kaɖala),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguwee kapɛsoo),
				'one' => q(Uruguwee kapɛsoo),
				'other' => q(Uruguwee kɩpɛsoo),
				'zero' => q(baa Uruguwee kapɛsoo),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbeekistan kasɔm),
				'one' => q(Usbeekistan kasɔm),
				'other' => q(Usbeekistan kɩsɔm),
				'zero' => q(baa Usbeekistan kasɔm),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Fenesuwelaa kabolifar),
				'one' => q(Fenesuwelaa kabolifar),
				'other' => q(Fenesuwelaa kɩbolifar),
				'zero' => q(baa Fenesuwelaa kabolifar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Fɛtnam kaɖɔŋgɩ),
				'one' => q(Fɛtnam kaɖɔŋgɩ),
				'other' => q(Fɛtnam kɩɖɔŋgɩ),
				'zero' => q(baa Fɛtnam kaɖɔŋgɩ),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Fanuwatu kafatu),
				'one' => q(Fanuwatu kafatu),
				'other' => q(Fanuwatu kɩfatu),
				'zero' => q(baa Fanuwatu kafatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samowa katala),
				'one' => q(Samowa katala),
				'other' => q(Samowa kɩtala),
				'zero' => q(baa Samowa katala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Garɩɖontǝna gɩcɩɩca kasɛɛfa),
				'one' => q(Garɩɖontǝna gɩcɩɩca kasɛɛfa),
				'other' => q(Garɩɖontǝna gɩcɩɩca kɩsɛɛfa),
				'zero' => q(baa Garɩɖontǝna gɩcɩɩca kasɛɛfa),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Karayiib gajakalaŋ kaɖala),
				'one' => q(Karayiib gajakalaŋ kaɖala),
				'other' => q(Karayiib gajakalaŋ kɩɖala),
				'zero' => q(baa Karayiib gajakalaŋ kaɖala),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Garɩɖontǝna gɩteŋshilelaŋ kasɛɛfa),
				'one' => q(Garɩɖontǝna gɩteŋshilelaŋ kasɛɛfa),
				'other' => q(Garɩɖontǝna gɩteŋshilelaŋ kɩsɛɛfa),
				'zero' => q(baa Garɩɖontǝna gɩteŋshilelaŋ kasɛɛfa),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Polinesiya Gafɔntǝna kaja kafaraŋ),
				'one' => q(Polinesiya Gafɔntǝna kaja kafaraŋ),
				'other' => q(Polinesiya Gafɔntǝna kaja kɩfaraŋ),
				'zero' => q(baa Polinesiya Gafɔntǝna kaja kafaraŋ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(gɩtanɩɩ kʊyɔʊ ʊ mana ma),
				'one' => q(gɩtanɩɩ kʊyɔʊ ʊ mana ma),
				'other' => q(ɩtanɩɩ kʊyɔʊ ʊ mana ma),
				'zero' => q(baa gɩtanɩɩ kʊyɔʊ ʊ mana ma),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yemɛn kariyal),
				'one' => q(Yemɛn kariyal),
				'other' => q(Yemɛn kɩriyal),
				'zero' => q(baa Yemɛn kariyal),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Sautafrika karanɖɩ),
				'one' => q(Sautafrika karanɖɩ),
				'other' => q(Sautafrika kɩranɖɩ),
				'zero' => q(baa Sautafrika karanɖɩ),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Sambii kakʊwaasha),
				'one' => q(Sambii kakʊwaasha),
				'other' => q(Sambii kɩkʊwaasha),
				'zero' => q(baa Sambii kakʊwaasha),
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
							'kaw',
							'kpa',
							'ci',
							'ɖʊ',
							'ɖu5',
							'ɖu6',
							'la',
							'kǝu',
							'fʊm',
							'cim',
							'pom',
							'bʊn'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ɩjikawǝrka kaŋɔrɔ',
							'ɩjikpaka kaŋɔrɔ',
							'arɛ́cika kaŋɔrɔ',
							'njɩbɔ nɖʊka kaŋɔrɔ',
							'acafʊnɖuka kaŋɔrɔ',
							'anɔɔɖuka kaŋɔrɔ',
							'alàlaka kaŋɔrɔ',
							'ɩjikǝuka kaŋɔrɔ',
							'abofʊmka kaŋɔrɔ',
							'ɩjicimka kaŋɔrɔ',
							'acapomka kaŋɔrɔ',
							'anɔɔbʊnka kaŋɔrɔ'
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
						mon => 'aɖɩt',
						tue => 'atal',
						wed => 'alar',
						thu => 'alam',
						fri => 'arɩs',
						sat => 'asib',
						sun => 'alah'
					},
					short => {
						mon => 'aɖt',
						tue => 'atl',
						wed => 'alr',
						thu => 'alm',
						fri => 'ars',
						sat => 'asb',
						sun => 'alh'
					},
					wide => {
						mon => 'aɖɩtɛnɛɛ',
						tue => 'atalaata',
						wed => 'alaarba',
						thu => 'alaamɩshɩ',
						fri => 'arɩsǝma',
						sat => 'asiibi',
						sun => 'alahaɖɩ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ɖt',
						tue => 'tl',
						wed => 'lr',
						thu => 'lm',
						fri => 'rs',
						sat => 'sb',
						sun => 'lh'
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
					abbreviated => {0 => 'ɩ1',
						1 => 'ɩ2',
						2 => 'ɩ3',
						3 => 'ɩ4'
					},
					wide => {0 => 'ɩŋɔrɩriu ɩsǝbaka',
						1 => 'ɩŋɔrɩriu ɩnyɩʊtaja',
						2 => 'ɩŋɔrɩriu ɩriutaja',
						3 => 'ɩŋɔrɩriu ɩnantaja'
					},
				},
				'stand-alone' => {
					wide => {0 => 'ɩŋɔrɩriu 1ka',
						1 => 'ɩŋɔrɩriu 2ja',
						2 => 'ɩŋɔrɩriu 3ja',
						3 => 'ɩŋɔrɩriu 4ja'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'afternoon2' if $time >= 1600
						&& $time < 2000;
					return 'evening1' if $time >= 2000
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'afternoon2' if $time >= 1600
						&& $time < 2000;
					return 'evening1' if $time >= 2000
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'afternoon2' if $time >= 1600
						&& $time < 2000;
					return 'evening1' if $time >= 2000
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'afternoon2' if $time >= 1600
						&& $time < 2000;
					return 'evening1' if $time >= 2000
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 0
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
					'afternoon1' => q{gɩshilikɔnɔ},
					'afternoon2' => q{gɩteŋshile},
					'am' => q{1ka},
					'evening1' => q{gɩjibɔŋɔ},
					'morning1' => q{asʊbaa},
					'morning2' => q{gajaka},
					'night1' => q{gajanɩ},
					'pm' => q{2ja},
				},
				'narrow' => {
					'afternoon1' => q{gshk},
					'afternoon2' => q{gtsh},
					'evening1' => q{gjb},
					'morning1' => q{asb},
					'morning2' => q{gjk},
					'night1' => q{gjn},
				},
				'wide' => {
					'am' => q{ʊshilè kʊboɖu},
					'pm' => q{ʊshilè kʊsasʊ},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{gshk},
					'afternoon2' => q{gtsh},
					'evening1' => q{gjb},
					'morning1' => q{asb},
					'morning2' => q{gjk},
					'night1' => q{gjn},
				},
				'wide' => {
					'afternoon1' => q{gɩshilikɔnɔ},
					'afternoon2' => q{gɩteŋshile},
					'evening1' => q{gɩjibɔŋɔ},
					'morning1' => q{asʊbaa},
					'morning2' => q{gajaka},
					'night1' => q{gajanɩ},
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
				'0' => 'naaBYŊAƖ',
				'1' => 'AƖAK'
			},
			wide => {
				'0' => 'naa Ba Ye Ŋʊm Annabi Ɩsa',
				'1' => 'Annabi Ɩsa Abʊŋʊma Kaŋkǝm'
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
			'full' => q{EEEE, MMMM d y G},
			'long' => q{MMMM d y G},
			'medium' => q{MMM d y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d y},
			'long' => q{MMMM d y},
			'medium' => q{MMM d y},
			'short' => q{M/d/y},
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
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E, h a mm},
			Ehms => q{E, h a mm:ss},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d y G},
			GyMMMd => q{MMM d y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			hm => q{h a mm},
			hms => q{h a mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bhm => q{h B mm},
			Bhms => q{h B mm:ss},
			EBhm => q{E h B mm},
			EBhms => q{E h B mm:ss},
			Ed => q{E d},
			Ehm => q{E h a mm},
			Ehms => q{E h a mm:ss},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d y G},
			GyMMMd => q{MMM d y G},
			GyMd => q{M/d/y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMW => q{MMMM 'abɔkɔɩ' W'ja'},
			Md => q{M/d},
			hm => q{h a mm},
			hms => q{h a mm:ss},
			hmsv => q{h a mm:ss v},
			hmv => q{h a mm v},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{Y 'kabɔkɔɩ' w'ja'},
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
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d y G – E, MMM d y G},
				M => q{E, MMM d – E, MMM d y G},
				d => q{E, MMM d – E, MMM d y G},
				y => q{E, MMM d y – E, MMM d y G},
			},
			GyMMMd => {
				G => q{MMM d y G – MMM d y G},
				M => q{MMM d – MMM d y G},
				d => q{MMM d – d y G},
				y => q{MMM d y – MMM d y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} halɩ {1}',
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d y G},
				d => q{E, MMM d – E, MMM d y G},
				y => q{E, MMM d y – E, MMM d y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d y G},
				d => q{MMM d – d y G},
				y => q{MMM d y – MMM d y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, M/d/y G – E, M/d/y G},
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d y G – E, MMM d y G},
				M => q{E, MMM d – E, MMM d y G},
				d => q{E, MMM d – E, MMM d y G},
				y => q{E, MMM d y – E, MMM d y G},
			},
			GyMMMd => {
				G => q{MMM d y G – MMM d y G},
				M => q{MMM d – MMM d y G},
				d => q{MMM d – d y G},
				y => q{MMM d y – MMM d y G},
			},
			GyMd => {
				G => q{M/d/y G – M/d/y G},
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
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
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} halɩ {1}',
			h => {
				h => q{h a – h a},
			},
			hm => {
				a => q{h a mm – h a mm},
				h => q{h a mm – h a mm},
				m => q{h a mm – h a mm},
			},
			hmv => {
				a => q{h a mm a – h a mm v},
				h => q{h a mm – h a mm v},
				m => q{h a mm – h a mm v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h a – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d y},
				d => q{E, MMM d – E, MMM d y},
				y => q{E, MMM d y – E, MMM d y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d y},
				d => q{MMM d – d y},
				y => q{MMM d y – MMM d y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q({0} Gk),
		gmtZeroFormat => q(Gk),
		regionFormat => q({0} kaakɔŋkɔŋɔ̀),
		regionFormat => q({0} kaakɔŋkɔŋɔ̀ gafʊbaka),
		regionFormat => q({0} kaakɔŋkɔŋɔ̀ ɖeiɖei),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistan kaakɔŋkɔŋɔ̀#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abijaŋ#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akraa#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Aɖis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljɛɛr#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmaraa#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamakoo#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Baŋgii#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisoo#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantiir#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brasafil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumburaa#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairoo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablaŋkaa#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seyuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakrii#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Ɖakaar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Ɖarɛsalaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibutii#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Ɖuwalaa#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Ɛl Ayun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Friitaʊn#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Hararee#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yohanɛsbuur#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Jubaa#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampalaa#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartuum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigalii#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasaa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Legɔs#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librǝfil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lʊmɛ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luwanɖaa#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashii#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusakaa#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malaboo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputoo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseruu#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabanee#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogaɖishuu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrofiyaa#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobii#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Njamenaa#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Nyɛmɛ#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuwakcɔt#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagaɖugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Pɔrto Nofoo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Saotome kampá#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolii#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tiniis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Winɖhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Garɩɖontǝna gɩcɩɩca kaakɔŋkɔŋɔ̀#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Garɩɖontǝna gajakalaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Garɩɖontǝna gʊnyɩsonolaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Garɩɖontǝna gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Garɩɖontǝna gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Garɩɖontǝna gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaskaa kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Alaskaa kaakɔŋkɔŋɔ̀#,
				'standard' => q#Alaskaa kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amasɔn kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Amasɔn kaakɔŋkɔŋɔ̀#,
				'standard' => q#Amasɔn kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Aɖak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Aŋkɔraajɩ#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Aŋguwilaa#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antiguwaa#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguweena#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Riyɔha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Riyo Galegɔs#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Huwan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luwis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuweyaa#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arubaa#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsiyɔn#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahiyaa#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahiiya ɖe Banɖeraasɩ#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbaɖɔɔsɩ#,
		},
		'America/Belem' => {
			exemplarCity => q#Belɛm#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliis#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blaŋ-Sablɔŋ#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Bowa Fistaa#,
		},
		'America/Boise' => {
			exemplarCity => q#Bɔwaasɩ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buwenɔs Airɛs#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambriijɩ Baɩ#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Granɖee#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kaŋkun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakaas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarkaa#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayɛɛn#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayimaan#,
		},
		'America/Chicago' => {
			exemplarCity => q#Shikagoo#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Shiwawaa#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Siwuɖaaɖ Huwarɛs#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kɔrɖobaa#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kɔsta Rikaa#,
		},
		'America/Creston' => {
			exemplarCity => q#Krɛstɔn#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuyabaa#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasaawu#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Ɖanǝmarkɩhaʊn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Ɖɔɔsǝn#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Ɖɔɔsǝn Kriik#,
		},
		'America/Denver' => {
			exemplarCity => q#Ɖɛnfa#,
		},
		'America/Detroit' => {
			exemplarCity => q#Ɖitrɔɔɩ#,
		},
		'America/Dominica' => {
			exemplarCity => q#Ɖominikaa#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Ɛɖmɔntɔn#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Ɛɩrunepee#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Ɛl Salfaɖɔɔr#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fɔɔr Nɛlsɔn#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fɔrtalɛsaa#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glaas Baɩ#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Guus Baɩ#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Granɖ Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenaaɖa#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guwaɖeluupu#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guwatemalaa#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guwayakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyanaa#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaas#,
		},
		'America/Havana' => {
			exemplarCity => q#Hafanaa#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Ɛrmosiloo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Nɔk, Ɩnɖiyaana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marɛŋgo, Ɩnɖiyaana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petɛrsbuur, Ɩnɖiyaana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tɛl Siti, Ɩnɖiyaana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Fefɛɩ, Ɩnɖiyaana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Fɛŋsɛn, Ɩnɖiyaana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamaak, Ɩnɖiyaana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Ɩnɖiyaanapoli#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inufik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluwiit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaɩka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Huhuyi#,
		},
		'America/Juneau' => {
			exemplarCity => q#Jinoo#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Mɔntishɛɛlo, Kɛntaki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralɛnɖaɩk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Pas#,
		},
		'America/Lima' => {
			exemplarCity => q#Limaa#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Lɔs Anjɛlɛɛs#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luwifiil#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lowɛɛ Prɛŋs Kwata#,
		},
		'America/Maceio' => {
			exemplarCity => q#Masɛɩyoo#,
		},
		'America/Managua' => {
			exemplarCity => q#Manaaguwa#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaʊs#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigoo#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martiniiki#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoroos#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Masatǝlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mɛnɖɔsaa#,
		},
		'America/Merida' => {
			exemplarCity => q#Meriiɖa#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metelakatelaa#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mɛsiko Siti#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelɔŋ#,
		},
		'America/Moncton' => {
			exemplarCity => q#Mɔŋtɔn#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Mɔntɛrɛɩ#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Mɔntefiɖeyoo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Mɔnsɛraatɩ#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasau#,
		},
		'America/New_York' => {
			exemplarCity => q#Niu Yɔrk#,
		},
		'America/Noronha' => {
			exemplarCity => q#Norɔnya#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Biula, Nɔɔr Ɖakoota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sɛnta, Nɔɔr Ɖakoota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Niu Salɛm, Nɔɔr Ɖakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamaa#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramariboo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Finiis#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Pɔɔr o Prɛŋs#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Pɔɔr ɔf Spɛɛn#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Pɔrto Feloo#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Pɔrto Rikoo#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Raŋkɩn Ɩnlɛɛtɩ#,
		},
		'America/Recife' => {
			exemplarCity => q#Resife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regiina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rɛsoluut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riyo Braŋkoo#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarɛm#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiyagoo#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Ɖomɩŋgo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Pauloo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itokɔrtoomiiti#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitkaa#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sɛŋ-Batolomayɔ#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sɛŋ Jɔɔns#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sɛŋ Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sɛŋ Lusiya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sɛŋ Tomaasɩ#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sɛŋ Fɩnsaŋ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Sǝwɩftɩ Kǝrɛɛntɩ#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tuule#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tihuwana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Torɔntoo#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tɔrtɔlaa#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Fɛŋkuufa#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Waɩthɔɔs#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winipɛɛg#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Amalɩka gʊnyɩpɛnɛlaŋ kagɩcɩɩca kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Amalɩka gʊnyɩpɛnɛlaŋ kagɩcɩɩca kaakɔŋkɔŋɔ̀#,
				'standard' => q#Amalɩka gʊnyɩpɛnɛlaŋ kagɩcɩɩca kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Amalɩka gʊnyɩpɛnɛlaŋ kaajakalaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Amalɩka gʊnyɩpɛnɛlaŋ kaajakalaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Amalɩka gʊnyɩpɛnɛlaŋ kaajakalaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Amalɩka gʊnyɩpɛnɛlaŋ kabʊnʊ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Amalɩka gʊnyɩpɛnɛlaŋ kabʊnʊ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Amalɩka gʊnyɩpɛnɛlaŋ kabʊnʊ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Amalɩka kapasifika kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Amalɩka kapasifika kaakɔŋkɔŋɔ̀#,
				'standard' => q#Amalɩka kapasifika kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keesi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Ɖefis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Ɖimɔn Ɖirfil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makarii#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mɔsɔn#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#MɛkMɔrɖoo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmɛɛr#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Roteraa#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Siyowaa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Trɔl#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Fɔstɔk#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apiya kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Apiya kaakɔŋkɔŋɔ̀#,
				'standard' => q#Apiya kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Galaaributǝna kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Galaaributǝna kaakɔŋkɔŋɔ̀#,
				'standard' => q#Galaaributǝna kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Lɔŋyiirbiyɛn#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Arjantin kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Arjantin kaakɔŋkɔŋɔ̀#,
				'standard' => q#Arjantin kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Arjantin gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Arjantin gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Arjantin gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenii kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Armenii kaakɔŋkɔŋɔ̀#,
				'standard' => q#Armenii kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aɖɛn#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatii#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amaan#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anaɖiir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktaʊ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobee#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabaat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atiraʊ#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagɖaaɖ#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barɛɛn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakuu#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Baŋkɔk#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnawul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beiruut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkɛk#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunɛɩ#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kɔlkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Shitaa#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolomboo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Ɖamaskɔɔsɩ#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Ɖakaa#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Ɖilii#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Ɖubaɩ#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Ɖushanbee#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagustaa#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gasaa#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrɔn#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hɔŋ Kɔŋ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hɔfɖǝ#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkut#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakataa#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapuraa#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalɛm#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamshatkaa#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karacɩ#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmanɖuu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Kanɖigaa#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyark#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuwala Lumpuur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuciŋ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koweeti#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makawoo#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magaɖan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasaar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manilaa#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskaat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nofokusnɛk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nofosibirk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Ɔmsǝkǝ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oraal#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Nɔm Pɛn#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pɔntiyanak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pɩyɔŋyaŋ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Kataa#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kɔstanaɩ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kisilɔrɖaa#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yaŋgɔn#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyaaɖ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Ci Min kaMpá#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkanɖ#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Sewul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shaŋgaɩ#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Siŋgapuur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srɛɖnɛkɔlim#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taɩpei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkɛnt#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiblisii#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teeraan#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timfu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokiyoo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tɔmsǝkǝ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbatɔɔr#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumkii#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Neraa#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Fiyentiyan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Flaɖifɔstɔk#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakut#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinbuu#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerefaan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Amalɩka katǝlantika kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Amalɩka katǝlantika kaakɔŋkɔŋɔ̀#,
				'standard' => q#Amalɩka katǝlantika kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asɔɔr#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bɛrmuɖaa#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanarii#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kapfɛɛr#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroi#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Maɖeiraa#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rɛɩkyafik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Jɔrjiya gʊnyɩsonolaŋ kaja#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sɛŋ Elenaa#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanlɛɩ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Aɖelɛɛɖ#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbɛn#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Brokǝn Hil#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Ɖarfin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Uklaa#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobaa#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Linɖeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lɔrɖ Hoo#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Mɛlbɔrn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pɛrt#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Siɖnee#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ɔstraliya kagɩcɩɩca kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Ɔstraliya kagɩcɩɩca kaakɔŋkɔŋɔ̀#,
				'standard' => q#Ɔstraliya kagɩcɩɩca kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ɔstraliya kagɩcɩɩca gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Ɔstraliya kagɩcɩɩca gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Ɔstraliya kagɩcɩɩca gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ɔstraliya kaajakalaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Ɔstraliya kaajakalaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Ɔstraliya kaajakalaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ɔstraliya kagɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Ɔstraliya kagɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Ɔstraliya kagɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Asɛrbaɩjaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Asɛrbaɩjaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Asɛrbaɩjaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Asɔɔr kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Asɔɔr kaakɔŋkɔŋɔ̀#,
				'standard' => q#Asɔɔr kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Baŋglaɖɛɛshɩ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Baŋglaɖɛɛshɩ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Baŋglaɖɛɛshɩ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan kaakɔŋkɔŋɔ̀#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolifiya kaakɔŋkɔŋɔ̀#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasiliya kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Brasiliya kaakɔŋkɔŋɔ̀#,
				'standard' => q#Brasiliya kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunɛɩ Ɖarusalaam kaakɔŋkɔŋɔ̀#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapfɛɛr kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Kapfɛɛr kaakɔŋkɔŋɔ̀#,
				'standard' => q#Kapfɛɛr kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Shamoroo kaakɔŋkɔŋɔ̀#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Shatam kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Shatam kaakɔŋkɔŋɔ̀#,
				'standard' => q#Shatam kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Shilii kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Shilii kaakɔŋkɔŋɔ̀#,
				'standard' => q#Shilii kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Caɩna kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Caɩna kaakɔŋkɔŋɔ̀#,
				'standard' => q#Caɩna kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Nowɛl kaAtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokoos kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolɔmbii kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Kolɔmbii kaakɔŋkɔŋɔ̀#,
				'standard' => q#Kolɔmbii kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kʊkʊ kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Kʊkʊ kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
				'standard' => q#Kʊkʊ kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubaa kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Kubaa kaakɔŋkɔŋɔ̀#,
				'standard' => q#Kubaa kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ɖefis kaakɔŋkɔŋɔ̀#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ɖimɔn Ɖirfil kaakɔŋkɔŋɔ̀#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Timɔɔ gajakalaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Paakɩ kaAtukǝltǝna kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Paakɩ kaAatukǝltǝna kaakɔŋkɔŋɔ̀#,
				'standard' => q#Paakɩ kaAtukǝltǝna kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekuwaɖɔɔr kaakɔŋkɔŋɔ̀#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ɖulinya aŋunii kaakɔŋkɔŋɔ̀#,
			},
			short => {
				'standard' => q#ƉAK#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#mpá nɖee kʊyɔʊ ʊ mana ma#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amstɛrɖam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Anɖɔraa#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakaan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atɛn#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Bɛlgraaɖ#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Bɛrlɛŋ#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislafa#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brisɛl#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarɛs#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Buɖapɛs#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busiŋgɛn#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Shisinoo#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenaag#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Ɖɔblɛŋ#,
			long => {
				'daylight' => q#Irlanɖ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltaa#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gǝrǝnsɛɩ#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hɛlsiŋkii#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man kaAtukǝltǝna#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istambuul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersei#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliniŋgraaɖ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyɛf#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirɔɔf#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbɔn#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Yubǝlyana#,
		},
		'Europe/London' => {
			exemplarCity => q#Lɔnɖɔn#,
			long => {
				'daylight' => q#Gagɛɛshɩtǝna kaakɔŋkɔŋɔ̀ gafʊbaka#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lusɛmbuur#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Maɖriiɖ#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariyeham#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mɩns#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monakoo#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskuu#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ɔsloo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parii#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Poɖgorikaa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Rigaa#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Room#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samaraa#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marinoo#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayefoo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratɔɔf#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skɔpyɛ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stɔkhɔlm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiranaa#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanɔɔf#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Faɖus#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Fatikaŋ#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Fiyɛna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Filniyus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Fɔlgograaɖ#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaʊ#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Sagrɛb#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Suriik#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Garɩfɔntǝna gɩcɩɩca kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Garɩfɔntǝna gɩcɩɩca kaakɔŋkɔŋɔ̀#,
				'standard' => q#Garɩfɔntǝna gɩcɩɩca kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Garɩfɔntǝna gajakalaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Garɩfɔntǝna gajakalaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Garɩfɔntǝna gajakalaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Garɩfɔntǝna gajakalaŋ kaajakalaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Garɩfɔntǝna gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Garɩfɔntǝna gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Garɩfɔntǝna gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Fɔklanɖ kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Fɔklanɖ kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
				'standard' => q#Fɔklanɖ kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Fiji kaakɔŋkɔŋɔ̀#,
				'standard' => q#Fiji kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Guyanaa Gafɔntǝna kaja kaakɔŋkɔŋɔ̀#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Gafɔntǝna gʊnyɩsonolaŋ na Gatutaltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Griinwish kaakɔŋkɔŋɔ̀#,
			},
			short => {
				'standard' => q#Gk#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagɔs kaakɔŋkɔŋɔ̀#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiyee kaakɔŋkɔŋɔ̀#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Jɔrjiya kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Jɔrjiya kaakɔŋkɔŋɔ̀#,
				'standard' => q#Jɔrjiya kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Jilbɛɛr kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Grinlanɖ gajakalaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Grinlanɖ gajakalaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Grinlanɖ gajakalaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Grinlanɖ gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Grinlanɖ gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Grinlanɖ gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guwam kaakɔŋkɔŋɔ̀#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gɔlf kaakɔŋkɔŋɔ̀#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyanaa kaakɔŋkɔŋɔ̀#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Awayɩɩ n’Alewutii kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Awayɩɩ n’Alewutii kaakɔŋkɔŋɔ̀#,
				'standard' => q#Awayɩɩ n’Alewutii kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hɔŋ Kɔŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Hɔŋ Kɔŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Hɔŋ Kɔŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hɔfɖǝ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Hɔfɖǝ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Hɔfɖǝ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Inɖiya kaakɔŋkɔŋɔ̀#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarifoo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Shagɔs#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Nowɛl#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokoos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoroo#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kɛrgelɛɛn#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahee#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malɖiifu#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Imoris#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayɔɔtɩ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reeniyɔŋ#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Inɖiya kateŋku kaakɔŋkɔŋɔ̀#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Inɖicaɩna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ɛnɖonosii kagɩcɩɩca kaakɔŋkɔŋɔ̀#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ɛnɖonosii kaajakalaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ɛnɖonosii kagɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iraŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Iraŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Iraŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkut kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Irkut kaakɔŋkɔŋɔ̀#,
				'standard' => q#Irkut kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Yishraɛl kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Yishraɛl kaakɔŋkɔŋɔ̀#,
				'standard' => q#Yishraɛl kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japaŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Japaŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Japaŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Kasastan kaakɔŋkɔŋɔ̀#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Kasastan gajakalaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Kasastan gɩteŋshilelaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koree kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Koree kaakɔŋkɔŋɔ̀#,
				'standard' => q#Koree kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kɔsrɛɛ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyark kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Krasnoyark kaakɔŋkɔŋɔ̀#,
				'standard' => q#Krasnoyark kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistan kaakɔŋkɔŋɔ̀#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Siri Laŋkaa kaakɔŋkɔŋɔ̀#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Laɩn kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lɔrɖ Hoo kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Lɔrɖ Hoo kaakɔŋkɔŋɔ̀#,
				'standard' => q#Lɔrɖ Hoo kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#akawoo kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Makawoo kaakɔŋkɔŋɔ̀#,
				'standard' => q#Makawoo kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magaɖan kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Magaɖan kaakɔŋkɔŋɔ̀#,
				'standard' => q#Magaɖan kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malɛsii kaakɔŋkɔŋɔ̀#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malɖiifu kaakɔŋkɔŋɔ̀#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markesas kaakɔŋkɔŋɔ̀#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshal kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Imoris kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Imoris kaakɔŋkɔŋɔ̀#,
				'standard' => q#Imoris kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mɔsɔn kaakɔŋkɔŋɔ̀#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mɛsik kapasifika kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Mɛsik kapasifika kaakɔŋkɔŋɔ̀#,
				'standard' => q#Mɛsik kapasifika kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulanbatɔɔr kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Ulanbatɔɔr kaakɔŋkɔŋɔ̀#,
				'standard' => q#Ulanbatɔɔr kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskuu kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Moskuu kaakɔŋkɔŋɔ̀#,
				'standard' => q#Moskuu kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Miyanmaa kaakɔŋkɔŋɔ̀#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nawuru kaakɔŋkɔŋɔ̀#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Neepal kaakɔŋkɔŋɔ̀#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Kaleɖonii afɔlɩ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Kaleɖonii afɔlɩ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Kaleɖonii afɔlɩ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Selanɖ afɔlɩ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Selanɖ afɔlɩ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Selanɖ afɔlɩ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Faʊnɖlanɖ afɔlɩ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Faʊnɖlanɖ afɔlɩ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Faʊnɖlanɖ afɔlɩ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niwuye kaakɔŋkɔŋɔ̀#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Nɔrfook kaAtukǝltǝna kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Nɔrfook kaAtukǝltǝna kaakɔŋkɔŋɔ̀#,
				'standard' => q#Nɔrfook kaAtukǝltǝna kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fɛrnanɖo ɖe Norɔnya kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Fɛrnanɖo ɖe Norɔnya kaakɔŋkɔŋɔ̀#,
				'standard' => q#Fɛrnanɖo ɖe Norɔnya kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Mariyan kǝbʊtukǝltǝna gʊnyɩpɛnɛlaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nofosibirk kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Nofosibirk kaakɔŋkɔŋɔ̀#,
				'standard' => q#Nofosibirk kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ɔmsǝkǝ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Ɔmsǝkǝ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Ɔmsǝkǝ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apiya#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Ɔɔklanɖ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugɛɛŋfil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Shatam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ista#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efatee#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakawofoo#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafutii#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagɔs#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambiyee#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guwaɖalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guwam#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Kantɔn#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kirimatii#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kɔsrɛɛ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalɛɛn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuroo#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Miɖwee#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nawuru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niwuye#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nɔrfook#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numeya#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pagoo#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palawoo#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pɩtkɛɛn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Poonpee#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pɔɔr Mɔrɛsbii#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotɔŋga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saɩpan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahitii#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawaa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tɔŋgatapuu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Cuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Week#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Walis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Pakistan kaakɔŋkɔŋɔ̀#,
				'standard' => q#Pakistan kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palawoo kaakɔŋkɔŋɔ̀#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papuasii Ginee afɔlɩ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguwee kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Paraguwee kaakɔŋkɔŋɔ̀#,
				'standard' => q#Paraguwee kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruu kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Peruu kaakɔŋkɔŋɔ̀#,
				'standard' => q#Peruu kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipiin kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Filipiin kaakɔŋkɔŋɔ̀#,
				'standard' => q#Filipiin kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Foeniis kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sɛŋ-Petrɔs na Mikelɔŋ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Sɛŋ-Petrɔs na Mikelɔŋ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Sɛŋ-Petrɔs na Mikelɔŋ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pɩtkɛɛn kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapee kaakɔŋkɔŋɔ̀#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pɩyɔŋyaŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reeniyɔŋ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Roteraa kaakɔŋkɔŋɔ̀#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakalin kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Sakalin kaakɔŋkɔŋɔ̀#,
				'standard' => q#Sakalin kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samowa kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Samowa kaakɔŋkɔŋɔ̀#,
				'standard' => q#Samowa kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seshɛl kaakɔŋkɔŋɔ̀#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Siŋgapuur kaakɔŋkɔŋɔ̀#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomɔɔn kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Jɔrjiya gʊnyɩsono kaakɔŋkɔŋɔ̀#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam kaakɔŋkɔŋɔ̀#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Siyowaa kaakɔŋkɔŋɔ̀#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitii kaakɔŋkɔŋɔ̀#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taɩpei kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Taɩpei kaakɔŋkɔŋɔ̀#,
				'standard' => q#Taɩpei kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tajikistan kaakɔŋkɔŋɔ̀#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelaʊ kaakɔŋkɔŋɔ̀#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tɔŋga kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Tɔŋga kaakɔŋkɔŋɔ̀#,
				'standard' => q#Tɔŋga kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Cuuk kaakɔŋkɔŋɔ̀#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Turkmenistan kaakɔŋkɔŋɔ̀#,
				'standard' => q#Turkmenistan kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tufalu kaakɔŋkɔŋɔ̀#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguwee kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Uruguwee kaakɔŋkɔŋɔ̀#,
				'standard' => q#Uruguwee kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbeekistan kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Usbeekistan kaakɔŋkɔŋɔ̀#,
				'standard' => q#Usbeekistan kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Fanuwatu kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Fanuwatu kaakɔŋkɔŋɔ̀#,
				'standard' => q#Fanuwatu kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Fenesuwelaa kaakɔŋkɔŋɔ̀#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Flaɖifɔstɔk kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Flaɖifɔstɔk kaakɔŋkɔŋɔ̀#,
				'standard' => q#Flaɖifɔstɔk kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Fɔlgograaɖ kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Fɔlgograaɖ kaakɔŋkɔŋɔ̀#,
				'standard' => q#Fɔlgograaɖ kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Fɔstɔk kaakɔŋkɔŋɔ̀#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Week kaBʊtukǝltǝna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Walis na Futuna kaakɔŋkɔŋɔ̀#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakut kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Yakut kaakɔŋkɔŋɔ̀#,
				'standard' => q#Yakut kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinbuu kaakɔŋkɔŋɔ̀ gafʊbaka#,
				'generic' => q#Yekaterinbuu kaakɔŋkɔŋɔ̀#,
				'standard' => q#Yekaterinbuu kaakɔŋkɔŋɔ̀ ɖeiɖei#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukɔn kaakɔŋkɔŋɔ̀#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
