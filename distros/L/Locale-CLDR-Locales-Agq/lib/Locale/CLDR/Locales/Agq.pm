=head1

Locale::CLDR::Locales::Agq - Package for language Aghem

=cut

package Locale::CLDR::Locales::Agq;
# This file auto generated from Data\common\main\agq.xml
#	on Fri 29 Apr  6:50:01 pm GMT

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
				'agq' => 'Aghem',
 				'ak' => 'Akan',
 				'am' => 'Àmalì',
 				'ar' => 'Àlabì',
 				'be' => 'Bɛ̀làlusàn',
 				'bg' => 'Bùugɨlìa',
 				'bn' => 'Bɨ̀ŋgalì',
 				'cs' => 'Chɛ̂',
 				'de' => 'Dzamɛ̀',
 				'el' => 'Gɨ̀lêʔ',
 				'en' => 'Kɨŋgele',
 				'es' => 'Sɨ̀kpanìs',
 				'fa' => 'Kpɛɛshìa',
 				'fr' => 'Kɨ̀fàlàŋsi',
 				'ha' => 'Kɨtsɔŋkaŋ',
 				'hi' => 'Endì',
 				'hu' => 'Hɔŋgalìa',
 				'id' => 'Èndònɛshìa',
 				'ig' => 'Egbò',
 				'it' => 'Ètalìa',
 				'ja' => 'Dzàkpànê',
 				'jv' => 'Dzàbvànê',
 				'km' => 'Kɨmɛ̀',
 				'ko' => 'kùulîa',
 				'ms' => 'Màlae',
 				'my' => 'Bùumɛsɛ̀',
 				'ne' => 'Nɛ̀kpalì',
 				'nl' => 'Dɔ̂s',
 				'pa' => 'Kpuwndzabì',
 				'pl' => 'Kpɔlìs',
 				'pt' => 'Kpotùwgîi',
 				'ro' => 'Lùmanyìa',
 				'ru' => 'Lushìa',
 				'rw' => 'Lùwandà',
 				'so' => 'Sòmalì',
 				'sv' => 'Suedìs',
 				'ta' => 'Tamì',
 				'th' => 'Tàe',
 				'tr' => 'Tʉʉkìs',
 				'uk' => 'Ùkɛlɛnìa',
 				'ur' => 'Uudùw',
 				'vi' => 'Vìyɛtnàmê',
 				'yo' => 'Yulùba',
 				'zh' => 'Chàenê',
 				'zu' => 'Zulù',

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
			'AD' => 'Àndolà',
 			'AE' => 'Yùnaetɛ Alab ɛmelɛ̀',
 			'AF' => 'Àfɨ̀ganìsɨ̀tân',
 			'AG' => 'Àntigwà à Bàbudà',
 			'AI' => 'Àŋgwilà',
 			'AL' => 'Àabɛnìa',
 			'AM' => 'Àmɛnyìa',
 			'AO' => 'Àŋgolà',
 			'AR' => 'Àdzɛ̀ntinà',
 			'AS' => 'Àmɛlekan Samwà',
 			'AT' => 'Usɨtɨ̀là',
 			'AU' => 'Ùsɨ̀tɛ̀lɛlìa',
 			'AW' => 'Àlubà',
 			'AZ' => 'Àzɨbɛ̀dzân',
 			'BA' => 'Bosɨnyìa à Hɛ̀zɛ̀gòvinà',
 			'BB' => 'Bàbadòs',
 			'BD' => 'Baŋgɨ̀làdɛ̂',
 			'BE' => 'Bɛɛdzwùm',
 			'BF' => 'Bùkinà Fasò',
 			'BG' => 'Bùugɛlìa',
 			'BH' => 'Bàlaen',
 			'BI' => 'Bùlundì',
 			'BJ' => 'Bɛ̀nɨ̂ŋ',
 			'BM' => 'Bɛ̀mudà',
 			'BN' => 'Bɨ̀lunè',
 			'BO' => 'Bòlevà',
 			'BR' => 'Bɨ̀làzîi',
 			'BS' => 'Bàhamàs',
 			'BT' => 'Mbutàn',
 			'BW' => 'Bòtɨ̀swǎnà',
 			'BY' => 'Bɛlàlûs',
 			'BZ' => 'Bɛ̀lezɨ̀',
 			'CA' => 'Kanadà',
 			'CD' => 'Dɛ̀mùkàlatì Lèkpubèlè è Kuŋgù',
 			'CF' => 'Sɛnta Afɨlekan Lèkpobèlè',
 			'CG' => 'Kuŋgù',
 			'CH' => 'Suezàlân',
 			'CI' => 'Ku Dɨ̀vûa',
 			'CK' => 'Chwɨla ŋ̀ Kûʔ',
 			'CL' => 'Chilè',
 			'CM' => 'Kàmàlûŋ',
 			'CN' => 'Chaenà',
 			'CO' => 'Kòlombìa',
 			'CR' => 'Kòsɨ̀tà Lekà',
 			'CU' => 'Kuuwbà',
 			'CV' => 'Chwɨla ŋ̀ Kɛ̀b Vɛ̂ɛ',
 			'CY' => 'Saekpùlù',
 			'CZ' => 'Chɛ̂ Lèkpubèlè',
 			'DE' => 'Dzamanè',
 			'DJ' => 'Dzìbuwtì',
 			'DK' => 'Dɛnɨmà',
 			'DM' => 'Dòmenekà',
 			'DO' => 'Dòmenekà Lèkpubèlè',
 			'DZ' => 'Àadzɛlìa',
 			'EC' => 'Ekwadò',
 			'EE' => 'Èsɨ̀tonyìa',
 			'EG' => 'Edzì',
 			'ER' => 'Èletɨ̀là',
 			'ES' => 'Sɨ̀kpɛ̂n',
 			'ET' => 'Ètyǒpìa',
 			'FI' => 'Fɨnlàn',
 			'FJ' => 'Fidzi',
 			'FK' => 'Chwɨlà fɨ Fakɨlàn',
 			'FM' => 'Maekòlòneshìa',
 			'FR' => 'Fàlâŋnsì',
 			'GA' => 'Gàbûn',
 			'GB' => 'Yùnaetɛ Kiŋdɔ̀m',
 			'GD' => 'Gɨ̀lɛnadà',
 			'GE' => 'Dzɔɔdzìa',
 			'GF' => 'Gàyanà è Fàlâŋnsì',
 			'GH' => 'Gaanà',
 			'GI' => 'Dzibɨ̀latà',
 			'GL' => 'Gɨ̀lenlân',
 			'GM' => 'Gambìa',
 			'GN' => 'Ginè',
 			'GP' => 'Gwadalukpɛ̀',
 			'GQ' => 'Èkwɛ̀tolia Ginè',
 			'GR' => 'Gɨ̀lês',
 			'GT' => 'Gwàtɨ̀malà',
 			'GU' => 'Gwam',
 			'GW' => 'Ginè Bìsawù',
 			'GY' => 'Gùyanà',
 			'HN' => 'Hɔndulàs',
 			'HR' => 'Kòwɛshìa',
 			'HT' => 'Hǎetì',
 			'HU' => 'Hɔŋgàlè',
 			'ID' => 'Èndòneshìa',
 			'IE' => 'Aelɨ̀lân',
 			'IL' => 'Ezɨ̀lɛ̂',
 			'IN' => 'Endìa',
 			'IO' => 'Dɨŋò kɨ dzughùnstòʔ kɨ Endìa kɨ Bɨ̀letì kò',
 			'IQ' => 'Èlâkɨ̀',
 			'IR' => 'Èlân',
 			'IS' => 'Aesɨ̀lân',
 			'IT' => 'Etalè',
 			'JM' => 'Dzàmɛkà',
 			'JO' => 'Dzodàn',
 			'JP' => 'Dzàkpân',
 			'KE' => 'Kɨnyà',
 			'KG' => 'Kìdzisɨ̀tân',
 			'KH' => 'Kàmbodìa',
 			'KI' => 'Kèlèbati',
 			'KM' => 'Komolòs',
 			'KN' => 'Sɛ̀n Kî à Nevì',
 			'KP' => 'Kùulîa, Ekùw',
 			'KR' => 'Kùulîa, Emàm',
 			'KW' => 'Kùwɛ̂',
 			'KY' => 'Chwɨlà ŋ̀ Kaemàn',
 			'KZ' => 'Kàzasɨ̀tân',
 			'LA' => 'Làwos',
 			'LB' => 'Lɛbanè',
 			'LC' => 'Sɛ̀n Lushìa',
 			'LI' => 'Letɨnshɨ̀n',
 			'LK' => 'Sɨ̀le Laŋkà',
 			'LR' => 'Làebɛlìa',
 			'LS' => 'Lɛ̀sotù',
 			'LT' => 'Lètwǎnyìa',
 			'LU' => 'Luzɨmbùʔ',
 			'LV' => 'Làtɨva',
 			'LY' => 'Lebìa',
 			'MA' => 'Mòlokò',
 			'MC' => 'Mùnaku',
 			'MD' => 'Mòodovà',
 			'MG' => 'Màdàgasɨkà',
 			'MH' => 'Chwɨlà fɨ Mashà',
 			'MK' => 'Mɨ̀sɨ̀donyìa',
 			'ML' => 'Malè',
 			'MM' => 'Mǐanmà',
 			'MN' => 'Mùŋgolìa',
 			'MP' => 'Chwɨlà m̀ Màlǐanà mɨ̀ Ekùw mò',
 			'MQ' => 'Màtìnekì',
 			'MR' => 'Mùlètanyìa',
 			'MS' => 'Mùŋtselà',
 			'MT' => 'Maatà',
 			'MU' => 'Mùleshwɨ̀s',
 			'MV' => 'Màdivè',
 			'MW' => 'Màlawì',
 			'MX' => 'Mɛkɨzikù',
 			'MY' => 'Màlɛshìa',
 			'MZ' => 'Mùzàmbî',
 			'NA' => 'Nàmibìa',
 			'NC' => 'Kàlèdonyìa È fūghū',
 			'NE' => 'Naedzà',
 			'NF' => 'Chwɨlà fɨ Nufòʔ',
 			'NG' => 'Gɨ̀anyɨ',
 			'NI' => 'Nikàlagwà',
 			'NL' => 'Nedàlân',
 			'NO' => 'Noowɛ̂ɛ',
 			'NP' => 'Nɛkpâa',
 			'NR' => 'Nàwulù',
 			'NU' => 'Niyu',
 			'NZ' => 'Zìlân È fūghū',
 			'OM' => 'Umàn',
 			'PA' => 'Kpanàma',
 			'PE' => 'Kpɛlû',
 			'PF' => 'Kpoleneshìa è Fàlâŋnsì',
 			'PG' => 'Kpakpua Ginè È fūghū',
 			'PH' => 'Felèkpî',
 			'PK' => 'Kpakìsɨ̀tân',
 			'PL' => 'Kpulàn',
 			'PM' => 'Sɛ̀n Kpiyɛ̀ à Mikelɔŋ',
 			'PN' => 'Kpitɨ̀kalè',
 			'PR' => 'Kpǒto Leko',
 			'PS' => 'Adzɨmā kɨ ŋgùŋ kɨ Palɛsɨtɨnyia à kɨ Gazà kò',
 			'PT' => 'Kputuwgà',
 			'PW' => 'Kpàlawù',
 			'PY' => 'Kpalàgwɛ̂',
 			'QA' => 'Katà',
 			'RE' => 'Lèyunyɔ̀ŋ',
 			'RO' => 'Lùmanyìa',
 			'RU' => 'Loshìa',
 			'RW' => 'Lùwandà',
 			'SA' => 'Sawudi Alabi',
 			'SB' => 'Chwɨlà fɨ Solomwɨ̀n',
 			'SC' => 'Sɛchɛ̀lɛ̀s',
 			'SD' => 'Sùdân',
 			'SE' => 'Suedɨ̀n',
 			'SG' => 'Siŋgàkpôo',
 			'SH' => 'Sɛ̀n Èlenà',
 			'SI' => 'Sɨ̀lòvɨnyìa',
 			'SK' => 'Sɨ̀lòvɨkɨ̀a',
 			'SL' => 'Silìa lûŋ',
 			'SM' => 'Sàn Màlenù',
 			'SN' => 'Sɛ̀nɛ̀gâa',
 			'SO' => 'Sòmalìa',
 			'SR' => 'Sulènamè',
 			'ST' => 'Sawo Tɔ̀me à Kpèlènsikpɛ̀',
 			'SV' => 'Esàvadò',
 			'SY' => 'Silîa',
 			'SZ' => 'Shǔazìlân',
 			'TC' => 'Chwɨla n Tɨtê à Kaekùs',
 			'TD' => 'Châ',
 			'TG' => 'Tugù',
 			'TH' => 'Taelàn',
 			'TJ' => 'Tàdzikìsɨ̀tân',
 			'TK' => 'Tuwkelawù',
 			'TL' => 'Ês Taemò',
 			'TM' => 'Tekɨmènèsɨ̀tân',
 			'TN' => 'Tùneshìa',
 			'TO' => 'Tuŋgà',
 			'TR' => 'Teekì',
 			'TT' => 'Tèlenedà à Tòbagù',
 			'TV' => 'Tuwvalùw',
 			'TW' => 'Taewàn',
 			'TZ' => 'Tàanzanyìa',
 			'UA' => 'Yùkɛ̀lɛ̂',
 			'UG' => 'Yùgandà',
 			'US' => 'USA',
 			'UY' => 'Yulùgwɛ̂',
 			'UZ' => 'Yùzɨ̀bɛkìsɨ̀tân',
 			'VA' => 'Vatikàn Sɨ̀tɛ̂',
 			'VC' => 'Sɛ̀n Vinsɨ̀n à Gɨlenadi Ù tē',
 			'VE' => 'Vɛ̀nɛ̀zǔɛɛlà',
 			'VG' => 'Chwɨlà m̀ Vidzinyìa m̀ Bɨ̀letì mò',
 			'VI' => 'U. S. Chwɨlà fɨ Mbuʔmbu',
 			'VN' => 'Vìyɛnàm',
 			'VU' => 'Vànǔatùw',
 			'WF' => 'Wales à Fùwtuwnà',
 			'WS' => 'Sàmowà',
 			'YE' => 'Yɛmɛ̀n',
 			'YT' => 'Màyotì',
 			'ZA' => 'Afɨlekà ghɨ Emàm ghò',
 			'ZM' => 'Zambìa',
 			'ZW' => 'Zìmbagbɛ̀',

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
			auxiliary => qr{(?^u:[q r x])},
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'Ɨ', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'S', 'T', 'U', 'Ʉ', 'V', 'W', 'Y', 'Z', 'ʔ'],
			main => qr{(?^u:[a à â ǎ ā b c d e è ê ě ē ɛ {ɛ̀} {ɛ̂} {ɛ̌} {ɛ̄} f g h i ì î ǐ ī ɨ {ɨ̀} {ɨ̂} {ɨ̌} {ɨ̄} k l m n ŋ o ò ô ǒ ō ɔ {ɔ̀} {ɔ̂} {ɔ̌} {ɔ̄} p s t u ù û ǔ ū ʉ {ʉ̀} {ʉ̂} {ʉ̌} {ʉ̄} v w y z ʔ])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'Ɨ', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'S', 'T', 'U', 'Ʉ', 'V', 'W', 'Y', 'Z', 'ʔ'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
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
	default		=> qq{‚},
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
	default		=> sub { qr'^(?i:òo|O|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hǎe|H|no|n)$' }
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
					'' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'' => '#,##0%',
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
				'currency' => q(Dilàm è Yùnaetɛ Alab Emelɛ̀),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanzà è Àŋgolà),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dɔlà e Ùsɨ̀tɛ̀lɛlìa),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinà è Balae),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Fàlâŋ è Bùlundì),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Kpuwlà è Botɨshǔanà),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dɔlà è Kanadà),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Fàlâŋ è Kuŋgùlê),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Fàlâŋ è Sues),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yùwân Lèmembi è Chaenî),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kàbòvàdianù è Èsùkudò),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Fàlâŋ è Dzìbutì),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinà è Àdzɛlìa),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Bɔ̀ŋ è Edzì),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakafa è Èletɨ̀làe),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bîi è Etyǒkpìa),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yulù),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Bɔ̀ŋ è Bèletì),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sɛ̀di è Gaanà),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dàlasì è Gambìa),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Fàlâŋ è Ginè),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Lukpì è Endìa),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Ghɨ̂n Dzàkpànê),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shwɨlà tɨ Kenyà),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Fàlâŋ è Komolìa),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dɔlà Làebɛlìa),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lɔtì Lèsutù),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinà è Lebìa),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dilàm è Mòlokò),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Àlǐalè è Màlàgasì),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ùgueya è Mùlètenyìa),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Lukpìi è Mùleshòs),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwachà è Màlawè),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mètikà è Mùzàmbî),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dɔlà è Nàmibìa),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naelà è Gɨ̀anyɨ),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Fàlâŋ è Lùwandà),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Leyà è Sàwudì),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Lukpìi è Sɛchɛ̀lɛ̀),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Bɔ̀ŋ è Sùdànê),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Bɔ̀ŋ è Sɛ̀n Èlenà),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Lyɔ̂ŋ),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shwɨlà è Sùmalìa),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dɔbàlà è Sàwu Tɔ̀me à Pèlènsipè),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lèlàŋgenè),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinà è Tùwneshìa),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shwɨlà è Tàanzanyìa),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shwɨlà è Yùgandà),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dɔlà è US),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA Fàlâŋ BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA Fàlâŋ BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Lân è Afɨlekà ghɨ Emàm ghò),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwachà è Zambìa \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwachà è Zambìa),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dɔlà è Zìmbagbɛ̀),
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
							'nùm',
							'kɨz',
							'tɨd',
							'taa',
							'see',
							'nzu',
							'dum',
							'fɔe',
							'dzu',
							'lɔm',
							'kaa',
							'fwo'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ndzɔ̀ŋɔ̀nùm',
							'ndzɔ̀ŋɔ̀kƗ̀zùʔ',
							'ndzɔ̀ŋɔ̀tƗ̀dʉ̀ghà',
							'ndzɔ̀ŋɔ̀tǎafʉ̄ghā',
							'ndzɔ̀ŋèsèe',
							'ndzɔ̀ŋɔ̀nzùghò',
							'ndzɔ̀ŋɔ̀dùmlo',
							'ndzɔ̀ŋɔ̀kwîfɔ̀e',
							'ndzɔ̀ŋɔ̀tƗ̀fʉ̀ghàdzughù',
							'ndzɔ̀ŋɔ̀ghǔuwelɔ̀m',
							'ndzɔ̀ŋɔ̀chwaʔàkaa wo',
							'ndzɔ̀ŋèfwòo'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'n',
							'k',
							't',
							't',
							's',
							'z',
							'k',
							'f',
							'd',
							'l',
							'c',
							'f'
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
						mon => 'kpa',
						tue => 'ghɔ',
						wed => 'tɔm',
						thu => 'ume',
						fri => 'ghɨ',
						sat => 'dzk',
						sun => 'nts'
					},
					wide => {
						mon => 'tsuʔukpà',
						tue => 'tsuʔughɔe',
						wed => 'tsuʔutɔ̀mlò',
						thu => 'tsuʔumè',
						fri => 'tsuʔughɨ̂m',
						sat => 'tsuʔndzɨkɔʔɔ',
						sun => 'tsuʔntsɨ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'k',
						tue => 'g',
						wed => 't',
						thu => 'u',
						fri => 'g',
						sat => 'd',
						sun => 'n'
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
					wide => {0 => 'kɨbâ kɨ 1',
						1 => 'ugbâ u 2',
						2 => 'ugbâ u 3',
						3 => 'ugbâ u 4'
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
					'am' => q{a.g},
					'pm' => q{a.k},
				},
				'abbreviated' => {
					'pm' => q{a.k},
					'am' => q{a.g},
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
				'0' => 'SK',
				'1' => 'BK'
			},
			wide => {
				'0' => 'Sěe Kɨ̀lesto',
				'1' => 'Bǎa Kɨ̀lesto'
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
			Ed => q{d E},
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
			Ed => q{d E},
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
