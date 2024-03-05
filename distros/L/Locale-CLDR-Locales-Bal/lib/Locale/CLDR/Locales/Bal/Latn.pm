=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bal::Latn - Package for language Baluchi

=cut

package Locale::CLDR::Locales::Bal::Latn;
# This file auto generated from Data\common\main\bal_Latn.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'bal' => 'بلۆچی',
 				'bal_Latn' => 'Balóchi',
 				'de' => 'Jarman',
 				'de_AT' => 'Ástriái Jarman',
 				'de_CH' => 'Swizi Jarman',
 				'en' => 'Engrézi',
 				'en_AU' => 'Ástréliái Engrézi',
 				'en_CA' => 'Kaynadhái Engrézi',
 				'en_GB' => 'Bartániái Engrézi',
 				'en_US' => 'Amriki Engrézi',
 				'es' => 'Espini',
 				'es_419' => 'Zerbári-Amriki Espini',
 				'es_ES' => 'Espini (Espin)',
 				'es_MX' => 'Meksiki Espini',
 				'fr' => 'Paránsi',
 				'fr_CA' => 'Kaynadhái Paránsi',
 				'fr_CH' => 'Swizi Paránsi',
 				'it' => 'Itáliái',
 				'ja' => 'Jápáni',
 				'pt' => 'Portagáli',
 				'pt_BR' => 'Brázili Portagáli',
 				'pt_PT' => 'Yuropi Portagáli',
 				'ru' => 'Rusi',
 				'und' => 'Nagisshetagén zobán',
 				'zh' => 'Chini',
 				'zh_Hans' => 'Sádah kortagén Chini',
 				'zh_Hant' => 'Rabyati Chini',

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
			'Arab' => 'Arabi',
 			'Cyrl' => 'Rusi',
 			'Hans' => 'Hán (sádah kortagén)',
 			'Hant' => 'Hán (asligén)',
 			'Latn' => 'Látin',
 			'Zxxx' => 'Nebeshtah nabutagén syáhag',
 			'Zzzz' => 'Kódh nakortagén syáhag',

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
			'BR' => 'Brázil',
 			'CN' => 'Chin',
 			'DE' => 'Jarmani',
 			'FR' => 'Paráns',
 			'GB' => 'Bartániá',
 			'IN' => 'Hendostán',
 			'IT' => 'Itáliá',
 			'JP' => 'Jápán',
 			'PK' => 'Pákestán',
 			'RU' => 'Rus',
 			'US' => 'Amrikáay Tepákén Están',
 			'ZZ' => 'Nagisshetagén damag',

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
 				'buddhist' => q{Buddái sáldar},
 				'chinese' => q{Chini sáldar},
 				'coptic' => q{Kobti sáldar},
 				'dangi' => q{Dángi sáldar},
 				'ethiopic' => q{Etupiái sáldar},
 				'ethiopic-amete-alem' => q{Etupiái Ámet Álem sáldar},
 				'gregorian' => q{Miládi sáldar},
 				'hebrew' => q{Ebráni sáldar},
 				'indian' => q{Hendi Kawmi sáldar},
 				'islamic' => q{Eslámi sáldar},
 				'islamic-civil' => q{Eslámi shahri sáldar},
 				'islamic-rgsa' => q{Eslámi Saudi-Arabi sáldar},
 				'islamic-tbla' => q{Eslámi Nojumi sáldar},
 				'islamic-umalqura' => q{Eslámi Omm al-Korrahi sáldar},
 				'iso8601' => q{ISO-8601 sáldar},
 				'japanese' => q{Jápáni sáldar},
 				'persian' => q{Pársi sáldar},
 				'roc' => q{Mingu-Chini sáldar},
 			},
 			'cf' => {
 				'standard' => q{Zarray anjárén káleb},
 			},
 			'collation' => {
 				'standard' => q{Gisshetagén red o band},
 			},
 			'numbers' => {
 				'arab' => q{Arabi-Hendi mórdán},
 				'cyrl' => q{Rusi mórdán},
 				'deva' => q{Dénágari mórdán},
 				'latn' => q{Rónendi mórdán},
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
			'metric' => q{mitari},
 			'UK' => q{Bartáni},
 			'US' => q{Amriki},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'zobán: {0}',
 			'script' => 'syáhag: {0}',
 			'region' => 'damag: {0}',

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
			auxiliary => qr{[f ń q x]},
			index => ['Á', 'A', 'B', '{Ch}', 'D', '{Dh}', 'É', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ó', 'O', 'P', 'R', '{Rh}', 'S', '{Sh}', 'T', '{Th}', 'U', 'V', 'W', 'Y', 'Z', '{Zh}'],
			main => qr{[á a b c d é e g h i j k l m n ó o p r s t u v w y z]},
			punctuation => qr{[, ; \: ? . ‘’ “”]},
		};
	},
