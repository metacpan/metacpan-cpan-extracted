=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mdf - Package for language Moksha

=cut

package Locale::CLDR::Locales::Mdf;
# This file auto generated from Data\common\main\mdf.xml
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
				'de' => 'Саксонь кяль',
 				'en' => 'Англань кяль',
 				'es' => 'Испаниянь кяль',
 				'fr' => 'Кранциянь кяль',
 				'it' => 'Италиянь кяль',
 				'ja' => 'Япононь кяль',
 				'mdf' => 'мокшень кяль',
 				'pl' => 'Поляконь кяль',
 				'pt' => 'Португалонь кяль',
 				'ru' => 'Рузонь кяль',
 				'tr' => 'Туркань кяль',

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
			'Cyrl' => 'Кириллица',
 			'Latn' => 'Латиница',

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
			'001' => 'масторланга',
 			'002' => 'Африкась',
 			'003' => 'Кельмеширень Америкась',
 			'005' => 'Лямбеширень Америкась',
 			'013' => 'Кучкань Америкась',
 			'017' => 'Кучкань Африкась',
 			'019' => 'Америкась',
 			'142' => 'Азиясь',
 			'150' => 'Европась',
 			'AR' => 'Аргентина',
 			'BM' => 'Бермуда',
 			'BO' => 'Боливия',
 			'BR' => 'Бразилия',
 			'CA' => 'Канада',
 			'CL' => 'Чили',
 			'CO' => 'Колумбия',
 			'CU' => 'Куба',
 			'DZ' => 'Алжир',
 			'EG' => 'Египет',
 			'EU' => 'Эуропонь соткс',
 			'GD' => 'Гренада',
 			'GL' => 'Гренландия',
 			'MX' => 'Мексика',
 			'NI' => 'Никарагуа',
 			'PA' => 'Панама',
 			'PE' => 'Перу',

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
			auxiliary => qr{[ӓ ә є җ ѕ і ԕ ҥ ԗ ў ѡ џ ѣ ԙ ѳ ѵѷ]},
			index => ['А', 'Б', 'В', 'Г', 'Д', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'],
			main => qr{[а б в г д её ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[, ; ! ? .]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Д', 'ЕЁ', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'], };
},
);


has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'RUB' => {
			symbol => '₽',
		},
	} },
);


no Moo;

1;

# vim: tabstop=4
