=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ti - Package for language Tigrinya

=cut

package Locale::CLDR::Locales::Ti;
# This file auto generated from Data\common\main\ti.xml
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
				'aa' => 'አፋር',
 				'ab' => 'ኣብካዝኛ',
 				'ace' => 'ኣቸኒዝኛ',
 				'ada' => 'ኣዳንግሜ',
 				'ady' => 'ኣዲጊ',
 				'af' => 'ኣፍሪካንስ',
 				'agq' => 'ኣገም',
 				'ain' => 'ኣይኑ',
 				'ak' => 'ኣካን',
 				'ale' => 'ኣለውትኛ',
 				'alt' => 'ደቡባዊ ኣልታይ',
 				'am' => 'ኣምሓርኛ',
 				'an' => 'ኣራጎንኛ',
 				'ann' => 'ኦቦሎ',
 				'anp' => 'ኣንጂካ',
 				'apc' => 'ሌቫንቲናዊ ዓረብኛ',
 				'ar' => 'ዓረብኛ',
 				'ar_001' => 'ዘመናዊ ምዱብ ዓረብኛ',
 				'arn' => 'ማፑቺ',
 				'arp' => 'ኣራፓሆ',
 				'ars' => 'ናጅዲ ዓረብኛ',
 				'as' => 'ኣሳሜዝኛ',
 				'asa' => 'ኣሱ',
 				'ast' => 'ኣስቱርያን',
 				'atj' => 'ኣቲካመክ',
 				'av' => 'ኣቫርኛ',
 				'awa' => 'ኣዋዲ',
 				'ay' => 'ኣይማራ',
 				'az' => 'ኣዘርባጃንኛ',
 				'az@alt=short' => 'ኣዘሪ',
 				'ba' => 'ባሽኪር',
 				'bal' => 'ባሉቺ',
 				'ban' => 'ባሊንኛ',
 				'bas' => 'ባሳ',
 				'be' => 'ቤላሩስኛ',
 				'bem' => 'ቤምባ',
 				'bew' => 'ቤታዊ',
 				'bez' => 'በና',
 				'bg' => 'ቡልጋርኛ',
 				'bgc' => 'ሃርያንቪ',
 				'bgn' => 'ምዕራባዊ ባሎቺ',
 				'bho' => 'ቦጅፑሪ',
 				'bi' => 'ቢስላማ',
 				'bin' => 'ቢኒ',
 				'bla' => 'ሲክሲካ',
 				'blo' => 'ኣኒ',
 				'blt' => 'ታይ ዳም',
 				'bm' => 'ባምባራ',
 				'bn' => 'በንጋሊ',
 				'bo' => 'ቲበታንኛ',
 				'br' => 'ብረቶንኛ',
 				'brx' => 'ቦዶ',
 				'bs' => 'ቦዝንኛ',
 				'bss' => 'ኣኮስ',
 				'bug' => 'ቡጊንኛ',
 				'byn' => 'ብሊን',
 				'ca' => 'ካታላን',
 				'cad' => 'ካድዶ',
 				'cay' => 'ካዩጋ',
 				'cch' => 'ኣትሳም',
 				'ccp' => 'ቻክማ',
 				'ce' => 'ቸቸንይና',
 				'ceb' => 'ሰብዋኖ',
 				'cgg' => 'ቺጋ',
 				'ch' => 'ቻሞሮ',
 				'chk' => 'ቹኪዝኛ',
 				'chm' => 'ማሪ',
 				'cho' => 'ቾክቶ',
 				'chp' => 'ቺፐውያን',
 				'chr' => 'ቸሮኪ',
 				'chy' => 'ሻያን',
 				'cic' => 'ቺካሳው',
 				'ckb' => 'ማእከላይ ኩርዲሽ',
 				'ckb@alt=menu' => 'ኩርዲሽ፣ ማእከላይ',
 				'ckb@alt=variant' => 'ኩርዲሽ፣ ሶራኒ',
 				'clc' => 'ቺልኮቲን',
 				'co' => 'ኮርስኛ',
 				'crg' => 'ሚቺፍ',
 				'crj' => 'ደቡባዊ ምብራቕ ክሪ',
 				'crk' => 'ክሪ ፕሌንስ',
 				'crl' => 'ሰሜናዊ ምብራቕ ክሪ',
 				'crm' => 'ሙስ ክሪ',
 				'crr' => 'ካሮሊና አልጎንጉያኛ',
 				'cs' => 'ቸክኛ',
 				'csw' => 'ክሪ ረግረግ',
 				'cu' => 'ቤተ-ክርስትያን ስላቭኛ',
 				'cv' => 'ቹቫሽኛ',
 				'cy' => 'ዌልስኛ',
 				'da' => 'ዳኒሽ',
 				'dak' => 'ዳኮታ',
 				'dar' => 'ዳርግዋ',
 				'dav' => 'ታይታ',
 				'de' => 'ጀርመን',
 				'dgr' => 'ዶግሪብ',
 				'dje' => 'ዛርማ',
 				'doi' => 'ዶግሪ',
 				'dsb' => 'ታሕተዋይ ሶርብኛ',
 				'dua' => 'ድዋላ',
 				'dv' => 'ዲቨሂ',
 				'dyo' => 'ጆላ-ፎኒይ',
 				'dz' => 'ድዞንግካ',
 				'dzg' => 'ዳዛጋ',
 				'ebu' => 'ኤምቡ',
 				'ee' => 'ኢው',
 				'efi' => 'ኤፊክ',
 				'eka' => 'ኤካጁክ',
 				'el' => 'ግሪኽኛ',
 				'en' => 'እንግሊዝኛ',
 				'en_US@alt=short' => 'እንግሊዝኛ (ሕ.መ.)',
 				'eo' => 'ኤስፐራንቶ',
 				'es' => 'ስጳንኛ',
 				'es_ES' => 'ስጳንኛ (ኤውሮጳዊ)',
 				'et' => 'ኤስቶንኛ',
 				'eu' => 'ባስክኛ',
 				'ewo' => 'ኤዎንዶ',
 				'fa' => 'ፋርስኛ',
 				'fa_AF' => 'ዳሪ',
 				'ff' => 'ፉላ',
 				'fi' => 'ፊንላንድኛ',
 				'fil' => 'ፊሊፒንኛ',
 				'fj' => 'ፊጅያንኛ',
 				'fo' => 'ፋሮእይና',
 				'fon' => 'ፎን',
 				'fr' => 'ፈረንሳይኛ',
 				'frc' => 'ካጁን ፈረንሳይ',
 				'frr' => 'ሰሜናዊ ፍሪስኛ',
 				'fur' => 'ፍርዩልኛ',
 				'fy' => 'ምዕራባዊ ፍሪስኛ',
 				'ga' => 'ኣየርላንድኛ',
 				'gaa' => 'ጋ',
 				'gd' => 'ስኮትላንዳዊ ጋኤሊክኛ',
 				'gez' => 'ግእዝ',
 				'gil' => 'ጊልበርትኛ',
 				'gl' => 'ጋሊሽያን',
 				'gn' => 'ጓራኒ',
 				'gor' => 'ጎሮንታሎ',
 				'gsw' => 'ስዊዘርላንዳዊ ጀርመን',
 				'gu' => 'ጉጃራቲ',
 				'guz' => 'ጉሲ',
 				'gv' => 'ማንክስ',
 				'gwi' => 'ጒቺን',
 				'ha' => 'ሃውሳ',
 				'hai' => 'ሃይዳ',
 				'haw' => 'ሃዋይኛ',
 				'hax' => 'ደቡባዊ ሃይዳ',
 				'he' => 'እብራይስጢ',
 				'hi' => 'ሂንዲ',
 				'hi_Latn@alt=variant' => 'ሂንግሊሽ',
 				'hil' => 'ሂሊጋይኖን',
 				'hmn' => 'ህሞንግ',
 				'hnj' => 'ህሞንግ ንጁዋ',
 				'hr' => 'ክሮኤሽያን',
 				'hsb' => 'ላዕለዋይ ሶርብኛ',
 				'ht' => 'ክርዮል ሃይትኛ',
 				'hu' => 'ሃንጋርኛ',
 				'hup' => 'ሁፓ',
 				'hur' => 'ሃልኮመለም',
 				'hy' => 'ኣርሜንኛ',
 				'hz' => 'ሄረሮ',
 				'ia' => 'ኢንተርሊንጓ',
 				'iba' => 'ኢባን',
 				'ibb' => 'ኢቢብዮ',
 				'id' => 'ኢንዶነዥኛ',
 				'ie' => 'ኢንተርሊንጔ',
 				'ig' => 'ኢግቦ',
 				'ii' => 'ሲችዋን ዪ',
 				'ikt' => 'ምዕራባዊ ካናዳዊ ኢናክቲቱት',
 				'ilo' => 'ኢሎካኖ',
 				'inh' => 'ኢንጉሽኛ',
 				'io' => 'ኢዶ',
 				'is' => 'ኣይስላንድኛ',
 				'it' => 'ጥልያን',
 				'iu' => 'ኢናክቲቱት',
 				'ja' => 'ጃፓንኛ',
 				'jbo' => 'ሎጅባን',
 				'jgo' => 'ኤንጎምባ',
 				'jmc' => 'ማኬም',
 				'jv' => 'ጃቫንኛ',
 				'ka' => 'ጆርጅያንኛ',
 				'kaa' => 'ካራ-ካልፓክ',
 				'kab' => 'ካቢልኛ',
 				'kac' => 'ካቺን',
 				'kaj' => 'ጅጁ',
 				'kam' => 'ካምባ',
 				'kbd' => 'ካባርድኛ',
 				'kcg' => 'ታያፕ',
 				'kde' => 'ማኮንደ',
 				'kea' => 'ክርዮል ኬፕ ቨርድኛ',
 				'ken' => 'ኬንያንግ',
 				'kfo' => 'ኮሮ',
 				'kgp' => 'ካይንጋንግ',
 				'kha' => 'ካሲ',
 				'khq' => 'ኮይራ ቺኒ',
 				'ki' => 'ኪኩዩ',
 				'kj' => 'ክዋንያማ',
 				'kk' => 'ካዛክ',
 				'kkj' => 'ካኮ',
 				'kl' => 'ግሪንላንድኛ',
 				'kln' => 'ካለንጂን',
 				'km' => 'ክመር',
 				'kmb' => 'ኪምቡንዱ',
 				'kn' => 'ካንናዳ',
 				'ko' => 'ኮርይኛ',
 				'kok' => 'ኮንካኒ',
 				'kpe' => 'ክፐለ',
 				'kr' => 'ካኑሪ',
 				'krc' => 'ካራቻይ-ባልካርኛ',
 				'krl' => 'ካረልኛ',
 				'kru' => 'ኩሩክ',
 				'ks' => 'ካሽሚሪ',
 				'ksb' => 'ሻምባላ',
 				'ksf' => 'ባፍያ',
 				'ksh' => 'ኮሎግኒያን',
 				'ku' => 'ኩርዲሽ',
 				'kum' => 'ኩሚይክ',
 				'kv' => 'ኮሚ',
 				'kw' => 'ኮርንኛ',
 				'kwk' => 'ክዋክዋላ',
 				'kxv' => 'ኩቪ',
 				'ky' => 'ኪርጊዝኛ',
 				'la' => 'ላቲን',
 				'lad' => 'ላዲኖ',
 				'lag' => 'ላንጊ',
 				'lb' => 'ሉክሰምበርግኛ',
 				'lez' => 'ለዝግኛ',
 				'lg' => 'ጋንዳ',
 				'li' => 'ሊምበርግኛ',
 				'lij' => 'ሊጉርኛ',
 				'lil' => 'ሊሉት',
 				'lkt' => 'ላኮታ',
 				'lmo' => 'ሎምባርድኛ',
 				'ln' => 'ሊንጋላ',
 				'lo' => 'ላኦ',
 				'lou' => 'ክርዮል ሉዊዝያና',
 				'loz' => 'ሎዚ',
 				'lrc' => 'ሰሜናዊ ሉሪ',
 				'lsm' => 'ሳምያ',
 				'lt' => 'ሊትዌንኛ',
 				'ltg' => 'ላትጋላዊ',
 				'lu' => 'ሉባ-ካታንጋ',
 				'lua' => 'ሉባ-ሉልዋ',
 				'lun' => 'ሉንዳ',
 				'luo' => 'ሉኦ',
 				'lus' => 'ማይዞ',
 				'luy' => 'ሉይያ',
 				'lv' => 'ላትቭኛ',
 				'mad' => 'ማዱሪዝኛ',
 				'mag' => 'ማጋሂ',
 				'mai' => 'ማይቲሊ',
 				'mak' => 'ማካሳር',
 				'mas' => 'ማሳይ',
 				'mdf' => 'ሞክሻ',
 				'men' => 'መንዴ',
 				'mer' => 'መሩ',
 				'mfe' => 'ክርዮል ማውሪሽይና',
 				'mg' => 'ማላጋሲ',
 				'mgh' => 'ማክዋ-ሜቶ',
 				'mgo' => 'መታ',
 				'mh' => 'ማርሻሊዝኛ',
 				'mi' => 'ማኦሪ',
 				'mic' => 'ሚክማክ',
 				'min' => 'ሚናንግካባው',
 				'mk' => 'መቄዶንኛ',
 				'ml' => 'ማላያላም',
 				'mn' => 'ሞንጎልኛ',
 				'mni' => 'ማኒፑሪ',
 				'moe' => 'ኢኑ-ኤመን',
 				'moh' => 'ሞሃውክ',
 				'mos' => 'ሞሲ',
 				'mr' => 'ማራቲ',
 				'ms' => 'ማላይኛ',
 				'mt' => 'ማልትኛ',
 				'mua' => 'ሙንዳንግ',
 				'mul' => 'ዝተፈላለዩ ቋንቋታት',
 				'mus' => 'ክሪክ',
 				'mwl' => 'ሚራንዲዝኛ',
 				'my' => 'በርምኛ',
 				'myv' => 'ኤርዝያ',
 				'mzn' => 'ማዛንደራኒ',
 				'na' => 'ናውርዋንኛ',
 				'nap' => 'ኒያፖሊታንኛ',
 				'naq' => 'ናማ',
 				'nb' => 'ኖርወያዊ ቦክማል',
 				'nd' => 'ሰሜን ኤንደበለ',
 				'nds' => 'ትሑት ጀርመን',
 				'nds_NL' => 'ትሑት ሳክሰን',
 				'ne' => 'ኔፓሊ',
 				'new' => 'ነዋሪ',
 				'ng' => 'ኤንዶንጋ',
 				'nia' => 'ንያስ',
 				'niu' => 'ንዌንኛ',
 				'nl' => 'ዳች',
 				'nl_BE' => 'ፍላሚሽ',
 				'nmg' => 'ክዋስዮ',
 				'nn' => 'ኖርወያዊ ናይኖርስክ',
 				'nnh' => 'ኤንጌምቡን',
 				'no' => 'ኖርወይኛ',
 				'nog' => 'ኖጋይኛ',
 				'nqo' => 'ኤንኮ',
 				'nr' => 'ደቡብ ኤንደበለ',
 				'nso' => 'ሰሜናዊ ሶቶ',
 				'nus' => 'ንዌር',
 				'nv' => 'ናቫሆ',
 				'ny' => 'ንያንጃ',
 				'nyn' => 'ንያንኮል',
 				'oc' => 'ኦክሲታንኛ',
 				'ojb' => 'ሰሜናዊ ምዕራብ ኦጂብዋ',
 				'ojc' => 'ማእከላይ ኦጂብዋ',
 				'ojs' => 'ኦጂ-ክሪ',
 				'ojw' => 'ምዕራባዊ ኦጂብዋ',
 				'oka' => 'ኦካናጋን',
 				'om' => 'ኦሮሞ',
 				'or' => 'ኦድያ',
 				'os' => 'ኦሰትኛ',
 				'osa' => 'ኦሳጌ',
 				'pa' => 'ፑንጃቢ',
 				'pag' => 'ፓንጋሲናን',
 				'pam' => 'ፓምፓንጋ',
 				'pap' => 'ፓፕያመንቶ',
 				'pau' => 'ፓላውኛ',
 				'pcm' => 'ፒጂን ናይጀርያ',
 				'pis' => 'ፒጂን',
 				'pl' => 'ፖሊሽ',
 				'pqm' => 'ማሊሲት-ፓሳማኳዲ',
 				'prg' => 'ፕሩስኛ',
 				'ps' => 'ፓሽቶ',
 				'pt' => 'ፖርቱጊዝኛ',
 				'qu' => 'ቀችዋ',
 				'quc' => 'ኪቼ',
 				'raj' => 'ራጃስታኒ',
 				'rap' => 'ራፓኑይ',
 				'rar' => 'ራሮቶንጋንኛ',
 				'rhg' => 'ሮሂንግያ',
 				'rif' => 'ሪፍኛ',
 				'rm' => 'ሮማንሽ',
 				'rn' => 'ኪሩንዲ',
 				'ro' => 'ሩማንኛ',
 				'ro_MD' => 'ሞልዶቨኛ',
 				'rof' => 'ሮምቦ',
 				'ru' => 'ሩስኛ',
 				'rup' => 'ኣሩማንኛ',
 				'rw' => 'ኪንያርዋንዳ',
 				'rwk' => 'ርዋ',
 				'sa' => 'ሳንስክሪት',
 				'sad' => 'ሳንዳወ',
 				'sah' => 'ሳኻ',
 				'saq' => 'ሳምቡሩ',
 				'sat' => 'ሳንታሊ',
 				'sba' => 'ኤንጋምባይ',
 				'sbp' => 'ሳንጉ',
 				'sc' => 'ሳርዲንኛ',
 				'scn' => 'ሲሲልኛ',
 				'sco' => 'ስኮትኛ',
 				'sd' => 'ሲንድሂ',
 				'sdh' => 'ደቡባዊ ኩርዲሽ',
 				'se' => 'ሰሜናዊ ሳሚ',
 				'seh' => 'ሰና',
 				'ses' => 'ኮይራቦሮ ሰኒ',
 				'sg' => 'ሳንጎ',
 				'sh' => 'ሰርቦ-ክሮኤሽያኛ',
 				'shi' => 'ታቸልሂት',
 				'shn' => 'ሻን',
 				'si' => 'ሲንሃላ',
 				'sid' => 'ሲዳመኛ',
 				'sk' => 'ስሎቫክኛ',
 				'sl' => 'ስሎቬንኛ',
 				'slh' => 'ደቡባዊ ሉሹትሲድ',
 				'sm' => 'ሳሞእኛ',
 				'sma' => 'ደቡባዊ ሳሚ',
 				'smj' => 'ሉለ ሳሚ',
 				'smn' => 'ሳሚ ኢናሪ',
 				'sms' => 'ሳሚ ስኮልት',
 				'sn' => 'ሾና',
 				'snk' => 'ሶኒንከ',
 				'so' => 'ሶማሊ',
 				'sq' => 'ኣልባንኛ',
 				'sr' => 'ሰርቢያኛ',
 				'srn' => 'ስራናን ቶንጎ',
 				'ss' => 'ስዋዚ',
 				'ssy' => 'ሳሆ',
 				'st' => 'ደቡባዊ ሶቶ',
 				'str' => 'ሳሊሽ መጻብቦታት',
 				'su' => 'ሱዳንኛ',
 				'suk' => 'ሱኩማ',
 				'sv' => 'ስዊድንኛ',
 				'sw' => 'ስዋሂሊ',
 				'sw_CD' => 'ስዋሂሊ (ኮንጎ)',
 				'swb' => 'ኮሞርኛ',
 				'syr' => 'ሶርያኛ',
 				'szl' => 'ሲሌሲያን',
 				'ta' => 'ታሚል',
 				'tce' => 'ደቡባዊ ታትቾን',
 				'te' => 'ተሉጉ',
 				'tem' => 'ቲምኔ',
 				'teo' => 'ተሶ',
 				'tet' => 'ቲተም',
 				'tg' => 'ታጂክኛ',
 				'tgx' => 'ታጊሽ',
 				'th' => 'ታይኛ',
 				'tht' => 'ታልተን',
 				'ti' => 'ትግርኛ',
 				'tig' => 'ትግረ',
 				'tk' => 'ቱርክመንኛ',
 				'tlh' => 'ክሊንጎን',
 				'tli' => 'ትሊንጊት',
 				'tn' => 'ስዋና',
 				'to' => 'ቶንጋንኛ',
 				'tok' => 'ቶኪ ፖና',
 				'tpi' => 'ቶክ ፒሲን',
 				'tr' => 'ቱርክኛ',
 				'trv' => 'ታሮኮ',
 				'trw' => 'ቶርዋሊኛ',
 				'ts' => 'ሶንጋ',
 				'tt' => 'ታታር',
 				'ttm' => 'ሰሜናዊ ታትቾን',
 				'tum' => 'ተምቡካ',
 				'tvl' => 'ቱቫልዋንኛ',
 				'tw' => 'ትዊ',
 				'twq' => 'ታሳዋቅ',
 				'ty' => 'ታሂትኛ',
 				'tyv' => 'ቱቪንኛ',
 				'tzm' => 'ማእከላይ ኣትላስ ታማዛይት',
 				'udm' => 'ዩድሙርት',
 				'ug' => 'ኡይጉር',
 				'uk' => 'ዩክረይንኛ',
 				'umb' => 'ኣምቡንዱ',
 				'und' => 'ዘይተፈልጠ ቋንቋ',
 				'ur' => 'ኡርዱ',
 				'uz' => 'ኡዝበክኛ',
 				'vai' => 'ቫይ',
 				've' => 'ቨንዳ',
 				'vec' => 'ቬንቲያንኛ',
 				'vi' => 'ቬትናምኛ',
 				'vmw' => 'ማክሁዋ',
 				'vo' => 'ቮላፑክ',
 				'vun' => 'ቩንጆ',
 				'wa' => 'ዋሎን',
 				'wae' => 'ዋልሰር',
 				'wal' => 'ዎላይታኛ',
 				'war' => 'ዋራይ',
 				'wbp' => 'ዋርልፒሪ',
 				'wo' => 'ዎሎፍ',
 				'wuu' => 'ቻይናዊ ዉ',
 				'xal' => 'ካልምይክ',
 				'xh' => 'ኮሳ',
 				'xnr' => 'ካንጋሪኛ',
 				'xog' => 'ሶጋ',
 				'yav' => 'ያንግበን',
 				'ybb' => 'የምባ',
 				'yi' => 'ይሁድኛ',
 				'yo' => 'ዮሩባ',
 				'yrl' => 'ኒንጋቱ',
 				'yue' => 'ካንቶንኛ',
 				'yue@alt=menu' => 'ቻይናዊ ካንቶንኛ',
 				'za' => 'ዙኣንግ',
 				'zgh' => 'ሞሮካዊ ምዱብ ታማዛይት',
 				'zh' => 'ቻይንኛ',
 				'zh@alt=menu' => 'ማንዳሪን ቻይንኛ',
 				'zh_Hans' => 'ቀሊል ቻይንኛ',
 				'zh_Hans@alt=long' => 'ቀሊል ማንዳሪን ቻይንኛ',
 				'zh_Hant' => 'ባህላዊ ቻይንኛ',
 				'zh_Hant@alt=long' => 'ባህላዊ ማንዳሪን ቻይንኛ',
 				'zu' => 'ዙሉ',
 				'zun' => 'ዙኚ',
 				'zxx' => 'ቋንቋዊ ትሕዝቶ የለን',
 				'zza' => 'ዛዛኪ',

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
			'Adlm' => 'አድላም',
 			'Arab' => 'ዓረብኛ',
 			'Aran' => 'ናስታሊ',
 			'Armn' => 'ዓይቡቤን',
 			'Beng' => 'ቋንቋ ቤንጋል',
 			'Bopo' => 'ቦፖሞፎ',
 			'Brai' => 'ብሬል',
 			'Cakm' => 'ቻክማ',
 			'Cans' => 'ውሁድ ካናዳዊ ኣቦርጅናል ሲላቢክስ',
 			'Cher' => 'ቼሪዮክ',
 			'Cyrl' => 'ቋንቋ ሲሪል',
 			'Deva' => 'ዴቫንጋሪ',
 			'Ethi' => 'እትዮጵያዊ',
 			'Geor' => 'ናይ ጆርጅያ',
 			'Grek' => 'ግሪክ',
 			'Gujr' => 'ጉጃርቲ',
 			'Guru' => 'ጉርሙኪ',
 			'Hanb' => 'ሃን ምስ ቦፖሞፎ',
 			'Hang' => 'ሃንጉል',
 			'Hani' => 'ሃን',
 			'Hans' => 'ዝተቐለለ',
 			'Hans@alt=stand-alone' => 'ዝተቐለለ ሃን',
 			'Hant' => 'ባህላዊ',
 			'Hant@alt=stand-alone' => 'ባህላዊ ሃን',
 			'Hebr' => 'ኢብራይስጥ',
 			'Hira' => 'ሂራጋና',
 			'Hrkt' => 'ጃፓናዊ ሲለባሪታት',
 			'Jamo' => 'ጃሞ',
 			'Jpan' => 'ጃፓናዊ',
 			'Kana' => 'ካታካና',
 			'Khmr' => 'ክመር',
 			'Knda' => 'ካናዳ',
 			'Kore' => 'ኮርያዊ',
 			'Laoo' => 'ሌኦ',
 			'Latn' => 'ላቲን',
 			'Mlym' => 'ማላያላም',
 			'Mong' => 'ማኦንጎላዊ',
 			'Mtei' => 'መይተይ ማየክ',
 			'Mymr' => 'ማይንማር',
 			'Nkoo' => 'ንኮ',
 			'Olck' => 'ኦል ቺኪ',
 			'Orya' => 'ኦዲያ',
 			'Rohg' => 'ሃኒፊ',
 			'Sinh' => 'ሲንሃላ',
 			'Sund' => 'ሱንዳናዊ',
 			'Syrc' => 'ስይሪክ',
 			'Taml' => 'ታሚል',
 			'Telu' => 'ቴሉጉ',
 			'Tfng' => 'ቲፊንጋ',
 			'Thaa' => 'ትሃና',
 			'Thai' => 'ታይ',
 			'Tibt' => 'ቲቤት',
 			'Vaii' => 'ቫይ',
 			'Yiii' => 'ዪ',
 			'Zmth' => 'ናይ ሒሳብ ምልክት',
 			'Zsye' => 'ኢሞጂ',
 			'Zsym' => 'ምልክታት',
 			'Zxxx' => 'ዘይተጻሕፈ',
 			'Zyyy' => 'ልሙድ',
 			'Zzzz' => 'ዘይፍለጥ ኢደ ጽሑፍ',

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
 			'CQ' => 'ሳርክ',
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
 			'MP' => 'ሰሜናዊ ደሴታት ማርያና',
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
 			'PF' => 'ፈረንሳዊት ፖሊነዥያ',
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
 			'TD' => 'ቻድ',
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
 			'collation' => 'ስርዓት ምድላው',
 			'currency' => 'ባጤራ',
 			'hc' => 'ዑደት ሰዓት (12 ኣንጻር 24)',
 			'lb' => 'ቅዲ ምብታኽ መስመር',
 			'ms' => 'ስርዓት መለክዒ',
 			'numbers' => 'ቁጽርታት',

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
 				'buddhist' => q{ናይ ቡድሃ ዓውደ ኣዋርሕ},
 				'chinese' => q{ናይ ቻይናዊ ዓውደ ኣዋርሕ},
 				'coptic' => q{ናይ ቅብጣዊ ዓውደ ኣዋርሕ},
 				'dangi' => q{ናይ ዳንጊ ዓውደ ኣዋርሕ},
 				'ethiopic' => q{ናይ ግእዝ ዓውደ ኣዋርሕ},
 				'ethiopic-amete-alem' => q{ግእዝ ኣመተ ኣለም ዓውደ ኣዋርሕ},
 				'gregorian' => q{ጎርጎርዮሳዊ ዓውደ ኣዋርሕ},
 				'hebrew' => q{ናይ እብራይስጢ ዓውደ ኣዋርሕ},
 				'islamic' => q{ናይ ሂጅሪ ዓውደ ኣዋርሕ},
 				'islamic-civil' => q{ናይ ሂጅሪ ዓውደ ኣዋርሕ (ሰንጠረዥ፣ ሲቪላዊ ዘመን)},
 				'islamic-tbla' => q{ናይ ሂጅሪ ዓውደ ኣዋርሕ (ሰንጠረዥ፣ ስነ-ፍልጠታዊ ዘመን)},
 				'islamic-umalqura' => q{ናይ ሂጅሪ ዓውደ ኣዋርሕ (ኡም ኣል-ቁራ)},
 				'iso8601' => q{ISO-8601 ዓውደ ኣዋርሕ},
 				'japanese' => q{ናይ ጃፓናዊ ዓውደ ኣዋርሕ},
 				'persian' => q{ናይ ፋርስ ዓውደ ኣዋርሕ},
 				'roc' => q{ናይ ሪፓብሊክ ቻይና ዓውደ ኣዋርሕ},
 			},
 			'cf' => {
 				'account' => q{ቅርጺ ባጤራ ሕሳብ},
 				'standard' => q{መደበኛ ቅርጺ ባጤራ},
 			},
 			'collation' => {
 				'ducet' => q{ነባሪ ዩኒኮድ ስርዓት ምድላው},
 				'search' => q{ሓፈሻዊ-ዕላማ ምድላይ},
 				'standard' => q{መደበኛ ምድላው ስርዓት},
 			},
 			'hc' => {
 				'h11' => q{ስርዓት 12 ሰዓታት (0–11)},
 				'h12' => q{ስርዓት 12 ሰዓታት (1–12)},
 				'h23' => q{ናይ 24 ሰዓታት ስርዓት (0–23)},
 				'h24' => q{ናይ 24 ሰዓታት ስርዓት (1–24)},
 			},
 			'lb' => {
 				'loose' => q{ልሕሉሕ መስመር ምብታኽ ቅዲ},
 				'normal' => q{ንቡር ቅዲ ምብታኽ መስመር},
 				'strict' => q{ቅዲ ስጡም መስመር ምብታኽ},
 			},
 			'ms' => {
 				'metric' => q{ሜትሪክ ስርዓት},
 				'uksystem' => q{ስርዓተ መለክዒ ሃጸያዊ},
 				'ussystem' => q{ስርዓት መለክዒ ኣሜሪካ},
 			},
 			'numbers' => {
 				'arab' => q{ዓረብ-ህንዳዊ ኣሃዛት},
 				'arabext' => q{ዝተዘርግሐ ኣሃዛት ዓረብ-ህንዳዊ},
 				'armn' => q{ኣርመንያዊ ቁጽርታት},
 				'armnlow' => q{ኣርመንያ ንኣሽቱ ቁጽርታት},
 				'beng' => q{ባንግላ ኣሃዛት},
 				'cakm' => q{ቻክማ ኣሃዛት},
 				'deva' => q{ደቫናጋሪ ኣሃዛት},
 				'ethi' => q{ግእዝ ቁጽርታት},
 				'fullwide' => q{ምሉእ ስፍሓት ዘለዎም ኣሃዛት},
 				'geor' => q{ጆርጅያዊ ቁጽርታት},
 				'grek' => q{ናይ ግሪኽ ቁጽርታት},
 				'greklow' => q{ናይ ግሪኽ ንኣሽቱ ቁጽርታት},
 				'gujr' => q{ናይ ጉጃራቲ ኣሃዛት},
 				'guru' => q{ናይ ጉርሙኪ ኣሃዛት},
 				'hanidec' => q{ቻይናዊ ዓስራይ ቁጽርታት},
 				'hans' => q{ዝተቐለለ ቻይናዊ ቁጽርታት},
 				'hansfin' => q{ዝተቐለለ ቻይናዊ ፋይናንሳዊ ቁጽርታት},
 				'hant' => q{ባህላዊ ቁጽርታት ቻይና},
 				'hantfin' => q{ባህላዊ ቻይናዊ ፋይናንሳዊ ቁጽርታት},
 				'hebr' => q{ናይ እብራይስጢ ቁጽርታት},
 				'java' => q{ጃቫናዊ ኣሃዛት},
 				'jpan' => q{ጃፓናዊ ቁጽርታት},
 				'jpanfin' => q{ጃፓናዊ ፋይናንሳዊ ቁጽርታት},
 				'khmr' => q{ኣሃዛት ክመር},
 				'knda' => q{ካናዳ ኣሃዛት},
 				'laoo' => q{ላኦ ዲጂትስ},
 				'latn' => q{ምዕራባዊ ኣሃዛት},
 				'mlym' => q{ማላያላም ኣሃዛት},
 				'mtei' => q{ሜተይ ማየክ ኣሃዛት},
 				'mymr' => q{ናይ ሚያንማር ኣሃዛት},
 				'olck' => q{ኦል ቺኪ ኣሃዛት},
 				'orya' => q{ኦድያ አሃዛት},
 				'roman' => q{ሮማዊ ቁጽርታት},
 				'romanlow' => q{ሮማዊ ንኣሽቱ ቁጽርታት},
 				'taml' => q{ባህላዊ ቁጽርታት ታሚል},
 				'tamldec' => q{ናይ ታሚል አሃዛት},
 				'telu' => q{ናይ ተለጉ አሃዛት},
 				'thai' => q{ናይ ታይላንዳዊ ኣሃዛት},
 				'tibt' => q{ናይ ትቤቲ ኣሃዛት},
 				'vaii' => q{ቫይ ኣሃዛት},
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
			main => qr{[፟ ሀ ሁ ሂ ሃ ሄ ህ ሆ ለ ሉ ሊ ላ ሌ ል ሎ ሏ ሐ ሑ ሒ ሓ ሔ ሕ ሖ ሗ መ ሙ ሚ ማ ሜ ም ሞ ሟ ሠ ሡ ሢ ሣ ሤ ሥ ሦ ሧ ረ ሩ ሪ ራ ሬ ር ሮ ሯ ሰ ሱ ሲ ሳ ሴ ስ ሶ ሷ ሸ ሹ ሺ ሻ ሼ ሽ ሾ ሿ ቀ ቁ ቂ ቃ ቄ ቅ ቆ ቈ ቊ ቋ ቌ ቍ ቐ ቑ ቒ ቓ ቔ ቕ ቖ ቘ ቚ ቛ ቜ ቝ በ ቡ ቢ ባ ቤ ብ ቦ ቧ ቨ ቩ ቪ ቫ ቬ ቭ ቮ ቯ ተ ቱ ቲ ታ ቴ ት ቶ ቷ ቸ ቹ ቺ ቻ ቼ ች ቾ ቿ ኀ ኁ ኂ ኃ ኄ ኅ ኆ ኈ ኊ ኋ ኌ ኍ ነ ኑ ኒ ና ኔ ን ኖ ኗ ኘ ኙ ኚ ኛ ኜ ኝ ኞ ኟ አ ኡ ኢ ኣ ኤ እ ኦ ኧ ከ ኩ ኪ ካ ኬ ክ ኮ ኰ ኲ ኳ ኴ ኵ ኸ ኹ ኺ ኻ ኼ ኽ ኾ ዀ ዂ ዃ ዄ ዅ ወ ዉ ዊ ዋ ዌ ው ዎ ዐ ዑ ዒ ዓ ዔ ዕ ዖ ዘ ዙ ዚ ዛ ዜ ዝ ዞ ዟ ዠ ዡ ዢ ዣ ዤ ዥ ዦ ዧ የ ዩ ዪ ያ ዬ ይ ዮ ደ ዱ ዲ ዳ ዴ ድ ዶ ዷ ጀ ጁ ጂ ጃ ጄ ጅ ጆ ጇ ገ ጉ ጊ ጋ ጌ ግ ጎ ጐ ጒ ጓ ጔ ጕ ጠ ጡ ጢ ጣ ጤ ጥ ጦ ጧ ጨ ጩ ጪ ጫ ጬ ጭ ጮ ጯ ጰ ጱ ጲ ጳ ጴ ጵ ጶ ጷ ጸ ጹ ጺ ጻ ጼ ጽ ጾ ጿ ፀ ፁ ፂ ፃ ፄ ፅ ፆ ፇ ፈ ፉ ፊ ፋ ፌ ፍ ፎ ፏ ፐ ፑ ፒ ፓ ፔ ፕ ፖ ፗ]},
		};
	},
