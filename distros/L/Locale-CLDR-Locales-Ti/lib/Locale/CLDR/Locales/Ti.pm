=head1

Locale::CLDR::Locales::Ti - Package for language Tigrinya

=cut

package Locale::CLDR::Locales::Ti;
# This file auto generated from Data\common\main\ti.xml
#	on Fri 29 Apr  7:28:55 pm GMT

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
				'af' => 'አፍሪቃንሰኛ',
 				'am' => 'አምሐረኛ',
 				'ar' => 'ዓረበኛ',
 				'az' => 'አዜርባይጃንኛ',
 				'be' => 'ቤላራሻኛ',
 				'bg' => 'ቡልጋሪኛ',
 				'bn' => 'በንጋሊኛ',
 				'br' => 'ብሬቶን',
 				'bs' => 'ቦስኒያን',
 				'ca' => 'ካታላን',
 				'cs' => 'ቼክኛ',
 				'cy' => 'ወልሽ',
 				'da' => 'ዴኒሽ',
 				'de' => 'ጀርመን',
 				'el' => 'ግሪከኛ',
 				'en' => 'እንግሊዝኛ',
 				'eo' => 'ኤስፐራንቶ',
 				'es' => 'ስፓኒሽ',
 				'et' => 'ኤስቶኒአን',
 				'eu' => 'ባስክኛ',
 				'fa' => 'ፐርሲያኛ',
 				'fi' => 'ፊኒሽ',
 				'fil' => 'ታጋሎገኛ',
 				'fo' => 'ፋሮኛ',
 				'fr' => 'ፈረንሳይኛ',
 				'fy' => 'ፍሪሰኛ',
 				'ga' => 'አይሪሽ',
 				'gd' => 'እስኮትስ ጌልክኛ',
 				'gl' => 'ጋለቪኛ',
 				'gn' => 'ጓራኒ',
 				'gu' => 'ጉጃራቲኛ',
 				'he' => 'ዕብራስጥ',
 				'hi' => 'ሕንደኛ',
 				'hr' => 'ክሮሽያንኛ',
 				'hu' => 'ሀንጋሪኛ',
 				'ia' => 'ኢንቴር ቋንቋ',
 				'id' => 'እንዶኑሲኛ',
 				'is' => 'አይስላንደኛ',
 				'it' => 'ጣሊያንኛ',
 				'ja' => 'ጃፓንኛ',
 				'jv' => 'ጃቫንኛ',
 				'ka' => 'ጊዮርጊያኛ',
 				'kn' => 'ካማደኛ',
 				'ko' => 'ኮሪያኛ',
 				'ku' => 'ኩርድሽ',
 				'ky' => 'ኪሩጋዚ',
 				'la' => 'ላቲንኛ',
 				'lt' => 'ሊቱአኒየን',
 				'lv' => 'ላቲቪያን',
 				'mk' => 'ማክዶኒኛ',
 				'ml' => 'ማላያላምኛ',
 				'mr' => 'ማራቲኛ',
 				'ms' => 'ማላይኛ',
 				'mt' => 'ማልቲስኛ',
 				'ne' => 'ኔፖሊኛ',
 				'nl' => 'ደች',
 				'nn' => 'ኖርዌይኛ (ናይ ኝኖርስክ)',
 				'no' => 'ኖርዌጂያን',
 				'oc' => 'ኦኪታንኛ',
 				'or' => 'ኦሪያ',
 				'pa' => 'ፑንጃቢኛ',
 				'pl' => 'ፖሊሽ',
 				'ps' => 'ፓሽቶ',
 				'pt' => 'ፖርቱጋሊኛ',
 				'pt_BR' => 'ፖርቱጋልኛ (ናይ ብራዚል)',
 				'pt_PT' => 'ፖርቱጋልኛ (ናይ ፖርቱጋል)',
 				'ro' => 'ሮማኒያን',
 				'ru' => 'ራሽኛ',
 				'sh' => 'ሰርቦ- ክሮዊታን',
 				'si' => 'ስንሃልኛ',
 				'sk' => 'ስሎቨክኛ',
 				'sl' => 'ስቁቪኛ',
 				'sq' => 'አልቤኒኛ',
 				'sr' => 'ሰርቢኛ',
 				'st' => 'ሰሴቶ',
 				'su' => 'ሱዳንኛ',
 				'sv' => 'ስዊድንኛ',
 				'sw' => 'ሰዋሂሊኛ',
 				'ta' => 'ታሚልኛ',
 				'te' => 'ተሉጉኛ',
 				'th' => 'ታይኛ',
 				'ti' => 'ትግርኛ',
 				'tk' => 'ናይ ቱርኪ ሰብዓይ (ቱርካዊ)',
 				'tlh' => 'ክሊንግኦንኛ',
 				'tr' => 'ቱርከኛ',
 				'tw' => 'ትዊ',
 				'uk' => 'ዩክረኒኛ',
 				'ur' => 'ኡርዱኛ',
 				'uz' => 'ኡዝበክኛ',
 				'vi' => 'ቪትናምኛ',
 				'xh' => 'ዞሳኛ',
 				'yi' => 'ዪዲሽ',
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
			'Ethi' => 'ፊደል',
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
			'001' => 'ዓለም',
 			'002' => 'አፍሪካ',
 			'005' => 'ደቡባዊ አሜሪካ',
 			'009' => 'ኦሽኒያ',
 			'011' => 'ምዕራባዊ አፍሪካ',
 			'014' => 'ምስራቃዊ አፍሪካ',
 			'015' => 'ሰሜናዊ አፍሪካ',
 			'017' => 'መካከለኛ አፍሪካ',
 			'018' => 'ደቡባዊ አፍሪካ',
 			'019' => 'አሜሪካዎች',
 			'021' => 'ሰሜናዊ አሜሪካ',
 			'029' => 'ካሪቢያን',
 			'034' => 'ምሥራቃዊ እስያ',
 			'039' => 'ደቡባዊ አውሮፓ',
 			'053' => 'አውስትራሊያ እና ኒው ዚላንድ',
 			'054' => 'ሜላኔሲያ',
 			'061' => 'ፖሊኔዢያ',
 			'142' => 'እስያ',
 			'145' => 'ምዕራባዊ እስያ',
 			'150' => 'አውሮፓ',
 			'151' => 'ምስራቃዊ አውሮፓ',
 			'154' => 'ሰሜናዊ አውሮፓ',
 			'155' => 'ምዕራባዊ አውሮፓ',
 			'AD' => 'አንዶራ',
 			'AE' => 'የተባበሩት አረብ ኤምሬትስ',
 			'AF' => 'አፍጋኒስታን',
 			'AG' => 'አንቲጓ እና ባሩዳ',
 			'AI' => 'አንጉኢላ',
 			'AL' => 'አልባኒያ',
 			'AM' => 'አርሜኒያ',
 			'AO' => 'አንጐላ',
 			'AQ' => 'አንታርክቲካ',
 			'AR' => 'አርጀንቲና',
 			'AS' => 'የአሜሪካ ሳሞአ',
 			'AT' => 'ኦስትሪያ',
 			'AU' => 'አውስትሬሊያ',
 			'AW' => 'አሩባ',
 			'AX' => 'የአላንድ ደሴቶች',
 			'AZ' => 'አዘርባጃን',
 			'BA' => 'ቦስኒያ እና ሄርዞጎቪኒያ',
 			'BB' => 'ባርቤዶስ',
 			'BD' => 'ባንግላዲሽ',
 			'BE' => 'ቤልጄም',
 			'BF' => 'ቡርኪና ፋሶ',
 			'BG' => 'ቡልጌሪያ',
 			'BH' => 'ባህሬን',
 			'BI' => 'ብሩንዲ',
 			'BJ' => 'ቤኒን',
 			'BM' => 'ቤርሙዳ',
 			'BN' => 'ብሩኒ',
 			'BO' => 'ቦሊቪያ',
 			'BR' => 'ብራዚል',
 			'BS' => 'ባሃማስ',
 			'BT' => 'ቡህታን',
 			'BV' => 'የቦውቬት ደሴት',
 			'BW' => 'ቦትስዋና',
 			'BY' => 'ቤላሩስ',
 			'BZ' => 'ቤሊዘ',
 			'CA' => 'ካናዳ',
 			'CC' => 'ኮኮስ ኬሊንግ ደሴቶች',
 			'CD' => 'ኮንጎ',
 			'CF' => 'የመካከለኛው አፍሪካ ሪፐብሊክ',
 			'CG' => 'ኮንጐ',
 			'CH' => 'ስዊዘርላንድ',
 			'CI' => 'ኮት ዲቯር',
 			'CK' => 'ኩክ ደሴቶች',
 			'CL' => 'ቺሊ',
 			'CM' => 'ካሜሩን',
 			'CN' => 'ቻይና',
 			'CO' => 'ኮሎምቢያ',
 			'CR' => 'ኮስታ ሪካ',
 			'CU' => 'ኩባ',
 			'CV' => 'ኬፕ ቬርዴ',
 			'CX' => 'የገና ደሴቶች',
 			'CY' => 'ሳይፕረስ',
 			'CZ' => 'ቼክ ሪፑብሊክ',
 			'DE' => 'ጀርመን',
 			'DJ' => 'ጂቡቲ',
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
 			'FK' => 'የፎልክላንድ ደሴቶች',
 			'FM' => 'ሚክሮኔዢያ',
 			'FO' => 'የፋሮይ ደሴቶች',
 			'FR' => 'ፈረንሳይ',
 			'GA' => 'ጋቦን',
 			'GB' => 'እንግሊዝ',
 			'GD' => 'ግሬናዳ',
 			'GE' => 'ጆርጂያ',
 			'GF' => 'የፈረንሳይ ጉዊአና',
 			'GH' => 'ጋና',
 			'GI' => 'ጊብራልታር',
 			'GL' => 'ግሪንላንድ',
 			'GM' => 'ጋምቢያ',
 			'GN' => 'ጊኒ',
 			'GP' => 'ጉዋደሉፕ',
 			'GQ' => 'ኢኳቶሪያል ጊኒ',
 			'GR' => 'ግሪክ',
 			'GS' => 'ደቡብ ጆርጂያ እና የደቡድ ሳንድዊች ደሴቶች',
 			'GT' => 'ጉዋቲማላ',
 			'GU' => 'ጉዋም',
 			'GW' => 'ቢሳዎ',
 			'GY' => 'ጉያና',
 			'HK' => 'ሆንግ ኮንግ',
 			'HM' => 'የኧርድ እና የማክዶናልድ ደሴቶች',
 			'HN' => 'ሆንዱራስ',
 			'HR' => 'ክሮኤሽያ',
 			'HT' => 'ሀይቲ',
 			'HU' => 'ሀንጋሪ',
 			'ID' => 'ኢንዶኔዢያ',
 			'IE' => 'አየርላንድ',
 			'IL' => 'እስራኤል',
 			'IN' => 'ህንድ',
 			'IO' => 'የብሪታኒያ ህንድ ውቂያኖስ ግዛት',
 			'IQ' => 'ኢራቅ',
 			'IR' => 'ኢራን',
 			'IS' => 'አይስላንድ',
 			'IT' => 'ጣሊያን',
 			'JM' => 'ጃማይካ',
 			'JO' => 'ጆርዳን',
 			'JP' => 'ጃፓን',
 			'KE' => 'ኬንያ',
 			'KH' => 'ካምቦዲያ',
 			'KI' => 'ኪሪባቲ',
 			'KM' => 'ኮሞሮስ',
 			'KN' => 'ቅዱስ ኪትስ እና ኔቪስ',
 			'KP' => 'ሰሜን ኮሪያ',
 			'KR' => 'ደቡብ ኮሪያ',
 			'KW' => 'ክዌት',
 			'KY' => 'ካይማን ደሴቶች',
 			'LA' => 'ላኦስ',
 			'LB' => 'ሊባኖስ',
 			'LC' => 'ሴንት ሉቺያ',
 			'LI' => 'ሊችተንስታይን',
 			'LK' => 'ሲሪላንካ',
 			'LR' => 'ላይቤሪያ',
 			'LS' => 'ሌሶቶ',
 			'LT' => 'ሊቱዌኒያ',
 			'LU' => 'ሉክሰምበርግ',
 			'LV' => 'ላትቪያ',
 			'LY' => 'ሊቢያ',
 			'MA' => 'ሞሮኮ',
 			'MC' => 'ሞናኮ',
 			'MD' => 'ሞልዶቫ',
 			'MG' => 'ማዳጋስካር',
 			'MH' => 'ማርሻል አይላንድ',
 			'MK' => 'ማከዶኒያ',
 			'ML' => 'ማሊ',
 			'MM' => 'ማያንማር',
 			'MN' => 'ሞንጎሊያ',
 			'MO' => 'ማካዎ',
 			'MP' => 'የሰሜናዊ ማሪያና ደሴቶች',
 			'MQ' => 'ማርቲኒክ',
 			'MR' => 'ሞሪቴኒያ',
 			'MS' => 'ሞንትሴራት',
 			'MT' => 'ማልታ',
 			'MU' => 'ማሩሸስ',
 			'MV' => 'ማልዲቭስ',
 			'MW' => 'ማላዊ',
 			'MX' => 'ሜክሲኮ',
 			'MY' => 'ማሌዢያ',
 			'MZ' => 'ሞዛምቢክ',
 			'NA' => 'ናሚቢያ',
 			'NC' => 'ኒው ካሌዶኒያ',
 			'NE' => 'ኒጀር',
 			'NF' => 'ኖርፎልክ ደሴት',
 			'NG' => 'ናይጄሪያ',
 			'NI' => 'ኒካራጓ',
 			'NL' => 'ኔዘርላንድ',
 			'NO' => 'ኖርዌ',
 			'NP' => 'ኔፓል',
 			'NR' => 'ናኡሩ',
 			'NU' => 'ኒኡይ',
 			'NZ' => 'ኒው ዚላንድ',
 			'OM' => 'ኦማን',
 			'PA' => 'ፓናማ',
 			'PE' => 'ፔሩ',
 			'PF' => 'የፈረንሳይ ፖሊኔዢያ',
 			'PG' => 'ፓፑዋ ኒው ጊኒ',
 			'PH' => 'ፊሊፒንስ',
 			'PK' => 'ፓኪስታን',
 			'PL' => 'ፖላንድ',
 			'PM' => 'ቅዱስ ፒዬር እና ሚኩኤሎን',
 			'PN' => 'ፒትካኢርን',
 			'PR' => 'ፖርታ ሪኮ',
 			'PS' => 'የፍልስጤም ግዛት',
 			'PT' => 'ፖርቱጋል',
 			'PW' => 'ፓላው',
 			'PY' => 'ፓራጓይ',
 			'QA' => 'ኳታር',
 			'QO' => 'ወጣ ያለ ኦሽኒያ',
 			'RE' => 'ሪዩኒየን',
 			'RO' => 'ሮሜኒያ',
 			'RU' => 'ራሺያ',
 			'RW' => 'ሩዋንዳ',
 			'SA' => 'ሳውድአረቢያ',
 			'SB' => 'ሰሎሞን ደሴት',
 			'SC' => 'ሲሼልስ',
 			'SD' => 'ሱዳን',
 			'SE' => 'ስዊድን',
 			'SG' => 'ሲንጋፖር',
 			'SH' => 'ሴንት ሄለና',
 			'SI' => 'ስሎቬኒያ',
 			'SJ' => 'የስቫልባርድ እና ዣን ማየን ደሴቶች',
 			'SK' => 'ስሎቫኪያ',
 			'SL' => 'ሴራሊዮን',
 			'SM' => 'ሳን ማሪኖ',
 			'SN' => 'ሴኔጋል',
 			'SO' => 'ሱማሌ',
 			'SR' => 'ሱሪናም',
 			'ST' => 'ሳኦ ቶሜ እና ፕሪንሲፔ',
 			'SV' => 'ኤል ሳልቫዶር',
 			'SY' => 'ሲሪያ',
 			'SZ' => 'ሱዋዚላንድ',
 			'TC' => 'የቱርኮችና የካኢኮስ ደሴቶች',
 			'TD' => 'ቻድ',
 			'TF' => 'የፈረንሳይ ደቡባዊ ግዛቶች',
 			'TG' => 'ቶጐ',
 			'TH' => 'ታይላንድ',
 			'TJ' => 'ታጃኪስታን',
 			'TK' => 'ቶክላው',
 			'TL' => 'ምስራቅ ቲሞር',
 			'TM' => 'ቱርክሜኒስታን',
 			'TN' => 'ቱኒዚያ',
 			'TO' => 'ቶንጋ',
 			'TR' => 'ቱርክ',
 			'TT' => 'ትሪኒዳድ እና ቶባጎ',
 			'TV' => 'ቱቫሉ',
 			'TW' => 'ታይዋን',
 			'TZ' => 'ታንዛኒያ',
 			'UA' => 'ዩክሬን',
 			'UG' => 'ዩጋንዳ',
 			'UM' => 'የአሜሪካ ራቅ ያሉ አናሳ ደሴቶች',
 			'US' => 'አሜሪካ',
 			'UY' => 'ኡራጓይ',
 			'UZ' => 'ዩዝበኪስታን',
 			'VA' => 'ቫቲካን',
 			'VC' => 'ቅዱስ ቪንሴንት እና ግሬናዲንስ',
 			'VE' => 'ቬንዙዌላ',
 			'VG' => 'የእንግሊዝ ድንግል ደሴቶች',
 			'VI' => 'የአሜሪካ ቨርጂን ደሴቶች',
 			'VN' => 'ቬትናም',
 			'VU' => 'ቫኑአቱ',
 			'WF' => 'ዋሊስ እና ፉቱና ደሴቶች',
 			'WS' => 'ሳሞአ',
 			'YE' => 'የመን',
 			'YT' => 'ሜይኦቴ',
 			'ZA' => 'ደቡብ አፍሪካ',
 			'ZM' => 'ዛምቢያ',
 			'ZW' => 'ዚምቧቤ',

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
			auxiliary => qr{(?^u:[᎐ ᎑ ᎒ ᎓ ᎔ ᎕ ᎖ ᎗ ᎘ ᎙ ሇ ⶀ ᎀ ᎁ ᎂ ᎃ ⶁ ⶂ ⶃ ⶄ ቇ ᎄ ᎅ ᎆ ᎇ ⶅ ⶆ ⶇ ኇ ⶈ ⶉ ⶊ ኯ ዏ ⶋ ዯ ⶌ ዸ ዹ ዺ ዻ ዼ ዽ ዾ ዿ ⶍ ⶎ ጏ ጘ ጙ ጚ ጛ ጜ ጝ ጞ ጟ ⶓ ⶔ ⶕ ⶖ ⶏ ⶐ ⶑ ᎈ ᎉ ᎊ ᎋ ᎌ ᎍ ᎎ ᎏ ⶒ ፘ ፙ ፚ ⶠ ⶡ ⶢ ⶣ ⶤ ⶥ ⶦ ⶨ ⶩ ⶪ ⶫ ⶬ ⶭ ⶮ ⶰ ⶱ ⶲ ⶳ ⶴ ⶵ ⶶ ⶸ ⶹ ⶺ ⶻ ⶼ ⶽ ⶾ ⷀ ⷁ ⷂ ⷃ ⷄ ⷅ ⷆ ⷈ ⷉ ⷊ ⷋ ⷌ ⷍ ⷎ ⷐ ⷑ ⷒ ⷓ ⷔ ⷕ ⷖ ⷘ ⷙ ⷚ ⷛ ⷜ ⷝ ⷞ])},
			index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ሸ', 'ቀ', 'ቈ', 'ቐ', 'ቘ', 'በ', 'ቨ', 'ተ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'አ', 'ከ', 'ኰ', 'ኸ', 'ዀ', 'ወ', 'ዐ', 'ዘ', 'ዠ', 'የ', 'ደ', 'ጀ', 'ገ', 'ጐ', 'ጠ', 'ጨ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'],
			main => qr{(?^u:[፟ ሀ-ሆ ለ-ቆ ቈ ቊ-ቍ ቐ-ቖ ቘ ቚ-ቝ በ-ኆ ኈ ኊ-ኍ ነ-ኮ ኰ ኲ-ኵ ኸ-ኾ ዀ ዂ-ዅ ወ-ዎ ዐ-ዖ ዘ-ዮ ደ-ዷ ጀ-ጎ ጐ ጒ-ጕ ጠ-ፗ])},
		};
	},
