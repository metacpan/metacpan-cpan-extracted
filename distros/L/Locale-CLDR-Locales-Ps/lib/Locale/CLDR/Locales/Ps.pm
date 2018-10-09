=encoding utf8

=head1

Locale::CLDR::Locales::Ps - Package for language Pashto

=cut

package Locale::CLDR::Locales::Ps;
# This file auto generated from Data\common\main\ps.xml
#	on Sun  7 Oct 10:53:58 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
				'aa' => 'افري',
 				'ab' => 'ابخازي',
 				'ace' => 'اچيني',
 				'ada' => 'ادانگمي',
 				'ady' => 'اديغي',
 				'af' => 'افریکانسي',
 				'agq' => 'اغیمي',
 				'ain' => 'اينويي',
 				'ak' => 'اکاني',
 				'ale' => 'اليوتي',
 				'alt' => 'سویل الټای',
 				'am' => 'امهاري',
 				'an' => 'اراگونېسي',
 				'anp' => 'انگيکي',
 				'ar' => 'عربي',
 				'ar_001' => 'نوې معياري عربي',
 				'arn' => 'ماپوچه',
 				'arp' => 'اراپاهوي',
 				'as' => 'اسامي',
 				'asa' => 'اسويي',
 				'ast' => 'استورياني',
 				'av' => 'اواري',
 				'awa' => 'اوادي',
 				'ay' => 'ایماري',
 				'az' => 'اذربایجاني',
 				'az@alt=short' => 'اذري',
 				'ba' => 'باشکير',
 				'bal' => 'بلوڅي',
 				'ban' => 'بالنی',
 				'bas' => 'باسا',
 				'be' => 'بېلاروسي',
 				'bem' => 'بیبا',
 				'bez' => 'بينا',
 				'bg' => 'بلغاري',
 				'bho' => 'بهوجپوري',
 				'bi' => 'بسلاما',
 				'bin' => 'بینی',
 				'bla' => 'سکسيکا',
 				'bm' => 'بامره',
 				'bn' => 'بنگالي',
 				'bo' => 'تبتي',
 				'br' => 'برېتون',
 				'brx' => 'بودو',
 				'bs' => 'بوسني',
 				'bug' => 'بگنيايي',
 				'byn' => 'بلین',
 				'ca' => 'کټلاني',
 				'ce' => 'چيچيني',
 				'ceb' => 'سیبوانوي',
 				'cgg' => 'چيگايي',
 				'ch' => 'چمورو',
 				'chk' => 'چواوکي',
 				'chm' => 'ماري',
 				'cho' => 'چوکټاوي',
 				'chr' => 'چېروکي',
 				'chy' => 'شيني',
 				'ckb' => 'منځنۍ کوردي',
 				'co' => 'کورسيکاني',
 				'crs' => 'سسيلوا ڪروئل فرانسوي',
 				'cs' => 'چېکي',
 				'cu' => 'د کليسا سلاوي',
 				'cv' => 'چوواشي',
 				'cy' => 'ويلشي',
 				'da' => 'دانمارکي',
 				'dak' => 'داکوتا',
 				'dar' => 'درگوا',
 				'dav' => 'ټایټا',
 				'de' => 'الماني',
 				'de_AT' => 'آسترالیا آلمان',
 				'de_CH' => 'سوئس لوی جرمن',
 				'dgr' => 'داگرب',
 				'dje' => 'زرما',
 				'dsb' => 'لوړې سربي',
 				'dua' => 'دوالا',
 				'dv' => 'ديویهی',
 				'dyo' => 'جولا فوني',
 				'dz' => 'ژونگکه',
 				'dzg' => 'ډزاګا',
 				'ebu' => 'ایمو',
 				'ee' => 'ايو',
 				'efi' => 'افک',
 				'eka' => 'اکجک',
 				'el' => 'یوناني',
 				'en' => 'انګریزي',
 				'en_AU' => 'انګریزي (AU)',
 				'en_CA' => 'کاناډايي انګلیسي',
 				'en_GB' => 'برتانوی انګلیسي',
 				'en_GB@alt=short' => 'انګریزي (GB)',
 				'en_US' => 'انګریزي (US)',
 				'en_US@alt=short' => 'انګریزي (US)',
 				'eo' => 'اسپرانتو',
 				'es' => 'هسپانوي',
 				'es_419' => 'لاتیني امریکایي اسپانوی',
 				'es_ES' => 'اروپایی اسپانوی',
 				'es_MX' => 'مکسیکو اسپانوی',
 				'et' => 'حبشي',
 				'eu' => 'باسکي',
 				'ewo' => 'اوونڊو',
 				'fa' => 'فارسي',
 				'ff' => 'فلاحہ',
 				'fi' => 'فینلنډي',
 				'fil' => 'فلیپیني',
 				'fj' => 'فجیان',
 				'fo' => 'فاروئې',
 				'fon' => 'فان',
 				'fr' => 'فرانسوي',
 				'fr_CA' => 'کاناډا فرانسي',
 				'fr_CH' => 'سویس فرانسي',
 				'fur' => 'فرائیلیین',
 				'fy' => 'فريزي',
 				'ga' => 'ائيرلېنډي',
 				'gaa' => 'gaa',
 				'gd' => 'سکاټلېنډي ګېلک',
 				'gez' => 'ګیز',
 				'gil' => 'گلبرتي',
 				'gl' => 'ګلېشيايي',
 				'gn' => 'ګوراني',
 				'gor' => 'ګورن ټالو',
 				'gsw' => 'سویس جرمن',
 				'gu' => 'ګجراتي',
 				'guz' => 'ګوسي',
 				'gv' => 'مینکس',
 				'gwi' => 'ګیچین',
 				'ha' => 'هوسا',
 				'haw' => 'هوایی',
 				'he' => 'عبري',
 				'hi' => 'هندي',
 				'hil' => 'ھلیګینون',
 				'hmn' => 'همونګ',
 				'hr' => 'کروواسي',
 				'hsb' => 'پورته صربي',
 				'ht' => 'هيٽي کرولي',
 				'hu' => 'هنگري',
 				'hup' => 'ھوپا',
 				'hy' => 'ارمني',
 				'hz' => 'هیرورو',
 				'ia' => 'انټرلنګوا',
 				'iba' => 'ابن',
 				'ibb' => 'ابیبیو',
 				'id' => 'انډونېزي',
 				'ie' => 'آسا نا جبة',
 				'ig' => 'اګبو',
 				'ii' => 'سیچیان یی',
 				'ilo' => 'الوکو',
 				'inh' => 'انگش',
 				'io' => 'اڊو',
 				'is' => 'ايسلنډي',
 				'it' => 'ایټالوي',
 				'iu' => 'انوکتیتوت',
 				'ja' => 'جاپاني',
 				'jbo' => 'لوجبان',
 				'jgo' => 'نګبا',
 				'jmc' => 'ماچمی',
 				'jv' => 'جاوايي',
 				'ka' => 'جورجيائي',
 				'kab' => 'کیبیل',
 				'kac' => 'کاچین',
 				'kaj' => 'ججو',
 				'kam' => 'کامبا',
 				'kbd' => 'کابیرین',
 				'kcg' => 'تایپ',
 				'kde' => 'ماکډون',
 				'kea' => 'کابوورډیانو',
 				'kfo' => 'کورو',
 				'kha' => 'خاسې',
 				'khq' => 'کویرا چینی',
 				'ki' => 'ککوؤو',
 				'kj' => 'کواناما',
 				'kk' => 'قازق',
 				'kkj' => 'کاکو',
 				'kl' => 'کلالیسٹ',
 				'kln' => 'کلینجن',
 				'km' => 'خمر',
 				'kmb' => 'کیمبوندو',
 				'kn' => 'کنأډه',
 				'ko' => 'کوریایی',
 				'kok' => 'کنکني',
 				'kpe' => 'کیلي',
 				'kr' => 'کنوری',
 				'krc' => 'کراچی بالکر',
 				'krl' => 'کاریلین',
 				'kru' => 'کورخ',
 				'ks' => 'کشمیري',
 				'ksb' => 'شمبلا',
 				'ksf' => 'بفیا',
 				'ksh' => 'کولوگنيسي',
 				'ku' => 'کردي',
 				'kum' => 'کومک',
 				'kv' => 'کومی',
 				'kw' => 'کرونيشي',
 				'ky' => 'کرګيز',
 				'la' => 'لاتیني',
 				'lad' => 'لاډینو',
 				'lag' => 'لنګی',
 				'lb' => 'لوګزامبورګي',
 				'lez' => 'لیګغیان',
 				'lg' => 'ګانده',
 				'li' => 'لمبرگیانی',
 				'lkt' => 'لکټو',
 				'ln' => 'لنگلا',
 				'lo' => 'لاو',
 				'loz' => 'لوزی',
 				'lrc' => 'شمالي لوری',
 				'lt' => 'ليتواني',
 				'lu' => 'لوبا-کټنګا',
 				'lua' => 'لبا لولوا',
 				'lun' => 'لندا',
 				'luo' => 'لو',
 				'lus' => 'ميزو',
 				'luy' => 'لویا',
 				'lv' => 'لېټواني',
 				'mad' => 'مدراسی',
 				'mag' => 'مګهي',
 				'mai' => 'مایتھلي',
 				'mak' => 'مکاسار',
 				'mas' => 'ماسائي',
 				'mdf' => 'موکشا',
 				'men' => 'مینڊي',
 				'mer' => 'ميرو',
 				'mfe' => 'ماریسیسن',
 				'mg' => 'ملغاسي',
 				'mgh' => 'مکھوامیتو',
 				'mgo' => 'ميټا',
 				'mh' => 'مارشلیز',
 				'mi' => 'ماوري',
 				'mic' => 'ممکق',
 				'min' => 'مينيگاباو',
 				'mk' => 'مقدوني',
 				'ml' => 'مالايالم',
 				'mn' => 'منګولیایی',
 				'mni' => 'مانی پوری',
 				'moh' => 'محاواک',
 				'mos' => 'ماسي',
 				'mr' => 'مراټهي',
 				'ms' => 'ملایا',
 				'mt' => 'مالټايي',
 				'mua' => 'مندانګ',
 				'mul' => 'څو ژبو',
 				'mus' => 'کريکي',
 				'mwl' => 'مرانديز',
 				'my' => 'برمایی',
 				'myv' => 'ارزيا',
 				'mzn' => 'مزاندراني',
 				'na' => 'نایرو',
 				'nap' => 'نيپالين',
 				'naq' => 'ناما',
 				'nb' => 'ناروې بوکمال',
 				'nd' => 'شمالي نديبل',
 				'ne' => 'نېپالي',
 				'new' => 'نيواري',
 				'ng' => 'ندونگا',
 				'nia' => 'نياس',
 				'niu' => 'نیان',
 				'nl' => 'هالېنډي',
 				'nl_BE' => 'فلېمېشي',
 				'nmg' => 'کواسیو',
 				'nn' => 'ناروېئي (نائنورسک)',
 				'nnh' => 'نایجیمون',
 				'no' => 'ناروېئې',
 				'nog' => 'نوګی',
 				'nqo' => 'نکو',
 				'nr' => 'سويلي نديبيل',
 				'nso' => 'شمالي سوتو',
 				'nus' => 'نویر',
 				'nv' => 'نواجو',
 				'ny' => 'نیانجا',
 				'nyn' => 'نینکول',
 				'oc' => 'اوکسيټاني',
 				'om' => 'اورومو',
 				'or' => 'اوڊيا',
 				'os' => 'اوسیٹک',
 				'pa' => 'پنجابي',
 				'pag' => 'پانګاسین',
 				'pam' => 'پمپانگا',
 				'pap' => 'پاپيامينتو',
 				'pau' => 'پالان',
 				'pcm' => 'نائجیریا پیدجن',
 				'pl' => 'پولنډي',
 				'prg' => 'پروشين',
 				'ps' => 'پښتو',
 				'pt' => 'پورتګالي',
 				'pt_BR' => 'برازیلي پرتګالي',
 				'pt_PT' => 'اروپايي پرتګالي',
 				'qu' => 'کېچوا',
 				'quc' => 'کچی',
 				'rap' => 'رپانوئي',
 				'rar' => 'راروټانګان',
 				'rm' => 'رومانیش',
 				'rn' => 'رونډی',
 				'ro' => 'رومانیایی',
 				'ro_MD' => 'مولداویایی',
 				'rof' => 'رومبو',
 				'root' => 'روټ',
 				'ru' => 'روسي',
 				'rup' => 'اروماني',
 				'rw' => 'کینیارونډا',
 				'rwk' => 'Rwa',
 				'sa' => 'سنسکریټ',
 				'sad' => 'سنډاوی',
 				'sah' => 'سخا',
 				'saq' => 'سمبورو',
 				'sat' => 'سنتالي',
 				'sba' => 'نګبای',
 				'sbp' => 'سانګوو',
 				'sc' => 'سارڊيني',
 				'scn' => 'سیلیسي',
 				'sco' => 'سکاټس',
 				'sd' => 'سندهي',
 				'se' => 'شمالي سامي',
 				'seh' => 'سینا',
 				'ses' => 'کوییرابورو سینی',
 				'sg' => 'سانګو',
 				'sh' => 'سرب-کروشيايي',
 				'shi' => 'تاکلهیټ',
 				'shn' => 'شان',
 				'si' => 'سينهالي',
 				'sk' => 'سلوواکي',
 				'sl' => 'سلوواني',
 				'sm' => 'ساموآن',
 				'sma' => 'سویلي سامی',
 				'smj' => 'لول سامي',
 				'smn' => 'اناري سميع',
 				'sms' => 'سکولټ سمیع',
 				'sn' => 'شونا',
 				'snk' => 'سونینګ',
 				'so' => 'سومالي',
 				'sq' => 'الباني',
 				'sr' => 'سربيائي',
 				'srn' => 'سوران ټونګو',
 				'ss' => 'سواتی',
 				'ssy' => 'سهو',
 				'st' => 'سيسوتو',
 				'su' => 'سوډاني',
 				'suk' => 'سکوما',
 				'sv' => 'سویډنی',
 				'sw' => 'سواهېلي',
 				'sw_CD' => 'کانګو سواهلی',
 				'swb' => 'کومورياني',
 				'syr' => 'سوریاني',
 				'ta' => 'تامیل',
 				'te' => 'تېليګو',
 				'tem' => 'تیمني',
 				'teo' => 'تیسو',
 				'tet' => 'تتوم',
 				'tg' => 'تاجکي',
 				'th' => 'تايلېنډي',
 				'ti' => 'تيګريني',
 				'tig' => 'تیګر',
 				'tk' => 'ترکمني',
 				'tlh' => 'کلينګاني',
 				'tn' => 'سووانا',
 				'to' => 'تونګان',
 				'tpi' => 'توک پیسین',
 				'tr' => 'ترکي',
 				'trv' => 'تاروکو',
 				'ts' => 'سونګا',
 				'tt' => 'تاتار',
 				'tum' => 'تامبوکا',
 				'tvl' => 'تووالو',
 				'tw' => 'توی',
 				'twq' => 'تساواق',
 				'ty' => 'تاهیتي',
 				'tyv' => 'توینیان',
 				'tzm' => 'مرکزی اطلس تمازائيٹ',
 				'udm' => 'ادمورت',
 				'ug' => 'اويغوري',
 				'uk' => 'اوکرانايي',
 				'umb' => 'امبوندو',
 				'und' => 'نامعلومه ژبه',
 				'ur' => 'اردو',
 				'uz' => 'اوزبکي',
 				'vai' => 'وای',
 				've' => 'ویندا',
 				'vi' => 'وېتنامي',
 				'vo' => 'والاپوک',
 				'vun' => 'وونجو',
 				'wa' => 'والون',
 				'wae' => 'ولسیر',
 				'wal' => 'ولایټا',
 				'war' => 'وارۍ',
 				'wo' => 'ولوف',
 				'xal' => 'کالمک',
 				'xh' => 'خوسا',
 				'xog' => 'سوګا',
 				'yav' => 'ینګبین',
 				'ybb' => 'یمبا',
 				'yi' => 'يديش',
 				'yo' => 'یوروبا',
 				'yue' => 'کانټوني',
 				'zgh' => 'معياري مراکش تمازټیټ',
 				'zh' => 'چیني',
 				'zh_Hans' => 'ساده چيني',
 				'zh_Hant' => 'دوديزه چيني',
 				'zu' => 'زولو',
 				'zun' => 'زوني',
 				'zxx' => 'نه ژبني منځپانګه',
 				'zza' => 'زازا',

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
			'Arab' => 'عربي',
 			'Armn' => 'ارمانیایي',
 			'Beng' => 'بنګله',
 			'Bopo' => 'بوپوموفو',
 			'Brai' => 'بریلي',
 			'Cyrl' => 'سیریلیک',
 			'Deva' => 'دیواناګري',
 			'Ethi' => 'ایتوپي',
 			'Geor' => 'ګرجستاني',
 			'Grek' => 'یوناني',
 			'Gujr' => 'ګجراتي',
 			'Guru' => 'ګرومي',
 			'Hanb' => 'هن او بوپوفومو',
 			'Hang' => 'هنګولي',
 			'Hani' => 'هن',
 			'Hans' => 'ساده شوی',
 			'Hans@alt=stand-alone' => 'ساده هان',
 			'Hant' => 'دودیزه',
 			'Hant@alt=stand-alone' => 'دودیز هان',
 			'Hebr' => 'عبراني',
 			'Hira' => 'هیراګانا',
 			'Hrkt' => 'د جاپاني سیلابري',
 			'Jamo' => 'جامو',
 			'Jpan' => 'جاپاني',
 			'Kana' => 'کاتاکانا',
 			'Khmr' => 'خمر',
 			'Knda' => 'کناډا',
 			'Kore' => 'کوریایی',
 			'Laoo' => 'لاوو',
 			'Latn' => 'لاتین',
 			'Mlym' => 'مالایالم',
 			'Mong' => 'منګولیایي',
 			'Mymr' => 'میانمار',
 			'Orya' => 'اویا',
 			'Sinh' => 'سنهالا',
 			'Taml' => 'تامیل',
 			'Telu' => 'تیلیګو',
 			'Thaa' => 'تهانا',
 			'Thai' => 'تایلنډي',
 			'Tibt' => 'تبتي',
 			'Zmth' => 'د ریاضیاتو نوټیشن',
 			'Zsye' => 'ایموجي',
 			'Zsym' => 'سمبولونه',
 			'Zxxx' => 'ناڅاپه',
 			'Zyyy' => 'عام',
 			'Zzzz' => 'نامعلومه سکرېپټ',

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
			'001' => 'نړۍ',
 			'002' => 'افريقا',
 			'003' => 'شمالی امریکا',
 			'005' => 'جنوبی امریکه',
 			'009' => 'سمندريه',
 			'011' => 'لویدیځ افریقا',
 			'013' => 'منخنۍ امريکا',
 			'014' => 'ختیځ افریقا',
 			'015' => 'شمالي افریقا',
 			'017' => 'منځنۍ افریقا',
 			'018' => 'جنوبي افریقا',
 			'019' => 'امريکا',
 			'021' => 'شمالي امریکا',
 			'029' => 'کیریبین',
 			'030' => 'ختیځ آسیا',
 			'034' => 'سهیل آسیا',
 			'035' => 'سویل ختیځ آسیا',
 			'039' => 'جنوبي اروپا',
 			'053' => 'آسترالیا',
 			'054' => 'ملانشیا',
 			'057' => 'د مایکرونیسینین سیمه',
 			'061' => 'پولینیا',
 			'142' => 'اسيا',
 			'143' => 'منځنۍ اسیا',
 			'145' => 'لویدیځ آسیا',
 			'150' => 'اروپا',
 			'151' => 'ختيځه اروپا',
 			'154' => 'شمالي اروپا',
 			'155' => 'لویدیځه اروپا',
 			'202' => 'د افریقا جنوب-صحرا',
 			'419' => 'لاتیني امریکا',
 			'AC' => 'د توغندیو ټاپو',
 			'AD' => 'اندورا',
 			'AE' => 'متحده عرب امارات',
 			'AF' => 'افغانستان',
 			'AG' => 'انټيګوا او باربودا',
 			'AI' => 'انګیلا',
 			'AL' => 'البانیه',
 			'AM' => 'ارمنستان',
 			'AO' => 'انګولا',
 			'AQ' => 'انتارکتیکا',
 			'AR' => 'ارژنټاین',
 			'AS' => 'امریکایی سمو',
 			'AT' => 'اتریش',
 			'AU' => 'آسټرالیا',
 			'AW' => 'آروبا',
 			'AX' => 'الاند ټاپوان',
 			'AZ' => 'اذربايجان',
 			'BA' => 'بوسنيا او هېرزګوينا',
 			'BB' => 'باربادوس',
 			'BD' => 'بنگله دېش',
 			'BE' => 'بیلجیم',
 			'BF' => 'بورکینا فاسو',
 			'BG' => 'بلغاریه',
 			'BH' => 'بحرين',
 			'BI' => 'بروندي',
 			'BJ' => 'بینن',
 			'BL' => 'سینټ بارټیلیټی',
 			'BM' => 'برمودا',
 			'BN' => 'بروني',
 			'BO' => 'بولیویا',
 			'BQ' => 'کیریبین هالینډ',
 			'BR' => 'برازیل',
 			'BS' => 'باهاما',
 			'BT' => 'بهوټان',
 			'BV' => 'بوویټ ټاپو',
 			'BW' => 'بوتسوانه',
 			'BY' => 'بیلاروس',
 			'BZ' => 'بلیز',
 			'CA' => 'کاناډا',
 			'CC' => 'کوکوز (کیبل) ټاپوګانې',
 			'CD' => 'کانګو - کینشاسا',
 			'CD@alt=variant' => 'کانګو (DRC)',
 			'CF' => 'د مرکزي افریقا جمهوریت',
 			'CG' => 'کانګو - بروزوییل',
 			'CG@alt=variant' => 'کانګو (جمهوریه)',
 			'CH' => 'سویس',
 			'CI' => 'د عاج ساحل',
 			'CI@alt=variant' => 'ایوري ساحل',
 			'CK' => 'کوک ټاپوګان',
 			'CL' => 'چیلي',
 			'CM' => 'کامرون',
 			'CN' => 'چین',
 			'CO' => 'کولمبیا',
 			'CP' => 'د کلپرټون ټاپو',
 			'CR' => 'کوستاریکا',
 			'CU' => 'کیوبا',
 			'CV' => 'کیپ ورد',
 			'CW' => 'کوکوکا',
 			'CX' => 'د کریساس ټاپو',
 			'CY' => 'قبرس',
 			'CZ' => 'چکیا',
 			'CZ@alt=variant' => 'چک جمهوريت',
 			'DE' => 'المان',
 			'DG' => 'ډایګو ګارسیا',
 			'DJ' => 'جی بوتي',
 			'DK' => 'ډنمارک',
 			'DM' => 'دومینیکا',
 			'DO' => 'دومینیکن جمهوريت',
 			'DZ' => 'الجزایر',
 			'EA' => 'سئوتا او مالایا',
 			'EC' => 'اکوادور',
 			'EE' => 'استونیا',
 			'EG' => 'مصر',
 			'EH' => 'لویدیځ صحرا',
 			'ER' => 'اریتره',
 			'ES' => 'هسپانیه',
 			'ET' => 'حبشه',
 			'EU' => 'اروپايي اتحاديه',
 			'EZ' => 'اروپاسيمه',
 			'FI' => 'فنلینډ',
 			'FJ' => 'في جي',
 			'FK' => 'فوکلنډ ټاپو',
 			'FK@alt=variant' => 'فاکلینډ ټاپو (آساس مالوناس)',
 			'FM' => 'میکرونیزیا',
 			'FO' => 'فارو ټاپو',
 			'FR' => 'فرانسه',
 			'GA' => 'ګابن',
 			'GB' => 'برتانیه',
 			'GB@alt=short' => 'انګلستان',
 			'GD' => 'ګرنادا',
 			'GE' => 'گورجستان',
 			'GF' => 'فرانسوي ګانا',
 			'GG' => 'ګرنسي',
 			'GH' => 'ګانا',
 			'GI' => 'جبل الطارق',
 			'GL' => 'ګرینلینډ',
 			'GM' => 'ګامبیا',
 			'GN' => 'ګینه',
 			'GP' => 'ګالډیپ',
 			'GQ' => 'استوایی ګینه',
 			'GR' => 'یونان',
 			'GS' => 'سویل جورجیا او جنوبي سینڈوچ ټاپو',
 			'GT' => 'ګواتیمالا',
 			'GU' => 'ګوام',
 			'GW' => 'ګینه بیسو',
 			'GY' => 'ګیانا',
 			'HK' => 'هانګ کانګ SAR چین',
 			'HK@alt=short' => 'هانګ کانګ',
 			'HM' => 'HM',
 			'HN' => 'هانډوراس',
 			'HR' => 'کرواثیا',
 			'HT' => 'هایټي',
 			'HU' => 'مجارستان',
 			'IC' => 'د کانري ټاپو',
 			'ID' => 'اندونیزیا',
 			'IE' => 'ایرلینډ',
 			'IL' => 'اسراييل',
 			'IM' => 'د آئل آف مین',
 			'IN' => 'هند',
 			'IO' => 'د هند سمندر سمندر سیمه',
 			'IQ' => 'عراق',
 			'IR' => 'ايران',
 			'IS' => 'آیسلینډ',
 			'IT' => 'ایټالیه',
 			'JE' => 'جرسی',
 			'JM' => 'جمیکا',
 			'JO' => 'اردن',
 			'JP' => 'جاپان',
 			'KE' => 'کینیا',
 			'KG' => 'قرغزستان',
 			'KH' => 'کمبودیا',
 			'KI' => 'کیري باتي',
 			'KM' => 'کوموروس',
 			'KN' => 'سینټ کټس او نیویس',
 			'KP' => 'شمالی کوریا',
 			'KR' => 'سویلي کوریا',
 			'KW' => 'کویټ',
 			'KY' => 'کیمان ټاپوګان',
 			'KZ' => 'قزاقستان',
 			'LA' => 'لاووس',
 			'LB' => 'لېبنان',
 			'LC' => 'سینټ لوسیا',
 			'LI' => 'لیختن اشتاین',
 			'LK' => 'سريلانکا',
 			'LR' => 'لایبریا',
 			'LS' => 'لسوتو',
 			'LT' => 'لیتوانیا',
 			'LU' => 'لوګزامبورګ',
 			'LV' => 'لتوني',
 			'LY' => 'لیبیا',
 			'MA' => 'مراکش',
 			'MC' => 'موناکو',
 			'MD' => 'مولدوا',
 			'ME' => 'مونټینیګرو',
 			'MF' => 'سینټ مارټن',
 			'MG' => 'مدګاسکار',
 			'MH' => 'مارشال ټاپو',
 			'MK' => 'مقدونیه',
 			'MK@alt=variant' => 'مقدونیه (FYROM)',
 			'ML' => 'مالي',
 			'MM' => 'ميانامار (برما)',
 			'MN' => 'مغولستان',
 			'MO' => 'مکا سار چین',
 			'MO@alt=short' => 'ماکو',
 			'MP' => 'شمالي ماریانا ټاپو',
 			'MQ' => 'مارټینیک',
 			'MR' => 'موریتانیا',
 			'MS' => 'مانټیسیرت',
 			'MT' => 'مالتا',
 			'MU' => 'موریشیس',
 			'MV' => 'مالديپ',
 			'MW' => 'مالاوي',
 			'MX' => 'میکسیکو',
 			'MY' => 'مالیزیا',
 			'MZ' => 'موزمبیک',
 			'NA' => 'نیمبیا',
 			'NC' => 'نوی کالیډونیا',
 			'NE' => 'نیجر',
 			'NF' => 'نارفولک ټاپوګان',
 			'NG' => 'نایجیریا',
 			'NI' => 'نکاراګوا',
 			'NL' => 'هالېنډ',
 			'NO' => 'ناروۍ',
 			'NP' => 'نیپال',
 			'NR' => 'نایرو',
 			'NU' => 'نیوو',
 			'NZ' => 'نیوزیلنډ',
 			'OM' => 'عمان',
 			'PA' => 'پاناما',
 			'PE' => 'پیرو',
 			'PF' => 'فرانسوي پولینیا',
 			'PG' => 'پاپ نيو ګيني، د يو هېواد نوم دې',
 			'PH' => 'فلپين',
 			'PK' => 'پاکستان',
 			'PL' => 'پولنډ',
 			'PM' => 'سینټ پییر او میکولون',
 			'PN' => 'پیټکیرن ټاپو',
 			'PR' => 'پورتو ریکو',
 			'PS' => 'فلسطين سيمې',
 			'PS@alt=short' => 'فلسطين',
 			'PT' => 'پورتګال',
 			'PW' => 'پلو',
 			'PY' => 'پاراګوی',
 			'QA' => 'قطر',
 			'QO' => 'بهرنی آسیا',
 			'RE' => 'ریونین',
 			'RO' => 'رومانیا',
 			'RS' => 'صربیا',
 			'RU' => 'روسیه',
 			'RW' => 'روندا',
 			'SA' => 'سعودي عربستان',
 			'SB' => 'سلیمان ټاپو',
 			'SC' => 'سیچیلیس',
 			'SD' => 'سوډان',
 			'SE' => 'سویډن',
 			'SG' => 'سينگاپور',
 			'SH' => 'سینټ هیلینا',
 			'SI' => 'سلوانیا',
 			'SJ' => 'سلواډر او جان میین',
 			'SK' => 'سلواکیا',
 			'SL' => 'سییرا لیون',
 			'SM' => 'سان مارینو',
 			'SN' => 'سنګال',
 			'SO' => 'سومالیا',
 			'SR' => 'سورینام',
 			'SS' => 'جنوبي سوډان',
 			'ST' => 'ساو ټیم او پرنسیپ',
 			'SV' => 'سالوېډور',
 			'SX' => 'سینټ مارټین',
 			'SY' => 'سوریه',
 			'SZ' => 'سوازیلینډ',
 			'TA' => 'تریستان دا کنها',
 			'TC' => 'د ترکیې او کیکاسو ټاپو',
 			'TD' => 'چاډ',
 			'TF' => 'د فرانسې جنوبي سیمې',
 			'TG' => 'تلل',
 			'TH' => 'تهايلنډ',
 			'TJ' => 'تاجيکستان',
 			'TK' => 'توکیلو',
 			'TL' => 'تيمور-ليسټ',
 			'TL@alt=variant' => 'ختيځ تيمور',
 			'TM' => 'تورکمنستان',
 			'TN' => 'تونس',
 			'TO' => 'تونګا',
 			'TR' => 'تورکيه',
 			'TT' => 'ټرینیاډډ او ټوبوګ',
 			'TV' => 'توالیو',
 			'TW' => 'تیوان',
 			'TZ' => 'تنزانیا',
 			'UA' => 'اوکراین',
 			'UG' => 'یوګانډا',
 			'UM' => 'د متحده ایالاتو ټاپو ټاپوګانې',
 			'UN' => 'ملگري ملتونه',
 			'US' => 'متحده ایالات',
 			'US@alt=short' => 'متحده ایالات',
 			'UY' => 'یوروګوی',
 			'UZ' => 'اوزبکستان',
 			'VA' => 'واتیکان ښار',
 			'VC' => 'سینټ ویسنټینټ او ګرینډینز',
 			'VE' => 'وینزویلا',
 			'VG' => 'بریتانوی ویګور ټاپو',
 			'VI' => 'د متحده ایالاتو ویګور ټاپو',
 			'VN' => 'وېتنام',
 			'VU' => 'واناتو',
 			'WF' => 'والیس او فوتونا',
 			'WS' => 'ساموا',
 			'XK' => 'کوسوو',
 			'YE' => 'یمن',
 			'YT' => 'میټوت',
 			'ZA' => 'سویلي افریقا',
 			'ZM' => 'زیمبیا',
 			'ZW' => 'زیمبابوی',
 			'ZZ' => 'ناپېژندلې سيمه',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'جنتري',
 			'cf' => 'اسعارو بڼه',
 			'collation' => 'ترتيب',
 			'currency' => 'اسعارو',
 			'hc' => 'hc',
 			'lb' => 'lb',
 			'ms' => 'ms',
 			'numbers' => 'numbers',

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
 				'buddhist' => q{بودايي جنتري},
 				'chinese' => q{د چين جنتري},
 				'dangi' => q{ډانګي جنتري},
 				'ethiopic' => q{ایتوپيک جنتري},
 				'gregorian' => q{د ګریګوریا کښته},
 				'hebrew' => q{جورجویان جنتري},
 				'islamic' => q{د اسلامي جنتري},
 				'islamic-civil' => q{د اسلامي جنتري (جدولي، د مدني عصر)},
 				'islamic-tbla' => q{د اسلامي جنتري (جدولي، ستورپوهنيزه برخه)},
 				'iso8601' => q{ISO-8601 Calendar},
 				'japanese' => q{د جاپاني جنتري},
 				'persian' => q{د فارسي جنتري},
 				'roc' => q{منگوو جنتري},
 			},
 			'cf' => {
 				'account' => q{محاسبه اسعارو بڼه},
 				'standard' => q{معياري اسعارو بڼه},
 			},
 			'collation' => {
 				'ducet' => q{ڊفالٽ یونیکوډ ترتیب},
 				'search' => q{عمومي موخو د لټون},
 				'standard' => q{معیاري ترتیب ترتیب},
 			},
 			'hc' => {
 				'h11' => q{h11},
 				'h12' => q{h12},
 				'h23' => q{h23},
 				'h24' => q{h24},
 			},
 			'lb' => {
 				'loose' => q{loose},
 				'normal' => q{normal},
 				'strict' => q{strict},
 			},
 			'ms' => {
 				'metric' => q{metric},
 				'uksystem' => q{uksystem},
 				'ussystem' => q{ussystem},
 			},
 			'numbers' => {
 				'arab' => q{عربي - انډیک ډایټونه},
 				'arabext' => q{پراخ شوی عربي - هندیک ډایټونه},
 				'armn' => q{armn},
 				'armnlow' => q{armnlow},
 				'beng' => q{beng},
 				'deva' => q{deva},
 				'ethi' => q{ethi},
 				'fullwide' => q{fullwide},
 				'geor' => q{geor},
 				'grek' => q{grek},
 				'greklow' => q{greklow},
 				'gujr' => q{gujr},
 				'guru' => q{guru},
 				'hanidec' => q{hanidec},
 				'hans' => q{hans},
 				'hansfin' => q{hansfin},
 				'hant' => q{hant},
 				'hantfin' => q{hantfin},
 				'hebr' => q{hebr},
 				'jpan' => q{jpan},
 				'jpanfin' => q{jpanfin},
 				'khmr' => q{khmr},
 				'knda' => q{knda},
 				'laoo' => q{laoo},
 				'latn' => q{لویدیځ ډایټونه},
 				'mlym' => q{mlym},
 				'mymr' => q{mymr},
 				'orya' => q{orya},
 				'roman' => q{roman},
 				'romanlow' => q{romanlow},
 				'taml' => q{taml},
 				'tamldec' => q{tamldec},
 				'telu' => q{telu},
 				'thai' => q{thai},
 				'tibt' => q{tibt},
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
			'metric' => q{مېټرک},
 			'UK' => q{بريتاني},
 			'US' => q{امريکايي},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'ژبه: {0}',
 			'script' => 'سکرېپټ: {0}',
 			'region' => 'سيمه: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => '',
			characters => 'right-to-left',
		}}
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
			auxiliary => qr{[‌ ‍ ‎‏]},
			index => ['آ', 'ا', 'ء', 'ب', 'پ', 'ت', 'ټ', 'ث', 'ج', 'ځ', 'چ', 'څ', 'ح', 'خ', 'د', 'ډ', 'ذ', 'ر', 'ړ', 'ز', 'ژ', 'ږ', 'س', 'ش', 'ښ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'ګ', 'ل', 'م', 'ن', 'ڼ', 'ه', 'و', 'ی'],
			main => qr{[َ ِ ُ ً ٍ ٌ ّ ْ ٔ ٰ آ ا أ ء ب پ ت ټ ث ج ځ چ څ ح خ د ډ ذ ر ړ ز ژ ږ س ش ښ ص ض ط ظ ع غ ف ق ک ګ گ ل م ن ڼ ه ة و ؤ ی ي ې ۍ ئ]},
			numbers => qr{[‎ \- , ٫ ٬ . % ٪ ‰ ؉ + − 0۰ 1۱ 2۲ 3۳ 4۴ 5۵ 6۶ 7۷ 8۸ 9۹]},
		};
	},
