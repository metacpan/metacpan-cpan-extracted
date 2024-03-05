=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tig - Package for language Tigre

=cut

package Locale::CLDR::Locales::Tig;
# This file auto generated from Data\common\main\tig.xml
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
 				'gd' => 'እስኮትስ ጌልክኛ',
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
 			'AE' => 'የተባበሩት አረብ ኤምሬትስ',
 			'AL' => 'አልባኒያ',
 			'AM' => 'አርሜኒያ',
 			'AR' => 'አርጀንቲና',
 			'AT' => 'ኦስትሪያ',
 			'AU' => 'አውስትሬሊያ',
 			'AZ' => 'አዘርባጃን',
 			'BA' => 'ቦስኒያ እና ሄርዞጎቪኒያ',
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
 			'CD' => 'ኮንጎ',
 			'CF' => 'የመካከለኛው አፍሪካ ሪፐብሊክ',
 			'CH' => 'ስዊዘርላንድ',
 			'CL' => 'ቺሊ',
 			'CM' => 'ካሜሩን',
 			'CN' => 'ቻይና',
 			'CO' => 'ኮሎምቢያ',
 			'CV' => 'ኬፕ ቬርዴ',
 			'CY' => 'ሳይፕረስ',
 			'CZ' => 'ቼክ ሪፑብሊክ',
 			'DE' => 'ጀርመን',
 			'DK' => 'ዴንማርክ',
 			'DM' => 'ዶሚኒካ',
 			'DO' => 'ዶሚኒክ ሪፑብሊክ',
 			'DZ' => 'አልጄሪያ',
 			'EC' => 'ኢኳዶር',
 			'EE' => 'ኤስቶኒያ',
 			'EG' => 'ግብጽ',
 			'EH' => 'ምዕራባዊ ሳህራ',
 			'ER' => 'ኤርትራ',
 			'ES' => 'ስፔን',
 			'ET' => 'ኢትዮጵያ',
 			'FI' => 'ፊንላንድ',
 			'FJ' => 'ፊጂ',
 			'FM' => 'ሚክሮኔዢያ',
 			'FR' => 'ፈረንሳይ',
 			'GB' => 'እንግሊዝ',
 			'GE' => 'ጆርጂያ',
 			'GF' => 'የፈረንሳይ ጉዊአና',
 			'GM' => 'ጋምቢያ',
 			'GN' => 'ጊኒ',
 			'GQ' => 'ኢኳቶሪያል ጊኒ',
 			'GR' => 'ግሪክ',
 			'GW' => 'ቢሳዎ',
 			'GY' => 'ጉያና',
 			'HK' => 'ሆንግ ኮንግ',
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
 			'KP' => 'ሰሜን ኮሪያ',
 			'KR' => 'ደቡብ ኮሪያ',
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
 			'NC' => 'ኒው ካሌዶኒያ',
 			'NG' => 'ናይጄሪያ',
 			'NL' => 'ኔዘርላንድ',
 			'NO' => 'ኖርዌ',
 			'NP' => 'ኔፓል',
 			'NZ' => 'ኒው ዚላንድ',
 			'PE' => 'ፔሩ',
 			'PF' => 'የፈረንሳይ ፖሊኔዢያ',
 			'PG' => 'ፓፑዋ ኒው ጊኒ',
 			'PL' => 'ፖላንድ',
 			'PR' => 'ፖርታ ሪኮ',
 			'RO' => 'ሮሜኒያ',
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
 			'TF' => 'የፈረንሳይ ደቡባዊ ግዛቶች',
 			'TH' => 'ታይላንድ',
 			'TJ' => 'ታጃኪስታን',
 			'TL' => 'ምስራቅ ቲሞር',
 			'TN' => 'ቱኒዚያ',
 			'TR' => 'ቱርክ',
 			'TT' => 'ትሪኒዳድ እና ቶባጎ',
 			'TZ' => 'ታንዛኒያ',
 			'UG' => 'ዩጋንዳ',
 			'US' => 'አሜሪካ',
 			'UZ' => 'ዩዝበኪስታን',
 			'VE' => 'ቬንዙዌላ',
 			'VG' => 'የእንግሊዝ ድንግል ደሴቶች',
 			'VI' => 'የአሜሪካ ቨርጂን ደሴቶች',
 			'YE' => 'የመን',
 			'ZA' => 'ደቡብ አፍሪካ',
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
			index => ['ሀ', 'ለ', 'ⶀ', 'መ', 'ᎀ', 'ᎁ', 'ᎃ', 'ⶁ', 'ረ', 'ⶂ', 'ሰ', 'ሸ', 'ⶄ', 'ቈ', 'ቐ', 'ቘ', 'ᎄ', 'ᎅ', 'ᎇ', 'ⶅ', 'ቨ', 'ⶆ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'ⶉ', 'ⶊ', 'ከ', 'ኰ', 'ዀ', 'ወ', 'ዐ', 'ⶋ', 'ዠ', 'ደ', 'ⶌ', 'ዸ', 'ጀ', 'ⶎ', 'ጐ', 'ጘ', 'ⶓ', 'ⶕ', 'ⶖ', 'ⶏ', 'ጨ', 'ⶐ', 'ⶑ', 'ጸ', 'ፈ', 'ᎈ', 'ᎉ', 'ᎋ', 'ፐ', 'ᎍ', 'ᎎ', 'ᎏ', 'ፘ', 'ⶠ', 'ⶢ', 'ⶣ', 'ⶤ', 'ⶦ', 'ⶨ', 'ⶩ', 'ⶫ', 'ⶬ', 'ⶮ', 'ⶰ', 'ⶱ', 'ⶳ', 'ⶴ', 'ⶶ', 'ⶸ', 'ⶹ', 'ⶻ', 'ⶼ', 'ⶾ', 'ⷀ', 'ⷁ', 'ⷃ', 'ⷄ', 'ⷆ', 'ⷈ', 'ⷉ', 'ⷋ', 'ⷌ', 'ⷎ', 'ⷐ', 'ⷑ', 'ⷓ', 'ⷔ', 'ⷖ', 'ⷘ', 'ⷙ', 'ⷛ', 'ⷜ', 'ⷝ'],
			main => qr{[፟ ፡ ፣ ፤ ፥ ፦ ፧ ። ፠ ፨ ᎐ ᎑ ᎒ ᎓ ᎔ ᎕ ᎖ ᎗ ᎘ ᎙ ፲ ፳ ፴ ፵ ፶ ፷ ፸ ፹ ፺ ፻ ፼ ሀ ሁ ሂ ሃ ሄ ህ ሆ ሇ ለ ሉ ሊ ላ ሌ ል ሎ ሏ ⶀ ሐ ሑ ሒ ሓ ሔ ሕ ሖ ሗ መ ሙ ሚ ማ ሜ ም ሞ ሟ ᎀ ᎁ ᎂ ᎃ ⶁ ሠ ሡ ሢ ሣ ሤ ሥ ሦ ሧ ረ ሩ ሪ ራ ሬ ር ሮ ሯ ⶂ ሰ ሱ ሲ ሳ ሴ ስ ሶ ሷ ⶃ ሸ ሹ ሺ ሻ ሼ ሽ ሾ ሿ ⶄ ቀ ቁ ቂ ቃ ቄ ቅ ቆ ቇ ቈ ቊ ቋ ቌ ቍ ቐ ቑ ቒ ቓ ቔ ቕ ቖ ቘ ቚ ቛ ቜ ቝ በ ቡ ቢ ባ ቤ ብ ቦ ቧ ᎄ ᎅ ᎆ ᎇ ⶅ ቨ ቩ ቪ ቫ ቬ ቭ ቮ ቯ ተ ቱ ቲ ታ ቴ ት ቶ ቷ ⶆ ቸ ቹ ቺ ቻ ቼ ች ቾ ቿ ⶇ ኀ ኁ ኂ ኃ ኄ ኅ ኆ ኇ ኈ ኊ ኋ ኌ ኍ ነ ኑ ኒ ና ኔ ን ኖ ኗ ⶈ ኘ ኙ ኚ ኛ ኜ ኝ ኞ ኟ ⶉ አ ኡ ኢ ኣ ኤ እ ኦ ኧ ⶊ ከ ኩ ኪ ካ ኬ ክ ኮ ኯ ኰ ኲ ኳ ኴ ኵ ኸ ኹ ኺ ኻ ኼ ኽ ኾ ዀ ዂ ዃ ዄ ዅ ወ ዉ ዊ ዋ ዌ ው ዎ ዏ ዐ ዑ ዒ ዓ ዔ ዕ ዖ ዘ ዙ ዚ ዛ ዜ ዝ ዞ ዟ ⶋ ዠ ዡ ዢ ዣ ዤ ዥ ዦ ዧ የ ዩ ዪ ያ ዬ ይ ዮ ዯ ደ ዱ ዲ ዳ ዴ ድ ዶ ዷ ⶌ ዸ ዹ ዺ ዻ ዼ ዽ ዾ ዿ ⶍ ጀ ጁ ጂ ጃ ጄ ጅ ጆ ጇ ⶎ ገ ጉ ጊ ጋ ጌ ግ ጎ ጏ ጐ ጒ ጓ ጔ ጕ ጘ ጙ ጚ ጛ ጜ ጝ ጞ ጟ ⶓ ⶔ ⶕ ⶖ ጠ ጡ ጢ ጣ ጤ ጥ ጦ ጧ ⶏ ጨ ጩ ጪ ጫ ጬ ጭ ጮ ጯ ⶐ ጰ ጱ ጲ ጳ ጴ ጵ ጶ ጷ ⶑ ጸ ጹ ጺ ጻ ጼ ጽ ጾ ጿ ፀ ፁ ፂ ፃ ፄ ፅ ፆ ፇ ፈ ፉ ፊ ፋ ፌ ፍ ፎ ፏ ᎈ ᎉ ᎊ ᎋ ፐ ፑ ፒ ፓ ፔ ፕ ፖ ፗ ᎌ ᎍ ᎎ ᎏ ⶒ ፘ ፙ ፚ ⶠ ⶡ ⶢ ⶣ ⶤ ⶥ ⶦ ⶨ ⶩ ⶪ ⶫ ⶬ ⶭ ⶮ ⶰ ⶱ ⶲ ⶳ ⶴ ⶵ ⶶ ⶸ ⶹ ⶺ ⶻ ⶼ ⶽ ⶾ ⷀ ⷁ ⷂ ⷃ ⷄ ⷅ ⷆ ⷈ ⷉ ⷊ ⷋ ⷌ ⷍ ⷎ ⷐ ⷑ ⷒ ⷓ ⷔ ⷕ ⷖ ⷘ ⷙ ⷚ ⷛ ⷜ ⷝ ⷞ]},
		};
	},
