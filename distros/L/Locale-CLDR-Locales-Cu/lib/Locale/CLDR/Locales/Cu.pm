=head1

Locale::CLDR::Locales::Cu - Package for language Church Slavic

=cut

package Locale::CLDR::Locales::Cu;
# This file auto generated from Data\common\main\cu.xml
#	on Fri 13 Apr  7:05:38 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
				'ab' => 'а҆бха́зскїй',
 				'ar' => 'а҆ра́вскїй',
 				'az' => 'а҆зербайджа́нскїй',
 				'be' => 'бѣлорꙋ́сскїй',
 				'bg' => 'бо́лгарскїй',
 				'cu' => 'церковнослове́нскїй',
 				'de' => 'нѣме́цкїй',
 				'de_AT' => 'а҆ѵстрі́йскїй нѣме́цкїй',
 				'de_CH' => 'є҆лветі́йскїй нѣме́цкїй',
 				'el' => 'є҆́ллинскїй',
 				'en' => 'а҆нглі́йскїй',
 				'en_AU' => 'а҆ѵстралі́йскїй а҆нглі́йскїй',
 				'en_CA' => 'кана́дскїй а҆нглі́йскїй',
 				'en_GB' => 'брїта́нскїй а҆нглі́йскїй',
 				'en_GB@alt=short' => 'а҆нглі́йскїй (вели́каѧ брїта́нїа)',
 				'en_US' => 'а҆мерїка́нскїй а҆нглі́йскїй',
 				'en_US@alt=short' => 'а҆нглі́йскїй (асд)',
 				'es' => 'і҆спа́нскїй',
 				'es_419' => 'латїноамерїка́нскїй і҆спа́нскїй',
 				'es_ES' => 'є҆ѵрѡпе́йскїй і҆спа́нскїй',
 				'es_MX' => 'і҆спанскїй (ме́ѯїка)',
 				'et' => 'є҆сто́нскїй',
 				'fi' => 'фі́нскїй',
 				'fr' => 'францꙋ́зскїй',
 				'fr_CA' => 'кана́дскїй францꙋ́зскїй',
 				'fr_CH' => 'є҆лветі́йскїй францꙋ́зскїй',
 				'he' => 'є҆вре́йскїй',
 				'hy' => 'а҆рме́нскїй',
 				'it' => 'і҆талїа́нскїй',
 				'ja' => 'ꙗ҆пѡ́нскїй',
 				'ka' => 'і҆́верскїй',
 				'kk' => 'каза́хскїй',
 				'la' => 'латі́нскїй',
 				'lt' => 'лїто́вскїй',
 				'lv' => 'латві́йскїй',
 				'pt' => 'портога́льскїй',
 				'pt_BR' => 'бразі́льскїй портога́льскїй',
 				'pt_PT' => 'є҆ѵрѡпе́йскїй портога́льскїй',
 				'ro' => 'дакорꙋмы́нскїй',
 				'ro_MD' => 'молда́вскїй',
 				'ru' => 'рꙋ́сскїй',
 				'sr' => 'се́рбскїй',
 				'uk' => 'ᲂу҆краи́нскїй',
 				'und' => 'невѣ́домый ѧ҆зы́къ',
 				'zh' => 'хи́нскїй',
 				'zh_Hans' => 'ᲂу҆проще́нный хи́нскїй',
 				'zh_Hant' => 'традїцїо́нный хи́нскїй',

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
			'Arab' => 'а҆раві́йскаѧ',
 			'Cyrl' => 'кѷри́ллица',
 			'Glag' => 'глаго́лица',
 			'Hans' => 'хи́нскаѧ ᲂу҆проще́ннаѧ',
 			'Hans@alt=stand-alone' => 'хи́нскаѧ ᲂу҆проще́ннаѧ',
 			'Hant' => 'хи́нскаѧ традїцїо́ннаѧ',
 			'Hant@alt=stand-alone' => 'хи́нскаѧ традїцїо́ннаѧ',
 			'Latn' => 'латі́ница',
 			'Zxxx' => 'безпи́сьменный',
 			'Zzzz' => 'невѣ̑домаѧ пи́сьмена',

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
			'AU' => 'А҆ѵстралі́ѧ',
 			'BR' => 'бразі́лїа',
 			'BY' => 'бѣ́лаѧ рꙋ́сь',
 			'CA' => 'Кана́да',
 			'CN' => 'хи́нскаѧ страна̀',
 			'DE' => 'герма́нїа',
 			'DK' => 'Дані́ѧ',
 			'FR' => 'га́ллїа',
 			'GB' => 'Вели́каѧ брїта́нїа',
 			'IN' => 'і҆́ндїа',
 			'IT' => 'і҆та́лїа',
 			'JP' => 'ꙗ҆пѡ́нїа',
 			'KG' => 'кирги́зїа',
 			'KZ' => 'казахста́нъ',
 			'MX' => 'Ме́ѯїко',
 			'RU' => 'рѡссі́а',
 			'UA' => 'ᲂу҆краи́на',
 			'US' => 'а҆мерїка̑нскїѧ соединє́нныѧ держа̑вы',
 			'ZZ' => 'невѣ́домаѧ страна̀',

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
 				'gregorian' => q{григорїа́нскїй мѣсѧцесло́въ},
 			},
 			'collation' => {
 				'standard' => q{канѡни́ческое ᲂу҆порѧ́доченїе},
 			},
 			'numbers' => {
 				'latn' => q{а҆раві́йстїи числові́и зна́цы},
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
			'metric' => q{метрі́ческаѧ},
 			'UK' => q{а҆нглі́йскаѧ},
 			'US' => q{а҆мерїка́нскаѧ},

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{[҈҉‌‍꙰꙱꙲︯ ҄ ︮ ꙯ ⷶ ꙣ ⷷ ꙴ ꙃ ꙅ ꙵ ꙶ ꙇ ꙉ ⷸ ꙥ ꙧ ҥ ꙩꙫꙭꙮꚙꚛ ⷫ ҁ ⷵ ⷮ ꙷ ⷹ ꚞ ꙻ ⷰ ꙡ џ ⷲ ⷳ ꙏ ꙸ ꙑ ꙹ ꙺ ⷺ ꙓ ⷻ ꙕ ⷼ ѥ ꚟ ⷽ ꙙ ⷾ ꙛ ѩ ꙝ ѭ ⷿ ꙟ]},
			index => ['А', 'Б', 'В', 'Г', 'Д', 'Є', 'Ж', 'Ѕ', 'З', 'И', 'І', 'К', 'Л', 'М', 'Н', 'Ѻ', 'О', 'П', 'Р', 'С', 'Т', 'Ꙋ', 'Ф', 'Х', 'Ѡ', 'Ѿ', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Ѣ', 'Ю', 'Ѫ', 'Ꙗ', 'Ѧ', 'Ѯ', 'Ѱ', 'Ѳ', 'Ѵ'],
			main => qr{[҇꙽ ҃ ҂ а б ⷠ в ⷡ г ⷢ д ⷣ е є ж ⷤ ⷥ ѕ з ꙁ и й і ї к ⷦ л ⷧ м ⷨ н ⷩ ѻ о ⷪ п р ⷬ с ⷭ т у ꙋ ф х ⷯ ѡ ѿ ꙍ ѽ ц ч ⷱ ш щ ⸯ ꙿ ъ ы ь ѣ ю ѫ ꙗ ѧ ѯ ѱ ѳ ѵ ѷ ⷴ]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[_ \- ‐ – — ⹃ , ; \: ! ? . ( ) ꙳ / ꙾]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Д', 'Є', 'Ж', 'Ѕ', 'З', 'И', 'І', 'К', 'Л', 'М', 'Н', 'Ѻ', 'О', 'П', 'Р', 'С', 'Т', 'Ꙋ', 'Ф', 'Х', 'Ѡ', 'Ѿ', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Ѣ', 'Ю', 'Ѫ', 'Ꙗ', 'Ѧ', 'Ѯ', 'Ѱ', 'Ѳ', 'Ѵ'], };
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
	default		=> qq{„},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:є҆́й|є|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:нѝ|н|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'cyrl',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
					'default' => '#,##0 %',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(бразі́льскїй реа́лъ),
				'other' => q(бразі́льскагѡ реа́ла),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(бѣлорꙋ́сскїй рꙋ́бль),
				'other' => q(бѣлорꙋ́сскагѡ рꙋблѧ̀),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(бѣлорꙋ́сскїй рꙋ́бль \(2000–2016\)),
				'other' => q(бѣлорꙋ́сскагѡ рꙋблѧ̀ \(2000–2016\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(хи́нскїй ю҆а́нь),
				'other' => q(хи́нскагѡ ю҆а́нѧ),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(є҆́ѵрѡ),
				'other' => q(є҆́ѵра),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(а҆нглі́йскїй фꙋ́нтъ сте́рлингѡвъ),
				'other' => q(а҆нглі́йскагѡ фꙋ́нта сте́рлингѡвъ),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(і҆нді́йскаѧ рꙋ́пїѧ),
				'other' => q(і҆нді́йскїѧ рꙋ́пїи),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(ꙗ҆пѡ́нскаѧ і҆е́на),
				'other' => q(ꙗ҆пѡ́нскїѧ і҆е́ны),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(кирги́зскїй сꙋ́мъ),
				'other' => q(кирги́зскагѡ сꙋ́ма),
			},
		},
		'KZT' => {
			symbol => '₸',
			display_name => {
				'currency' => q(каза́хскаѧ деньга̀),
				'other' => q(каза́хскїѧ деньгѝ),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(рѡссі́йскїй рꙋ́бль),
				'other' => q(рѡссі́йскагѡ рꙋблѧ̀),
			},
		},
		'UAH' => {
			symbol => '₴',
			display_name => {
				'currency' => q(ᲂу҆краи́нскаѧ гри́вна),
				'other' => q(ᲂу҆краи́нскїѧ гри́вны),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(а҆мерїка́нскїй до́лларъ),
				'other' => q(а҆мерїка́нскагѡ до́ллара),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(невѣ́домое пла́тное сре́дство),
				'other' => q(невѣ́домагѡ пла́тнагѡ сре́дства),
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
							'і҆аⷩ҇',
							'феⷡ҇',
							'маⷬ҇',
							'а҆пⷬ҇',
							'маꙵ',
							'і҆ꙋⷩ҇',
							'і҆ꙋⷧ҇',
							'а҆́ѵⷢ҇',
							'сеⷫ҇',
							'ѻ҆кⷮ',
							'ноеⷨ',
							'деⷦ҇'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'І҆',
							'Ф',
							'М',
							'А҆',
							'М',
							'І҆',
							'І҆',
							'А҆',
							'С',
							'Ѻ҆',
							'Н',
							'Д'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'і҆аннꙋа́рїа',
							'феврꙋа́рїа',
							'ма́рта',
							'а҆прі́ллїа',
							'ма́їа',
							'і҆ꙋ́нїа',
							'і҆ꙋ́лїа',
							'а҆́ѵгꙋста',
							'септе́мврїа',
							'ѻ҆ктѡ́врїа',
							'ное́мврїа',
							'деке́мврїа'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'і҆аⷩ҇',
							'феⷡ҇',
							'маⷬ҇',
							'а҆пⷬ҇',
							'маꙵ',
							'і҆ꙋⷩ҇',
							'і҆ꙋⷧ҇',
							'а҆́ѵⷢ҇',
							'сеⷫ҇',
							'ѻ҆кⷮ',
							'ноеⷨ',
							'деⷦ҇'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'І҆',
							'Ф',
							'М',
							'А҆',
							'М',
							'І҆',
							'І҆',
							'А҆',
							'С',
							'Ѻ҆',
							'Н',
							'Д'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'і҆аннꙋа́рїй',
							'феврꙋа́рїй',
							'ма́ртъ',
							'а҆прі́ллїй',
							'ма́їй',
							'і҆ꙋ́нїй',
							'і҆ꙋ́лїй',
							'а҆́ѵгꙋстъ',
							'септе́мврїй',
							'ѻ҆ктѡ́врїй',
							'ное́мврїй',
							'деке́мврїй'
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
						mon => 'пнⷣе',
						tue => 'втоⷬ҇',
						wed => 'срⷣе',
						thu => 'чеⷦ҇',
						fri => 'пѧⷦ҇',
						sat => 'сꙋⷠ҇',
						sun => 'ндⷧ҇ѧ'
					},
					narrow => {
						mon => 'П',
						tue => 'В',
						wed => 'С',
						thu => 'Ч',
						fri => 'П',
						sat => 'С',
						sun => 'Н'
					},
					short => {
						mon => 'пнⷣе',
						tue => 'втоⷬ҇',
						wed => 'срⷣе',
						thu => 'чеⷦ҇',
						fri => 'пѧⷦ҇',
						sat => 'сꙋⷠ҇',
						sun => 'ндⷧ҇ѧ'
					},
					wide => {
						mon => 'понедѣ́льникъ',
						tue => 'вто́рникъ',
						wed => 'среда̀',
						thu => 'четверто́къ',
						fri => 'пѧто́къ',
						sat => 'сꙋббѡ́та',
						sun => 'недѣ́лѧ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'пнⷣе',
						tue => 'втоⷬ҇',
						wed => 'срⷣе',
						thu => 'чеⷦ҇',
						fri => 'пѧⷦ҇',
						sat => 'сꙋⷠ҇',
						sun => 'ндⷧ҇ѧ'
					},
					narrow => {
						mon => 'П',
						tue => 'В',
						wed => 'С',
						thu => 'Ч',
						fri => 'П',
						sat => 'С',
						sun => 'Н'
					},
					short => {
						mon => 'пнⷣе',
						tue => 'втоⷬ҇',
						wed => 'срⷣе',
						thu => 'чеⷦ҇',
						fri => 'пѧⷦ҇',
						sat => 'сꙋⷠ҇',
						sun => 'ндⷧ҇ѧ'
					},
					wide => {
						mon => 'понедѣ́льникъ',
						tue => 'вто́рникъ',
						wed => 'среда̀',
						thu => 'четверто́къ',
						fri => 'пѧто́къ',
						sat => 'сꙋббѡ́та',
						sun => 'недѣ́лѧ'
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
					abbreviated => {0 => 'а҃_ѧ че́тверть',
						1 => 'в҃_ѧ че́тверть',
						2 => 'г҃_ѧ че́тверть',
						3 => 'д҃_ѧ че́тверть'
					},
					narrow => {0 => 'а҃',
						1 => 'в҃',
						2 => 'г҃',
						3 => 'д҃'
					},
					wide => {0 => 'а҃_ѧ че́тверть',
						1 => 'в҃_ѧ че́тверть',
						2 => 'г҃_ѧ че́тверть',
						3 => 'д҃_ѧ че́тверть'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'а҃',
						1 => 'в҃',
						2 => 'г҃',
						3 => 'д҃'
					},
					narrow => {0 => 'а҃',
						1 => 'в҃',
						2 => 'г҃',
						3 => 'д҃'
					},
					wide => {0 => 'а҃_ѧ че́тверть',
						1 => 'в҃_ѧ че́тверть',
						2 => 'г҃_ѧ че́тверть',
						3 => 'д҃_ѧ че́тверть'
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
				'wide' => {
					'pm' => q{ПП},
					'am' => q{ДП},
				},
				'abbreviated' => {
					'am' => q{ДП},
					'pm' => q{ПП},
				},
			},
			'stand-alone' => {
				'wide' => {
					'pm' => q{ПП},
					'am' => q{ДП},
				},
				'narrow' => {
					'am' => q{ДП},
					'pm' => q{ПП},
				},
				'abbreviated' => {
					'am' => q{ДП},
					'pm' => q{ПП},
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
				'0' => 'пре́дъ р. х.',
				'1' => 'ѿ р. х.'
			},
			wide => {
				'0' => 'пре́дъ р. х.',
				'1' => 'по р. х.'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM 'л'. y.},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y.MM.dd},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
		'gregorian' => {
			fallback => '{0} – {1}',
		},
		'generic' => {
			fallback => '{0} – {1}',
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} (вре́мѧ)),
		regionFormat => q({0} (лѣ́тнее вре́мѧ)),
		regionFormat => q({0} (зи́мнее вре́мѧ)),
		fallbackFormat => q({1} ({0})),
		'America_Central' => {
			long => {
				'daylight' => q#среднеамерїка́нское лѣ́тнее вре́мѧ#,
				'generic' => q#среднеамерїка́нское вре́мѧ#,
				'standard' => q#среднеамерїка́нское зи́мнее вре́мѧ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#восточноамерїка́нское лѣ́тнее вре́мѧ#,
				'generic' => q#восточноамерїка́нское вре́мѧ#,
				'standard' => q#восточноамерїка́нское зи́мнее вре́мѧ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#а҆мерїка́нское наго́рнее лѣ́тнее вре́мѧ#,
				'generic' => q#а҆мерїка́нское наго́рнее вре́мѧ#,
				'standard' => q#а҆мерїка́нское наго́рнее зи́мнее вре́мѧ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#тихоѻкеа́нское лѣ́тнее вре́мѧ#,
				'generic' => q#тихоѻкеа́нское вре́мѧ#,
				'standard' => q#тихоѻкеа́нское зи́мнее вре́мѧ#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#а҆лматы̀#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#а҆на́дырь#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#а҆кта́ꙋ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#а҆ктю́бинскъ#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#бишке́къ#,
		},
		'Asia/Chita' => {
			exemplarCity => q#чита̀#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#и҆ркꙋ́тскъ#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#петропа́ѵловскъ_камча́тскїй#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#ха́ндыга#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#красноѧ́рскъ#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#магада́нъ#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#новокꙋзне́цкъ#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#новосиби́рскъ#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ѻ҆́мскъ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ᲂу҆ра́льскъ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#кызылѻрда̀#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#сахали́нъ#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#среднеколы́мскъ#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#ᲂу҆́сть_не́ра#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#владивосто́къ#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#ꙗ҆кꙋ́тскъ#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#є҆катерїнбꙋ́ргъ#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#а҆тланті́ческое лѣ́тнее вре́мѧ#,
				'generic' => q#а҆тланті́ческое вре́мѧ#,
				'standard' => q#а҆тланті́ческое зи́мнее вре́мѧ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#всемі́рное сѷгхронїзи́рованное вре́мѧ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#невѣ́домый гра́дъ#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#калинингра́дъ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#кі́евъ#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#ми́нскъ#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#москва̀#,
		},
		'Europe/Samara' => {
			exemplarCity => q#сама́ра#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#сѷмферꙋ́поль#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#ᲂу҆́жградъ#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#волгогра́дъ#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#запра́жїе#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#среднеєѵрѡпе́йское лѣ́тнее вре́мѧ#,
				'generic' => q#среднеєѵрѡпе́йское вре́мѧ#,
				'standard' => q#среднеєѵрѡпе́йское зи́мнее вре́мѧ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#восточноєѵрѡпе́йское лѣ́тнее вре́мѧ#,
				'generic' => q#восточноєѵрѡпе́йское вре́мѧ#,
				'standard' => q#восточноєѵрѡпе́йское зи́мнее вре́мѧ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#вре́мѧ въ калинингра́дѣ и҆ ми́нскѣ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#западноєѵрѡпе́йское лѣ́тнее вре́мѧ#,
				'generic' => q#западноєѵрѡпе́йское вре́мѧ#,
				'standard' => q#западноєѵрѡпе́йское зи́мнее вре́мѧ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#сре́днее вре́мѧ по грі́нꙋичꙋ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#и҆ркꙋ́тское лѣ́тнее вре́мѧ#,
				'generic' => q#и҆ркꙋ́тское вре́мѧ#,
				'standard' => q#и҆ркꙋ́тское зи́мнее вре́мѧ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#восто́чный казахста́нъ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#за́падный казахста́нъ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#красноѧ́рское лѣ́тнее вре́мѧ#,
				'generic' => q#красноѧ́рское вре́мѧ#,
				'standard' => q#красноѧ́рское зи́мнее вре́мѧ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#кирги́зїа#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#магада́нское лѣ́тнее вре́мѧ#,
				'generic' => q#магада́нское вре́мѧ#,
				'standard' => q#магада́нское зи́мнее вре́мѧ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#моско́вское лѣ́тнее вре́мѧ#,
				'generic' => q#моско́вское вре́мѧ#,
				'standard' => q#моско́вское зи́мнее вре́мѧ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#новосиби́рское лѣ́тнее вре́мѧ#,
				'generic' => q#новосиби́рское вре́мѧ#,
				'standard' => q#новосиби́рское зи́мнее вре́мѧ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ѻ҆́мское лѣ́тнее вре́мѧ#,
				'generic' => q#ѻ҆́мское вре́мѧ#,
				'standard' => q#ѻ҆́мское зи́мнее вре́мѧ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#лѣ́тнее вре́мѧ на сахали́нѣ#,
				'generic' => q#вре́мѧ на сахали́нѣ#,
				'standard' => q#зи́мнее вре́мѧ на сахали́нѣ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#владивосто́цкое лѣ́тнее вре́мѧ#,
				'generic' => q#владивосто́цкое вре́мѧ#,
				'standard' => q#владивосто́цкое зи́мнее вре́мѧ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#волгогра́дское лѣ́тнее вре́мѧ#,
				'generic' => q#волгогра́дское вре́мѧ#,
				'standard' => q#волгогра́дское зи́мнее вре́мѧ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ꙗ҆кꙋ́тское лѣ́тнее вре́мѧ#,
				'generic' => q#ꙗ҆кꙋ́тское вре́мѧ#,
				'standard' => q#ꙗ҆кꙋ́тское зи́мнее вре́мѧ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#є҆катерїнбꙋ́ржское лѣ́тнее вре́мѧ#,
				'generic' => q#є҆катерїнбꙋ́ржское вре́мѧ#,
				'standard' => q#є҆катерїнбꙋ́ржское зи́мнее вре́мѧ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