EOT
: sub {
		return { index => ['آ', 'ا', 'ء', 'ب', 'پ', 'ت', 'ټ', 'ث', 'ج', 'ځ', 'چ', 'څ', 'ح', 'خ', 'د', 'ډ', 'ذ', 'ر', 'ړ', 'ز', 'ژ', 'ږ', 'س', 'ش', 'ښ', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ک', 'ګ', 'ل', 'م', 'ن', 'ڼ', 'ه', 'و', 'ی'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
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
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					'arc-minute' => {
						'name' => q(آرشیف),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(آرکیسیفسونه),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(astronomical units),
						'one' => q({0} astronomical unit),
						'other' => q({0} astronomical units),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					'calorie' => {
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					'carat' => {
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					'celsius' => {
						'name' => q(degrees Celsius),
						'one' => q({0} degree Celsius),
						'other' => q({0} degrees Celsius),
					},
					'centiliter' => {
						'name' => q(centiliters),
						'one' => q({0} centiliter),
						'other' => q({0} centiliters),
					},
					'centimeter' => {
						'name' => q(centimeters),
						'one' => q({0} centimeter),
						'other' => q({0} centimeters),
						'per' => q({0} per centimeter),
					},
					'century' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'coordinate' => {
						'east' => q({0} ختيځ),
						'north' => q({0} شمال),
						'south' => q({0} جنوب),
						'west' => q({0} لوېديځ),
					},
					'cubic-centimeter' => {
						'name' => q(cubic centimeters),
						'one' => q({0} cubic centimeter),
						'other' => q({0} cubic centimeters),
						'per' => q({0} per cubic centimeter),
					},
					'cubic-foot' => {
						'name' => q(cubic feet),
						'one' => q({0} cubic foot),
						'other' => q({0} cubic feet),
					},
					'cubic-inch' => {
						'name' => q(cubic inches),
						'one' => q({0} cubic inch),
						'other' => q({0} cubic inches),
					},
					'cubic-kilometer' => {
						'name' => q(cubic kilometers),
						'one' => q({0} cubic kilometer),
						'other' => q({0} cubic kilometers),
					},
					'cubic-meter' => {
						'name' => q(cubic meters),
						'one' => q({0} cubic meter),
						'other' => q({0} cubic meters),
						'per' => q({0} per cubic meter),
					},
					'cubic-mile' => {
						'name' => q(cubic miles),
						'one' => q({0} cubic mile),
						'other' => q({0} cubic miles),
					},
					'cubic-yard' => {
						'name' => q(cubic yards),
						'one' => q({0} cubic yard),
						'other' => q({0} cubic yards),
					},
					'cup' => {
						'name' => q(cups),
						'one' => q({0} cup),
						'other' => q({0} cups),
					},
					'cup-metric' => {
						'name' => q(metric cups),
						'one' => q({0} metric cup),
						'other' => q({0} metric cups),
					},
					'day' => {
						'name' => q(ورځې),
						'one' => q({0} ورځ),
						'other' => q({0} ورځې),
						'per' => q({0} په هره ورځ کې),
					},
					'deciliter' => {
						'name' => q(deciliters),
						'one' => q({0} deciliter),
						'other' => q({0} deciliters),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} decimeter),
						'other' => q({0} decimeters),
					},
					'degree' => {
						'name' => q(درجو),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(degrees Fahrenheit),
						'one' => q({0} degree Fahrenheit),
						'other' => q({0} degrees Fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
					},
					'foodcalorie' => {
						'name' => q(Calories),
						'one' => q({0} Calorie),
						'other' => q({0} Calories),
					},
					'foot' => {
						'name' => q(feet),
						'one' => q({0} foot),
						'other' => q({0} feet),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					'gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} per gallon),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gallons),
						'one' => q({0} Imp. gallon),
						'other' => q({0} Imp. gallons),
						'per' => q({0} per Imp. gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					'gram' => {
						'name' => q(grams),
						'one' => q({0} gram),
						'other' => q({0} grams),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					'hectoliter' => {
						'name' => q(hectoliters),
						'one' => q({0} hectoliter),
						'other' => q({0} hectoliters),
					},
					'hectopascal' => {
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(horsepower),
						'one' => q({0} horsepower),
						'other' => q({0} horsepower),
					},
					'hour' => {
						'name' => q(hr),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(inches),
						'one' => q({0} inch),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					'inch-hg' => {
						'name' => q(inches of mercury),
						'one' => q({0} inch of mercury),
						'other' => q({0} inches of mercury),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(کارات),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					'kilocalorie' => {
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					'kilogram' => {
						'name' => q(kilograms),
						'one' => q({0} kilogram),
						'other' => q({0} kilograms),
						'per' => q({0} per kilogram),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					'kilometer' => {
						'name' => q(کيلومترونه),
						'one' => q({0} کيلومتر),
						'other' => q({0} کيلومتره),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometers per hour),
						'one' => q({0} kilometer per hour),
						'other' => q({0} kilometers per hour),
					},
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatt-hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} kilowatt-hours),
					},
					'knot' => {
						'name' => q(knots),
						'one' => q({0} knot),
						'other' => q({0} knots),
					},
					'light-year' => {
						'name' => q(light years),
						'one' => q({0} light year),
						'other' => q({0} light years),
					},
					'liter' => {
						'name' => q(liters),
						'one' => q({0} liter),
						'other' => q({0} liters),
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megaliters),
						'one' => q({0} megaliter),
						'other' => q({0} megaliters),
					},
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					'meter' => {
						'name' => q(متر),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(meters per second),
						'one' => q({0} meter per second),
						'other' => q({0} meters per second),
					},
					'meter-per-second-squared' => {
						'name' => q(meters per second squared),
						'one' => q({0} meter per second squared),
						'other' => q({0} meters per second squared),
					},
					'metric-ton' => {
						'name' => q(metric tons),
						'one' => q({0} metric ton),
						'other' => q({0} metric tons),
					},
					'microgram' => {
						'name' => q(micrograms),
						'one' => q({0} microgram),
						'other' => q({0} micrograms),
					},
					'micrometer' => {
						'name' => q(micrometers),
						'one' => q({0} micrometer),
						'other' => q({0} micrometers),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					'mile-per-gallon' => {
						'name' => q(mpg US),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(miles per hour),
						'one' => q({0} mile per hour),
						'other' => q({0} miles per hour),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(milliamperes),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperes),
					},
					'millibar' => {
						'name' => q(millibars),
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					'milligram' => {
						'name' => q(milligrams),
						'one' => q({0} milligram),
						'other' => q({0} milligrams),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(milliliters),
						'one' => q({0} milliliter),
						'other' => q({0} milliliters),
					},
					'millimeter' => {
						'name' => q(millimeters),
						'one' => q({0} millimeter),
						'other' => q({0} millimeters),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeters of mercury),
						'one' => q({0} millimeter of mercury),
						'other' => q({0} millimeters of mercury),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(مياشتې),
						'one' => q({0} مياشت),
						'other' => q({0} مياشتې),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nanometers),
						'one' => q({0} nanometer),
						'other' => q({0} nanometers),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					'ounce' => {
						'name' => q(ounces),
						'one' => q({0} ounce),
						'other' => q({0} ounces),
						'per' => q({0} per ounce),
					},
					'ounce-troy' => {
						'name' => q(troy ounces),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounces),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(picometers),
						'one' => q({0} picometer),
						'other' => q({0} picometers),
					},
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					'pint-metric' => {
						'name' => q(metric pints),
						'one' => q({0} metric pint),
						'other' => q({0} metric pints),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(pounds),
						'one' => q({0} pound),
						'other' => q({0} pounds),
						'per' => q({0} per pound),
					},
					'pound-per-square-inch' => {
						'name' => q(pounds per square inch),
						'one' => q({0} pound per square inch),
						'other' => q({0} pounds per square inch),
					},
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					'radian' => {
						'name' => q(رادیان),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(انقلاب),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(square centimeters),
						'one' => q({0} square centimeter),
						'other' => q({0} square centimeters),
						'per' => q({0} per square centimeter),
					},
					'square-foot' => {
						'name' => q(square feet),
						'one' => q({0} square foot),
						'other' => q({0} square feet),
					},
					'square-inch' => {
						'name' => q(square inches),
						'one' => q({0} square inch),
						'other' => q({0} square inches),
						'per' => q({0} per square inch),
					},
					'square-kilometer' => {
						'name' => q(square kilometers),
						'one' => q({0} square kilometer),
						'other' => q({0} square kilometers),
						'per' => q({0} per square kilometer),
					},
					'square-meter' => {
						'name' => q(square meters),
						'one' => q({0} square meter),
						'other' => q({0} square meters),
						'per' => q({0} per square meter),
					},
					'square-mile' => {
						'name' => q(square miles),
						'one' => q({0} square mile),
						'other' => q({0} square miles),
						'per' => q({0} per square mile),
					},
					'square-yard' => {
						'name' => q(square yards),
						'one' => q({0} square yard),
						'other' => q({0} square yards),
					},
					'tablespoon' => {
						'name' => q(tablespoons),
						'one' => q({0} tablespoon),
						'other' => q({0} tablespoons),
					},
					'teaspoon' => {
						'name' => q(teaspoons),
						'one' => q({0} teaspoon),
						'other' => q({0} teaspoons),
					},
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					'ton' => {
						'name' => q(tons),
						'one' => q({0} ton),
						'other' => q({0} tons),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					'week' => {
						'name' => q(اونۍ),
						'one' => q(اونۍ),
						'other' => q({0} اونۍ),
						'per' => q({0} په هره اونۍ کې),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					'year' => {
						'name' => q(کالونه),
						'one' => q({0} کال),
						'other' => q({0} کالونه),
						'per' => q({0} په هر کال کې),
					},
				},
				'narrow' => {
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'coordinate' => {
						'east' => q({0}خ),
						'north' => q({0}ش),
						'south' => q({0}ج),
						'west' => q({0}ل),
					},
					'day' => {
						'name' => q(ورځ),
						'one' => q({0} ورځ),
						'other' => q({0} ورځې),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hour' => {
						'name' => q(hr),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0}kph),
						'other' => q({0}kph),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(مياشت),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'week' => {
						'name' => q(اونۍ),
						'one' => q({0} w),
						'other' => q({0} w),
					},
					'year' => {
						'name' => q(yr),
						'one' => q({0} y),
						'other' => q({0} y),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(acre ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amps),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(آرکسیسیس),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(آرکیسی),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(carats),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(deg. C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'coordinate' => {
						'east' => q({0} خ),
						'north' => q({0} ش),
						'south' => q({0} ج),
						'west' => q({0} ل),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(feet³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(inches³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yards³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cups),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(ورځې),
						'one' => q({0} ورځ),
						'other' => q({0} ورځې),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(درجو),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(deg. F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(feet),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal US),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GByte),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(grams),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(hr),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(inches),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(کارات),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kByte),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/hour),
						'one' => q({0} kph),
						'other' => q({0} kph),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kW-hour),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(light yrs),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(liters),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MByte),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(meters/sec),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(meters/sec²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmeters),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(miles),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg US),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(miles/hour),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(milliamps),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(مياشتې),
						'one' => q({0} m),
						'other' => q({0} mths),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz troy),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(pounds),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qts),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(رادیان),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(sq feet),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					'square-inch' => {
						'name' => q(inches²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(meters²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(sq miles),
						'one' => q({0} sq mi),
						'other' => q({0} sq mi),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yards²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TByte),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tons),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(اونۍ),
						'one' => q({0} w),
						'other' => q({0} wks),
						'per' => q({0}/w),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(کالونه),
						'one' => q({0} y),
						'other' => q({0} y),
						'per' => q({0}/y),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0} او {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arabext',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arabext',
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
		'arabext' => {
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'infinity' => q(∞),
			'minusSign' => q(‎-‎),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+‎),
			'superscriptingExponent' => q(×),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'minusSign' => q(‎−),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(‎+),
			'superscriptingExponent' => q(×),
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
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000B',
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
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000B',
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
		'arabext' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00 ¤',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
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
			symbol => 'AED',
			display_name => {
				'currency' => q(AED),
				'one' => q(AED),
				'other' => q(AED),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(افغانۍ \(1927–2002\)),
				'one' => q(افغانۍ \(1927–2002\)),
				'other' => q(افغانۍ \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => '؋',
			display_name => {
				'currency' => q(افغانۍ),
				'one' => q(افغانۍ),
				'other' => q(افغانۍ),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(ALL),
				'one' => q(ALL),
				'other' => q(ALL),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(AMD),
				'one' => q(AMD),
				'other' => q(AMD),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(ANG),
				'one' => q(ANG),
				'other' => q(ANG),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(AOA),
				'one' => q(AOA),
				'other' => q(AOA),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(ARS),
				'one' => q(ARS),
				'other' => q(ARS),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(AUD),
				'one' => q(AUD),
				'other' => q(AUD),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(AWG),
				'one' => q(AWG),
				'other' => q(AWG),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(AZN),
				'one' => q(AZN),
				'other' => q(AZN),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(BAM),
				'one' => q(BAM),
				'other' => q(BAM),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(BBD),
				'one' => q(BBD),
				'other' => q(BBD),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(BDT),
				'one' => q(BDT),
				'other' => q(BDT),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(BGN),
				'one' => q(BGN),
				'other' => q(BGN),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(BHD),
				'one' => q(BHD),
				'other' => q(BHD),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(BIF),
				'one' => q(BIF),
				'other' => q(BIF),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(BMD),
				'one' => q(BMD),
				'other' => q(BMD),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(BND),
				'one' => q(BND),
				'other' => q(BND),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(BOB),
				'one' => q(BOB),
				'other' => q(BOB),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(BRL),
				'one' => q(BRL),
				'other' => q(BRL),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(BSD),
				'one' => q(BSD),
				'other' => q(BSD),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(BTN),
				'one' => q(BTN),
				'other' => q(BTN),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(BWP),
				'one' => q(BWP),
				'other' => q(BWP),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(BYN),
				'one' => q(BYN),
				'other' => q(BYN),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(BZD),
				'one' => q(BZD),
				'other' => q(BZD),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(CAD),
				'one' => q(CAD),
				'other' => q(CAD),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(CDF),
				'one' => q(CDF),
				'other' => q(CDF),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(CHF),
				'one' => q(CHF),
				'other' => q(CHF),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(CLP),
				'one' => q(CLP),
				'other' => q(CLP),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(CNH),
				'one' => q(CNH),
				'other' => q(CNH),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(CNY),
				'one' => q(CNY),
				'other' => q(CNY),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(COP),
				'one' => q(COP),
				'other' => q(COP),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(CRC),
				'one' => q(CRC),
				'other' => q(CRC),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(CUC),
				'one' => q(CUC),
				'other' => q(CUC),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(CUP),
				'one' => q(CUP),
				'other' => q(CUP),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(CVE),
				'one' => q(CVE),
				'other' => q(CVE),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(CZK),
				'one' => q(CZK),
				'other' => q(CZK),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(DJF),
				'one' => q(DJF),
				'other' => q(DJF),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(DKK),
				'one' => q(DKK),
				'other' => q(DKK),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(DOP),
				'one' => q(DOP),
				'other' => q(DOP),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(DZD),
				'one' => q(DZD),
				'other' => q(DZD),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(EGP),
				'one' => q(EGP),
				'other' => q(EGP),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(ERN),
				'one' => q(ERN),
				'other' => q(ERN),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(ETB),
				'one' => q(ETB),
				'other' => q(ETB),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(EUR),
				'one' => q(EUR),
				'other' => q(EUR),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(FJD),
				'one' => q(FJD),
				'other' => q(FJD),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(FKP),
				'one' => q(FKP),
				'other' => q(FKP),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(GBP),
				'one' => q(GBP),
				'other' => q(GBP),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(GEL),
				'one' => q(GEL),
				'other' => q(GEL),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(GHS),
				'one' => q(GHS),
				'other' => q(GHS),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(GIP),
				'one' => q(GIP),
				'other' => q(GIP),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(GMD),
				'one' => q(GMD),
				'other' => q(GMD),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(GNF),
				'one' => q(GNF),
				'other' => q(GNF),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(GTQ),
				'one' => q(GTQ),
				'other' => q(GTQ),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(GYD),
				'one' => q(GYD),
				'other' => q(GYD),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(HKD),
				'one' => q(HKD),
				'other' => q(HKD),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(HNL),
				'one' => q(HNL),
				'other' => q(HNL),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(HRK),
				'one' => q(HRK),
				'other' => q(HRK),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(HTG),
				'one' => q(HTG),
				'other' => q(HTG),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(HUF),
				'one' => q(HUF),
				'other' => q(HUF),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(IDR),
				'one' => q(IDR),
				'other' => q(IDR),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(ILS),
				'one' => q(ILS),
				'other' => q(ILS),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(INR),
				'one' => q(INR),
				'other' => q(INR),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(IQD),
				'one' => q(IQD),
				'other' => q(IQD),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(IRR),
				'one' => q(IRR),
				'other' => q(IRR),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(ISK),
				'one' => q(ISK),
				'other' => q(ISK),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(JMD),
				'one' => q(JMD),
				'other' => q(JMD),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(JOD),
				'one' => q(JOD),
				'other' => q(JOD),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(JPY),
				'one' => q(JPY),
				'other' => q(JPY),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(KES),
				'one' => q(KES),
				'other' => q(KES),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(KGS),
				'one' => q(KGS),
				'other' => q(KGS),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(KHR),
				'one' => q(KHR),
				'other' => q(KHR),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(KMF),
				'one' => q(KMF),
				'other' => q(KMF),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(KPW),
				'one' => q(KPW),
				'other' => q(KPW),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(KRW),
				'one' => q(KRW),
				'other' => q(KRW),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(KWD),
				'one' => q(KWD),
				'other' => q(KWD),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(KYD),
				'one' => q(KYD),
				'other' => q(KYD),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(KZT),
				'one' => q(KZT),
				'other' => q(KZT),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(LAK),
				'one' => q(LAK),
				'other' => q(LAK),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(LBP),
				'one' => q(LBP),
				'other' => q(LBP),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(LKR),
				'one' => q(LKR),
				'other' => q(LKR),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(LRD),
				'one' => q(LRD),
				'other' => q(LRD),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(LYD),
				'one' => q(LYD),
				'other' => q(LYD),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(MAD),
				'one' => q(MAD),
				'other' => q(MAD),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(MDL),
				'one' => q(MDL),
				'other' => q(MDL),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(MGA),
				'one' => q(MGA),
				'other' => q(MGA),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(MKD),
				'one' => q(MKD),
				'other' => q(MKD),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(MMK),
				'one' => q(MMK),
				'other' => q(MMK),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(MNT),
				'one' => q(MNT),
				'other' => q(MNT),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(MOP),
				'one' => q(MOP),
				'other' => q(MOP),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(MRO),
				'one' => q(MRO),
				'other' => q(MRO),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(MRU),
				'one' => q(MRU),
				'other' => q(MRU),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(MUR),
				'one' => q(MUR),
				'other' => q(MUR),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(MVR),
				'one' => q(MVR),
				'other' => q(MVR),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(MWK),
				'one' => q(MWK),
				'other' => q(MWK),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(MXN),
				'one' => q(MXN),
				'other' => q(MXN),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(MYR),
				'one' => q(MYR),
				'other' => q(MYR),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(MZN),
				'one' => q(MZN),
				'other' => q(MZN),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(NAD),
				'one' => q(NAD),
				'other' => q(NAD),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(NGN),
				'one' => q(NGN),
				'other' => q(NGN),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(NIO),
				'one' => q(NIO),
				'other' => q(NIO),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(NOK),
				'one' => q(NOK),
				'other' => q(NOK),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(نيپالي روپيه),
				'one' => q(نيپالي روپيه),
				'other' => q(نيپالي روپۍ),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(NZD),
				'one' => q(NZD),
				'other' => q(NZD),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(OMR),
				'one' => q(OMR),
				'other' => q(OMR),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(PAB),
				'one' => q(PAB),
				'other' => q(PAB),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(PEN),
				'one' => q(PEN),
				'other' => q(PEN),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(PGK),
				'one' => q(PGK),
				'other' => q(PGK),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(PHP),
				'one' => q(PHP),
				'other' => q(PHP),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(پاکستانۍ کلداره),
				'one' => q(پاکستانۍ کلداره),
				'other' => q(پاکستانۍ کلدارې),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(PLN),
				'one' => q(PLN),
				'other' => q(PLN),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(PYG),
				'one' => q(PYG),
				'other' => q(PYG),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(QAR),
				'one' => q(QAR),
				'other' => q(QAR),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(RON),
				'one' => q(RON),
				'other' => q(RON),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(RSD),
				'one' => q(RSD),
				'other' => q(RSD),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(RUB),
				'one' => q(RUB),
				'other' => q(RUB),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(RWF),
				'one' => q(RWF),
				'other' => q(RWF),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(SAR),
				'one' => q(SAR),
				'other' => q(SAR),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(SBD),
				'one' => q(SBD),
				'other' => q(SBD),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(SCR),
				'one' => q(SCR),
				'other' => q(SCR),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(SDG),
				'one' => q(SDG),
				'other' => q(SDG),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(SEK),
				'one' => q(SEK),
				'other' => q(SEK),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(SGD),
				'one' => q(SGD),
				'other' => q(SGD),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(SHP),
				'one' => q(SHP),
				'other' => q(SHP),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(SLL),
				'one' => q(SLL),
				'other' => q(SLL),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(SOS),
				'one' => q(SOS),
				'other' => q(SOS),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(SRD),
				'one' => q(SRD),
				'other' => q(SRD),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(SSP),
				'one' => q(SSP),
				'other' => q(SSP),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(STD),
				'one' => q(STD),
				'other' => q(STD),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(STN),
				'one' => q(STN),
				'other' => q(STN),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(SYP),
				'one' => q(SYP),
				'other' => q(SYP),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(SZL),
				'one' => q(SZL),
				'other' => q(SZL),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(THB),
				'one' => q(THB),
				'other' => q(THB),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(TJS),
				'one' => q(TJS),
				'other' => q(TJS),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(TMT),
				'one' => q(TMT),
				'other' => q(TMT),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(TND),
				'one' => q(TND),
				'other' => q(TND),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(TOP),
				'one' => q(TOP),
				'other' => q(TOP),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(TRY),
				'one' => q(TRY),
				'other' => q(TRY),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(TTD),
				'one' => q(TTD),
				'other' => q(TTD),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(TWD),
				'one' => q(TWD),
				'other' => q(TWD),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(TZS),
				'one' => q(TZS),
				'other' => q(TZS),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(UAH),
				'one' => q(UAH),
				'other' => q(UAH),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(UGX),
				'one' => q(UGX),
				'other' => q(UGX),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(USD),
				'one' => q(USD),
				'other' => q(USD),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(UYU),
				'one' => q(UYU),
				'other' => q(UYU),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(UZS),
				'one' => q(UZS),
				'other' => q(UZS),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(VEF),
				'one' => q(VEF),
				'other' => q(VEF),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(VND),
				'one' => q(VND),
				'other' => q(VND),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(VUV),
				'one' => q(VUV),
				'other' => q(VUV),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(WST),
				'one' => q(WST),
				'other' => q(WST),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(XAF),
				'one' => q(XAF),
				'other' => q(XAF),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(XCD),
				'one' => q(XCD),
				'other' => q(XCD),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(XOF),
				'one' => q(XOF),
				'other' => q(XOF),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(XPF),
				'one' => q(XPF),
				'other' => q(XPF),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(نامعلوم د اسعارو له),
				'one' => q(د اسعارو د نامعلومو واحد),
				'other' => q(نامعلوم د اسعارو له),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(YER),
				'one' => q(YER),
				'other' => q(YER),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(ZAR),
				'one' => q(ZAR),
				'other' => q(ZAR),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(ZMW),
				'one' => q(ZMW),
				'other' => q(ZMW),
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
							'جنوري',
							'فبروري',
							'مارچ',
							'اپریل',
							'مۍ',
							'جون',
							'جولای',
							'اگست',
							'سېپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ج',
							'ف',
							'م',
							'ا',
							'م',
							'ج',
							'ج',
							'ا',
							'س',
							'ا',
							'ن',
							'د'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جنوري',
							'فبروري',
							'مارچ',
							'اپریل',
							'مۍ',
							'جون',
							'جولای',
							'اگست',
							'سېپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'جنوري',
							'فبروري',
							'مارچ',
							'اپریل',
							'مۍ',
							'جون',
							'جولای',
							'اگست',
							'سپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'جنوري',
							'فېبروري',
							'مارچ',
							'اپریل',
							'مۍ',
							'جون',
							'جولای',
							'اگست',
							'سپتمبر',
							'اکتوبر',
							'نومبر',
							'دسمبر'
						],
						leap => [
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'چيترا',
							'ويساکا',
							'جياستا',
							'اسادها',
							'سراوانا',
							'بهادرا',
							'اسوينا',
							'کارتيکا',
							'اگراهايانا',
							'پاوسا',
							'مگها',
							'پهالگونا'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'چيترا',
							'ويساکا',
							'جياستا',
							'اسادها',
							'سراوانا',
							'بهادرا',
							'اسوينا',
							'کارتيکا',
							'اگراهايانا',
							'پاوسا',
							'مگها',
							'پهالگونا'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'چيترا',
							'ويساکا',
							'جياستا',
							'اسادها',
							'سراوانا',
							'بهادرا',
							'اسوينا',
							'کارتيکا',
							'اگراهايانا',
							'پاوسا',
							'مگها',
							'پهالگونا'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'چيترا',
							'ويساکا',
							'جياستا',
							'اسادها',
							'سراوانا',
							'بهادرا',
							'اسوينا',
							'کارتيکا',
							'اگراهايانا',
							'پاوسا',
							'مگها',
							'پهالگونا'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'محرم',
							'د صفرې د',
							'ربيع',
							'ربيع II',
							'جماعه',
							'جموما II',
							'راجاب',
							'شعبان',
							'رمضان',
							'شوال',
							'دالقاعده',
							'حلال حج'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'محرم',
							'د صفرې د',
							'ربيع',
							'ربيع II',
							'جماعه',
							'جموما II',
							'راجاب',
							'شعبان',
							'رمضان',
							'شوال',
							'دالقاعده',
							'حلال حج'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'محرم',
							'د صفرې د',
							'ربيع',
							'ربيع II',
							'جماعه',
							'جموما II',
							'راجاب',
							'شعبان',
							'رمضان',
							'شوال',
							'دالقاعده',
							'حلال حج'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'محرم',
							'د صفرې د',
							'ربيع',
							'ربيع II',
							'جماعه',
							'جموما II',
							'راجاب',
							'شعبان',
							'رمضان',
							'شوال',
							'دالقاعده',
							'حلال حج'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'وری',
							'غویی',
							'غبرگولی',
							'چنگاښ',
							'زمری',
							'وږی',
							'تله',
							'لړم',
							'لیندۍ',
							'مرغومی',
							'سلواغه',
							'کب'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'وری',
							'غویی',
							'غبرگولی',
							'چنگاښ',
							'زمری',
							'وږی',
							'تله',
							'لړم',
							'لیندۍ',
							'مرغومی',
							'سلواغه',
							'کب'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'وری',
							'غویی',
							'غبرگولی',
							'چنگاښ',
							'زمری',
							'وږی',
							'تله',
							'لړم',
							'لیندۍ',
							'مرغومی',
							'سلواغه',
							'کب'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'وری',
							'غویی',
							'غبرگولی',
							'چنگاښ',
							'زمری',
							'وږی',
							'تله',
							'لړم',
							'لیندۍ',
							'مرغومی',
							'سلواغه',
							'کب'
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
						mon => 'دونۍ',
						tue => 'درېنۍ',
						wed => 'څلرنۍ',
						thu => 'پينځنۍ',
						fri => 'جمعه',
						sat => 'اونۍ',
						sun => 'يونۍ'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'دونۍ',
						tue => 'درېنۍ',
						wed => 'څلرنۍ',
						thu => 'پينځنۍ',
						fri => 'جمعه',
						sat => 'اونۍ',
						sun => 'يونۍ'
					},
					wide => {
						mon => 'دونۍ',
						tue => 'درېنۍ',
						wed => 'څلرنۍ',
						thu => 'پينځنۍ',
						fri => 'جمعه',
						sat => 'اونۍ',
						sun => 'يونۍ'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'دونۍ',
						tue => 'درېنۍ',
						wed => 'څلرنۍ',
						thu => 'پينځنۍ',
						fri => 'جمعه',
						sat => 'اونۍ',
						sun => 'يونۍ'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'دونۍ',
						tue => 'درېنۍ',
						wed => 'څلرنۍ',
						thu => 'پينځنۍ',
						fri => 'جمعه',
						sat => 'اونۍ',
						sun => 'يونۍ'
					},
					wide => {
						mon => 'دونۍ',
						tue => 'درېنۍ',
						wed => 'څلرنۍ',
						thu => 'پينځنۍ',
						fri => 'جمعه',
						sat => 'اونۍ',
						sun => 'يونۍ'
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
					abbreviated => {0 => 'لومړۍ ربعه',
						1 => '۲مه ربعه',
						2 => '۳مه ربعه',
						3 => '۴مه ربعه'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'لومړۍ ربعه',
						1 => '۲مه ربعه',
						2 => '۳مه ربعه',
						3 => '۴مه ربعه'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'لومړۍ ربعه',
						1 => '۲مه ربعه',
						2 => '۳مه ربعه',
						3 => '۴مه ربعه'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'لومړۍ ربعه',
						1 => '۲مه ربعه',
						2 => '۳مه ربعه',
						3 => '۴مه ربعه'
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
					'am' => q{غ.م.},
					'pm' => q{غ.و.},
				},
				'narrow' => {
					'am' => q{غ.م.},
					'pm' => q{غ.و.},
				},
				'abbreviated' => {
					'am' => q{غ.م.},
					'pm' => q{غ.و.},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{غ.م.},
					'pm' => q{غ.و.},
				},
				'narrow' => {
					'pm' => q{غ.و.},
					'am' => q{غ.م.},
				},
				'abbreviated' => {
					'pm' => q{غ.و.},
					'am' => q{غ.م.},
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
				'0' => 'له میلاد وړاندې',
				'1' => 'م.'
			},
			narrow => {
				'1' => 'م.'
			},
			wide => {
				'0' => 'له میلاد څخه وړاندې',
				'1' => 'له میلاد څخه وروسته'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'ساکا'
			},
			narrow => {
				'0' => 'ساکا'
			},
			wide => {
				'0' => 'ساکا'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
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
			'full' => q{EEEE د G y د MMMM d},
			'long' => q{د G y د MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y/M/d},
		},
		'gregorian' => {
			'full' => q{EEEE د y د MMMM d},
			'long' => q{د y د MMMM d},
			'medium' => q{y MMM d},
			'short' => q{y/M/d},
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{EEEE د G y د MMMM d},
			'long' => q{د G y د MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y/M/d},
		},
		'persian' => {
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
			'full' => q{H:mm:ss (zzzz)},
			'long' => q{H:mm:ss (z)},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
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
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMd => q{d MMMM},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{G y},
			yM => q{G y/M},
			yMMMM => q{د G y د MMMM},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
		'islamic' => {
			E => q{ccc},
			Ed => q{d, E},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			M => q{L},
			MEd => q{MM-dd, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMd => q{d MMMM},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			y => q{G y},
			yM => q{G y/M},
			yMMMM => q{د G y د MMMM},
			yyyy => q{G y},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
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
			MMMMW => q{اونۍ W د MMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
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
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y MMMM},
			yMMMd => q{y MMM d},
			yMd => q{y-MM-dd},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{اونۍ w د Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} ({1})',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
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
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
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
		regionFormat => q(د {0} په وخت),
		regionFormat => q({0} رڼا ورځ وخت),
		regionFormat => q({0} معیاری وخت),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#افغانستان وخت#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#ابيجان#,
		},
		'Africa/Accra' => {
			exemplarCity => q#اکرا#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#اضافی ابابا#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#الګیرز#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#اساماره#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#بامیکو#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#بنوګي#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#بانجول#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#بسو#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#بجوګورا#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#قاهره#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#کاسابلانکا#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#کونکري#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ډاکار#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#دار السلام#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#جبوتي#,
		},
		'Africa/Douala' => {
			exemplarCity => q#ډالاله#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#الیون#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#فریټون#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#ګابرون#,
		},
		'Africa/Harare' => {
			exemplarCity => q#هرارې#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#جوهانبرګ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#جوبا#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#کمپاله#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#خرتوم#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#کيگالي#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#کينشاسا#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#لاگوس#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#لیبریل#,
		},
		'Africa/Lome' => {
			exemplarCity => q#لووم#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#لونده#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#لبوباشي#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#لسیکا#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#مالابو#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#ماپوټو#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#مسرو#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#موگديشو#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#مونروفیا#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#نايروبي#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#نجامینا#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#نیمي#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#نوکوچټ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#اوواګاګواګو#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#پورټو - نوو#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ساو ټوم#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#تريپولي#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#تونس#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#وینهوک#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#منځنی افريقا وخت#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ختيځ افريقا وخت#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#جنوبي افريقا معياري وخت#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#د افریقا افریقا لویدیځ وخت#,
				'generic' => q#لوېديځ افريقا وخت#,
				'standard' => q#لویدیځ افریقایي معیاري وخت#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#د الاسکا د ورځې روښانه کول#,
				'generic' => q#الاسکا وخت#,
				'standard' => q#الاسکا معياري وخت#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#∅∅∅#,
				'generic' => q#الماتا په وخت#,
				'standard' => q#∅∅∅#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ایمیزون اوړي وخت#,
				'generic' => q#ایمیزون وخت#,
				'standard' => q#ایمیزون معیاری وخت#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#اداک#,
		},
		'America/Anchorage' => {
			exemplarCity => q#اینکریج#,
		},
		'America/Anguilla' => {
			exemplarCity => q#انګیلا#,
		},
		'America/Antigua' => {
			exemplarCity => q#انټيګ#,
		},
		'America/Araguaina' => {
			exemplarCity => q#ارګینیا#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#لا ریوج#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ریو ګیلیلیګوس#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#سالټا#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#سان جوان#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#سان لویس#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ټيکووم#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#اوشوایا#,
		},
		'America/Aruba' => {
			exemplarCity => q#آروبا#,
		},
		'America/Asuncion' => {
			exemplarCity => q#اسونسيون#,
		},
		'America/Bahia' => {
			exemplarCity => q#بهیا#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#بهیا بینډراس#,
		},
		'America/Barbados' => {
			exemplarCity => q#باربادوس#,
		},
		'America/Belem' => {
			exemplarCity => q#بلم#,
		},
		'America/Belize' => {
			exemplarCity => q#بلیز#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#بلانک-سابلون#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#بوا ویسټا#,
		},
		'America/Bogota' => {
			exemplarCity => q#بوګټا#,
		},
		'America/Boise' => {
			exemplarCity => q#بوز#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#بينوس اييرز#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#کیمبرج بي#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#کمپو ګرډی#,
		},
		'America/Cancun' => {
			exemplarCity => q#کینن#,
		},
		'America/Caracas' => {
			exemplarCity => q#کاراکاس#,
		},
		'America/Catamarca' => {
			exemplarCity => q#کټامارکا#,
		},
		'America/Cayenne' => {
			exemplarCity => q#کیین#,
		},
		'America/Cayman' => {
			exemplarCity => q#کیمن#,
		},
		'America/Chicago' => {
			exemplarCity => q#شیکاګو#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#چھواھوا#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#اتیکوکن#,
		},
		'America/Cordoba' => {
			exemplarCity => q#کوډوبا#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#کوستاریکا#,
		},
		'America/Creston' => {
			exemplarCity => q#کرسټون#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#کویابا#,
		},
		'America/Curacao' => {
			exemplarCity => q#کیکاو#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ډنمارک هاربر#,
		},
		'America/Dawson' => {
			exemplarCity => q#داوسن#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#داسن کریک#,
		},
		'America/Denver' => {
			exemplarCity => q#ډنور#,
		},
		'America/Detroit' => {
			exemplarCity => q#ډایټروټ#,
		},
		'America/Dominica' => {
			exemplarCity => q#دومینیکا#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ایډمونټن#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#اییرونپ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ايل سلوادور#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#فورټ نیلسن#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#فورتیلزا#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ګیسس بيی#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#گوز بي#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#لوی ترک#,
		},
		'America/Grenada' => {
			exemplarCity => q#ګرنادا#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ګالډیپ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ګواتمالا#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#ګویاګل#,
		},
		'America/Guyana' => {
			exemplarCity => q#ګیانا#,
		},
		'America/Halifax' => {
			exemplarCity => q#هیلفکس#,
		},
		'America/Havana' => {
			exemplarCity => q#هایانا#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#هرموسیلو#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#نکس، اندیانا#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#مارینګ، انډیانا#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#پیتربورګ، انډيانا#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ښار، انډیا ته ووایی#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ویوی، انډیډا#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#وینینسین، انډا#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ویناماسک، انډی#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#انډولپولیس#,
		},
		'America/Inuvik' => {
			exemplarCity => q#انوک#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#اقلیټ#,
		},
		'America/Jamaica' => {
			exemplarCity => q#جمایکه#,
		},
		'America/Jujuy' => {
			exemplarCity => q#جوجو#,
		},
		'America/Juneau' => {
			exemplarCity => q#جونو#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#مونټیکیلو، کینیسي#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#کلینډیزج#,
		},
		'America/La_Paz' => {
			exemplarCity => q#لا پاز#,
		},
		'America/Lima' => {
			exemplarCity => q#لیما#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#لاس اینجلس#,
		},
		'America/Louisville' => {
			exemplarCity => q#لوئس ویل#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#د کمتر شهزاده درې میاشتنۍ#,
		},
		'America/Maceio' => {
			exemplarCity => q#مایسیو#,
		},
		'America/Managua' => {
			exemplarCity => q#منګوا#,
		},
		'America/Manaus' => {
			exemplarCity => q#منوس#,
		},
		'America/Marigot' => {
			exemplarCity => q#مارګټ#,
		},
		'America/Martinique' => {
			exemplarCity => q#مارټینیک#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#مزاتلان#,
		},
		'America/Mendoza' => {
			exemplarCity => q#مینډوزا#,
		},
		'America/Menominee' => {
			exemplarCity => q#مینومین#,
		},
		'America/Merida' => {
			exemplarCity => q#مرده#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#میتلاکاټلا#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#مکسيکو ښار#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ميکلين#,
		},
		'America/Moncton' => {
			exemplarCity => q#مونټون#,
		},
		'America/Monterrey' => {
			exemplarCity => q#منټرري#,
		},
		'America/Montevideo' => {
			exemplarCity => q#مونټ وډیو#,
		},
		'America/Montserrat' => {
			exemplarCity => q#مانټیسیرت#,
		},
		'America/Nassau' => {
			exemplarCity => q#نیساو#,
		},
		'America/New_York' => {
			exemplarCity => q#نیویارک#,
		},
		'America/Nipigon' => {
			exemplarCity => q#نیپګون#,
		},
		'America/Nome' => {
			exemplarCity => q#نوم#,
		},
		'America/Noronha' => {
			exemplarCity => q#نورونها#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#بيلاه، شمالي داکوتا#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#مرکز، د شمالي ټاپو#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#نوی سلیم، شمالي داکوتا#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#اوجنګا#,
		},
		'America/Panama' => {
			exemplarCity => q#پاناما#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#پيننټيرګ#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#پاراماربو#,
		},
		'America/Phoenix' => {
			exemplarCity => q#فینکس#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#پورټ ایو - پرنس#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#د اسپانیا بندر#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#پورټو ویلهو#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#پورتو ریکو#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#پنټا آریناس#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#د باران باران#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#رانکين لط#,
		},
		'America/Recife' => {
			exemplarCity => q#ریسیفي#,
		},
		'America/Regina' => {
			exemplarCity => q#ریګینا#,
		},
		'America/Resolute' => {
			exemplarCity => q#غوڅ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ریو برانکو#,
		},
		'America/Santarem' => {
			exemplarCity => q#سناترم#,
		},
		'America/Santiago' => {
			exemplarCity => q#سنتياګو#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#سنتو ډومینګو#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ساو پاولو#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#سیټکا#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#سینټ بارټیلیم#,
		},
		'America/St_Johns' => {
			exemplarCity => q#د سینټ جان#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#سینټ کټس#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#سینټ لوسیا#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#سایټ توماس#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#سېنټ ویسنټ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#اوسنی بدلون#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ټګسیګالپا#,
		},
		'America/Thule' => {
			exemplarCity => q#تول#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#د تندر خلیج#,
		},
		'America/Tijuana' => {
			exemplarCity => q#تجهان#,
		},
		'America/Toronto' => {
			exemplarCity => q#ټورنټو#,
		},
		'America/Tortola' => {
			exemplarCity => q#ټورتولا#,
		},
		'America/Vancouver' => {
			exemplarCity => q#وینکوور#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#سپین آس#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#وینپیګ#,
		},
		'America/Yakutat' => {
			exemplarCity => q#یاکتټ#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#زرونیف#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#مرکزي رڼا ورځې وخت#,
				'generic' => q#مرکزي وخت#,
				'standard' => q#مرکزي معياري وخت#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ختيځ د رڼا ورځې وخت#,
				'generic' => q#ختیځ وخت#,
				'standard' => q#ختيځ معياري وخت#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#د غره د رڼا ورځې وخت#,
				'generic' => q#د غره د وخت#,
				'standard' => q#د غره معياري وخت#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#پیسفک د رڼا ورځې وخت#,
				'generic' => q#پیسفک وخت#,
				'standard' => q#د پیسفک معياري وخت#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#کیسي#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#دیویس#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ډومونټ ډي اوورول#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#مکاکري#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#مسونسن#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#پالر#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#رورها#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#سیوا#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ټول#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#واستوک#,
		},
		'Apia' => {
			long => {
				'daylight' => q#د اپیا د ورځې وخت#,
				'generic' => q#د اپیا وخت#,
				'standard' => q#د اپیا معياري وخت#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#د عربي ورځپاڼې وخت#,
				'generic' => q#عربي وخت#,
				'standard' => q#عربي معیاري وخت#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#لاندینبیبین#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ارجنټاین اوړي وخت#,
				'generic' => q#ارجنټاین وخت#,
				'standard' => q#ارجنټاین معیاری وخت#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#غربي ارجنټاین اوړي وخت#,
				'generic' => q#غربي ارجنټاین وخت#,
				'standard' => q#غربي ارجنټاین معیاری وخت#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ارمنستان سمر وخت#,
				'generic' => q#ارمنستان وخت#,
				'standard' => q#ارمنستان معياري وخت#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#اډن#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#الماتی#,
		},
		'Asia/Amman' => {
			exemplarCity => q#اممان#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#اکاټو#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#اکتوب#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#اشغ آباد#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#اېټراو#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#بغداد#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#بحرین#,
		},
		'Asia/Baku' => {
			exemplarCity => q#باکو#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#بانکاک#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#برنول#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#بیروت#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#بشکیک#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#برویني#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#کولکته#,
		},
		'Asia/Chita' => {
			exemplarCity => q#چيتا#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#کولمبو#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#دمشق#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ډهاکه#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ديلي#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#دوبی#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#دوشنبي#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#غزه#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#هبرون#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#هانګ کانګ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ایرکوټس#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#جاکارټا#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#جاپورا#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#یهودان#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#کابل#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#کامچاتکا#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#کراچي#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#کټمنډو#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#خندګي#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#کریسایویارسک#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#کولالمپور#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#کوچيګ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#کویټ#,
		},
		'Asia/Macau' => {
			exemplarCity => q#مکا#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#مګدان#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#مکاسار#,
		},
		'Asia/Manila' => {
			exemplarCity => q#منیلا#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#مسکټ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#نیکوسیا#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#نووکوزنیټک#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#نووسوسبیرک#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#اوک#,
		},
		'Asia/Oral' => {
			exemplarCity => q#اورل#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#دوم قلم#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#پونټینیک#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#پیونگګنګ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#قطر#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#قزیلیلرا#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#یانګون#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#رياض#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#هو چي مينه#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#سخنین#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#سمرقند#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#سیول#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#شنگھائی#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#سینګاپور#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#سنینیکولوژیک#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#تاپي#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#تاشکند#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#تبلیسي#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#تهران#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#تهيمفو#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ټوکیو#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#توماس#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#اللانبیر#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#اوسترا#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#وینټینیا#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#ولادیوستاک#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#یااکټس#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#یاراتینینګ برګ#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#ییران#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#اتلانتیک د رڼا ورځې وخت#,
				'generic' => q#اتلانتیک د وخت#,
				'standard' => q#اتلانتیک معياري وخت#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#برمودا#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#کیري#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#کېپ وردا#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#فارو#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#مایررا#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ريکسجيک#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#سویل جورجیا#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#سینټ هیلینا#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#سټنلي#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#اډیلایډ#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#بریسبن#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#مات شوی هیل#,
		},
		'Australia/Currie' => {
			exemplarCity => q#کرري#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ډارون#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#ایولیکا#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#هوبارټ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#لینډامین#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#رب هیله#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#میلبورن#,
		},
		'Australia/Perth' => {
			exemplarCity => q#پورت#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#سډني#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#د آسټرالیا مرکزي مرکزی ورځ#,
				'generic' => q#د مرکزي آسټر وخت#,
				'standard' => q#د اسټرالیا مرکزي مرکزي معیار#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#د آسټرالیا مرکزي مرکزی لویدیځ د وخت وخت#,
				'generic' => q#د آسټرالیا مرکزی لویدیځ وخت#,
				'standard' => q#د آسټرالیا مرکزي لویدیځ معیاري وخت#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#د اسټرالیا ختیځ ختیځ ورځی وخت#,
				'generic' => q#د ختیځ آسټر وخت#,
				'standard' => q#د آسټرالیا ختیځ معیاري وخت#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#د اسټرالیا لویدیځ د ورځې وخت#,
				'generic' => q#د لویدیځ آسټرالیا وخت#,
				'standard' => q#د اسټرالیا لویدیز معیار#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#د اذرباییجان سمر وخت#,
				'generic' => q#د آذربايجان وخت#,
				'standard' => q#آذربايجان معياري وخت#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores سمر وخت#,
				'generic' => q#Azores Time#,
				'standard' => q#Azores معياري وخت#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#د بنگله دیش د سمر وخت#,
				'generic' => q#بنگله دېش وخت#,
				'standard' => q#د بنګلادیش معیاري وخت#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#د بوتان وخت#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#بولیویا وخت#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#برسلیا اوړي وخت#,
				'generic' => q#برسلیا وخت#,
				'standard' => q#برسلیا معیاری وخت#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#د بروني درسلام وخت#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#کیپ وردډ سمر وخت#,
				'generic' => q#کیپ وردډ وخت#,
				'standard' => q#کیپ وردډ معياري وخت#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#چمارو معياري وخت#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#د چتام ورځی وخت#,
				'generic' => q#چامام وخت#,
				'standard' => q#د چمتم معياري وخت#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#چلی اوړي وخت#,
				'generic' => q#چلی وخت#,
				'standard' => q#چلی معیاری وخت#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#د چين د رڼا ورځې وخت#,
				'generic' => q#چين وخت#,
				'standard' => q#چین معیاري وخت#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#چوئیبیلسن اوړي وخت#,
				'generic' => q#چوئیبیلسن وخت#,
				'standard' => q#چوئیبیلسن معیاری وخت#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#د کریسټ ټاپو وخت#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#د کوکوز ټاپوز وخت#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#کولمبیا اوړي وخت#,
				'generic' => q#کولمبیا وخت#,
				'standard' => q#کولمبیا معیاری وخت#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#د کوک ټاپو نیمه سمر وخت#,
				'generic' => q#د کوک ټاپوز وخت#,
				'standard' => q#د کوک ټاپوز معياري وخت#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#کیوبا د رڼا ورځې وخت#,
				'generic' => q#کیوبا د وخت#,
				'standard' => q#کیوبا معياري وخت#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#دیوس وخت#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ډومونټ-ډیریلوی وخت#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ختیځ ختیځ تیمور وخت#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ايستر ټاپو اوړي وخت#,
				'generic' => q#ايستر ټاپو وخت#,
				'standard' => q#ايستر ټاپو معياري وخت#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#د اکوادور وخت#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#همغږۍ نړیواله موده#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#نامعلوم ښار#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#امستردام#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#اندورا#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#آسترخان#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ایترین#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#بلغاد#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#برلین#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#براتسکوا#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#بروسلز#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#بخارست#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#بوډاپیس#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#بسینګین#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#چیسینو#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#کوپینګنګ#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ډوبلین#,
			long => {
				'daylight' => q#ایراني معیاري وخ#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#جبل الطارق#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#ګرنسي#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#هیلسنکی#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#د آئل آف مین#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#استانبول#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#جرسی#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#کیليینګراډر#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#کیو#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#کیروف#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#لیسبون#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#لوججانا#,
		},
		'Europe/London' => {
			exemplarCity => q#لندن#,
			long => {
				'daylight' => q#د انګلستان سمر وخت#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#لوګزامبورګ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#میډریډ#,
		},
		'Europe/Malta' => {
			exemplarCity => q#مالتا#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#ماریاهمین#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#منسک#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#موناکو#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#ماسکو#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#اوسلو#,
		},
		'Europe/Paris' => {
			exemplarCity => q#پاریس#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#پوډورګویکا#,
		},
		'Europe/Prague' => {
			exemplarCity => q#پراګ#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ریګ#,
		},
		'Europe/Rome' => {
			exemplarCity => q#روم#,
		},
		'Europe/Samara' => {
			exemplarCity => q#سمارا#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#سان مارینو#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#سرجیو#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#سراتف#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#سیمفروپول#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#سکپوګ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#صوفیا#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#استولوم#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#تالين#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ایلیانوفس#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#یوژورډ#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#وادز#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#ویټیکان#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#ویانا#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#ویلیونس#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#والګراډر#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#وارسا#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#زګرب#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#زاپوروژی#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#زریچ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#د مرکزي اروپا د اوړي وخت#,
				'generic' => q#منځنۍ اروپا وخت#,
				'standard' => q#د مرکزي اروپا معیاري وخت#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Eastern European Summer Time#,
				'generic' => q#Eastern European Time#,
				'standard' => q#Eastern European Standard Time#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#نور ختیځ ختیځ اروپا وخت#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#د لودیځې اورپا د اوړي وخت#,
				'generic' => q#لوېديزې اروپا وخت#,
				'standard' => q#د لودیځې اروپا معیاري وخت#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#د فوکلنډ ټاپو اوړي وخت#,
				'generic' => q#د فوکلنډ ټاپو وخت#,
				'standard' => q#د فوکلنډ ټاپو معیاری وخت#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#د فجی سمر وخت#,
				'generic' => q#فجی وخت#,
				'standard' => q#د فجی معياري وخت#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#د فرانسوي ګانا وخت#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#د فرانسې سویل او انټارټيک وخت#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#گرينويچ وخت#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ګالپګوس وخت#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#د ګیمبریر وخت#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#د جورجیا د سمر وخت#,
				'generic' => q#جورجیا وخت#,
				'standard' => q#جورجیا معیاري وخت#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#د ګیلبرټ جزیره وخت#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#د ختیځ ګرینلینډ اوړي وخت#,
				'generic' => q#د ختیځ ګرینلینډ وخت#,
				'standard' => q#د ختیځ ګرینلینډ معياري وخت#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#لویدیځ ګرینلینډ اوړي وخت#,
				'generic' => q#لویدیځ ګرینلینډ وخت#,
				'standard' => q#لویدیځ ګرینلینډ معياري وخت#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#د خلیج معياري وخت#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#د ګوانانا وخت#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#هوایی الیوتین رڼا ورځې وخت#,
				'generic' => q#هوایی الیوتین وخت#,
				'standard' => q#هوایی الیوتین معیاری وخت#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#د هانګ کانګ اوړي وخت#,
				'generic' => q#د هانګ کانګ د وخت#,
				'standard' => q#د هانګ کانګ معياري وخت#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#هاوډ اوړي وخت#,
				'generic' => q#هاوډ وخت#,
				'standard' => q#هاوډ معیاری وخت#,
			},
		},
		'India' => {
			long => {
				'standard' => q#د هند معیاري وخت#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#انتوننارو#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#چارګوس#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#کریمیس#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#کوکوس#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#کومو#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#مای#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#مالديپ#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#ماوريشوس#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#میټوت#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ریونیو#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#د هند سمندر وخت#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#د اندوچینا وخت#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#د اندونیزیا مرکزي وخت#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#د اندونیزیا وخت#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#د لویدیځ اندونیزیا وخت#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#د ایران د ورځې وخت#,
				'generic' => q#د ایران وخت#,
				'standard' => q#د ایران معياري وخت#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#د ایککوټس سمر وخت#,
				'generic' => q#د ارکوټس وخت#,
				'standard' => q#د ارکوټس معياري وخت#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#د اسراییلو د ورځې وخت#,
				'generic' => q#د اسراییل وخت#,
				'standard' => q#د اسراییل معياري وخت#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#جاپان د رڼا ورځې وخت#,
				'generic' => q#جاپان د وخت#,
				'standard' => q#د جاپان معياري وخت#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ختیځ د قزاقستان د وخت#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#لویدیځ قزاقستان وخت#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#د کوریا د ورځې د ورځې وخت#,
				'generic' => q#کوريا وخت#,
				'standard' => q#کوريا معياري وخت#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#کوسیرا وخت#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#کریسایویارسک سمر وخت#,
				'generic' => q#کریسایویسسک وخت#,
				'standard' => q#کریسایویارسک معیاري وخت#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#کرغیزستان وخت#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#د کرښې ټاټوبي وخت#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#رب هاو د ورځې د رڼا وخت#,
				'generic' => q#رب های وخت#,
				'standard' => q#رب های معیاري وخت#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#د مکاکري ټاپو وخت#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#د مګمان سمر وخ#,
				'generic' => q#د مګدان وخت#,
				'standard' => q#میګډان معياري وخت#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ملائیشیا وخت#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#مالديف وخت#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#مارکسس وخت#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#مارشیل ټاپو وخت#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ماریسیس سمر وخت#,
				'generic' => q#ماریسیس وخت#,
				'standard' => q#ماریشیس معياري وخت#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#دسونسن وخت#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#د شمال لویدیځ مکسیکو رڼا ورځې وخت#,
				'generic' => q#د شمال لویدیځ مکسیکو وخت#,
				'standard' => q#د شمال لویدیځ مکسیکو معیاري وخت#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#مکسیکن پیسفک رڼا ورځې وخت#,
				'generic' => q#مکسیکن پیسفک وخت#,
				'standard' => q#مکسیکن پیسفک معیاری وخت#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#دلان بیتر سمر وخت#,
				'generic' => q#دلانانباټ وخت#,
				'standard' => q#اولان بټر معیاري وخت#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ماسکو سمر وخت#,
				'generic' => q#ماسکو وخت#,
				'standard' => q#ماسکو معياري وخت#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#د میانمار وخت#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ناورو وخت#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#نیپال وخت#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#د نیو کالیډونیا سمر وخت#,
				'generic' => q#د نیو کالیډونیا وخت#,
				'standard' => q#نوی کالیډونیا معياري وخت#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#د نیوزی لینڈ د ورځې د رڼا وخت#,
				'generic' => q#د نیوزی لینڈ وخت#,
				'standard' => q#د نیوزی لینڈ معیاري وخت#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#د نوي فیلډلینډ رڼا ورځې وخت#,
				'generic' => q#د نوي فیلډلینډ وخت#,
				'standard' => q#د نوي فیلډلینډ معیاری وخت#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#نییو وخت#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#د نورفکاس ټاپو وخت#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#فرنانڈو دي نورونھا اوړي وخت#,
				'generic' => q#فرنانڈو دي نورونها وخت#,
				'standard' => q#فرنانڈو دي نورونها معیاری وخت#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#نووسوسبیرک سمر وخت#,
				'generic' => q#د نووسوسبیرک وخت#,
				'standard' => q#د نووسوسبیرک معياري وخت#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#اوسمک سمر وخت#,
				'generic' => q#اوزک وخت#,
				'standard' => q#د اوزک معياري وخت#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#اپیا#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#اکلند#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#چامام#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ایسټر#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ایات#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#فوکافو#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#في جي#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#فرهفتی#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#ګالپګوس#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#ګيمبي#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#ګالالکنال#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#ګوام#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#هینولولو#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#جانستون#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#کوسیرا#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#کجیجینین#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#مجورو#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#مارکسونه#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#میډیا#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#نایرو#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#نیوو#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#نورفک#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#نواما#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#پیگو پیگو#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#پلو#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#پونپي#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#پور موورسبی#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#راروتاګون#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#سيپان#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ټیټیټي#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#ترارو#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ټونګاتاپو#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#چکوک#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#ویک#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#والس#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#د پاکستان سمر وخت#,
				'generic' => q#د پاکستان وخت#,
				'standard' => q#د پاکستان معیاري وخت#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#پالاو وخت#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#پاپوا نیو ګنی وخت#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#پاراګوای اوړي وخت#,
				'generic' => q#پاراګوای د وخت#,
				'standard' => q#پیراګوای معياري وخت#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#پیرو اوړي وخت#,
				'generic' => q#پیرو وخت#,
				'standard' => q#پیرو معياري وخت#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#د فلپین سمر وخت#,
				'generic' => q#د فلپین وخت#,
				'standard' => q#فلپین معياري وخت#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#د فینکس ټاپو وخت#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#سینټ پییرا و ميکلين رڼا ورځې وخت#,
				'generic' => q#سینټ پییرا و ميکلين وخت#,
				'standard' => q#سینټ پییرا و ميکلين معیاری وخت#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#پیټ کارین وخت#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#پونپپ وخت#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#پیونگګنګ وخت#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#د غبرګون وخت#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#د رورېټا وخت#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#د سخلین سمر وخت#,
				'generic' => q#د سخنین وخت#,
				'standard' => q#سخلین معياري وخت#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#د سموا د ورځې روښانه کول#,
				'generic' => q#سموا وخت#,
				'standard' => q#سموډ معياري وخت#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#سیچیلس وخت#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#د سنګاپور معیاري وخت#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#د سلیمان ټاپوګانو وخت#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#د سویل جورجیا وخت#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#سورینام وخت#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#سیوا وخت#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ټیټيټي وخت#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#تاپي د ورځې د رڼا وخت#,
				'generic' => q#تاپي وخت#,
				'standard' => q#تاپي معياري وخت#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#تاجکستان د وخت#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#توکیلاو وخت#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#د ټونګ سمر وخت#,
				'generic' => q#ټونګا وخت#,
				'standard' => q#د ټونګ معياري وخت#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#د چوکو وخت#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ترکمنستان اوړي وخت#,
				'generic' => q#ترکمانستان وخت#,
				'standard' => q#ترکمنستان معياري وخت#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#توولول وخت#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#یوروګوای اوړي وخت#,
				'generic' => q#یوروګوای وخت#,
				'standard' => q#یوروګوای معياري وخت#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ازبکستان اوړي وخت#,
				'generic' => q#د ازبکستان وخت#,
				'standard' => q#ازبکستان معياري وخت#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#وانوات سمر وخت#,
				'generic' => q#د وناتو وخت#,
				'standard' => q#د وناتو معياري وخت#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#وینزویلا وخت#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ولادیوستک سمر وخت#,
				'generic' => q#ولادیوستاک وخت#,
				'standard' => q#ولادیوستکو معياري وخت#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#د ولگګراډ سمر وخت#,
				'generic' => q#د ولګاجرا وخت#,
				'standard' => q#دګګراډر معياري وخت#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#د واستوک وخت#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#دک ټاپو وخت#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#والیس او فوتونا وخت#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#داککوسک سمر وخت#,
				'generic' => q#داککوس وخت#,
				'standard' => q#داککوسک معياري وخت#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#د یاراتینګینګ ګرم موسم#,
				'generic' => q#د یاراتینګینګ وخت#,
				'standard' => q#د یاراتینګینبرین معياري وخت#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
