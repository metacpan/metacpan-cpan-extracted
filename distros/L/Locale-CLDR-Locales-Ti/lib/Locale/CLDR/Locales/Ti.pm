=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ti - Package for language Tigrinya

=cut

package Locale::CLDR::Locales::Ti;
# This file auto generated from Data\common\main\ti.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
	my $subtags = join '{0}፣ {1}', grep {$_} (
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
				'af' => 'ኣፍሪካንስ',
 				'agq' => 'ኣገም',
 				'ak' => 'ኣካን',
 				'am' => 'ኣምሓርኛ',
 				'ar' => 'ዓረብ',
 				'ar_001' => 'ዘመናዊ ምዱብ ዓረብ',
 				'as' => 'ኣሳሜዝኛ',
 				'asa' => 'ኣሱ',
 				'ast' => 'ኣስቱርያን',
 				'az' => 'ኣዘርባጃንኛ',
 				'az@alt=short' => 'ኣዘሪ',
 				'bas' => 'ባሳ',
 				'be' => 'ቤላሩስኛ',
 				'bem' => 'ቤምባ',
 				'bez' => 'በና',
 				'bg' => 'ቡልጋርኛ',
 				'bm' => 'ባምባራ',
 				'bn' => 'በንጋሊ',
 				'bo' => 'ቲበታንኛ',
 				'br' => 'ብረቶንኛ',
 				'brx' => 'ቦዶ',
 				'bs' => 'ቦዝንኛ',
 				'ca' => 'ካታላን',
 				'ccp' => 'ቻክማ',
 				'ce' => 'ቸቸንይና',
 				'ceb' => 'ሰብዋኖ',
 				'cgg' => 'ቺጋ',
 				'chr' => 'ቸሮኪ',
 				'ckb' => 'ሶራኒ ኩርዲሽ',
 				'ckb@alt=variant' => 'ማእከላይ ኩርዲሽ',
 				'co' => 'ኮርስኛ',
 				'cs' => 'ቸክኛ',
 				'cu' => 'ቤተ-ክርስትያን ስላቭኛ',
 				'cy' => 'ዌልስኛ',
 				'da' => 'ዳኒሽ',
 				'dav' => 'ታይታ',
 				'de' => 'ጀርመን',
 				'dje' => 'ዛርማ',
 				'doi' => 'ዶግሪ',
 				'dsb' => 'ታሕተዋይ ሶርብኛ',
 				'dua' => 'ድዋላ',
 				'dyo' => 'ጆላ-ፎኒይ',
 				'dz' => 'ድዞንግካ',
 				'ebu' => 'ኤምቡ',
 				'ee' => 'ኢው',
 				'el' => 'ግሪኽኛ',
 				'en' => 'እንግሊዝኛ',
 				'en_US' => 'እንግሊዝኛ (ሕቡራት መንግስታት)',
 				'eo' => 'ኤስፐራንቶ',
 				'es' => 'ስጳንኛ',
 				'et' => 'ኤስቶንኛ',
 				'eu' => 'ባስክኛ',
 				'ewo' => 'ኤዎንዶ',
 				'fa' => 'ፋርስኛ',
 				'fa_AF' => 'ዳሪ',
 				'ff' => 'ፉላ',
 				'fi' => 'ፊንላንድኛ',
 				'fil' => 'ፊሊፒንኛ',
 				'fo' => 'ፋሮእይና',
 				'fr' => 'ፈረንሳይኛ',
 				'frc' => 'ካጁን ፈረንሳይ',
 				'fur' => 'ፍርዩልኛ',
 				'fy' => 'ምዕራባዊ ፍሪስኛ',
 				'ga' => 'ኣየርላንድኛ',
 				'gd' => 'ስኮትላንዳዊ ጋኤሊክኛ',
 				'gl' => 'ጋሊሽያን',
 				'gn' => 'ጓራኒ',
 				'gsw' => 'ስዊዘርላንዳዊ ጀርመን',
 				'gu' => 'ጉጃራቲ',
 				'guz' => 'ጉሲ',
 				'gv' => 'ማንክስ',
 				'ha' => 'ሃውሳ',
 				'haw' => 'ሃዋይኛ',
 				'he' => 'እብራይስጢ',
 				'hi' => 'ሂንዲ',
 				'hmn' => 'ህሞንግ',
 				'hr' => 'ክሮኤሽያን',
 				'hsb' => 'ላዕለዋይ ሶርብኛ',
 				'ht' => 'ክርዮል ሃይትኛ',
 				'hu' => 'ሃንጋርኛ',
 				'hy' => 'ኣርሜንኛ',
 				'ia' => 'ኢንተርሊንጓ',
 				'id' => 'ኢንዶነዥኛ',
 				'ig' => 'ኢግቦ',
 				'ii' => 'ሲችዋን ዪ',
 				'is' => 'ኣይስላንድኛ',
 				'it' => 'ጥልያን',
 				'ja' => 'ጃፓንኛ',
 				'jgo' => 'ንጎምባ',
 				'jmc' => 'ማኬም',
 				'jv' => 'ጃቫንኛ',
 				'ka' => 'ጆርጅያንኛ',
 				'kab' => 'ካቢልኛ',
 				'kam' => 'ካምባ',
 				'kde' => 'ማኮንደ',
 				'kea' => 'ክርዮል ኬፕ ቨርድኛ',
 				'kgp' => 'ካይንጋንግ',
 				'khq' => 'ኮይራ ቺኒ',
 				'ki' => 'ኪኩዩ',
 				'kk' => 'ካዛክ',
 				'kkj' => 'ካኮ',
 				'kl' => 'ግሪንላንድኛ',
 				'kln' => 'ካለንጂን',
 				'km' => 'ክመር',
 				'kn' => 'ካንናዳ',
 				'ko' => 'ኮርይኛ',
 				'kok' => 'ኮንካኒ',
 				'ks' => 'ካሽሚሪ',
 				'ksb' => 'ሻምባላ',
 				'ksf' => 'ባፍያ',
 				'ksh' => 'ኮልሽ',
 				'ku' => 'ኩርዲሽ',
 				'kw' => 'ኮርንኛ',
 				'ky' => 'ኪርጊዝኛ',
 				'la' => 'ላቲን',
 				'lag' => 'ላንጊ',
 				'lb' => 'ሉክሰምበርግኛ',
 				'lg' => 'ጋንዳ',
 				'lij' => 'ሊጉርኛ',
 				'lkt' => 'ላኮታ',
 				'ln' => 'ሊንጋላ',
 				'lo' => 'ላኦ',
 				'lou' => 'ክርዮል ሉዊዝያና',
 				'lrc' => 'ሰሜናዊ ሉሪ',
 				'lt' => 'ሊትዌንኛ',
 				'lu' => 'ሉባ-ካታንጋ',
 				'luo' => 'ሉኦ',
 				'luy' => 'ሉይያ',
 				'lv' => 'ላትቭኛ',
 				'mai' => 'ማይቲሊ',
 				'mas' => 'ማሳይ',
 				'mer' => 'መሩ',
 				'mfe' => 'ክርዮል ማውሪሽይና',
 				'mg' => 'ማላጋሲ',
 				'mgh' => 'ማክዋ-ሜቶ',
 				'mgo' => 'መታ',
 				'mi' => 'ማኦሪ',
 				'mk' => 'መቄዶንኛ',
 				'ml' => 'ማላያላም',
 				'mn' => 'ሞንጎልኛ',
 				'mni' => 'ማኒፑሪ',
 				'mr' => 'ማራቲ',
 				'ms' => 'ማላይኛ',
 				'mt' => 'ማልትኛ',
 				'mua' => 'ሙንዳንግ',
 				'mul' => 'ዝተፈላለዩ ቋንቋታት',
 				'my' => 'በርምኛ',
 				'mzn' => 'ማዛንደራኒ',
 				'naq' => 'ናማ',
 				'nb' => 'ኖርወያዊ ቦክማል',
 				'nd' => 'ሰሜን ንደበለ',
 				'nds' => 'ትሑት ጀርመን',
 				'nds_NL' => 'ትሑት ሳክሰን',
 				'ne' => 'ኔፓሊ',
 				'nl' => 'ዳች',
 				'nl_BE' => 'ፍላሚሽ',
 				'nmg' => 'ክዋስዮ',
 				'nn' => 'ኖርወያዊ ናይኖርስክ',
 				'nnh' => 'ንጌምቡን',
 				'no' => 'ኖርወይኛ',
 				'nus' => 'ንዌር',
 				'nv' => 'ናቫሆ',
 				'ny' => 'ንያንጃ',
 				'nyn' => 'ንያንኮል',
 				'oc' => 'ኦክሲታንኛ',
 				'om' => 'ኦሮሞ',
 				'or' => 'ኦድያ',
 				'os' => 'ኦሰትኛ',
 				'pa' => 'ፑንጃቢ',
 				'pcm' => 'ፒጂን ናይጀርያ',
 				'pl' => 'ፖሊሽ',
 				'prg' => 'ፕሩስኛ',
 				'ps' => 'ፓሽቶ',
 				'pt' => 'ፖርቱጊዝኛ',
 				'qu' => 'ቀችዋ',
 				'rhg' => 'ሮሂንግያ',
 				'rm' => 'ሮማንሽ',
 				'rn' => 'ኪሩንዲ',
 				'ro' => 'ሩማንኛ',
 				'ro_MD' => 'ሞልዶቨኛ',
 				'rof' => 'ሮምቦ',
 				'ru' => 'ሩስኛ',
 				'rw' => 'ኪንያርዋንዳ',
 				'rwk' => 'ርዋ',
 				'sa' => 'ሳንስክሪት',
 				'sah' => 'ሳኻ',
 				'saq' => 'ሳምቡሩ',
 				'sat' => 'ሳንታሊ',
 				'sbp' => 'ሳንጉ',
 				'sd' => 'ሲንድሂ',
 				'se' => 'ሰሜናዊ ሳሚ',
 				'seh' => 'ሰና',
 				'ses' => 'ኮይራቦሮ ሰኒ',
 				'sg' => 'ሳንጎ',
 				'sh' => 'ሰርቦ-ክሮኤሽያን',
 				'shi' => 'ታቸልሂት',
 				'si' => 'ሲንሃላ',
 				'sk' => 'ስሎቫክኛ',
 				'sl' => 'ስሎቬንኛ',
 				'sm' => 'ሳሞእኛ',
 				'smn' => 'ሳሚ ኢናሪ',
 				'sn' => 'ሾና',
 				'so' => 'ሶማሊ',
 				'sq' => 'ኣልባንኛ',
 				'sr' => 'ሰርብኛ',
 				'st' => 'ደቡባዊ ሶቶ',
 				'su' => 'ሱንዳንኛ',
 				'sv' => 'ስዊድንኛ',
 				'sw' => 'ስዋሂሊ',
 				'sw_CD' => 'ስዋሂሊ (ኮንጎ)',
 				'ta' => 'ታሚል',
 				'te' => 'ተሉጉ',
 				'teo' => 'ተሶ',
 				'tg' => 'ታጂክኛ',
 				'th' => 'ታይኛ',
 				'ti' => 'ትግርኛ',
 				'tk' => 'ቱርክመንኛ',
 				'tlh' => 'ክሊንጎን',
 				'to' => 'ቶንጋንኛ',
 				'tr' => 'ቱርክኛ',
 				'tt' => 'ታታር',
 				'tw' => 'ትዊ',
 				'twq' => 'ታሳዋቅ',
 				'tzm' => 'ማእከላይ ኣትላስ ታማዛይት',
 				'ug' => 'ኡይጉር',
 				'uk' => 'ዩክረይንኛ',
 				'und' => 'ዘይተፈልጠ ቋንቋ',
 				'ur' => 'ኡርዱ',
 				'uz' => 'ኡዝበክኛ',
 				'vai' => 'ቫይ',
 				'vi' => 'ቬትናምኛ',
 				'vo' => 'ቮላፑክ',
 				'vun' => 'ቩንጆ',
 				'wae' => 'ዋልሰር',
 				'wo' => 'ዎሎፍ',
 				'xh' => 'ኮሳ',
 				'xog' => 'ሶጋ',
 				'yav' => 'ያንግበን',
 				'yi' => 'ይሁድኛ',
 				'yo' => 'ዮሩባ',
 				'yue' => 'ካንቶንኛ',
 				'yue@alt=menu' => 'ቻይናዊ ካንቶንኛ',
 				'zgh' => 'ሞሮካዊ ምዱብ ታማዛይት',
 				'zh' => 'ቻይንኛ',
 				'zh@alt=menu' => 'ማንዳሪን ቻይንኛ',
 				'zh_Hans' => 'ቀሊል ቻይንኛ',
 				'zh_Hans@alt=long' => 'ቀሊል ማንዳሪን ቻይንኛ',
 				'zh_Hant' => 'ባህላዊ ቻይንኛ',
 				'zh_Hant@alt=long' => 'ባህላዊ ማንዳሪን ቻይንኛ',
 				'zu' => 'ዙሉ',
 				'zxx' => 'ቋንቋዊ ትሕዝቶ የለን',

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
 			'Zsye' => 'ኢሞጂ',
 			'Zsym' => 'ምልክታት',
 			'Zxxx' => 'ዘይተጻሕፈ',

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
 			'002' => 'ኣፍሪቃ',
 			'003' => 'ሰሜን ኣመሪካ',
 			'005' => 'ደቡብ ኣመሪካ',
 			'009' => 'ኦሽያንያ',
 			'011' => 'ምዕራባዊ ኣፍሪቃ',
 			'013' => 'ማእከላይ ኣመሪካ',
 			'014' => 'ምብራቓዊ ኣፍሪቃ',
 			'015' => 'ሰሜናዊ ኣፍሪቃ',
 			'017' => 'ማእከላይ ኣፍሪቃ',
 			'018' => 'ደቡባዊ ኣፍሪቃ',
 			'019' => 'ኣመሪካታት',
 			'021' => 'ሰሜናዊ ኣመሪካ',
 			'029' => 'ካሪብያን',
 			'030' => 'ምብራቓዊ ኤስያ',
 			'034' => 'ደቡባዊ ኤስያ',
 			'035' => 'ደቡባዊ ምብራቕ ኤስያ',
 			'039' => 'ደቡባዊ ኤውሮጳ',
 			'053' => 'ኣውስትራሌዥያ',
 			'054' => 'መላነዥያ',
 			'057' => 'ዞባ ማይክሮነዥያ',
 			'061' => 'ፖሊነዥያ',
 			'142' => 'ኤስያ',
 			'143' => 'ማእከላይ ኤስያ',
 			'145' => 'ምዕራባዊ ኤስያ',
 			'150' => 'ኤውሮጳ',
 			'151' => 'ምብራቓዊ ኤውሮጳ',
 			'154' => 'ሰሜናዊ ኤውሮጳ',
 			'155' => 'ምዕራባዊ ኤውሮጳ',
 			'202' => 'ንኡስ ሰሃራዊ ኣፍሪቃ',
 			'419' => 'ላቲን ኣመሪካ',
 			'AC' => 'ደሴት ኣሰንስዮን',
 			'AD' => 'ኣንዶራ',
 			'AE' => 'ሕቡራት ኢማራት ዓረብ',
 			'AF' => 'ኣፍጋኒስታን',
 			'AG' => 'ኣንቲጓን ባርቡዳን',
 			'AI' => 'ኣንጒላ',
 			'AL' => 'ኣልባንያ',
 			'AM' => 'ኣርሜንያ',
 			'AO' => 'ኣንጎላ',
 			'AQ' => 'ኣንታርክቲካ',
 			'AR' => 'ኣርጀንቲና',
 			'AS' => 'ኣመሪካዊት ሳሞኣ',
 			'AT' => 'ኦስትርያ',
 			'AU' => 'ኣውስትራልያ',
 			'AW' => 'ኣሩባ',
 			'AX' => 'ደሴታት ኣላንድ',
 			'AZ' => 'ኣዘርባጃን',
 			'BA' => 'ቦዝንያን ሄርዘጎቪናን',
 			'BB' => 'ባርባዶስ',
 			'BD' => 'ባንግላደሽ',
 			'BE' => 'ቤልጅዩም',
 			'BF' => 'ቡርኪና ፋሶ',
 			'BG' => 'ቡልጋርያ',
 			'BH' => 'ባሕሬን',
 			'BI' => 'ብሩንዲ',
 			'BJ' => 'ቤኒን',
 			'BL' => 'ቅዱስ ባርተለሚ',
 			'BM' => 'በርሙዳ',
 			'BN' => 'ብሩነይ',
 			'BO' => 'ቦሊቭያ',
 			'BQ' => 'ካሪብያን ኔዘርላንድ',
 			'BR' => 'ብራዚል',
 			'BS' => 'ባሃማስ',
 			'BT' => 'ቡታን',
 			'BV' => 'ደሴት ቡቨት',
 			'BW' => 'ቦትስዋና',
 			'BY' => 'ቤላሩስ',
 			'BZ' => 'በሊዝ',
 			'CA' => 'ካናዳ',
 			'CC' => 'ደሴታት ኮኮስ',
 			'CD' => 'ደሞክራስያዊት ሪፓብሊክ ኮንጎ',
 			'CD@alt=variant' => 'ኮንጎ (ደ.ሪ.ኮ.)',
 			'CF' => 'ሪፓብሊክ ማእከላይ ኣፍሪቃ',
 			'CG' => 'ኮንጎ',
 			'CG@alt=variant' => 'ኮንጎ (ሪፓብሊክ)',
 			'CH' => 'ስዊዘርላንድ',
 			'CI' => 'ኮት ዲቭዋር',
 			'CI@alt=variant' => 'ኣይቮሪ ኮስት',
 			'CK' => 'ደሴታት ኩክ',
 			'CL' => 'ቺሌ',
 			'CM' => 'ካሜሩን',
 			'CN' => 'ቻይና',
 			'CO' => 'ኮሎምብያ',
 			'CP' => 'ደሴት ክሊፐርቶን',
 			'CR' => 'ኮስታ ሪካ',
 			'CU' => 'ኩባ',
 			'CV' => 'ኬፕ ቨርደ',
 			'CW' => 'ኩራሳው',
 			'CX' => 'ደሴት ክሪስማስ',
 			'CY' => 'ቆጵሮስ',
 			'CZ' => 'ቸክያ',
 			'CZ@alt=variant' => 'ሪፓብሊክ ቸክ',
 			'DE' => 'ጀርመን',
 			'DG' => 'ድየጎ ጋርስያ',
 			'DJ' => 'ጅቡቲ',
 			'DK' => 'ደንማርክ',
 			'DM' => 'ዶሚኒካ',
 			'DO' => 'ዶሚኒካዊት ሪፓብሊክ',
 			'DZ' => 'ኣልጀርያ',
 			'EA' => 'ሴውታን መሊላን',
 			'EC' => 'ኤኳዶር',
 			'EE' => 'ኤስቶንያ',
 			'EG' => 'ግብጺ',
 			'EH' => 'ምዕራባዊ ሰሃራ',
 			'ER' => 'ኤርትራ',
 			'ES' => 'ስጳኛ',
 			'ET' => 'ኢትዮጵያ',
 			'EU' => 'ኤውሮጳዊ ሕብረት',
 			'EZ' => 'ዞባ ዩሮ',
 			'FI' => 'ፊንላንድ',
 			'FJ' => 'ፊጂ',
 			'FK' => 'ደሴታት ፎክላንድ',
 			'FK@alt=variant' => 'ደሴታት ፎክላንድ (ኢስላስ ማልቪናስ)',
 			'FM' => 'ማይክሮነዥያ',
 			'FO' => 'ደሴታት ፋሮ',
 			'FR' => 'ፈረንሳ',
 			'GA' => 'ጋቦን',
 			'GB' => 'ብሪጣንያ',
 			'GB@alt=short' => 'ዩ.ኪ.',
 			'GD' => 'ግረናዳ',
 			'GE' => 'ጆርጅያ',
 			'GF' => 'ፈረንሳዊት ጊያና',
 			'GG' => 'ገርንዚ',
 			'GH' => 'ጋና',
 			'GI' => 'ጂብራልታር',
 			'GL' => 'ግሪንላንድ',
 			'GM' => 'ጋምብያ',
 			'GN' => 'ጊኒ',
 			'GP' => 'ጓደሉፕ',
 			'GQ' => 'ኢኳቶርያል ጊኒ',
 			'GR' => 'ግሪኽ',
 			'GS' => 'ደሴታት ደቡብ ጆርጅያን ደቡብ ሳንድዊችን',
 			'GT' => 'ጓቲማላ',
 			'GU' => 'ጓም',
 			'GW' => 'ጊኒ-ቢሳው',
 			'GY' => 'ጉያና',
 			'HK' => 'ፍሉይ ምምሕዳራዊ ዞባ ሆንግ ኮንግ (ቻይና)',
 			'HK@alt=short' => 'ሆንግ ኮንግ',
 			'HM' => 'ደሴታት ሄርድን ማክዶናልድን',
 			'HN' => 'ሆንዱራስ',
 			'HR' => 'ክሮኤሽያ',
 			'HT' => 'ሃይቲ',
 			'HU' => 'ሃንጋሪ',
 			'IC' => 'ደሴታት ካናሪ',
 			'ID' => 'ኢንዶነዥያ',
 			'IE' => 'ኣየርላንድ',
 			'IL' => 'እስራኤል',
 			'IM' => 'ኣይል ኦፍ ማን',
 			'IN' => 'ህንዲ',
 			'IO' => 'ብሪጣንያዊ ህንዳዊ ውቅያኖስ ግዝኣት',
 			'IQ' => 'ዒራቕ',
 			'IR' => 'ኢራን',
 			'IS' => 'ኣይስላንድ',
 			'IT' => 'ኢጣልያ',
 			'JE' => 'ጀርዚ',
 			'JM' => 'ጃማይካ',
 			'JO' => 'ዮርዳኖስ',
 			'JP' => 'ጃፓን',
 			'KE' => 'ኬንያ',
 			'KG' => 'ኪርጊዝስታን',
 			'KH' => 'ካምቦድያ',
 			'KI' => 'ኪሪባቲ',
 			'KM' => 'ኮሞሮስ',
 			'KN' => 'ቅዱስ ኪትስን ኔቪስን',
 			'KP' => 'ሰሜን ኮርያ',
 			'KR' => 'ደቡብ ኮርያ',
 			'KW' => 'ኩዌት',
 			'KY' => 'ደሴታት ካይማን',
 			'KZ' => 'ካዛኪስታን',
 			'LA' => 'ላኦስ',
 			'LB' => 'ሊባኖስ',
 			'LC' => 'ቅድስቲ ሉስያ',
 			'LI' => 'ሊኽተንሽታይን',
 			'LK' => 'ስሪ ላንካ',
 			'LR' => 'ላይበርያ',
 			'LS' => 'ሌሶቶ',
 			'LT' => 'ሊትዌንያ',
 			'LU' => 'ሉክሰምበርግ',
 			'LV' => 'ላትቭያ',
 			'LY' => 'ሊብያ',
 			'MA' => 'ሞሮኮ',
 			'MC' => 'ሞናኮ',
 			'MD' => 'ሞልዶቫ',
 			'ME' => 'ሞንተኔግሮ',
 			'MF' => 'ቅዱስ ማርቲን',
 			'MG' => 'ማዳጋስካር',
 			'MH' => 'ደሴታት ማርሻል',
 			'MK' => 'ሰሜን መቄዶንያ',
 			'ML' => 'ማሊ',
 			'MM' => 'ሚያንማር (በርማ)',
 			'MN' => 'ሞንጎልያ',
 			'MO' => 'ፍሉይ ምምሕዳራዊ ዞባ ማካው (ቻይና)',
 			'MO@alt=short' => 'ማካው',
 			'MP' => 'ደሴታት ሰሜናዊ ማርያና',
 			'MQ' => 'ማርቲኒክ',
 			'MR' => 'ማውሪታንያ',
 			'MS' => 'ሞንትሰራት',
 			'MT' => 'ማልታ',
 			'MU' => 'ማውሪሸስ',
 			'MV' => 'ማልዲቭስ',
 			'MW' => 'ማላዊ',
 			'MX' => 'ሜክሲኮ',
 			'MY' => 'ማለዥያ',
 			'MZ' => 'ሞዛምቢክ',
 			'NA' => 'ናሚብያ',
 			'NC' => 'ኒው ካለዶንያ',
 			'NE' => 'ኒጀር',
 			'NF' => 'ደሴት ኖርፎልክ',
 			'NG' => 'ናይጀርያ',
 			'NI' => 'ኒካራጓ',
 			'NL' => 'ኔዘርላንድ',
 			'NO' => 'ኖርወይ',
 			'NP' => 'ኔፓል',
 			'NR' => 'ናውሩ',
 			'NU' => 'ኒዩ',
 			'NZ' => 'ኒው ዚላንድ',
 			'OM' => 'ዖማን',
 			'PA' => 'ፓናማ',
 			'PE' => 'ፔሩ',
 			'PF' => 'ፈረንሳይ ፖሊነዥያ',
 			'PG' => 'ፓፕዋ ኒው ጊኒ',
 			'PH' => 'ፊሊፒንስ',
 			'PK' => 'ፓኪስታን',
 			'PL' => 'ፖላንድ',
 			'PM' => 'ቅዱስ ፕየርን ሚከሎንን',
 			'PN' => 'ደሴታት ፒትካርን',
 			'PR' => 'ፖርቶ ሪኮ',
 			'PS' => 'ግዝኣታት ፍልስጤም',
 			'PS@alt=short' => 'ፍልስጤም',
 			'PT' => 'ፖርቱጋል',
 			'PW' => 'ፓላው',
 			'PY' => 'ፓራጓይ',
 			'QA' => 'ቐጠር',
 			'QO' => 'ካብ ኦሽያንያ ርሒቖም ግዝኣታት',
 			'RE' => 'ርዩንየን',
 			'RO' => 'ሩማንያ',
 			'RS' => 'ሰርብያ',
 			'RU' => 'ሩስያ',
 			'RW' => 'ርዋንዳ',
 			'SA' => 'ስዑዲ ዓረብ',
 			'SB' => 'ደሴታት ሰሎሞን',
 			'SC' => 'ሲሸልስ',
 			'SD' => 'ሱዳን',
 			'SE' => 'ሽወደን',
 			'SG' => 'ሲንጋፖር',
 			'SH' => 'ቅድስቲ ሄለና',
 			'SI' => 'ስሎቬንያ',
 			'SJ' => 'ስቫልባርድን ጃን ማየንን',
 			'SK' => 'ስሎቫክያ',
 			'SL' => 'ሴራ ልዮን',
 			'SM' => 'ሳን ማሪኖ',
 			'SN' => 'ሰነጋል',
 			'SO' => 'ሶማልያ',
 			'SR' => 'ሱሪናም',
 			'SS' => 'ደቡብ ሱዳን',
 			'ST' => 'ሳኦ ቶመን ፕሪንሲፐን',
 			'SV' => 'ኤል ሳልቫዶር',
 			'SX' => 'ሲንት ማርተን',
 			'SY' => 'ሶርያ',
 			'SZ' => 'ኤስዋቲኒ',
 			'SZ@alt=variant' => 'ስዋዚላንድ',
 			'TA' => 'ትሪስታን ዳ ኩንያ',
 			'TC' => 'ደሴታት ቱርካትን ካይኮስን',
 			'TD' => 'ጫድ',
 			'TF' => 'ፈረንሳዊ ደቡባዊ ግዝኣታት',
 			'TG' => 'ቶጎ',
 			'TH' => 'ታይላንድ',
 			'TJ' => 'ታጂኪስታን',
 			'TK' => 'ቶከላው',
 			'TL' => 'ቲሞር-ለስተ',
 			'TL@alt=variant' => 'ምብራቕ ቲሞር',
 			'TM' => 'ቱርክመኒስታን',
 			'TN' => 'ቱኒዝያ',
 			'TO' => 'ቶንጋ',
 			'TR' => 'ቱርኪ',
 			'TT' => 'ትሪኒዳድን ቶባጎን',
 			'TV' => 'ቱቫሉ',
 			'TW' => 'ታይዋን',
 			'TZ' => 'ታንዛንያ',
 			'UA' => 'ዩክሬን',
 			'UG' => 'ኡጋንዳ',
 			'UM' => 'ካብ ኣመሪካ ርሒቐን ንኣሽቱ ደሴታት',
 			'UN' => 'ሕቡራት ሃገራት',
 			'US' => 'ኣመሪካ',
 			'US@alt=short' => 'ሕ.መ.',
 			'UY' => 'ኡራጓይ',
 			'UZ' => 'ኡዝበኪስታን',
 			'VA' => 'ከተማ ቫቲካን',
 			'VC' => 'ቅዱስ ቪንሰንትን ግረነዲነዝን',
 			'VE' => 'ቬኔዝዌላ',
 			'VG' => 'ደሴታት ደናግል ብሪጣንያ',
 			'VI' => 'ደሴታት ደናግል ኣመሪካ',
 			'VN' => 'ቬትናም',
 			'VU' => 'ቫንዋቱ',
 			'WF' => 'ዋሊስን ፉቱናን',
 			'WS' => 'ሳሞኣ',
 			'XA' => 'ናይ ሓሶት ላህጃታት',
 			'XB' => 'ናይ ሓሶት ክልተ ኣንፈታዊ',
 			'XK' => 'ኮሶቮ',
 			'YE' => 'የመን',
 			'YT' => 'ማዮት',
 			'ZA' => 'ደቡብ ኣፍሪቃ',
 			'ZM' => 'ዛምብያ',
 			'ZW' => 'ዚምባብዌ',
 			'ZZ' => 'ዘይተፈልጠ ዞባ',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1959ACAD' => 'ኣካዳምያዊ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ዓውደ-ኣዋርሕ',
 			'cf' => 'ቅርጺ ባጤራ',
 			'currency' => 'ባጤራ',
 			'numbers' => 'ቁጽርታት',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{ሜትሪክ},
 			'UK' => q{ብሪጣንያ},
 			'US' => q{ኣመሪካ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ቋንቋ፦ {0}',
 			'script' => 'ኢደ-ጽሕፈት፦ {0}',
 			'region' => 'ዞባ፦ {0}',

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
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ሸ', 'ቀ', 'ቈ', 'ቐ', 'ቘ', 'በ', 'ቨ', 'ተ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'አ', 'ከ', 'ኰ', 'ኸ', 'ዀ', 'ወ', 'ዐ', 'ዘ', 'ዠ', 'የ', 'ደ', 'ጀ', 'ገ', 'ጐ', 'ጠ', 'ጨ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'word-initial' => '… {0}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
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
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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
				'long' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ዘመናት),
						'one' => q({0} ዘመን),
						'other' => q({0} ዘመናት),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ዘመናት),
						'one' => q({0} ዘመን),
						'other' => q({0} ዘመናት),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ዓሰርተታት ዓመታት),
						'one' => q({0} ዓሰርተ ዓመት),
						'other' => q({0} ዓሰርተታት ዓመታት),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ዓሰርተታት ዓመታት),
						'one' => q({0} ዓሰርተ ዓመት),
						'other' => q({0} ዓሰርተታት ዓመታት),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ዓመታት),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ዓመታት),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ዘመን),
						'one' => q({0} ዘመን),
						'other' => q({0} ዘመናት),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ዘመን),
						'one' => q({0} ዘመን),
						'other' => q({0} ዘመናት),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ዓሰርተ ዓመት),
						'one' => q({0} ዓ.ዓ.),
						'other' => q({0} ዓ.ዓ.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ዓሰርተ ዓመት),
						'one' => q({0} ዓ.ዓ.),
						'other' => q({0} ዓ.ዓ.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ዘመን),
						'one' => q({0} ዘመን),
						'other' => q({0} ዘመናት),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ዘመን),
						'one' => q({0} ዘመን),
						'other' => q({0} ዘመናት),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ዓሰርተ ዓመት),
						'one' => q({0} ዓሰ.ዓመ.),
						'other' => q({0} ዓሰ.ዓመ.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ዓሰርተ ዓመት),
						'one' => q({0} ዓሰ.ዓመ.),
						'other' => q({0} ዓሰ.ዓመ.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:እወ|እ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}፣ {1}),
				middle => q({0}፣ {1}),
				end => q({0}፣ {1}),
				2 => q({0}ን {1}ን),
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
					'one' => '0 ሽ',
					'other' => '0 ሽ',
				},
				'10000' => {
					'one' => '00 ሽ',
					'other' => '00 ሽ',
				},
				'100000' => {
					'one' => '000 ሽ',
					'other' => '000 ሽ',
				},
				'1000000' => {
					'one' => '0 ሚ',
					'other' => '0 ሚ',
				},
				'10000000' => {
					'one' => '00 ሚ',
					'other' => '00 ሚ',
				},
				'100000000' => {
					'one' => '000 ሚ',
					'other' => '000 ሚ',
				},
				'1000000000' => {
					'one' => '0 ቢ',
					'other' => '0 ቢ',
				},
				'10000000000' => {
					'one' => '00 ቢ',
					'other' => '00 ቢ',
				},
				'100000000000' => {
					'one' => '000 ቢ',
					'other' => '000 ቢ',
				},
				'1000000000000' => {
					'one' => '0 ት',
					'other' => '0 ት',
				},
				'10000000000000' => {
					'one' => '00 ት',
					'other' => '00 ት',
				},
				'100000000000000' => {
					'one' => '000 ት',
					'other' => '000 ት',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 ሽሕ',
					'other' => '0 ሽሕ',
				},
				'10000' => {
					'one' => '00 ሽሕ',
					'other' => '00 ሽሕ',
				},
				'100000' => {
					'one' => '000 ሽሕ',
					'other' => '000 ሽሕ',
				},
				'1000000' => {
					'one' => '0 ሚልዮን',
					'other' => '0 ሚልዮን',
				},
				'10000000' => {
					'one' => '00 ሚልዮን',
					'other' => '00 ሚልዮን',
				},
				'100000000' => {
					'one' => '000 ሚልዮን',
					'other' => '000 ሚልዮን',
				},
				'1000000000' => {
					'one' => '0 ቢልዮን',
					'other' => '0 ቢልዮን',
				},
				'10000000000' => {
					'one' => '00 ቢልዮን',
					'other' => '00 ቢልዮን',
				},
				'100000000000' => {
					'one' => '000 ቢልዮን',
					'other' => '000 ቢልዮን',
				},
				'1000000000000' => {
					'one' => '0 ትሪልዮን',
					'other' => '0 ትሪልዮን',
				},
				'10000000000000' => {
					'one' => '00 ትሪልዮን',
					'other' => '00 ትሪልዮን',
				},
				'100000000000000' => {
					'one' => '000 ትሪልዮን',
					'other' => '000 ትሪልዮን',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 ሽ',
					'other' => '0 ሽ',
				},
				'10000' => {
					'one' => '00 ሽ',
					'other' => '00 ሽ',
				},
				'100000' => {
					'one' => '000 ሽ',
					'other' => '000 ሽ',
				},
				'1000000' => {
					'one' => '0 ሚ',
					'other' => '0 ሚ',
				},
				'10000000' => {
					'one' => '00 ሚ',
					'other' => '00 ሚ',
				},
				'100000000' => {
					'one' => '000 ሚ',
					'other' => '000 ሚ',
				},
				'1000000000' => {
					'one' => '0 ቢ',
					'other' => '0 ቢ',
				},
				'10000000000' => {
					'one' => '00 ቢ',
					'other' => '00 ቢ',
				},
				'100000000000' => {
					'one' => '000 ቢ',
					'other' => '000 ቢ',
				},
				'1000000000000' => {
					'one' => '0 ት',
					'other' => '0 ት',
				},
				'10000000000000' => {
					'one' => '00 ት',
					'other' => '00 ት',
				},
				'100000000000000' => {
					'one' => '000 ት',
					'other' => '000 ት',
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
		'BMD' => {
			symbol => '$',
		},
		'BRL' => {
			display_name => {
				'currency' => q(የብራዚል ሪል),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(ዩዋን ቻይና),
				'one' => q(ዩዋን ቻይና),
				'other' => q(ዩዋን ቻይና),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(ናቕፋ),
				'one' => q(ናቕፋ),
				'other' => q(ናቕፋ),
			},
		},
		'ETB' => {
			symbol => 'Br',
			display_name => {
				'currency' => q(ብር),
				'one' => q(ብር),
				'other' => q(ብር),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(ዩሮ),
				'one' => q(ዩሮ),
				'other' => q(ዩሮ),
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
			symbol => 'JPY',
			display_name => {
				'currency' => q(የን ጃፓን),
				'one' => q(የን ጃፓን),
				'other' => q(የን ጃፓን),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(የራሻ ሩብል),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(ዶላር ኣመሪካ),
				'one' => q(ዶላር ኣመሪካ),
				'other' => q(ዶላር ኣመሪካ),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(ብሩር),
				'one' => q(ብሩር),
				'other' => q(ብሩር),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(ወርቂ),
				'one' => q(ወርቂ),
				'other' => q(ወርቂ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ዘይተፈልጠ ባጤራ),
				'one' => q(\(ዘይተፈልጠ ባጤራ\)),
				'other' => q(\(ዘይተፈልጠ ባጤራ\)),
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
						tue => 'ሰሉስ',
						wed => 'ረቡዕ',
						thu => 'ሓሙስ',
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
					wide => {0 => '1ይ ርብዒ',
						1 => '2ይ ርብዒ',
						2 => '3ይ ርብዒ',
						3 => '4ይ ርብዒ'
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
					wide => {0 => '1ይ ርብዒ',
						1 => '2ይ ርብዒ',
						2 => '3ይ ርብዒ',
						3 => '4ይ ርብዒ'
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
					'am' => q{ቅ.ቀ.},
					'pm' => q{ድ.ቀ.},
				},
				'narrow' => {
					'am' => q{ቅ.ቀ.},
					'pm' => q{ድ.ቀ.},
				},
				'wide' => {
					'am' => q{ቅ.ቀ.},
					'pm' => q{ድ.ቀ.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ቅ.ቀ.},
					'pm' => q{ድ.ቀ.},
				},
				'narrow' => {
					'am' => q{ቅ.ቀ.},
					'pm' => q{ድ.ቀ.},
				},
				'wide' => {
					'am' => q{ቅ.ቀ.},
					'pm' => q{ድ.ቀ.},
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
		'buddhist' => {
			abbreviated => {
				'0' => 'BE'
			},
			narrow => {
				'0' => 'BE'
			},
			wide => {
				'0' => 'BE'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'ዓ/ዓ',
				'1' => 'ዓ/ም'
			},
			wide => {
				'0' => 'ቅድመ ክርስቶስ',
				'1' => 'ዓመተ ምሕረት'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'generic' => {
			'full' => q{EEEE፣ d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE፣ d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
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
		'buddhist' => {
		},
		'generic' => {
			'full' => q{{1} ሰዓት {0}},
			'long' => q{{1} ሰዓት {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} ሰዓት {0}},
			'long' => q{{1} ሰዓት {0}},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E፣ d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E፣ d/M},
			MMM => q{LLL},
			MMMEd => q{E፣ d MMM},
			MMMMd => q{d MMMM},
			MMMMdd => q{dd MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E፣ d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E፣ d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E፣ HH:mm},
			EHms => q{E፣ HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E፣ h:mm a},
			Ehms => q{E፣ h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E፣ d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E፣ d/M},
			MMM => q{LLL},
			MMMEd => q{E፣ d MMM},
			MMMMW => q{ሰሙን W ናይ MMMM},
			MMMMd => q{d MMMM},
			MMMMdd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{d/M},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E፣ d/M/y},
			yMM => q{M/y},
			yMMM => q{MMM y},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{ሰሙን w ናይ Y},
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
		'generic' => {
			H => {
				H => q{HH–HH},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E፣ d/M/y GGGGG – E፣ d/M/y GGGGG},
				M => q{E፣ d/M/y – E፣ d/M/y GGGGG},
				d => q{E፣ d/M/y – E፣ d/M/y GGGGG},
				y => q{E፣ d/M/y – E፣ d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E፣ d MMM y G – E፣ d MMM y G},
				M => q{E፣ d MMM – E፣ d MMM y G},
				d => q{E፣ d MMM – E፣ d MMM y G},
				y => q{E፣ d MMM y – E፣ d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E፣ d/M – E፣ d/M},
				d => q{E፣ d/M – E፣ d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E፣ d MMM – E፣ d MMM},
				d => q{E፣ d MMM – E፣ d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
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
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
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
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E፣ d/M/y – E፣ d/M/y},
				d => q{E፣ d/M/y – E፣ d/M/y},
				y => q{E፣ d/M/y – E፣ d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E፣ d MMM – E፣ d MMM y},
				d => q{E፣ d MMM – E፣ d MMM y},
				y => q{E፣ d MMM y – E፣ d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
		regionFormat => q(ግዜ {0}),
		regionFormat => q(ግዜ ክረምቲ {0}),
		regionFormat => q(ምዱብ ግዜ {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣክሪ#,
				'generic' => q#ግዜ ኣክሪ#,
				'standard' => q#ምዱብ ግዜ ኣክሪ#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#ኣቢጃን#,
		},
		'Africa/Accra' => {
			exemplarCity => q#ኣክራ#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#ኣዲስ ኣበባ#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#ኣልጀርስ#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#ኣስመራ#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#ባማኮ#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#ባንጊ#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#ባንጁል#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#ቢሳው#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#ብላንታየር#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#ብራዛቪል#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#ቡጁምቡራ#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#ካይሮ#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#ካዛብላንካ#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#ሴውታ#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#ኮናክሪ#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ዳካር#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#ዳር ኤስ ሳላም#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#ጅቡቲ#,
		},
		'Africa/Douala' => {
			exemplarCity => q#ዱዋላ#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#ኤል ኣዩን#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#ፍሪታውን#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#ጋቦሮን#,
		},
		'Africa/Harare' => {
			exemplarCity => q#ሃራረ#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#ጆሃንስበርግ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#ጁባ#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#ካምፓላ#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#ካርቱም#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#ኪጋሊ#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#ኪንሻሳ#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#ሌጎስ#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#ሊብረቪል#,
		},
		'Africa/Lome' => {
			exemplarCity => q#ሎመ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#ሉዋንዳ#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#ሉቡምባሺ#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#ሉሳካ#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#ማላቦ#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#ማፑቶ#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#ማሰሩ#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#ምባባነ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#ሞቓድሾ#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#ሞንሮቭያ#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#ናይሮቢ#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#ንጃመና#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#ንያመይ#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#ንዋክሾት#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#ዋጋዱጉ#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#ፖርቶ ኖቮ#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ሳኦ ቶመ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ትሪፖሊ#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ቱኒስ#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#ዊንድሆክ#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#ግዜ ማእከላይ ኣፍሪቃ#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ግዜ ምብራቕ ኣፍሪቃ#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#ግዜ ደቡብ ኣፍሪቃ#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ምዕራብ ኣፍሪቃ#,
				'generic' => q#ግዜ ምዕራብ ኣፍሪቃ#,
				'standard' => q#ምዱብ ግዜ ምዕራብ ኣፍሪቃ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣላስካ#,
				'generic' => q#ግዜ ኣላስካ#,
				'standard' => q#ምዱብ ግዜ ኣላስካ#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣማዞን#,
				'generic' => q#ግዜ ኣማዞን#,
				'standard' => q#ምዱብ ግዜ ኣማዞን#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#ኣዳክ#,
		},
		'America/Anchorage' => {
			exemplarCity => q#ኣንኮረጅ#,
		},
		'America/Anguilla' => {
			exemplarCity => q#ኣንጒላ#,
		},
		'America/Antigua' => {
			exemplarCity => q#ኣንቲጓ#,
		},
		'America/Araguaina' => {
			exemplarCity => q#ኣራጓይና#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#ላ ርዮሃ#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ርዮ ጋየጎስ#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#ሳልታ#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#ሳን ህዋን#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#ሳን ልዊስ#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ቱኩማን#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#ኡሽዋያ#,
		},
		'America/Aruba' => {
			exemplarCity => q#ኣሩባ#,
		},
		'America/Asuncion' => {
			exemplarCity => q#ኣሱንስዮን#,
		},
		'America/Bahia' => {
			exemplarCity => q#ባህያ#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#ባእያ ደ ባንደራስ#,
		},
		'America/Barbados' => {
			exemplarCity => q#ባርባዶስ#,
		},
		'America/Belem' => {
			exemplarCity => q#በለም#,
		},
		'America/Belize' => {
			exemplarCity => q#በሊዝ#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ብላንክ-ሳብሎን#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#ቦዋ ቪስታ#,
		},
		'America/Bogota' => {
			exemplarCity => q#ቦጎታ#,
		},
		'America/Boise' => {
			exemplarCity => q#ቦይዚ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#ብወኖስ ኣይረስ#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#ካምብሪጅ በይ#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#ካምፖ ግራንደ#,
		},
		'America/Cancun' => {
			exemplarCity => q#ካንኩን#,
		},
		'America/Caracas' => {
			exemplarCity => q#ካራካስ#,
		},
		'America/Catamarca' => {
			exemplarCity => q#ካታማርካ#,
		},
		'America/Cayenne' => {
			exemplarCity => q#ካየን#,
		},
		'America/Cayman' => {
			exemplarCity => q#ካይማን#,
		},
		'America/Chicago' => {
			exemplarCity => q#ቺካጎ#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ቺዋዋ#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#ኣቲኮካን#,
		},
		'America/Cordoba' => {
			exemplarCity => q#ኮርዶባ#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#ኮስታ ሪካ#,
		},
		'America/Creston' => {
			exemplarCity => q#ክረስተን#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#ኩያባ#,
		},
		'America/Curacao' => {
			exemplarCity => q#ኩራሳው#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ዳንማርክሻቭን#,
		},
		'America/Dawson' => {
			exemplarCity => q#ዳውሰን#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ዳውሰን ክሪክ#,
		},
		'America/Denver' => {
			exemplarCity => q#ደንቨር#,
		},
		'America/Detroit' => {
			exemplarCity => q#ዲትሮይት#,
		},
		'America/Dominica' => {
			exemplarCity => q#ዶሚኒካ#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ኤድመንተን#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ኤይሩኔፒ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ኤል ሳልቫዶር#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#ፎርት ነልሰን#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#ፎርታለዛ#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ግሌስ በይ#,
		},
		'America/Godthab' => {
			exemplarCity => q#ኑክ#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#ጉዝ በይ#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#ግራንድ ቱርክ#,
		},
		'America/Grenada' => {
			exemplarCity => q#ግረናዳ#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ጓደሉፕ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ጓቲማላ#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#ጓያኪል#,
		},
		'America/Guyana' => {
			exemplarCity => q#ጉያና#,
		},
		'America/Halifax' => {
			exemplarCity => q#ሃሊፋክስ#,
		},
		'America/Havana' => {
			exemplarCity => q#ሃቫና#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ኤርሞስዮ#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#ኖክስ፣ ኢንድያና#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#ማረንጎ፣ ኢንድያና#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#ፒተርስበርግ፣ ኢንድያና#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ተል ሲቲ፣ ኢንድያና#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ቪቪ፣ ኢንድያና#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#ቪንሰንስ፣ ኢንድያና#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ዊናማክ፣ ኢንድያና#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#ኢንድያናፖሊስ#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ኢኑቪክ#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ኢቃልዊት#,
		},
		'America/Jamaica' => {
			exemplarCity => q#ጃማይካ#,
		},
		'America/Jujuy' => {
			exemplarCity => q#ሁሁይ#,
		},
		'America/Juneau' => {
			exemplarCity => q#ጁነው#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#ሞንቲቸሎ፣ ከንታኪ#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#ክራለንዳይክ#,
		},
		'America/La_Paz' => {
			exemplarCity => q#ላ ፓዝ#,
		},
		'America/Lima' => {
			exemplarCity => q#ሊማ#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#ሎስ ኣንጀለስ#,
		},
		'America/Louisville' => {
			exemplarCity => q#ልዊቪል#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#ለወር ፕሪንሰስ ኳርተር#,
		},
		'America/Maceio' => {
			exemplarCity => q#ማሰዮ#,
		},
		'America/Managua' => {
			exemplarCity => q#ማናጓ#,
		},
		'America/Manaus' => {
			exemplarCity => q#ማናውስ#,
		},
		'America/Marigot' => {
			exemplarCity => q#ማሪጎት#,
		},
		'America/Martinique' => {
			exemplarCity => q#ማርቲኒክ#,
		},
		'America/Matamoros' => {
			exemplarCity => q#ማታሞሮስ#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#ማዛትላን#,
		},
		'America/Mendoza' => {
			exemplarCity => q#መንዶዛ#,
		},
		'America/Menominee' => {
			exemplarCity => q#ሜኖሚኒ#,
		},
		'America/Merida' => {
			exemplarCity => q#መሪዳ#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#መትላካትላ#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#ከተማ ሜክሲኮ#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ሚከሎን#,
		},
		'America/Moncton' => {
			exemplarCity => q#ሞንክተን#,
		},
		'America/Monterrey' => {
			exemplarCity => q#ሞንተረይ#,
		},
		'America/Montevideo' => {
			exemplarCity => q#ሞንተቪደዮ#,
		},
		'America/Montserrat' => {
			exemplarCity => q#ሞንትሰራት#,
		},
		'America/Nassau' => {
			exemplarCity => q#ናሳው#,
		},
		'America/New_York' => {
			exemplarCity => q#ኒው ዮርክ#,
		},
		'America/Nipigon' => {
			exemplarCity => q#ኒፒጎን#,
		},
		'America/Nome' => {
			exemplarCity => q#ነውም#,
		},
		'America/Noronha' => {
			exemplarCity => q#ኖሮንያ#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#ብዩላ፣ ሰሜን ዳኮታ#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#ሰንተር፣ ሰሜን ዳኮታ#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#ኒው ሳለም፣ ሰሜን ዳኮታ#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ኦጂናጋ#,
		},
		'America/Panama' => {
			exemplarCity => q#ፓናማ#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#ፓንግኒርተንግ#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#ፓራማሪቦ#,
		},
		'America/Phoenix' => {
			exemplarCity => q#ፊኒክስ#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#ፖርት-ኦ-ፕሪንስ#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#ፖርት ኦፍ ስፔን#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#ፖርቶ ቨልዮ#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ፖርቶ ሪኮ#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#ፑንታ ኣረናስ#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#ረይኒ ሪቨር#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#ራንኪን ኢንለት#,
		},
		'America/Recife' => {
			exemplarCity => q#ረሲፈ#,
		},
		'America/Regina' => {
			exemplarCity => q#ረጂና#,
		},
		'America/Resolute' => {
			exemplarCity => q#ረዞሉት#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ርዮ ብራንኮ#,
		},
		'America/Santarem' => {
			exemplarCity => q#ሳንታረም#,
		},
		'America/Santiago' => {
			exemplarCity => q#ሳንትያጎ#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#ሳንቶ ዶሚንጎ#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ሳኦ ፓውሎ#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#ኢቶቆርቶሚት#,
		},
		'America/Sitka' => {
			exemplarCity => q#ሲትካ#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#ቅዱስ ባርተለሚ#,
		},
		'America/St_Johns' => {
			exemplarCity => q#ቅዱስ ዮሃንስ#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#ቅዱስ ኪትስ#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#ቅድስቲ ሉስያ#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#ሰይንት ቶማስ#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#ቅዱስ ቪንሰንት#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ስዊፍት ካረንት#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ተጉሲጋልፓ#,
		},
		'America/Thule' => {
			exemplarCity => q#ዙል#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#ዛንደር በይ#,
		},
		'America/Tijuana' => {
			exemplarCity => q#ቲጅዋና#,
		},
		'America/Toronto' => {
			exemplarCity => q#ቶሮንቶ#,
		},
		'America/Tortola' => {
			exemplarCity => q#ቶርቶላ#,
		},
		'America/Vancouver' => {
			exemplarCity => q#ቫንኩቨር#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#ዋይትሆዝ#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ዊኒፐግ#,
		},
		'America/Yakutat' => {
			exemplarCity => q#ያኩታት#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#የለውናይፍ#,
		},
		'Antarctica/Casey' => {
			exemplarCity => q#ከይዚ#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#ደቪስ#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ዱሞንት ዲኡርቪል#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#ማኳሪ#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#ማውሰን#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#ማክሙርዶ#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#ፓልመር#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#ሮዘራ#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#ስዮዋ#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ትሮል#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#ቮስቶክ#,
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#ሎንግየርባየን#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣርጀንቲና#,
				'generic' => q#ግዜ ኣርጀንቲና#,
				'standard' => q#ምዱብ ግዜ ኣርጀንቲና#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#ዓደን#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#ኣልማቲ#,
		},
		'Asia/Amman' => {
			exemplarCity => q#ዓማን#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#ኣናዲር#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#ኣክታው#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#ኣክቶበ#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#ኣሽጋባት#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#ኣቲራው#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#ባቕዳድ#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#ባሕሬን#,
		},
		'Asia/Baku' => {
			exemplarCity => q#ባኩ#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#ባንግኮክ#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#ባርናውል#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#በይሩት#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#ቢሽኬክ#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#ብሩነይ#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#ኮልካታ#,
		},
		'Asia/Chita' => {
			exemplarCity => q#ቺታ#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#ቾይባልሳን#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#ኮሎምቦ#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#ደማስቆ#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ዳካ#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ዲሊ#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#ዱባይ#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#ዱሻንበ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#ፋማጉስታ#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#ቓዛ#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#ኬብሮን#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#ሆንግ ኮንግ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#ሆቭድ#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ኢርኩትስክ#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#ጃካርታ#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#ጃያፑራ#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#የሩሳሌም#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#ካቡል#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#ካምቻትካ#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#ካራቺ#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#ካትማንዱ#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#ካንዲጋ#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#ክራስኖያርስክ#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#ኳላ ሉምፑር#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#ኩቺንግ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#ኩዌት#,
		},
		'Asia/Macau' => {
			exemplarCity => q#ማካው#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#ማጋዳን#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#ማካሳር#,
		},
		'Asia/Manila' => {
			exemplarCity => q#ማኒላ#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#ሙስካት#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#ኒኮስያ#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#ኖቮኩዝነትስክ#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#ኖቮሲቢርስክ#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ኦምስክ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ኦራል#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#ፕኖም ፐን#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#ፖንትያናክ#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#ፕዮንግያንግ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#ቐጠር#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#ኮስታናይ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#ኪዚሎርዳ#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#ያንጎን#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#ርያድ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#ከተማ ሆ ቺ ሚን#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#ሳካሊን#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#ሳማርካንድ#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#ሶውል#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#ሻንግሃይ#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#ሲንጋፖር#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#ስሬድነኮሊምስክ#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#ታይፐይ#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#ታሽከንት#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#ትቢሊሲ#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#ተህራን#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#ቲምፉ#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ቶክዮ#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#ቶምስክ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ኡላን ባቶር#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#ኡሩምኪ#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#ኡስት-ኔራ#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#ቭየንትያን#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#ቭላዲቮስቶክ#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#ያኩትስክ#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#የካተሪንበርግ#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#የረቫን#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#ኣዞረስ#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#በርሙዳ#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#ካናሪ#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#ኬፕ ቨርደ#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#ደሴታት ፋሮ#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#ማደይራ#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ረይክያቪክ#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#ደቡብ ጆርጅያ#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#ቅድስቲ ሄለና#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#ስታንሊ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#ኣደለይድ#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#ብሪዝቤን#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#ብሮክን ሂል#,
		},
		'Australia/Currie' => {
			exemplarCity => q#ኩሪ#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ዳርዊን#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#ዩክላ#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#ሆባርት#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#ሊንድማን#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#ሎርድ ሃው#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#መልበርን#,
		},
		'Australia/Perth' => {
			exemplarCity => q#ፐርዝ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#ሲድኒ#,
		},
		'Azores' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣዞረስ#,
				'generic' => q#ግዜ ኣዞረስ#,
				'standard' => q#ምዱብ ግዜ ኣዞረስ#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#ግዜ ቦሊቭያ#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ብራዚልያ#,
				'generic' => q#ግዜ ብራዚልያ#,
				'standard' => q#ምዱብ ግዜ ብራዚልያ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኬፕ ቨርደ#,
				'generic' => q#ግዜ ኬፕ ቨርደ#,
				'standard' => q#ምዱብ ግዜ ኬፕ ቨርደ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ቺሌ#,
				'generic' => q#ግዜ ቺሌ#,
				'standard' => q#ምዱብ ግዜ ቺሌ#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኮሎምብያ#,
				'generic' => q#ግዜ ኮሎምብያ#,
				'standard' => q#ምዱብ ግዜ ኮሎምብያ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ደሴት ፋሲካ#,
				'generic' => q#ግዜ ደሴት ፋሲካ#,
				'standard' => q#ምዱብ ግዜ ደሴት ፋሲካ#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ግዜ ኤኳዶር#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ዝተሳነየ ኣድማሳዊ ግዜ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ዘይተፈልጠ ከተማ#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#ኣምስተርዳም#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#ኣንዶራ#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#ኣስትራካን#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ኣቴንስ#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#በልግሬድ#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#በርሊን#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#ብራቲስላቫ#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#ብራስልስ#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#ቡካረስት#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#ቡዳፐስት#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#ቡሲንገን#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#ኪሺናው#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#ኮፐንሃገን#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ደብሊን#,
			long => {
				'daylight' => q#Irish Standard Time#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#ጂብራልታር#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#ገርንዚ#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#ሄልሲንኪ#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#ኣይል ኦፍ ማን#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#ኢስታንቡል#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#ጀርዚ#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#ካሊኒንግራድ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#ክየቭ#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#ኪሮቭ#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#ሊዝበን#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ልዩብልያና#,
		},
		'Europe/London' => {
			exemplarCity => q#ሎንደን#,
			long => {
				'daylight' => q#ግዜ ክረምቲ ብሪጣንያ#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#ሉክሰምበርግ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#ማድሪድ#,
		},
		'Europe/Malta' => {
			exemplarCity => q#ማልታ#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#ማሪሃምን#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#ሚንስክ#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#ሞናኮ#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#ሞስኮ#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#ኦስሎ#,
		},
		'Europe/Paris' => {
			exemplarCity => q#ፓሪስ#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#ፖድጎሪጻ#,
		},
		'Europe/Prague' => {
			exemplarCity => q#ፕራግ#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ሪጋ#,
		},
		'Europe/Rome' => {
			exemplarCity => q#ሮማ#,
		},
		'Europe/Samara' => {
			exemplarCity => q#ሳማራ#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#ሳን ማሪኖ#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#ሳራየቮ#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#ሳራቶቭ#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#ሲምፈሮፖል#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#ስኮፕየ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#ሶፍያ#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#ስቶክሆልም#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#ታሊን#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#ቲራና#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ኡልያኖቭስክ#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#ኡዝጎሮድ#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#ቫዱዝ#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#ቫቲካን#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#ቭየና#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#ቪልንየስ#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#ቮልጎግራድ#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#ዋርሳው#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#ዛግረብ#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#ዛፖሪዥያ#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#ዙሪክ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኤውሮጳ#,
				'generic' => q#ግዜ ማእከላይ ኤውሮጳ#,
				'standard' => q#ምዱብ ግዜ ማእከላይ ኤውሮጳ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ምብራቕ ኤውሮጳ#,
				'generic' => q#ግዜ ምብራቕ ኤውሮጳ#,
				'standard' => q#ምዱብ ግዜ ምብራቕ ኤውሮጳ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ግዜ ከረምቲ ደሴታት ፎክላንድ#,
				'generic' => q#ግዜ ደሴታት ፎክላንድ#,
				'standard' => q#ምዱብ ግዜ ደሴታት ፎክላንድ#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ግዜ ፈረንሳዊት ጊያና#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ግዜ ፈረንሳዊ ደቡባዊ ግዝኣታትን ኣንታርቲክን#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ግዜ ጋላፓጎስ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ግዜ ጉያና#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#ኣንታናናሪቮ#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#ቻጎስ#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#ክሪስማስ#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#ኮኮስ#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#ኮሞሮ#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#ከርጉለን#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#ማሄ#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#ማልዲቭስ#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#ማውሪሸስ#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#ማዮት#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ርዩንየን#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ግዜ ህንዳዊ ውቅያኖስ#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#ግዜ ማእከላይ ኢንዶነዥያ#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#ግዜ ምብራቓዊ ኢንዶነዥያ#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#ግዜ ምዕራባዊ ኢንዶነዥያ#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ግዜ ማለዥያ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ማውሪሸስ#,
				'generic' => q#ግዜ ማውሪሸስ#,
				'standard' => q#ምዱብ ግዜ ማውሪሸስ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ፈርናንዶ ደ ኖሮንያ#,
				'generic' => q#ግዜ ፈርናንዶ ደ ኖሮንያ#,
				'standard' => q#ምዱብ ግዜ ፈርናንዶ ደ ኖሮንያ#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#ኣፕያ#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ኦክላንድ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#ቡገንቪል#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#ቻታም#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ደሴት ፋሲካ#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ኤፋቴ#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#ኤንደርበሪ#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#ፋካኦፎ#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#ፊጂ#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#ፉናፉቲ#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#ጋላፓጎስ#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#ጋምብየር#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#ጓዳልካናል#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#ጓም#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#ሆኖሉሉ#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#ጆንስተን#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#ኪሪቲማቲ#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#ኮስሬ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#ክዋጃሊን#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#ማጁሮ#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#ማርኬሳስ#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#ሚድወይ#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#ናውሩ#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#ኒዩ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#ኖርፎልክ#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#ኑመያ#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#ፓጎ ፓጎ#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#ፓላው#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#ፒትከርን#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#ፖንፐይ#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#ፖርት ሞርስቢ#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#ራሮቶንጋ#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#ሳይፓን#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ታሂቲ#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#ታራዋ#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ቶንጋታፑ#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#ቹክ#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#ዌክ#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#ዋሊስ#,
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ፓራጓይ#,
				'generic' => q#ግዜ ፓራጓይ#,
				'standard' => q#ምዱብ ግዜ ፓራጓይ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ፔሩ#,
				'generic' => q#ግዜ ፔሩ#,
				'standard' => q#ምዱብ ግዜ ፔሩ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ግዜ ርዩንየን#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#ግዜ ሲሸልስ#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#ግዜ ሲንጋፖር#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#ግዜ ደቡብ ጆርጅያ#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#ግዜ ሱሪናም#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኡራጓይ#,
				'generic' => q#ግዜ ኡራጓይ#,
				'standard' => q#ምዱብ ግዜ ኡራጓይ#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ግዜ ቬኔዝዌላ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
