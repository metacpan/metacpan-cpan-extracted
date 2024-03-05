=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sw::Latn::Ke - Package for language Swahili

=cut

package Locale::CLDR::Locales::Sw::Latn::Ke;
# This file auto generated from Data\common\main\sw_KE.xml
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

extends('Locale::CLDR::Locales::Sw::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'alt' => 'Kialtai cha Kusini',
 				'arq' => 'Kiarabu cha Aljeria',
 				'atj' => 'Kiatikameku',
 				'az' => 'Kiazabaijani',
 				'ban' => 'Kibalini',
 				'bho' => 'Kibojpuri',
 				'bn' => 'Kibangla',
 				'ce' => 'Kichechen',
 				'ceb' => 'Kisebuano',
 				'ch' => 'Kichamoro',
 				'chk' => 'Kichuuki',
 				'chr' => 'Kicheroki',
 				'ckb' => 'Kikurdi cha Kati',
 				'ckb@alt=menu' => 'Kikurdi, Kati',
 				'ckb@alt=variant' => 'Kikurdi, Sorani',
 				'clc' => 'Kichilkotini',
 				'crg' => 'Kimichif',
 				'crk' => 'Kikrii cha Chini',
 				'crm' => 'Kimoosekrii',
 				'crr' => 'Kialgiki cha Carolina',
 				'csw' => 'Kikrii cha Kinamasi',
 				'cu' => 'Kislovakia cha Kanisa la Jadi',
 				'cy' => 'Kiwels',
 				'de_AT' => 'Kijerumani cha Austria',
 				'de_CH' => 'Kijerumani cha Kawaida cha Uswisi',
 				'dje' => 'Kizama',
 				'en_AU' => 'Kiingereza cha Australia',
 				'en_CA' => 'Kiingereza cha Kanada',
 				'en_GB' => 'Kiingereza cha Uingereza',
 				'en_GB@alt=short' => 'Kiingereza cha Uingereza',
 				'en_US' => 'Kiingereza cha Marekani',
 				'en_US@alt=short' => 'Kiingereza cha Marekani)',
 				'es_419' => 'Kihispania cha Amerika Kusini',
 				'es_ES' => 'Kihispania cha Ulaya',
 				'es_MX' => 'Kihispania cha Meksiko',
 				'fa_AF' => 'Kidari',
 				'ff' => 'Kifula',
 				'fo' => 'Kifaro',
 				'fr_CA' => 'Kifaransa cha Kanada',
 				'fr_CH' => 'Kifaransa cha Uswisi',
 				'frr' => 'Kifrisi cha Kaskazini',
 				'fur' => 'Kifriuli',
 				'fy' => 'Kifrisi cha Magharibi',
 				'gaa' => 'Kiga',
 				'gez' => 'Kigiiz',
 				'gil' => 'Kigilbert',
 				'grc' => 'Kigiriki cha Kale',
 				'gv' => 'Kimaniksi',
 				'gwi' => 'Kigwichʼin',
 				'haw' => 'Kihawaii',
 				'hi_Latn@alt=variant' => 'Kihindi na Kiingereza',
 				'hr' => 'Kikroeshia',
 				'hsb' => 'Kisorbia cha Juu',
 				'ht' => 'Kikrioli cha Haiti',
 				'hup' => 'Kihupa',
 				'hur' => 'Kihalkomelem',
 				'ia' => 'Lugha ya kimataifa',
 				'ig' => 'Kiibo',
 				'ii' => 'Kiiyi cha Sichuan',
 				'ikt' => 'Kiinuktitut cha Kanada Magharibi',
 				'ilo' => 'Kiiloko',
 				'inh' => 'Kiingushi',
 				'is' => 'Kiaisilandi',
 				'jbo' => 'Kilojbani',
 				'kac' => 'Kikachini',
 				'kbd' => 'Kikabadi',
 				'kea' => 'Kikabuvedi',
 				'khq' => 'Kikoyrachiini',
 				'kj' => 'Kikuanyama',
 				'kk' => 'Kikazaki',
 				'kkj' => 'Kikako',
 				'km' => 'Kikhema',
 				'koi' => 'Kikomipermyak',
 				'kpe' => 'Kikpele',
 				'krc' => 'Kikarachaybalka',
 				'krl' => 'Kakareli',
 				'kru' => 'Kikuruki',
 				'ksb' => 'Kisambala',
 				'ksh' => 'Kikolon',
 				'kum' => 'Kikumyk',
 				'kw' => 'Kikoni',
 				'ky' => 'Kikirigizi',
 				'lag' => 'Kilangi',
 				'lam' => 'Kilamba',
 				'lez' => 'Kilezighi',
 				'li' => 'Kilimbugi',
 				'luy' => 'Kiluyia',
 				'mak' => 'Kimakasaa',
 				'mas' => 'Kimasai',
 				'mdf' => 'Kimoksha',
 				'mfe' => 'Kimorisi',
 				'mh' => 'Kimashali',
 				'mic' => 'Kimi\'kmak',
 				'mk' => 'Kimasedonia',
 				'ml' => 'Kimalayalam',
 				'moh' => 'Kimohok',
 				'mos' => 'Kimosi',
 				'mus' => 'Kimuskogii',
 				'mwl' => 'Kimiranda',
 				'my' => 'Kibama',
 				'nds' => 'Kijerumani cha Chini',
 				'nnh' => 'Kiingiemboon',
 				'nqo' => 'Kiin’ko',
 				'nr' => 'Kindebele cha Kusini',
 				'oc' => 'Kiositia',
 				'ojc' => 'Kiojibwa cha Kati',
 				'or' => 'Kiodia',
 				'pag' => 'Kipangasini',
 				'pcm' => 'Kipijini cha Naijeria',
 				'pt_BR' => 'Kireno cha Brazili',
 				'pt_PT' => 'Kireno cha Ulaya',
 				'rm' => 'Kirumi',
 				'rwk' => 'Kirwa',
 				'sba' => 'Kingambei',
 				'sc' => 'Kisadini',
 				'scn' => 'Kisisilia',
 				'ses' => 'Kikoyraborosenni',
 				'shn' => 'Kishani',
 				'shu' => 'Kiarabu cha Chadi',
 				'slh' => 'Kilushootseed cha Kusini',
 				'srn' => 'Kisranantongo',
 				'st' => 'Kisotho cha Kusini',
 				'str' => 'Kisali cha Straits',
 				'su' => 'Kisundani',
 				'sw_CD' => 'Kiswahili cha Kongo',
 				'swb' => 'Kikomoro',
 				'syr' => 'Kisiria',
 				'tce' => 'Kituchone cha Kusini',
 				'tem' => 'Kitimne',
 				'tgx' => 'Kitagi',
 				'tht' => 'Kitahlti',
 				'tn' => 'Kiswana',
 				'tok' => 'Kitokipona',
 				'ts' => 'Kisonga',
 				'ttm' => 'Kituchone cha Kaskazini',
 				'tw' => 'Kitwi',
 				'tzm' => 'Kitamazight cha Atlas ya Kati',
 				'udm' => 'Kiudumurti',
 				'ug' => 'Kiuiguri',
 				'uk' => 'Kiukreni',
 				'umb' => 'Kiumbundu',
 				'wa' => 'Kiwaluni',
 				'wae' => 'Kiwalsa',
 				'wal' => 'Kiwolaitta',
 				'war' => 'Kiwarai',
 				'wo' => 'Kiwolof',
 				'xh' => 'Kikhosa',
 				'yav' => 'Kiyangbeni',
 				'yi' => 'Kiyidi',
 				'zgh' => 'Kitamazight cha Kawaida cha Moroko',
 				'zh@alt=menu' => 'Kichina, Kimandarini',
 				'zh_Hans' => 'Kichina Kilichorahisishwa',
 				'zh_Hans@alt=long' => 'Kichina cha Kimandarini Kilichorahisishwa',
 				'zh_Hant' => 'Kichina cha Kawaida',
 				'zh_Hant@alt=long' => 'Kichina cha Kimandarini cha Kawaida',

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
			'Beng' => 'Kibangla',
 			'Brai' => 'Breli',
 			'Cans' => 'Silabi za Asili Zilizounganishwa za Kanada',
 			'Cher' => 'Kicherokii',
 			'Cyrl' => 'Kikrili',
 			'Ethi' => 'Kihabeshi',
 			'Hanb' => 'Kihan chenye Kibopomofo',
 			'Hans' => 'Kilichorahisishwa',
 			'Hans@alt=stand-alone' => 'Kihan Kilichorahisishwa',
 			'Hira' => 'Kihiragana',
 			'Hrkt' => 'Silabi za Kijapani',
 			'Jamo' => 'Kijamo',
 			'Khmr' => 'Kikhema',
 			'Mtei' => 'Kimeiteimayek',
 			'Mymr' => 'Kimyanma',
 			'Nkoo' => 'Kiin’ko',
 			'Olck' => 'Kiolchiki',
 			'Orya' => 'Kiodia',
 			'Sund' => 'Kisundani',
 			'Syrc' => 'Kisiria',
 			'Taml' => 'Kitamili',
 			'Yiii' => 'Kiiyi',
 			'Zmth' => 'Mwandiko wa kihisabati',

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
			'001' => 'dunia',
 			'011' => 'Afrika Magharibi',
 			'014' => 'Afrika Mashariki',
 			'015' => 'Afrika Kaskazini',
 			'030' => 'Asia Mashariki',
 			'034' => 'Asia Kusini',
 			'035' => 'Kusini Mashariki mwa Asia',
 			'039' => 'Ulaya Kusini',
 			'057' => 'Maikronesia',
 			'061' => 'Polinesia',
 			'145' => 'Asia Magharibi',
 			'151' => 'Ulaya Mashariki',
 			'154' => 'Ulaya Kaskazini',
 			'155' => 'Ulaya Magharibi',
 			'202' => 'Kusini mwa Jangwa la Sahara',
 			'AF' => 'Afghanistani',
 			'AG' => 'Antigua na Babuda',
 			'AI' => 'Anguila',
 			'AQ' => 'Antaktika',
 			'AZ' => 'Azabajani',
 			'BB' => 'Babados',
 			'BJ' => 'Benini',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutani',
 			'BY' => 'Belarusi',
 			'CC' => 'Visiwa vya Kokos (Keeling)',
 			'CD' => 'Kongo - Kinshasa',
 			'CV' => 'Kepuvede',
 			'CW' => 'Kurakao',
 			'EA' => 'Keuta na Melilla',
 			'EC' => 'Ekwado',
 			'GA' => 'Gaboni',
 			'GP' => 'Gwadelupe',
 			'GS' => 'Visiwa vya Jojia Kusini na Sandwich Kusini',
 			'GT' => 'Gwatemala',
 			'GU' => 'Guami',
 			'HR' => 'Kroashia',
 			'JO' => 'Yordani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LI' => 'Lishenteni',
 			'LS' => 'Lesotho',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MK' => 'Masedonia',
 			'MM' => 'Myama (Burma)',
 			'MS' => 'Montserati',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nijeri',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'OM' => 'Omani',
 			'PF' => 'Polinesia ya Ufaransa',
 			'PG' => 'Papua Guinea Mpya',
 			'PL' => 'Polandi',
 			'PM' => 'St. Pierre na Miquelon',
 			'PR' => 'Pwetoriko',
 			'PS' => 'Himaya za Palestina',
 			'PY' => 'Paragwai',
 			'QA' => 'Katari',
 			'QO' => 'Eneo la Oceania',
 			'SG' => 'Singapuri',
 			'ST' => 'Sao Tome na Prinsipe',
 			'SV' => 'Elsalvado',
 			'SY' => 'Shamu',
 			'TD' => 'Chadi',
 			'TH' => 'Thailandi',
 			'TM' => 'Turukimenstani',
 			'TW' => 'Taiwani',
 			'UA' => 'Ukreni',
 			'US@alt=short' => 'Marekani',
 			'UY' => 'Urugwai',
 			'VA' => 'Mji wa Vatikani',
 			'VG' => 'Visiwa vya Virgin vya Uingereza',
 			'VI' => 'Visiwa vya Virgin vya Marekani',
 			'XA' => 'Lafudhi za Kigeni',
 			'XB' => 'Lugha Bandia',
 			'YT' => 'Mayote',
 			'ZZ' => 'Eneo Lisilojulikana',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'hc' => 'Kipindi cha saa (12 dhidi ya 24)',
 			'va' => 'Tofauti ya Lugha',

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
 				'dangi' => q{Kalenda ya Kidangi},
 				'ethiopic' => q{Kalenda ya Kihabeshi},
 				'hebrew' => q{Kalenda ya kihibrania},
 			},
 			'numbers' => {
 				'ethi' => q{Nambari za Kihabeshi},
 				'geor' => q{Nambari za Kijiojia},
 				'hebr' => q{Nambari za Kihibrania},
 				'mlym' => q{Nambari za Kimalayalam},
 				'mymr' => q{Nambari za Kimyama},
 				'tamldec' => q{Nambari za Kitamili},
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
			'metric' => q{Kipimo},

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
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(maikrosekunde),
						'one' => q(maikroseunde {0}),
						'other' => q(maikrosekunde {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(maikrosekunde),
						'one' => q(maikroseunde {0}),
						'other' => q(maikrosekunde {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nukta kwa kila sentimita),
						'one' => q(nukta {0} kwa kila sentimita),
						'other' => q(nukta {0} kwa kila sentimita),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nukta kwa kila sentimita),
						'one' => q(nukta {0} kwa kila sentimita),
						'other' => q(nukta {0} kwa kila sentimita),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nukta kwa kila inchi),
						'one' => q(nuka {0} kwa kila inchi),
						'other' => q(nukta {0} kwa kila inchi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nukta kwa kila inchi),
						'one' => q(nuka {0} kwa kila inchi),
						'other' => q(nukta {0} kwa kila inchi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ukubwa wa nafasi ya fonti),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ukubwa wa nafasi ya fonti),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q(pikseli {0} kwa kila sekunde),
						'other' => q(pikseli {0} kwa kila sekunde),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q(pikseli {0} kwa kila sekunde),
						'other' => q(pikseli {0} kwa kila sekunde),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q(miaka {0} ya mwanga),
						'other' => q(miaka {0} ya mwanga),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q(miaka {0} ya mwanga),
						'other' => q(miaka {0} ya mwanga),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q(nusu kipenyo {0} cha jua),
						'other' => q(nusu vipenyo {0} vya jua),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q(nusu kipenyo {0} cha jua),
						'other' => q(nusu vipenyo {0} vya jua),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(maili/gal Imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(maili/gal Imp),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(kipimo cha astronomia),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(kipimo cha astronomia),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(mm Hg {0}),
						'other' => q(mm Hg {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(mm Hg {0}),
						'other' => q(mm Hg {0}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(maili/gal Imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(maili/gal Imp),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(mwongo),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(mwongo),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikseli),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikseli),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q(pikseli {0}),
						'other' => q(px {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q(pikseli {0}),
						'other' => q(px {0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(kipimo cha astronomia),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(kipimo cha astronomia),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(maikromita),
						'one' => q(maikromita {0}),
						'other' => q(maikromita {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q(kila sekunde {0}),
						'other' => q(kila sekunde {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q(kila sekunde {0}),
						'other' => q(kila sekunde {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(baa),
						'one' => q(baa {0}),
						'other' => q(baa {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(mm Hg {0}),
						'other' => q(mm Hg {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(mm Hg {0}),
						'other' => q(mm Hg {0}),
					},
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
					'one' => 'elfu 0;elfu -0',
					'other' => 'elfu 0;elfu -0',
				},
				'10000' => {
					'one' => 'elfu 00;elfu -00',
					'other' => 'elfu 00',
				},
				'100000' => {
					'one' => 'elfu 000',
					'other' => 'elfu 000',
				},
				'1000000' => {
					'one' => 'milioni 0',
					'other' => 'milioni 0',
				},
				'10000000' => {
					'one' => 'milioni 00',
					'other' => 'milioni 00',
				},
				'100000000' => {
					'one' => 'milioni 000',
					'other' => 'milioni 000',
				},
				'1000000000' => {
					'one' => 'bilioni 0',
					'other' => 'bilioni 0',
				},
				'10000000000' => {
					'one' => 'bilioni 00',
					'other' => 'bilioni 00',
				},
				'100000000000' => {
					'one' => 'bilioni 000',
					'other' => 'bilioni 000',
				},
				'1000000000000' => {
					'one' => 'trilioni 0',
					'other' => 'trilioni 0',
				},
				'10000000000000' => {
					'one' => 'trilioni 00',
					'other' => 'trilioni 00',
				},
				'100000000000000' => {
					'one' => 'trilioni 000',
					'other' => 'trilioni 000',
				},
			},
			'short' => {
				'1000' => {
					'one' => 'elfu 0',
					'other' => 'elfu 0',
				},
				'10000' => {
					'one' => 'elfu 00',
					'other' => 'elfu 00',
				},
				'100000' => {
					'one' => 'elfu 000',
					'other' => 'elfu 000',
				},
				'1000000' => {
					'one' => 'M0',
					'other' => 'M0',
				},
				'10000000' => {
					'one' => 'M00',
					'other' => 'M00',
				},
				'100000000' => {
					'one' => 'M000',
					'other' => 'M000',
				},
				'1000000000' => {
					'one' => 'B0',
					'other' => 'B0',
				},
				'10000000000' => {
					'one' => 'B00',
					'other' => 'B00',
				},
				'100000000000' => {
					'one' => 'B000',
					'other' => 'B000',
				},
				'1000000000000' => {
					'one' => 'T0',
					'other' => 'T0',
				},
				'10000000000000' => {
					'one' => 'T00',
					'other' => 'T00',
				},
				'100000000000000' => {
					'one' => 'T000',
					'other' => 'T000',
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
						'negative' => '¤-M0',
						'positive' => '¤ M0',
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
				'currency' => q(Diramu ya Falme za Kiarabu),
				'one' => q(diramu ya Falme za Kiarabu),
				'other' => q(diramu za Falme za Kiarabu),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani ya Afghanistani),
				'one' => q(afghani ya Afghanistani),
				'other' => q(afghani za Afghanistani),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Gilda ya Antili ya Uholanzi),
				'one' => q(gilda ya Antili ya Uholanzi),
				'other' => q(gilda za Antili ya Uholanzi),
			},
		},
		'AWG' => {
			display_name => {
				'one' => q(florin ya Aruba),
				'other' => q(florin ya Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manati ya Azabajani),
				'one' => q(manati ya Azabajani),
				'other' => q(manati za Azabajani),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Maki ya Bosnia na Hezegovina Inayoweza Kubadilishwa),
				'one' => q(maki ya Bosnia na Hezegovina inayoweza kubadilishwa),
				'other' => q(maki za Bosnia na Hezegovina zinazoweza kubadilishwa),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dola ya Babadosi),
				'one' => q(dola ya Babadosi),
				'other' => q(dola za Babadosi),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka ya Bangladeshi),
				'one' => q(taka ya Bangladeshi),
				'other' => q(taka za Bangladeshi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dola ya Bamuda),
				'one' => q(dola ya Bamuda),
				'other' => q(dola za Bamuda),
			},
		},
		'BOB' => {
			display_name => {
				'one' => q(boliviano ya Bolivia),
				'other' => q(boliviano za Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Reale ya Brazili),
				'one' => q(reale ya Brazili),
				'other' => q(reale za Brazili),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dola ya Bahama),
				'one' => q(dola ya Bahama),
				'other' => q(dola za Bahama),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrumi ya Bhutani),
				'one' => q(ngultrumi ya Bhutani),
				'other' => q(ngultrumi za Bhutani),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ruble ya Belarusi),
				'one' => q(ruble ya Belarusi),
				'other' => q(ruble za Belarusi),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola ya Kanada),
				'one' => q(dola ya Kanada),
				'other' => q(dola za Kanada),
			},
		},
		'CLP' => {
			display_name => {
				'one' => q(peso ya Chile),
				'other' => q(peso za Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan ya China \(huru\)),
				'one' => q(yuan ya China \(huru\)),
				'other' => q(yuan ya China \(huru\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan ya China),
				'one' => q(yuan ya China),
				'other' => q(yuan za China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Eskudo ya Kepuvede),
				'one' => q(eskudo ya Kepuvede),
				'other' => q(eskudo za Kepuvede),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna ya Cheki),
				'one' => q(koruna ya Cheki),
				'other' => q(koruna za Cheki),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kroni ya Denmaki),
				'one' => q(kroni ya Denmaki),
				'other' => q(kroni za Denmaki),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinari ya Aljeria),
				'one' => q(dinari ya Aljeria),
				'other' => q(dinari za Aljeria),
			},
		},
		'FKP' => {
			display_name => {
				'one' => q(pauni ya Visiwa vya Falkland),
				'other' => q(pauni za Visiwa vya Falkland),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari ya Jiojia),
				'one' => q(lari ya Jiojia),
				'other' => q(lari za Jiojia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Sidi ya Ghana),
				'one' => q(sidi ya Ghana),
				'other' => q(sidi za Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pauni ya Jibrata),
				'one' => q(pauni ya Jibrata),
				'other' => q(pauni za Jibrata),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna ya Kroeshia),
				'one' => q(kuna ya Kroeshia),
				'other' => q(kuna za Kroeshia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Godi ya Haiti),
				'one' => q(godi ya Haiti),
				'other' => q(godi za Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forinti ya Hungaria),
				'one' => q(forinti ya Hungaria),
				'other' => q(forinti za Hungaria),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupia ya Indonesia),
				'one' => q(rupia ya Indonesia),
				'other' => q(rupia za Indonesia),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Riali ya Irani),
				'one' => q(riali ya Irani),
				'other' => q(riali za Irani),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinari ya Yordani),
				'one' => q(dinari ya Yordani),
				'other' => q(dinari za Yordani),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ya Japani),
				'one' => q(yeni ya japani),
				'other' => q(yeni za japani),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Rieli ya Kambodia),
				'one' => q(rieli ya Kambodia),
				'other' => q(rieli za Kambodia),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge ya Kazakistani),
				'one' => q(tenge ya Kazakistani),
				'other' => q(tenge za Kazakistani),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pauni ya Lebanoni),
				'one' => q(pauni ya Lebanoni),
				'other' => q(pauni za Lebanoni),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Diramu ya Moroko),
				'one' => q(diramu ya Moroko),
				'other' => q(diramu za Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'one' => q(ariari ya Madagaska),
				'other' => q(Ariari za Madagaska),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinari ya Masedonia),
				'one' => q(dinari ya Masedonia),
				'other' => q(dinari za Masedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kiati ya Myama),
				'one' => q(kiati ya Myama),
				'other' => q(kiati za Myama),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataka ya Macau),
				'one' => q(pataka ya Macau),
				'other' => q(pataka za Macau),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa ya Maldivi),
				'one' => q(rufiyaa ya Maldivi),
				'other' => q(rufiyaa za Maldivi),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgiti ya Malesia),
				'one' => q(ringgiti ya Malesia),
				'other' => q(ringgiti za Malesia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Naijeria),
				'one' => q(naira ya Naijeria),
				'other' => q(Naira za Naijeria),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Kroni ya Norwe),
				'one' => q(kroni ya Norwe),
				'other' => q(kroni za Norwe),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupia ya Nepali),
				'one' => q(rupia ya Nepali),
				'other' => q(rupia za Nepali),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Riali ya Omani),
				'one' => q(riali ya Omani),
				'other' => q(riali za Omani),
			},
		},
		'PAB' => {
			display_name => {
				'one' => q(balboa za Panama),
				'other' => q(balboa za Panama),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupia ya Pakistani),
				'one' => q(rupia ya Pakistani),
				'other' => q(rupia za Pakistani),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloti ya Polandi),
				'one' => q(zloti ya Polandi),
				'other' => q(zloti za Polandi),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riali ya Katari),
				'one' => q(riali ya Katari),
				'other' => q(riali za Katari),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinari ya Serbia),
				'one' => q(dinari ya Serbia),
				'other' => q(dinari za Serbia),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyali ya Saudia),
				'one' => q(riyali ya Saudia),
				'other' => q(riyali za Saudia),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dola ya Visiwa vya Solomoni),
				'one' => q(dola ya Visiwa vya Solomoni),
				'other' => q(dola za Visiwa vya Solomoni),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pauni ya Sudani),
				'one' => q(pauni ya Sudani),
				'other' => q(pauni za Sudani),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dola ya Singapoo),
				'one' => q(dola ya Singapoo),
				'other' => q(dola za Singapoo),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leoni ya Siera Leoni),
				'one' => q(leoni ya Siera Leoni),
				'other' => q(leoni za Siera Leoni),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leoni ya Siera Leoni \(1964—2022\)),
				'one' => q(leoni ya Siera Leoni \(1964—2022\)),
				'other' => q(leoni za Siera Leoni \(1964—2022\)),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pauni ya Sudani Kusini),
				'one' => q(pauni ya Sudani Kusini),
				'other' => q(pauni za Sudani Kusini),
			},
		},
		'SZL' => {
			display_name => {
				'one' => q(lilangeni ya Uswazi),
				'other' => q(lilangeni za Uswazi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Bahti ya Tailandi),
				'one' => q(bahti ya Tailandi),
				'other' => q(bahti za Tailandi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni ya Tajikistani),
				'one' => q(somoni ya Tajikistani),
				'other' => q(somoni za Tajikistani),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manati ya Turkmenistani),
				'one' => q(manati ya Turkmenistani),
				'other' => q(manati za Turkmenistani),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dola ya Trinidadi na Tobago),
				'one' => q(dola ya Trinidadi na Tobago),
				'other' => q(dola za Trinidadi na Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dola ya Taiwani),
				'one' => q(dola ya Taiwani),
				'other' => q(dola za Taiwani),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia ya Ukraini),
				'one' => q(hryvnia ya Ukraini),
				'other' => q(hryvnia za Ukraini),
			},
		},
		'USD' => {
			symbol => '$',
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som ya Uzbekistani),
				'one' => q(som ya Uzbekistani),
				'other' => q(som za Uzbekistani),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Boliva ya Venezuela),
				'one' => q(boliva ya Venezuele),
				'other' => q(boliva za Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong ya Vietnamu),
				'one' => q(dong ya Vietnamu),
				'other' => q(Dong za Vietnamu),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga ya CFA ya Afrika ya Kati),
				'one' => q(faranga ya CFA ya Afrika ya Kati),
				'other' => q(faranga ya CFA ya Afrika ya Kati),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga ya CFA ya Afrika Magharibi),
				'one' => q(faranga ya CFA ya Afrika Magharibi),
				'other' => q(faranga za CFA ya Afrika Magharibi),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Sarafu Isiyojulikana),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Riali ya Yemeni),
				'one' => q(riali ya Yemeni),
				'other' => q(riali za Yemeni),
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
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 700;
					return 'morning2' if $time >= 700
						&& $time < 1200;
					return 'night1' if $time >= 1900;
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
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
			'short' => q{dd/MM/y},
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
		'gregorian' => {
			GyMd => q{d/M/y G},
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
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#Saa za Afghanistani#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Afrika Magharibi#,
				'generic' => q#Saa za Afrika Magharibi#,
				'standard' => q#Saa za Wastani za Afrika Magharibi#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Amazon#,
				'generic' => q#Saa za Amazon#,
				'standard' => q#Saa za Wastani za Amazon#,
			},
		},
		'America/Barbados' => {
			exemplarCity => q#Babados#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Curacao' => {
			exemplarCity => q#kurakao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Elsalvado#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota Kaskazini#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota Kaskazini#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota Kaskazini#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Bandari ya Uhispania#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Pwetoriko#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Saa za Majira Joto za Ajentina#,
				'generic' => q#Saa za Ajentina#,
				'standard' => q#Saa za Wastani za Ajentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Magharibi mwa Ajentina#,
				'generic' => q#Saa za Magharibi mwa Ajentina#,
				'standard' => q#Saa za Wastani za Magharibi mwa Ajentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Armenia#,
				'generic' => q#Saa za Armenia#,
				'standard' => q#Saa za Wastani za Armenia#,
			},
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Jiji la Ho Chi Minh#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapoo#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Saa za Mchana za Magharibi mwa Australia ya Kati#,
				'generic' => q#Saa za Magharibi mwa Austrialia ya Kati#,
				'standard' => q#Saa za Wastani za Magharibi mwa Australia ya Kati#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Azabajani#,
				'generic' => q#Saa za Azabajani#,
				'standard' => q#Saa za Wastani za Azabajani#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Azores#,
				'generic' => q#Saa za Azores#,
				'standard' => q#Saa za Wastani za Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Bangladeshi#,
				'generic' => q#Saa za Bangladeshi#,
				'standard' => q#Saa za Wastani za Bangladeshi#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Saa za Butani#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Brazili#,
				'generic' => q#Saa za Brazili#,
				'standard' => q#Saa za Wastani za Brazili#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kepuvede#,
				'generic' => q#Saa za Kepuvede#,
				'standard' => q#Saa za Wastani za Kepuvede#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Choibalsan#,
				'generic' => q#Saa za Choibalsan#,
				'standard' => q#Saa za Wastani za Choibalsan#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kolombia#,
				'generic' => q#Saa za Kolombia#,
				'standard' => q#Saa za Wastani za Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Saa za Majira Nusu ya Joto za Visiwa vya Cook#,
				'generic' => q#Saa za Visiwa vya Cook#,
				'standard' => q#Saa za Wastani za Visiwa vya Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Saa za Mchana za Kuba#,
				'generic' => q#Saa za Kuba#,
				'standard' => q#Saa za Wastani za Kuba#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kisiwa cha Easter#,
				'generic' => q#Saa za Kisiwa cha Easter#,
				'standard' => q#Saa za Wastani za Kisiwa cha Easter#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Saa ya Dunia#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Ulaya ya Kati#,
				'generic' => q#Saa za Ulaya ya Kati#,
				'standard' => q#Saa za Wastani za Ulaya ya Kati#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Mashariki mwa Ulaya#,
				'generic' => q#Saa za Mashariki mwa Ulaya#,
				'standard' => q#Saa za Wastani za Mashariki mwa Ulaya#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Magharibi mwa Ulaya#,
				'generic' => q#Saa za Magharibi mwa Ulaya#,
				'standard' => q#Saa za Wastani za Magharibi mwa Ulaya#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Saa za Guiana#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Jiojia#,
				'generic' => q#Saa za Jiojia#,
				'standard' => q#Saa za Wastani za Jiojia#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Greenland Mashariki#,
				'generic' => q#Saa za Greenland Mashariki#,
				'standard' => q#Saa za Wastani za Greenland Mashariki#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Saa za Wastani za Ghuba#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Hong Kong#,
				'generic' => q#Saa za Hong Kong#,
				'standard' => q#Saa za Wastani za Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Hovd#,
				'generic' => q#Saa za Hovd#,
				'standard' => q#Saa za Wastani za Hovd#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krismasi#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivi#,
		},
		'Iran' => {
			long => {
				'daylight' => q#Saa za Mchana za Irani#,
				'generic' => q#Saa za Irani#,
				'standard' => q#Saa za Wastani za Irani#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Irkutsk#,
				'generic' => q#Saa za Irkutsk#,
				'standard' => q#Saa za Wastani za Irkutsk#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Saa za Mchana za Japani#,
				'generic' => q#Saa za Japani#,
				'standard' => q#Saa za Wastani za Japani#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Saa za Kazakistani Mashariki#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Saa za Kazakistani Magharibi#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Krasnoyarsk#,
				'generic' => q#Saa za Krasnoyarsk#,
				'standard' => q#Saa za Wastani za Krasnoyask#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Saa za Makwuarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Magadan#,
				'generic' => q#Saa za Magadan#,
				'standard' => q#Saa za Wastani za Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Saa za Malesia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Saa za Maldivi#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Morisi#,
				'generic' => q#Saa za Morisi#,
				'standard' => q#Saa za Wastani za Morisi#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Saa za Mchana za Kaskazini Magharibi mwa Meksiko#,
				'generic' => q#Saa za Kaskazini Magharibi mwa Meksiko#,
				'standard' => q#Saa za Wastani za Kaskazini Magharibi mwa Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Ulaanbaatar#,
				'generic' => q#Saa za Ulaanbataar#,
				'standard' => q#Saa za Wastani za Ulaanbataar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Moscow#,
				'generic' => q#Saa za Moscow#,
				'standard' => q#Saa za Wastani za Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Saa za Myanma#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Saa za Nepali#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kaledonia Mpya#,
				'generic' => q#Saa za Kaledonia Mpya#,
				'standard' => q#Saa za Wastani za Kaledonia Mpya#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Saa za Mchana za Nyuzilandi#,
				'generic' => q#Saa za Nyuzilandi#,
				'standard' => q#Saa za Wastani za Nyuzilandi#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Kisiwa cha Norfolk#,
				'generic' => q#Saa za Kisiwa cha Norfolk#,
				'standard' => q#Saa za Wastani za Kisiwa cha Norfolk#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Novosibirsk#,
				'generic' => q#Saa za Novosibirsk#,
				'standard' => q#Saa za Wastani za Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Omsk#,
				'generic' => q#Saa za Omsk#,
				'standard' => q#Saa za Wastani za Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Pakistani#,
				'generic' => q#Saa za Pakistani#,
				'standard' => q#Saa za Wastani za Pakistani#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Saa za Papua#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Paragwai#,
				'generic' => q#Saa za Paragwai#,
				'standard' => q#Saa za Wastani za Paragwai#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Peru#,
				'generic' => q#Saa za Peru#,
				'standard' => q#Saa za Wastani za Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Ufilipino#,
				'generic' => q#Saa za Ufilipino#,
				'standard' => q#Saa za Wastani za Ufilipino#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Saa za Visiwa vya Finiksi#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Sakhalin#,
				'generic' => q#Saa za Sakhalin#,
				'standard' => q#Saa za Wastani za Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Saa za Mchana za Samoa#,
				'generic' => q#Saa za Samoa#,
				'standard' => q#Saa za Wastani za Samoa#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Saa za Wastani za Singapoo#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Saa za Jojia Kusini#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Saaza Tajikistani#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Tonga#,
				'generic' => q#Saa za Tonga#,
				'standard' => q#Saa za Wastani za Tonga#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Turkmenistani#,
				'generic' => q#Saa za Turkmenistani#,
				'standard' => q#Saa za Wastani za Turkmenistani#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Urugwai#,
				'generic' => q#Saa za Urugwai#,
				'standard' => q#Saa za Wastani za Urugwai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Uzbekistani#,
				'generic' => q#Saa za Uzbekistani#,
				'standard' => q#Saa za wastani za Uzbekistani#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Vanuatu#,
				'generic' => q#Saa za Vanuatu#,
				'standard' => q#Saa za Wastani za Vanuatu#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Vladivostok#,
				'generic' => q#Saa za Vladivostok#,
				'standard' => q#Saa za Wastani za Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Volgograd#,
				'generic' => q#Saa za Volgograd#,
				'standard' => q#Saa za Wastani za Volgograd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Yakutsk#,
				'generic' => q#Saa za Yakutsk#,
				'standard' => q#Saa za Wastani za Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Saa za Majira ya Joto za Yekaterinburg#,
				'generic' => q#Saa za Yekaterinburg#,
				'standard' => q#Saa za Wastani za Yekaterinburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
