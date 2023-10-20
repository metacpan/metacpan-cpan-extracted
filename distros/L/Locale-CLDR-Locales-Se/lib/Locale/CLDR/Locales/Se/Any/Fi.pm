=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Se::Any::Fi - Package for language Northern Sami

=cut

package Locale::CLDR::Locales::Se::Any::Fi;
# This file auto generated from Data\common\main\se_FI.xml
#	on Fri 13 Oct  9:36:50 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Se::Any');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ace' => 'ačehgiella',
 				'ar_001' => 'standárda arábagiella',
 				'be' => 'vilgesruoššagiella',
 				'bn' => 'bengalagiella',
 				'de_AT' => 'nuortariikkalaš duiskkagiella',
 				'de_CH' => 'šveicalaš duiskkagiella',
 				'en_AU' => 'austrálialaš eaŋgalsgiella',
 				'en_CA' => 'kanádalaš eaŋgalsgiella',
 				'en_GB' => 'brihttalaš eaŋgalsgiella',
 				'en_GB@alt=short' => 'brihttalaš eaŋgalsgiella',
 				'en_US' => 'amerihkálaš eaŋgalsgiella',
 				'en_US@alt=short' => 'amerihkálaš eaŋgalsgiella',
 				'es_419' => 'latiinna-amerihkalaš spánskkagiella',
 				'es_ES' => 'espánjalaš spánskkagiella',
 				'es_MX' => 'meksikolaš spánskkagiella',
 				'fj' => 'fižigiella',
 				'fr_CA' => 'kanádalaš fránskkagiella',
 				'fr_CH' => 'šveicalaš fránskkagiella',
 				'hy' => 'armenagiella',
 				'kk' => 'kazakhgiella',
 				'km' => 'kambožagiella',
 				'ne' => 'nepalagiella',
 				'nl_BE' => 'belgialaš hollánddagiella',
 				'pa' => 'panjabagiella',
 				'pt_BR' => 'brasilialaš portugálagiella',
 				'pt_PT' => 'portugálalaš portugálagiella',
 				'ro_MD' => 'moldávialaš romániagiella',
 				'swb' => 'komoragiella',
 				'th' => 'thaigiella',
 				'vi' => 'vietnamagiella',
 				'zh_Hans' => 'álkes kiinnágiella',

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
			'Arab' => 'arábalaš',
 			'Hani' => 'kiinnálaš',
 			'Hans' => 'álkes kiinnálaš',
 			'Hans@alt=stand-alone' => 'álkes kiinnálaš',
 			'Hant' => 'árbevirolaš kiinnálaš',
 			'Hant@alt=stand-alone' => 'árbevirolaš kiinnálaš',
 			'Zxxx' => 'orrut čállojuvvot',
 			'Zzzz' => 'dovdameahttun čállin',

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
			'001' => 'Máilbmi',
 			'002' => 'Afrihka',
 			'003' => 'Davvi-Amerihká ja Gaska-Amerihká',
 			'005' => 'Lulli-Amerihká',
 			'011' => 'Oarje-Afrihká',
 			'013' => 'Gaska-Amerihká',
 			'014' => 'Nuorta-Afrihká',
 			'015' => 'Davvi-Afrihká',
 			'017' => 'Gaska-Afrihká',
 			'018' => 'Lulli-Afrihká',
 			'019' => 'Amerihka',
 			'021' => 'Davvi-Amerihká',
 			'057' => 'Mikronesia guovlu',
 			'419' => 'Latiinnalaš Amerihká',
 			'BA' => 'Bosnia ja Hercegovina',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'EZ' => 'Euroavádat',
 			'KH' => 'Kamboža',
 			'SD' => 'Sudan',
 			'TD' => 'Chad',
 			'UN' => 'Ovttastuvvan Našuvnnat',

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
 				'buddhist' => q{buddhista kaleandar},
 				'chinese' => q{kiinná kaleandar},
 				'coptic' => q{koptalaš kaleandar},
 				'dangi' => q{dangi kaleandar},
 				'ethiopic' => q{etiohpalaš kaleandar},
 				'ethiopic-amete-alem' => q{etiohpalaš-amete-alem kaleandar},
 				'gregorian' => q{gregorialaš kalendar},
 			},
 			'numbers' => {
 				'fullwide' => q{fullwide},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'script' => 'čállin: {0}',

		}
	},
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'other' => '0 duháhat',
					'two' => '0 dt',
				},
				'10000' => {
					'one' => '00 duháhat',
					'two' => '00 dt',
				},
				'100000' => {
					'one' => '000 duháhat',
					'two' => '000 dt',
				},
				'1000000' => {
					'two' => '0 mn',
				},
				'10000000' => {
					'one' => '00 miljonat',
					'two' => '00 mn',
				},
				'100000000' => {
					'one' => '000 miljonat',
					'two' => '000 mn',
				},
				'1000000000' => {
					'one' => '0 miljárda',
					'other' => '0 miljárdat',
					'two' => '0 miljárdat',
				},
				'10000000000' => {
					'one' => '00 miljárdat',
					'other' => '00 miljárdat',
					'two' => '00 md',
				},
				'100000000000' => {
					'one' => '000 miljárdat',
					'other' => '000 miljárdat',
					'two' => '000 md',
				},
				'1000000000000' => {
					'one' => '0 biljovdna',
					'other' => '0 biljovdnat',
					'two' => '0 bn',
				},
				'10000000000000' => {
					'one' => '00 biljovdnat',
					'other' => '00 biljovdnat',
					'two' => '00 bn',
				},
				'100000000000000' => {
					'one' => '000 biljovdnat',
					'other' => '000 biljovdnat',
					'two' => '000 bn',
				},
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
							'',
							'',
							'',
							'cuoŋ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'',
							'',
							'',
							'cuoŋ'
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
						mon => 'má',
						tue => 'di',
						wed => 'ga',
						thu => 'du',
						fri => 'be',
						sat => 'lá',
						sun => 'so'
					},
					narrow => {
						mon => 'M',
						tue => 'D'
					},
					short => {
						mon => 'má',
						tue => 'di',
						wed => 'ga',
						thu => 'du',
						fri => 'be',
						sat => 'lá',
						sun => 'so'
					},
					wide => {
						mon => 'mánnodat',
						tue => 'disdat',
						wed => 'gaskavahkku',
						thu => 'duorastat',
						fri => 'bearjadat',
						sat => 'lávvordat'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'má',
						tue => 'di',
						wed => 'ga',
						thu => 'du',
						fri => 'be',
						sat => 'lá',
						sun => 'so'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'G',
						thu => 'D',
						fri => 'B',
						sat => 'L',
						sun => 'S'
					},
					short => {
						mon => 'má',
						tue => 'di',
						wed => 'ga',
						thu => 'du',
						fri => 'be',
						sat => 'lá',
						sun => 'so'
					},
					wide => {
						mon => 'mánnodat',
						tue => 'disdat',
						thu => 'duorastat',
						sat => 'lávvordat'
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
					abbreviated => {0 => '1Q',
						1 => '2Q',
						2 => '3Q',
						3 => '4Q'
					},
					wide => {0 => '1. njealjádas',
						1 => '2. njealjádas',
						2 => '3. njealjádas',
						3 => '4. njealjádas'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => '2Q',
						2 => '3Q',
						3 => '4Q'
					},
					wide => {0 => '1. njealjádas',
						1 => '2. njealjádas',
						2 => '3. njealjádas',
						3 => '4. njealjádas'
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
					'am' => q{ib},
					'pm' => q{eb},
				},
				'narrow' => {
					'am' => q{i},
					'pm' => q{e},
				},
				'wide' => {
					'am' => q{ib},
					'pm' => q{eb},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ib},
					'pm' => q{eb},
				},
				'narrow' => {
					'am' => q{ib},
					'pm' => q{eb},
				},
				'wide' => {
					'am' => q{ib},
					'pm' => q{eb},
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
				'0' => 'oKr.',
				'1' => 'mKr.'
			},
			wide => {
				'0' => 'ovdal Kristusa',
				'1' => 'maŋŋel Kristusa'
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
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.y},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E d.M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM.y. GGGG},
			yyyyMEd => q{E dd.MM.y GGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd.MM.y GGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{d E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E d.M},
			MMMEd => q{E d MMM},
			MMMMW => q{MMMM':a vahkku' W},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{MM.y},
			yMEd => q{E dd.MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
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
		'generic' => {
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E d.M – E d.M},
				d => q{E d.M – E d.M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M –d.M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M.y – M.y GGGG},
				y => q{M.y – M.y GGGG},
			},
			yMEd => {
				M => q{E d.M.y – E.d.M.y GGGG},
				d => q{E d.M.y – E d.M.y GGGG},
				y => q{E d.M.y – E d.M.y GGGG},
			},
			yMMMEd => {
				M => q{E d MMM y – E d MMM y G},
				d => q{E d MMM y – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d.MMM – d.MMM y G},
				d => q{d–d.MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d.M.y – d.M.y GGGG},
				d => q{d.M.y – d.M.y GGGG},
				y => q{d.M.y – d.M.y GGGG},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d.M.–E d.M.},
				d => q{E d.M.–E.d.M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d.MMM–E d.MMM},
				d => q{E d.MMM–E d.MMM},
			},
			MMMd => {
				M => q{d MMM–d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.M.–d.M.},
			},
			yM => {
				M => q{M.y–M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y},
				d => q{E d.M.y – E d.M.y},
				y => q{E d.M.y – E d.M.y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d.M.y – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q({0} GMT),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} geasseáigi),
		regionFormat => q({0} dálveáigi),
		'Afghanistan' => {
			long => {
				'standard' => q#Afganisthana áigi#,
			},
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Gaska-Afrihká áigi#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Nuorta-Afrihká áigi#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Lulli-Afrihká dálveáigi#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Oarje-Afrihká geasseáigi#,
				'generic' => q#Oarje-Afrihká áigi#,
				'standard' => q#Oarje-Afrihká dálveáigi#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska geasseáigi#,
				'generic' => q#Alaska áigi#,
				'standard' => q#Alaska dálveáigi#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazona geasseáigi#,
				'generic' => q#Amazona áigi#,
				'standard' => q#Amazona dálveáigi#,
			},
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Dánmárkkuhámman#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Davvi-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Guovddáš, Davvi-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Davvi-Dakota#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#dábálaš geasseáigi#,
				'generic' => q#dábálašáigi#,
				'standard' => q#dábálaš dálveáigi#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#geasseáigi nuortan#,
				'generic' => q#áigi nuortan#,
				'standard' => q#dálveáigi nuortan#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#geasseduottaráigi#,
				'generic' => q#duottaráigi#,
				'standard' => q#dálveduottaráigi#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Jaskesábi geasseáigi#,
				'generic' => q#Jaskesábi áigi#,
				'standard' => q#Jaskesábi dálveáigi#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia geasseáigi#,
				'generic' => q#Apia áigi#,
				'standard' => q#Apia dálveáigi#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arábia geasseáigi#,
				'generic' => q#Arábia áigi#,
				'standard' => q#Arábia dálveáigi#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina geasseáigi#,
				'generic' => q#Argentina áigi#,
				'standard' => q#Argentina dálveáigi#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Oarje-Argentina geasseáigi#,
				'generic' => q#Oarje-Argentina áigi#,
				'standard' => q#Oarje-Argentina dálveáigi#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenia geasseáigi#,
				'generic' => q#Armenia áigi#,
				'standard' => q#Armenia dálveáigi#,
			},
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskos#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkuck#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokusneck#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan-Bator#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakuck#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlántalaš geasseáigi#,
				'generic' => q#atlántalaš áigi#,
				'standard' => q#atlántalaš dálveáigi#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorat#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanária#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Lulli-Georgia#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Gaska-Austrália geasseáigi#,
				'generic' => q#Gaska-Austrália áigi#,
				'standard' => q#Gaska-Austrália dálveáigi#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Gaska-Austrália oarjjabeali geasseáigi#,
				'generic' => q#Gaska-Austrália oarjjabeali áigi#,
				'standard' => q#Gaska-Austrália oarjjabeali dálveáigi#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Nuorta-Austrália geasseáigi#,
				'generic' => q#Nuorta-Austrália áigi#,
				'standard' => q#Nuorta-Austrália dálveáigi#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Oarje-Austrália geasseáigi#,
				'generic' => q#Oarje-Austrália áigi#,
				'standard' => q#Oarje-Austrália dálveáigi#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbaižana geasseáigi#,
				'generic' => q#Aserbaižana áigi#,
				'standard' => q#Aserbaižana dálveáigi#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoraid geasseáigi#,
				'generic' => q#Azoraid áigi#,
				'standard' => q#Azoraid dálveáigi#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesha geasseáigi#,
				'generic' => q#Bangladesha áigi#,
				'standard' => q#Bangladesha dálveáigi#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutana áigi#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia áigi#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia geasseáigi#,
				'generic' => q#Brasilia áigi#,
				'standard' => q#Brasilia dálveáigi#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalama áigi#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kap Verde geasseáigi#,
				'generic' => q#Kap Verde áigi#,
				'standard' => q#Kap Verde dálveáigi#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Čamorro dálveáigi#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathama geasseáigi#,
				'generic' => q#Chathama áigi#,
				'standard' => q#Chathama dálveáigi#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chile geasseáigi#,
				'generic' => q#Chile áigi#,
				'standard' => q#Chile dálveáigi#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Kiinná geasseáigi#,
				'generic' => q#Kiinná áigi#,
				'standard' => q#Kiinná dálveáigi#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibolsana geasseáigi#,
				'generic' => q#Choibolsana áigi#,
				'standard' => q#Choibolsana dálveáigi#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Juovlasullo áigi#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokossulloid áigi#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombia geasseáigi#,
				'generic' => q#Colombia áigi#,
				'standard' => q#Colombia dálveáigi#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cooksulloid geasi beallemuttu áigi#,
				'generic' => q#Cooksulloid áigi#,
				'standard' => q#Cooksulloid dálveáigi#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba geasseáigi#,
				'generic' => q#Cuba áigi#,
				'standard' => q#Cuba dálveáigi#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davisa áigi#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville áigi#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Nuorta-Timora áigi#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Beassášsullo geasseáigi#,
				'generic' => q#Beassášsullo áigi#,
				'standard' => q#Beassášsullo dálveáigi#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadora áigi#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinerejuvvon oktasaš áigi#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Dovdameahttun gávpot#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athena#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#København#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irlánddalaš dálveáigi#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsset#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mansuolu#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Brihtalaš geasseáigi#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxenburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsawa#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Gaska-Eurohpá geasseáigi#,
				'generic' => q#Gaska-Eurohpá áigi#,
				'standard' => q#Gaska-Eurohpá dálveáigi#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Nuorta-Eurohpa geasseáigi#,
				'generic' => q#Nuorta-Eurohpa áigi#,
				'standard' => q#Nuorta-Eurohpa dálveáigi#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Gáiddus-Nuortti eurohpalaš áigi#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Oarje-Eurohpá geasseáigi#,
				'generic' => q#Oarje-Eurohpá áigi#,
				'standard' => q#Oarje-Eurohpá dálveáigi#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandsulluid geasseáigi#,
				'generic' => q#Falklandsulluid áigi#,
				'standard' => q#Falklandsulluid dálveáigi#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji geasseáigi#,
				'generic' => q#Fiji áigi#,
				'standard' => q#Fiji dálveáigi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Frankriikka Guyana áigi#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Frankriikka lulli & antárktisa áigi#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwicha áigi#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagosa áigi#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambiera áigi#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia geasseáigi#,
				'generic' => q#Georgia áigi#,
				'standard' => q#Georgia dálveáigi#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbertsulloid áigi#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Nuorta-Ruonáeatnama geasseáigi#,
				'generic' => q#Nuorta-Ruonáeatnama áigi#,
				'standard' => q#Nuorta-Ruonáeatnama dálveáigi#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Oarje-Ruonáeatnama geasseáigi#,
				'generic' => q#Oarje-Ruonáeatnama áigi#,
				'standard' => q#Oarje-Ruonáeatnama dálveáigi#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golfa dálveáigi#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana áigi#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-aleuhtalaš geasseáigi#,
				'generic' => q#Hawaii-aleuhtalaš áigi#,
				'standard' => q#Hawaii-aleuhtalaš dálveáigi#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Konga geasseáigi#,
				'generic' => q#Hong Konga áigi#,
				'standard' => q#Hong Konga dálveáigi#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovda geasseáigi#,
				'generic' => q#Hovda áigi#,
				'standard' => q#Hovda dálveáigi#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India dálveáigi#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Juovlasuolu#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediivvat#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiaábi áigi#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indokiinná áigi#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Gaska-Indonesia áigi#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Nuorta-Indonesia áigi#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Oarje-Indonesia áigi#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Irana geasseáigi#,
				'generic' => q#Irana áigi#,
				'standard' => q#Irana dálveáigi#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkucka geasseáigi#,
				'generic' => q#Irkucka áigi#,
				'standard' => q#Irkucka dálveáigi#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israela geasseáigi#,
				'generic' => q#Israela áigi#,
				'standard' => q#Israela dálveáigi#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japána geasseáigi#,
				'generic' => q#Japána áigi#,
				'standard' => q#Japána dálveáigi#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Nuorta-Kasakstana áigi#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Oarje-Kasakstana áigi#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korea geasseáigi#,
				'generic' => q#Korea áigi#,
				'standard' => q#Korea dálveáigi#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraea áigi#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarska geasseáigi#,
				'generic' => q#Krasnojarska áigi#,
				'standard' => q#Krasnojarska dálveáigi#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisia áigi#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Linesulloid áigi#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe geasseáigi#,
				'generic' => q#Lord Howe áigi#,
				'standard' => q#Lord Howe dálveáigi#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#MacQuarie sullo áigi#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadana geasseáigi#,
				'generic' => q#Magadana áigi#,
				'standard' => q#Magadana dálveáigi#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malesia áigi#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediivvaid áigi#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesasiid áigi#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshallsulloid áigi#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritiusa geasseáigi#,
				'generic' => q#Mauritiusa áigi#,
				'standard' => q#Mauritiusa dálveáigi#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsona áigi#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Oarjedavvi-Meksiko geasseáigi#,
				'generic' => q#Oarjedavvi-Meksiko áigi#,
				'standard' => q#Oarjedavvi-Meksiko dálveáigi#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksiko Jáskesábi geasseáigi#,
				'generic' => q#Meksiko Jáskesábi áigi#,
				'standard' => q#Meksiko Jáskesábi dálveáigi#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan-Batora geasseáigi#,
				'generic' => q#Ulan-Batora áigi#,
				'standard' => q#Ulan-Batora dálveáigi#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva geasseáigi#,
				'generic' => q#Moskva áigi#,
				'standard' => q#Moskva dálveáigi#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmara áigi#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru áigi#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepala áigi#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ođđa-Kaledonia geasseáigi#,
				'generic' => q#Ođđa-Kaledonia áigi#,
				'standard' => q#Ođđa-Kaledonia dálveáigi#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ođđa-Selánda geasseáigi#,
				'generic' => q#Ođđa-Selánda áigi#,
				'standard' => q#Ođđa-Selánda dálveáigi#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundlanda geasseáigi#,
				'generic' => q#Newfoundlanda áigi#,
				'standard' => q#Newfoundlanda dálveáigi#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuea áigi#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolksullo áigi#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha geasseáigi#,
				'generic' => q#Fernando de Noronha áigi#,
				'standard' => q#Fernando de Noronha dálveáigi#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirska geasseáigi#,
				'generic' => q#Novosibirska áigi#,
				'standard' => q#Novosibirska dálveáigi#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omska geasseáigi#,
				'generic' => q#Omska áigi#,
				'standard' => q#Omska dálveáigi#,
			},
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesasat#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistana geasseáigi#,
				'generic' => q#Pakistana áigi#,
				'standard' => q#Pakistana dálveáigi#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palaua áigi#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Ođđa-Guinea áigi#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguaya geasseáigi#,
				'generic' => q#Paraguaya áigi#,
				'standard' => q#Paraguaya dálveáigi#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru geasseáigi#,
				'generic' => q#Peru áigi#,
				'standard' => q#Peru dálveáigi#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippiinnaid geasseáigi#,
				'generic' => q#Filippiinnaid áigi#,
				'standard' => q#Filippiinnaid dálveáigi#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixsulloid áigi#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelo geasseáigi#,
				'generic' => q#St. Pierre & Miquelo áigi#,
				'standard' => q#St. Pierre & Miquelo dálveáigi#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairnsulloid áigi#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape áigi#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyanga áigi#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reuniona áigi#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera áigi#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalina geasseáigi#,
				'generic' => q#Sahalina áigi#,
				'standard' => q#Sahalina dálveáigi#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa geasseáigi#,
				'generic' => q#Samoa áigi#,
				'standard' => q#Samoa dálveáigi#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychellaid áigi#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapore dálveáigi#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonsulloid áigi#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Lulli-Georgia áigi#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname áigi#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa áigi#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti áigi#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipeia geasseáigi#,
				'generic' => q#Taipeia áigi#,
				'standard' => q#Taipeia dálveáigi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tažikistana áigi#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelaua áigi#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga geasseáigi#,
				'generic' => q#Tonga áigi#,
				'standard' => q#Tonga dálveáigi#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuka áigi#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistana geasseáigi#,
				'generic' => q#Turkmenistana áigi#,
				'standard' => q#Turkmenistana dálveáigi#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu áigi#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguaya geasseáigi#,
				'generic' => q#Uruguaya áigi#,
				'standard' => q#Uruguaya dálveáigi#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekistana geasseáigi#,
				'generic' => q#Usbekistana áigi#,
				'standard' => q#Usbekistana dálveáigi#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu geasseáigi#,
				'generic' => q#Vanuatu áigi#,
				'standard' => q#Vanuatu dálveáigi#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela áigi#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostoka geasseáigi#,
				'generic' => q#Vladivostoka áigi#,
				'standard' => q#Vladivostoka dálveáigi#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograda geasseáigi#,
				'generic' => q#Volgograda áigi#,
				'standard' => q#Volgograda dálveáigi#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostoka áigi#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wakesullo áigi#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis- ja Futuna áigi#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakucka geasseáigi#,
				'generic' => q#Jakucka áigi#,
				'standard' => q#Jakucka dálveáigi#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburga geasseáigi#,
				'generic' => q#Jekaterinburga áigi#,
				'standard' => q#Jekaterinburga dálveáigi#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