EOT
: sub {
		return { index => ['ሀ', 'ለ', 'ሐ', 'መ', 'ሠ', 'ረ', 'ሰ', 'ሸ', 'ቀ', 'ቈ', 'ቐ', 'ቘ', 'በ', 'ቨ', 'ተ', 'ቸ', 'ኀ', 'ኈ', 'ነ', 'ኘ', 'አ', 'ከ', 'ኰ', 'ኸ', 'ዀ', 'ወ', 'ዐ', 'ዘ', 'ዠ', 'የ', 'ደ', 'ጀ', 'ገ', 'ጐ', 'ጠ', 'ጨ', 'ጰ', 'ጸ', 'ፀ', 'ፈ', 'ፐ'], };
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
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ካርዲናል ኣንፈት),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ካርዲናል ኣንፈት),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(ኪቢ{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(ኪቢ{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(ሜቢ{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(ሜቢ{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(ጊቢ{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(ጊቢ{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(ቴቢ{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(ቴቢ{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(ፔቢ{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(ፔቢ{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ኤግዚቢ{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ኤግዚቢ{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(ዜቢ{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(ዜቢ{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(ዮቢ{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(ዮቢ{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ዴሲ{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ዴሲ{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(ፒኮ{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(ፒኮ{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ፌምቶ{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ፌምቶ{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(አቶ{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(አቶ{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(ሴንቲ{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(ሴንቲ{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(ዜፕቶ{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(ዜፕቶ{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ዮክቶ{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ዮክቶ{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ሮንቶ{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ሮንቶ{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ሚሊ{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ሚሊ{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(ክዌክቶ{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(ክዌክቶ{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(ማይክሮ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(ማይክሮ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(ናኖ{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(ናኖ{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ዴካ{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ዴካ{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ቴራ{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ቴራ{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(ፔታ{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(ፔታ{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ኤግዛ{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ኤግዛ{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ሄክቶ{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ሄክቶ{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(ዜታ{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(ዜታ{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ዮታ{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ዮታ{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ሮና{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ሮና{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(ኪሎ{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(ኪሎ{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(ክዌታ{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(ክዌታ{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(ሜጋ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(ሜጋ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(ጊጋ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(ጊጋ{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ሓይሊ ስሕበት),
						'one' => q({0} ሓይሊ ስሕበት),
						'other' => q({0} ሓይሊ ስሕበት),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ሓይሊ ስሕበት),
						'one' => q({0} ሓይሊ ስሕበት),
						'other' => q({0} ሓይሊ ስሕበት),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ሜትሮ ኣብ ሰከንድ ኣብ ካሬ),
						'one' => q({0} ሜትሮ ኣብ ሰከንድ ኣብ ካሬ),
						'other' => q({0} ሜትሮ ኣብ ሰከንድ ኣብ ካሬ),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ሜትሮ ኣብ ሰከንድ ኣብ ካሬ),
						'one' => q({0} ሜትሮ ኣብ ሰከንድ ኣብ ካሬ),
						'other' => q({0} ሜትሮ ኣብ ሰከንድ ኣብ ካሬ),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(ኣርክ ደቓይቕ),
						'one' => q({0} ኣርክ ደቒቓ),
						'other' => q({0} ኣርክ ደቓይቕ),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ኣርክ ደቓይቕ),
						'one' => q({0} ኣርክ ደቒቓ),
						'other' => q({0} ኣርክ ደቓይቕ),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ኣርክ ሰከንድ),
						'one' => q({0} ኣርክ ሰከንድ),
						'other' => q({0} ኣርክ ሰከንድ),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ኣርክ ሰከንድ),
						'one' => q({0} ኣርክ ሰከንድ),
						'other' => q({0} ኣርክ ሰከንድ),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ዲግሪ),
						'one' => q({0} ዲግሪ),
						'other' => q({0} ዲግሪ),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ዲግሪ),
						'one' => q({0} ዲግሪ),
						'other' => q({0} ዲግሪ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ራድያን),
						'one' => q({0} ራድያን),
						'other' => q({0} ራድያን),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ራድያን),
						'one' => q({0} ራድያን),
						'other' => q({0} ራድያን),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ሬቮልዩሽን),
						'one' => q({0} ሬቮልዩሽን),
						'other' => q({0} ሬቮልዩሽን),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ሬቮልዩሽን),
						'one' => q({0} ሬቮልዩሽን),
						'other' => q({0} ሬቮልዩሽን),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ዱናም),
						'one' => q({0} ዱናም),
						'other' => q({0} ዱናም),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ዱናም),
						'one' => q({0} ዱናም),
						'other' => q({0} ዱናም),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ሄክታር),
						'one' => q({0} ሄክታር),
						'other' => q({0} ሄክታር),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ሄክታር),
						'one' => q({0} ሄክታር),
						'other' => q({0} ሄክታር),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ካሬ ሴንቲሜትር),
						'one' => q({0} ካሬ ሴንቲሜትር),
						'other' => q({0} ካሬ ሴንቲሜትር),
						'per' => q({0} ብካሬ ሴንቲሜትር),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ካሬ ሴንቲሜትር),
						'one' => q({0} ካሬ ሴንቲሜትር),
						'other' => q({0} ካሬ ሴንቲሜትር),
						'per' => q({0} ብካሬ ሴንቲሜትር),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ካሬ ጫማ),
						'one' => q({0} ካሬ ጫማ),
						'other' => q({0} ካሬ ጫማ),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ካሬ ጫማ),
						'one' => q({0} ካሬ ጫማ),
						'other' => q({0} ካሬ ጫማ),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ካሬ ኢንች),
						'one' => q({0} ካሬ ኢንች),
						'other' => q({0} ካሬ ኢንች),
						'per' => q({0} ብካሬ ኢንች),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ካሬ ኢንች),
						'one' => q({0} ካሬ ኢንች),
						'other' => q({0} ካሬ ኢንች),
						'per' => q({0} ብካሬ ኢንች),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ኪሜ²),
						'one' => q({0} ኪሜ²),
						'other' => q({0} ኪሜ²),
						'per' => q({0}/ኪሜ²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ኪሜ²),
						'one' => q({0} ኪሜ²),
						'other' => q({0} ኪሜ²),
						'per' => q({0}/ኪሜ²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ሜተር²),
						'one' => q({0} ሜተር²),
						'other' => q({0} ሜትር²),
						'per' => q({0} ብሜተር²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ሜተር²),
						'one' => q({0} ሜተር²),
						'other' => q({0} ሜትር²),
						'per' => q({0} ብሜተር²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ካሬ ማይል),
						'one' => q({0} ካሬ ማይል),
						'other' => q({0} ካሬ ማይል),
						'per' => q({0} ብካሬ ማይል),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ካሬ ማይል),
						'one' => q({0} ካሬ ማይል),
						'other' => q({0} ካሬ ማይል),
						'per' => q({0} ብካሬ ማይል),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ካሬ ያርድ),
						'one' => q({0} ካሬ ያርድ),
						'other' => q({0} ካሬ ያርድ),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ካሬ ያርድ),
						'one' => q({0} ካሬ ያርድ),
						'other' => q({0} ካሬ ያርድ),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ኣቕሑ),
						'one' => q({0} ኣቕሓ),
						'other' => q({0} ኣቕሑ),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ኣቕሑ),
						'one' => q({0} ኣቕሓ),
						'other' => q({0} ኣቕሑ),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ሚሊግራም ኣብ ሓደ ዲሲሊተርትሮ),
						'one' => q({0} ሚሊግራም ኣብ ሓደ ዲሲሊተርትሮ),
						'other' => q({0} ሚሊግራም ኣብ ሓደ ዲሲሊተርትሮ),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ሚሊግራም ኣብ ሓደ ዲሲሊተርትሮ),
						'one' => q({0} ሚሊግራም ኣብ ሓደ ዲሲሊተርትሮ),
						'other' => q({0} ሚሊግራም ኣብ ሓደ ዲሲሊተርትሮ),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ሚሊሞል ኣብ ሊትሮ),
						'one' => q({0} ሚሊሞል ኣብ ሊትሮ),
						'other' => q({0} ሚሊሞል ኣብ ሊትሮ),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ሚሊሞል ኣብ ሊትሮ),
						'one' => q({0} ሚሊሞል ኣብ ሊትሮ),
						'other' => q({0} ሚሊሞል ኣብ ሊትሮ),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ሞል),
						'one' => q({0} ሞል),
						'other' => q({0} ሞል),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ሞል),
						'one' => q({0} ሞል),
						'other' => q({0} ሞል),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ሚእታዊ),
						'one' => q({0} ሚእታዊ),
						'other' => q({0} ሚእታዊ),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ሚእታዊ),
						'one' => q({0} ሚእታዊ),
						'other' => q({0} ሚእታዊ),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(አብ ሚሌ),
						'one' => q({0} አብ ሚሌ),
						'other' => q({0} አብ ሚሌ),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(አብ ሚሌ),
						'one' => q({0} አብ ሚሌ),
						'other' => q({0} አብ ሚሌ),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ክፍልታት ኣብ ሚልዮን),
						'one' => q({0} ክፍልታት ኣብ ሚልዮን),
						'other' => q({0} ክፍልታት ኣብ ሚልዮን),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ክፍልታት ኣብ ሚልዮን),
						'one' => q({0} ክፍልታት ኣብ ሚልዮን),
						'other' => q({0} ክፍልታት ኣብ ሚልዮን),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(አብ ሚርያድ),
						'one' => q({0} አብ ሚርያድ),
						'other' => q({0} አብ ሚርያድ),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(አብ ሚርያድ),
						'one' => q({0} አብ ሚርያድ),
						'other' => q({0} አብ ሚርያድ),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(ክፍልታት ኣብ ሓደ ቢልዮን),
						'one' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
						'other' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(ክፍልታት ኣብ ሓደ ቢልዮን),
						'one' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
						'other' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ሊትሮ አብ 100 ኪሎሜትር),
						'one' => q({0} ሊትሮ አብ 100 ኪሎሜትር),
						'other' => q({0} ሊትሮ አብ 100 ኪሎሜትር),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ሊትሮ አብ 100 ኪሎሜትር),
						'one' => q({0} ሊትሮ አብ 100 ኪሎሜትር),
						'other' => q({0} ሊትሮ አብ 100 ኪሎሜትር),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ሊትሮ ኣብ ኪሎሜትር),
						'one' => q({0} ሊትሮ አብ ኪሎሜትር),
						'other' => q({0} ሊትሮ አብ ኪሎሜትር),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ሊትሮ ኣብ ኪሎሜትር),
						'one' => q({0} ሊትሮ አብ ኪሎሜትር),
						'other' => q({0} ሊትሮ አብ ኪሎሜትር),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ማይል ኣብ ሓደ ጋሎን),
						'one' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
						'other' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ማይል ኣብ ሓደ ጋሎን),
						'one' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
						'other' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
						'one' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
						'other' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
						'one' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
						'other' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ምብራቕ),
						'north' => q({0} ሰሜን),
						'south' => q({0} ደቡብ),
						'west' => q({0} ምዕራብ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ምብራቕ),
						'north' => q({0} ሰሜን),
						'south' => q({0} ደቡብ),
						'west' => q({0} ምዕራብ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(ቢት),
						'one' => q({0} ቢት),
						'other' => q({0} ቢት),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(ቢት),
						'one' => q({0} ቢት),
						'other' => q({0} ቢት),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(ባይት),
						'one' => q({0} ባይት),
						'other' => q({0} ባይት),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(ባይት),
						'one' => q({0} ባይት),
						'other' => q({0} ባይት),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(ጊጋቢት),
						'one' => q({0} ጊጋቢት),
						'other' => q({0} ጊጋቢት),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(ጊጋቢት),
						'one' => q({0} ጊጋቢት),
						'other' => q({0} ጊጋቢት),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ጊጋባይት),
						'one' => q({0} ጊጋባይት),
						'other' => q({0} ጊጋባይት),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ጊጋባይት),
						'one' => q({0} ጊጋባይት),
						'other' => q({0} ጊጋባይት),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(ኪሎቢት),
						'one' => q({0} ኪሎቢት),
						'other' => q({0} ኪሎቢት),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(ኪሎቢት),
						'one' => q({0} ኪሎቢት),
						'other' => q({0} ኪሎቢት),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ኪሎባይት),
						'one' => q({0} ኪሎባይት),
						'other' => q({0} ኪሎባይት),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ኪሎባይት),
						'one' => q({0} ኪሎባይት),
						'other' => q({0} ኪሎባይት),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ሜጋቢት),
						'one' => q({0} ሜጋቢት),
						'other' => q({0} ሜጋቢት),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ሜጋቢት),
						'one' => q({0} ሜጋቢት),
						'other' => q({0} ሜጋቢት),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ሜጋባይት),
						'one' => q({0} ሜጋባይት),
						'other' => q({0} ሜጋባይት),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ሜጋባይት),
						'one' => q({0} ሜጋባይት),
						'other' => q({0} ሜጋባይት),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(ፔታባይት),
						'one' => q({0} ፔታባይት),
						'other' => q({0} ፔታባይት),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(ፔታባይት),
						'one' => q({0} ፔታባይት),
						'other' => q({0} ፔታባይት),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ቴራቢት),
						'one' => q({0} ቴራቢት),
						'other' => q({0} ቴራቢት),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ቴራቢት),
						'one' => q({0} ቴራቢት),
						'other' => q({0} ቴራቢት),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ቴራባይት),
						'one' => q({0} ቴራባይት),
						'other' => q({0} ቴራባይት),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ቴራባይት),
						'one' => q({0} ቴራባይት),
						'other' => q({0} ቴራባይት),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ዘመናት),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ዘመናት),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(መዓልታት),
						'one' => q({0} መዓልቲ),
						'other' => q({0} መዓልታት),
						'per' => q({0}/መዓልቲ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(መዓልታት),
						'one' => q({0} መዓልቲ),
						'other' => q({0} መዓልታት),
						'per' => q({0}/መዓልቲ),
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
					'duration-hour' => {
						'name' => q(ሰዓታት),
						'one' => q({0} ሰዓት),
						'other' => q({0} ሰዓታት),
						'per' => q({0}/ሰዓት),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ሰዓታት),
						'one' => q({0} ሰዓት),
						'other' => q({0} ሰዓታት),
						'per' => q({0}/ሰዓት),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(ማይክሮ ሰከንድ),
						'one' => q({0} ማይክሮ ሰከንድ),
						'other' => q({0} ማይክሮ ሰከንድ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(ማይክሮ ሰከንድ),
						'one' => q({0} ማይክሮ ሰከንድ),
						'other' => q({0} ማይክሮ ሰከንድ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ሚሊሴኮንድ),
						'one' => q({0} ሚሊሴኮንድ),
						'other' => q({0} ሚሊሴኮንድ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ሚሊሴኮንድ),
						'one' => q({0} ሚሊሴኮንድ),
						'other' => q({0} ሚሊሴኮንድ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ደቒቓታት),
						'one' => q({0} ደቒቓ),
						'other' => q({0} ደቒቓታት),
						'per' => q({0}/ደቒቓ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ደቒቓታት),
						'one' => q({0} ደቒቓ),
						'other' => q({0} ደቒቓታት),
						'per' => q({0}/ደቒቓ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ኣዋርሕ),
						'one' => q({0}/ወርሒ),
						'other' => q({0}/ኣዋርሕ),
						'per' => q({0}/ወርሒ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ኣዋርሕ),
						'one' => q({0}/ወርሒ),
						'other' => q({0}/ኣዋርሕ),
						'per' => q({0}/ወርሒ),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(ለይቲ),
						'one' => q({0} ለይቲ),
						'other' => q({0} ለይቲ),
						'per' => q({0}/ ለይቲ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(ለይቲ),
						'one' => q({0} ለይቲ),
						'other' => q({0} ለይቲ),
						'per' => q({0}/ ለይቲ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ርብዒ),
						'one' => q({0}/ርብዒ),
						'other' => q({0} ርብዒ),
						'per' => q({0}/ርብዒ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ርብዒ),
						'one' => q({0}/ርብዒ),
						'other' => q({0} ርብዒ),
						'per' => q({0}/ርብዒ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ሴኮንድ),
						'one' => q({0} ሴኮንድ),
						'other' => q({0} ሴኮንድ),
						'per' => q({0}/ሴኮንድ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ሴኮንድ),
						'one' => q({0} ሴኮንድ),
						'other' => q({0} ሴኮንድ),
						'per' => q({0}/ሴኮንድ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ሰሙናት),
						'one' => q({0} ሰሙን),
						'other' => q({0} ሰሙናት),
						'per' => q({0}/ሰሙን),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ሰሙናት),
						'one' => q({0} ሰሙን),
						'other' => q({0} ሰሙናት),
						'per' => q({0}/ሰሙን),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ዓመታት),
						'one' => q({0} ዓመት),
						'other' => q({0} ዓመታት),
						'per' => q({0}/ዓመታት),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ዓመታት),
						'one' => q({0} ዓመት),
						'other' => q({0} ዓመታት),
						'per' => q({0}/ዓመታት),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(አምፒር),
						'one' => q({0} አምፒር),
						'other' => q({0} አምፒር),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(አምፒር),
						'one' => q({0} አምፒር),
						'other' => q({0} አምፒር),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(ሚሊ አምፒር),
						'one' => q({0} ሚሊ አምፒር),
						'other' => q({0} ሚሊ አምፒር),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(ሚሊ አምፒር),
						'one' => q({0} ሚሊ አምፒር),
						'other' => q({0} ሚሊ አምፒር),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ኦህም),
						'one' => q({0} ኦህም),
						'other' => q({0} ኦህም),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ኦህም),
						'one' => q({0} ኦህም),
						'other' => q({0} ኦህም),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ቮልት),
						'one' => q({0} ቮልት),
						'other' => q({0} ቮልት),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ቮልት),
						'one' => q({0} ቮልት),
						'other' => q({0} ቮልት),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ናይ እንግሊዝ ናይ ሙቐት መለክዒ),
						'one' => q({0} ናይ እንግሊዝ ናይ ሙቐት መለክዒ),
						'other' => q({0} ናይ እንግሊዝ ናይ ሙቐት መለክዒ),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ናይ እንግሊዝ ናይ ሙቐት መለክዒ),
						'one' => q({0} ናይ እንግሊዝ ናይ ሙቐት መለክዒ),
						'other' => q({0} ናይ እንግሊዝ ናይ ሙቐት መለክዒ),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(ካሎሪ),
						'one' => q({0} ካሎሪ),
						'other' => q({0} ካሎሪ),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(ካሎሪ),
						'one' => q({0} ካሎሪ),
						'other' => q({0} ካሎሪ),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(ኤሌክትሮኖቮልት),
						'one' => q({0} ኤሌክትሮኖቮልት),
						'other' => q({0} ኤሌክትሮኖቮልት),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(ኤሌክትሮኖቮልት),
						'one' => q({0} ኤሌክትሮኖቮልት),
						'other' => q({0} ኤሌክትሮኖቮልት),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ጁል),
						'one' => q({0} ጁል),
						'other' => q({0} ጁል),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ጁል),
						'one' => q({0} ጁል),
						'other' => q({0} ጁል),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(ኪሎካሎሪ),
						'one' => q({0} ኪሎካሎሪ),
						'other' => q({0} ኪሎካሎሪ),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(ኪሎካሎሪ),
						'one' => q({0} ኪሎካሎሪ),
						'other' => q({0} ኪሎካሎሪ),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ኪሎጁል),
						'one' => q({0} ኪሎጁል),
						'other' => q({0} ኪሎጁል),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ኪሎጁል),
						'one' => q({0} ኪሎጁል),
						'other' => q({0} ኪሎጁል),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(ኪሎዋት-ሰዓት),
						'one' => q({0} ኪሎዋት ሰዓት),
						'other' => q({0} ኪሎዋት-ሰዓት),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(ኪሎዋት-ሰዓት),
						'one' => q({0} ኪሎዋት ሰዓት),
						'other' => q({0} ኪሎዋት-ሰዓት),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'one' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'other' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'one' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'other' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(ኪሎዋት-ሰዓት ኣብ 100 ኪሎሜትር),
						'one' => q({0} ኪሎዋት-ሰዓት ኣብ 100 ኪሎሜትር),
						'other' => q({0} ኪሎዋት-ሰዓት ኣብ 100 ኪሎሜትር),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(ኪሎዋት-ሰዓት ኣብ 100 ኪሎሜትር),
						'one' => q({0} ኪሎዋት-ሰዓት ኣብ 100 ኪሎሜትር),
						'other' => q({0} ኪሎዋት-ሰዓት ኣብ 100 ኪሎሜትር),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ኒውተን),
						'one' => q({0} ኒውተን),
						'other' => q({0}ኒውተን),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ኒውተን),
						'one' => q({0} ኒውተን),
						'other' => q({0}ኒውተን),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(ፓውንድ ሓይሊ),
						'one' => q({0} ፓውንድ ሓይሊ),
						'other' => q({0} ፓውንድ ሓይሊ),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(ፓውንድ ሓይሊ),
						'one' => q({0} ፓውንድ ሓይሊ),
						'other' => q({0} ፓውንድ ሓይሊ),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(ጊጋኸርትዝ),
						'one' => q({0} ጊጋኸርትዝ),
						'other' => q({0} ጊጋኸርትዝ),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(ጊጋኸርትዝ),
						'one' => q({0} ጊጋኸርትዝ),
						'other' => q({0} ጊጋኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ኸርትዝ),
						'one' => q({0} ኸርትዝ),
						'other' => q({0} ኸርትዝ),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ኸርትዝ),
						'one' => q({0} ኸርትዝ),
						'other' => q({0} ኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(ኪሎኸርትዝ),
						'one' => q({0} ኪሎኸርትዝ),
						'other' => q({0} ኪሎኸርትዝ),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(ኪሎኸርትዝ),
						'one' => q({0} ኪሎኸርትዝ),
						'other' => q({0} ኪሎኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(ሜጋኸርትዝ),
						'one' => q({0} ሜጋኸርትዝ),
						'other' => q({0} ሜጋኸርትዝ),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(ሜጋኸርትዝ),
						'one' => q({0} ሜጋኸርትዝ),
						'other' => q({0} ሜጋኸርትዝ),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ነጥብታት),
						'one' => q({0} ነጥብ),
						'other' => q({0} ነጥብታት),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ነጥብታት),
						'one' => q({0} ነጥብ),
						'other' => q({0} ነጥብታት),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ነጥብታት ኣብ ኢንች),
						'one' => q({0} ነጥብ ኣብ ኢንች),
						'other' => q({0} ነጥብታት ኣብ ኢንች),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ነጥብታት ኣብ ኢንች),
						'one' => q({0} ነጥብ ኣብ ኢንች),
						'other' => q({0} ነጥብታት ኣብ ኢንች),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ታይፕግራፊክ ኢኤምኤስ),
						'one' => q({0} ኢኤም),
						'other' => q({0} ኢኤምኤስ),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ታይፕግራፊክ ኢኤምኤስ),
						'one' => q({0} ኢኤም),
						'other' => q({0} ኢኤምኤስ),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ሜጋፒክሰላታ),
						'one' => q({0} ሜጋፒክሰል),
						'other' => q({0} ሜጋፒክሰላት),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ሜጋፒክሰላታ),
						'one' => q({0} ሜጋፒክሰል),
						'other' => q({0} ሜጋፒክሰላት),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ፒክሰላት),
						'one' => q({0} ፒክስል),
						'other' => q({0} ፒክሰላት),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ፒክሰላት),
						'one' => q({0} ፒክስል),
						'other' => q({0} ፒክሰላት),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ፒክሰል ኣብ ሴንቲ ሜተር),
						'one' => q({0} ፒክሰል ኣብ ሴንቲ ሜተር),
						'other' => q({0} ፒክሰል ኣብ ሴንቲ ሜተር),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ፒክሰል ኣብ ሴንቲ ሜተር),
						'one' => q({0} ፒክሰል ኣብ ሴንቲ ሜተር),
						'other' => q({0} ፒክሰል ኣብ ሴንቲ ሜተር),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ፒክሰል ኣብ ኢንች),
						'one' => q({0} ፒክሰል ኣብ ኢንች),
						'other' => q({0} ፒክሰል ኣብ ኢንች),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ፒክሰል ኣብ ኢንች),
						'one' => q({0} ፒክሰል ኣብ ኢንች),
						'other' => q({0} ፒክሰል ኣብ ኢንች),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ኣስትሮኖሚያዊ ኣሃዱታት),
						'one' => q({0} ኣስትሮኖሚያዊ ኣሃድ),
						'other' => q({0} ኣስትሮኖሚያዊ ኣሃዱታት),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ኣስትሮኖሚያዊ ኣሃዱታት),
						'one' => q({0} ኣስትሮኖሚያዊ ኣሃድ),
						'other' => q({0} ኣስትሮኖሚያዊ ኣሃዱታት),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(ሴንቲሜተር),
						'one' => q({0} ሴንቲሜተር),
						'other' => q({0} ሴንቲሜተር),
						'per' => q({0}/ሴንቲሜተር),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(ሴንቲሜተር),
						'one' => q({0} ሴንቲሜተር),
						'other' => q({0} ሴንቲሜተር),
						'per' => q({0}/ሴንቲሜተር),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ዴሲሜተር),
						'one' => q({0} ዴሲሜተር),
						'other' => q({0} ዴሲሜተር),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ዴሲሜተር),
						'one' => q({0} ዴሲሜተር),
						'other' => q({0} ዴሲሜተር),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ራድየስ መሬት),
						'one' => q({0} ራድየስ መሬት),
						'other' => q({0} ራድየስ መሬት),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ራድየስ መሬት),
						'one' => q({0} ራድየስ መሬት),
						'other' => q({0} ራድየስ መሬት),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ፊት),
						'one' => q({0} ፉት),
						'other' => q({0} ፊት),
						'per' => q({0}/ፊት),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ፊት),
						'one' => q({0} ፉት),
						'other' => q({0} ፊት),
						'per' => q({0}/ፊት),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(ኢንች),
						'one' => q({0} ኢንች),
						'other' => q({0} ኢንችስ),
						'per' => q({0}/ ኢንች),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(ኢንች),
						'one' => q({0} ኢንች),
						'other' => q({0} ኢንችስ),
						'per' => q({0}/ ኢንች),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ኪሎ ሜትር),
						'one' => q({0} ኪሎ ሜትር),
						'other' => q({0} ኪሎ ሜትር),
						'per' => q({0}/ኪሎ ሜትር),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ኪሎ ሜትር),
						'one' => q({0} ኪሎ ሜትር),
						'other' => q({0} ኪሎ ሜትር),
						'per' => q({0}/ኪሎ ሜትር),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ሜተር),
						'one' => q({0}/ሜትር),
						'other' => q({0}/ሜትር),
						'per' => q({0}/ ሜተር),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ሜተር),
						'one' => q({0}/ሜትር),
						'other' => q({0}/ሜትር),
						'per' => q({0}/ ሜተር),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(ማይክሮሜተር),
						'one' => q({0} ማይክሮሜተር),
						'other' => q({0} ማይክሮሜተር),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(ማይክሮሜተር),
						'one' => q({0} ማይክሮሜተር),
						'other' => q({0} ማይክሮሜተር),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ማይላት),
						'one' => q({0} ማይል),
						'other' => q({0} ማይላት),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ማይላት),
						'one' => q({0} ማይል),
						'other' => q({0} ማይላት),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ሚሊሜተር),
						'one' => q({0} ሚሊሜተር),
						'other' => q({0} ሚሊሜተር),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ሚሊሜተር),
						'one' => q({0} ሚሊሜተር),
						'other' => q({0} ሚሊሜተር),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(ናኖሜተር),
						'one' => q({0} ናኖሜተር),
						'other' => q({0} ናኖሜተር),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(ናኖሜተር),
						'one' => q({0} ናኖሜተር),
						'other' => q({0} ናኖሜተር),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(ናይ ባሕሪ ማይላት),
						'one' => q({0} ናይ ባሕሪ ማይል),
						'other' => q({0} ናይ ባሕሪ ማይላት),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(ናይ ባሕሪ ማይላት),
						'one' => q({0} ናይ ባሕሪ ማይል),
						'other' => q({0} ናይ ባሕሪ ማይላት),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(ፒኮሜተር),
						'one' => q({0} ፒኮሜተር),
						'other' => q({0} ፒኮሜተር),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(ፒኮሜተር),
						'one' => q({0} ፒኮሜተር),
						'other' => q({0} ፒኮሜተር),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ናይ ጸሓይ ራዲየስ),
						'one' => q({0} ናይ ጸሓይ ራዲየስ),
						'other' => q({0} ናይ ጸሓይ ራዲየስ),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ናይ ጸሓይ ራዲየስ),
						'one' => q({0} ናይ ጸሓይ ራዲየስ),
						'other' => q({0} ናይ ጸሓይ ራዲየስ),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ያርድስ),
						'one' => q({0} ያርድ),
						'other' => q({0} ያርድስ),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ያርድስ),
						'one' => q({0} ያርድ),
						'other' => q({0} ያርድስ),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ካንዴላ),
						'one' => q({0} ካንዴላ),
						'other' => q({0} ካንዴላ),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ካንዴላ),
						'one' => q({0} ካንዴላ),
						'other' => q({0} ካንዴላ),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(ሉመን),
						'one' => q({0} ሉመን),
						'other' => q({0} ሉመን),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(ሉመን),
						'one' => q({0} ሉመን),
						'other' => q({0} ሉመን),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(ለክስ),
						'one' => q({0} ለክስ),
						'other' => q({0} ለክስ),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(ለክስ),
						'one' => q({0} ለክስ),
						'other' => q({0} ለክስ),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(ጸሓያዊ ብርሃናት),
						'one' => q({0} ጸሓያዊ ብርሃን),
						'other' => q({0} ጸሓያዊ ብርሃናት),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(ጸሓያዊ ብርሃናት),
						'one' => q({0} ጸሓያዊ ብርሃን),
						'other' => q({0} ጸሓያዊ ብርሃናት),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(ዳልቶን),
						'one' => q({0} ዳልቶን),
						'other' => q({0} ዳልቶን),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(ዳልቶን),
						'one' => q({0} ዳልቶን),
						'other' => q({0} ዳልቶን),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ናይ መሬት ክብደት),
						'one' => q({0} ናይ መሬት ክብደት),
						'other' => q({0} ናይ መሬት ክብደት),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ናይ መሬት ክብደት),
						'one' => q({0} ናይ መሬት ክብደት),
						'other' => q({0} ናይ መሬት ክብደት),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(ግሬን),
						'one' => q({0} ግሬን),
						'other' => q({0} ግሬን),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(ግሬን),
						'one' => q({0} ግሬን),
						'other' => q({0} ግሬን),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ግራም),
						'one' => q({0} ግራም),
						'other' => q({0} ግራም),
						'per' => q({0} አብ ግራም),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ግራም),
						'one' => q({0} ግራም),
						'other' => q({0} ግራም),
						'per' => q({0} አብ ግራም),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(ኪሎግራም),
						'one' => q({0} ኪሎግራም),
						'other' => q({0} ኪሎግራም),
						'per' => q({0} አብ ኪሎግራም),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(ኪሎግራም),
						'one' => q({0} ኪሎግራም),
						'other' => q({0} ኪሎግራም),
						'per' => q({0} አብ ኪሎግራም),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(ማይክሮ ግራም),
						'one' => q({0} ማይክሮ ግራም),
						'other' => q({0} ማይክሮ ግራም),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(ማይክሮ ግራም),
						'one' => q({0} ማይክሮ ግራም),
						'other' => q({0} ማይክሮ ግራም),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ሚሊ ግራም),
						'one' => q({0} ሚሊ ግራም),
						'other' => q({0} ሚሊ ግራም),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ሚሊ ግራም),
						'one' => q({0} ሚሊ ግራም),
						'other' => q({0} ሚሊ ግራም),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ኣውንስ),
						'one' => q({0} ኣውንስ),
						'other' => q({0} oኣውንስ),
						'per' => q({0} አብ ኣውንስ),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ኣውንስ),
						'one' => q({0} ኣውንስ),
						'other' => q({0} oኣውንስ),
						'per' => q({0} አብ ኣውንስ),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ትሮይ ኣውንስ),
						'one' => q({0} ትሮይ ኣውንስ),
						'other' => q({0} ትሮይ ኣውንስ),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ትሮይ ኣውንስ),
						'one' => q({0} ትሮይ ኣውንስ),
						'other' => q({0} ትሮይ ኣውንስ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ፓውንድ),
						'one' => q({0} ፓውንድ),
						'other' => q({0} ፓውንድ),
						'per' => q({0} አብ ፓውንድ),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ፓውንድ),
						'one' => q({0} ፓውንድ),
						'other' => q({0} ፓውንድ),
						'per' => q({0} አብ ፓውንድ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(ናይ ጸሓይ ክብደት),
						'one' => q({0} ናይ ጸሓይ ክብደት),
						'other' => q({0} ናይ ጸሓይ ክብደት),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(ናይ ጸሓይ ክብደት),
						'one' => q({0} ናይ ጸሓይ ክብደት),
						'other' => q({0} ናይ ጸሓይ ክብደት),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ሜትሪክ ቶን),
						'one' => q({0} ሜትሪክ ቶን),
						'other' => q({0} ሜትሪክ ቶን),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ሜትሪክ ቶን),
						'one' => q({0} ሜትሪክ ቶን),
						'other' => q({0} ሜትሪክ ቶን),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} አብ {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} አብ {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(ጊጋዋት),
						'one' => q({0} ጊጋዋት),
						'other' => q({0} ጊጋዋት),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(ጊጋዋት),
						'one' => q({0} ጊጋዋት),
						'other' => q({0} ጊጋዋት),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ሓይሊ ፈረስ),
						'one' => q({0} ሓይሊ ፈረስ),
						'other' => q({0} ሓይሊ ፈረስ),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ሓይሊ ፈረስ),
						'one' => q({0} ሓይሊ ፈረስ),
						'other' => q({0} ሓይሊ ፈረስ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(ኪሎዋት),
						'one' => q({0} ኪሎዋት),
						'other' => q({0} ኪሎዋት),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(ኪሎዋት),
						'one' => q({0} ኪሎዋት),
						'other' => q({0} ኪሎዋት),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(ሜጋዋት),
						'one' => q({0} ሜጋዋት),
						'other' => q({0} ሜጋዋት),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(ሜጋዋት),
						'one' => q({0} ሜጋዋት),
						'other' => q({0} ሜጋዋት),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ሚሊዋት),
						'one' => q({0} ሚሊዋት),
						'other' => q({0} ሚሊዋት),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ሚሊዋት),
						'one' => q({0} ሚሊዋት),
						'other' => q({0} ሚሊዋት),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ዋት),
						'one' => q({0} ዋት),
						'other' => q({0} ዋት),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ዋት),
						'one' => q({0} ዋት),
						'other' => q({0} ዋት),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(ካሬ {0}),
						'other' => q(ካሬ {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(ካሬ {0}),
						'other' => q(ካሬ {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(ኪዩቢክ {0}),
						'other' => q(ኪዩቢክ {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(ኪዩቢክ {0}),
						'other' => q(ኪዩቢክ {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(አትሞስፌር),
						'one' => q({0} አትሞስፌር),
						'other' => q({0} አትሞስፌር),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(አትሞስፌር),
						'one' => q({0} አትሞስፌር),
						'other' => q({0} አትሞስፌር),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ባር),
						'one' => q({0} ባር),
						'other' => q({0} ባር),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ባር),
						'one' => q({0} ባር),
						'other' => q({0} ባር),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ሄክቶ ፓስካል),
						'one' => q({0} ሄክቶ ፓስካል),
						'other' => q({0} ሄክቶ ፓስካል),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ሄክቶ ፓስካል),
						'one' => q({0} ሄክቶ ፓስካል),
						'other' => q({0} ሄክቶ ፓስካል),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(ኢንች ሜርኩሪ),
						'one' => q({0} ኢንች ሜርኩሪ),
						'other' => q({0} ኢንች ሜርኩሪ),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(ኢንች ሜርኩሪ),
						'one' => q({0} ኢንች ሜርኩሪ),
						'other' => q({0} ኢንች ሜርኩሪ),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(ኪሎፓስካል),
						'one' => q({0} ኪሎፓስካል),
						'other' => q({0} ኪሎፓስካል),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(ኪሎፓስካል),
						'one' => q({0} ኪሎፓስካል),
						'other' => q({0} ኪሎፓስካል),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(ሜጋፓስካል),
						'one' => q({0} ሜጋፓስካል),
						'other' => q({0} ሜጋፓስካል),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(ሜጋፓስካል),
						'one' => q({0} ሜጋፓስካል),
						'other' => q({0} ሜጋፓስካል),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ሚሊባር),
						'one' => q({0} ሚሊባር),
						'other' => q({0} ሚሊባር),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ሚሊባር),
						'one' => q({0} ሚሊባር),
						'other' => q({0} ሚሊባር),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(ሚሊሜተር ሜርኩሪ),
						'one' => q({0} ሚሊሜተር ሜርኩሪ),
						'other' => q({0} ሚሊሜተር ሜርኩሪ),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(ሚሊሜተር ሜርኩሪ),
						'one' => q({0} ሚሊሜተር ሜርኩሪ),
						'other' => q({0} ሚሊሜተር ሜርኩሪ),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(ፓስካል),
						'one' => q({0} ፓስካል),
						'other' => q({0} ፓስካል),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(ፓስካል),
						'one' => q({0} ፓስካል),
						'other' => q({0} ፓስካል),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(ፓውንድ-ሓይሊ ኣብ ሓደ ካሬ ኢንች),
						'one' => q({0} ፓውንድ-ሓይሊ ኣብ ሓደ ካሬ ኢንች),
						'other' => q({0} ፓውንድ-ሓይሊ ኣብ ሓደ ካሬ ኢንች),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(ፓውንድ-ሓይሊ ኣብ ሓደ ካሬ ኢንች),
						'one' => q({0} ፓውንድ-ሓይሊ ኣብ ሓደ ካሬ ኢንች),
						'other' => q({0} ፓውንድ-ሓይሊ ኣብ ሓደ ካሬ ኢንች),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(ኪሎሜተር ኣብ ሰዓት),
						'one' => q({0} ኪሎሜተር ኣብ ሰዓት),
						'other' => q({0} ኪሎሜተር ኣብ ሰዓት),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(ኪሎሜተር ኣብ ሰዓት),
						'one' => q({0} ኪሎሜተር ኣብ ሰዓት),
						'other' => q({0} ኪሎሜተር ኣብ ሰዓት),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(እስር),
						'one' => q({0} እስር),
						'other' => q({0} እስር),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(እስር),
						'one' => q({0} እስር),
						'other' => q({0} እስር),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ብርሃን),
						'one' => q({0} ብርሃን),
						'other' => q({0} ብርሃን),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ብርሃን),
						'one' => q({0} ብርሃን),
						'other' => q({0} ብርሃን),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ሜትሮ ኣብ ሰከንድ),
						'one' => q({0} ሜትሮ ኣብ ሰከንድ),
						'other' => q({0} ሜትሮ ኣብ ሰከንድ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ሜትሮ ኣብ ሰከንድ),
						'one' => q({0} ሜትሮ ኣብ ሰከንድ),
						'other' => q({0} ሜትሮ ኣብ ሰከንድ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ማይል ኣብ ሰዓት),
						'one' => q({0} ማይል ኣብ ሰዓት),
						'other' => q({0} ማይል ኣብ ሰዓት),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ማይል ኣብ ሰዓት),
						'one' => q({0} ማይል ኣብ ሰዓት),
						'other' => q({0} ማይል ኣብ ሰዓት),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ዲግሪ ሴንቲግሬድ),
						'one' => q({0} ዲግሪ ሴንቲግሬድ),
						'other' => q({0} ዲግሪ ሴንቲግሬድ),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ዲግሪ ሴንቲግሬድ),
						'one' => q({0} ዲግሪ ሴንቲግሬድ),
						'other' => q({0} ዲግሪ ሴንቲግሬድ),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ዲግሪ ፋረንሃይት),
						'one' => q({0} ዲግሪ ፋረንሃይት),
						'other' => q({0} ዲግሪ ፋረንሃይት),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ዲግሪ ፋረንሃይት),
						'one' => q({0} ዲግሪ ፋረንሃይት),
						'other' => q({0} ዲግሪ ፋረንሃይት),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(ዲግሪ ሙቐት),
						'one' => q({0} ዲግሪ ሙቐት),
						'other' => q({0} ዲግሪ ሙቐት),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(ዲግሪ ሙቐት),
						'one' => q({0} ዲግሪ ሙቐት),
						'other' => q({0} ዲግሪ ሙቐት),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(ኬልቪን),
						'one' => q({0} ኬልቪን),
						'other' => q({0} ኬልቪን),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(ኬልቪን),
						'one' => q({0} ኬልቪን),
						'other' => q({0} ኬልቪን),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(ኒውተን ሜትር),
						'one' => q({0} ኒውተን ሜትር),
						'other' => q({0} ኒውተን ሜትር),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(ኒውተን ሜትር),
						'one' => q({0} ኒውተን ሜትር),
						'other' => q({0} ኒውተን ሜትር),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(ፓውንድ ሓይሊ ጫማ),
						'one' => q({0} ፓውንድ ሓይሊ ጫማ),
						'other' => q({0} ፓውንድ ሓይሊ ጫማ),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(ፓውንድ ሓይሊ ጫማ),
						'one' => q({0} ፓውንድ ሓይሊ ጫማ),
						'other' => q({0} ፓውንድ ሓይሊ ጫማ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-ጫማ),
						'one' => q({0} acre ጫማ),
						'other' => q({0} acre ጫማ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-ጫማ),
						'one' => q({0} acre ጫማ),
						'other' => q({0} acre ጫማ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(በርሚል),
						'one' => q({0} በርሚል),
						'other' => q({0} በርሚል),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(በርሚል),
						'one' => q({0} በርሚል),
						'other' => q({0} በርሚል),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(ዳውላ),
						'one' => q({0} ዳውላ),
						'other' => q({0} ዳውላ),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(ዳውላ),
						'one' => q({0} ዳውላ),
						'other' => q({0} ዳውላ),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ሴንቲ ሊትሮ),
						'one' => q({0} ሴንቲ ሊትሮ),
						'other' => q({0} ሴንቲ ሊትሮ),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ሴንቲ ሊትሮ),
						'one' => q({0} ሴንቲ ሊትሮ),
						'other' => q({0} ሴንቲ ሊትሮ),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(ሴንቲሜትር ክዩብ),
						'one' => q({0} ሴንቲሜትር ክዩብ),
						'other' => q({0} ሴንቲሜትር ክዩብ),
						'per' => q({0} ብሴንቲሜትር ክዩብ),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(ሴንቲሜትር ክዩብ),
						'one' => q({0} ሴንቲሜትር ክዩብ),
						'other' => q({0} ሴንቲሜትር ክዩብ),
						'per' => q({0} ብሴንቲሜትር ክዩብ),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ክዩብ ጫማ),
						'one' => q({0} ክዩብ ጫማ),
						'other' => q({0} ክዩብ ጫማ),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ክዩብ ጫማ),
						'one' => q({0} ክዩብ ጫማ),
						'other' => q({0} ክዩብ ጫማ),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ኢንች ክዩብ),
						'one' => q({0} ኢንች ክዩብ),
						'other' => q({0} ኢንች ክዩብ),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ኢንች ክዩብ),
						'one' => q({0} ኢንች ክዩብ),
						'other' => q({0} ኢንች ክዩብ),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(ኪሎ ሜትር ኪዩብ),
						'one' => q({0} ኪሎ ሜትር ኪዩብ),
						'other' => q({0} ኪሎ ሜትር ኪዩብ),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(ኪሎ ሜትር ኪዩብ),
						'one' => q({0} ኪሎ ሜትር ኪዩብ),
						'other' => q({0} ኪሎ ሜትር ኪዩብ),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(ሜትር ኪዩብ),
						'one' => q({0} ሜትር ኪዩብ),
						'other' => q({0} ሜትር ኪዩብ),
						'per' => q({0}/ ብሜትር ኪዩብ),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(ሜትር ኪዩብ),
						'one' => q({0} ሜትር ኪዩብ),
						'other' => q({0} ሜትር ኪዩብ),
						'per' => q({0}/ ብሜትር ኪዩብ),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(ማይል ክዩብ),
						'one' => q({0} ማይል ክዩብ),
						'other' => q({0} ማይል ክዩብ),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ማይል ክዩብ),
						'one' => q({0} ማይል ክዩብ),
						'other' => q({0} ማይል ክዩብ),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ክዩብ ያርድ),
						'one' => q({0} ክዩብ ያርድ),
						'other' => q({0} ክዩብ ያርድ),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ክዩብ ያርድ),
						'one' => q({0} ክዩብ ያርድ),
						'other' => q({0} ክዩብ ያርድ),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ኩባያ),
						'one' => q({0} ኩባያ),
						'other' => q({0} ኩባያ),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ኩባያ),
						'one' => q({0} ኩባያ),
						'other' => q({0} ኩባያ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ዴሲ ሊትሮ),
						'one' => q({0} ዴሲ ሊትሮ),
						'other' => q({0} ዴሲ ሊትሮ),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ዴሲ ሊትሮ),
						'one' => q({0} ዴሲ ሊትሮ),
						'other' => q({0} ዴሲ ሊትሮ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ናይ ኬክ ማንካ),
						'one' => q({0} ናይ ኬክ ማንካ),
						'other' => q({0} ናይ ኬክ ማንካ),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ናይ ኬክ ማንካ),
						'one' => q({0} ናይ ኬክ ማንካ),
						'other' => q({0} ናይ ኬክ ማንካ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(ኢምፕ. ናይ ኬክ ማንካ),
						'one' => q({0} ኢምፕ ናይ ኬክ ማንካ),
						'other' => q({0} ኢምፕ. ናይ ኬክ ማንካ),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ኢምፕ. ናይ ኬክ ማንካ),
						'one' => q({0} ኢምፕ ናይ ኬክ ማንካ),
						'other' => q({0} ኢምፕ. ናይ ኬክ ማንካ),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ድራም),
						'one' => q({0} ድራም),
						'other' => q({0} ድራም),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ድራም),
						'one' => q({0} ድራም),
						'other' => q({0} ድራም),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ጠብታ),
						'one' => q({0} ጠብታ),
						'other' => q({0} ጠብታ),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ጠብታ),
						'one' => q({0} ጠብታ),
						'other' => q({0} ጠብታ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ፈሳሲ ኦውንስ),
						'one' => q({0} ፈሳሲ ኦውንስ),
						'other' => q({0} ፈሳሲ ኦውንስ),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ፈሳሲ ኦውንስ),
						'one' => q({0} ፈሳሲ ኦውንስ),
						'other' => q({0} ፈሳሲ ኦውንስ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ኢምፕ. ፈሳሲ ኦውንስ),
						'one' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
						'other' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ኢምፕ. ፈሳሲ ኦውንስ),
						'one' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
						'other' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(ጋሎን),
						'one' => q({0} ጋሎን),
						'other' => q({0} ጋሎን),
						'per' => q({0} ብጋሎን),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(ጋሎን),
						'one' => q({0} ጋሎን),
						'other' => q({0} ጋሎን),
						'per' => q({0} ብጋሎን),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ኢምፕ. ጋሎን),
						'one' => q({0} ኢምፕ. ጋሎን),
						'other' => q({0} ኢምፕ. ጋሎን),
						'per' => q({0} ብኢምፕ. ጋሎን),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ኢምፕ. ጋሎን),
						'one' => q({0} ኢምፕ. ጋሎን),
						'other' => q({0} ኢምፕ. ጋሎን),
						'per' => q({0} ብኢምፕ. ጋሎን),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ሄክቶ ሊትሮ),
						'one' => q({0} ሄክቶ ሊትሮ),
						'other' => q({0} ሄክቶ ሊትሮ),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ሄክቶ ሊትሮ),
						'one' => q({0} ሄክቶ ሊትሮ),
						'other' => q({0} ሄክቶ ሊትሮ),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(ጂገር),
						'one' => q({0} ጂገር),
						'other' => q({0} ጂገር),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(ጂገር),
						'one' => q({0} ጂገር),
						'other' => q({0} ጂገር),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ሊትሮ),
						'one' => q({0} ሊትሮ),
						'other' => q({0} ሊትሮ),
						'per' => q({0} ብሊትሮ),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ሊትሮ),
						'one' => q({0} ሊትሮ),
						'other' => q({0} ሊትሮ),
						'per' => q({0} ብሊትሮ),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ሜጋ ሊትሮ),
						'one' => q({0} ሜጋ ሊትሮ),
						'other' => q({0} ሜጋ ሊትሮ),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ሜጋ ሊትሮ),
						'one' => q({0} ሜጋ ሊትሮ),
						'other' => q({0} ሜጋ ሊትሮ),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ሚሊ ሊትሮ),
						'one' => q({0} ሚሊ ሊትሮ),
						'other' => q({0} ሚሊ ሊትሮ),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ሚሊ ሊትሮ),
						'one' => q({0} ሚሊ ሊትሮ),
						'other' => q({0} ሚሊ ሊትሮ),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ቁንጣር),
						'one' => q({0} ቁንጣር),
						'other' => q({0} ቁንጣር),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ቁንጣር),
						'one' => q({0} ቁንጣር),
						'other' => q({0} ቁንጣር),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(ፒንት),
						'one' => q({0} ፒንት),
						'other' => q({0} ፒንት),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(ፒንት),
						'one' => q({0} ፒንት),
						'other' => q({0} ፒንት),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ሜትሪክ ፓይንት),
						'one' => q({0} ሜትሪክ ፓይንት),
						'other' => q({0} ሜትሪክ ፓይንት),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ሜትሪክ ፓይንት),
						'one' => q({0} ሜትሪክ ፓይንት),
						'other' => q({0} ሜትሪክ ፓይንት),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ርብዒ ጋሎን),
						'one' => q({0} ርብዒ ጋሎን),
						'other' => q({0} ርብዒ ጋሎን),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ርብዒ ጋሎን),
						'one' => q({0} ርብዒ ጋሎን),
						'other' => q({0} ርብዒ ጋሎን),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ኢምፒ. ርብዒ ጋሎን),
						'one' => q({0} ኢምፒ. ርብዒ ጋሎን),
						'other' => q({0} ኢምፒ. ርብዒ ጋሎን),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ኢምፒ. ርብዒ ጋሎን),
						'one' => q({0} ኢምፒ. ርብዒ ጋሎን),
						'other' => q({0} ኢምፒ. ርብዒ ጋሎን),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ማንካ),
						'one' => q({0} ማንካ),
						'other' => q({0} ማንካ),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ማንካ),
						'one' => q({0} ማንካ),
						'other' => q({0} ማንካ),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ናይ ሻሂ ማንካ),
						'one' => q({0} ናይ ሻሂ ማንካ),
						'other' => q({0} ናይ ሻሂ ማንካ),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ናይ ሻሂ ማንካ),
						'one' => q({0} ናይ ሻሂ ማንካ),
						'other' => q({0} ናይ ሻሂ ማንካ),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ኣንፈት),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ኣንፈት),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(ኪቢ{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(ኪቢ{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(ሜቢ{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(ሜቢ{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(ጊቢ{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(ጊቢ{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(ቴቢ{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(ቴቢ{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(ፔቢ{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(ፔቢ{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ኤግዚቢ{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ኤግዚቢ{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(ዜቢ{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(ዜቢ{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(ዮቢ{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(ዮቢ{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ዴሲ{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ዴሲ{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(ፒኮ{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(ፒኮ{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ፌምቶ{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ፌምቶ{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(አቶ{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(አቶ{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(ሴንቲ{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(ሴንቲ{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(ዜፕቶ{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(ዜፕቶ{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ዮክቶ{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ዮክቶ{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ሮንቶ{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ሮንቶ{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ሚሊ{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ሚሊ{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(ክዌክቶ{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(ክዌክቶ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(ናኖ{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(ናኖ{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ዴካ{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ዴካ{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ቴራ{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ቴራ{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(ፔታ{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(ፔታ{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ኤግዛ{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ኤግዛ{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ሄክቶ{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ሄክቶ{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(ዜታ{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(ዜታ{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ዮታ{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ዮታ{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ሮና{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ሮና{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(ኪ{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(ኪ{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(ክዌታ{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(ክዌታ{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(ሜጋ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(ሜጋ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(ጊጋ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(ጊጋ{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ሓይሊ ስሕበት),
						'one' => q({0}ስሕበት),
						'other' => q({0}ስሕበት),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ሓይሊ ስሕበት),
						'one' => q({0}ስሕበት),
						'other' => q({0}ስሕበት),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ሜ/ሰ²),
						'one' => q({0}ሜ/ሰ²),
						'other' => q({0}ሜ/ሰ²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ሜ/ሰ²),
						'one' => q({0}ሜ/ሰ²),
						'other' => q({0}ሜ/ሰ²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(ኣርክ ደቒቓ),
						'one' => q({0} ኣርክ ደቒቓ),
						'other' => q({0} ኣርክ ደቓይቕ),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ኣርክ ደቒቓ),
						'one' => q({0} ኣርክ ደቒቓ),
						'other' => q({0} ኣርክ ደቓይቕ),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ኣርክ ሰከንድ),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ኣርክ ሰከንድ),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ዲግሪ),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ዲግሪ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ራድያን),
						'one' => q({0}ራድያን),
						'other' => q({0}ራድያን),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ራድያን),
						'one' => q({0}ራድያን),
						'other' => q({0}ራድያን),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ሬቮልዩሽን),
						'one' => q({0}ሬቮልዩሽን),
						'other' => q({0}ሬቮልዩሽን),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ሬቮልዩሽን),
						'one' => q({0}ሬቮልዩሽን),
						'other' => q({0}ሬቮልዩሽን),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ዱናም),
						'one' => q({0}ዱናም),
						'other' => q({0}ዱናም),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ዱናም),
						'one' => q({0}ዱናም),
						'other' => q({0}ዱናም),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ሄክታር),
						'one' => q({0}ሄክ),
						'other' => q({0}ሄክ),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ሄክታር),
						'one' => q({0}ሄክ),
						'other' => q({0}ሄክ),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ሴሜ²),
						'one' => q({0}ሴሜ²),
						'other' => q({0}ሴሜ²),
						'per' => q({0}/ሴሜ²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ሴሜ²),
						'one' => q({0}ሴሜ²),
						'other' => q({0}ሴሜ²),
						'per' => q({0}/ሴሜ²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ጫማ²),
						'one' => q({0}ጫማ²),
						'other' => q({0}ጫማ²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ጫማ²),
						'one' => q({0}ጫማ²),
						'other' => q({0}ጫማ²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ኢንች²),
						'one' => q({0}ኢንች²),
						'other' => q({0}ኢንች²),
						'per' => q({0}/ኢንች²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ኢንች²),
						'one' => q({0}ኢንች²),
						'other' => q({0}ኢንች²),
						'per' => q({0}/ኢንች²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ኪሜ²),
						'one' => q({0}ኪሜ²),
						'other' => q({0}ኪሜ²),
						'per' => q({0}/ኪሜ²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ኪሜ²),
						'one' => q({0}ኪሜ²),
						'other' => q({0}ኪሜ²),
						'per' => q({0}/ኪሜ²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ሜተር²),
						'one' => q({0}ሜ²),
						'other' => q({0}ሜ²),
						'per' => q({0}/ሜ²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ሜተር²),
						'one' => q({0}ሜ²),
						'other' => q({0}ሜ²),
						'per' => q({0}/ሜ²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ማ²),
						'one' => q({0}ማ²),
						'other' => q({0}ማ²),
						'per' => q({0}/ማ²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ማ²),
						'one' => q({0}ማ²),
						'other' => q({0}ማ²),
						'per' => q({0}/ማ²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ያ²),
						'one' => q({0}ያ²),
						'other' => q({0}ያ²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ያ²),
						'one' => q({0}ያ²),
						'other' => q({0}ያ²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ኣቕሓ),
						'one' => q({0}ኣቕሓ),
						'other' => q({0}ኣቕሑ),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ኣቕሓ),
						'one' => q({0}ኣቕሓ),
						'other' => q({0}ኣቕሑ),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ካራት),
						'one' => q({0}ካራት),
						'other' => q({0}ካራት),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ካራት),
						'one' => q({0}ካራት),
						'other' => q({0}ካራት),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ሚግ/ዲሲሊተርትሮ),
						'one' => q({0}ሚግ/ዲሲሊተርትሮ),
						'other' => q({0}ሚግ/ዲሲሊተርትሮ),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ሚግ/ዲሲሊተርትሮ),
						'one' => q({0}ሚግ/ዲሲሊተርትሮ),
						'other' => q({0}ሚግ/ዲሲሊተርትሮ),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ሚሊሞል/ሊትሮ),
						'one' => q({0}ሚሊሞል/ሊትሮ),
						'other' => q({0}ሚሊሞል/ሊትሮ),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ሚሊሞል/ሊትሮ),
						'one' => q({0}ሚሊሞል/ሊትሮ),
						'other' => q({0}ሚሊሞል/ሊትሮ),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ሞል),
						'one' => q({0}ሞል),
						'other' => q({0}ሞል),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ሞል),
						'one' => q({0}ሞል),
						'other' => q({0}ሞል),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ክፍልታት ኣብ ሚልዮን),
						'one' => q({0}ክፍልታት ኣብ ሚልዮን),
						'other' => q({0}ክፍልታት ኣብ ሚልዮን),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ክፍልታት ኣብ ሚልዮን),
						'one' => q({0}ክፍልታት ኣብ ሚልዮን),
						'other' => q({0}ክፍልታት ኣብ ሚልዮን),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(ክፍልታት ኣብ ሓደ ቢልዮን),
						'one' => q({0}ክፍልታት ኣብ ሓደ ቢልዮን),
						'other' => q({0}ክፍልታት ኣብ ሓደ ቢልዮን),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(ክፍልታት ኣብ ሓደ ቢልዮን),
						'one' => q({0}ክፍልታት ኣብ ሓደ ቢልዮን),
						'other' => q({0}ክፍልታት ኣብ ሓደ ቢልዮን),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ሊትሮ/100 ኪሜ),
						'one' => q({0}ሊትሮ/100 ኪሜ),
						'other' => q({0}ሊትሮ/100 ኪሜ),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ሊትሮ/100 ኪሜ),
						'one' => q({0}ሊትሮ/100 ኪሜ),
						'other' => q({0}ሊትሮ/100 ኪሜ),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ሊትሮ/ኪሜ),
						'one' => q({0}ሊትሮ/ኪሜ),
						'other' => q({0}ሊትሮ/ኪሜ),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ሊትሮ/ኪሜ),
						'one' => q({0}ሊትሮ/ኪሜ),
						'other' => q({0}ሊትሮ/ኪሜ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ማይልስ ኣብ ሓደ ጋሎን),
						'one' => q({0}ማይልስ ኣብ ሓደ ጋሎን),
						'other' => q({0}ማይልስ ኣብ ሓደ ጋሎን),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ማይልስ ኣብ ሓደ ጋሎን),
						'one' => q({0}ማይልስ ኣብ ሓደ ጋሎን),
						'other' => q({0}ማይልስ ኣብ ሓደ ጋሎን),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ናይ እንግሊዝ ማይል ኣብ ሓደ ጋሎን),
						'one' => q({0}ናይ እንግሊዝ ማይል/ሓደ ጋሎን),
						'other' => q({0}ናይ እንግሊዝ ማይል/ሓደ ጋሎን),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ናይ እንግሊዝ ማይል ኣብ ሓደ ጋሎን),
						'one' => q({0}ናይ እንግሊዝ ማይል/ሓደ ጋሎን),
						'other' => q({0}ናይ እንግሊዝ ማይል/ሓደ ጋሎን),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}ምብራቕ),
						'north' => q({0}ሰሜን),
						'south' => q({0}ደቡብ),
						'west' => q({0}ምዕራብ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}ምብራቕ),
						'north' => q({0}ሰሜን),
						'south' => q({0}ደቡብ),
						'west' => q({0}ምዕራብ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(ቢት),
						'one' => q({0}ቢት),
						'other' => q({0}ቢት),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(ቢት),
						'one' => q({0}ቢት),
						'other' => q({0}ቢት),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(ባይት),
						'one' => q({0}ባይት),
						'other' => q({0}ባይት),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(ባይት),
						'one' => q({0}ባይት),
						'other' => q({0}ባይት),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(ጊጋቢት),
						'one' => q({0}ጊጋቢት),
						'other' => q({0}ጊጋቢት),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(ጊጋቢት),
						'one' => q({0}ጊጋቢት),
						'other' => q({0}ጊጋቢት),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ጊጋባይት),
						'one' => q({0}ጊጋባይት),
						'other' => q({0}ጊጋባይት),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ጊጋባይት),
						'one' => q({0}ጊጋባይት),
						'other' => q({0}ጊጋባይት),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(ኪሎቢት),
						'one' => q({0}ኪሎቢት),
						'other' => q({0}ኪሎቢት),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(ኪሎቢት),
						'one' => q({0}ኪሎቢት),
						'other' => q({0}ኪሎቢት),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ኪሎባይት),
						'one' => q({0}ኪሎባይት),
						'other' => q({0}ኪሎባይት),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ኪሎባይት),
						'one' => q({0}ኪሎባይት),
						'other' => q({0}ኪሎባይት),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ሜጋቢት),
						'one' => q({0}ሜጋቢት),
						'other' => q({0}ሜጋቢት),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ሜጋቢት),
						'one' => q({0}ሜጋቢት),
						'other' => q({0}ሜጋቢት),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ሜጋባይት),
						'one' => q({0}ሜጋባይት),
						'other' => q({0}ሜጋባይት),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ሜጋባይት),
						'one' => q({0}ሜጋባይት),
						'other' => q({0}ሜጋባይት),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(ፔታባይት),
						'one' => q({0}ፔታባይት),
						'other' => q({0}ፔታባይት),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(ፔታባይት),
						'one' => q({0}ፔታባይት),
						'other' => q({0}ፔታባይት),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ቴራቢት),
						'one' => q({0}ቴራቢት),
						'other' => q({0}ቴራቢት),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ቴራቢት),
						'one' => q({0}ቴራቢት),
						'other' => q({0}ቴራቢት),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ቴራባይት),
						'one' => q({0}ቴራባይት),
						'other' => q({0}ቴራባይት),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ቴራባይት),
						'one' => q({0}ቴራባይት),
						'other' => q({0}ቴራባይት),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(መዓልታት),
						'one' => q({0} መ),
						'other' => q({0} መ),
						'per' => q({0}/መ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(መዓልታት),
						'one' => q({0} መ),
						'other' => q({0} መ),
						'per' => q({0}/መ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0} ዓ.ዓ.),
						'other' => q({0} ዓ.ዓ.),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0} ዓ.ዓ.),
						'other' => q({0} ዓ.ዓ.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ሰዓት),
						'one' => q({0} ሰ),
						'other' => q({0} ሰ),
						'per' => q({0}/ሰ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ሰዓት),
						'one' => q({0} ሰ),
						'other' => q({0} ሰ),
						'per' => q({0}/ሰ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μሰከንድ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μሰከንድ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ሚሴኮንድ),
						'one' => q({0} ሚሴ),
						'other' => q({0} ሚሴ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ሚሴኮንድ),
						'one' => q({0} ሚሴ),
						'other' => q({0} ሚሴ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ደቒቓ),
						'one' => q({0} ደ),
						'other' => q({0} ደ),
						'per' => q({0}/ደቒቓ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ደቒቓ),
						'one' => q({0} ደ),
						'other' => q({0} ደ),
						'per' => q({0}/ደቒቓ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ወርሒ),
						'one' => q({0}/ወ),
						'other' => q({0}/ወ),
						'per' => q({0}/ወርሒ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ወርሒ),
						'one' => q({0}/ወ),
						'other' => q({0}/ወ),
						'per' => q({0}/ወርሒ),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(ለይቲ),
						'one' => q({0} ለይቲ),
						'other' => q({0} ለይቲ),
						'per' => q({0}/ ለይቲ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(ለይቲ),
						'one' => q({0} ለይቲ),
						'other' => q({0} ለይቲ),
						'per' => q({0}/ ለይቲ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ርብዒ),
						'one' => q({0} ርብዒ),
						'other' => q({0} ርብዒ),
						'per' => q({0}/ርብዒ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ርብዒ),
						'one' => q({0} ርብዒ),
						'other' => q({0} ርብዒ),
						'per' => q({0}/ርብዒ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ሴኮንድ),
						'one' => q({0} ሴ),
						'other' => q({0} ሴ),
						'per' => q({0}/ሴ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ሴኮንድ),
						'one' => q({0} ሴ),
						'other' => q({0} ሴ),
						'per' => q({0}/ሴ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ሰሙ),
						'one' => q({0} ሰ),
						'other' => q({0} ሰ),
						'per' => q({0}/ሰሙን),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ሰሙ),
						'one' => q({0} ሰ),
						'other' => q({0} ሰ),
						'per' => q({0}/ሰሙን),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ዓመታት),
						'one' => q({0} ዓመት),
						'other' => q({0}ዓመት),
						'per' => q({0}/ዓመት),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ዓመታት),
						'one' => q({0} ዓመት),
						'other' => q({0}ዓመት),
						'per' => q({0}/ዓመት),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(አምፒር),
						'one' => q({0}አምፒር),
						'other' => q({0}አምፒር),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(አምፒር),
						'one' => q({0}አምፒር),
						'other' => q({0}አምፒር),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(ሚሊ አምፒር),
						'one' => q({0}ሚሊ አምፒር),
						'other' => q({0}ሚሊ አምፒር),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(ሚሊ አምፒር),
						'one' => q({0}ሚሊ አምፒር),
						'other' => q({0}ሚሊ አምፒር),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ኦህም),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ኦህም),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ቮልት),
						'one' => q({0}ቮልት),
						'other' => q({0}ቮልት),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ቮልት),
						'one' => q({0}ቮልት),
						'other' => q({0}ቮልት),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(ካሎሪ),
						'one' => q({0}ካሎሪ),
						'other' => q({0}ካሎሪ),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(ካሎሪ),
						'one' => q({0}ካሎሪ),
						'other' => q({0}ካሎሪ),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(ኢቪ),
						'one' => q({0}ኤሌክትሮኖቮልት),
						'other' => q({0}ኤሌክትሮኖቮልት),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(ኢቪ),
						'one' => q({0}ኤሌክትሮኖቮልት),
						'other' => q({0}ኤሌክትሮኖቮልት),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ጁል),
						'one' => q({0}ጁል),
						'other' => q({0}ጁል),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ጁል),
						'one' => q({0}ጁል),
						'other' => q({0}ጁል),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(ኪካሎሪ),
						'one' => q({0}ኪካሎሪ),
						'other' => q({0}ኪካሎሪ),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(ኪካሎሪ),
						'one' => q({0}ኪካሎሪ),
						'other' => q({0}ኪካሎሪ),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ኪጁ),
						'one' => q({0}ኪጁ),
						'other' => q({0}ኪጁ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ኪጁ),
						'one' => q({0}ኪጁ),
						'other' => q({0}ኪጁ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(ኪሎዋት ሰዓት),
						'one' => q({0}ኪሎዋት ሰዓት),
						'other' => q({0}ኪሎዋት ሰዓት),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(ኪሎዋት ሰዓት),
						'one' => q({0}ኪሎዋት ሰዓት),
						'other' => q({0}ኪሎዋት ሰዓት),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'one' => q({0}ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'other' => q({0}ናይ አመሪካ ናይ ሙቐት መለክዒ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'one' => q({0}ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'other' => q({0}ናይ አመሪካ ናይ ሙቐት መለክዒ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'one' => q({0}ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'other' => q({0}ኪሎዋት-ሰዓት/100 ኪሎሜትር),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'one' => q({0}ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'other' => q({0}ኪሎዋት-ሰዓት/100 ኪሎሜትር),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ኒውተን),
						'one' => q({0}ኒውተን),
						'other' => q({0}ኒውተን),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ኒውተን),
						'one' => q({0}ኒውተን),
						'other' => q({0}ኒውተን),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(ፓውንድ ሓይሊ),
						'one' => q({0}ፓውንድ ሓይሊ),
						'other' => q({0}ፓውንድ ሓይሊ),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(ፓውንድ ሓይሊ),
						'one' => q({0}ፓውንድ ሓይሊ),
						'other' => q({0}ፓውንድ ሓይሊ),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(ጊጋኸርትዝ),
						'one' => q({0}ጊጋኸርትዝ),
						'other' => q({0}ጊጋኸርትዝ),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(ጊጋኸርትዝ),
						'one' => q({0}ጊጋኸርትዝ),
						'other' => q({0}ጊጋኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ኸርትዝ),
						'one' => q({0}ኸርትዝ),
						'other' => q({0}ኸርትዝ),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ኸርትዝ),
						'one' => q({0}ኸርትዝ),
						'other' => q({0}ኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(ኪሎኸርትዝ),
						'one' => q({0}ኪሎኸርትዝ),
						'other' => q({0}ኪሎኸርትዝ),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(ኪሎኸርትዝ),
						'one' => q({0}ኪሎኸርትዝ),
						'other' => q({0}ኪሎኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(ሜጋኸርትዝ),
						'one' => q({0}ሜጋኸርትዝ),
						'other' => q({0}ሜጋኸርትዝ),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(ሜጋኸርትዝ),
						'one' => q({0}ሜጋኸርትዝ),
						'other' => q({0}ሜጋኸርትዝ),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ነጥብ),
						'one' => q({0} ነጥብ),
						'other' => q({0} ነጥብ),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ነጥብ),
						'one' => q({0} ነጥብ),
						'other' => q({0} ነጥብ),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ኢኤም),
						'one' => q({0} ኢኤም),
						'other' => q({0} ኢኤም),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ኢኤም),
						'one' => q({0} ኢኤም),
						'other' => q({0} ኢኤም),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ሜፕ),
						'one' => q({0} ሜጋ),
						'other' => q({0} ሜጋ),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ሜፕ),
						'one' => q({0} ሜጋ),
						'other' => q({0} ሜጋ),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ፒክ),
						'one' => q({0} ፒክ),
						'other' => q({0} ፒክ),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ፒክ),
						'one' => q({0} ፒክ),
						'other' => q({0} ፒክ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(ሴሜ),
						'one' => q({0}ሴሜ),
						'other' => q({0}ሴሜ),
						'per' => q({0}/ሴሜ),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(ሴሜ),
						'one' => q({0}ሴሜ),
						'other' => q({0}ሴሜ),
						'per' => q({0}/ሴሜ),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ዴሜ),
						'one' => q({0}ዴሜ),
						'other' => q({0}ዴሜ),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ዴሜ),
						'one' => q({0}ዴሜ),
						'other' => q({0}ዴሜ),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ራድየስ መሬት),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ራድየስ መሬት),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ፊት),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/ፊት),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ፊት),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/ፊት),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(ኢን),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/ኢን),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(ኢን),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/ኢን),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ኪሜ),
						'one' => q({0} ኪሜ),
						'other' => q({0} ኪሜ),
						'per' => q({0}/ኪሜ),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ኪሜ),
						'one' => q({0} ኪሜ),
						'other' => q({0} ኪሜ),
						'per' => q({0}/ኪሜ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ሜ),
						'one' => q({0}ሜ),
						'other' => q({0}ሜ),
						'per' => q({0}/ሜ),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ሜ),
						'one' => q({0}ሜ),
						'other' => q({0}ሜ),
						'per' => q({0}/ሜ),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(ማሜ),
						'one' => q({0}ማሜ),
						'other' => q({0}ማሜ),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(ማሜ),
						'one' => q({0}ማሜ),
						'other' => q({0}ማሜ),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ማ),
						'one' => q({0}ማ),
						'other' => q({0}ማ),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ማ),
						'one' => q({0}ማ),
						'other' => q({0}ማ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ሚሜ),
						'one' => q({0}ሚሜ),
						'other' => q({0}ሚሜ),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ሚሜ),
						'one' => q({0}ሚሜ),
						'other' => q({0}ሚሜ),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(ናሜ),
						'one' => q({0} ናሜ),
						'other' => q({0} ናሜ),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(ናሜ),
						'one' => q({0} ናሜ),
						'other' => q({0} ናሜ),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(ፒሜ),
						'one' => q({0}ፒሜ),
						'other' => q({0}ፒሜ),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(ፒሜ),
						'one' => q({0}ፒሜ),
						'other' => q({0}ፒሜ),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ያ),
						'one' => q({0}ያ),
						'other' => q({0}ያ),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ያ),
						'one' => q({0}ያ),
						'other' => q({0}ያ),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ካንዴላ),
						'one' => q({0}ካንዴላ),
						'other' => q({0}ካንዴላ),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ካንዴላ),
						'one' => q({0}ካንዴላ),
						'other' => q({0}ካንዴላ),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(ሉመን),
						'one' => q({0}ሉመን),
						'other' => q({0}ሉመን),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(ሉመን),
						'one' => q({0}ሉመን),
						'other' => q({0}ሉመን),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(ለክስ),
						'one' => q({0}ለክስ),
						'other' => q({0}ለክስ),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(ለክስ),
						'one' => q({0}ለክስ),
						'other' => q({0}ለክስ),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ካራት),
						'one' => q({0}ካራት),
						'other' => q({0}ካራት),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ካራት),
						'one' => q({0}ካራት),
						'other' => q({0}ካራት),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(ዳልቶን),
						'one' => q({0}ዳልቶን),
						'other' => q({0}ዳልቶን),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(ዳልቶን),
						'one' => q({0}ዳልቶን),
						'other' => q({0}ዳልቶን),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ናይ መሬት ክብደት),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ናይ መሬት ክብደት),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(ግሬን),
						'one' => q({0}ግሬን),
						'other' => q({0}ግሬን),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(ግሬን),
						'one' => q({0}ግሬን),
						'other' => q({0}ግሬን),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ግራም),
						'one' => q({0}ግ),
						'other' => q({0}ግ),
						'per' => q({0}/ግራም),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ግራም),
						'one' => q({0}ግ),
						'other' => q({0}ግ),
						'per' => q({0}/ግራም),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(ኪግ),
						'one' => q({0}ኪግ),
						'other' => q({0}ኪግ),
						'per' => q({0}/ኪግ),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(ኪግ),
						'one' => q({0}ኪግ),
						'other' => q({0}ኪግ),
						'per' => q({0}/ኪግ),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μግ),
						'one' => q({0}μግ),
						'other' => q({0}μግ),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μግ),
						'one' => q({0}μግ),
						'other' => q({0}μግ),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ሚግ),
						'one' => q({0}ሚግ),
						'other' => q({0}ሚግ),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ሚግ),
						'one' => q({0}ሚግ),
						'other' => q({0}ሚግ),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ኣውንስ),
						'one' => q({0}ኣውንስ),
						'other' => q({0}ኣውንስ),
						'per' => q({0}/ኣውንስ),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ኣውንስ),
						'one' => q({0}ኣውንስ),
						'other' => q({0}ኣውንስ),
						'per' => q({0}/ኣውንስ),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ትሮይ ኣውንስ),
						'one' => q({0}ትሮይ ኣውንስ),
						'other' => q({0}ትሮይ ኣውንስ),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ትሮይ ኣውንስ),
						'one' => q({0}ትሮይ ኣውንስ),
						'other' => q({0}ትሮይ ኣውንስ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ፓውንድ),
						'one' => q({0} ፓውንድ),
						'other' => q({0} ፓውንድ),
						'per' => q({0}/ፓውንድ),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ፓውንድ),
						'one' => q({0} ፓውንድ),
						'other' => q({0} ፓውንድ),
						'per' => q({0}/ፓውንድ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(ናይ ጸሓይ ክብደት),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(ናይ ጸሓይ ክብደት),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ቶን),
						'one' => q({0}ቶን),
						'other' => q({0}ቶን),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ቶን),
						'one' => q({0}ቶን),
						'other' => q({0}ቶን),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(ጊጋዋት),
						'one' => q({0}ጊጋዋት),
						'other' => q({0}ጊጋዋት),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(ጊጋዋት),
						'one' => q({0}ጊጋዋት),
						'other' => q({0}ጊጋዋት),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ሓይሊ ፈረስ),
						'one' => q({0}ሓይሊ ፈረስ),
						'other' => q({0}ሓይሊ ፈረስ),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ሓይሊ ፈረስ),
						'one' => q({0}ሓይሊ ፈረስ),
						'other' => q({0}ሓይሊ ፈረስ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(ኪሎዋት),
						'one' => q({0}ኪሎዋት),
						'other' => q({0}ኪሎዋት),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(ኪሎዋት),
						'one' => q({0}ኪሎዋት),
						'other' => q({0}ኪሎዋት),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(ሜጋዋት),
						'one' => q({0}ሜጋዋት),
						'other' => q({0}ሜጋዋት),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(ሜጋዋት),
						'one' => q({0}ሜጋዋት),
						'other' => q({0}ሜጋዋት),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ሚሊዋት),
						'one' => q({0}ሚሊዋት),
						'other' => q({0}ሚሊዋት),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ሚሊዋት),
						'one' => q({0}ሚሊዋት),
						'other' => q({0}ሚሊዋት),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ዋት),
						'one' => q({0}ዋት),
						'other' => q({0}ዋት),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ዋት),
						'one' => q({0}ዋት),
						'other' => q({0}ዋት),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(አትሞስፌር),
						'one' => q({0}አትሞስፌር),
						'other' => q({0}አትሞስፌር),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(አትሞስፌር),
						'one' => q({0}አትሞስፌር),
						'other' => q({0}አትሞስፌር),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ባር),
						'one' => q({0}ባር),
						'other' => q({0}ባር),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ባር),
						'one' => q({0}ባር),
						'other' => q({0}ባር),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ሄክቶ ፓስካል),
						'one' => q({0}ሄክቶ ፓስካል),
						'other' => q({0}ሄክቶ ፓስካል),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ሄክቶ ፓስካል),
						'one' => q({0}ሄክቶ ፓስካል),
						'other' => q({0}ሄክቶ ፓስካል),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ ሜርኩሪ),
						'one' => q({0}″ ሜርኩሪ),
						'other' => q({0}″ ሜርኩሪ),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ ሜርኩሪ),
						'one' => q({0}″ ሜርኩሪ),
						'other' => q({0}″ ሜርኩሪ),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(ኪሎፓስካል),
						'one' => q({0}ኪሎፓስካል),
						'other' => q({0}ኪሎፓስካል),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(ኪሎፓስካል),
						'one' => q({0}ኪሎፓስካል),
						'other' => q({0}ኪሎፓስካል),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(ሜጋፓስካል),
						'one' => q({0}ሜጋፓስካል),
						'other' => q({0}ሜጋፓስካል),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(ሜጋፓስካል),
						'one' => q({0}ሜጋፓስካል),
						'other' => q({0}ሜጋፓስካል),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ሚሊባር),
						'one' => q({0}ሚሊባር),
						'other' => q({0}ሚሊባር),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ሚሊባር),
						'one' => q({0}ሚሊባር),
						'other' => q({0}ሚሊባር),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(ሚሜ ሜርኩሪ),
						'one' => q({0}ሚሜ ሜርኩሪ),
						'other' => q({0}ሚሜ ሜርኩሪ),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(ሚሜ ሜርኩሪ),
						'one' => q({0}ሚሜ ሜርኩሪ),
						'other' => q({0}ሚሜ ሜርኩሪ),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(ፓስካል),
						'one' => q({0}ፓስካል),
						'other' => q({0}ፓስካል),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(ፓስካል),
						'one' => q({0}ፓስካል),
						'other' => q({0}ፓስካል),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(ኪሜ/ሰዓት),
						'one' => q({0}ኪሜ/ሰዓት),
						'other' => q({0}ኪሜ/ሰዓት),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(ኪሜ/ሰዓት),
						'one' => q({0}ኪሜ/ሰዓት),
						'other' => q({0}ኪሜ/ሰዓት),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(እስር),
						'one' => q({0}እስር),
						'other' => q({0}እስር),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(እስር),
						'one' => q({0}እስር),
						'other' => q({0}እስር),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ብርሃን),
						'one' => q({0}ብርሃን),
						'other' => q({0}ብርሃን),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ብርሃን),
						'one' => q({0}ብርሃን),
						'other' => q({0}ብርሃን),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ሜ/ሰ),
						'one' => q({0}ሜ/ሰ),
						'other' => q({0}ሜ/ሰ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ሜ/ሰ),
						'one' => q({0}ሜ/ሰ),
						'other' => q({0}ሜ/ሰ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ማይል/ሰዓት),
						'one' => q({0}ማይል ኣብ ሰዓት),
						'other' => q({0}ማይል ኣብ ሰዓት),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ማይል/ሰዓት),
						'one' => q({0}ማይል ኣብ ሰዓት),
						'other' => q({0}ማይል ኣብ ሰዓት),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ዲግሪ ሴንቲግሬድ),
						'one' => q({0}°ሴ),
						'other' => q({0}°ሴ),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ዲግሪ ሴንቲግሬድ),
						'one' => q({0}°ሴ),
						'other' => q({0}°ሴ),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ዲግሪ ፋረንሃይት),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ዲግሪ ፋረንሃይት),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(ዲግሪ ሙቐት),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(ዲግሪ ሙቐት),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(ኬ),
						'one' => q({0}ኬ),
						'other' => q({0}ኬ),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(ኬ),
						'one' => q({0}ኬ),
						'other' => q({0}ኬ),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(ኒውተን ሜትር),
						'one' => q({0}ኒውተን ሜትር),
						'other' => q({0}ኒውተን ሜትር),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(ኒውተን ሜትር),
						'one' => q({0}ኒውተን ሜትር),
						'other' => q({0}ኒውተን ሜትር),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(ፓውንድ ሓይሊ ጫማ),
						'one' => q({0}ፓውንድ ሓይሊ ጫማ),
						'other' => q({0}ፓውንድ ሓይሊ ጫማ),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(ፓውንድ ሓይሊ ጫማ),
						'one' => q({0}ፓውንድ ሓይሊ ጫማ),
						'other' => q({0}ፓውንድ ሓይሊ ጫማ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre ጫማ),
						'one' => q({0}ac ጫማ),
						'other' => q({0}ac ጫማ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre ጫማ),
						'one' => q({0}ac ጫማ),
						'other' => q({0}ac ጫማ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(በርሚል),
						'one' => q({0}በርሚል),
						'other' => q({0}በርሚል),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(በርሚል),
						'one' => q({0}በርሚል),
						'other' => q({0}በርሚል),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(ዳውላ),
						'one' => q({0}ዳውላ),
						'other' => q({0}ዳውላ),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(ዳውላ),
						'one' => q({0}ዳውላ),
						'other' => q({0}ዳውላ),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ሴሊ),
						'one' => q({0}ሴሊ),
						'other' => q({0}ሴሊ),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ሴሊ),
						'one' => q({0}ሴሊ),
						'other' => q({0}ሴሊ),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(ሴሜ³),
						'one' => q({0}ሴሜ³),
						'other' => q({0}ሴሜ³),
						'per' => q({0}/ሴሜ³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(ሴሜ³),
						'one' => q({0}ሴሜ³),
						'other' => q({0}ሴሜ³),
						'per' => q({0}/ሴሜ³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ጫማ³),
						'one' => q({0}ጫማ³),
						'other' => q({0}ጫማ³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ጫማ³),
						'one' => q({0}ጫማ³),
						'other' => q({0}ጫማ³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ኢንች³),
						'one' => q({0}ኢንች³),
						'other' => q({0}ኢንች³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ኢንች³),
						'one' => q({0}ኢንች³),
						'other' => q({0}ኢንች³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(ኪሜ³),
						'one' => q({0}ኪሜ³),
						'other' => q({0}ኪሜ³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(ኪሜ³),
						'one' => q({0}ኪሜ³),
						'other' => q({0}ኪሜ³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(ሜ³),
						'one' => q({0}ሜ³),
						'other' => q({0}ሜ³),
						'per' => q({0}/ሜ³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(ሜ³),
						'one' => q({0}ሜ³),
						'other' => q({0}ሜ³),
						'per' => q({0}/ሜ³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(ማ³),
						'one' => q({0}ማ³),
						'other' => q({0}ማ³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ማ³),
						'one' => q({0}ማ³),
						'other' => q({0}ማ³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ያ³),
						'one' => q({0}ያ³),
						'other' => q({0}ያ³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ያ³),
						'one' => q({0}ያ³),
						'other' => q({0}ያ³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ኩባያ),
						'one' => q({0}ኩባያ),
						'other' => q({0}ኩባያ),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ኩባያ),
						'one' => q({0}ኩባያ),
						'other' => q({0}ኩባያ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ዴሊ),
						'one' => q({0}ዴሊ),
						'other' => q({0}ዴሊ),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ዴሊ),
						'one' => q({0}ዴሊ),
						'other' => q({0}ዴሊ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ናይ ኬክ ማንካ),
						'one' => q({0}ናይ ኬክ ማንካ),
						'other' => q({0}ናይ ኬክ ማንካ),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ናይ ኬክ ማንካ),
						'one' => q({0}ናይ ኬክ ማንካ),
						'other' => q({0}ናይ ኬክ ማንካ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(ኢምፕ ናይ ኬክ ማንካ),
						'one' => q({0}ኢምፕ ናይ ኬክ ማንካ),
						'other' => q({0}ኢምፕ ናይ ኬክ ማንካ),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ኢምፕ ናይ ኬክ ማንካ),
						'one' => q({0}ኢምፕ ናይ ኬክ ማንካ),
						'other' => q({0}ኢምፕ ናይ ኬክ ማንካ),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ድራም),
						'one' => q({0}ድራም),
						'other' => q({0}ድራም),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ድራም),
						'one' => q({0}ድራም),
						'other' => q({0}ድራም),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ጠብታ),
						'one' => q({0}ጠብታ),
						'other' => q({0}ጠብታ),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ጠብታ),
						'one' => q({0}ጠብታ),
						'other' => q({0}ጠብታ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ፈሳሲ ኦውንስ),
						'one' => q({0}ፈሳሲ ኦውንስ),
						'other' => q({0}ፈሳሲ ኦውንስ),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ፈሳሲ ኦውንስ),
						'one' => q({0}ፈሳሲ ኦውንስ),
						'other' => q({0}ፈሳሲ ኦውንስ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ኢምፕ ፈሳሲ ኦውንስ),
						'one' => q({0}ኢምፕ ፈሳሲ ኦውንስ),
						'other' => q({0}ኢምፕ ፈሳሲ ኦውንስ),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ኢምፕ ፈሳሲ ኦውንስ),
						'one' => q({0}ኢምፕ ፈሳሲ ኦውንስ),
						'other' => q({0}ኢምፕ ፈሳሲ ኦውንስ),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(ጋሎን),
						'one' => q({0}ጋሎን),
						'other' => q({0}ጋሎን),
						'per' => q({0}/ጋሎን),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(ጋሎን),
						'one' => q({0}ጋሎን),
						'other' => q({0}ጋሎን),
						'per' => q({0}/ጋሎን),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ኢምፕ. ጋሎን),
						'one' => q({0}ኢምፕጋሎን),
						'other' => q({0}ኢምፕጋሎን),
						'per' => q({0}/ኢምፕጋሎን),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ኢምፕ. ጋሎን),
						'one' => q({0}ኢምፕጋሎን),
						'other' => q({0}ኢምፕጋሎን),
						'per' => q({0}/ኢምፕጋሎን),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ሄሊ),
						'one' => q({0}ሄሊ),
						'other' => q({0}ሄሊ),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ሄሊ),
						'one' => q({0}ሄሊ),
						'other' => q({0}ሄሊ),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(ጂገር),
						'one' => q({0}ጂገር),
						'other' => q({0}ጂገር),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(ጂገር),
						'one' => q({0}ጂገር),
						'other' => q({0}ጂገር),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ሊትሮ),
						'one' => q({0}ሊ),
						'other' => q({0}ሊ),
						'per' => q({0}/ሊ),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ሊትሮ),
						'one' => q({0}ሊ),
						'other' => q({0}ሊ),
						'per' => q({0}/ሊ),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ሜሊ),
						'one' => q({0}ሜሊ),
						'other' => q({0}ሜሊ),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ሜሊ),
						'one' => q({0}ሜሊ),
						'other' => q({0}ሜሊ),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ሚሊ),
						'one' => q({0}ሚሊ),
						'other' => q({0}ሚሊ),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ሚሊ),
						'one' => q({0}ሚሊ),
						'other' => q({0}ሚሊ),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ቁንጣር),
						'one' => q({0}ቁንጣር),
						'other' => q({0}ቁንጣር),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ቁንጣር),
						'one' => q({0}ቁንጣር),
						'other' => q({0}ቁንጣር),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(ፒንት),
						'one' => q({0}ፒንት),
						'other' => q({0}ፒንት),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(ፒንት),
						'one' => q({0}ፒንት),
						'other' => q({0}ፒንት),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ሜፓ),
						'one' => q({0}ሜፓ),
						'other' => q({0}ሜፓ),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ሜፓ),
						'one' => q({0}ሜፓ),
						'other' => q({0}ሜፓ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ርብዒ ጋሎን),
						'one' => q({0}ርብዒ ጋሎን),
						'other' => q({0}ርብዒ ጋሎን),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ርብዒ ጋሎን),
						'one' => q({0}ርብዒ ጋሎን),
						'other' => q({0}ርብዒ ጋሎን),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ኢምፒ ርብዒ ጋሎን),
						'one' => q({0}ኢምፒ. ርብዒ ጋሎን),
						'other' => q({0}ኢምፒ. ርብዒ ጋሎን),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ኢምፒ ርብዒ ጋሎን),
						'one' => q({0}ኢምፒ. ርብዒ ጋሎን),
						'other' => q({0}ኢምፒ. ርብዒ ጋሎን),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ማንካ),
						'one' => q({0}ማንካ),
						'other' => q({0}ማንካ),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ማንካ),
						'one' => q({0}ማንካ),
						'other' => q({0}ማንካ),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ናይ ሻሂ ማንካ),
						'one' => q({0}ናይ ሻሂ ማንካ),
						'other' => q({0}ናይ ሻሂ ማንካ),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ናይ ሻሂ ማንካ),
						'one' => q({0}ናይ ሻሂ ማንካ),
						'other' => q({0}ናይ ሻሂ ማንካ),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ኣንፈት),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ኣንፈት),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(ኪቢ{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(ኪቢ{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(ሜቢ{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(ሜቢ{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(ጊቢ{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(ጊቢ{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(ቴቢ{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(ቴቢ{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(ፔቢ{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(ፔቢ{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ኤግዚቢ{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ኤግዚቢ{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(ዜቢ{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(ዜቢ{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(ዮቢ{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(ዮቢ{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ዴሲ{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ዴሲ{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(ፒኮ{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(ፒኮ{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ፌምቶ{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ፌምቶ{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(አቶ{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(አቶ{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(ሴንቲ{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(ሴንቲ{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(ዜፕቶ{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(ዜፕቶ{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ዮክቶ{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ዮክቶ{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ሮንቶ{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ሮንቶ{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ሚሊ{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ሚሊ{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(ክዌክቶ{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(ክዌክቶ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(ናኖ{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(ናኖ{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ዴካ{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ዴካ{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ቴራ{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ቴራ{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(ፔታ{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(ፔታ{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(ኤግዛ{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ኤግዛ{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ሄክቶ{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ሄክቶ{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(ዜታ{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(ዜታ{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ዮታ{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ዮታ{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ሮና{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ሮና{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(ኪ{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(ኪ{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(ክዌታ{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(ክዌታ{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(ሜጋ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(ሜጋ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(ጊጋ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(ጊጋ{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ሓይሊ ስሕበት),
						'one' => q({0} ስሕበት),
						'other' => q({0} ስሕበት),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ሓይሊ ስሕበት),
						'one' => q({0} ስሕበት),
						'other' => q({0} ስሕበት),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ሜትሮ/ሰከንድ²),
						'one' => q({0} ሜ/ሰ²),
						'other' => q({0} ሜ/ሰ²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ሜትሮ/ሰከንድ²),
						'one' => q({0} ሜ/ሰ²),
						'other' => q({0} ሜ/ሰ²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(ኣርክ ደቓይቕ),
						'one' => q({0} ኣርክ ደቒቓ),
						'other' => q({0} ኣርክ ደቓይቕ),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ኣርክ ደቓይቕ),
						'one' => q({0} ኣርክ ደቒቓ),
						'other' => q({0} ኣርክ ደቓይቕ),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ኣርክ ሰከንድ),
						'one' => q({0} ኣርክ ሰከንድ),
						'other' => q({0} ኣርክ ሰከንድ),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ኣርክ ሰከንድ),
						'one' => q({0} ኣርክ ሰከንድ),
						'other' => q({0} ኣርክ ሰከንድ),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ዲግሪ),
						'one' => q({0} ዲግሪ),
						'other' => q({0} ዲግሪ),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ዲግሪ),
						'one' => q({0} ዲግሪ),
						'other' => q({0} ዲግሪ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ራድያን),
						'one' => q({0} ራድያን),
						'other' => q({0} ራድያን),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ራድያን),
						'one' => q({0} ራድያን),
						'other' => q({0} ራድያን),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ሬቮልዩሽን),
						'one' => q({0} ሬቮልዩሽን),
						'other' => q({0} ሬቮልዩሽን),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ሬቮልዩሽን),
						'one' => q({0} ሬቮልዩሽን),
						'other' => q({0} ሬቮልዩሽን),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ዱናም),
						'one' => q({0} ዱናም),
						'other' => q({0} ዱናም),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ዱናም),
						'one' => q({0} ዱናም),
						'other' => q({0} ዱናም),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ሄክታር),
						'one' => q({0} ሄክ),
						'other' => q({0} ሄክ),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ሄክታር),
						'one' => q({0} ሄክ),
						'other' => q({0} ሄክ),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ሴሜ²),
						'one' => q({0} ሴሜ²),
						'other' => q({0} ሴሜ²),
						'per' => q({0}/ሴሜ²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ሴሜ²),
						'one' => q({0} ሴሜ²),
						'other' => q({0} ሴሜ²),
						'per' => q({0}/ሴሜ²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ካሬ ጫማ),
						'one' => q({0} ካሬ ጫማ),
						'other' => q({0} ካሬ ጫማ),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ካሬ ጫማ),
						'one' => q({0} ካሬ ጫማ),
						'other' => q({0} ካሬ ጫማ),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ኢንች²),
						'one' => q({0} ኢንች²),
						'other' => q({0} ኢንች²),
						'per' => q({0}/ኢንች²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ኢንች²),
						'one' => q({0} ኢንች²),
						'other' => q({0} ኢንች²),
						'per' => q({0}/ኢንች²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ኪሜ²),
						'one' => q({0} ኪሜ²),
						'other' => q({0} ኪሜ²),
						'per' => q({0}/ኪሜ²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ኪሜ²),
						'one' => q({0} ኪሜ²),
						'other' => q({0} ኪሜ²),
						'per' => q({0}/ኪሜ²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ሜተር²),
						'one' => q({0} ሜ²),
						'other' => q({0} ሜ²),
						'per' => q({0}/ሜ²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ሜተር²),
						'one' => q({0} ሜ²),
						'other' => q({0} ሜ²),
						'per' => q({0}/ሜ²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ካሬ ማይል),
						'one' => q({0} ካሬ ማ),
						'other' => q({0} ካሬ ማ),
						'per' => q({0}/ማ²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ካሬ ማይል),
						'one' => q({0} ካሬ ማ),
						'other' => q({0} ካሬ ማ),
						'per' => q({0}/ማ²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ያርድ²),
						'one' => q({0} ያ²),
						'other' => q({0} ያ²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ያርድ²),
						'one' => q({0} ያ²),
						'other' => q({0} ያ²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ኣቕሓ),
						'one' => q({0} ኣቕሓ),
						'other' => q({0} ኣቕሑ),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ኣቕሓ),
						'one' => q({0} ኣቕሓ),
						'other' => q({0} ኣቕሑ),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ሚግ/ዲሲሊተርትሮ),
						'one' => q({0} ሚግ/ዲሲሊተርትሮ),
						'other' => q({0} ሚግ/ዲሲሊተርትሮ),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ሚግ/ዲሲሊተርትሮ),
						'one' => q({0} ሚግ/ዲሲሊተርትሮ),
						'other' => q({0} ሚግ/ዲሲሊተርትሮ),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ሚሊሞል/ሊትሮ),
						'one' => q({0} ሚሊሞል/ሊትሮ),
						'other' => q({0} ሚሊሞል/ሊትሮ),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ሚሊሞል/ሊትሮ),
						'one' => q({0} ሚሊሞል/ሊትሮ),
						'other' => q({0} ሚሊሞል/ሊትሮ),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ሞል),
						'one' => q({0} ሞል),
						'other' => q({0} ሞል),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ሞል),
						'one' => q({0} ሞል),
						'other' => q({0} ሞል),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ሚእታዊ),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ሚእታዊ),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(አብ ሚሌ),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(አብ ሚሌ),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ክፍልታት/ሚልዮን),
						'one' => q({0} ክፍልታት ኣብ ሚልዮን),
						'other' => q({0} ክፍልታት ኣብ ሚልዮን),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ክፍልታት/ሚልዮን),
						'one' => q({0} ክፍልታት ኣብ ሚልዮን),
						'other' => q({0} ክፍልታት ኣብ ሚልዮን),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(አብ ሚርያድ),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(አብ ሚርያድ),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(ክፍልታት/ሓደ ቢልዮን),
						'one' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
						'other' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(ክፍልታት/ሓደ ቢልዮን),
						'one' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
						'other' => q({0} ክፍልታት ኣብ ሓደ ቢልዮን),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ሊትሮ/100 ኪሜ),
						'one' => q({0} ሊትሮ/100 ኪሜ),
						'other' => q({0} ሊትሮ/100 ኪሜ),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ሊትሮ/100 ኪሜ),
						'one' => q({0} ሊትሮ/100 ኪሜ),
						'other' => q({0} ሊትሮ/100 ኪሜ),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ሊትሮ/ኪሎሜትር),
						'one' => q({0} ሊትሮ/ኪሜ),
						'other' => q({0} ሊትሮ/ኪሜ),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ሊትሮ/ኪሎሜትር),
						'one' => q({0} ሊትሮ/ኪሜ),
						'other' => q({0} ሊትሮ/ኪሜ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ማይልስ/ሓደ ጋሎን),
						'one' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
						'other' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ማይልስ/ሓደ ጋሎን),
						'one' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
						'other' => q({0} ማይልስ ኣብ ሓደ ጋሎን),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ማይል/ሓደ ኢምፕ. ጋሎን),
						'one' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
						'other' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ማይል/ሓደ ኢምፕ. ጋሎን),
						'one' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
						'other' => q({0} ማይል ኣብ ሓደ ኢምፕ. ጋሎን),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ምብራቕ),
						'north' => q({0} ሰሜን),
						'south' => q({0} ደቡብ),
						'west' => q({0} ምዕራብ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ምብራቕ),
						'north' => q({0} ሰሜን),
						'south' => q({0} ደቡብ),
						'west' => q({0} ምዕራብ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(ቢት),
						'one' => q({0} ቢት),
						'other' => q({0} ቢት),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(ቢት),
						'one' => q({0} ቢት),
						'other' => q({0} ቢት),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(ባይት),
						'one' => q({0} ባይት),
						'other' => q({0} ባይት),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(ባይት),
						'one' => q({0} ባይት),
						'other' => q({0} ባይት),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(ጊጋቢት),
						'one' => q({0} ጊጋቢት),
						'other' => q({0} ጊጋቢት),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(ጊጋቢት),
						'one' => q({0} ጊጋቢት),
						'other' => q({0} ጊጋቢት),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ጊጋባይት),
						'one' => q({0} ጊጋባይት),
						'other' => q({0} ጊጋባይት),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ጊጋባይት),
						'one' => q({0} ጊጋባይት),
						'other' => q({0} ጊጋባይት),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(ኪሎቢት),
						'one' => q({0} ኪሎቢት),
						'other' => q({0} ኪሎቢት),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(ኪሎቢት),
						'one' => q({0} ኪሎቢት),
						'other' => q({0} ኪሎቢት),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ኪሎባይት),
						'one' => q({0} ኪሎባይት),
						'other' => q({0} ኪሎባይት),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ኪሎባይት),
						'one' => q({0} ኪሎባይት),
						'other' => q({0} ኪሎባይት),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ሜጋቢት),
						'one' => q({0} ሜጋቢት),
						'other' => q({0} ሜጋቢት),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ሜጋቢት),
						'one' => q({0} ሜጋቢት),
						'other' => q({0} ሜጋቢት),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ሜጋባይት),
						'one' => q({0} ሜጋባይት),
						'other' => q({0} ሜጋባይት),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ሜጋባይት),
						'one' => q({0} ሜጋባይት),
						'other' => q({0} ሜጋባይት),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(ፔታባይት),
						'one' => q({0} ፔታባይት),
						'other' => q({0} ፔታባይት),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(ፔታባይት),
						'one' => q({0} ፔታባይት),
						'other' => q({0} ፔታባይት),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ቴራቢት),
						'one' => q({0} ቴራቢት),
						'other' => q({0} ቴራቢት),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ቴራቢት),
						'one' => q({0} ቴራቢት),
						'other' => q({0} ቴራቢት),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ቴራባይት),
						'one' => q({0} ቴራባይት),
						'other' => q({0} ቴራባይት),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ቴራባይት),
						'one' => q({0} ቴራባይት),
						'other' => q({0} ቴራባይት),
					},
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
					'duration-day' => {
						'name' => q(መዓልታት),
						'one' => q({0} መዓልቲ),
						'other' => q({0} መዓልታት),
						'per' => q({0}/መ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(መዓልታት),
						'one' => q({0} መዓልቲ),
						'other' => q({0} መዓልታት),
						'per' => q({0}/መ),
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
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ሰዓታት),
						'one' => q({0} ሰዓ),
						'other' => q({0} ሰዓ),
						'per' => q({0}/ሰ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ሰዓታት),
						'one' => q({0} ሰዓ),
						'other' => q({0} ሰዓ),
						'per' => q({0}/ሰ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μሰከንድ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μሰከንድ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ሚሊሴኮንድ),
						'one' => q({0} ሚሴ),
						'other' => q({0} ሚሴ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ሚሊሴኮንድ),
						'one' => q({0} ሚሴ),
						'other' => q({0} ሚሴ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ደቒቓታት),
						'one' => q({0} ደቒቓ),
						'other' => q({0} ደቒቓ),
						'per' => q({0}/ደቒቓ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ደቒቓታት),
						'one' => q({0} ደቒቓ),
						'other' => q({0} ደቒቓ),
						'per' => q({0}/ደቒቓ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ኣዋርሕ),
						'one' => q({0}/ኣዋርሕ),
						'other' => q({0}/ኣዋርሕ),
						'per' => q({0}/ወርሒ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ኣዋርሕ),
						'one' => q({0}/ኣዋርሕ),
						'other' => q({0}/ኣዋርሕ),
						'per' => q({0}/ወርሒ),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(ለይቲ),
						'one' => q({0} ለይቲ),
						'other' => q({0} ለይቲ),
						'per' => q({0}/ ለይቲ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(ለይቲ),
						'one' => q({0} ለይቲ),
						'other' => q({0} ለይቲ),
						'per' => q({0}/ ለይቲ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ርብዒ),
						'one' => q({0} ርብዒ),
						'other' => q({0} ርብዒ),
						'per' => q({0}/ርብዒ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ርብዒ),
						'one' => q({0} ርብዒ),
						'other' => q({0} ርብዒ),
						'per' => q({0}/ርብዒ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ሴኮንድ),
						'one' => q({0} ሴኮንድ),
						'other' => q({0} ሴኮንድ),
						'per' => q({0}/ሴ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ሴኮንድ),
						'one' => q({0} ሴኮንድ),
						'other' => q({0} ሴኮንድ),
						'per' => q({0}/ሴ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ሰሙናት),
						'one' => q({0} ሰሙን),
						'other' => q({0} ሰሙ),
						'per' => q({0}/ሰሙን),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ሰሙናት),
						'one' => q({0} ሰሙን),
						'other' => q({0} ሰሙ),
						'per' => q({0}/ሰሙን),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ዓመታት),
						'one' => q({0} ዓመት),
						'other' => q({0} ዓመታት),
						'per' => q({0}/ዓመት),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ዓመታት),
						'one' => q({0} ዓመት),
						'other' => q({0} ዓመታት),
						'per' => q({0}/ዓመት),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(አምፒር),
						'one' => q({0} አምፒር),
						'other' => q({0} አምፒር),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(አምፒር),
						'one' => q({0} አምፒር),
						'other' => q({0} አምፒር),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(ሚሊ አምፒር),
						'one' => q({0} ሚሊ አምፒር),
						'other' => q({0} ሚሊ አምፒር),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(ሚሊ አምፒር),
						'one' => q({0} ሚሊ አምፒር),
						'other' => q({0} ሚሊ አምፒር),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ኦህም),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ኦህም),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ቮልት),
						'one' => q({0} ቮልት),
						'other' => q({0} ቮልት),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ቮልት),
						'one' => q({0} ቮልት),
						'other' => q({0} ቮልት),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(ካሎሪ),
						'one' => q({0} ካሎሪ),
						'other' => q({0} ካሎሪ),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(ካሎሪ),
						'one' => q({0} ካሎሪ),
						'other' => q({0} ካሎሪ),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(ኤሌክትሮኖቮልት),
						'one' => q({0} ኤሌክትሮኖቮልት),
						'other' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(ኤሌክትሮኖቮልት),
						'one' => q({0} ኤሌክትሮኖቮልት),
						'other' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ጁል),
						'one' => q({0} ጁል),
						'other' => q({0} ጁል),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ጁል),
						'one' => q({0} ጁል),
						'other' => q({0} ጁል),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(ኪካሎሪ),
						'one' => q({0} ኪካሎሪ),
						'other' => q({0} ኪካሎሪ),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(ኪካሎሪ),
						'one' => q({0} ኪካሎሪ),
						'other' => q({0} ኪካሎሪ),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ኪሎጁል),
						'one' => q({0} ኪጁ),
						'other' => q({0} ኪጁ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ኪሎጁል),
						'one' => q({0} ኪጁ),
						'other' => q({0} ኪጁ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(ኪሎዋት-ሰዓት),
						'one' => q({0} ኪሎዋት ሰዓት),
						'other' => q({0} ኪሎዋት ሰዓት),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(ኪሎዋት-ሰዓት),
						'one' => q({0} ኪሎዋት ሰዓት),
						'other' => q({0} ኪሎዋት ሰዓት),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'one' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'other' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'one' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
						'other' => q({0} ናይ አመሪካ ናይ ሙቐት መለክዒ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'one' => q({0} ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'other' => q({0} ኪሎዋት-ሰዓት/100 ኪሎሜትር),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'one' => q({0} ኪሎዋት-ሰዓት/100 ኪሎሜትር),
						'other' => q({0} ኪሎዋት-ሰዓት/100 ኪሎሜትር),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ኒውተን),
						'one' => q({0} ኒውተን),
						'other' => q({0} ኒውተን),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ኒውተን),
						'one' => q({0} ኒውተን),
						'other' => q({0} ኒውተን),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(ፓውንድ ሓይሊ),
						'one' => q({0} ፓውንድ ሓይሊ),
						'other' => q({0} ፓውንድ ሓይሊ),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(ፓውንድ ሓይሊ),
						'one' => q({0} ፓውንድ ሓይሊ),
						'other' => q({0} ፓውንድ ሓይሊ),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(ጊጋኸርትዝ),
						'one' => q({0} ጊጋኸርትዝ),
						'other' => q({0} ጊጋኸርትዝ),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(ጊጋኸርትዝ),
						'one' => q({0} ጊጋኸርትዝ),
						'other' => q({0} ጊጋኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ኸርትዝ),
						'one' => q({0} ኸርትዝ),
						'other' => q({0} ኸርትዝ),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ኸርትዝ),
						'one' => q({0} ኸርትዝ),
						'other' => q({0} ኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(ኪሎኸርትዝ),
						'one' => q({0} ኪሎኸርትዝ),
						'other' => q({0} ኪሎኸርትዝ),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(ኪሎኸርትዝ),
						'one' => q({0} ኪሎኸርትዝ),
						'other' => q({0} ኪሎኸርትዝ),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(ሜጋኸርትዝ),
						'one' => q({0} ሜጋኸርትዝ),
						'other' => q({0} ሜጋኸርትዝ),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(ሜጋኸርትዝ),
						'one' => q({0} ሜጋኸርትዝ),
						'other' => q({0} ሜጋኸርትዝ),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ነጥብታት),
						'one' => q({0} ነጥብ),
						'other' => q({0} ነጥብታት),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ነጥብታት),
						'one' => q({0} ነጥብ),
						'other' => q({0} ነጥብታት),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ኢኤም),
						'one' => q({0} ኢኤም),
						'other' => q({0} ኢኤም),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ኢኤም),
						'one' => q({0} ኢኤም),
						'other' => q({0} ኢኤም),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ሜጋፒክሰላታ),
						'one' => q({0} ሜጋ),
						'other' => q({0} ሜጋ),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ሜጋፒክሰላታ),
						'one' => q({0} ሜጋ),
						'other' => q({0} ሜጋ),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ፒክሰላት),
						'one' => q({0} ፒክ),
						'other' => q({0} ፒክ),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ፒክሰላት),
						'one' => q({0} ፒክ),
						'other' => q({0} ፒክ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ፒፒሴሜ),
						'one' => q({0} ፒፒሴሜ),
						'other' => q({0} ፒፒሴሜ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ፒፒኢ),
						'one' => q({0} ፒፒኢ),
						'other' => q({0} ፒፒኢ),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(ሴሜ),
						'one' => q({0} ሴሜ),
						'other' => q({0} ሴሜ),
						'per' => q({0}/ሴሜ),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(ሴሜ),
						'one' => q({0} ሴሜ),
						'other' => q({0} ሴሜ),
						'per' => q({0}/ሴሜ),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ዴሜ),
						'one' => q({0} ዴሜ),
						'other' => q({0} ዴሜ),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ዴሜ),
						'one' => q({0} ዴሜ),
						'other' => q({0} ዴሜ),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ራድየስ መሬት),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ራድየስ መሬት),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ፊት),
						'one' => q({0} ፊት),
						'other' => q({0} ፊት),
						'per' => q({0}/ፊት),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ፊት),
						'one' => q({0} ፊት),
						'other' => q({0} ፊት),
						'per' => q({0}/ፊት),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(ኢንችስ),
						'one' => q({0} ኢን),
						'other' => q({0} ኢን),
						'per' => q({0}/ኢን),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(ኢንችስ),
						'one' => q({0} ኢን),
						'other' => q({0} ኢን),
						'per' => q({0}/ኢን),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ኪሜ),
						'one' => q({0} ኪሜ),
						'other' => q({0} ኪሜ),
						'per' => q({0}/ኪሜ),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ኪሜ),
						'one' => q({0} ኪሜ),
						'other' => q({0} ኪሜ),
						'per' => q({0}/ኪሜ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ሜ),
						'one' => q({0} ሜ),
						'other' => q({0} ሜ),
						'per' => q({0}/ሜ),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ሜ),
						'one' => q({0} ሜ),
						'other' => q({0} ሜ),
						'per' => q({0}/ሜ),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(ማይክሮሜተር),
						'one' => q({0} ማሜ),
						'other' => q({0} ማሜ),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(ማይክሮሜተር),
						'one' => q({0} ማሜ),
						'other' => q({0} ማሜ),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ማይላት),
						'one' => q({0} ማ),
						'other' => q({0} ማ),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ማይላት),
						'one' => q({0} ማ),
						'other' => q({0} ማ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ሚሜ),
						'one' => q({0} ሚሜ),
						'other' => q({0} ሚሜ),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ሚሜ),
						'one' => q({0} ሚሜ),
						'other' => q({0} ሚሜ),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(ናሜ),
						'one' => q({0} ናሜ),
						'other' => q({0} ናሜ),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(ናሜ),
						'one' => q({0} ናሜ),
						'other' => q({0} ናሜ),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(ፒሜ),
						'one' => q({0} ፒሜ),
						'other' => q({0} ፒሜ),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(ፒሜ),
						'one' => q({0} ፒሜ),
						'other' => q({0} ፒሜ),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ናይ ጸሓይ ራዲየስ),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ናይ ጸሓይ ራዲየስ),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ያርድስ),
						'one' => q({0} ያ),
						'other' => q({0} ያ),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ያርድስ),
						'one' => q({0} ያ),
						'other' => q({0} ያ),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ካንዴላ),
						'one' => q({0} ካንዴላ),
						'other' => q({0} ካንዴላ),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ካንዴላ),
						'one' => q({0} ካንዴላ),
						'other' => q({0} ካንዴላ),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(ሉመን),
						'one' => q({0} ሉመን),
						'other' => q({0} ሉመን),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(ሉመን),
						'one' => q({0} ሉመን),
						'other' => q({0} ሉመን),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(ለክስ),
						'one' => q({0} ለክስ),
						'other' => q({0} ለክስ),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(ለክስ),
						'one' => q({0} ለክስ),
						'other' => q({0} ለክስ),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(ጸሓያዊ ብርሃናት),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(ጸሓያዊ ብርሃናት),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ካራት),
						'one' => q({0} ካራት),
						'other' => q({0} ካራት),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(ዳልቶን),
						'one' => q({0} ዳልቶን),
						'other' => q({0} ዳልቶን),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(ዳልቶን),
						'one' => q({0} ዳልቶን),
						'other' => q({0} ዳልቶን),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ናይ መሬት ክብደት),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ናይ መሬት ክብደት),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(ግሬን),
						'one' => q({0} ግሬን),
						'other' => q({0} ግሬን),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(ግሬን),
						'one' => q({0} ግሬን),
						'other' => q({0} ግሬን),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ግራም),
						'one' => q({0} ግ),
						'other' => q({0} ግ),
						'per' => q({0}/ግራም),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ግራም),
						'one' => q({0} ግ),
						'other' => q({0} ግ),
						'per' => q({0}/ግራም),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(ኪግ),
						'one' => q({0} ኪግ),
						'other' => q({0} ኪግ),
						'per' => q({0}/ኪግ),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(ኪግ),
						'one' => q({0} ኪግ),
						'other' => q({0} ኪግ),
						'per' => q({0}/ኪግ),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μግ),
						'one' => q({0} μግ),
						'other' => q({0} μግ),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μግ),
						'one' => q({0} μግ),
						'other' => q({0} μግ),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ሚግ),
						'one' => q({0} ሚግ),
						'other' => q({0} ሚግ),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ሚግ),
						'one' => q({0} ሚግ),
						'other' => q({0} ሚግ),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ኣውንስ),
						'one' => q({0} ኣውንስ),
						'other' => q({0} ኣውንስ),
						'per' => q({0}/ኣውንስ),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ኣውንስ),
						'one' => q({0} ኣውንስ),
						'other' => q({0} ኣውንስ),
						'per' => q({0}/ኣውንስ),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ትሮይ ኣውንስ),
						'one' => q({0} ትሮይ ኣውንስ),
						'other' => q({0} ትሮይ ኣውንስ),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ትሮይ ኣውንስ),
						'one' => q({0} ትሮይ ኣውንስ),
						'other' => q({0} ትሮይ ኣውንስ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ፓውንድ),
						'one' => q({0} ፓውንድ),
						'other' => q({0} ፓውንድ),
						'per' => q({0}/ፓውንድ),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ፓውንድ),
						'one' => q({0} ፓውንድ),
						'other' => q({0} ፓውንድ),
						'per' => q({0}/ፓውንድ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(ናይ ጸሓይ ክብደት),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(ናይ ጸሓይ ክብደት),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ቶን),
						'one' => q({0} ቶን),
						'other' => q({0} ቶን),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ቶን),
						'one' => q({0} ቶን),
						'other' => q({0} ቶን),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(ጊጋዋት),
						'one' => q({0} ጊጋዋት),
						'other' => q({0} ጊጋዋት),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(ጊጋዋት),
						'one' => q({0} ጊጋዋት),
						'other' => q({0} ጊጋዋት),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ሓይሊ ፈረስ),
						'one' => q({0} ሓይሊ ፈረስ),
						'other' => q({0} ሓይሊ ፈረስ),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ሓይሊ ፈረስ),
						'one' => q({0} ሓይሊ ፈረስ),
						'other' => q({0} ሓይሊ ፈረስ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(ኪሎዋት),
						'one' => q({0} ኪሎዋት),
						'other' => q({0} ኪሎዋት),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(ኪሎዋት),
						'one' => q({0} ኪሎዋት),
						'other' => q({0} ኪሎዋት),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(ሜጋዋት),
						'one' => q({0} ሜጋዋት),
						'other' => q({0} ሜጋዋት),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(ሜጋዋት),
						'one' => q({0} ሜጋዋት),
						'other' => q({0} ሜጋዋት),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ሚሊዋት),
						'one' => q({0} ሚሊዋት),
						'other' => q({0} ሚሊዋት),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ሚሊዋት),
						'one' => q({0} ሚሊዋት),
						'other' => q({0} ሚሊዋት),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ዋት),
						'one' => q({0} ዋት),
						'other' => q({0} ዋት),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ዋት),
						'one' => q({0} ዋት),
						'other' => q({0} ዋት),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(አትሞስፌር),
						'one' => q({0} አትሞስፌር),
						'other' => q({0} አትሞስፌር),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(አትሞስፌር),
						'one' => q({0} አትሞስፌር),
						'other' => q({0} አትሞስፌር),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ባር),
						'one' => q({0} ባር),
						'other' => q({0} ባር),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ባር),
						'one' => q({0} ባር),
						'other' => q({0} ባር),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ሄክቶ ፓስካል),
						'one' => q({0} ሄክቶ ፓስካል),
						'other' => q({0} ሄክቶ ፓስካል),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ሄክቶ ፓስካል),
						'one' => q({0} ሄክቶ ፓስካል),
						'other' => q({0} ሄክቶ ፓስካል),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(ኢንች ሜርኩሪ),
						'one' => q({0} ኢንች ሜርኩሪ),
						'other' => q({0} ኢንች ሜርኩሪ),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(ኢንች ሜርኩሪ),
						'one' => q({0} ኢንች ሜርኩሪ),
						'other' => q({0} ኢንች ሜርኩሪ),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(ኪሎፓስካል),
						'one' => q({0} ኪሎፓስካል),
						'other' => q({0} ኪሎፓስካል),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(ኪሎፓስካል),
						'one' => q({0} ኪሎፓስካል),
						'other' => q({0} ኪሎፓስካል),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(ሜጋፓስካል),
						'one' => q({0} ሜጋፓስካል),
						'other' => q({0} ሜጋፓስካል),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(ሜጋፓስካል),
						'one' => q({0} ሜጋፓስካል),
						'other' => q({0} ሜጋፓስካል),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ሚሊባር),
						'one' => q({0} ሚሊባር),
						'other' => q({0} ሚሊባር),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ሚሊባር),
						'one' => q({0} ሚሊባር),
						'other' => q({0} ሚሊባር),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(ሚሜ ሜርኩሪ),
						'one' => q({0} ሚሜ ሜርኩሪ),
						'other' => q({0} ሚሜ ሜርኩሪ),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(ሚሜ ሜርኩሪ),
						'one' => q({0} ሚሜ ሜርኩሪ),
						'other' => q({0} ሚሜ ሜርኩሪ),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(ፓስካል),
						'one' => q({0} ፓስካል),
						'other' => q({0} ፓስካል),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(ፓስካል),
						'one' => q({0} ፓስካል),
						'other' => q({0} ፓስካል),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(ኪሜ/ሰዓት),
						'one' => q({0} ኪሜ/ሰዓት),
						'other' => q({0} ኪሜ/ሰዓት),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(ኪሜ/ሰዓት),
						'one' => q({0} ኪሜ/ሰዓት),
						'other' => q({0} ኪሜ/ሰዓት),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(እስር),
						'one' => q({0} እስር),
						'other' => q({0} እስር),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(እስር),
						'one' => q({0} እስር),
						'other' => q({0} እስር),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ብርሃን),
						'one' => q({0} ብርሃን),
						'other' => q({0} ብርሃን),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ብርሃን),
						'one' => q({0} ብርሃን),
						'other' => q({0} ብርሃን),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ሜትሮ/ሰከንድ),
						'one' => q({0} ሜ/ሰ),
						'other' => q({0} ሜ/ሰ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ሜትሮ/ሰከንድ),
						'one' => q({0} ሜ/ሰ),
						'other' => q({0} ሜ/ሰ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ማይል/ሰዓት),
						'one' => q({0} ማይል ኣብ ሰዓት),
						'other' => q({0} ማይል ኣብ ሰዓት),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ማይል/ሰዓት),
						'one' => q({0} ማይል ኣብ ሰዓት),
						'other' => q({0} ማይል ኣብ ሰዓት),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ዲግሪ ሴንቲግሬድ),
						'one' => q({0}°ሴ),
						'other' => q({0}°ሴ),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ዲግሪ ሴንቲግሬድ),
						'one' => q({0}°ሴ),
						'other' => q({0}°ሴ),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ዲግሪ ፋረንሃይት),
						'one' => q({0}°ፋ),
						'other' => q({0}°ፋ),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ዲግሪ ፋረንሃይት),
						'one' => q({0}°ፋ),
						'other' => q({0}°ፋ),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(ዲግሪ ሙቐት),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(ዲግሪ ሙቐት),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(ኬ),
						'one' => q({0} ኬ),
						'other' => q({0} ኬ),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(ኬ),
						'one' => q({0} ኬ),
						'other' => q({0} ኬ),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(ኒውተን ሜትር),
						'one' => q({0} ኒውተን ሜትር),
						'other' => q({0} ኒውተን ሜትር),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(ኒውተን ሜትር),
						'one' => q({0} ኒውተን ሜትር),
						'other' => q({0} ኒውተን ሜትር),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(ፓውንድ ሓይሊ ጫማ),
						'one' => q({0} ፓውንድ ሓይሊ ጫማ),
						'other' => q({0} ፓውንድ ሓይሊ ጫማ),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(ፓውንድ ሓይሊ ጫማ),
						'one' => q({0} ፓውንድ ሓይሊ ጫማ),
						'other' => q({0} ፓውንድ ሓይሊ ጫማ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre ጫማ),
						'one' => q({0} ac ጫማ),
						'other' => q({0} ac ጫማ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre ጫማ),
						'one' => q({0} ac ጫማ),
						'other' => q({0} ac ጫማ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(በርሚል),
						'one' => q({0} በርሚል),
						'other' => q({0} በርሚል),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(በርሚል),
						'one' => q({0} በርሚል),
						'other' => q({0} በርሚል),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(ዳውላ),
						'one' => q({0} ዳውላ),
						'other' => q({0} ዳውላ),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(ዳውላ),
						'one' => q({0} ዳውላ),
						'other' => q({0} ዳውላ),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ሴሊ),
						'one' => q({0} ሴሊ),
						'other' => q({0} ሴሊ),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ሴሊ),
						'one' => q({0} ሴሊ),
						'other' => q({0} ሴሊ),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(ሴሚ³),
						'one' => q({0} ሴሜ³),
						'other' => q({0} ሴሜ³),
						'per' => q({0}/ሴሜ³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(ሴሚ³),
						'one' => q({0} ሴሜ³),
						'other' => q({0} ሴሜ³),
						'per' => q({0}/ሴሜ³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ጫማ³),
						'one' => q({0} ጫማ³),
						'other' => q({0} ጫማ³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ጫማ³),
						'one' => q({0} ጫማ³),
						'other' => q({0} ጫማ³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ኢንች³),
						'one' => q({0} ኢንች³),
						'other' => q({0} ኢንች³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ኢንች³),
						'one' => q({0} ኢንች³),
						'other' => q({0} ኢንች³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(ኪሜ³),
						'one' => q({0} ኪሜ³),
						'other' => q({0} ኪሜ³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(ኪሜ³),
						'one' => q({0} ኪሜ³),
						'other' => q({0} ኪሜ³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(ሜ³),
						'one' => q({0} ሜ³),
						'other' => q({0} ሜ³),
						'per' => q({0}/ሜ³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(ሜ³),
						'one' => q({0} ሜ³),
						'other' => q({0} ሜ³),
						'per' => q({0}/ሜ³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(ማ³),
						'one' => q({0} ማ³),
						'other' => q({0} ማ³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ማ³),
						'one' => q({0} ማ³),
						'other' => q({0} ማ³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ያርድ³),
						'one' => q({0} ያ³),
						'other' => q({0} ያ³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ያርድ³),
						'one' => q({0} ያ³),
						'other' => q({0} ያ³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ኩባያ),
						'one' => q({0} ኩባያ),
						'other' => q({0} ኩባያ),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ኩባያ),
						'one' => q({0} ኩባያ),
						'other' => q({0} ኩባያ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ዴሊ),
						'one' => q({0} ዴሊ),
						'other' => q({0} ዴሊ),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ዴሊ),
						'one' => q({0} ዴሊ),
						'other' => q({0} ዴሊ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ናይ ኬክ ማንካ),
						'one' => q({0} ናይ ኬክ ማንካ),
						'other' => q({0} ናይ ኬክ ማንካ),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ናይ ኬክ ማንካ),
						'one' => q({0} ናይ ኬክ ማንካ),
						'other' => q({0} ናይ ኬክ ማንካ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(ኢምፕ. ናይ ኬክ ማንካ),
						'one' => q({0} ኢምፕ. ናይ ኬክ ማንካ),
						'other' => q({0} ኢምፕ. ናይ ኬክ ማንካ),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ኢምፕ. ናይ ኬክ ማንካ),
						'one' => q({0} ኢምፕ. ናይ ኬክ ማንካ),
						'other' => q({0} ኢምፕ. ናይ ኬክ ማንካ),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ድራም),
						'one' => q({0} ድራም),
						'other' => q({0} ድራም),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ድራም),
						'one' => q({0} ድራም),
						'other' => q({0} ድራም),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ጠብታ),
						'one' => q({0} ጠብታ),
						'other' => q({0} ጠብታ),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ጠብታ),
						'one' => q({0} ጠብታ),
						'other' => q({0} ጠብታ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ፈሳሲ ኦውንስ),
						'one' => q({0} ፈሳሲ ኦውንስ),
						'other' => q({0} ፈሳሲ ኦውንስ),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ፈሳሲ ኦውንስ),
						'one' => q({0} ፈሳሲ ኦውንስ),
						'other' => q({0} ፈሳሲ ኦውንስ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ኢምፕ. ፈሳሲ ኦውንስ),
						'one' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
						'other' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ኢምፕ. ፈሳሲ ኦውንስ),
						'one' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
						'other' => q({0} ኢምፕ. ፈሳሲ ኦውንስ),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(ጋሎን),
						'one' => q({0} ጋሎን),
						'other' => q({0} ጋሎን),
						'per' => q({0}/ብጋሎን),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(ጋሎን),
						'one' => q({0} ጋሎን),
						'other' => q({0} ጋሎን),
						'per' => q({0}/ብጋሎን),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ኢምፕ. ጋሎን),
						'one' => q({0} ኢምፕ. ጋሎን),
						'other' => q({0} ኢምፕ. ጋሎን),
						'per' => q({0}/ኢምፕጋሎን),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ኢምፕ. ጋሎን),
						'one' => q({0} ኢምፕ. ጋሎን),
						'other' => q({0} ኢምፕ. ጋሎን),
						'per' => q({0}/ኢምፕጋሎን),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ሄሊ),
						'one' => q({0} ሄሊ),
						'other' => q({0} ሄሊ),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ሄሊ),
						'one' => q({0} ሄሊ),
						'other' => q({0} ሄሊ),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(ጂገር),
						'one' => q({0} ጂገር),
						'other' => q({0} ጂገር),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(ጂገር),
						'one' => q({0} ጂገር),
						'other' => q({0} ጂገር),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ሊትሮ),
						'one' => q({0} ሊ),
						'other' => q({0} ሊ),
						'per' => q({0}/ሊ),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ሊትሮ),
						'one' => q({0} ሊ),
						'other' => q({0} ሊ),
						'per' => q({0}/ሊ),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ሜሊ),
						'one' => q({0} ሜሊ),
						'other' => q({0} ሜሊ),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ሜሊ),
						'one' => q({0} ሜሊ),
						'other' => q({0} ሜሊ),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ሚሊ),
						'one' => q({0} ሚሊ),
						'other' => q({0} ሚሊ),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ሚሊ),
						'one' => q({0} ሚሊ),
						'other' => q({0} ሚሊ),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ቁንጣር),
						'one' => q({0} ቁንጣር),
						'other' => q({0} ቁንጣር),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ቁንጣር),
						'one' => q({0} ቁንጣር),
						'other' => q({0} ቁንጣር),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(ፒንት),
						'one' => q({0} ፒንት),
						'other' => q({0} ፒንት),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(ፒንት),
						'one' => q({0} ፒንት),
						'other' => q({0} ፒንት),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ሜፓት),
						'one' => q({0} ሜፓ),
						'other' => q({0} ሜፓ),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ሜፓት),
						'one' => q({0} ሜፓ),
						'other' => q({0} ሜፓ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ርብዒ ጋሎን),
						'one' => q({0} ርብዒ ጋሎን),
						'other' => q({0} ርብዒ ጋሎን),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ርብዒ ጋሎን),
						'one' => q({0} ርብዒ ጋሎን),
						'other' => q({0} ርብዒ ጋሎን),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ኢምፒ. ርብዒ ጋሎን),
						'one' => q({0} ኢምፒ. ርብዒ ጋሎን),
						'other' => q({0} ኢምፒ. ርብዒ ጋሎን),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ኢምፒ. ርብዒ ጋሎን),
						'one' => q({0} ኢምፒ. ርብዒ ጋሎን),
						'other' => q({0} ኢምፒ. ርብዒ ጋሎን),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ማንካ),
						'one' => q({0} ማንካ),
						'other' => q({0} ማንካ),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ማንካ),
						'one' => q({0} ማንካ),
						'other' => q({0} ማንካ),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ናይ ሻሂ ማንካ),
						'one' => q({0} ናይ ሻሂ ማንካ),
						'other' => q({0} ናይ ሻሂ ማንካ),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ናይ ሻሂ ማንካ),
						'one' => q({0} ናይ ሻሂ ማንካ),
						'other' => q({0} ናይ ሻሂ ማንካ),
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
	default		=> sub { qr'^(?i:ኣይፋልን|ኣ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}፣ {1}),
				middle => q({0}፣ {1}),
				end => q({0}ን {1}ን),
				2 => q({0}ን {1}ን),
		} }
);

