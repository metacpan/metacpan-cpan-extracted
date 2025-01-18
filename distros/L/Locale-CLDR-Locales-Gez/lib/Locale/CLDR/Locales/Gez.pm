=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gez - Package for language Geez

=cut

package Locale::CLDR::Locales::Gez;
# This file auto generated from Data\common\main\gez.xml
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
				'aa' => 'አፋርኛ',
 				'ab' => 'አብሐዚኛ',
 				'af' => 'አፍሪቃንስኛ',
 				'am' => 'አምሐረኛ',
 				'ar' => 'ዐርቢኛ',
 				'as' => 'አሳሜዛዊ',
 				'ay' => 'አያማርኛ',
 				'az' => 'አዜርባይጃንኛ',
 				'ba' => 'ባስኪርኛ',
 				'be' => 'ቤላራሻኛ',
 				'bg' => 'ቡልጋሪኛ',
 				'bi' => 'ቢስላምኛ',
 				'bn' => 'በንጋሊኛ',
 				'bo' => 'ትበትንኛ',
 				'br' => 'ብሬቶንኛ',
 				'byn' => 'ብሊን',
 				'ca' => 'ካታላንኛ',
 				'co' => 'ኮርሲካኛ',
 				'cs' => 'ቼክኛ',
 				'cy' => 'ወልሽ',
 				'da' => 'ዴኒሽ',
 				'de' => 'ጀርመን',
 				'dz' => 'ድዞንግኻኛ',
 				'el' => 'ግሪክኛ',
 				'en' => 'እንግሊዝኛ',
 				'eo' => 'ኤስፐራንቶ',
 				'es' => 'ስፓኒሽ',
 				'et' => 'ኤስቶኒአን',
 				'eu' => 'ባስክኛ',
 				'fa' => 'ፐርሲያኛ',
 				'fi' => 'ፊኒሽ',
 				'fj' => 'ፊጂኛ',
 				'fo' => 'ፋሮኛ',
 				'fr' => 'ፈረንሳይኛ',
 				'fy' => 'ፍሪስኛ',
 				'ga' => 'አይሪሽ',
 				'gd' => 'እስኮትስ፡ጌልክኛ',
 				'gez' => 'ግዕዝኛ',
 				'gl' => 'ጋለጋኛ',
 				'gn' => 'ጓራኒኛ',
 				'gu' => 'ጉጃርቲኛ',
 				'ha' => 'ሃውሳኛ',
 				'he' => 'ዕብራስጥ',
 				'hi' => 'ሐንድኛ',
 				'hr' => 'ክሮሽያንኛ',
 				'hu' => 'ሀንጋሪኛ',
 				'hy' => 'አርመናዊ',
 				'ia' => 'ኢንቴርሊንጓ',
 				'id' => 'እንዶኒሲኛ',
 				'ie' => 'እንተርሊንግወ',
 				'ik' => 'እኑፒያቅኛ',
 				'is' => 'አይስላንድኛ',
 				'it' => 'ጣሊያንኛ',
 				'iu' => 'እኑክቲቱትኛ',
 				'ja' => 'ጃፓንኛ',
 				'jv' => 'ጃቫንኛ',
 				'ka' => 'ጊዮርጊያን',
 				'kk' => 'ካዛክኛ',
 				'kl' => 'ካላሊሱትኛ',
 				'km' => 'ክመርኛ',
 				'kn' => 'ካናዳኛ',
 				'ko' => 'ኮሪያኛ',
 				'ks' => 'ካሽሚርኛ',
 				'ku' => 'ኩርድሽኛ',
 				'ky' => 'ኪርጊዝኛ',
 				'la' => 'ላቲንኛ',
 				'ln' => 'ሊንጋላኛ',
 				'lo' => 'ላውስኛ',
 				'lt' => 'ሊቱአኒያን',
 				'lv' => 'ላትቪያን',
 				'mg' => 'ማላጋስኛ',
 				'mi' => 'ማዮሪኛ',
 				'mk' => 'ማከዶኒኛ',
 				'ml' => 'ማላያላምኛ',
 				'mn' => 'ሞንጎላዊኛ',
 				'mr' => 'ማራዚኛ',
 				'ms' => 'ማላይኛ',
 				'mt' => 'ማልቲስኛ',
 				'my' => 'ቡርማኛ',
 				'na' => 'ናኡሩ',
 				'ne' => 'ኔፓሊኛ',
 				'nl' => 'ደች',
 				'no' => 'ኖርዌጂያን',
 				'oc' => 'ኦኪታንኛ',
 				'om' => 'ኦሮምኛ',
 				'or' => 'ኦሪያኛ',
 				'pa' => 'ፓንጃቢኛ',
 				'pl' => 'ፖሊሽ',
 				'ps' => 'ፑሽቶኛ',
 				'pt' => 'ፖርቱጋሊኛ',
 				'qu' => 'ኵቿኛ',
 				'rm' => 'ሮማንስ',
 				'rn' => 'ሩንዲኛ',
 				'ro' => 'ሮማኒያን',
 				'ro_MD' => 'ሞልዳቫዊና',
 				'ru' => 'ራሽኛ',
 				'rw' => 'ኪንያርዋንድኛ',
 				'sa' => 'ሳንስክሪትኛ',
 				'sd' => 'ሲንድሂኛ',
 				'sg' => 'ሳንጎኛ',
 				'si' => 'ስንሃልኛ',
 				'sid' => 'ሲዳምኛ',
 				'sk' => 'ስሎቫክኛ',
 				'sl' => 'ስሎቪኛ',
 				'sm' => 'ሳሞአኛ',
 				'sn' => 'ሾናኛ',
 				'so' => 'ሱማልኛ',
 				'sq' => 'ልቤኒኛ',
 				'sr' => 'ሰርቢኛ',
 				'ss' => 'ስዋቲኛ',
 				'st' => 'ሶዞኛ',
 				'su' => 'ሱዳንኛ',
 				'sv' => 'ስዊድንኛ',
 				'sw' => 'ስዋሂሊኛ',
 				'ta' => 'ታሚልኛ',
 				'te' => 'ተሉጉኛ',
 				'tg' => 'ታጂኪኛ',
 				'th' => 'ታይኛ',
 				'ti' => 'ትግርኛ',
 				'tig' => 'ትግረ',
 				'tk' => 'ቱርክመንኛ',
 				'tl' => 'ታጋሎገኛ',
 				'tn' => 'ጽዋናዊኛ',
 				'to' => 'ቶንጋ',
 				'tr' => 'ቱርክኛ',
 				'ts' => 'ጾንጋኛ',
 				'tt' => 'ታታርኛ',
 				'tw' => 'ትዊኛ',
 				'ug' => 'ኡዊግሁርኛ',
 				'uk' => 'ዩክረኒኛ',
 				'ur' => 'ኡርዱኛ',
 				'uz' => 'ኡዝበክኛ',
 				'vi' => 'ቪትናምኛ',
 				'vo' => 'ቮላፑክኛ',
 				'wo' => 'ዎሎፍኛ',
 				'xh' => 'ዞሳኛ',
 				'yi' => 'ይዲሻዊኛ',
 				'yo' => 'ዮሩባዊኛ',
 				'za' => 'ዡዋንግኛ',
 				'zh' => 'ቻይንኛ',
 				'zu' => 'ዙሉኛ',

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
			'Latn' => 'ላቲን',

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
			'AD' => 'አንዶራ',
 			'AE' => 'የተባበሩት፡አረብ፡ኤምሬትስ',
 			'AL' => 'አልባኒያ',
 			'AM' => 'አርሜኒያ',
 			'AR' => 'አርጀንቲና',
 			'AT' => 'ኦስትሪያ',
 			'AU' => 'አውስትሬሊያ',
 			'AZ' => 'አዘርባጃን',
 			'BA' => 'ቦስኒያ፡እና፡ሄርዞጎቪኒያ',
 			'BB' => 'ባርቤዶስ',
 			'BE' => 'ቤልጄም',
 			'BG' => 'ቡልጌሪያ',
 			'BH' => 'ባህሬን',
 			'BM' => 'ቤርሙዳ',
 			'BO' => 'ቦሊቪያ',
 			'BR' => 'ብራዚል',
 			'BT' => 'ቡህታን',
 			'BY' => 'ቤላሩስ',
 			'BZ' => 'ቤሊዘ',
 			'CF' => 'የመካከለኛው፡አፍሪካ፡ሪፐብሊክ',
 			'CH' => 'ስዊዘርላንድ',
 			'CL' => 'ቺሊ',
 			'CM' => 'ካሜሩን',
 			'CN' => 'ቻይና',
 			'CO' => 'ኮሎምቢያ',
 			'CV' => 'ኬፕ፡ቬርዴ',
 			'CY' => 'ሳይፕረስ',
 			'CZ' => 'ቼክ፡ሪፑብሊክ',
 			'DE' => 'ጀርመን',
 			'DK' => 'ዴንማርክ',
 			'DM' => 'ዶሚኒካ',
 			'DO' => 'ዶሚኒክ፡ሪፑብሊክ',
 			'DZ' => 'አልጄሪያ',
 			'EC' => 'ኢኳዶር',
 			'EE' => 'ኤስቶኒያ',
 			'EG' => 'ግብጽ',
 			'EH' => 'ምዕራባዊ፡ሳህራ',
 			'ER' => 'ኤርትራ',
 			'ES' => 'ስፔን',
 			'ET' => 'ኢትዮጵያ',
 			'FI' => 'ፊንላንድ',
 			'FJ' => 'ፊጂ',
 			'FM' => 'ሚክሮኔዢያ',
 			'FR' => 'ፈረንሳይ',
 			'GB' => 'እንግሊዝ',
 			'GE' => 'ጆርጂያ',
 			'GF' => 'የፈረንሳይ፡ጉዊአና',
 			'GM' => 'ጋምቢያ',
 			'GN' => 'ጊኒ',
 			'GQ' => 'ኢኳቶሪያል፡ጊኒ',
 			'GR' => 'ግሪክ',
 			'GW' => 'ቢሳዎ',
 			'GY' => 'ጉያና',
 			'HK' => 'ሆንግ፡ኮንግ',
 			'HR' => 'ክሮኤሽያ',
 			'HT' => 'ሀይቲ',
 			'HU' => 'ሀንጋሪ',
 			'ID' => 'ኢንዶኔዢያ',
 			'IE' => 'አየርላንድ',
 			'IL' => 'እስራኤል',
 			'IN' => 'ህንድ',
 			'IQ' => 'ኢራቅ',
 			'IS' => 'አይስላንድ',
 			'IT' => 'ጣሊያን',
 			'JM' => 'ጃማይካ',
 			'JO' => 'ጆርዳን',
 			'JP' => 'ጃፓን',
 			'KH' => 'ካምቦዲያ',
 			'KM' => 'ኮሞሮስ',
 			'KP' => 'ደቡብ፡ኮሪያ',
 			'KR' => 'ሰሜን፡ኮሪያ',
 			'KW' => 'ክዌት',
 			'LB' => 'ሊባኖስ',
 			'LT' => 'ሊቱዌኒያ',
 			'LV' => 'ላትቪያ',
 			'LY' => 'ሊቢያ',
 			'MA' => 'ሞሮኮ',
 			'MD' => 'ሞልዶቫ',
 			'MK' => 'ማከዶኒያ',
 			'MN' => 'ሞንጎሊያ',
 			'MO' => 'ማካዎ',
 			'MR' => 'ሞሪቴኒያ',
 			'MT' => 'ማልታ',
 			'MU' => 'ማሩሸስ',
 			'MX' => 'ሜክሲኮ',
 			'MY' => 'ማሌዢያ',
 			'NA' => 'ናሚቢያ',
 			'NC' => 'ኒው፡ካሌዶኒያ',
 			'NG' => 'ናይጄሪያ',
 			'NL' => 'ኔዘርላንድ',
 			'NO' => 'ኖርዌ',
 			'NP' => 'ኔፓል',
 			'NZ' => 'ኒው፡ዚላንድ',
 			'PE' => 'ፔሩ',
 			'PF' => 'የፈረንሳይ፡ፖሊኔዢያ',
 			'PG' => 'ፓፑዋ፡ኒው፡ጊኒ',
 			'PL' => 'ፖላንድ',
 			'PR' => 'ፖርታ፡ሪኮ',
 			'RO' => 'ሮሜኒያ',
 			'RS' => 'ሰርቢያ',
 			'RU' => 'ራሺያ',
 			'SA' => 'ሳውድአረቢያ',
 			'SD' => 'ሱዳን',
 			'SE' => 'ስዊድን',
 			'SG' => 'ሲንጋፖር',
 			'SI' => 'ስሎቬኒያ',
 			'SK' => 'ስሎቫኪያ',
 			'SN' => 'ሴኔጋል',
 			'SO' => 'ሱማሌ',
 			'SY' => 'ሲሪያ',
 			'TD' => 'ቻድ',
 			'TF' => 'የፈረንሳይ፡ደቡባዊ፡ግዛቶች',
 			'TH' => 'ታይላንድ',
 			'TJ' => 'ታጃኪስታን',
 			'TL' => 'ምስራቅ፡ቲሞር',
 			'TN' => 'ቱኒዚያ',
 			'TR' => 'ቱርክ',
 			'TT' => 'ትሪኒዳድ፡እና፡ቶባጎ',
 			'TZ' => 'ታንዛኒያ',
 			'UG' => 'ዩጋንዳ',
 			'US' => 'አሜሪካ',
 			'UZ' => 'ዩዝበኪስታን',
 			'VE' => 'ቬንዙዌላ',
 			'VG' => 'የእንግሊዝ፡ድንግል፡ደሴቶች',
 			'VI' => 'የአሜሪካ፡ቨርጂን፡ደሴቶች',
 			'YE' => 'የመን',
 			'ZA' => 'ደቡብ፡አፍሪካ',
 			'ZM' => 'ዛምቢያ',

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
			auxiliary => qr{[ሇ ሏ ⶀ ሗ ሟ ᎀ ᎁ ᎂ ᎃ ⶁ ሧ ሯ ⶂ ሷ ⶃ ሸ ሹ ሺ ሻ ሼ ሽ ሾ ሿ ⶄ ቇ ቐ ቑ ቒ ቓ ቔ ቕ ቖ ቘ ቚ ቛ ቜ ቝ ቧ ᎄ ᎅ ᎆ ᎇ ⶅ ቮ ቯ ቷ ⶆ ቿ ⶇ ኇ ኗ ⶈ ኛ ኟ ⶉ ኧ ⶊ ኯ ኸ ኹ ኺ ኻ ኼ ኽ ኾ ዀ ዂ ዃ ዄ ዅ ዏ ዟ ⶋ ዠ ዡ ዢ ዣ ዤ ዥ ዦ ዧ ዷ ⶌ ዸ ዹ ዺ ዻ ዼ ዽ ዾ ዿ ⶍ ጀ ጁ ጂ ጃ ጄ ጅ ጆ ጇ ⶎ ጏ ጘ ጙ ጚ ጛ ጜ ጝ ጞ ጟ ⶓ ⶔ ⶕ ⶖ ጧ ⶏ ጨ ጩ ጪ ጫ ጬ ጭ ጮ ጯ ⶐ ጷ ⶑ ጿ ፇ ፏ ᎈ ᎉ ᎊ ᎋ ፗ ᎌ ᎍ ᎎ ᎏ ⶒ ፘ ፙ ፚ ⶠ ⶡ ⶢ ⶣ ⶤ ⶥ ⶦ ⶨ ⶩ ⶪ ⶫ ⶬ ⶭ ⶮ ⶰ ⶱ ⶲ ⶳ ⶴ ⶵ ⶶ ⶸ ⶹ ⶺ ⶻ ⶼ ⶽ ⶾ ⷀ ⷁ ⷂ ⷃ ⷄ ⷅ ⷆ ⷈ ⷉ ⷊ ⷋ ⷌ ⷍ ⷎ ⷐ ⷑ ⷒ ⷓ ⷔ ⷕ ⷖ ⷘ ⷙ ⷚ ⷛ ⷜ ⷝ ⷞ]},
			index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ቀ', 'ቈ', 'በ', 'ተ', 'ኀ', 'ኈ', 'ነ', 'አ', 'ከ', 'ኰ', 'ወ', 'ዐ', 'ዘ', 'የ', 'ደ', 'ገ', 'ጐ', 'ጠ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'],
			main => qr{[፟ ᎐ ᎑ ᎒ ᎓ ᎔ ᎕ ᎖ ᎗ ᎘ ᎙ ሀ ሁ ሂ ሃ ሄ ህ ሆ ለ ሉ ሊ ላ ሌ ል ሎ ሐ ሑ ሒ ሓ ሔ ሕ ሖ መ ሙ ሚ ማ ሜ ም ሞ ሠ ሡ ሢ ሣ ሤ ሥ ሦ ረ ሩ ሪ ራ ሬ ር ሮ ሰ ሱ ሲ ሳ ሴ ስ ሶ ቀ ቁ ቂ ቃ ቄ ቅ ቆ ቈ ቊ ቋ ቌ ቍ በ ቡ ቢ ባ ቤ ብ ቦ ተ ቱ ቲ ታ ቴ ት ቶ ኀ ኁ ኂ ኃ ኄ ኅ ኆ ኈ ኊ ኋ ኌ ኍ ነ ኑ ኒ ና ኔ ን ኖ አ ኡ ኢ ኣ ኤ እ ኦ ከ ኩ ኪ ካ ኬ ክ ኮ ኰ ኲ ኳ ኴ ኵ ወ ዉ ዊ ዋ ዌ ው ዎ ዐ ዑ ዒ ዓ ዔ ዕ ዖ ዘ ዙ ዚ ዛ ዜ ዝ ዞ የ ዩ ዪ ያ ዬ ይ ዮ ደ ዱ ዲ ዳ ዴ ድ ዶ ገ ጉ ጊ ጋ ጌ ግ ጎ ጐ ጒ ጓ ጔ ጕ ጠ ጡ ጢ ጣ ጤ ጥ ጦ ጰ ጱ ጲ ጳ ጴ ጵ ጶ ጸ ጹ ጺ ጻ ጼ ጽ ጾ ፀ ፁ ፂ ፃ ፄ ፅ ፆ ፈ ፉ ፊ ፋ ፌ ፍ ፎ ፐ ፑ ፒ ፓ ፔ ፕ ፖ]},
		};
	},
