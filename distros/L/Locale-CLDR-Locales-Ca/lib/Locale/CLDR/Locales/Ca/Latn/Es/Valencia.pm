=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ca::Latn::Es::Valencia - Package for language Catalan

=cut

package Locale::CLDR::Locales::Ca::Latn::Es::Valencia;
# This file auto generated from Data\common\main\ca_ES_VALENCIA.xml
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

extends('Locale::CLDR::Locales::Ca::Latn::Es');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'an' => 'aragonés',
 				'ang' => 'anglés antic',
 				'as' => 'assamés',
 				'az' => 'azerbaidjanés',
 				'ban' => 'balinés',
 				'bar' => 'bavarés',
 				'ce' => 'txetxé',
 				'cy' => 'gal·lés',
 				'da' => 'danés',
 				'dum' => 'neerlandés mitjà',
 				'en' => 'anglés',
 				'en_AU' => 'anglés australià',
 				'en_CA' => 'anglés canadenc',
 				'en_GB' => 'anglés britànic',
 				'en_GB@alt=short' => 'anglés (GB)',
 				'en_US' => 'anglés americà',
 				'en_US@alt=short' => 'anglés (EUA)',
 				'enm' => 'anglés mitjà',
 				'fi' => 'finés',
 				'fo' => 'feroés',
 				'fr' => 'francés',
 				'fr_CA' => 'francés canadenc',
 				'fr_CH' => 'francés suís',
 				'frc' => 'francés cajun',
 				'frm' => 'francés mitjà',
 				'fro' => 'francés antic',
 				'ga' => 'irlandés',
 				'gd' => 'gaèlic escocés',
 				'gil' => 'gilbertés',
 				'hu' => 'hongarés',
 				'is' => 'islandés',
 				'ja' => 'japonés',
 				'jv' => 'javanés',
 				'kho' => 'khotanés',
 				'kl' => 'grenlandés',
 				'lb' => 'luxemburgués',
 				'li' => 'limburgués',
 				'mad' => 'madurés',
 				'mga' => 'gaèlic irlandés mitjà',
 				'mh' => 'marshallés',
 				'mt' => 'maltés',
 				'mwl' => 'mirandés',
 				'ne' => 'nepalés',
 				'nl' => 'neerlandés',
 				'pl' => 'polonés',
 				'pt' => 'portugués',
 				'pt_BR' => 'portugués del Brasil',
 				'pt_PT' => 'portugués de Portugal',
 				'ro' => 'romanés',
 				'rup' => 'aromanés',
 				'rw' => 'ruandés',
 				'sco' => 'escocés',
 				'sga' => 'irlandés antic',
 				'si' => 'singalés',
 				'sl' => 'eslové',
 				'sq' => 'albanés',
 				'su' => 'sundanés',
 				'th' => 'tailandés',
 				'tkl' => 'tokelaués',
 				'to' => 'tongalés',
 				'uk' => 'ucraïnés',
 				'yue' => 'cantonés',
 				'yue@alt=menu' => 'xinés, cantonés',
 				'zh' => 'xinés',
 				'zh@alt=menu' => 'xinés, mandarí',
 				'zh_Hans' => 'xinés simplificat',
 				'zh_Hans@alt=long' => 'xinés mandarí (simplificat)',
 				'zh_Hant' => 'xinés tradicional',
 				'zh_Hant@alt=long' => 'xinés mandarí (tradicional)',

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
			'Aghb' => 'albanés caucàsic',
 			'Bali' => 'balinés',
 			'Bugi' => 'buginés',
 			'Hung' => 'hongarés antic',
 			'Java' => 'javanés',
 			'Jpan' => 'japonés',
 			'Palm' => 'palmiré',
 			'Sinh' => 'singalés',
 			'Sund' => 'sundanés',
 			'Thai' => 'tailandés',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'chinese' => q{calendari xinés},
 				'japanese' => q{calendari japonés},
 			},
 			'collation' => {
 				'big5han' => q{ordre del xinés tradicional - Big5},
 				'gb2312han' => q{ordre del xinés simplificat - GB2312},
 			},

		}
	},
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AFA' => {
			display_name => {
				'currency' => q(afgani afganés \(1927–2002\)),
				'one' => q(afgani afganés \(1927–2002\)),
				'other' => q(afganis afganesos \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani afganés),
				'one' => q(afgani afganés),
				'other' => q(afganis afganesos),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albanés \(1946–1965\)),
				'one' => q(lek albanés \(1946–1965\)),
				'other' => q(lekë albanesos \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albanés),
				'one' => q(lek albanés),
				'other' => q(lekë albanesos),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolés),
				'one' => q(kwanza angolés),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolés \(1977–1991\)),
				'one' => q(kwanza angolés \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nou kwanza angolés \(1990–2000\)),
				'one' => q(nou kwanza angolés \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza angolés reajustat \(1995–1999\)),
				'one' => q(kwanza angolés reajustat \(1995–1999\)),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azerbaidjanés \(1993–2006\)),
				'one' => q(manat azerbaidjanés \(1993–2006\)),
				'other' => q(manats azerbaidjanesos \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azerbaidjanés),
				'one' => q(manat azerbaidjanés),
				'other' => q(manats azerbaidjanesos),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolés),
				'one' => q(franc congolés),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(escut xilé),
				'one' => q(escut xilé),
				'other' => q(escudos xilens),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso xilé),
				'one' => q(peso xilé),
				'other' => q(pesos xilens),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(iuan xinés extracontinental),
				'one' => q(iuan xinés extracontinental),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(dòlar del Banc Popular Xinés),
				'one' => q(dòlar del Banc Popular Xinés),
				'other' => q(dòlars del Banc Popular Xinés),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(iuan xinés),
				'one' => q(iuan xinés),
				'other' => q(iuan xinesos),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(marc finlandés),
				'one' => q(marc finlandés),
				'other' => q(marcs finlandesos),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franc francés),
				'one' => q(franc francés),
				'other' => q(francs francesos),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ghanés \(1979–2007\)),
				'one' => q(cedi ghanés \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanés),
				'one' => q(cedi ghanés),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(fòrint hongarés),
				'one' => q(fòrint hongarés),
				'other' => q(fòrints hongaresos),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ien japonés),
				'one' => q(ien japonés),
				'other' => q(iens japonesos),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franc convertible luxemburgués),
				'one' => q(franc convertible luxemburgués),
				'other' => q(francs convertibles luxemburguesos),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franc luxemburgués),
				'one' => q(franc luxemburgués),
				'other' => q(francs luxemburguesos),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franc financer luxemburgués),
				'one' => q(franc financer luxemburgués),
				'other' => q(francs financers luxemburguesos),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escut moçambiqués),
				'one' => q(escut moçambiqués),
				'other' => q(escuts moçambiquesos),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(antic metical moçambiqués),
				'one' => q(antic metical moçambiqués),
				'other' => q(antics meticals moçambiquesos),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical moçambiqués),
				'one' => q(metical moçambiqués),
				'other' => q(meticals moçambiquesos),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(florí neerlandés),
				'one' => q(florí neerlandés),
				'other' => q(florins neerlandesos),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dòlar neozelandés),
				'one' => q(dòlar neozelandés),
				'other' => q(dòlars neozelandesos),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polonés),
				'one' => q(zloty polonés),
				'other' => q(zlote polonesos),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty polonés \(1950–1995\)),
				'one' => q(zloty polonés \(1950–1995\)),
				'other' => q(zlote polonesos \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escut portugués),
				'one' => q(escut portugués),
				'other' => q(escuts portuguesos),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(antic leu romanés),
				'one' => q(antic leu romanés),
				'other' => q(antics lei romanesos),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu romanés),
				'one' => q(leu romanés),
				'other' => q(lei romanesos),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franc rwandés),
				'one' => q(franc rwandés),
				'other' => q(francs de Ruanda),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanés),
				'one' => q(dinar sudanés),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar eslové),
				'one' => q(tolar eslové),
				'other' => q(tolars eslovens),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandés),
				'one' => q(baht tailandés),
				'other' => q(bahts tailandesos),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbóvanets ucraïnés),
				'one' => q(karbóvanets ucraïnés),
				'other' => q(karbóvantsiv ucraïnesos),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(xíling ugandés \(1966–1987\)),
				'one' => q(xíling ugandés \(1966–1987\)),
				'other' => q(xílings ugandesos \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(xíling ugandés),
				'one' => q(xíling ugandés),
				'other' => q(xílings ugandesos),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franc or francés),
				'one' => q(franc or francés),
				'other' => q(francs or francesos),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franc UIC francés),
				'one' => q(franc UIC francés),
				'other' => q(francs UIC francesos),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nou zaire zairés),
				'one' => q(nou zaire zairés),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire zairés),
				'one' => q(zaire zairés),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dòlar zimbabués \(1980–2008\)),
				'one' => q(dòlar zimbabués \(1980–2008\)),
				'other' => q(dòlars zimbabuesos \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dòlar zimbabués \(2009\)),
				'one' => q(dòlar zimbabués \(2009\)),
				'other' => q(dòlars zimbabuesos \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dòlar zimbabués \(2008\)),
				'one' => q(dòlar zimbabués \(2008\)),
				'other' => q(dòlars zimbabuesos \(2008\)),
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
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
					'afternoon2' => q{vesprada},
				},
				'narrow' => {
					'afternoon2' => q{vesprada},
				},
				'wide' => {
					'afternoon2' => q{vesprada},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'afternoon2' => q{vesprada},
				},
				'wide' => {
					'afternoon2' => q{vesprada},
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