EOT
: sub {
		return { index => ['ሀ', 'ለ', 'ⶀ', 'መ', 'ᎀ', 'ᎁ', 'ᎃ', 'ⶁ', 'ረ', 'ⶂ', 'ሰ', 'ሸ', 'ⶄ', 'ቈ', 'ቐ', 'ቘ', 'ᎄ', 'ᎅ', 'ᎇ', 'ⶅ', 'ቨ', 'ⶆ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'ⶉ', 'ⶊ', 'ከ', 'ኰ', 'ዀ', 'ወ', 'ዐ', 'ⶋ', 'ዠ', 'ደ', 'ⶌ', 'ዸ', 'ጀ', 'ⶎ', 'ጐ', 'ጘ', 'ⶓ', 'ⶕ', 'ⶖ', 'ⶏ', 'ጨ', 'ⶐ', 'ⶑ', 'ጸ', 'ፈ', 'ᎈ', 'ᎉ', 'ᎋ', 'ፐ', 'ᎍ', 'ᎎ', 'ᎏ', 'ፘ', 'ⶠ', 'ⶢ', 'ⶣ', 'ⶤ', 'ⶦ', 'ⶨ', 'ⶩ', 'ⶫ', 'ⶬ', 'ⶮ', 'ⶰ', 'ⶱ', 'ⶳ', 'ⶴ', 'ⶶ', 'ⶸ', 'ⶹ', 'ⶻ', 'ⶼ', 'ⶾ', 'ⷀ', 'ⷁ', 'ⷃ', 'ⷄ', 'ⷆ', 'ⷈ', 'ⷉ', 'ⷋ', 'ⷌ', 'ⷎ', 'ⷐ', 'ⷑ', 'ⷓ', 'ⷔ', 'ⷖ', 'ⷘ', 'ⷙ', 'ⷛ', 'ⷜ', 'ⷝ'], };
},
);


has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'ethi',
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
				'currency' => q(የብራዚል ሪል),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(የቻይና ዩአን ረንሚንቢ),
			},
		},
		'ERN' => {
			symbol => 'Nfk',
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
					abbreviated => {
						nonleap => [
							'ጃንዩ',
							'ፌብሩ',
							'ማርች',
							'ኤፕረ',
							'ሜይ',
							'ጁን',
							'ጁላይ',
							'ኦገስ',
							'ሴፕቴ',
							'ኦክተ',
							'ኖቬም',
							'ዲሴም'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ጃንዩወሪ',
							'ፌብሩወሪ',
							'ማርች',
							'ኤፕረል',
							'ሜይ',
							'ጁን',
							'ጁላይ',
							'ኦገስት',
							'ሴፕቴምበር',
							'ኦክተውበር',
							'ኖቬምበር',
							'ዲሴምበር'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ጃ',
							'ፌ',
							'ማ',
							'ኤ',
							'ሜ',
							'ጁ',
							'ጁ',
							'ኦ',
							'ሴ',
							'ኦ',
							'ኖ',
							'ዲ'
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
						mon => 'ሰኖ',
						tue => 'ታላሸ',
						wed => 'ኣረር',
						thu => 'ከሚሽ',
						fri => 'ጅምዓ',
						sat => 'ሰ/ን',
						sun => 'ሰ/ዓ'
					},
					wide => {
						mon => 'ሰኖ',
						tue => 'ታላሸኖ',
						wed => 'ኣረርባዓ',
						thu => 'ከሚሽ',
						fri => 'ጅምዓት',
						sat => 'ሰንበት ንኢሽ',
						sun => 'ሰንበት ዓባይ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ሰ',
						tue => 'ታ',
						wed => 'ኣ',
						thu => 'ከ',
						fri => 'ጅ',
						sat => 'ሰ',
						sun => 'ሰ'
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
					'am' => q{ቀደም ሰርምዕል},
					'pm' => q{ሓቆ ስርምዕል},
				},
				'wide' => {
					'am' => q{ቀደም ሰርምዕል},
					'pm' => q{ሓቆ ስርምዕል},
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
			'full' => q{EEEE፡ dd MMMM ዮም y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE፡ dd MMMM ዮም y G},
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