has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'ethi',
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
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
		'AED' => {
			display_name => {
				'currency' => q(ሕቡራት ኢማራት ዓረብ ዲርሃም),
				'one' => q(ኢማራት ዲርሃም),
				'other' => q(ኢማራት ዲርሃም),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(ኣፍጋኒስታናዊ ኣፍጋን),
				'one' => q(ኣፍጋኒስታናዊ ኣፍጋን),
				'other' => q(ኣፍጋኒስታናዊ ኣፍጋን),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(ኣልባናዊ ሌክ),
				'one' => q(ኣልባናዊ ሌክ),
				'other' => q(ኣልባናዊ ሌኬ),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(ኣርመንያዊ ድራም),
				'one' => q(ኣርመንያዊ ድራም),
				'other' => q(ኣርመንያዊ ድራም),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(ሆላንድ ኣንቲለያን ጊልደር),
				'one' => q(ሆላንድ ኣንቲለያን ጊልደር),
				'other' => q(ሆላንድ ኣንቲለያን ጊልደር),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(ኣንጎላዊ ክዋንዛ),
				'one' => q(ኣንጎላዊ ክዋንዛ),
				'other' => q(ኣንጎላዊ ክዋንዛ),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(ኣርጀንቲናዊ ፔሶ),
				'one' => q(ኣርጀንቲናዊ ፔሶ),
				'other' => q(ኣርጀንቲናዊ ፔሶ),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(ኣውስትራልያዊ ዶላር),
				'one' => q(ኣውስትራልያዊ ዶላር),
				'other' => q(ኣውስትራልያዊ ዶላር),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(ኣሩባን ፍሎሪን),
				'one' => q(ኣሩባን ፍሎሪን),
				'other' => q(ኣሩባን ፍሎሪን),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(ኣዘርባጃናዊ ማናት),
				'one' => q(ኣዘርባጃናዊ ማናት),
				'other' => q(ኣዘርባጃናዊ ማናት),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(ቦዝንያ-ሄርዘጎቪና ተቐያሪ ምልክት),
				'one' => q(ቦዝንያ-ሄርዘጎቪና ተቐያሪ ምልክት),
				'other' => q(ቦዝንያ-ሄርዘጎቪና ተቐያሪ ምልክታት),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(ባርባዲያን ዶላር),
				'one' => q(ባርባዲያን ዶላር),
				'other' => q(ባርባዲያን ዶላር),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(ባንግላደሻዊ ታካ),
				'one' => q(ባንግላደሻዊ ታካ),
				'other' => q(ባንግላደሻዊ ታካ),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(ቡልጋርያዊ ሌቭ),
				'one' => q(ቡልጋርያዊ ሌቭ),
				'other' => q(ቡልጋርያዊ ሌቫ),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(ባሕሬናዊ ዲናር),
				'one' => q(ባሕሬናዊ ዲናር),
				'other' => q(ባሕሬናዊ ዲናር),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(ብሩንዳዊ ፍራንክ),
				'one' => q(ብሩንዳዊ ፍራንክ),
				'other' => q(ብሩንዳዊ ፍራንክ),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(በርሙዳን ዶላር),
				'one' => q(በርሙዳን ዶላር),
				'other' => q(በርሙዳን ዶላር),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(ብሩነይ ዶላር),
				'one' => q(ብሩነይ ዶላር),
				'other' => q(ብሩነይ ዶላር),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(ቦሊቭያዊ ቦሊቭያኖ),
				'one' => q(ቦሊቭያዊ ቦሊቭያኖ),
				'other' => q(ቦሊቭያዊ ቦሊቭያኖ),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(የብራዚል ሪል),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(ባሃማዊ ዶላር),
				'one' => q(ባሃማዊ ዶላር),
				'other' => q(ባሃማዊ ዶላር),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ቡታናዊ ንጉልትሩም),
				'one' => q(ቡታናዊ ንጉልትሩም),
				'other' => q(ቡታናዊ ንጉልትሩም),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(ቦትስዋናዊ ፑላ),
				'one' => q(ቦትስዋናዊ ፑላ),
				'other' => q(ቦትስዋናዊ ፑላ),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(ናይ ቤላሩስ ሩብል),
				'one' => q(ናይ ቤላሩስ ሩብል),
				'other' => q(ናይ ቤላሩስ ሩብል),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(ቤሊዝ ዶላር),
				'one' => q(ቤሊዝ ዶላር),
				'other' => q(ቤሊዝ ዶላር),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(ካናዳ ዶላር),
				'one' => q(ካናዳ ዶላር),
				'other' => q(ካናዳ ዶላር),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(ኮንጎ ፍራንክ),
				'one' => q(ኮንጎ ፍራንክ),
				'other' => q(ኮንጎ ፍራንክ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(ስዊስ ፍራንክ),
				'one' => q(ስዊስ ፍራንክ),
				'other' => q(ስዊስ ፍራንክ),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(ቺለዊ ፔሶ),
				'one' => q(ቺለዊ ፔሶ),
				'other' => q(ቺለዊ ፔሶ),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(ቻይናዊ ዩዋን \(ካብ ባሕሪ ወጻኢ\)),
				'one' => q(ቻይናዊ ዩዋን \(ካብ ባሕሪ ወጻኢ\)),
				'other' => q(ቻይናዊ ዩዋን \(ካብ ባሕሪ ወጻኢ\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(ዩዋን ቻይና),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(ኮሎምብያዊ ፔሶ),
				'one' => q(ኮሎምብያዊ ፔሶ),
				'other' => q(ኮሎምብያዊ ፔሶ),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(ኮስታሪካ ኮሎን),
				'one' => q(ኮስታሪካ ኮሎን),
				'other' => q(ኮስታሪካ ኮሎን),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(ኩባውያን ተቐያሪ ፔሶ),
				'one' => q(ኩባውያን ተቐያሪ ፔሶ),
				'other' => q(ኩባውያን ተቐያሪ ፔሶ),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(ኩባዊ ፔሶ),
				'one' => q(ኩባዊ ፔሶ),
				'other' => q(ኩባዊ ፔሶ),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(ናይ ኬፕ ቨርዲ ኤስኩዶ),
				'one' => q(ናይ ኬፕ ቨርዲ ኤስኩዶ),
				'other' => q(ናይ ኬፕ ቨርዲ ኤስኩዶ),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(ናይ ቸክ ኮሩና),
				'one' => q(ናይ ቸክ ኮሩና),
				'other' => q(ናይ ቸክ ኮሩና),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(ናይ ጅቡቲ ፍራንክ),
				'one' => q(ናይ ጅቡቲ ፍራንክ),
				'other' => q(ናይ ጅቡቲ ፍራንክ),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(ናይ ዴንማርክ ክሮነር),
				'one' => q(ናይ ዴንማርክ ክሮነር),
				'other' => q(ናይ ዴንማርክ ክሮነር),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(ዶሚኒካን ፔሶ),
				'one' => q(ዶሚኒካን ፔሶ),
				'other' => q(ዶሚኒካን ፔሶ),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(ኣልጀርያዊ ዲናር),
				'one' => q(ኣልጀርያዊ ዲናር),
				'other' => q(ኣልጀርያዊ ዲናር),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(ግብጻዊ ፓውንድ),
				'one' => q(ግብጻዊ ፓውንድ),
				'other' => q(ግብጻዊ ፓውንድ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(ኤርትራዊ ናቕፋ),
				'one' => q(ኤርትራዊ ናቕፋ),
				'other' => q(ኤርትራዊ ናቕፋ),
			},
		},
		'ETB' => {
			symbol => 'Br',
			display_name => {
				'currency' => q(ብር),
				'one' => q(ናይ ኢትዮጵያ ብር),
				'other' => q(ናይ ኢትዮጵያ ብር),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ዩሮ),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(ዶላር ፊጂ),
				'one' => q(ዶላር ፊጂ),
				'other' => q(ዶላር ፊጂ),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(ደሴታት ፎክላንድ ፓውንድ),
				'one' => q(ደሴታት ፎክላንድ ፓውንድ),
				'other' => q(ደሴታት ፎክላንድ ፓውንድ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(የእንግሊዝ ፓውንድ ስተርሊንግ),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(ጆርጅያዊ ላሪ),
				'one' => q(ጆርጅያዊ ላሪ),
				'other' => q(ጆርጅያዊ ላሪ),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ጋናዊ ሴዲ),
				'one' => q(ጋናዊ ሴዲ),
				'other' => q(ጋናዊ ሴዲስ),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(ጂብራልተር ፓውንድ),
				'one' => q(ጂብራልተር ፓውንድ),
				'other' => q(ጂብራልተር ፓውንድ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(ጋምብያዊ ዳላሲ),
				'one' => q(ጋምብያዊ ዳላሲ),
				'other' => q(ጋምብያዊ ዳላሲስ),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(ናይ ጊኒ ፍራንክ),
				'one' => q(ናይ ጊኒ ፍራንክ),
				'other' => q(ናይ ጊኒ ፍራንክ),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(ጓቲማላ ኲትዛል),
				'one' => q(ጓቲማላ ኲትዛል),
				'other' => q(ጓቲማላ ኲትዛል),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(ጓያናኛ ዶላር),
				'one' => q(ጓያናኛ ዶላር),
				'other' => q(ጓያናኛ ዶላር),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(ሆንግ ኮንግ ዶላር),
				'one' => q(ሆንግ ኮንግ ዶላር),
				'other' => q(ሆንግ ኮንግ ዶላር),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(ሆንዱራስ ለምፒራ),
				'one' => q(ሆንዱራስ ለምፒራ),
				'other' => q(ሆንዱራስ ለምፒራ),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(ክሮኤሽያዊ ኩና),
				'one' => q(ክሮኤሽያዊ ኩና),
				'other' => q(ክሮኤሽያዊ ኩና),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(ናይ ሃይቲ ጎርደ),
				'one' => q(ናይ ሃይቲ ጎርደ),
				'other' => q(ናይ ሃይቲ ጎርደ),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ሃንጋርያዊ ፎርንት),
				'one' => q(ሃንጋርያዊ ፎርንት),
				'other' => q(ሃንጋርያዊ ፎርንት),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(ኢንዶነዥያዊ ሩፒያ),
				'one' => q(ኢንዶነዥያዊ ሩፒያ),
				'other' => q(ኢንዶነዥያዊ ሩፒያ),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(እስራኤላዊ ሓድሽ ሸቃል),
				'one' => q(እስራኤላዊ ሓድሽ ሸቃል),
				'other' => q(እስራኤላዊ ሓድሽ ሸቃል),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ናይ ሕንድ ሩፒ),
				'one' => q(ናይ ሕንድ ሩፒ),
				'other' => q(ናይ ሕንድ ሩፒ),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(ዒራቂ ዲናር),
				'one' => q(ናይ ዒራቕ ዲናር),
				'other' => q(ዒራቂ ዲናር),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(ናይ ኢራን ርያል),
				'one' => q(ናይ ኢራን ርያል),
				'other' => q(ናይ ኢራን ርያል),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(ናይ ኣይስላንድ ክሮና),
				'one' => q(ናይ ኣይስላንድ ክሮና),
				'other' => q(ናይ ኣይስላንድ ክሮና),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(ጃማይካ ዶላር),
				'one' => q(ጃማይካ ዶላር),
				'other' => q(ጃማይካ ዶላር),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(ዮርዳኖሳዊ ዲናር),
				'one' => q(ዮርዳኖሳዊ ዲናር),
				'other' => q(ዮርዳኖሳዊ ዲናር),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(የን ጃፓን),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(ኬንያዊ ሽልንግ),
				'one' => q(ኬንያዊ ሽልንግ),
				'other' => q(ኬንያዊ ሽልንግ),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(ኪርጊስታናዊ ሶም),
				'one' => q(ኪርጊስታናዊ ሶም),
				'other' => q(ኪርጊስታናዊ ሶም),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(ካምቦድያዊ ሪኤል),
				'one' => q(ካምቦድያዊ ሪኤል),
				'other' => q(ካምቦድያዊ ሪኤል),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(ኮሞርያዊ ፍራንክ),
				'one' => q(ኮሞርያዊ ፍራንክ),
				'other' => q(ኮሞርያዊ ፍራንክ),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(ሰሜን ኮርያዊ ዎን),
				'one' => q(ሰሜን ኮርያዊ ዎን),
				'other' => q(ሰሜን ኮርያዊ ዎን),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(ደቡብ ኮርያዊ ዎን),
				'one' => q(ደቡብ ኮርያዊ ዎን),
				'other' => q(ደቡብ ኮርያዊ ዎን),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(ኩዌቲ ዲናር),
				'one' => q(ኩዌቲ ዲናር),
				'other' => q(ኩዌቲ ዲናር),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(ደሴታት ካይመን ዶላር),
				'one' => q(ደሴታት ካይመን ዶላር),
				'other' => q(ደሴታት ካይመን ዶላር),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(ካዛኪስታናዊ ተንገ),
				'one' => q(ካዛኪስታናዊ ተንገ),
				'other' => q(ካዛኪስታናዊ ተንገ),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(ላኦስያዊ ኪፕ),
				'one' => q(ላኦስያዊ ኪፕ),
				'other' => q(ላኦስያዊ ኪፕ),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(ሊባኖሳዊ ፓውንድ),
				'one' => q(ሊባኖሳዊ ፓውንድ),
				'other' => q(ሊባኖሳዊ ፓውንድ),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(ስሪላንካ ሩፒ),
				'one' => q(ስሪላንካ ሩፒ),
				'other' => q(ስሪላንካ ሩፒ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(ላይበርያዊ ዶላር),
				'one' => q(ላይበርያዊ ዶላር),
				'other' => q(ላይበርያዊ ዶላር),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(ሌሶቶ ሎቲ),
				'one' => q(ሌሶቶ ሎቲ),
				'other' => q(ሌሶቶ ሎቲ),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(ናይ ሊብያ ዲናር),
				'one' => q(ናይ ሊብያ ዲናር),
				'other' => q(ናይ ሊብያ ዲናር),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(ሞሮካዊ ዲርሃም),
				'one' => q(ሞሮካዊ ዲርሃም),
				'other' => q(ሞሮካዊ ዲርሃም),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(ሞልዶቫን ሌው),
				'one' => q(ሞልዶቫን ሌው),
				'other' => q(ሞልዶቫን ሌይ),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ማላጋሲ ኣሪያሪ),
				'one' => q(ማላጋሲ ኣሪያሪ),
				'other' => q(ማላጋሲ ኣሪያሪ),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(ናይ መቄዶንያ ዲናር),
				'one' => q(ናይ መቄዶንያ ዲናር),
				'other' => q(ናይ መቄዶንያ ዲናሪ),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(ሚያንማር ክያት),
				'one' => q(ሚያንማር ክያት),
				'other' => q(ሚያንማር ክያት),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(ሞንጎላዊ ቱግሪክ),
				'one' => q(ሞንጎላዊ ቱግሪክ),
				'other' => q(ሞንጎላዊ ቱግሪክ),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(ማካኒዝ ፓታካ),
				'one' => q(ማካኒዝ ፓታካ),
				'other' => q(ማካኒዝ ፓታካ),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ሞሪታናዊ ኡጉዋያ),
				'one' => q(ሞሪታናዊ ኡጉዋያ),
				'other' => q(ሞሪታናዊ ኡጉዋያ),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(ሞሪሸስ ሩፒ),
				'one' => q(ሞሪሸስ ሩፒ),
				'other' => q(ሞሪሸስ ሩፒ),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(ማልዲቭያዊ ሩፍያ),
				'one' => q(ማልዲቭያዊ ሩፍያ),
				'other' => q(ማልዲቭያዊ ሩፍያ),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(ማላዊያዊ ኳቻ),
				'one' => q(ማላዊያዊ ኳቻ),
				'other' => q(ማላዊያዊ ኳቻ),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(ሜክሲካዊ ፔሶ),
				'one' => q(ሜክሲካዊ ፔሶ),
				'other' => q(ሜክሲካዊ ፔሶ),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(ሜክሲካዊ ብሩር ፔሶ \(1861–1992\)),
				'one' => q(ሜክሲካዊ ብሩር ፔሶ \(1861–1992\)),
				'other' => q(ሜክሲካዊ ብሩር ፔሶ \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(ኣሃዱ ወፍሪ ሜክሲኮ),
				'one' => q(ኣሃዱ ወፍሪ ሜክሲኮ),
				'other' => q(ኣሃዱ ወፍሪ ሜክሲኮ),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ማሌዥያዊ ሪንግጊት),
				'one' => q(ማሌዥያዊ ሪንግጊት),
				'other' => q(ማሌዥያዊ ሪንግጊት),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(ሞዛምቢካዊ ሜቲካል),
				'one' => q(ሞዛምቢካዊ ሜቲካል),
				'other' => q(ሞዛምቢካዊ ሜቲካል),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(ናሚብያ ዶላር),
				'one' => q(ናሚብያ ዶላር),
				'other' => q(ናሚብያ ዶላር),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(ናይጀርያዊ ናይራ),
				'one' => q(ናይጀርያዊ ናይራ),
				'other' => q(ናይጀርያዊ ናይራስ),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(ኒካራጓ ካርዶባ \(1988–1991\)),
				'one' => q(ኒካራጓ ካርዶባ \(1988–1991\)),
				'other' => q(ኒካራጓ ካርዶባ \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(ኒካራጓ ኮርዶባ),
				'one' => q(ኒካራጓ ኮርዶባ),
				'other' => q(ኒካራጓ ኮርዶባ),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(ናይ ኖርወይ ክሮነር),
				'one' => q(ናይ ኖርወይ ክሮነር),
				'other' => q(ናይ ኖርወይ ክሮነር),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(ኔፓላዊ ሩፒ),
				'one' => q(ኔፓላዊ ሩፒ),
				'other' => q(ኔፓላዊ ሩፒ),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(ኒውዚላንዳዊ ዶላር),
				'one' => q(ኒውዚላንዳዊ ዶላር),
				'other' => q(ኒውዚላንዳዊ ዶላር),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ኦማን ርያል),
				'one' => q(ኦማን ርያል),
				'other' => q(ኦማን ርያል),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(ፓናማያን ባልቦኣ),
				'one' => q(ፓናማያን ባልቦኣ),
				'other' => q(ፓናማያን ባልቦኣ),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(ፔሩቪያን ሶል),
				'one' => q(ፔሩቪያን ሶል),
				'other' => q(ፔሩቪያን ሶል),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(ፓፑዋ ኒው ጊኒ ኪና),
				'one' => q(ፓፑዋ ኒው ጊኒ ኪና),
				'other' => q(ፓፑዋ ኒው ጊኒ ኪና),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(ፊሊፒንስ ፔሶ),
				'one' => q(ፊሊፒንስ ፔሶ),
				'other' => q(ፊሊፒንስ ፔሶ),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(ፓኪስታናዊ ሩፒ),
				'one' => q(ፓኪስታናዊ ሩፒ),
				'other' => q(ፓኪስታናዊ ሩፒ),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(ፖላንዳዊ ዝሎቲ),
				'one' => q(ፖላንዳዊ ዝሎቲ),
				'other' => q(ፖላንዳዊ ዝሎቲ),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(ፓራጓያዊ ጓራኒ),
				'one' => q(ፓራጓያዊ ጓራኒ),
				'other' => q(ፓራጓያዊ ጓራኒ),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(ቀጠሪ ሪያል),
				'one' => q(ቀጠሪ ሪያል),
				'other' => q(ቀጠሪ ሪያል),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(ሮማንያዊ ሌው),
				'one' => q(ሮማንያዊ ሌው),
				'other' => q(ሮማንያዊ ሌይ),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(ናይ ሰርብያን ዲናር),
				'one' => q(ናይ ሰርብያን ዲናር),
				'other' => q(ናይ ሰርብያን ዲናር),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(የራሻ ሩብል),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ፍራንክ ሩዋንዳ),
				'one' => q(ፍራንክ ሩዋንዳ),
				'other' => q(ፍራንክ ሩዋንዳ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(ስዑዲ ዓረብ ሪያል),
				'one' => q(ስዑዲ ዓረብ ሪያል),
				'other' => q(ስዑዲ ዓረብ ሪያል),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(ደሴታት ሰሎሞን ዶላር),
				'one' => q(ደሴታት ሰሎሞን ዶላር),
				'other' => q(ደሴታት ሰሎሞን ዶላር),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(ሲሸሎ ሩፒ),
				'one' => q(ሲሸሎ ሩፒ),
				'other' => q(ሲሸሎ ሩፒ),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(ሱዳናዊ ፓውንድ),
				'one' => q(ሱዳናዊ ፓውንድ),
				'other' => q(ሱዳናዊ ፓውንድ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(ሽወደናዊ ክሮና),
				'one' => q(ሽወደናዊ ክሮና),
				'other' => q(ሽወደናዊ ክሮና),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(ሲንጋፖር ዶላር),
				'one' => q(ሲንጋፖር ዶላር),
				'other' => q(ሲንጋፖር ዶላር),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(ቅድስቲ ሄለና ፓውንድ),
				'one' => q(ቅድስቲ ሄለና ፓውንድ),
				'other' => q(ቅድስቲ ሄለና ፓውንድ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(ሴራሊዮን ልዮን),
				'one' => q(ሴራሊዮን ልዮን),
				'other' => q(ሴራሊዮን ልዮንስ),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(ሴራሊዮን ልዮን \(1964—2022\)),
				'one' => q(ሴራሊዮን ልዮን \(1964—2022\)),
				'other' => q(ሴራሊዮን ልዮንስ \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(ሶማልያዊ ሽልንግ),
				'one' => q(ሶማልያዊ ሽልንግ),
				'other' => q(ሶማልያዊ ሽልንግ),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(ሱሪናማዊ ዶላር),
				'one' => q(ሱሪናማዊ ዶላር),
				'other' => q(ሱሪናማዊ ዶላር),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(ደቡብ ሱዳን ፓውንድ),
				'one' => q(ደቡብ ሱዳን ፓውንድ),
				'other' => q(ደቡብ ሱዳን ፓውንድ),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(ሳኦ ቶሜን ፕሪንሲፐ ዶብራ),
				'one' => q(ሳኦ ቶሜን ፕሪንሲፐ ዶብራ),
				'other' => q(ሳኦ ቶሜን ፕሪንሲፐ ዶብራ),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(ሳልቫዶራን ኮሎን),
				'one' => q(ሳልቫዶራን ኮሎን),
				'other' => q(ሳልቫዶራን ኮሎን),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(ሶርያዊ ፓውንድ),
				'one' => q(ሶርያዊ ፓውንድ),
				'other' => q(ሶርያዊ ፓውንድ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(ስዋዚ ሊላንገኒ),
				'one' => q(ስዋዚ ሊላንገኒ),
				'other' => q(ስዋዚ ሊላንገኒ),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(ታይላንዳዊ ባህ),
				'one' => q(ታይላንዳዊ ባህ),
				'other' => q(ታይላንዳዊ ባህ),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(ታጂኪስታናዊ ሶሞኒ),
				'one' => q(ታጂኪስታናዊ ሶሞኒ),
				'other' => q(ታጂኪስታናዊ ሶሞኒ),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(ቱርክመኒስታናዊ ማናት),
				'one' => q(ቱርክመኒስታናዊ ማናት),
				'other' => q(ቱርክመኒስታናዊ ማናት),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(ቱኒዝያዊ ዲናር),
				'one' => q(ቱኒዝያዊ ዲናር),
				'other' => q(ቱኒዝያዊ ዲናር),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(ቶንጋዊ ፓ`ኣንጋ),
				'one' => q(ቶንጋዊ ፓ`ኣንጋ),
				'other' => q(ቶንጋዊ ፓ`ኣንጋ),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(ቱርካዊ ሊራ),
				'one' => q(ቱርካዊ ሊራ),
				'other' => q(ቱርካዊ ሊራ),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(ትሪኒዳድን ቶባጎ ዶላር),
				'one' => q(ትሪኒዳድን ቶባጎ ዶላር),
				'other' => q(ትሪኒዳድን ቶባጎ ዶላር),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(ኒው ታይዋን ዶላር),
				'one' => q(ኒው ታይዋን ዶላር),
				'other' => q(ኒው ታይዋን ዶላር),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(ታንዛንያዊ ሽልንግ),
				'one' => q(ታንዛንያዊ ሽልንግ),
				'other' => q(ታንዛንያዊ ሽልንግ),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ዩክሬናዊት ሪቭንያ),
				'one' => q(ዩክሬናዊት ሪቭንያ),
				'other' => q(ዩክሬናዊት ሪቭንያ),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ኡጋንዳዊ ሽልንግ),
				'one' => q(ኡጋንዳዊ ሽልንግ),
				'other' => q(ኡጋንዳዊ ሽልንግ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ዶላር ኣመሪካ),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(ዶላር ኣመሪካ \(ዝቕጽል መዓልቲ\)),
				'one' => q(ዶላር ኣመሪካ \(ዝቕጽል መዓልቲ\)),
				'other' => q(ዶላር ኣመሪካ \(ዝቕጽል መዓልቲ\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(ዶላር ኣመሪካ \(ተመሳሳሊ መዓልቲ\)),
				'one' => q(ዶላር ኣመሪካ \(ተመሳሳሊ መዓልቲ\)),
				'other' => q(ዶላር ኣመሪካ \(ተመሳሳሊ መዓልቲ\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(ኡራጋያዊ ፔሶ),
				'one' => q(ኡራጋያዊ ፔሶ),
				'other' => q(ኡራጋያዊ ፔሶ),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(ኡዝቤኪስታናዊ ሶም),
				'one' => q(ኡዝቤኪስታናዊ ሶም),
				'other' => q(ኡዝቤኪስታናዊ ሶም),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(ቬንዙዌላዊ ቦሊቫር),
				'one' => q(ቬንዙዌላዊ ቦሊቫር),
				'other' => q(ቬንዙዌላዊ ቦሊቫር),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(ቬትናማዊ ዶንግ),
				'one' => q(ቬትናማዊ ዶንግ),
				'other' => q(ቬትናማዊ ዶንግ),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(ቫኑኣቱ ቫቱ),
				'one' => q(ቫኑኣቱ ቫቱ),
				'other' => q(ቫኑኣቱ ቫቱ),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(ሳሞኣዊ ታላ),
				'one' => q(ሳሞኣዊ ታላ),
				'other' => q(ሳሞኣዊ ታላ),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(ማእከላይ ኣፍሪቃ ሲኤፍኤ ፍራንክ),
				'one' => q(ማእከላይ ኣፍሪቃ ሲኤፍኤ ፍራንክ),
				'other' => q(ማእከላይ ኣፍሪቃ ሲኤፍኤ ፍራንክ),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(ብሩር),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(ወርቂ),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(ምብራቕ ካሪብያን ዶላር),
				'one' => q(ምብራቕ ካሪብያን ዶላር),
				'other' => q(ምብራቕ ካሪብያን ዶላር),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(ምዕራብ ኣፍሪቃ CFA ፍራንክ),
				'one' => q(ምዕራብ ኣፍሪቃ ሲኤፍኤ ፍራንክ),
				'other' => q(ምዕራብ ኣፍሪቃ CFA ፍራንክ),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(ሲኤፍፒ ፍራንክ),
				'one' => q(ሲኤፍፒ ፍራንክ),
				'other' => q(ሲኤፍፒ ፍራንክ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ዘይተፈልጠ ባጤራ),
				'one' => q(\(ዘይተፈልጠ ባጤራ\)),
				'other' => q(\(ዘይተፈልጠ ባጤራ\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(የመኒ ርያል),
				'one' => q(የመኒ ርያል),
				'other' => q(የመኒ ርያል),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(ናይ ደቡብ ኣፍሪቃ ራንድ),
				'one' => q(ናይ ደቡብ ኣፍሪቃ ራንድ),
				'other' => q(ናይ ደቡብ ኣፍሪቃ ራንድ),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(ዛምብያዊ ኳቻ),
				'one' => q(ዛምብያዊ ኳቻ),
				'other' => q(ዛምብያዊ ኳቻ),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'ethiopic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'መስከረም',
							'ጥቅምቲ',
							'ሕዳር',
							'ታሕሳስ',
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዚያ',
							'ጉንበት',
							'ሰነ',
							'ሓምለ',
							'ነሓሰ',
							'ጷጉሜ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'መስከረም',
							'ጥቅምቲ',
							'ሕዳር',
							'ታሕሳስ',
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዚያ',
							'ጉንበት',
							'ሰነ',
							'ሓምለ',
							'ነሓሰ',
							'ጷጉሜ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'መስከረም',
							'ጥቅምቲ',
							'ሕዳር',
							'ታሕሳስ',
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዚያ',
							'ጉንበት',
							'ሰነ',
							'ሓምለ',
							'ነሓሰ',
							'ጷጉሜ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'መስከረም',
							'ጥቅምቲ',
							'ሕዳር',
							'ታሕሳስ',
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዚያ',
							'ጉንበት',
							'ሰነ',
							'ሓምለ',
							'ነሓሰ',
							'ጷጉሜ'
						],
						leap => [
							
						],
					},
				},
			},
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
					wide => {
						nonleap => [
							'ጥሪ',
							'ለካቲት',
							'መጋቢት',
							'ሚያዝያ',
							'ጉንበት',
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
							'ጉንበት',
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
					narrow => {
						mon => 'ሰ',
						tue => 'ሰ',
						wed => 'ረ',
						thu => 'ሓ',
						fri => 'ዓ',
						sat => 'ቀ',
						sun => 'ሰ'
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
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ethiopic' => {
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
		'islamic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE፣ d MMMM y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
		},
		'islamic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'ethiopic' => {
		},
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
		'islamic' => {
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E፣ d MMM y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E፣ d/M},
			MMMEd => q{E, MMM d},
			MMMMd => q{d MMMM},
			MMMMdd => q{dd MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{M/d},
			y => q{y G},
			yMM => q{MM/y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E፣ d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E፣ HH:mm},
			EHms => q{E፣ HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E፣ h:mm a},
			Ehms => q{E፣ h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E፣ d MMM y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y G},
			MEd => q{E፣ d/M},
			MMMEd => q{E፣ d MMM},
			MMMMW => q{ሰሙን W ናይ MMMM},
			MMMMd => q{d MMMM},
			MMMMdd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{d/M},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E፣ d/M/y},
			yMM => q{M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{ሰሙን w ናይ Y},
		},
		'islamic' => {
			Ed => q{d E},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			fallback => '{0} – {1}',
			hm => {
				h => q{h:mm – h:mm a},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
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
			fallback => '{0} – {1}',
			hm => {
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
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
		regionFormat => q(ግዘ {0}),
		regionFormat => q(ናይ {0} መዓልቲ ግዘ),
		regionFormat => q(ናይ መደበኛ ጊዜ {0} ግዘ),
		'Acre' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣክሪ#,
				'generic' => q#ግዘ አክሪ#,
				'standard' => q#ናይ መደበኛ ግዘ ኣክሪ#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#ናይ አፍጋኒስታን ግዘ#,
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
				'standard' => q#ናይ መደበኛ ግዘ ምዕራብ ኣፍሪቃ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ አላስካ#,
				'generic' => q#ግዘ አላስካ#,
				'standard' => q#ናይ መደበኛ ግዘ አላስካ#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣማዞን#,
				'generic' => q#ግዜ ኣማዞን#,
				'standard' => q#ናይ መደበኛ ግዘ ኣማዞን#,
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
		'America/Ciudad_Juarez' => {
			exemplarCity => q#ሲዩዳድ ጁዋረዝ#,
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
			exemplarCity => q#ቅዱስ ቶማስ#,
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
		'America_Central' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ ማእከላይ አመሪካ#,
				'generic' => q#ማእከላይ አመሪካ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ማእከላይ አመሪካ#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ ምብራቓዊ አመሪካ#,
				'generic' => q#ናይ ምብራቓዊ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ምብራቓዊ ኣመሪካ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ ጎቦ አመሪካ#,
				'generic' => q#ናይ ጎቦ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ጎቦ ኣመሪካ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ ፓስፊክ#,
				'generic' => q#ናይ ፓስፊክ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ፓስፊክ#,
			},
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
		'Apia' => {
			long => {
				'daylight' => q#ናይ መዓልቲ አፒያ ግዘ#,
				'generic' => q#ናይ አፒያ ግዘ#,
				'standard' => q#ናይ መደበኛ አፒያ ግዘ#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ናይ መዓልቲ አረብ ግዘ#,
				'generic' => q#ናይ አረብ ግዘ#,
				'standard' => q#ናይ መደበኛ አረብ ግዘ#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#ሎንግየርባየን#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኣርጀንቲና#,
				'generic' => q#ግዜ ኣርጀንቲና#,
				'standard' => q#ናይ መደበኛ ግዘ ኣርጀንቲና#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ምዕራባዊ ኣርጀንቲና#,
				'generic' => q#ግዜ ምዕራባዊ ኣርጀንቲና#,
				'standard' => q#ናይ መደበኛ ግዘ ምዕራባዊ ኣርጀንቲና#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ናይ ክረምቲ አርሜኒያ ግዘ#,
				'generic' => q#ናይ አርሜኒያ ግዘ#,
				'standard' => q#ናይ መደበኛ አርሜኒያ ግዘ#,
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
		'Atlantic' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ አትላንቲክ#,
				'generic' => q#ናይ አትላንቲክ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ አትላንቲክ#,
			},
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
		'Australia_Central' => {
			long => {
				'daylight' => q#ናይ ማዕከላይ መዓልቲ አውስራሊያ ግዘ#,
				'generic' => q#ናይ አውስራሊያ ግዘ#,
				'standard' => q#ናይ ማዕከላይ መደበኛ አውስራሊያ ግዘ#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ናይ ምዕራባዊ መዓልቲ አውስራሊያ ግዘ#,
				'generic' => q#ናይ ምዕራባዊ አውስራሊያ ግዘ#,
				'standard' => q#ናይ ምዕራባዊ መደበኛ አውስራሊያ ግዘ#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ናይ ምብራቓዊ መዓልቲ ኣውስትራልያ ግዘ#,
				'generic' => q#ናይ ምብራቓዊ ኣውስትራልያ ግዘ#,
				'standard' => q#ናይ ምብራቓዊ መደበኛ ኣውስትራልያ ግዘ#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ናይ ምዕራባዊ መዓልቲ አውስትራሊያ ግዘ#,
				'generic' => q#ናይ ምዕራባዊ አውስትራሊያ ግዘ#,
				'standard' => q#ናይ ምዕራባዊ መደበኛ አውስትራሊያ ግዘ#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ናይ ክረምቲ አዘርባዣን ግዘ#,
				'generic' => q#ናይ አዘርባዣን ግዘ#,
				'standard' => q#ናይ መደበኛ አዘርባዣን ግዘ#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ናይ ክረምቲ አዞረስ ግዘ#,
				'generic' => q#ናይ አዞረስ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ኣዞረስ#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ባንግላዲሽ ግዘ#,
				'generic' => q#ናይ ባንግላዲሽ ግዘ#,
				'standard' => q#ናይ መደበኛ ባንግላዲሽ ግዘ#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#ናይ ቡህታን ግዘ#,
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
				'standard' => q#ናይ መደበኛ ግዘ ብራዚልያ#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ናይ ብሩኔ ዳሩሳሌም ግዘ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኬፕ ቨርደ#,
				'generic' => q#ግዜ ኬፕ ቨርደ#,
				'standard' => q#ናይ መደበኛ ግዘ ኬፕ ቨርደ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#ናይ መደበኛ ቻሞሮ ግዘ#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ቻትሃም ግዘ#,
				'generic' => q#ናይ ቻትሃም ግዘ#,
				'standard' => q#ናይ መደበኛ ቻትሃም ግዘ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ቺሌ#,
				'generic' => q#ግዜ ቺሌ#,
				'standard' => q#ናይ መደበኛ ግዘ ቺሌ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ቻይና ግዘ#,
				'generic' => q#ናይ ቻይና ግዘ#,
				'standard' => q#ናይ መደበኛ ቻይና ግዘ#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#ናይ ልደት ደሴት ግዘ#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#ናይ ኮኮስ ደሴት ግዘ#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኮሎምብያ#,
				'generic' => q#ግዜ ኮሎምብያ#,
				'standard' => q#ናይ መደበኛ ግዘ ኮሎምብያ#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#ናይ ፍርቂ ክረምቲ ኩክ ደሴት ግዘ#,
				'generic' => q#ናይ ኩክ ደሴት ግዘ#,
				'standard' => q#ናይ መደበኛ ኩክ ደሴት ግዘ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ግዘ ኩባ#,
				'generic' => q#ናይ ኩባ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ኩባ#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ናይ ዴቪስ ግዘ#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ናይ ዱሞ-ዱርቪል ግዘ#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ናይ ምብራቅ ቲሞር ግዘ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ደሴት ፋሲካ#,
				'generic' => q#ግዜ ደሴት ፋሲካ#,
				'standard' => q#ናይ መደበኛ ግዘ ደሴት ፋሲካ#,
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
				'daylight' => q#ናይ መደበኛ አይሪሽ ግዘ#,
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
		'Europe/Zurich' => {
			exemplarCity => q#ዙሪክ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኤውሮጳ#,
				'generic' => q#ናይ ማእከላይ ኤውሮጳ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ማእከላይ ኤውሮጳ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ምብራቕ ኤውሮጳ#,
				'generic' => q#ናይ ምብራቕ ኤውሮጳ ግዘ#,
				'standard' => q#ናይ መደበኛ ግዘ ምብራቕ ኤውሮጳ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ናይ ርሑቕ-ምብራቕ ኤውሮጳዊ ግዘ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ምዕራባዊ ኤውሮጳዊ ግዘ#,
				'generic' => q#ናይ ምዕራባዊ ኤውሮጳዊ ግዘ#,
				'standard' => q#ናይ መደበኛ ምዕራባዊ ኤውሮጳዊ ግዘ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ግዜ ከረምቲ ደሴታት ፎክላንድ#,
				'generic' => q#ግዜ ደሴታት ፎክላንድ#,
				'standard' => q#ናይ መደበኛ ግዘ ደሴታት ፎክላንድ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ፊጂ ግዘ#,
				'generic' => q#ናይ ፊጂ ግዘ#,
				'standard' => q#ናይ መደበኛ ፊጂ ግዘ#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ግዜ ፈረንሳዊት ጊያና#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ናይ ደቡባዊን ኣንታርቲክ ግዘ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ግዜ ጋላፓጎስ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#ናይ ጋምቢየር ግዘ#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ጆርጂያ ግዘ#,
				'generic' => q#ናይ ጆርጂያ ግዘ#,
				'standard' => q#ናይ መደበኛ ጆርጂያ ግዘ#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#ናይ ጊልበርት ደሴታት ግዘ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ምብራቓዊ ግዘ ግሪንላንድ#,
				'generic' => q#ናይ ምብራቓዊ ግዘ ግሪንላንድ#,
				'standard' => q#ናይ መደበኛ ምብራቓዊ ግዘ ግሪንላንድ#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ምዕራብ ግሪንላንድ ግዘ#,
				'generic' => q#ናይ ምዕራብ ግሪንላንድ ግዘ#,
				'standard' => q#ናይ መደበኛ ምዕራብ ግሪንላንድ ግዘ#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#ናይ መደበኛ ገልፍ ግዘ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ግዜ ጉያና#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ሃዋይ-ኣሌውቲያን ግዘ#,
				'generic' => q#ናይ ሃዋይ-ኣሌውቲያን ግዘ#,
				'standard' => q#ናይ መደበኛ ሃዋይ-ኣሌውቲያን ግዘ#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ሆንግ ኮንግ ግዘ#,
				'generic' => q#ናይ ሆንግ ኮንግ ግዘ#,
				'standard' => q#ናይ መደበኛ ሆንግ ኮንግ ግዘ#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ሆቭድ ግዘ#,
				'generic' => q#ናይ ሆቭድ ግዘ#,
				'standard' => q#ናይ መደበኛ ሆቭድ ግዘ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ናይ መደበኛ ህንድ ግዘ#,
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
		'Indochina' => {
			long => {
				'standard' => q#ናይ ኢንዶቻይና ግዘ#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#ናይ ማእከላይ ኢንዶነዥያ ግዘ#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#ናይ ምብራቓዊ ኢንዶነዥያ ግዘ#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#ናይ ምዕራባዊ ኢንዶነዥያ ግዘ#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ኢራን ግዘ#,
				'generic' => q#ናይ ኢራን ግዘ#,
				'standard' => q#ናይ መደበኛ ኢራን ግዘ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ኢርኩትስክ ግዘ#,
				'generic' => q#ናይ ኢርኩትስክ ግዘ#,
				'standard' => q#ናይ መደበኛ ኢርኩትስክ ግዘ#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ናይ መዓልቲ እስራኤል ግዘ#,
				'generic' => q#ናይ እስራኤል ግዘ#,
				'standard' => q#ናይ መደበኛ እስራኤል ግዘ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ጃፓን ግዘ#,
				'generic' => q#ናይ ጃፓን ግዘ#,
				'standard' => q#ናይ መደበኛ ጃፓን ግዘ#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#ናይ ካዛኪስታን ግዘ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ናይ ምብራቅ ካዛኪስታን ግዘ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#ናይ ምዕራብ ካዛኪስታን ግዘ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ኮሪያን ግዘ#,
				'generic' => q#ናይ ኮሪያን ግዘ#,
				'standard' => q#ናይ መደበኛ ኮሪያን ግዘ#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#ናይ ኮርሳይ ግዘ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ክራንስኖያርክ ግዘ#,
				'generic' => q#ናይ ክራንስኖያርክ ግዘ#,
				'standard' => q#ናይ መደበኛ ክራንስኖያርክ ግዘ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#ናይ ክርጅስታን ግዘ#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#ናይ ላይን ደሴታት ግዘ#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ሎርድ ሆው ግዘ#,
				'generic' => q#ናይ ሎርድ ሆው ግዘ#,
				'standard' => q#ናይ መድበኛ ሎርድ ሆው ግዘ#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ሜጋዳን ግዘ#,
				'generic' => q#ናይ ሜጋዳን ግዘ#,
				'standard' => q#ናይ መደበኛ ሜጋዳን ግዘ#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ናይ ማሌዢያ ግዘ#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#ናይ ሞልዲቭስ ግዘ#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#ናይ ማርኩዌሳስ ግዘ#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#ናይ ማርሻል ደሴታት ግዘ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ማውሪሸስ#,
				'generic' => q#ግዜ ማውሪሸስ#,
				'standard' => q#ናይ መደበኛ ግዘ ማውሪሸስ#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#ናይ ማውሶን ግዘ#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ሜክሲኮ ፓስፊክ ግዘ#,
				'generic' => q#ናይ ሜክሲኮ ፓስፊክ ግዘ#,
				'standard' => q#ናይ መደበኛ ሜክሲኮ ፓስፊክ ግዘ#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ኡላንባታር ግዘ#,
				'generic' => q#ናይ ኡላንባታር ግዘ#,
				'standard' => q#ናይ መደበኛ ኡላንባታር ግዘ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ሞስኮው ግዘ#,
				'generic' => q#ናይ ሞስኮው ግዘ#,
				'standard' => q#ናይ መደበኛ ሞስኮው ግዘ#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#ናይ ምያንማር ግዘ#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ናይ ናውሩ ግዘ#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#ናይ ኔፓል ግዘ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ኒው ካሌዶኒያ ግዘ#,
				'generic' => q#ናይ ኒው ካሌዶኒያ ግዘ#,
				'standard' => q#ናይ መደበኛ ኒው ካሌዶኒያ ግዘ#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ኒው ዚላንድ ግዘ#,
				'generic' => q#ናይ ኒው ዚላንድ ግዘ#,
				'standard' => q#ናይ መደበኛ ኒው ዚላንድ ግዘ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ኒውፋውንድላንድ ግዘ#,
				'generic' => q#ናይ ኒውፋውንድላንድ ግዘ#,
				'standard' => q#ናይ መደበኛ ኒውፋውንድላንድ ግዘ#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#ናይ ኒዌ ግዘ#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ኖርፎልክ ደሴት ግዘ#,
				'generic' => q#ናይ ኖርፎልክ ደሴት ግዘ#,
				'standard' => q#ናይ መደበኛ ኖርፎልክ ደሴት ግዘ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ፈርናንዶ ደ ኖሮንያ#,
				'generic' => q#ግዜ ፈርናንዶ ደ ኖሮንያ#,
				'standard' => q#ናይ መደበኛ ግዘ ፈርናንዶ ደ ኖሮንያ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ኖቮሲሪስክ ግዘ#,
				'generic' => q#ናይ ኖቮሲሪስክ ግዘ#,
				'standard' => q#ናይ መደበኛ ኖቮሲሪስክ ግዘ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ኦምስክ ግዘ#,
				'generic' => q#ናይ ኦምስክ ግዘ#,
				'standard' => q#ናይ መደበኛ ኦምስክ ግዘ#,
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
		'Pacific/Kanton' => {
			exemplarCity => q#ካንቶን#,
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
		'Pakistan' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ፓኪስታን ግዘ#,
				'generic' => q#ናይ ፓኪስታን ግዘ#,
				'standard' => q#ናይ መደበኛ ፓኪስታን ግዘ#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#ናይ ፓላው ግዘ#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#ናይ ፓፗ ኒው ጊኒ ግዘ#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ፓራጓይ#,
				'generic' => q#ግዜ ፓራጓይ#,
				'standard' => q#ናይ መደበኛ ግዘ ፓራጓይ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ፔሩ#,
				'generic' => q#ግዜ ፔሩ#,
				'standard' => q#ናይ መደበኛ ግዘ ፔሩ#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ፊሊፒን ግዘ#,
				'generic' => q#ናይ ፊሊፒን ግዘ#,
				'standard' => q#ናይ መደበኛ ፊሊፒን ግዘ#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ናይ ፊኒክስ ደሴታት ግዘ#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ቅዱስ ፒየርን ሚከሎን ግዘ#,
				'generic' => q#ናይ ቅዱስ ፒየርን ሚከሎን ግዘ#,
				'standard' => q#ናይ መደበኛ ቅዱስ ፒየርን ሚከሎን ግዘ#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#ናይ ፒትቻይርን ግዘ#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ናይ ፖናፔ ግዘ#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#ናይ ፕዮንግያንግ ግዘ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ግዜ ርዩንየን#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#ናይ ሮቴራ ግዘ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ሳክሃሊን ግዘ#,
				'generic' => q#ናይ ሳክሃሊን ግዘ#,
				'standard' => q#ናይ መደበኛ ሳክሃሊን ግዘ#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ሳሞዋ ግዘ#,
				'generic' => q#ናይ ሳሞዋ ግዘ#,
				'standard' => q#ናይ መደበኛ ሳሞዋ ግዘ#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#ግዜ ሲሸልስ#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#ናይ መደበኛ ሲጋፖር ግዘ#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#ናይ ሶሎሞን ደሴታት ግዘ#,
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
		'Syowa' => {
			long => {
				'standard' => q#ናይ ስዮዋ ግዘ#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ናይ ቲሂቲ ግዘ#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ናይ መዓልቲ ቴፒ ግዘ#,
				'generic' => q#ናይ ቴፒ ግዘ#,
				'standard' => q#ናይ መደበኛ ቴፒ ግዘ#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#ናይ ታጃክስታን ግዘ#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ናይ ቶኬላው ግዘ#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ቶንጋ ግዘ#,
				'generic' => q#ናይ ቶንጋ ግዘ#,
				'standard' => q#ናይ መደበኛ ቶንጋ ግዘ#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#ናይ ቹክ ግዘ#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ቱርክሜኒስታን ግዘ#,
				'generic' => q#ናይ ቱርክሜኒስታን ግዘ#,
				'standard' => q#ናይ መደበኛ ቱርክሜኒስታን ግዘ#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#ናይ ቱቫሉ ግዘ#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ግዜ ክረምቲ ኡራጓይ#,
				'generic' => q#ግዜ ኡራጓይ#,
				'standard' => q#ናይ መደበኛ ግዘ ኡራጓይ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ኡዝቤኪስታን ግዘ#,
				'generic' => q#ናይ ኡዝቤኪስታን ግዘ#,
				'standard' => q#ናይ መደበኛ ኡዝቤኪስታን ግዘ#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ቫኗታው ግዘ#,
				'generic' => q#ናይ ቫኗታው ግዘ#,
				'standard' => q#ናይ መደበኛ ቫኗታው ግዘ#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ግዜ ቬኔዝዌላ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ቭላዲቮስቶክ ግዘ#,
				'generic' => q#ናይ ቭላዲቮስቶክ ግዘ#,
				'standard' => q#ናይ መደበኛ ቭላዲቮስቶክ ግዘ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ቮልጎግራድ ግዘ#,
				'generic' => q#ናይ ቮልጎግራድ ግዘ#,
				'standard' => q#ናይ መደበኛ ቮልጎግራድ ግዘ#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ናይ ቮስቶክ ግዘ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ናይ ዌክ ደሴት ግዘ#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ናይ ዌልስን ፉቷ ግዘ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ያኩትስክ ግዘ#,
				'generic' => q#ናይ ያኩትስክ ግዘ#,
				'standard' => q#ናይ መደበኛ ያኩትስክ ግዘ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ናይ ክረምቲ ያክተርኒበርግ ግዘ#,
				'generic' => q#ናይ ያክተርኒበርግ ግዘ#,
				'standard' => q#ናይ መደበኛ ያክተርኒበርግ ግዘ#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#ናይ ዩኮን ግዘ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
