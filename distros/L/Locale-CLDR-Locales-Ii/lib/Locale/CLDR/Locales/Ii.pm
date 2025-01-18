=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ii - Package for language Sichuan Yi

=cut

package Locale::CLDR::Locales::Ii;
# This file auto generated from Data\common\main\ii.xml
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
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0}（{1}）';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}，{1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'ꀊꇁꀨꉙ',
 				'ar_001' => 'ꀊꇁꀨꉙ（ꋧꃅ）',
 				'de' => 'ꄓꇩꉙ',
 				'en' => 'ꑱꇩꉙ',
 				'es' => 'ꑭꀠꑸꉙ',
 				'fr' => 'ꃔꇩꉙ',
 				'hi' => 'ꑴꄃꉙ',
 				'hi_Latn@alt=variant' => 'ꑴꐛꑱꉙ',
 				'ii' => 'ꆈꌠꉙ',
 				'it' => 'ꑴꄊꆺꉙ',
 				'ja' => 'ꏝꀪꉙ',
 				'nds' => 'ꃅꄷꀁꂥꄓꉙ',
 				'nl' => 'ꉿꇂꉙ',
 				'pt' => 'ꁍꄨꑸꉙ',
 				'ro' => 'ꇆꂷꆀꑸꉙ',
 				'ru' => 'ꊉꇩꉙ',
 				'sw' => 'ꌖꑟꆺꉙ',
 				'und' => 'ꅉꀋꌠꅇꂷ',
 				'zh' => 'ꍏꇩꉙ',

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
			'Arab' => 'ꀊꇁꀨꁱꂷ',
 			'Cyrl' => 'ꀊꆨꌦꇁꃚꁱꂷ',
 			'Hans' => 'ꈝꐮꁱꂷ',
 			'Hans@alt=stand-alone' => 'ꈝꐮꉌꈲꁱꂷ',
 			'Hant' => 'ꀎꋏꁱꂷ',
 			'Latn' => 'ꇁꄂꁱꂷ',
 			'Yiii' => 'ꆈꌠꁱꂷ',
 			'Zxxx' => 'ꁱꀋꉆꌠ',
 			'Zzzz' => 'ꅉꀋꐚꌠꁱꂷ',

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
			'001' => 'ꋧꃅ',
 			'002' => 'ꃏꍏ',
 			'003' => 'ꀙꂰꍏ',
 			'005' => 'ꆆꂰꍏ',
 			'009' => 'ꄊꑸꍏ',
 			'019' => 'ꂰꍏ',
 			'142' => 'ꑸꍏ',
 			'150' => 'ꉩꍏ',
 			'BE' => 'ꀘꆹꏃ',
 			'BR' => 'ꀠꑭ',
 			'CN' => 'ꍏꇩ',
 			'DE' => 'ꄓꇩ',
 			'FR' => 'ꃔꇩ',
 			'GB' => 'ꑱꇩ',
 			'IN' => 'ꑴꄗ',
 			'IT' => 'ꑴꄊꆺ',
 			'JP' => 'ꏝꀪ',
 			'MX' => 'ꃀꑭꇬ',
 			'RU' => 'ꊉꇆꌦ',
 			'US' => 'ꂰꇩ',
 			'ZZ' => 'ꃅꄷꅉꀋꐚꌠ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ꈎꌗ',

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
 				'gregorian' => q{ꄉꉻꃅꑍ},
 				'islamic' => q{ꑳꌦꇂꑍꉖ},
 			},
 			'numbers' => {
 				'latn' => q{ꀊꆿꀙꃷꁨꁱꂷ},
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
			'metric' => q{ꂰꌬꌠ},
 			'UK' => q{ꑱꇩ},
 			'US' => q{ꂰꇩ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ꅇꉙ: {0}',
 			'script' => 'ꁱꂷꑵ：{0}',
 			'region' => 'ꃅꄷ: {0}',

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
			auxiliary => qr{[꒐ ꒑ ꒒ ꒓ ꒔ ꒕ ꒖ ꒗ ꒘ ꒙ ꒚ ꒛ ꒜ ꒝ ꒞ ꒟ ꒠ ꒡ ꒢ ꒣ ꒤ ꒥ ꒦ ꒧ ꒨ ꒩ ꒪ ꒫ ꒬ ꒭ ꒮ ꒯ ꒰ ꒱ ꒲ ꒳ ꒴ ꒵ ꒶ ꒷ ꒸ ꒹ ꒺ ꒻ ꒼ ꒽ ꒾ ꒿ ꓀ ꓁ ꓂ ꓃ ꓄ ꓅ ꓆]},
			index => ['A', 'B', '{BB}', 'C', '{CH}', 'D', '{DD}', 'E', 'F', 'G', '{GG}', 'H', '{HL}', '{HM}', '{HN}', '{HX}', 'I', '{IE}', 'J', '{JJ}', 'K', 'L', 'M', '{MG}', 'N', '{NB}', '{ND}', '{NG}', '{NJ}', '{NR}', '{NY}', '{NZ}', 'O', 'P', 'Q', 'R', '{RR}', 'S', '{SH}', '{SS}', 'T', '{UO}', 'V', 'W', 'X', 'Y', 'Z', '{ZH}', '{ZZ}'],
			main => qr{[ꀀ ꀁ ꀂ ꀃ ꀄ ꀅ ꀆ ꀇ ꀈ ꀉ ꀊ ꀋ ꀌ ꀍ ꀎ ꀏ ꀐ ꀑ ꀒ ꀓ ꀔ ꀕ ꀖ ꀗ ꀘ ꀙ ꀚ ꀛ ꀜ ꀝ ꀞ ꀟ ꀠ ꀡ ꀢ ꀣ ꀤ ꀥ ꀦ ꀧ ꀨ ꀩ ꀪ ꀫ ꀬ ꀭ ꀮ ꀯ ꀰ ꀱ ꀲ ꀳ ꀴ ꀵ ꀶ ꀷ ꀸ ꀹ ꀺ ꀻ ꀼ ꀽ ꀾ ꀿ ꁀ ꁁ ꁂ ꁃ ꁄ ꁅ ꁆ ꁇ ꁈ ꁉ ꁊ ꁋ ꁌ ꁍ ꁎ ꁏ ꁐ ꁑ ꁒ ꁓ ꁔ ꁕ ꁖ ꁗ ꁘ ꁙ ꁚ ꁛ ꁜ ꁝ ꁞ ꁟ ꁠ ꁡ ꁢ ꁣ ꁤ ꁥ ꁦ ꁧ ꁨ ꁩ ꁪ ꁫ ꁬ ꁭ ꁮ ꁯ ꁰ ꁱ ꁲ ꁳ ꁴ ꁵ ꁶ ꁷ ꁸ ꁹ ꁺ ꁻ ꁼ ꁽ ꁾ ꁿ ꂀ ꂁ ꂂ ꂃ ꂄ ꂅ ꂆ ꂇ ꂈ ꂉ ꂊ ꂋ ꂌ ꂍ ꂎ ꂏ ꂐ ꂑ ꂒ ꂓ ꂔ ꂕ ꂖ ꂗ ꂘ ꂙ ꂚ ꂛ ꂜ ꂝ ꂞ ꂟ ꂠ ꂡ ꂢ ꂣ ꂤ ꂥ ꂦ ꂧ ꂨ ꂩ ꂪ ꂫ ꂬ ꂭ ꂮ ꂯ ꂰ ꂱ ꂲ ꂳ ꂴ ꂵ ꂶ ꂷ ꂸ ꂹ ꂺ ꂻ ꂼ ꂽ ꂾ ꂿ ꃀ ꃁ ꃂ ꃃ ꃄ ꃅ ꃆ ꃇ ꃈ ꃉ ꃊ ꃋ ꃌ ꃍ ꃎ ꃏ ꃐ ꃑ ꃒ ꃓ ꃔ ꃕ ꃖ ꃗ ꃘ ꃙ ꃚ ꃛ ꃜ ꃝ ꃞ ꃟ ꃠ ꃡ ꃢ ꃣ ꃤ ꃥ ꃦ ꃧ ꃨ ꃩ ꃪ ꃫ ꃬ ꃭ ꃮ ꃯ ꃰ ꃱ ꃲ ꃳ ꃴ ꃵ ꃶ ꃷ ꃸ ꃹ ꃺ ꃻ ꃼ ꃽ ꃾ ꃿ ꄀ ꄁ ꄂ ꄃ ꄄ ꄅ ꄆ ꄇ ꄈ ꄉ ꄊ ꄋ ꄌ ꄍ ꄎ ꄏ ꄐ ꄑ ꄒ ꄓ ꄔ ꄕ ꄖ ꄗ ꄘ ꄙ ꄚ ꄛ ꄜ ꄝ ꄞ ꄟ ꄠ ꄡ ꄢ ꄣ ꄤ ꄥ ꄦ ꄧ ꄨ ꄩ ꄪ ꄫ ꄬ ꄭ ꄮ ꄯ ꄰ ꄱ ꄲ ꄳ ꄴ ꄵ ꄶ ꄷ ꄸ ꄹ ꄺ ꄻ ꄼ ꄽ ꄾ ꄿ ꅀ ꅁ ꅂ ꅃ ꅄ ꅅ ꅆ ꅇ ꅈ ꅉ ꅊ ꅋ ꅌ ꅍ ꅎ ꅏ ꅐ ꅑ ꅒ ꅓ ꅔ ꅕ ꅖ ꅗ ꅘ ꅙ ꅚ ꅛ ꅜ ꅝ ꅞ ꅟ ꅠ ꅡ ꅢ ꅣ ꅤ ꅥ ꅦ ꅧ ꅨ ꅩ ꅪ ꅫ ꅬ ꅭ ꅮ ꅯ ꅰ ꅱ ꅲ ꅳ ꅴ ꅵ ꅶ ꅷ ꅸ ꅹ ꅺ ꅻ ꅼ ꅽ ꅾ ꅿ ꆀ ꆁ ꆂ ꆃ ꆄ ꆅ ꆆ ꆇ ꆈ ꆉ ꆊ ꆋ ꆌ ꆍ ꆎ ꆏ ꆐ ꆑ ꆒ ꆓ ꆔ ꆕ ꆖ ꆗ ꆘ ꆙ ꆚ ꆛ ꆜ ꆝ ꆞ ꆟ ꆠ ꆡ ꆢ ꆣ ꆤ ꆥ ꆦ ꆧ ꆨ ꆩ ꆪ ꆫ ꆬ ꆭ ꆮ ꆯ ꆰ ꆱ ꆲ ꆳ ꆴ ꆵ ꆶ ꆷ ꆸ ꆹ ꆺ ꆻ ꆼ ꆽ ꆾ ꆿ ꇀ ꇁ ꇂ ꇃ ꇄ ꇅ ꇆ ꇇ ꇈ ꇉ ꇊ ꇋ ꇌ ꇍ ꇎ ꇏ ꇐ ꇑ ꇒ ꇓ ꇔ ꇕ ꇖ ꇗ ꇘ ꇙ ꇚ ꇛ ꇜ ꇝ ꇞ ꇟ ꇠ ꇡ ꇢ ꇣ ꇤ ꇥ ꇦ ꇧ ꇨ ꇩ ꇪ ꇫ ꇬ ꇭ ꇮ ꇯ ꇰ ꇱ ꇲ ꇳ ꇴ ꇵ ꇶ ꇷ ꇸ ꇹ ꇺ ꇻ ꇼ ꇽ ꇾ ꇿ ꈀ ꈁ ꈂ ꈃ ꈄ ꈅ ꈆ ꈇ ꈈ ꈉ ꈊ ꈋ ꈌ ꈍ ꈎ ꈏ ꈐ ꈑ ꈒ ꈓ ꈔ ꈕ ꈖ ꈗ ꈘ ꈙ ꈚ ꈛ ꈜ ꈝ ꈞ ꈟ ꈠ ꈡ ꈢ ꈣ ꈤ ꈥ ꈦ ꈧ ꈨ ꈩ ꈪ ꈫ ꈬ ꈭ ꈮ ꈯ ꈰ ꈱ ꈲ ꈳ ꈴ ꈵ ꈶ ꈷ ꈸ ꈹ ꈺ ꈻ ꈼ ꈽ ꈾ ꈿ ꉀ ꉁ ꉂ ꉃ ꉄ ꉅ ꉆ ꉇ ꉈ ꉉ ꉊ ꉋ ꉌ ꉍ ꉎ ꉏ ꉐ ꉑ ꉒ ꉓ ꉔ ꉕ ꉖ ꉗ ꉘ ꉙ ꉚ ꉛ ꉜ ꉝ ꉞ ꉟ ꉠ ꉡ ꉢ ꉣ ꉤ ꉥ ꉦ ꉧ ꉨ ꉩ ꉪ ꉫ ꉬ ꉭ ꉮ ꉯ ꉰ ꉱ ꉲ ꉳ ꉴ ꉵ ꉶ ꉷ ꉸ ꉹ ꉺ ꉻ ꉼ ꉽ ꉾ ꉿ ꊀ ꊁ ꊂ ꊃ ꊄ ꊅ ꊆ ꊇ ꊈ ꊉ ꊊ ꊋ ꊌ ꊍ ꊎ ꊏ ꊐ ꊑ ꊒ ꊓ ꊔ ꊕ ꊖ ꊗ ꊘ ꊙ ꊚ ꊛ ꊜ ꊝ ꊞ ꊟ ꊠ ꊡ ꊢ ꊣ ꊤ ꊥ ꊦ ꊧ ꊨ ꊩ ꊪ ꊫ ꊬ ꊭ ꊮ ꊯ ꊰ ꊱ ꊲ ꊳ ꊴ ꊵ ꊶ ꊷ ꊸ ꊹ ꊺ ꊻ ꊼ ꊽ ꊾ ꊿ ꋀ ꋁ ꋂ ꋃ ꋄ ꋅ ꋆ ꋇ ꋈ ꋉ ꋊ ꋋ ꋌ ꋍ ꋎ ꋏ ꋐ ꋑ ꋒ ꋓ ꋔ ꋕ ꋖ ꋗ ꋘ ꋙ ꋚ ꋛ ꋜ ꋝ ꋞ ꋟ ꋠ ꋡ ꋢ ꋣ ꋤ ꋥ ꋦ ꋧ ꋨ ꋩ ꋪ ꋫ ꋬ ꋭ ꋮ ꋯ ꋰ ꋱ ꋲ ꋳ ꋴ ꋵ ꋶ ꋷ ꋸ ꋹ ꋺ ꋻ ꋼ ꋽ ꋾ ꋿ ꌀ ꌁ ꌂ ꌃ ꌄ ꌅ ꌆ ꌇ ꌈ ꌉ ꌊ ꌋ ꌌ ꌍ ꌎ ꌏ ꌐ ꌑ ꌒ ꌓ ꌔ ꌕ ꌖ ꌗ ꌘ ꌙ ꌚ ꌛ ꌜ ꌝ ꌞ ꌟ ꌠ ꌡ ꌢ ꌣ ꌤ ꌥ ꌦ ꌧ ꌨ ꌩ ꌪ ꌫ ꌬ ꌭ ꌮ ꌯ ꌰ ꌱ ꌲ ꌳ ꌴ ꌵ ꌶ ꌷ ꌸ ꌹ ꌺ ꌻ ꌼ ꌽ ꌾ ꌿ ꍀ ꍁ ꍂ ꍃ ꍄ ꍅ ꍆ ꍇ ꍈ ꍉ ꍊ ꍋ ꍌ ꍍ ꍎ ꍏ ꍐ ꍑ ꍒ ꍓ ꍔ ꍕ ꍖ ꍗ ꍘ ꍙ ꍚ ꍛ ꍜ ꍝ ꍞ ꍟ ꍠ ꍡ ꍢ ꍣ ꍤ ꍥ ꍦ ꍧ ꍨ ꍩ ꍪ ꍫ ꍬ ꍭ ꍮ ꍯ ꍰ ꍱ ꍲ ꍳ ꍴ ꍵ ꍶ ꍷ ꍸ ꍹ ꍺ ꍻ ꍼ ꍽ ꍾ ꍿ ꎀ ꎁ ꎂ ꎃ ꎄ ꎅ ꎆ ꎇ ꎈ ꎉ ꎊ ꎋ ꎌ ꎍ ꎎ ꎏ ꎐ ꎑ ꎒ ꎓ ꎔ ꎕ ꎖ ꎗ ꎘ ꎙ ꎚ ꎛ ꎜ ꎝ ꎞ ꎟ ꎠ ꎡ ꎢ ꎣ ꎤ ꎥ ꎦ ꎧ ꎨ ꎩ ꎪ ꎫ ꎬ ꎭ ꎮ ꎯ ꎰ ꎱ ꎲ ꎳ ꎴ ꎵ ꎶ ꎷ ꎸ ꎹ ꎺ ꎻ ꎼ ꎽ ꎾ ꎿ ꏀ ꏁ ꏂ ꏃ ꏄ ꏅ ꏆ ꏇ ꏈ ꏉ ꏊ ꏋ ꏌ ꏍ ꏎ ꏏ ꏐ ꏑ ꏒ ꏓ ꏔ ꏕ ꏖ ꏗ ꏘ ꏙ ꏚ ꏛ ꏜ ꏝ ꏞ ꏟ ꏠ ꏡ ꏢ ꏣ ꏤ ꏥ ꏦ ꏧ ꏨ ꏩ ꏪ ꏫ ꏬ ꏭ ꏮ ꏯ ꏰ ꏱ ꏲ ꏳ ꏴ ꏵ ꏶ ꏷ ꏸ ꏹ ꏺ ꏻ ꏼ ꏽ ꏾ ꏿ ꐀ ꐁ ꐂ ꐃ ꐄ ꐅ ꐆ ꐇ ꐈ ꐉ ꐊ ꐋ ꐌ ꐍ ꐎ ꐏ ꐐ ꐑ ꐒ ꐓ ꐔ ꐕ ꐖ ꐗ ꐘ ꐙ ꐚ ꐛ ꐜ ꐝ ꐞ ꐟ ꐠ ꐡ ꐢ ꐣ ꐤ ꐥ ꐦ ꐧ ꐨ ꐩ ꐪ ꐫ ꐬ ꐭ ꐮ ꐯ ꐰ ꐱ ꐲ ꐳ ꐴ ꐵ ꐶ ꐷ ꐸ ꐹ ꐺ ꐻ ꐼ ꐽ ꐾ ꐿ ꑀ ꑁ ꑂ ꑃ ꑄ ꑅ ꑆ ꑇ ꑈ ꑉ ꑊ ꑋ ꑌ ꑍ ꑎ ꑏ ꑐ ꑑ ꑒ ꑓ ꑔ ꑕ ꑖ ꑗ ꑘ ꑙ ꑚ ꑛ ꑜ ꑝ ꑞ ꑟ ꑠ ꑡ ꑢ ꑣ ꑤ ꑥ ꑦ ꑧ ꑨ ꑩ ꑪ ꑫ ꑬ ꑭ ꑮ ꑯ ꑰ ꑱ ꑲ ꑳ ꑴ ꑵ ꑶ ꑷ ꑸ ꑹ ꑺ ꑻ ꑼ ꑽ ꑾ ꑿ ꒀ ꒁ ꒂ ꒃ ꒄ ꒅ ꒆ ꒇ ꒈ ꒉ ꒊ ꒋ ꒌ]},
			numbers => qr{[\- ‑ , . {\\\-} % ‰ + 0 1 2 3 4 5 6 7 8 9 {ꋍꑍꌕꇖꉬꃘꏃꉆꈬ}]},
			punctuation => qr{[﹉﹊﹋﹌ _＿﹍﹎﹏︳︴ \-－﹣ ‐‑ – —︱ ― ,，﹐ 、﹑ ;；﹔ \:：﹕ !！﹗ ?？﹖ .．﹒ ‥︰ … 。 · ＇‘’ ＂“”〝〞 (（﹙︵ )）﹚︶ \[［ \]］ \N{U+FF5B.FE5B.FE37}｝﹜︸ 〈︿ 〉﹀ 《︽ 》︾ 「﹁ 」﹂ 『﹃ 』﹄ 【︻ 】︼ 〔﹝︹ 〕﹞︺ 〖 〗 ‖ § @＠﹫ *＊﹡ /／ \\＼﹨ \&＆﹠ #＃﹟ %％﹪ ‰ ′ ″ ‵ 〃 ※]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{BB}', 'C', '{CH}', 'D', '{DD}', 'E', 'F', 'G', '{GG}', 'H', '{HL}', '{HM}', '{HN}', '{HX}', 'I', '{IE}', 'J', '{JJ}', 'K', 'L', 'M', '{MG}', 'N', '{NB}', '{ND}', '{NG}', '{NJ}', '{NR}', '{NY}', '{NZ}', 'O', 'P', 'Q', 'R', '{RR}', 'S', '{SH}', '{SS}', 'T', '{UO}', 'V', 'W', 'X', 'Y', 'Z', '{ZH}', '{ZZ}'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ꉬ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ꀋꉬ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}、{1}),
				middle => q({0}、{1}),
				end => q({0}ꌋꆀ{1}),
				2 => q({0}ꌋꆀ{1}),
		} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'CNY' => {
			symbol => '¥',
		},
		'XXX' => {
			display_name => {
				'currency' => q(ꅉꀋꐚꌠꌋꆀꎆꃀꀋꈁꀐꌠ),
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
					wide => {
						nonleap => [
							'ꋍꆪ',
							'ꑍꆪ',
							'ꌕꆪ',
							'ꇖꆪ',
							'ꉬꆪ',
							'ꃘꆪ',
							'ꏃꆪ',
							'ꉆꆪ',
							'ꈬꆪ',
							'ꊰꆪ',
							'ꊯꊪꆪ',
							'ꊰꑋꆪ'
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
						mon => 'ꆏꋍ',
						tue => 'ꆏꑍ',
						wed => 'ꆏꌕ',
						thu => 'ꆏꇖ',
						fri => 'ꆏꉬ',
						sat => 'ꆏꃘ',
						sun => 'ꑬꆏ'
					},
					wide => {
						mon => 'ꆏꊂꋍ',
						tue => 'ꆏꊂꑍ',
						wed => 'ꆏꊂꌕ',
						thu => 'ꆏꊂꇖ',
						fri => 'ꆏꊂꉬ',
						sat => 'ꆏꊂꃘ',
						sun => 'ꑬꆏꑍ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ꋍ',
						tue => 'ꑍ',
						wed => 'ꌕ',
						thu => 'ꇖ',
						fri => 'ꉬ',
						sat => 'ꃘ',
						sun => 'ꆏ'
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
					abbreviated => {0 => '1ꄮꐰ',
						1 => '2ꄮꐰ',
						2 => '3ꄮꐰ',
						3 => '4ꄮꐰ'
					},
					wide => {0 => 'ꄮꐰꋍꂷꂶꌠ',
						1 => 'ꄮꐰꑍꂷꂶꌠ',
						2 => 'ꄮꐰꌕꂷꂶꌠ',
						3 => 'ꄮꐰꇖꂷꂶꌠ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
					'am' => q{ꎸꄑ},
					'pm' => q{ꁯꋒ},
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
				'0' => 'ꃅꋊꂿ',
				'1' => 'ꃅꋊꊂ'
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
			'full' => q{G y MMMM dꑍ,EEEE},
			'long' => q{G y MMMM dꑍ},
			'medium' => q{G y MMM dꑍ},
		},
		'gregorian' => {
			'full' => q{y MMMM d, EEEE},
			'long' => q{y MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
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
		'generic' => {
			Ed => q{dꑍ,E},
			GyMMMEd => q{G y MMMM dꑍ,E},
			GyMMMd => q{G y MMM dꑍ},
			MMMEd => q{MMM dꑍ,E},
			MMMMd => q{MMMM dꑍ},
			MMMd => q{MMM dꑍ},
			d => q{dꑍ},
			yyyyMMMEd => q{G y MMM dꑍ,E},
			yyyyMMMd => q{G y MMM dꑍ},
		},
		'gregorian' => {
			Ed => q{dꑍ, E},
			GyMMMEd => q{G y MMM dꑍ,E},
			GyMMMd => q{G y MMM dꑍ},
			Hmsv => q{v HH:mm:ss},
			MEd => q{MMꆪ-ddꑍ，E},
			MMMEd => q{MMMM dꑍ,E},
			MMMMd => q{MMMM dꑍ},
			MMMd => q{MMM dꑍ},
			Md => q{MMꆪ-ddꑍ},
			d => q{dꑍ},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			hmsv => q{v ah:mm:ss},
			yMMMEd => q{y MMM dꑍ,E},
			yMMMd => q{yꈎMꆪdꑍ},
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
			yMMMEd => {
				y => q{G y MMM dꑍ, E – y MMM dꑍ, E},
			},
		},
		'gregorian' => {
			MMMEd => {
				M => q{MMM dꑍ, E – MMM dꑍ, E},
				d => q{MMM dꑍ, E – MMM dꑍ, E},
			},
			MMMd => {
				M => q{MMM dꑍ – MMM dꑍ},
				d => q{MMM dꑍ–dꑍ},
			},
			fallback => '{0} – {1}',
			yMMMEd => {
				M => q{y MMM dꑍ, E – MMM dꑍ, E},
				d => q{y MMM dꑍ, E – MMM dꑍ, E},
				y => q{y MMM dꑍ, E – y MMM dꑍ, E},
			},
			yMMMd => {
				M => q{y MMM dꑍ – MMM dꑍ},
				d => q{y MMM dꑍ–dꑍ},
				y => q{y MMM dꑍ – y MMM dꑍ},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(ꋧꃅꎕꏦꄮꈉ{0}),
		gmtZeroFormat => q(ꋧꃅꎕꏦꄮꈉ),
		regionFormat => q({0}ꄮꈉ),
		regionFormat => q({0}ꃅꎸꄮꈉ),
		regionFormat => q({0}ꎕꏦꄮꈉ),
		fallbackFormat => q({1}（{0}）),
		'Etc/Unknown' => {
			exemplarCity => q#ꅉꀋꐚꌠ#,
		},
		'GMT' => {
			long => {
				'standard' => q#ꋧꃅꎕꏦꄮꈉ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
