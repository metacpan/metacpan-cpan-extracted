=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Scn - Package for language Sicilian

=cut

package Locale::CLDR::Locales::Scn;
# This file auto generated from Data\common\main\scn.xml
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
				'am' => 'amàricu',
 				'ar' => 'àrabbu',
 				'ast' => 'asturianu',
 				'bg' => 'bùrgaru',
 				'br' => 'brètuni',
 				'ca' => 'catalanu',
 				'ckb' => 'curdu cintrali',
 				'co' => 'corsu',
 				'cs' => 'cecu',
 				'cy' => 'gallisi',
 				'da' => 'danisi',
 				'de' => 'tidiscu',
 				'de_AT' => 'tidiscu austrìacu',
 				'de_CH' => 'tidiscu autu sbìzziru',
 				'el' => 'grecu',
 				'en' => 'ngrisi',
 				'en_AU' => 'ngrisi australianu',
 				'en_CA' => 'ngrisi canadisi',
 				'en_GB' => 'ngridi britànnicu',
 				'en_US' => 'ngrisi miricanu',
 				'eo' => 'spirantu',
 				'es' => 'spagnolu',
 				'es_419' => 'spagnolu dâ mèrica latina',
 				'es_ES' => 'spagnolu eurupeu',
 				'es_MX' => 'spagnolu missicanu',
 				'et' => 'èstuni',
 				'eu' => 'bascu',
 				'fil' => 'filippinu',
 				'fr' => 'francisi',
 				'fr_CA' => 'francisi canadisi',
 				'fr_CH' => 'francisi sbìzziru',
 				'fur' => 'friulanu',
 				'fy' => 'frìsuni uccidintali',
 				'ga' => 'irlannisi',
 				'gl' => 'galizzianu',
 				'gsw' => 'tidiscu sbìzziru',
 				'he' => 'ebbràicu',
 				'hr' => 'cruatu',
 				'hu' => 'unghirisi',
 				'hy' => 'armenu',
 				'ia' => 'ntirlingua',
 				'it' => 'talianu',
 				'ja' => 'giappunisi',
 				'ko' => 'curianu',
 				'ku' => 'curdu',
 				'la' => 'latinu',
 				'lt' => 'lituanu',
 				'lv' => 'lèttuni',
 				'mk' => 'macèduni',
 				'mn' => 'mòngulu',
 				'mt' => 'martisi',
 				'mul' => 'assai lingui',
 				'nb' => 'nurviggisi Bokmål',
 				'nl' => 'ulannisi',
 				'nn' => 'nurviggisi Nynorsk',
 				'pl' => 'pulaccu',
 				'prg' => 'prussianu',
 				'pt' => 'purtughisi',
 				'pt_BR' => 'purtughisi brasilianu',
 				'pt_PT' => 'purtughisi eurupeu',
 				'ro' => 'rumenu',
 				'ro_MD' => 'murdavu',
 				'ru' => 'russu',
 				'sa' => 'sànscritu',
 				'scn' => 'sicilianu',
 				'sk' => 'sluvaccu',
 				'sl' => 'sluvenu',
 				'so' => 'sòmalu',
 				'sq' => 'arbanisi',
 				'sr' => 'serbu',
 				'sv' => 'svidisi',
 				'sw' => 'swahili',
 				'tr' => 'turcu',
 				'und' => 'lingua scanusciuta',
 				'ur' => 'urdu',
 				'uz' => 'uzbeku',
 				'vo' => 'volapük',
 				'yue' => 'cantunisi',
 				'zh' => 'cinisi',
 				'zh_Hant' => 'cinisi tradizziunali',
 				'zu' => 'zulu',
 				'zxx' => 'nuḍḍu cuntinutu linguìsticu',

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
			'Arab' => 'àrabbu',
 			'Aran' => 'nastaliq',
 			'Brai' => 'braille',
 			'Cyrl' => 'cirìllicu',
 			'Grek' => 'grecu',
 			'Hebr' => 'ebbràicu',
 			'Hira' => 'hiragana',
 			'Jpan' => 'giappunisi',
 			'Kana' => 'katakana',
 			'Kore' => 'curianu',
 			'Latn' => 'latinu',
 			'Zmth' => 'nutazziuni matimàtica',
 			'Zsye' => 'emoji',
 			'Zsym' => 'sìmmuli',
 			'Zxxx' => 'nun scrittu',
 			'Zyyy' => 'cumuni',
 			'Zzzz' => 'scrittura scanusciuta',

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
			'001' => 'Munnu',
 			'002' => 'Àfrica',
 			'009' => 'Uciania',
 			'011' => 'Àfrica uccidintali',
 			'013' => 'Mèrica cintrali',
 			'014' => 'Àfrica urintali',
 			'017' => 'Àfrica di menzu',
 			'019' => 'Mèrichi',
 			'030' => 'Asia urintali',
 			'142' => 'Asia',
 			'143' => 'Asia cintrali',
 			'145' => 'Asia uccidintali',
 			'150' => 'Europa',
 			'151' => 'Europa urintali',
 			'155' => 'Europa uccidintali',
 			'419' => 'Mèrica latina',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Arbanìa',
 			'AQ' => 'Antàrtidi',
 			'AR' => 'Argintina',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'BB' => 'Barbados',
 			'BE' => 'Bergiu',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Burgarìa',
 			'BJ' => 'Benin',
 			'BO' => 'Bulivia',
 			'BR' => 'Brasili',
 			'BS' => 'Bahamas',
 			'BZ' => 'Belize',
 			'CH' => 'Sbìzzira',
 			'CL' => 'Cili',
 			'CN' => 'Cina',
 			'CO' => 'Culommia',
 			'CU' => 'Cubba',
 			'CV' => 'Capu Virdi',
 			'CZ' => 'Cechia',
 			'CZ@alt=variant' => 'Ripùbblica Ceca',
 			'DE' => 'Girmania',
 			'DK' => 'Danimarca',
 			'DO' => 'Ripùbblica Duminicana',
 			'EC' => 'Ècuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egittu',
 			'EH' => 'Sahara uccidintali',
 			'ES' => 'Spagna',
 			'EU' => 'Uniuni Eurupea',
 			'EZ' => 'Zuna Euru',
 			'FR' => 'Francia',
 			'GB' => 'Regnu Unitu',
 			'GB@alt=short' => 'RU',
 			'GF' => 'Guiana Francisi',
 			'GH' => 'Ghana',
 			'GR' => 'Grecia',
 			'GY' => 'Guiana',
 			'HN' => 'Honduras',
 			'HR' => 'Cruazzia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarìa',
 			'IC' => 'Ìsuli Canari',
 			'IE' => 'Irlanna',
 			'IN' => 'Ìnnia',
 			'IS' => 'Islanna',
 			'IT' => 'Italia',
 			'JM' => 'Giamàica',
 			'JO' => 'Giurdania',
 			'JP' => 'Giappuni',
 			'KH' => 'Camboggia',
 			'KW' => 'Kuwait',
 			'LB' => 'Lìbbanu',
 			'LI' => 'Liechtenstein',
 			'LR' => 'Libberia',
 			'LT' => 'Lituania',
 			'LU' => 'Lussimmurgu',
 			'LV' => 'Littonia',
 			'LY' => 'Libbia',
 			'MA' => 'Maroccu',
 			'MC' => 'Mònacu',
 			'MD' => 'Murdova',
 			'ML' => 'Mali',
 			'MR' => 'Mauritania',
 			'MT' => 'Marta',
 			'MV' => 'Mardivi',
 			'MX' => 'Mèssicu',
 			'NE' => 'Niger',
 			'NG' => 'Niggeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paisi Vasci',
 			'NO' => 'Nurveggia',
 			'PA' => 'Pànama',
 			'PE' => 'Pirù',
 			'PL' => 'Pulonia',
 			'PT' => 'Purtugallu',
 			'PY' => 'Paraguay',
 			'RO' => 'Rumanìa',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'SE' => 'Sbezzia',
 			'SI' => 'Sluvenia',
 			'SK' => 'Sluvacchia',
 			'SM' => 'San Marinu',
 			'SN' => 'Sènigal',
 			'SV' => 'El Salvador',
 			'TG' => 'Togu',
 			'TN' => 'Tunisìa',
 			'TR' => 'Turchìa',
 			'UN' => 'Nazziuna Uniti',
 			'US' => 'Stati Uniti',
 			'US@alt=short' => 'SUM',
 			'UY' => 'Uruguay',
 			'VA' => 'Città dû Vaticanu',
 			'XA' => 'Accenti fausi',
 			'XB' => 'Bidirizziunali fausu',
 			'XK' => 'Kossovo',
 			'ZZ' => 'Riggiuni scanusciuta',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Calannariu',
 			'ms' => 'Sistema di misura',
 			'numbers' => 'Nùmmari',

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
 				'buddhist' => q{Calannariu buddista},
 				'chinese' => q{Calannariu cinisi},
 				'gregorian' => q{Calannariu grigurianu},
 				'hebrew' => q{Calannariu ebbràicu},
 				'iso8601' => q{Calannariu ISO-8601},
 				'japanese' => q{Calannariu giappunisi},
 			},
 			'ms' => {
 				'metric' => q{Sistema mètricu},
 				'uksystem' => q{Sistema mpiriali},
 				'ussystem' => q{Sistema miricanu},
 			},

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
			auxiliary => qr{[ç đ éë ə ḥ ì k š ù w x y]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'Z'],
			main => qr{[aàâ b c dḍ eèê f g h iíî j l m n oòô p q r s t uúû v z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'Z'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:se|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|no|n)$' }
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

has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'jin',
							'fri',
							'mar',
							'apr',
							'maj',
							'giu',
							'gnt',
							'agu',
							'sit',
							'utt',
							'nuv',
							'dic'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'jinnaru',
							'frivaru',
							'marzu',
							'aprili',
							'maju',
							'giugnu',
							'giugnettu',
							'agustu',
							'sittèmmiru',
							'uttòviru',
							'nuvèmmiru',
							'dicèmmiru'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'G',
							'G',
							'A',
							'S',
							'U',
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
					wide => {
						mon => 'lunnidìa',
						tue => 'martidìa',
						wed => 'mercuridìa',
						thu => 'jovidìa',
						fri => 'vennidìa',
						sat => 'sàbbatu',
						sun => 'dumìnica'
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

no Moo;

1;

# vim: tabstop=4
