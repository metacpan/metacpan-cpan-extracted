=head1

Locale::CLDR::Locales::Se::Any::Fi - Package for language Northern Sami

=cut

package Locale::CLDR::Locales::Se::Any::Fi;
# This file auto generated from Data\common\main\se_FI.xml
#	on Fri 29 Apr  7:23:58 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
			'003' => 'Davvi-Amerihkká ja Gaska-Amerihkká',
 			'005' => 'Lulli-Amerihkká',
 			'013' => 'Gaska-Amerihkká',
 			'021' => 'Davvi-Amerihkká',
 			'419' => 'Latiinnalaš-Amerihkká',
 			'BA' => 'Bosnia ja Hercegovina',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'KH' => 'Kamboža',
 			'SD' => 'Sudan',
 			'TD' => 'Chad',

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

has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'ođđajage',
							'guovva',
							'njukča',
							'cuoŋo',
							'miesse',
							'geasse',
							'suoidne',
							'borge',
							'čakča',
							'golggot',
							'skábma',
							'juovla'
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
					wide => {
						mon => 'måanta',
						tue => 'däjsta',
						wed => 'gaskevahkoe',
						thu => 'dåarsta',
						fri => 'bearjadahke',
						sat => 'laavadahke',
						sun => 'aejlege'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'G',
						thu => 'D',
						fri => 'B',
						sat => 'L',
						sun => 'S'
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
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
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
		gmtZeroFormat => q(GMT),
	 } }
);
no Moo;

1;

# vim: tabstop=4
