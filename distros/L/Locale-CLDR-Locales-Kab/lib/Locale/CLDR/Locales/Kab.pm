=head1

Locale::CLDR::Locales::Kab - Package for language Kabyle

=cut

package Locale::CLDR::Locales::Kab;
# This file auto generated from Data\common\main\kab.xml
#	on Fri 29 Apr  7:11:30 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

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
				'ak' => 'Takanit',
 				'am' => 'Tamahrict',
 				'ar' => 'Taɛrabt',
 				'be' => 'Tabilarusit',
 				'bg' => 'Tabulgarit',
 				'bn' => 'Tabengalit',
 				'cs' => 'Tačikit',
 				'de' => 'Talmant',
 				'el' => 'Tagrikit',
 				'en' => 'Taglizit',
 				'es' => 'Taspenyulit',
 				'fa' => 'Tafarisit',
 				'fr' => 'Tafransist',
 				'ha' => 'Tahwasit',
 				'hi' => 'Tahendit',
 				'hu' => 'Tahungarit',
 				'id' => 'Tandunisit',
 				'ig' => 'Tigbut',
 				'it' => 'Taṭalyanit',
 				'ja' => 'Tajapunit',
 				'jv' => 'Tajavanit',
 				'kab' => 'Taqbaylit',
 				'km' => 'Takemrit',
 				'ko' => 'Takurit',
 				'ms' => 'Tamalawit',
 				'my' => 'Taburmisit',
 				'ne' => 'Tanipalit',
 				'nl' => 'Tadučit',
 				'pa' => 'Tapunjabit',
 				'pl' => 'Tapulunit',
 				'pt' => 'Tapurtugalit',
 				'ro' => 'Tarumanit',
 				'ru' => 'Tarusit',
 				'rw' => 'Taruwandit',
 				'so' => 'Taṣumalit',
 				'sv' => 'Taswidit',
 				'ta' => 'Taṭamulit',
 				'th' => 'Taṭaylundit',
 				'tr' => 'Taṭurkit',
 				'uk' => 'Tukranit',
 				'ur' => 'Turdut',
 				'vi' => 'Tabyiṭnamit',
 				'yo' => 'Tayurubit',
 				'zh' => 'Tacinwat, Tamundarint',
 				'zu' => 'Tazulut',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'AD' => 'Undura',
 			'AE' => 'Tigeldunin Yedduklen Taɛrabin',
 			'AF' => 'Afɣanistan',
 			'AG' => 'Untiga d Barbuda',
 			'AI' => 'Ungiya',
 			'AL' => 'Lalbani',
 			'AM' => 'Arminya',
 			'AO' => 'Ungula',
 			'AR' => 'Arjuntin',
 			'AS' => 'Samwa Tamarikanit',
 			'AT' => 'Ustriya',
 			'AU' => 'Ustrali',
 			'AW' => 'Aruba',
 			'AZ' => 'Azrabijan',
 			'BA' => 'Busna d Hersek',
 			'BB' => 'Barbadus',
 			'BD' => 'Bangladac',
 			'BE' => 'Belǧik',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Bulgari',
 			'BH' => 'Baḥrin',
 			'BI' => 'Burandi',
 			'BJ' => 'Binin',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruney',
 			'BO' => 'Bulivi',
 			'BR' => 'Brizil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BW' => 'Bustwana',
 			'BY' => 'Bilarus',
 			'BZ' => 'Biliz',
 			'CA' => 'Kanada',
 			'CD' => 'Tigduda Tagdudant n Kungu',
 			'CF' => 'Tigduda n Tefriqt Talemmast',
 			'CG' => 'Kungu',
 			'CH' => 'Swis',
 			'CI' => 'Kuṭ Divwar',
 			'CK' => 'Tigzirin n Kuk',
 			'CL' => 'Cili',
 			'CM' => 'Kamirun',
 			'CN' => 'Lacin',
 			'CO' => 'Kulumbi',
 			'CR' => 'Kusta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Tigzirin n yixef azegzaw',
 			'CY' => 'Cipr',
 			'CZ' => 'Čček',
 			'DE' => 'Lalman',
 			'DJ' => 'Ǧibuti',
 			'DK' => 'Denmark',
 			'DM' => 'Duminik',
 			'DO' => 'Tigduda Taduminikit',
 			'DZ' => 'Lezzayer',
 			'EC' => 'Ikwaṭur',
 			'EE' => 'Istunya',
 			'EG' => 'Maṣr',
 			'ER' => 'Iritiria',
 			'ES' => 'Spanya',
 			'ET' => 'Utyupi',
 			'FI' => 'Finlund',
 			'FJ' => 'Fiji',
 			'FK' => 'Tigzirin n Falkland',
 			'FM' => 'Mikrunizya',
 			'FR' => 'Fransa',
 			'GA' => 'Gabun',
 			'GB' => 'Tagelda Yedduklen',
 			'GD' => 'Grunad',
 			'GE' => 'Jiyurji',
 			'GF' => 'Ɣana tafransist',
 			'GH' => 'Ɣana',
 			'GI' => 'Jibraltar',
 			'GL' => 'Grunland',
 			'GM' => 'Gambya',
 			'GN' => 'Ɣinya',
 			'GP' => 'Gwadalupi',
 			'GQ' => 'Ɣinya Tasebgast',
 			'GR' => 'Lagris',
 			'GT' => 'Gwatimala',
 			'GU' => 'Gwam',
 			'GW' => 'Ɣinya-Bisaw',
 			'GY' => 'Guwana',
 			'HN' => 'Hunduras',
 			'HR' => 'Kerwasya',
 			'HT' => 'Hayti',
 			'HU' => 'Hungri',
 			'ID' => 'Indunizi',
 			'IE' => 'Lirlund',
 			'IL' => 'Izrayil',
 			'IN' => 'Lhend',
 			'IO' => 'Akal Aglizi deg Ugaraw Ahendi',
 			'IQ' => 'Lɛiraq',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Ṭelyan',
 			'JM' => 'Jamyika',
 			'JO' => 'Lajurdani',
 			'JP' => 'Jappu',
 			'KE' => 'Kinya',
 			'KG' => 'Kirigistan',
 			'KH' => 'Cambudya',
 			'KI' => 'Kiribati',
 			'KM' => 'Kumur',
 			'KN' => 'San Kits d Nivis',
 			'KP' => 'Kurya, Ufella',
 			'KR' => 'Kurya, Wadda',
 			'KW' => 'Kuwayt',
 			'KY' => 'Tigzirin n Kamyan',
 			'KZ' => 'Kazaxistan',
 			'LA' => 'Laws',
 			'LB' => 'Lubnan',
 			'LC' => 'San Lučya',
 			'LI' => 'Layctenstan',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libirya',
 			'LS' => 'Lizuṭu',
 			'LT' => 'Liṭwanya',
 			'LU' => 'Luksamburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Lmerruk',
 			'MC' => 'Munaku',
 			'MD' => 'Muldabi',
 			'MG' => 'Madaɣecqer',
 			'MH' => 'Tigzirin n Marcal',
 			'MK' => 'Masidwan',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mungulya',
 			'MP' => 'Tigzirin n Maryan Ufella',
 			'MQ' => 'Martinik',
 			'MR' => 'Muriṭanya',
 			'MS' => 'Munsirat',
 			'MT' => 'Malṭ',
 			'MU' => 'Muris',
 			'MV' => 'Maldib',
 			'MW' => 'Malawi',
 			'MX' => 'Meksik',
 			'MY' => 'Malizya',
 			'MZ' => 'Muzembiq',
 			'NA' => 'Namibya',
 			'NC' => 'Kalidunya Tamaynut',
 			'NE' => 'Nijer',
 			'NF' => 'Tigzirin Tinawfukin',
 			'NG' => 'Nijirya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Timura-Yessakesren',
 			'NO' => 'Nurvij',
 			'NP' => 'Nipal',
 			'NR' => 'Nuru',
 			'NU' => 'Niwi',
 			'NZ' => 'Ziland Tamaynut',
 			'OM' => 'Ɛuman',
 			'PA' => 'Panam',
 			'PE' => 'Piru',
 			'PF' => 'Pulunizi tafransist',
 			'PG' => 'Ɣinya Tamaynut Tapaput',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistan',
 			'PL' => 'Pulund',
 			'PM' => 'San Pyar d Miklun',
 			'PN' => 'Pitkarin',
 			'PR' => 'Purtu Riku',
 			'PS' => 'Falisṭin d Ɣezza',
 			'PT' => 'Purtugal',
 			'PW' => 'Palu',
 			'PY' => 'Paragway',
 			'QA' => 'Qaṭar',
 			'RE' => 'Timlilit',
 			'RO' => 'Rumani',
 			'RU' => 'Rrus',
 			'RW' => 'Ruwanda',
 			'SA' => 'Suɛudiya Taɛrabt',
 			'SB' => 'Tigzirin n Sulumun',
 			'SC' => 'Seycel',
 			'SD' => 'Sudan',
 			'SE' => 'Swid',
 			'SG' => 'Singafur',
 			'SH' => 'Sant Ilina',
 			'SI' => 'Sluvinya',
 			'SK' => 'Sluvakya',
 			'SL' => 'Sira Lyun',
 			'SM' => 'San Marinu',
 			'SN' => 'Sinigal',
 			'SO' => 'Ṣumal',
 			'SR' => 'Surinam',
 			'ST' => 'Saw Tumi d Pransip',
 			'SV' => 'Salvadur',
 			'SY' => 'Surya',
 			'SZ' => 'Swazilund',
 			'TC' => 'Ṭurk d Tegzirin n Kaykus',
 			'TD' => 'Čad',
 			'TG' => 'Ṭugu',
 			'TH' => 'Ṭayland',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Ṭuklu',
 			'TL' => 'Tumur Asamar',
 			'TM' => 'Ṭurkmanistan',
 			'TN' => 'Tunes',
 			'TO' => 'Ṭunga',
 			'TR' => 'Ṭurk',
 			'TT' => 'Ṭrindad d Ṭubagu',
 			'TV' => 'Ṭuvalu',
 			'TW' => 'Ṭaywan',
 			'TZ' => 'Ṭanzanya',
 			'UA' => 'Ukran',
 			'UG' => 'Uɣanda',
 			'US' => 'WDM',
 			'UY' => 'Urugway',
 			'UZ' => 'Uzbaxistan',
 			'VA' => 'Awanek n Vatikan',
 			'VC' => 'San Vansu d Grunadin',
 			'VE' => 'Venzwila',
 			'VG' => 'Tigzirin Tiverjiniyin Tigliziyin',
 			'VI' => 'W.D. Tigzirin n Virginya',
 			'VN' => 'Vyeṭnam',
 			'VU' => 'Vanwatu',
 			'WF' => 'Wallis d Futuna',
 			'WS' => 'Samwa',
 			'YE' => 'Lyamen',
 			'YT' => 'Mayuṭ',
 			'ZA' => 'Tafriqt Wadda',
 			'ZM' => 'Zambya',
 			'ZW' => 'Zimbabwi',

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
			auxiliary => qr{(?^u:[o v])},
			index => ['A', 'B', 'C', 'Č', 'D', 'Ḍ', 'E', 'Ɛ', 'F', 'G', 'Ǧ', 'Ɣ', 'H', 'Ḥ', 'I', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'Ṛ', 'S', 'Ṣ', 'T', 'Ṭ', 'U', 'W', 'X', 'Y', 'Z', 'Ẓ'],
			main => qr{(?^u:[a b c č d ḍ e ɛ f g ǧ ɣ h ḥ i j k l m n p q r ṛ s ṣ t ṭ u w x y z ẓ])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'D', 'Ḍ', 'E', 'Ɛ', 'F', 'G', 'Ǧ', 'Ɣ', 'H', 'Ḥ', 'I', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'Ṛ', 'S', 'Ṣ', 'T', 'Ṭ', 'U', 'W', 'X', 'Y', 'Z', 'Ẓ'], };
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

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ih|I|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Uhu|U|no|n)$' }
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

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00¤',
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
				'currency' => q(Adirham n Tgeldunin Taɛrabin Yedduklen),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Akwanza n Ungula),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Adular n Lusṭrali),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Adinar Abaḥrini),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Afrank Aburandi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Apula Abusṭwanan),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Adular Akanadi),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Afrank Akunguli),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Afrank Aswis),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Ayuwan Renminbi Acinwa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Akabuviradinu Askudi),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Afrank Ajibuti),
			},
		},
		'DZD' => {
			symbol => 'DA',
			display_name => {
				'currency' => q(Adinar Azzayri),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Apund Amaṣri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Anakfa Iritiri),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Abir Utyupi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Uru),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Apund Aglizi),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Asidi Aɣani),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Adalasi Agambi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Afrank Aɣini),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Arupi Ahendi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Ayen Ajappuni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Aciling Akini),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Afrank Akamiruni),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Adular Alibiri),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Aluṭi Alizuṭi),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Adinar Alibi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Adirham Amerruki),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Aryari Amalgac),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Agiya Amuriṭani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Arupi Amurisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Akwaca Amalawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Amitikal Amuzembiqi),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Adular Anamibi),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Anayra Anijiri),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Afrank Aruwandi),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Aryal Asuɛudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Arupi Aseycili),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Apund Asudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Apund Asant Ilini),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Alyun),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Aciling Aṣumali),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Asw Ṭum d Udubra Amenzay),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Alilangini),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Adinar Atunsi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Aciling Aṭanẓani),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Aciling Awgandi),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Adular WD),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Afrank BCEA CFA),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Afrank BCEAO CFA),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Arand Afriqi n Wadda),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Akwaca Azambi \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Akwaca Azambi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Adular Azimbabwi),
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
							'Yen',
							'Fur',
							'Meɣ',
							'Yeb',
							'May',
							'Yun',
							'Yul',
							'Ɣuc',
							'Cte',
							'Tub',
							'Nun',
							'Duǧ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yennayer',
							'Fuṛar',
							'Meɣres',
							'Yebrir',
							'Mayyu',
							'Yunyu',
							'Yulyu',
							'Ɣuct',
							'Ctembeṛ',
							'Tubeṛ',
							'Nunembeṛ',
							'Duǧembeṛ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Y',
							'F',
							'M',
							'Y',
							'M',
							'Y',
							'Y',
							'Ɣ',
							'C',
							'T',
							'N',
							'D'
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
						mon => 'San',
						tue => 'Kraḍ',
						wed => 'Kuẓ',
						thu => 'Sam',
						fri => 'Sḍis',
						sat => 'Say',
						sun => 'Yan'
					},
					wide => {
						mon => 'Sanass',
						tue => 'Kraḍass',
						wed => 'Kuẓass',
						thu => 'Samass',
						fri => 'Sḍisass',
						sat => 'Sayass',
						sun => 'Yanass'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'K',
						wed => 'K',
						thu => 'S',
						fri => 'S',
						sat => 'S',
						sun => 'Y'
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
					abbreviated => {0 => 'Kḍg1',
						1 => 'Kḍg2',
						2 => 'Kḍg3',
						3 => 'Kḍg4'
					},
					wide => {0 => 'akraḍaggur amenzu',
						1 => 'akraḍaggur wis-sin',
						2 => 'akraḍaggur wis-kraḍ',
						3 => 'akraḍaggur wis-kuẓ'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'pm' => q{n tmeddit},
					'am' => q{n tufat},
				},
				'wide' => {
					'am' => q{n tufat},
					'pm' => q{n tmeddit},
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
				'0' => 'snd. T.Ɛ',
				'1' => 'sld. T.Ɛ'
			},
			wide => {
				'0' => 'send talalit n Ɛisa',
				'1' => 'seld talalit n Ɛisa'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
	} },
);

has 'datetime_formats' => (
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

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
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

no Moo;

1;

# vim: tabstop=4
