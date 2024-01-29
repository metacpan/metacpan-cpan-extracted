=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Dyo - Package for language Jola-Fonyi

=cut

package Locale::CLDR::Locales::Dyo;
# This file auto generated from Data\common\main\dyo.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
				'ak' => 'akan',
 				'am' => 'amharik',
 				'ar' => 'arab',
 				'be' => 'belarus',
 				'bg' => 'bulgaari',
 				'bn' => 'bengali',
 				'cs' => 'sek',
 				'de' => 'alman',
 				'dyo' => 'joola',
 				'el' => 'greek',
 				'en' => 'angle',
 				'es' => 'español',
 				'fa' => 'persan',
 				'fr' => 'franse',
 				'ha' => 'hausa',
 				'hi' => 'endu',
 				'hu' => 'ongrua',
 				'id' => 'indoneesi',
 				'ig' => 'igbo',
 				'it' => 'italien',
 				'ja' => 'saponee',
 				'jv' => 'savanee',
 				'km' => 'kmeer',
 				'ko' => 'koree',
 				'ms' => 'maleesi',
 				'my' => 'birmani',
 				'ne' => 'nepalees',
 				'nl' => 'neerlande',
 				'pa' => 'penjabi',
 				'pl' => 'polonees',
 				'pt' => 'portugees',
 				'ro' => 'rumeen',
 				'ru' => 'rus',
 				'rw' => 'ruanda',
 				'so' => 'somali',
 				'sv' => 'suedi',
 				'ta' => 'tamil',
 				'th' => 'tay',
 				'tr' => 'turki',
 				'uk' => 'ukrain',
 				'ur' => 'urdu',
 				'vi' => 'vietnam',
 				'yo' => 'yoruba',
 				'zh' => 'sinua',
 				'zu' => 'sulu',

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
			'AD' => 'Andorra',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua di Barbuda',
 			'AI' => 'Angiiya',
 			'AL' => 'Albani',
 			'AM' => 'Armeni',
 			'AO' => 'Angola',
 			'AR' => 'Arsantin',
 			'AS' => 'Samoa yati Amerik',
 			'AT' => 'Otris',
 			'AU' => 'Ostraalia',
 			'AW' => 'Aruba',
 			'AZ' => 'Aserbaysan',
 			'BA' => 'Bosni di Hersegovin',
 			'BB' => 'Barbad',
 			'BD' => 'Banglades',
 			'BE' => 'Belsik',
 			'BF' => 'Burukiina Faso',
 			'BG' => 'Bulgari',
 			'BH' => 'Bahrayn',
 			'BI' => 'Burundi',
 			'BJ' => 'Bene',
 			'BM' => 'Bermud',
 			'BN' => 'Buruney',
 			'BO' => 'Boliivi',
 			'BR' => 'Bresil',
 			'BS' => 'Bahama',
 			'BT' => 'Butan',
 			'BW' => 'Boswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliis',
 			'CA' => 'Kanada',
 			'CD' => 'Mofam demokratik mati Kongo',
 			'CG' => 'Kongo',
 			'CI' => 'Koddiwar',
 			'CL' => 'Cili',
 			'CM' => 'Kamerun',
 			'CN' => 'Siin',
 			'CO' => 'Kolombi',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Ver',
 			'CY' => 'Siipr',
 			'CZ' => 'Mofam mati Cek',
 			'DE' => 'Almaañ',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominika',
 			'DO' => 'Mofam mati Dominik',
 			'DZ' => 'Alseri',
 			'EC' => 'Ekuador',
 			'EE' => 'Estoni',
 			'EG' => 'Esípt',
 			'ER' => 'Eritree',
 			'ES' => 'Espaañ',
 			'ET' => 'Ecoopi',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FR' => 'Frans',
 			'GA' => 'Gabon',
 			'GD' => 'Grenada',
 			'GE' => 'Seorsi',
 			'GH' => 'Gaana',
 			'GI' => 'Sipraltaar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambi',
 			'GN' => 'Giné',
 			'GP' => 'Guwadalup',
 			'GR' => 'Gres',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Giné Bisaau',
 			'GY' => 'Giyan',
 			'HN' => 'Onduras',
 			'HR' => 'Kroasi',
 			'HT' => 'Ayti',
 			'HU' => 'Oŋri',
 			'ID' => 'Endonesi',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IN' => 'End',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Iisland',
 			'IT' => 'Itali',
 			'JM' => 'Samaik',
 			'JP' => 'Sapoŋ',
 			'KE' => 'Keniya',
 			'KH' => 'Kamboj',
 			'KM' => 'Komor',
 			'LC' => 'Saŋ Lusia',
 			'LK' => 'Siri Lanka',
 			'LR' => 'Liberia',
 			'MG' => 'Madagaskaar',
 			'ML' => 'Mali',
 			'NF' => 'Ecinkey yati Noorfok',
 			'SA' => 'Abari Saudi',
 			'SD' => 'Sudan',
 			'SG' => 'Singapur',
 			'SI' => 'Sloveni',
 			'SK' => 'Slovaki',
 			'SL' => 'Serra Leon',
 			'SN' => 'Senegal',
 			'SO' => 'Somali',
 			'SV' => 'Salvadoor',
 			'TD' => 'Cad',
 			'TG' => 'Togo',
 			'TH' => 'Tailand',

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
			auxiliary => qr{[z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y'],
			main => qr{[a á b c d e é f g h i í j k l m n ñ ŋ o ó p q r s t u ú v w x y]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y'], };
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
	default		=> sub { qr'^(?i:Eey|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hani|H|no|n)$' }
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
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###',
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
		'AOA' => {
			display_name => {
				'currency' => q(kwanza yati Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dolaar yati Ostraalia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinaar yati Bahrayn),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(fraaŋ yati Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula yati Boswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dolaar yati Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(fraaŋ yati Kongo),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan yati Siin),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(eskuudo yati Kap Ver),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(fraaŋ yati Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinaar yati Alseri),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(liiverey yati Esípt),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka yati Eritree),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr yati Ecoopi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi yati Gaana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi yati Gambi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(sili yati Giné),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupii yati End),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen yati Sapoŋ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(silliŋ yati Keniya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(fraaŋ yati Komor),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dolaar yati Liberia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinaar yati Libia),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariari yati Madagaskaar),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ugiiya yati Mooritanii \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ugiiya yati Mooritanii),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha yati Malawi),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(seefa BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(seefa yati BCEAO),
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
							'Sa',
							'Fe',
							'Ma',
							'Ab',
							'Me',
							'Su',
							'Sú',
							'Ut',
							'Se',
							'Ok',
							'No',
							'De'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Sanvie',
							'Fébirie',
							'Mars',
							'Aburil',
							'Mee',
							'Sueŋ',
							'Súuyee',
							'Ut',
							'Settembar',
							'Oktobar',
							'Novembar',
							'Disambar'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'S',
							'F',
							'M',
							'A',
							'M',
							'S',
							'S',
							'U',
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
						mon => 'Ten',
						tue => 'Tal',
						wed => 'Ala',
						thu => 'Ara',
						fri => 'Arj',
						sat => 'Sib',
						sun => 'Dim'
					},
					wide => {
						mon => 'Teneŋ',
						tue => 'Talata',
						wed => 'Alarbay',
						thu => 'Aramisay',
						fri => 'Arjuma',
						sat => 'Sibiti',
						sun => 'Dimas'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'T',
						tue => 'T',
						wed => 'A',
						thu => 'A',
						fri => 'A',
						sat => 'S',
						sun => 'D'
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
				'0' => 'ArY',
				'1' => 'AtY'
			},
			wide => {
				'0' => 'Ariŋuu Yeesu',
				'1' => 'Atooŋe Yeesu'
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
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
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
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