EOT
: sub {
		return { index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ቀ', 'ቈ', 'በ', 'ተ', 'ኀ', 'ኈ', 'ነ', 'አ', 'ከ', 'ኰ', 'ወ', 'ዐ', 'ዘ', 'የ', 'ደ', 'ገ', 'ጐ', 'ጠ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'], };
},
);


has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'group' => q(ወ),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BRL' => {
			display_name => {
				'currency' => q(የብራዚል ሪል),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(የቻይና ዩአን ረንሚንቢ),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(የኢትዮጵያ ብር),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(አውሮ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(የእንግሊዝ ፓውንድ ስተርሊንግ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(የሕንድ ሩፒ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(የጃፓን የን),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(የራሻ ሩብል),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(የአሜሪካን ዶላር),
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
							'ጠሐረ',
							'ከተተ',
							'መገበ',
							'አኀዘ',
							'ግንባት',
							'ሠንየ',
							'ሐመለ',
							'ነሐሰ',
							'ከረመ',
							'ጠቀመ',
							'ኀደረ',
							'ኀሠሠ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ጠ',
							'ከ',
							'መ',
							'አ',
							'ግ',
							'ሠ',
							'ሐ',
							'ነ',
							'ከ',
							'ጠ',
							'ኀ',
							'ኀ'
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
						mon => 'ሰኑይ',
						tue => 'ሠሉስ',
						wed => 'ራብዕ',
						thu => 'ሐሙስ',
						fri => 'ዓርበ',
						sat => 'ቀዳሚት',
						sun => 'እኁድ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ሰ',
						tue => 'ሠ',
						wed => 'ራ',
						thu => 'ሐ',
						fri => 'ዓ',
						sat => 'ቀ',
						sun => 'እ'
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
					'am' => q{ጽባሕ},
					'pm' => q{ምሴት},
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
				'0' => 'ዓ/ዓ',
				'1' => 'ዓ/ም'
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
			'full' => q{EEEE፥ dd MMMM መዓልት y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE፥ dd MMMM መዓልት y G},
			'long' => q{dd MMMM y},
			'medium' => q{dd-MMM-y},
			'short' => q{dd/MM/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
