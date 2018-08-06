=head1

Locale::CLDR::Locales::Ti - Package for language Tigrinya

=cut

package Locale::CLDR::Locales::Ti;
# This file auto generated from Data\common\main\ti.xml
#	on Sun  5 Aug  6:24:22 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
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
 				'en_GB@alt=short' => 'እንግሊዝኛ (GB)',
 				'en_US@alt=short' => 'እንግሊዝኛ (US)',
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
 			'AC' => 'አሴንሽን ደሴት',
 			'AD' => 'አንዶራ',
 			'AE' => 'ሕቡራት ኢማራት ዓረብ',
 			'AF' => 'አፍጋኒስታን',
 			'AG' => 'ኣንቲጓን ባሩዳን',
 			'AI' => 'አንጉኢላ',
 			'AL' => 'አልባኒያ',
 			'AM' => 'አርሜኒያ',
 			'AO' => 'አንጐላ',
 			'AQ' => 'አንታርክቲካ',
 			'AR' => 'አርጀንቲና',
 			'AS' => 'ናይ ኣሜሪካ ሳሞኣ',
 			'AT' => 'ኦስትሪያ',
 			'AU' => 'አውስትሬሊያ',
 			'AW' => 'አሩባ',
 			'AX' => 'ደሴታት ኣላንድ',
 			'AZ' => 'አዘርባጃን',
 			'BA' => 'ቦዝንያን ሄርዘጎቪናን',
 			'BB' => 'ባርቤዶስ',
 			'BD' => 'ባንግላዲሽ',
 			'BE' => 'ቤልጄም',
 			'BF' => 'ቡርኪና ፋሶ',
 			'BG' => 'ቡልጌሪያ',
 			'BH' => 'ባህሬን',
 			'BI' => 'ብሩንዲ',
 			'BJ' => 'ቤኒን',
 			'BL' => 'ቅዱስ ባርተለሚይ',
 			'BM' => 'ቤርሙዳ',
 			'BN' => 'ብሩኒ',
 			'BO' => 'ቦሊቪያ',
 			'BQ' => 'ካሪቢያን ኔዘርላንድስ',
 			'BR' => 'ብራዚል',
 			'BS' => 'ባሃማስ',
 			'BT' => 'ቡህታን',
 			'BV' => 'ደሴታት ቦውቬት',
 			'BW' => 'ቦትስዋና',
 			'BY' => 'ቤላሩስ',
 			'BZ' => 'ቤሊዘ',
 			'CA' => 'ካናዳ',
 			'CC' => 'ኮኮስ ኬሊንግ ደሴቶች',
 			'CD' => 'ኮንጎ',
 			'CF' => 'ማእከላይ ኣፍሪቃ ሪፓብሊክ',
 			'CG' => 'ኮንጎ ሪፓብሊክ',
 			'CH' => 'ስዊዘርላንድ',
 			'CI' => 'ኮት ዲቯር',
 			'CI@alt=variant' => 'አይቮሪ ኮስት',
 			'CK' => 'ደሴታት ኩክ',
 			'CL' => 'ቺሊ',
 			'CM' => 'ካሜሩን',
 			'CN' => 'ቻይና',
 			'CO' => 'ኮሎምቢያ',
 			'CP' => 'ክሊፐርቶን ደሴት',
 			'CR' => 'ኮስታ ሪካ',
 			'CU' => 'ኩባ',
 			'CV' => 'ኬፕ ቬርዴ',
 			'CW' => 'ኩራካዎ',
 			'CX' => 'ደሴታት ክሪስትማስ',
 			'CY' => 'ሳይፕረስ',
 			'CZ' => 'ቼክ ሪፓብሊክ',
 			'CZ@alt=variant' => 'CZ',
 			'DE' => 'ጀርመን',
 			'DG' => 'ዲየጎ ጋርሺያ',
 			'DJ' => 'ጂቡቲ',
 			'DK' => 'ዴንማርክ',
 			'DM' => 'ዶሚኒካ',
 			'DO' => 'ዶመኒካ ሪፓብሊክ',
 			'DZ' => 'አልጄሪያ',
 			'EA' => 'ሲውታን ሜሊላን',
 			'EC' => 'ኢኳዶር',
 			'EE' => 'ኤስቶኒያ',
 			'EG' => 'ግብጽ',
 			'EH' => 'ምዕራባዊ ሳህራ',
 			'ER' => 'ኤርትራ',
 			'ES' => 'ስፔን',
 			'ET' => 'ኢትዮጵያ',
 			'FI' => 'ፊንላንድ',
 			'FJ' => 'ፊጂ',
 			'FK' => 'ደሴታት ፎክላንድ',
 			'FM' => 'ሚክሮኔዢያ',
 			'FO' => 'ደሴታት ፋራኦ',
 			'FR' => 'ፈረንሳይ',
 			'GA' => 'ጋቦን',
 			'GB' => 'እንግሊዝ',
 			'GB@alt=short' => 'ዩኬይ',
 			'GD' => 'ግሬናዳ',
 			'GE' => 'ጆርጂያ',
 			'GF' => 'ናይ ፈረንሳይ ጉይና',
 			'GG' => 'ገርንሲ',
 			'GH' => 'ጋና',
 			'GI' => 'ጊብራልታር',
 			'GL' => 'ግሪንላንድ',
 			'GM' => 'ጋምቢያ',
 			'GN' => 'ጊኒ',
 			'GP' => 'ጉዋደሉፕ',
 			'GQ' => 'ኢኳቶሪያል ጊኒ',
 			'GR' => 'ግሪክ',
 			'GS' => 'ደሴታት ደቡብ ጆርጂያን ደቡድ ሳንድዊችን',
 			'GT' => 'ጉዋቲማላ',
 			'GU' => 'ጉዋም',
 			'GW' => 'ቢሳዎ',
 			'GY' => 'ጉያና',
 			'HK' => 'ሆንግ ኮንግ',
 			'HK@alt=short' => 'ሆንግ ኮንግ',
 			'HM' => 'ደሴታት ሀርድን ማክዶናልድን',
 			'HN' => 'ሆንዱራስ',
 			'HR' => 'ክሮኤሽያ',
 			'HT' => 'ሀይቲ',
 			'HU' => 'ሀንጋሪ',
 			'IC' => 'ደሴታት ካናሪ',
 			'ID' => 'ኢንዶኔዢያ',
 			'IE' => 'አየርላንድ',
 			'IL' => 'እስራኤል',
 			'IM' => 'አይል ኦፍ ማን',
 			'IN' => 'ህንዲ',
 			'IO' => 'ናይ ብሪጣንያ ህንዳዊ ውቅያኖስ ግዝኣት',
 			'IQ' => 'ኢራቅ',
 			'IR' => 'ኢራን',
 			'IS' => 'አይስላንድ',
 			'IT' => 'ጣሊያን',
 			'JE' => 'ጀርሲ',
 			'JM' => 'ጃማይካ',
 			'JO' => 'ጆርዳን',
 			'JP' => 'ጃፓን',
 			'KE' => 'ኬንያ',
 			'KG' => 'ኪርጂስታን',
 			'KH' => 'ካምቦዲያ',
 			'KI' => 'ኪሪባቲ',
 			'KM' => 'ኮሞሮስ',
 			'KN' => 'ቅዱስ ኪትስን ኔቪስን',
 			'KP' => 'ሰሜን ኮሪያ',
 			'KR' => 'ደቡብ ኮሪያ',
 			'KW' => 'ክዌት',
 			'KY' => 'ካይማን ደሴቶች',
 			'KZ' => 'ካዛኪስታን',
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
 			'ME' => 'ሞንቴኔግሮ',
 			'MF' => 'ሴንት ማርቲን',
 			'MG' => 'ማዳጋስካር',
 			'MH' => 'ማርሻል አይላንድ',
 			'MK' => 'ማከዶኒያ',
 			'MK@alt=variant' => 'መቄዶኒያ',
 			'ML' => 'ማሊ',
 			'MM' => 'ማያንማር',
 			'MN' => 'ሞንጎሊያ',
 			'MO' => 'ማካዎ',
 			'MO@alt=short' => 'ማካው',
 			'MP' => 'ደሴታት ሰሜናዊ ማሪያና',
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
 			'NL' => 'ኔዘርላንድስ',
 			'NO' => 'ኖርዌ',
 			'NP' => 'ኔፓል',
 			'NR' => 'ናኡሩ',
 			'NU' => 'ኒኡይ',
 			'NZ' => 'ኒው ዚላንድ',
 			'OM' => 'ኦማን',
 			'PA' => 'ፓናማ',
 			'PE' => 'ፔሩ',
 			'PF' => 'ናይ ፈረንሳይ ፖሊነዝያ',
 			'PG' => 'ፓፑዋ ኒው ጊኒ',
 			'PH' => 'ፊሊፒንስ',
 			'PK' => 'ፓኪስታን',
 			'PL' => 'ፖላንድ',
 			'PM' => 'ቅዱስ ፒዬርን ሚኩኤሎን',
 			'PN' => 'ፒትካኢርን',
 			'PR' => 'ፖርታ ሪኮ',
 			'PS' => 'ምምሕዳር ፍልስጤም',
 			'PS@alt=short' => 'ፍልስጤም',
 			'PT' => 'ፖርቱጋል',
 			'PW' => 'ፓላው',
 			'PY' => 'ፓራጓይ',
 			'QA' => 'ቀጠር',
 			'QO' => 'ወጣ ያለ ኦሽኒያ',
 			'RE' => 'ሪዩኒየን',
 			'RO' => 'ሮሜኒያ',
 			'RS' => 'ሰርቢያ',
 			'RU' => 'ራሺያ',
 			'RW' => 'ሩዋንዳ',
 			'SA' => 'ስዑዲ ዓረብ',
 			'SB' => 'ሰሎሞን ደሴት',
 			'SC' => 'ሲሼልስ',
 			'SD' => 'ሱዳን',
 			'SE' => 'ስዊድን',
 			'SG' => 'ሲንጋፖር',
 			'SH' => 'ሴንት ሄለና',
 			'SI' => 'ስሎቬኒያ',
 			'SJ' => 'ስቫልባርድን ዣን ማየን ደሴታት',
 			'SK' => 'ስሎቫኪያ',
 			'SL' => 'ሴራሊዮን',
 			'SM' => 'ሳን ማሪኖ',
 			'SN' => 'ሴኔጋል',
 			'SO' => 'ሱማሌ',
 			'SR' => 'ሱሪናም',
 			'SS' => 'ደቡብ ሱዳን',
 			'ST' => 'ሳኦ ቶሜን ፕሪንሲፔን',
 			'SV' => 'ኤል ሳልቫዶር',
 			'SX' => 'ሲንት ማርቲን',
 			'SY' => 'ሲሪያ',
 			'SZ' => 'ሱዋዚላንድ',
 			'TA' => 'ትሪስን ዳ ኩንሃ',
 			'TC' => 'ደሴታት ቱርክን ካይኮስን',
 			'TD' => 'ጫድ',
 			'TF' => 'ናይ ፈረንሳይ ደቡባዊ ግዝኣታት',
 			'TG' => 'ቶጐ',
 			'TH' => 'ታይላንድ',
 			'TJ' => 'ታጃኪስታን',
 			'TK' => 'ቶክላው',
 			'TL' => 'ምብራቕ ቲሞር',
 			'TM' => 'ቱርክሜኒስታን',
 			'TN' => 'ቱኒዚያ',
 			'TO' => 'ቶንጋ',
 			'TR' => 'ቱርክ',
 			'TT' => 'ትሪኒዳድን ቶባጎን',
 			'TV' => 'ቱቫሉ',
 			'TW' => 'ታይዋን',
 			'TZ' => 'ታንዛኒያ',
 			'UA' => 'ዩክሬን',
 			'UG' => 'ዩጋንዳ',
 			'UM' => 'ናይ ኣሜሪካ ፍንትት ዝበሉ ደሴታት',
 			'US' => 'አሜሪካ',
 			'US@alt=short' => 'ዩኤስ',
 			'UY' => 'ኡራጓይ',
 			'UZ' => 'ዩዝበኪስታን',
 			'VA' => 'ቫቲካን',
 			'VC' => 'ቅዱስ ቪንሴንትን ግሬናዲንስን',
 			'VE' => 'ቬንዙዌላ',
 			'VG' => 'ቨርጂን ደሴታት እንግሊዝ',
 			'VI' => 'ቨርጂን ደሴታት ኣሜሪካ',
 			'VN' => 'ቬትናም',
 			'VU' => 'ቫኑአቱ',
 			'WF' => 'ዋሊስን ፉቱናን',
 			'WS' => 'ሳሞአ',
 			'XK' => 'ኮሶቮ',
 			'YE' => 'የመን',
 			'YT' => 'ሜይኦቴ',
 			'ZA' => 'ደቡብ አፍሪካ',
 			'ZM' => 'ዛምቢያ',
 			'ZW' => 'ዚምቧቤ',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[᎐ ᎑ ᎒ ᎓ ᎔ ᎕ ᎖ ᎗ ᎘ ᎙ ሇ ⶀ ᎀ ᎁ ᎂ ᎃ ⶁ ⶂ ⶃ ⶄ ቇ ᎄ ᎅ ᎆ ᎇ ⶅ ⶆ ⶇ ኇ ⶈ ⶉ ⶊ ኯ ዏ ⶋ ዯ ⶌ ዸ ዹ ዺ ዻ ዼ ዽ ዾ ዿ ⶍ ⶎ ጏ ጘ ጙ ጚ ጛ ጜ ጝ ጞ ጟ ⶓ ⶔ ⶕ ⶖ ⶏ ⶐ ⶑ ᎈ ᎉ ᎊ ᎋ ᎌ ᎍ ᎎ ᎏ ⶒ ፘ ፙ ፚ ⶠ ⶡ ⶢ ⶣ ⶤ ⶥ ⶦ ⶨ ⶩ ⶪ ⶫ ⶬ ⶭ ⶮ ⶰ ⶱ ⶲ ⶳ ⶴ ⶵ ⶶ ⶸ ⶹ ⶺ ⶻ ⶼ ⶽ ⶾ ⷀ ⷁ ⷂ ⷃ ⷄ ⷅ ⷆ ⷈ ⷉ ⷊ ⷋ ⷌ ⷍ ⷎ ⷐ ⷑ ⷒ ⷓ ⷔ ⷕ ⷖ ⷘ ⷙ ⷚ ⷛ ⷜ ⷝ ⷞ]},
			index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ሸ', 'ቀ', 'ቈ', 'ቐ', 'ቘ', 'በ', 'ቨ', 'ተ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'አ', 'ከ', 'ኰ', 'ኸ', 'ዀ', 'ወ', 'ዐ', 'ዘ', 'ዠ', 'የ', 'ደ', 'ጀ', 'ገ', 'ጐ', 'ጠ', 'ጨ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'],
			main => qr{[፟ ሀ-ሆ ለ-ቆ ቈ ቊ-ቍ ቐ-ቖ ቘ ቚ-ቝ በ-ኆ ኈ ኊ-ኍ ነ-ኮ ኰ ኲ-ኵ ኸ-ኾ ዀ ዂ-ዅ ወ-ዎ ዐ-ዖ ዘ-ዮ ደ-ዷ ጀ-ጎ ጐ ጒ-ጕ ጠ-ፗ]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ሸ', 'ቀ', 'ቈ', 'ቐ', 'ቘ', 'በ', 'ቨ', 'ተ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'አ', 'ከ', 'ኰ', 'ኸ', 'ዀ', 'ወ', 'ዐ', 'ዘ', 'ዠ', 'የ', 'ደ', 'ጀ', 'ገ', 'ጐ', 'ጠ', 'ጨ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'], };
},
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

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
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
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
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
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0G',
					'other' => '0G',
				},
				'10000000000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000G',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0G',
					'other' => '0G',
				},
				'10000000000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000G',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0G',
					'other' => '0G',
				},
				'10000000000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000G',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
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
					'accounting' => {
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
							'ጥሪ',
							'ለካ',
							'መጋ',
							'ሚያ',
							'ግን',
							'ሰነ',
							'ሓም',
							'ነሓ',
							'መስ',
							'ጥቅ',
							'ሕዳ',
							'ታሕ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ጥ',
							'ለ',
							'መ',
							'ሚ',
							'ግ',
							'ሰ',
							'ሓ',
							'ነ',
							'መ',
							'ጥ',
							'ሕ',
							'ታ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዝያ',
							'ግንቦት',
							'ሰነ',
							'ሓምለ',
							'ነሓሰ',
							'መስከረም',
							'ጥቅምቲ',
							'ሕዳር',
							'ታሕሳስ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ጥሪ',
							'ለካ',
							'መጋ',
							'ሚያ',
							'ግን',
							'ሰነ',
							'ሓም',
							'ነሓ',
							'መስ',
							'ጥቅ',
							'ሕዳ',
							'ታሕ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ጥ',
							'ለ',
							'መ',
							'ሚ',
							'ግ',
							'ሰ',
							'ሓ',
							'ነ',
							'መ',
							'ጥ',
							'ሕ',
							'ታ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዝያ',
							'ግንቦት',
							'ሰነ',
							'ሓምለ',
							'ነሓሰ',
							'መስከረም',
							'ጥቅምቲ',
							'ሕዳር',
							'ታሕሳስ'
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
						mon => 'ሰኑ',
						tue => 'ሰሉ',
						wed => 'ረቡ',
						thu => 'ሓሙ',
						fri => 'ዓር',
						sat => 'ቀዳ',
						sun => 'ሰን'
					},
					narrow => {
						mon => 'ሰ',
						tue => 'ሰ',
						wed => 'ረ',
						thu => 'ሓ',
						fri => 'ዓ',
						sat => 'ቀ',
						sun => 'ሰ'
					},
					short => {
						mon => 'ሰኑ',
						tue => 'ሰሉ',
						wed => 'ረቡ',
						thu => 'ሓሙ',
						fri => 'ዓር',
						sat => 'ቀዳ',
						sun => 'ሰን'
					},
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
					abbreviated => {
						mon => 'ሰኑ',
						tue => 'ሰሉ',
						wed => 'ረቡ',
						thu => 'ሓሙ',
						fri => 'ዓር',
						sat => 'ቀዳ',
						sun => 'ሰን'
					},
					narrow => {
						mon => 'ሰ',
						tue => 'ሠ',
						wed => 'ረ',
						thu => 'ሓ',
						fri => 'ዓ',
						sat => 'ቀ',
						sun => 'ሰ'
					},
					short => {
						mon => 'ሰኑ',
						tue => 'ሰሉ',
						wed => 'ረቡ',
						thu => 'ሓሙ',
						fri => 'ዓር',
						sat => 'ቀዳ',
						sun => 'ሰን'
					},
					wide => {
						mon => 'ሰኑይ',
						tue => 'ሰሉስ',
						wed => 'ረቡዕ',
						thu => 'ሓሙስ',
						fri => 'ዓርቢ',
						sat => 'ቀዳም',
						sun => 'ሰንበት'
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
					abbreviated => {0 => 'ር1',
						1 => 'ር2',
						2 => 'ር3',
						3 => 'ር4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'ቀዳማይ ርብዒ',
						1 => 'ካልኣይ ርብዒ',
						2 => 'ሳልሳይ ርብዒ',
						3 => 'ራብዓይ ርብዒ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'ር1',
						1 => 'ር2',
						2 => 'ር3',
						3 => 'ር4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'ቀዳማይ ርብዒ',
						1 => 'ካልኣይ ርብዒ',
						2 => 'ሳልሳይ ርብዒ',
						3 => 'ራብዓይ ርብዒ'
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
				'narrow' => {
					'pm' => q{ድሕር ሰዓት},
					'am' => q{ንጉሆ ሰዓተ},
				},
				'wide' => {
					'am' => q{ንጉሆ ሰዓተ},
					'pm' => q{ድሕር ሰዓት},
				},
				'abbreviated' => {
					'pm' => q{ድሕር ሰዓት},
					'am' => q{ንጉሆ ሰዓተ},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ንጉሆ ሰዓተ},
					'pm' => q{ድሕር ሰዓት},
				},
				'wide' => {
					'pm' => q{ድሕር ሰዓት},
					'am' => q{ንጉሆ ሰዓተ},
				},
				'narrow' => {
					'pm' => q{ድሕር ሰዓት},
					'am' => q{ንጉሆ ሰዓተ},
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
			wide => {
				'0' => 'ዓ/ዓ',
				'1' => 'ዓመተ ምህረት'
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
			MMMMdd => q{dd MMMM},
			MMdd => q{dd/MM},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{ሰሙን W ናይ MMM},
			MMMMd => q{MMMM d},
			MMMMdd => q{dd MMMM},
			MMMd => q{MMM d},
			MMdd => q{dd/MM},
			Md => q{MM-dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y-MM},
			yMEd => q{y-MM-dd, E},
			yMM => q{MM/y},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{MMMM y},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQ y},
			yQQQQ => q{y QQQQ},
			yw => q{መበል w ሰሙን ናይ y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
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
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algiers#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadishu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curacao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico City#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthelemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damascus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapore#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#South Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unknown#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucharest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembourg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscow#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prague#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rome#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Easter#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