EOT
: sub {
		return { index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ሸ', 'ቀ', 'ቈ', 'ቐ', 'ቘ', 'በ', 'ቨ', 'ተ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'አ', 'ከ', 'ኰ', 'ኸ', 'ዀ', 'ወ', 'ዐ', 'ዘ', 'ዠ', 'የ', 'ደ', 'ጀ', 'ገ', 'ጐ', 'ጠ', 'ጨ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'], };
},
);


has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
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
		'ETB' => {
			symbol => 'Br',
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
					wide => {
						mon => 'ሰኑይ',
						tue => 'ሠሉስ',
						wed => 'ረቡዕ',
						thu => 'ኃሙስ',
						fri => 'ዓርቢ',
						sat => 'ቀዳም',
						sun => 'ሰንበት'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ሰ',
						tue => 'ሠ',
						wed => 'ረ',
						thu => 'ኃ',
						fri => 'ዓ',
						sat => 'ቀ',
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
					'am' => q{ንጉሆ ሰዓተ},
					'pm' => q{ድሕር ሰዓት},
				},
				'wide' => {
					'am' => q{ንጉሆ ሰዓተ},
					'pm' => q{ድሕር ሰዓት},
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
			'full' => q{EEEE፣ dd MMMM መዓልቲ y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE፣ dd MMMM መዓልቲ y G},
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
		'generic' => {
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
		},
		'gregorian' => {
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
	 } }
);
no Moo;

1;

# vim: tabstop=4
