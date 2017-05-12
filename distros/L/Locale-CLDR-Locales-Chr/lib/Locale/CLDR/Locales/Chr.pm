=head1

Locale::CLDR::Locales::Chr - Package for language Cherokee

=cut

package Locale::CLDR::Locales::Chr;
# This file auto generated from Data\common\main\chr.xml
#	on Fri 29 Apr  6:55:50 pm GMT

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
				'cay' => 'ᎦᏳᎦ',
 				'cho' => 'ᎠᏣᏗ',
 				'chr' => 'ᏣᎳᎩ',
 				'de' => 'ᎠᏂᏓᏥ',
 				'en' => 'ᎩᎵᏏ',
 				'es' => 'ᏍᏆᏂ',
 				'fr' => 'ᎦᎸᏥ',
 				'it' => 'ᎬᏩᎵᏲᏥᎢ',
 				'ja' => 'ᏣᏩᏂᏏ',
 				'moh' => 'ᎼᎻᎦ',
 				'mus' => 'ᎠᎫᏌ',
 				'pt' => 'ᏉᏧᎦᎵ',
 				'ru' => 'ᏲᏂᎢ',
 				'see' => 'ᏏᏂᎦ',
 				'und' => 'ᏄᏬᎵᏍᏛᎾ ᎦᏬᏂᎯᏍᏗ',
 				'zh' => 'ᏓᎶᏂᎨ',

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
			'Arab' => 'ᎡᎳᏈᎩ',
 			'Cher' => 'ᏣᎳᎩ',
 			'Cyrl' => 'ᏲᏂᎢ ᏗᎪᏪᎵ',
 			'Hans' => 'ᎠᎯᏗᎨ ᏓᎶᏂᎨ',
 			'Hant' => 'ᎤᏦᏍᏗ ᏓᎶᏂᎨ',
 			'Latn' => 'ᎳᏗᎾ',
 			'Zzzz' => 'ᏄᏬᎵᏍᏛᎾ ᎠᏍᏓᏩᏛᏍᏙᏗ',

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
			'001' => 'ᎡᎶᎯ',
 			'003' => 'ᏧᏴᏢ ᎠᎺᎵᎦ',
 			'005' => 'ᏧᎦᏃᏮ ᎠᎺᎵᎦ',
 			'019' => 'ᎠᎺᎵᎦᎢ',
 			'AD' => 'ᎠᏂᏙᎳ',
 			'AE' => 'ᏌᏊ ᎢᏳᎾᎵᏍᏔᏅ ᎡᎳᏈ ᎢᎹᎵᏘᏏ',
 			'AF' => 'ᎠᏫᎨᏂᏍᏖᏂ',
 			'AG' => 'ᎤᏪᏘ ᎠᎴ ᏆᏊᏓ',
 			'AI' => 'ᎠᏂᎩᎳ',
 			'AL' => 'ᎠᎵᏇᏂᏯ',
 			'AM' => 'ᎠᎵᎻᏂᎠ',
 			'AO' => 'ᎠᏂᎪᎳ',
 			'AQ' => 'ᏧᏁᏍᏓᎸ',
 			'AR' => 'ᎠᏥᏂᏘᏂᎠ',
 			'AS' => 'ᎠᎺᎵᎧ ᏌᎼᎠ',
 			'AT' => 'ᎠᏍᏟᏯ',
 			'AU' => 'ᎡᎳᏗᏜ',
 			'AW' => 'ᎠᎷᏆ',
 			'AX' => 'ᎣᎴᏅᏓ ᏚᎦᏚᏛᎢ',
 			'AZ' => 'ᎠᏏᎵᏆᏌᏂ',
 			'BA' => 'ᏉᏏᏂᎠ ᎠᎴ ᎲᏤᎪᏫ',
 			'BB' => 'ᏆᏇᏙᏍ',
 			'BD' => 'ᏆᏂᎦᎵᏕᏍ',
 			'BE' => 'ᏇᎵᏥᎥᎻ',
 			'BF' => 'ᏋᎩᎾ ᏩᏐ',
 			'BG' => 'ᏊᎵᎨᎵᎠ',
 			'BH' => 'ᏆᎭᎴᎢᏂ',
 			'BI' => 'ᏋᎷᏂᏗ',
 			'BJ' => 'ᏆᏂᎢᏂ',
 			'BL' => 'ᎠᏥᎸᏉᏗ ᏆᏕᎳᎻ',
 			'BM' => 'ᏆᏊᏓ',
 			'BN' => 'ᏊᎾᎢ',
 			'BO' => 'ᏉᎵᏫᎠ',
 			'BR' => 'ᏆᏏᎵᎢ',
 			'BS' => 'ᎾᏍᎩ ᏆᎭᎹᏍ',
 			'BT' => 'ᏊᏔᏂ',
 			'BV' => 'ᏊᏪ ᎤᎦᏚᏛᎢ',
 			'BW' => 'ᏆᏣᏩᎾ',
 			'BY' => 'ᏇᎳᎷᏍ',
 			'BZ' => 'ᏇᎵᏍ',
 			'CA' => 'ᎨᎾᏓ',
 			'CC' => 'ᎪᎪᏍ (ᎩᎵᏂ) ᏚᎦᏚᏛ',
 			'CD' => 'ᎧᏂᎪ',
 			'CF' => 'ᎬᎿᎨᏍᏛ ᎠᏰᏟ ᏍᎦᏚᎩ',
 			'CG' => 'ᎧᏂᎪ (ᏍᎦᏚᎩ)',
 			'CH' => 'ᏍᏫᏍ',
 			'CI' => 'ᎢᏬᎵ ᎾᎿ ᎠᎹᏳᎶᏗ',
 			'CK' => 'ᎠᏓᏍᏓᏴᎲᏍᎩ ᎤᎦᏚᏛ',
 			'CL' => 'ᏥᎵ',
 			'CM' => 'ᎧᎹᎷᏂ',
 			'CN' => 'ᏓᎶᏂᎨᏍᏛ',
 			'CO' => 'ᎪᎸᎻᏈᎢᎠ',
 			'CR' => 'ᎪᏍᏓ ᎵᎧ',
 			'CU' => 'ᎫᏆ',
 			'CV' => 'ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ',
 			'CW' => 'ᏂᎦᏓ ᎤᏂᎲ ᎾᎿ ᎫᎳᎨᎣ',
 			'CX' => 'ᏓᏂᏍᏓᏲᎯᎲ ᎤᎦᏚᏛᎢ',
 			'CY' => 'ᏌᎢᏆᏍ',
 			'CZ' => 'ᏤᎩ ᏍᎦᏚᎩ',
 			'DE' => 'ᎠᏂᏛᏥ',
 			'DJ' => 'ᏥᏊᏗ',
 			'DK' => 'ᏗᏂᎹᎦ',
 			'DM' => 'ᏙᎻᏂᎧ',
 			'DO' => 'ᏙᎻᏂᎧᏂ ᏍᎦᏚᎩ',
 			'DZ' => 'ᎠᎵᏥᎵᏯ',
 			'EC' => 'ᎡᏆᏙᎵ',
 			'EE' => 'ᎡᏍᏙᏂᏯ',
 			'EG' => 'ᎢᏥᏈᎢ',
 			'ER' => 'ᎡᎵᏟᏯ',
 			'ES' => 'ᎠᏂᏍᏆᏂᏱ',
 			'FI' => 'ᏫᏂᎦᏙᎯ',
 			'FJ' => 'ᏫᏥ',
 			'FK' => 'ᏩᎩ ᏚᎦᏚᏛᎢ',
 			'FK@alt=variant' => 'ᏩᎩ ᎤᎦᏚᏛ (ᎢᏍᎳᏍ ᎹᎸᏫᎾᏍ)',
 			'FM' => 'ᎠᏰᏟ ᏧᎾᎵᎪᎯ ᎾᎿ ᎹᎢᏉᏂᏏᏯ',
 			'FO' => 'ᏪᎶ ᏚᎦᏚᏛᎢ',
 			'FR' => 'ᎦᎸᏥᏱ',
 			'GA' => 'ᎦᏉᏂ',
 			'GB' => 'ᎩᎵᏏᏲ',
 			'GD' => 'ᏋᎾᏓ',
 			'GE' => 'ᏣᎠᏥᎢ',
 			'GF' => 'ᎠᏂᎦᎸᏥ ᎩᎠ',
 			'GG' => 'ᎬᏂᏏ',
 			'GH' => 'ᎦᎠᎾ',
 			'GI' => 'ᏥᏆᎵᏓ',
 			'GL' => 'ᎢᏤᏍᏛᏱ',
 			'GM' => 'ᎦᎹᏈᎢᎠ',
 			'GN' => 'ᎫᏇ',
 			'GP' => 'ᏩᏓᎷᏇ',
 			'GQ' => 'ᎡᏆᏙᎵᎠᎵ ᎩᎢᏂ',
 			'GR' => 'ᎪᎢᎯ',
 			'GS' => 'ᏧᎦᏃᏮ ᏣᏥᏱ ᎠᎴ ᎾᏍᎩ ᏧᎦᏃᏮ ᎠᏍᏛᎭᏟ ᏚᎦᏚᏛ',
 			'GT' => 'ᏩᏔᎹᎳ',
 			'GU' => 'ᏆᎻ',
 			'GW' => 'ᎫᏇ-ᏈᏌᎤᏫ',
 			'GY' => 'ᎦᏯᎾ',
 			'HK' => 'ᎰᏂᎩ ᎪᏂᎩ',
 			'HM' => 'ᎲᏗ ᎤᎦᏚᏛᎢ ᎠᎴ ᎺᎩᏓᎾᎵᏗ ᏚᎦᏚᏛᎢ',
 			'HR' => 'ᎧᎶᎡᏏᎠ',
 			'HT' => 'ᎮᎢᏘ',
 			'HU' => 'ᎲᏂᎦᎵ',
 			'ID' => 'ᎢᏂᏙᏂᏍᏯ',
 			'IE' => 'ᎠᎢᎴᏂᏗ',
 			'IL' => 'ᎢᏏᎵᏱ',
 			'IM' => 'ᎤᏍᏗ ᎤᎦᏚᏛᎢ ᎾᎿ ᎠᏍᎦᏯ',
 			'IN' => 'ᎢᏅᏗᎾ',
 			'IO' => 'ᏈᏗᏏ ᏴᏫᏯ ᎠᎺᏉ ᎢᎬᎾᏕᏅ',
 			'IQ' => 'ᎢᎳᎩ',
 			'IR' => 'ᎢᎴᏂ',
 			'IS' => 'ᏧᏁᏍᏓᎸᎯ',
 			'IT' => 'ᏲᎶ',
 			'JE' => 'ᏨᎵᏏ',
 			'JM' => 'ᏣᎺᎢᎧ',
 			'JO' => 'ᏦᏓᏂ',
 			'JP' => 'ᏣᏩᏂᏏ',
 			'KE' => 'ᎨᏂᏯ',
 			'KG' => 'ᎩᎵᏣᎢᏍ',
 			'KH' => 'ᎧᎹᏉᏗᎠᏂ',
 			'KI' => 'ᎧᎵᏆᏘ',
 			'KM' => 'ᎪᎼᎳᏍ',
 			'KN' => 'ᎠᏰᏟ ᎾᎿ ᎨᏥᎸᏉᏗ ᎠᏂᏪᏌ ᎠᎴ ᎠᏂᏁᏫᏍ',
 			'KP' => 'ᏧᏴᏢ ᎪᎵᎠ',
 			'KR' => 'ᏧᎦᏃᏮ ᎪᎵᎠ',
 			'KW' => 'ᎫᏪᎢᏘ',
 			'KY' => 'ᎨᎢᎹᏂ ᏚᎦᏚᏛᎢ',
 			'KZ' => 'ᎧᏎᎧᏍᏕᏂ',
 			'LA' => 'ᎴᎣᏍ',
 			'LB' => 'ᎴᏆᎾᏂ',
 			'LI' => 'ᎵᎦᏗᏂᏍᏓᏂ',
 			'LK' => 'ᏍᎵ ᎳᏂᎧ',
 			'LR' => 'ᎳᏈᎵᏯ',
 			'LS' => 'ᎴᏐᏙ',
 			'LT' => 'ᎵᏗᏪᏂᎠ',
 			'LU' => 'ᎸᎧᏎᏋᎩ',
 			'LV' => 'ᎳᏘᏫᎠ',
 			'LY' => 'ᎵᏈᏯ',
 			'MA' => 'ᎼᎶᎪ',
 			'MC' => 'ᎹᎾᎪ',
 			'MD' => 'ᎹᎵᏙᏫᎠ',
 			'ME' => 'ᎼᏂᏔᏁᎦᎶ',
 			'MF' => 'ᎠᏥᎸᏉᏗ ᏡᏡ',
 			'MG' => 'ᎹᏓᎦᏍᎧᎵ',
 			'MH' => 'ᎹᏌᎵ ᏚᎪᏚᏛ',
 			'MK' => 'ᎹᏏᏙᏂᎢᎠ',
 			'ML' => 'ᎹᎵ',
 			'MM' => 'ᎹᏯᎹᎵ',
 			'MN' => 'ᎹᏂᎪᎵᎠ',
 			'MO' => 'ᎹᎧᎣ (ᎤᏓᏤᎵᏓ ᏧᏂᎸᏫᏍᏓᏁᏗ ᎢᎬᎾᏕᎾ) ᏣᎢ',
 			'MO@alt=short' => 'ᎹᎧᎣ',
 			'MP' => 'ᎾᏍᎩ ᎤᏴᏢ ᏗᏜ ᎹᎵᎠᎾ ᏚᎦᏚᏛ',
 			'MQ' => 'ᎹᏘᏂᎨ',
 			'MR' => 'ᎹᏘᎢᏯ',
 			'MS' => 'ᎹᏂᏘᏌᎳᏗ',
 			'MT' => 'ᎹᎵᏔ',
 			'MU' => 'ᎼᎵᏏᎥᏍ',
 			'MV' => 'ᎹᎵᏗᏫᏍ',
 			'MW' => 'ᎹᎳᏫ',
 			'MX' => 'ᏍᏆᏂᏱ',
 			'MY' => 'ᎹᎴᏏᎢᎠ',
 			'MZ' => 'ᎼᏎᎻᏇᎩ',
 			'NA' => 'ᎾᎻᏈᎢᏯ',
 			'NC' => 'ᎢᏤ ᎧᎵᏙᏂᎠᏂ',
 			'NF' => 'ᏃᎵᏬᎵᎩ ᎤᎦᏚᏛᎢ',
 			'NG' => 'ᏂᏥᎵᏯ',
 			'NI' => 'ᏂᎧᎳᏆ',
 			'NL' => 'ᏁᏛᎳᏂ',
 			'NO' => 'ᏃᏪ',
 			'NP' => 'ᏁᏆᎵ',
 			'NR' => 'ᏃᎤᎷ',
 			'NU' => 'ᏂᏳ',
 			'NZ' => 'ᎢᏤ ᏏᎢᎴᏂᏗ',
 			'OM' => 'ᎣᎺᏂ',
 			'PA' => 'ᏆᎾᎹ',
 			'PE' => 'ᏇᎷ',
 			'PF' => 'ᎠᏂᎦᎸᏣ ᏆᎵᏂᏏᎠ',
 			'PG' => 'ᏆᏇ ᎢᏤ ᎩᏂ',
 			'PH' => 'ᎠᏂᏈᎵᎩᏃ',
 			'PK' => 'ᏆᎩᏍᏖᏂ',
 			'PL' => 'ᏉᎳᏂ',
 			'PM' => 'ᏎᏂᏘ ᏈᏓ ᎠᎴ ᎻᏇᎶᏂ',
 			'PN' => 'ᏈᎧᎵᏂ ᎤᎦᏚᏛᎢ',
 			'PR' => 'ᏇᎡᏙ ᎵᎢᎪ',
 			'PS' => 'ᏆᎴᏍᏗᏂᎠᏂ ᏄᎬᏫᏳᏌᏕᎩ',
 			'PT' => 'ᏉᏥᎦᎳ',
 			'PW' => 'ᏆᎴᎠᏫ',
 			'PY' => 'ᏆᎳᏇᎢᏯ',
 			'QA' => 'ᎧᏔᎵ',
 			'RO' => 'ᎶᎹᏂᏯ',
 			'RS' => 'ᏒᏈᏯ',
 			'RU' => 'ᏲᏂᎢ',
 			'RW' => 'ᎶᏩᏂᏓ',
 			'SA' => 'ᏌᎤᏗ ᎡᎴᏈᎠ',
 			'SB' => 'ᏐᎶᎹᏂ ᏚᎦᏚᏛᎢ',
 			'SC' => 'ᏏᎡᏥᎵᏍ',
 			'SD' => 'ᏑᏕᏂ',
 			'SE' => 'ᏍᏫᏕᏂ',
 			'SG' => 'ᏏᏂᎦᏉᎵ',
 			'SH' => 'ᎠᏥᎸᏉᏗ ᎮᎵᎾ',
 			'SI' => 'ᏍᎶᏫᏂᎠ',
 			'SK' => 'ᏍᎶᏩᎩᎠ',
 			'SL' => 'ᏏᎡᎳ ᎴᎣᏂ',
 			'US' => 'ᎠᎹᏰᏟ',
 			'ZZ' => 'ᏄᏬᎵᏍᏛᎾ ᎤᏔᏂᏗᎦᏙᎯ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'ᏅᏙ ᏗᏎᏗ',
 			'currency' => 'ᎠᏕᎳ',

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
 				'gregorian' => q{ᏅᏙ ᏗᏎᏗ},
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
			'metric' => q{ᎺᏘᎩ},
 			'US' => q{ᎣᏂᏏ},

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
			index => ['Ꭰ', 'Ꭶ', 'Ꭽ', 'Ꮃ', 'Ꮉ', 'Ꮎ', 'Ꮖ', 'Ꮜ', 'Ꮣ', 'Ꮬ', 'Ꮳ', 'Ꮹ', 'Ꮿ'],
			main => qr{(?^u:[ꭰ ꭱ ꭲ ꭳ ꭴ ꭵ ꭶ ꭷ ꭸ ꭹ ꭺ ꭻ ꭼ ꭽ ꭾ ꭿ ꮀ ꮁ ꮂ ꮃ ꮄ ꮅ ꮆ ꮇ ꮈ ꮉ ꮊ ꮋ ꮌ ꮍ ꮎ ꮏ ꮐ ꮑ ꮒ ꮓ ꮔ ꮕ ꮖ ꮗ ꮘ ꮙ ꮚ ꮛ ꮜ ꮝ ꮞ ꮟ ꮠ ꮡ ꮢ ꮣ ꮤ ꮥ ꮦ ꮧ ꮨ ꮩ ꮪ ꮫ ꮬ ꮭ ꮮ ꮯ ꮰ ꮱ ꮲ ꮳ ꮴ ꮵ ꮶ ꮷ ꮸ ꮹ ꮺ ꮻ ꮼ ꮽ ꮾ ꮿ ᏸ ᏹ ᏺ ᏻ ᏼ])},
		};
	},