EOT
: sub {
		return { index => ['Á', 'A', 'B', '{Ch}', 'D', '{Dh}', 'É', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ó', 'O', 'P', 'R', '{Rh}', 'S', '{Sh}', 'T', '{Th}', 'U', 'V', 'W', 'Y', 'Z', '{Zh}'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:haw|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:na|n)$' }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(Brázili riál),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(yuró),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Bartáni pawndh),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Hendostáni rupi),
			},
		},
		'IRR' => {
			symbol => 'ریال',
			display_name => {
				'currency' => q(Éráni ryál),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Jápáni yen),
			},
		},
		'PKR' => {
			symbol => 'Rs',
			display_name => {
				'currency' => q(Pákestáni rupi),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(Rusi rubel),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Amriki dhálar),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Nazántagén zarr),
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
							'Jan',
							'Par',
							'Már',
							'Apr',
							'Mai',
							'Jun',
							'Jól',
							'Aga',
							'Sat',
							'Akt',
							'Naw',
							'Das'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janwari',
							'Parwari',
							'Márch',
							'Aprél',
							'Mai',
							'Jun',
							'Jólái',
							'Agast',
							'Satambar',
							'Aktubar',
							'Nawambar',
							'Dasambar'
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
						mon => 'Do',
						tue => 'Say',
						wed => 'Chá',
						thu => 'Pan',
						fri => 'Jom',
						sat => 'Sha',
						sun => 'Yak'
					},
					wide => {
						mon => 'Doshambeh',
						tue => 'Sayshambeh',
						wed => 'Chárshambeh',
						thu => 'Panchshambeh',
						fri => 'Jomah',
						sat => 'Shambeh',
						sun => 'Yakshambeh'
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
					abbreviated => {0 => '1/4',
						1 => '2/4',
						2 => '3/4',
						3 => '4/4'
					},
					wide => {0 => 'awali chárek',
						1 => 'domi chárek',
						2 => 'sayomi chárek',
						3 => 'cháromi chárek'
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
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'full' => q{hh:mm:ss a zzzz},
			'long' => q{hh:mm:ss a zzz},
			'medium' => q{hh:mm:ss a},
			'short' => q{hh:mm a},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'Alaska' => {
			long => {
				'daylight' => q#Aláskáay garmági wahd#,
				'generic' => q#Aláskáay wahd#,
				'standard' => q#Aláskáay anjári wahd#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amázónay garmági wahd#,
				'generic' => q#Amázónay wahd#,
				'standard' => q#Amázónay anjári wahd#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#Delgáhi Amrikáay garmági wahd#,
				'generic' => q#Delgáhi Amrikáay wahd#,
				'standard' => q#Delgáhi Amrikáay anjári wahd#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Amrikáay garmági wahd#,
				'generic' => q#Ródarátki Amrikáay wahd#,
				'standard' => q#Ródarátki Amrikáay anjári wahd#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Kóhestagi Amrikáay garmági wahd#,
				'generic' => q#Kóhestagi Amrikáay wahd#,
				'standard' => q#Kóhestagi Amrikáay anjári wahd#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Árámzeri Amrikáay garmági wahd#,
				'generic' => q#Árámzeri Amrikáay wahd#,
				'standard' => q#Árámzeri Amrikáay anjári wahd#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Arjentináay garmági wahd#,
				'generic' => q#Arjentináay wahd#,
				'standard' => q#Arjentináay anjári wahd#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Rónendi Arjentináay gramági wahd#,
				'generic' => q#Rónendi Arjentináay wahd#,
				'standard' => q#Rónendi Arjentináay anjári wahd#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Delgáhi Ástréliáay garmági wahd#,
				'generic' => q#Delgáhi Ástréliáay wahd#,
				'standard' => q#Delgáhi Ástréliáay anjári wahd#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Delgáhirónendi Ástréliáay garmági wahd#,
				'generic' => q#Delgáhirónendi Ástréliáay wahd#,
				'standard' => q#Delgáhirónendi Ástréliáay anjári wahd#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Ástréliáay garmági wahd#,
				'generic' => q#Ródarátki Ástréliáay wahd#,
				'standard' => q#Ródarátki Ástréliáay anjári wahd#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Rónendi Ástréliáay garmági wahd#,
				'generic' => q#Rónendi Ástréliáay wahd#,
				'standard' => q#Rónendi Ástréliáay anjári wahd#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brázilay garmági wahd#,
				'generic' => q#Brázilay wahd#,
				'standard' => q#Brázilay anjári wahd#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Delgáhi Yuropay garmági wahd#,
				'generic' => q#Delgáhi Yuropay wahd#,
				'standard' => q#Delgáhi Yuropay anjári wahd#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ródarátki Yuropay garmági wahd#,
				'generic' => q#Ródarátki Yuropay wahd#,
				'standard' => q#Ródarátki Yuropay anjári wahd#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Démterén Ródarátki Yuropay anjári wahd#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Rónendi Yuropay garmági wahd#,
				'generic' => q#Rónendi Yuropay wahd#,
				'standard' => q#Rónendi Yuropay anjári wahd#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawái/Alushiay garmági wahd#,
				'generic' => q#Hawái/Alushiay wahd#,
				'standard' => q#Hawái/Alushiay anjári wahd#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Delgáhi Endhonishiáay anjári wahd#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ródarátki Endhonishiáay anjári wahd#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Rónendi Endhonishiáay anjári wahd#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Erkuskay garmági wahd#,
				'generic' => q#Erkuskay wahd#,
				'standard' => q#Erkuskay anjári wahd#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ródarátki Kázekestánay anjári wahd#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Rónendi Kázekestánay anjári wahd#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnóyáskay garmági wahd#,
				'generic' => q#Krasnóyáskay wahd#,
				'standard' => q#Krasnóyáskay anjári wahd#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ástréliáay, Ládhaway garmági wahd#,
				'generic' => q#Ástréliáay, Ládhaway wahd#,
				'standard' => q#Ástréliáay, Ládhaway anjári wahd#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Makwáriay anjári wahd#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Mágadánay garmági wahd#,
				'generic' => q#Mágadánay wahd#,
				'standard' => q#Mágadánay anjári wahd#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Shemálrónendi Meksikóay garmági wahd#,
				'generic' => q#Shemálrónendi Meksikóay wahd#,
				'standard' => q#Górichánrónendi Meksikóay anjári wahd#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Árámzeri Meksikóay garmági wahd#,
				'generic' => q#Árámzeri Meksikóay wahd#,
				'standard' => q#Árámzeri Meksikóay anjári wahd#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Máskóay garmági wahd#,
				'generic' => q#Máskóay wahd#,
				'standard' => q#Máskóay anjári wahd#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nipándlaynday garmági wahd#,
				'generic' => q#Nipándlaynday wahd#,
				'standard' => q#Nipándlaynday anjári wahd#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Noronáay garmági wahd#,
				'generic' => q#Noronáay wahd#,
				'standard' => q#Noronáay anjári wahd#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nawásibiskay garmági wahd#,
				'generic' => q#Nawásibiskay wahd#,
				'standard' => q#Nawásibiskay anjári wahd#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ómskay garmági wahd#,
				'generic' => q#Ómskay wahd#,
				'standard' => q#Ómskay anjári wahd#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waládiwástókay garmági wahd#,
				'generic' => q#Waládiwástókay wahd#,
				'standard' => q#Waládiwástókay anjári wahd#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yákuskay garmági wahd#,
				'generic' => q#Yákuskay wahd#,
				'standard' => q#Yákuskay anjári wahd#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yakátrinborgay garmági wahd#,
				'generic' => q#Yakátrinborgay wahd#,
				'standard' => q#Yakátrinborgay anjári wahd#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
