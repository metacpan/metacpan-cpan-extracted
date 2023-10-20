=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Seh - Package for language Sena

=cut

package Locale::CLDR::Locales::Seh;
# This file auto generated from Data\common\main\seh.xml
#	on Fri 13 Oct  9:36:57 am GMT

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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ak' => 'akan',
 				'am' => 'amárico',
 				'ar' => 'árabe',
 				'be' => 'bielo-russo',
 				'bg' => 'búlgaro',
 				'bn' => 'bengali',
 				'cs' => 'tcheco',
 				'de' => 'alemão',
 				'el' => 'grego',
 				'en' => 'inglês',
 				'es' => 'espanhol',
 				'fa' => 'persa',
 				'fr' => 'francês',
 				'ha' => 'hausa',
 				'hi' => 'hindi',
 				'hu' => 'húngaro',
 				'id' => 'indonésio',
 				'ig' => 'ibo',
 				'it' => 'italiano',
 				'ja' => 'japonês',
 				'jv' => 'javanês',
 				'km' => 'cmer',
 				'ko' => 'coreano',
 				'ms' => 'malaio',
 				'my' => 'birmanês',
 				'ne' => 'nepalês',
 				'nl' => 'holandês',
 				'pa' => 'panjabi',
 				'pl' => 'polonês',
 				'pt' => 'português',
 				'ro' => 'romeno',
 				'ru' => 'russo',
 				'rw' => 'kinyarwanda',
 				'seh' => 'sena',
 				'so' => 'somali',
 				'sv' => 'sueco',
 				'ta' => 'tâmil',
 				'th' => 'tailandês',
 				'tr' => 'turco',
 				'uk' => 'ucraniano',
 				'ur' => 'urdu',
 				'vi' => 'vietnamita',
 				'yo' => 'iorubá',
 				'zh' => 'chinês',
 				'zu' => 'zulu',

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
 			'AE' => 'Emirados Árabes Unidos',
 			'AF' => 'Afeganistão',
 			'AG' => 'Antígua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albânia',
 			'AM' => 'Armênia',
 			'AO' => 'Angola',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Áustria',
 			'AU' => 'Austrália',
 			'AW' => 'Aruba',
 			'AZ' => 'Azerbaijão',
 			'BA' => 'Bósnia-Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bélgica',
 			'BF' => 'Burquina Faso',
 			'BG' => 'Bulgária',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Butão',
 			'BW' => 'Botsuana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canadá',
 			'CD' => 'Congo-Kinshasa',
 			'CF' => 'República Centro-Africana',
 			'CG' => 'Congo',
 			'CH' => 'Suíça',
 			'CI' => 'Costa do Marfim',
 			'CK' => 'Ilhas Cook',
 			'CL' => 'Chile',
 			'CM' => 'República dos Camarões',
 			'CN' => 'China',
 			'CO' => 'Colômbia',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CY' => 'Chipre',
 			'CZ' => 'República Tcheca',
 			'DE' => 'Alemanha',
 			'DJ' => 'Djibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Argélia',
 			'EC' => 'Equador',
 			'EE' => 'Estônia',
 			'EG' => 'Egito',
 			'ER' => 'Eritréia',
 			'ES' => 'Espanha',
 			'ET' => 'Etiópia',
 			'FI' => 'Finlândia',
 			'FJ' => 'Fiji',
 			'FK' => 'Ilhas Malvinas',
 			'FM' => 'Micronésia',
 			'FR' => 'França',
 			'GA' => 'Gabão',
 			'GB' => 'Reino Unido',
 			'GD' => 'Granada',
 			'GE' => 'Geórgia',
 			'GF' => 'Guiana Francesa',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groênlandia',
 			'GM' => 'Gâmbia',
 			'GN' => 'Guiné',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guiné Equatorial',
 			'GR' => 'Grécia',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guiné Bissau',
 			'GY' => 'Guiana',
 			'HN' => 'Honduras',
 			'HR' => 'Croácia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungria',
 			'ID' => 'Indonésia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IN' => 'Índia',
 			'IO' => 'Território Britânico do Oceano Índico',
 			'IQ' => 'Iraque',
 			'IR' => 'Irã',
 			'IS' => 'Islândia',
 			'IT' => 'Itália',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordânia',
 			'JP' => 'Japão',
 			'KE' => 'Quênia',
 			'KG' => 'Quirguistão',
 			'KH' => 'Camboja',
 			'KI' => 'Quiribati',
 			'KM' => 'Comores',
 			'KN' => 'São Cristovão e Nevis',
 			'KP' => 'Coréia do Norte',
 			'KR' => 'Coréia do Sul',
 			'KW' => 'Kuwait',
 			'KY' => 'Ilhas Caiman',
 			'KZ' => 'Casaquistão',
 			'LA' => 'Laos',
 			'LB' => 'Líbano',
 			'LC' => 'Santa Lúcia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libéria',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituânia',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letônia',
 			'LY' => 'Líbia',
 			'MA' => 'Marrocos',
 			'MC' => 'Mônaco',
 			'MD' => 'Moldávia',
 			'MG' => 'Madagascar',
 			'MH' => 'Ilhas Marshall',
 			'MK' => 'Macedônia',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar',
 			'MN' => 'Mongólia',
 			'MP' => 'Ilhas Marianas do Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritânia',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurício',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'México',
 			'MY' => 'Malásia',
 			'MZ' => 'Moçambique',
 			'NA' => 'Namíbia',
 			'NC' => 'Nova Caledônia',
 			'NE' => 'Níger',
 			'NF' => 'Ilhas Norfolk',
 			'NG' => 'Nigéria',
 			'NI' => 'Nicarágua',
 			'NL' => 'Holanda',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelândia',
 			'OM' => 'Omã',
 			'PA' => 'Panamá',
 			'PE' => 'Peru',
 			'PF' => 'Polinésia Francesa',
 			'PG' => 'Papua-Nova Guiné',
 			'PH' => 'Filipinas',
 			'PK' => 'Paquistão',
 			'PL' => 'Polônia',
 			'PM' => 'Saint Pierre e Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Território da Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Catar',
 			'RE' => 'Reunião',
 			'RO' => 'Romênia',
 			'RU' => 'Rússia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arábia Saudita',
 			'SB' => 'Ilhas Salomão',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudão',
 			'SE' => 'Suécia',
 			'SG' => 'Cingapura',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovênia',
 			'SK' => 'Eslováquia',
 			'SL' => 'Serra Leoa',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somália',
 			'SR' => 'Suriname',
 			'ST' => 'São Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Síria',
 			'SZ' => 'Suazilândia',
 			'TC' => 'Ilhas Turks e Caicos',
 			'TD' => 'Chade',
 			'TG' => 'Togo',
 			'TH' => 'Tailândia',
 			'TJ' => 'Tadjiquistão',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TM' => 'Turcomenistão',
 			'TN' => 'Tunísia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'UA' => 'Ucrânia',
 			'UG' => 'Uganda',
 			'US' => 'Estados Unidos',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbequistão',
 			'VA' => 'Vaticano',
 			'VC' => 'São Vicente e Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Ilhas Virgens Britânicas',
 			'VI' => 'Ilhas Virgens dos EUA',
 			'VN' => 'Vietnã',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Iêmen',
 			'YT' => 'Mayotte',
 			'ZA' => 'África do Sul',
 			'ZM' => 'Zâmbia',
 			'ZW' => 'Zimbábue',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á à â ã b c ç d e é ê f g h i í j k l m n o ó ò ô õ p q r s t u ú v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ande|A|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Nkhabe|N)$' }
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
				'currency' => q(Dirém dos Emirados Árabes Unidos),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Cuanza angolano),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dólar australiano),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar bareinita),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franco do Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula botsuanesa),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dólar canadense),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franco congolês),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franco suíço),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Renminbi chinês),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo cabo-verdiano),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franco do Djibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar argelino),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Libra egípcia),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa da Eritréia),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr etíope),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Libra britânica),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi de Gana \(1979–2007\)),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi de Gâmbia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli da Guiné),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rúpia indiana),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Iene japonês),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Xelim queniano),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franco de Comores),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dólar liberiano),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti do Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar líbio),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirém marroquino),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Franco de Madagascar),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya da Mauritânia \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya da Mauritânia),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia de Maurício),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Cuacha do Maláui),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical antigo de Moçambique),
			},
		},
		'MZN' => {
			symbol => 'MTn',
			display_name => {
				'currency' => q(Metical de Moçambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dólar da Namíbia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira nigeriana),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franco ruandês),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rial saudita),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia das Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinar sudanês),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Libra sudanesa antiga),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Libra de Santa Helena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone de Serra Leoa),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Xelim somali),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni da Suazilândia),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar tunisiano),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Xelim da Tanzânia),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Xelim ugandense \(1966–1987\)),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dólar norte-americano),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franco CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franco CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand sul-africano),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Cuacha zambiano \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Cuacha zambiano),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dólar do Zimbábue),
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
							'Fev',
							'Mar',
							'Abr',
							'Mai',
							'Jun',
							'Jul',
							'Aug',
							'Set',
							'Otu',
							'Nov',
							'Dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janeiro',
							'Fevreiro',
							'Marco',
							'Abril',
							'Maio',
							'Junho',
							'Julho',
							'Augusto',
							'Setembro',
							'Otubro',
							'Novembro',
							'Decembro'
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
							'J',
							'J',
							'A',
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
						mon => 'Pos',
						tue => 'Pir',
						wed => 'Tat',
						thu => 'Nai',
						fri => 'Sha',
						sat => 'Sab',
						sun => 'Dim'
					},
					wide => {
						mon => 'Chiposi',
						tue => 'Chipiri',
						wed => 'Chitatu',
						thu => 'Chinai',
						fri => 'Chishanu',
						sat => 'Sabudu',
						sun => 'Dimingu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'P',
						tue => 'C',
						wed => 'T',
						thu => 'N',
						fri => 'S',
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
				'0' => 'AC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Antes de Cristo',
				'1' => 'Anno Domini'
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
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d 'de' MMM 'de' y},
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
			HHmm => q{HH:mm},
			HHmmss => q{HH:mm:ss},
			Hm => q{H:mm},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM 'de' y},
			yMMMEd => q{E, d 'de' MMM 'de' y},
			yMMMM => q{MMMM 'de' y},
			yMMMd => q{d 'de' MMM 'de' y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
		},
		'gregorian' => {
			HHmm => q{HH:mm},
			HHmmss => q{HH:mm:ss},
			Hm => q{H:mm},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM 'de' y},
			yMMMEd => q{E, d 'de' MMM 'de' y},
			yMMMM => q{MMMM 'de' y},
			yMMMd => q{d 'de' MMM 'de' y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
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