EOT
: sub {
		return { index => ['Ꭰ', 'Ꭶ', 'Ꭽ', 'Ꮃ', 'Ꮉ', 'Ꮎ', 'Ꮖ', 'Ꮜ', 'Ꮣ', 'Ꮬ', 'Ꮳ', 'Ꮹ', 'Ꮿ'], };
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(ᏧᏒᎯᏓ),
						'one' => q({0} ᏏᎦ),
						'other' => q({0} ᏧᏒᎯᏓ),
					},
					'hour' => {
						'name' => q(ᎢᏧᏣᎶᏓ),
						'one' => q({0} ᏑᏣᎶᏓ),
						'other' => q({0} ᎢᏧᏣᎶᏓ),
					},
					'minute' => {
						'name' => q(ᎢᏧᏔᏬᏍᏔᏅ),
						'one' => q({0} ᎢᏯᏔᏬᏍᏔᏅ),
						'other' => q({0} ᎢᏧᏔᏬᏍᏔᏅ),
					},
					'month' => {
						'name' => q(ᎢᏯᏅᏓ),
						'one' => q({0} ᏏᏅᏓ),
						'other' => q({0} ᎢᏯᏅᏓ),
					},
					'second' => {
						'name' => q(ᏗᏎᏢ),
						'one' => q({0} ᎠᏎᏢ),
						'other' => q({0} ᏗᏎᏢ),
					},
					'week' => {
						'name' => q(ᎢᏳᎾᏙᏓᏆᏍᏗ),
						'one' => q({0} ᏒᎾᏙᏓᏆᏍᏗ),
						'other' => q({0} ᎢᏳᎾᏙᏓᏆᏍᏗ),
					},
					'year' => {
						'name' => q(ᏧᏕᏘᏴᏓ),
						'one' => q({0} ᏑᏕᏘᏴᏓ),
						'other' => q({0} ᏧᏕᏘᏴᏓ),
					},
				},
				'narrow' => {
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
				'short' => {
					'day' => {
						'name' => q(ᏧᏒᎯᏓ),
					},
					'hour' => {
						'name' => q(ᎢᏧᏣᎶᏓ),
					},
					'minute' => {
						'name' => q(ᎢᏧᏔᏬᏍᏔᏅ),
					},
					'month' => {
						'name' => q(ᎢᏯᏅᏓ),
					},
					'second' => {
						'name' => q(ᏗᏎᏢ),
					},
					'week' => {
						'name' => q(ᎢᏳᎾᏙᏓᏆᏍᏗ),
					},
					'year' => {
						'name' => q(ᏧᏕᏘᏴᏓ),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᎥᎥ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᎥᏝ|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
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
		scientificFormat => {
			'default' => {
				'standard' => {
					'' => '#E0',
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
					'accounting' => {
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
			display_name => {
				'currency' => q(ᏆᏏᎵᎢ ᎠᏕᎳ),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(ᎧᎾᏓ ᎠᏕᎳ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ᏓᎶᏂᎨ ᎠᏕᎳ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ᏳᎳᏛ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ᎩᎵᏏᏲ ᎠᏕᎳ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ᎢᏅᏗᎾ ᎠᏕᎳ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ᏣᏩᏂᏏ ᎠᏕᎳ),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(ᏍᏆᏂ ᎠᏕᎳ),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ᏲᏂᎢ ᎠᏕᎳ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ᎤᏃᏍᏗ),
				'one' => q(ᎤᏃᏍᏗ),
				'other' => q(ᏧᏃᏍᏗ),
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
							'ᎤᏃ',
							'ᎧᎦ',
							'ᎠᏅ',
							'ᎧᏬ',
							'ᎠᏂ',
							'ᏕᎭ',
							'ᎫᏰ',
							'ᎦᎶ',
							'ᏚᎵ',
							'ᏚᏂ',
							'ᏅᏓ',
							'ᎥᏍ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ᎤᏃᎸᏔᏅ',
							'ᎧᎦᎵ',
							'ᎠᏅᏱ',
							'ᎧᏬᏂ',
							'ᎠᏂᏍᎬᏘ',
							'ᏕᎭᎷᏱ',
							'ᎫᏰᏉᏂ',
							'ᎦᎶᏂ',
							'ᏚᎵᏍᏗ',
							'ᏚᏂᏅᏗ',
							'ᏅᏓᏕᏆ',
							'ᎥᏍᎩᏱ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Ꭴ',
							'Ꭷ',
							'Ꭰ',
							'Ꭷ',
							'Ꭰ',
							'Ꮥ',
							'Ꭻ',
							'Ꭶ',
							'Ꮪ',
							'Ꮪ',
							'Ꮕ',
							'Ꭵ'
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
						mon => 'ᏉᏅᎯ',
						tue => 'ᏔᎵᏁ',
						wed => 'ᏦᎢᏁ',
						thu => 'ᏅᎩᏁ',
						fri => 'ᏧᎾᎩ',
						sat => 'ᏈᏕᎾ',
						sun => 'ᏆᏍᎬ'
					},
					wide => {
						mon => 'ᎤᎾᏙᏓᏉᏅᎯ',
						tue => 'ᏔᎵᏁᎢᎦ',
						wed => 'ᏦᎢᏁᎢᎦ',
						thu => 'ᏅᎩᏁᎢᎦ',
						fri => 'ᏧᎾᎩᎶᏍᏗ',
						sat => 'ᎤᎾᏙᏓᏈᏕᎾ',
						sun => 'ᎤᎾᏙᏓᏆᏍᎬ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Ꮙ',
						tue => 'Ꮤ',
						wed => 'Ꮶ',
						thu => 'Ꮕ',
						fri => 'Ꮷ',
						sat => 'Ꭴ',
						sun => 'Ꮖ'
					},
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
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
					'morning1' => q{ᏌᎾᎴ},
					'noon' => q{ᎢᎦ},
					'pm' => q{ᏒᎯᏱᎢᏗᏢ},
					'am' => q{ᏌᎾᎴ},
					'afternoon1' => q{ᏒᎯᏱᎢᏗᏢ},
				},
				'wide' => {
					'pm' => q{ᏒᎯᏱᎢᏗᏢ},
					'morning1' => q{ᏌᎾᎴ},
					'noon' => q{ᎢᎦ},
					'am' => q{ᏌᎾᎴ},
					'afternoon1' => q{ᏒᎯᏱᎢᏗᏢ},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{ᏌᎾᎴ},
					'morning1' => q{ᏌᎾᎴ},
					'noon' => q{ᎢᎦ},
					'pm' => q{ᏒᎯᏱᎢᏗᏢ},
					'afternoon1' => q{ᏒᎯᏱᎢᏗᏢ},
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
				'0' => 'ᎤᏓᎷᎸ',
				'1' => 'ᎤᎶᏐᏅ'
			},
			wide => {
				'0' => 'Ꮟ ᏥᏌ ᎾᏕᎲᏍᎬᎾ',
				'1' => 'ᎠᎩᏃᎮᎵᏓᏍᏗᏱ ᎠᏕᏘᏱᏍᎬ ᏱᎰᏩ ᏧᏓᏂᎸᎢᏍᏗ'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
		'gregorian' => {
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{E, M/d},
			MMMd => q{MMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'generic' => {
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{E, M/d},
			MMMd => q{MMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, M/d/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
		'gregorian' => {
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d–d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
		'generic' => {
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y – E, M/d/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d–d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y – M/d/y G},
				y => q{M/d/y – M/d/y G},
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
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(ᎢᎢᎢ),
		regionFormat => q({0} ᎢᏳᏩᎪᏗ),
		'Alaska' => {
			short => {
				'daylight' => q(AKDT),
				'generic' => q(AKT),
				'standard' => q(AKST),
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q(ᎠᏰᎵ ᎢᎦ ᎢᏳᏩᎪᏗ),
				'generic' => q(ᎠᏰᎵ ᎢᏳᏩᎪᏗ),
				'standard' => q(ᎠᏰᎵ ᏰᎵᏊ ᏗᏙᎳᎩ ᎢᏳᏩᎪᏗ),
			},
			short => {
				'daylight' => q(CDT),
				'generic' => q(CT),
				'standard' => q(CST),
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q(ᎧᎸᎬᎢᏗᏢ ᎢᎦ ᎢᏳᏩᎪᏗ),
				'generic' => q(ᎧᎸᎬᎢᏗᏢ ᎢᏳᏩᎪᏗ),
				'standard' => q(ᎧᎸᎬᎢᏗᏢ ᏰᎵᏊ ᏗᏙᎳᎩ ᎢᏳᏩᎪᏗ),
			},
			short => {
				'daylight' => q(EDT),
				'generic' => q(ET),
				'standard' => q(EST),
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q(ᎣᏓᎸ ᎢᎦ ᎢᏳᏩᎪᏗ),
				'generic' => q(ᎣᏓᎸ ᎢᏳᏩᎪᏗ),
				'standard' => q(ᎣᏓᎸ ᏰᎵᏊ ᏗᏙᎳᎩ ᎢᏳᏩᎪᏗ),
			},
			short => {
				'daylight' => q(MDT),
				'generic' => q(MT),
				'standard' => q(MST),
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q(ᏭᏕᎵᎬ ᎢᎦ ᎢᏳᏩᎪᏗ),
				'generic' => q(ᏭᏕᎵᎬ ᎢᏳᏩᎪᏗ),
				'standard' => q(ᏭᏕᎵᎬ ᏰᎵᏊ ᏗᏙᎳᎩ ᎢᏳᏩᎪᏗ),
			},
			short => {
				'daylight' => q(PDT),
				'generic' => q(PT),
				'standard' => q(PST),
			},
		},
		'Atlantic' => {
			short => {
				'daylight' => q(ADT),
				'generic' => q(AT),
				'standard' => q(AST),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(ᎢᏤ ᎢᏳᏍᏗ ᎢᏳᏩᎪᏗ),
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q(HADT),
				'generic' => q(HAT),
				'standard' => q(HAST),
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q(HDT),
				'generic' => q(HST),
				'standard' => q(HST),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
