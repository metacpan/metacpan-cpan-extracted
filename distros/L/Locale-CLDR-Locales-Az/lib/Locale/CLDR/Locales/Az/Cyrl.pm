=head1

Locale::CLDR::Locales::Az::Cyrl - Package for language Azerbaijani

=cut

package Locale::CLDR::Locales::Az::Cyrl;
# This file auto generated from Data\common\main\az_Cyrl.xml
#	on Sun  5 Aug  5:51:55 pm GMT

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

extends('Locale::CLDR::Locales::Az');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'aa' => 'афар',
 				'ab' => 'абхаз',
 				'ace' => 'акин',
 				'ada' => 'адангме',
 				'ady' => 'адуҝе',
 				'af' => 'африкаанс',
 				'agq' => 'агһем',
 				'ain' => 'ајну',
 				'ak' => 'акан',
 				'ale' => 'алеут',
 				'alt' => 'ҹәнуби алтај',
 				'am' => 'амһар',
 				'an' => 'арагон',
 				'anp' => 'анҝика',
 				'ar' => 'әрәб',
 				'ar_001' => 'мүасир стандарт әрәб',
 				'arn' => 'арауканҹа',
 				'arp' => 'арапаһо',
 				'as' => 'ассам',
 				'asa' => 'асу',
 				'ast' => 'астурија',
 				'av' => 'авар',
 				'awa' => 'авадһи',
 				'ay' => 'ајмара',
 				'az' => 'азәрбајҹан',
 				'ba' => 'башгырд',
 				'ban' => 'балли',
 				'bas' => 'баса',
 				'be' => 'беларус',
 				'bem' => 'бемба',
 				'bez' => 'бена',
 				'bg' => 'булгар',
 				'bho' => 'бхочпури',
 				'bi' => 'бислама',
 				'bin' => 'бини',
 				'bla' => 'сиксикә',
 				'bm' => 'бамбара',
 				'bn' => 'бенгал',
 				'bo' => 'тибет',
 				'br' => 'бретон',
 				'brx' => 'бодо',
 				'bs' => 'босниак',
 				'bug' => 'буҝин',
 				'byn' => 'блин',
 				'ca' => 'каталан',
 				'ce' => 'чечен',
 				'ceb' => 'себуан',
 				'cgg' => 'чига',
 				'ch' => 'чаморо',
 				'chk' => 'чукиз',
 				'chm' => 'мари',
 				'cho' => 'чоктау',
 				'chr' => 'чероки',
 				'chy' => 'чејен',
 				'ckb' => 'соран',
 				'co' => 'корсика',
 				'crs' => 'сејшел креолу',
 				'cs' => 'чех',
 				'cu' => 'славјан',
 				'cv' => 'чуваш',
 				'cy' => 'уелс',
 				'da' => 'данимарка',
 				'dak' => 'дакота',
 				'dar' => 'даргва',
 				'dav' => 'таита',
 				'de' => 'алман',
 				'de_AT' => 'Австрија алманҹасы',
 				'de_CH' => 'Исвечрә јүксәк алманҹасы',
 				'dgr' => 'догриб',
 				'dje' => 'зарма',
 				'dsb' => 'ашағы сорб',
 				'dua' => 'дуала',
 				'dv' => 'малдив',
 				'dyo' => 'диола',
 				'dz' => 'дзонга',
 				'dzg' => 'дазага',
 				'ebu' => 'ембу',
 				'ee' => 'еве',
 				'efi' => 'ефик',
 				'eka' => 'екаҹук',
 				'el' => 'јунан',
 				'en' => 'инҝилис',
 				'en_AU' => 'Австралија инҝилисҹәси',
 				'en_CA' => 'Канада инҝилисҹәси',
 				'en_GB' => 'Британија инҝилисҹәси',
 				'en_GB@alt=short' => 'инҝилис (Б.К.)',
 				'en_US' => 'Америка инҝилисҹәси',
 				'en_US@alt=short' => 'инҝилис (АБШ)',
 				'eo' => 'есперанто',
 				'es' => 'испан',
 				'es_419' => 'Латын Америкасы испанҹасы',
 				'es_ES' => 'Кастилија испанҹасы',
 				'es_MX' => 'Мексика испанҹасы',
 				'et' => 'естон',
 				'eu' => 'баск',
 				'ewo' => 'евондо',
 				'fa' => 'фарс',
 				'ff' => 'фула',
 				'fi' => 'фин',
 				'fil' => 'филиппин',
 				'fj' => 'фиҹи',
 				'fo' => 'фарер',
 				'fon' => 'фон',
 				'fr' => 'франсыз',
 				'fr_CA' => 'Канада франсызҹасы',
 				'fr_CH' => 'Исвечрә франсызҹасы',
 				'fur' => 'фриул',
 				'fy' => 'гәрби фриз',
 				'ga' => 'ирланд',
 				'gaa' => 'га',
 				'gd' => 'шотланд келт',
 				'gez' => 'гез',
 				'gil' => 'гилберт',
 				'gl' => 'галисија',
 				'gn' => 'гуарани',
 				'gor' => 'горонтало',
 				'gsw' => 'Исвечрә алманҹасы',
 				'gu' => 'гуҹарат',
 				'guz' => 'гуси',
 				'gv' => 'манкс',
 				'gwi' => 'гвичин',
 				'ha' => 'һауса',
 				'haw' => 'һавај',
 				'he' => 'иврит',
 				'hi' => 'һинд',
 				'hil' => 'һилигајнон',
 				'hmn' => 'монг',
 				'hr' => 'хорват',
 				'hsb' => 'јухары сорб',
 				'ht' => 'һаити креол',
 				'hu' => 'маҹар',
 				'hup' => 'һупа',
 				'hy' => 'ермәни',
 				'hz' => 'һереро',
 				'ia' => 'интерлингве',
 				'iba' => 'ибан',
 				'ibb' => 'ибибио',
 				'id' => 'индонезија',
 				'ig' => 'игбо',
 				'ilo' => 'илоко',
 				'inh' => 'ингуш',
 				'io' => 'идо',
 				'is' => 'исланд',
 				'it' => 'италјан',
 				'iu' => 'инуктитут',
 				'ja' => 'јапон',
 				'jbo' => 'лоғбан',
 				'jgo' => 'нгомба',
 				'jmc' => 'мачам',
 				'jv' => 'јава',
 				'ka' => 'ҝүрҹү',
 				'kab' => 'кабиле',
 				'kac' => 'качин',
 				'kaj' => 'жу',
 				'kam' => 'камба',
 				'kbd' => 'кабарда-чәркәз',
 				'kcg' => 'тви',
 				'kde' => 'маконде',
 				'kea' => 'кабувердиан',
 				'kfo' => 'коро',
 				'kha' => 'хази',
 				'khq' => 'којра чиини',
 				'ki' => 'кикују',
 				'kj' => 'куанјама',
 				'kk' => 'газах',
 				'kkj' => 'како',
 				'kl' => 'калааллисут',
 				'kln' => 'каленҹин',
 				'km' => 'кхмер',
 				'kmb' => 'кимбунду',
 				'kn' => 'каннада',
 				'ko' => 'кореја',
 				'kok' => 'конкани',
 				'kpe' => 'кпелле',
 				'kr' => 'канури',
 				'krc' => 'гарачај-балкар',
 				'krl' => 'карел',
 				'kru' => 'курух',
 				'ks' => 'кәшмир',
 				'ksb' => 'шамбала',
 				'ksf' => 'бафиа',
 				'ksh' => 'көлн',
 				'ku' => 'күрд',
 				'kum' => 'кумык',
 				'kv' => 'коми',
 				'kw' => 'корн',
 				'ky' => 'гырғыз',
 				'la' => 'латын',
 				'lad' => 'сефард',
 				'lag' => 'ланҝи',
 				'lb' => 'лүксембург',
 				'lez' => 'ләзҝи',
 				'lg' => 'ганда',
 				'li' => 'лимбург',
 				'lkt' => 'лакота',
 				'ln' => 'лингала',
 				'lo' => 'лаос',
 				'loz' => 'лози',
 				'lrc' => 'шимали лури',
 				'lt' => 'литва',
 				'lu' => 'луба-катанга',
 				'lua' => 'луба-лулуа',
 				'lun' => 'лунда',
 				'luo' => 'луо',
 				'lus' => 'мизо',
 				'luy' => 'лујиа',
 				'lv' => 'латыш',
 				'mad' => 'мадуриз',
 				'mag' => 'магаһи',
 				'mai' => 'маитили',
 				'mak' => 'макасар',
 				'mas' => 'масај',
 				'mdf' => 'мокша',
 				'men' => 'менде',
 				'mer' => 'меру',
 				'mfe' => 'морисиен',
 				'mg' => 'малагас',
 				'mgh' => 'махува-меетто',
 				'mgo' => 'метаʼ',
 				'mh' => 'маршал',
 				'mi' => 'маори',
 				'mic' => 'микмак',
 				'min' => 'минангкабан',
 				'mk' => 'македон',
 				'ml' => 'малајалам',
 				'mn' => 'монгол',
 				'mni' => 'манипүри',
 				'moh' => 'моһавк',
 				'mos' => 'моси',
 				'mr' => 'маратһи',
 				'ms' => 'малај',
 				'mt' => 'малта',
 				'mua' => 'мунданг',
 				'mul' => 'чохсајлы дилләр',
 				'mus' => 'крик',
 				'mwl' => 'миранд',
 				'my' => 'бирман',
 				'myv' => 'ерзја',
 				'mzn' => 'мазандаран',
 				'na' => 'науру',
 				'nap' => 'неаполитан',
 				'naq' => 'нама',
 				'nb' => 'бокмал норвеч',
 				'nd' => 'шимали ндебеле',
 				'nds_NL' => 'ашағы саксон',
 				'ne' => 'непал',
 				'new' => 'невари',
 				'ng' => 'ндонга',
 				'nia' => 'ниас',
 				'niu' => 'нијуан',
 				'nl' => 'һолланд',
 				'nl_BE' => 'фламанд',
 				'nmg' => 'квасио',
 				'nn' => 'нүнорск норвеч',
 				'nnh' => 'нҝиембоон',
 				'nog' => 'ногај',
 				'nqo' => 'нго',
 				'nr' => 'ҹәнуби ндебеле',
 				'nso' => 'шимали сото',
 				'nus' => 'нуер',
 				'nv' => 'навајо',
 				'ny' => 'нјанҹа',
 				'nyn' => 'нјанкол',
 				'oc' => 'окситан',
 				'om' => 'оромо',
 				'or' => 'одија',
 				'os' => 'осетин',
 				'pa' => 'пәнҹаб',
 				'pag' => 'пангасинан',
 				'pam' => 'пампанга',
 				'pap' => 'папјаменто',
 				'pau' => 'палајан',
 				'pcm' => 'ниҝер креол',
 				'pl' => 'полјак',
 				'prg' => 'прусс',
 				'ps' => 'пушту',
 				'pt' => 'португал',
 				'pt_BR' => 'Бразилија португалҹасы',
 				'pt_PT' => 'Португалија португалҹасы',
 				'qu' => 'кечуа',
 				'quc' => 'киче',
 				'rap' => 'рапануи',
 				'rar' => 'раротонган',
 				'rm' => 'романш',
 				'rn' => 'рунди',
 				'ro' => 'румын',
 				'rof' => 'ромбо',
 				'root' => 'рут',
 				'ru' => 'рус',
 				'rup' => 'ароман',
 				'rw' => 'кинјарванда',
 				'rwk' => 'руа',
 				'sa' => 'санскрит',
 				'sad' => 'сандаве',
 				'sah' => 'саха',
 				'saq' => 'самбуру',
 				'sat' => 'сантал',
 				'sba' => 'нгамбај',
 				'sbp' => 'сангу',
 				'sc' => 'сардин',
 				'scn' => 'сиҹилија',
 				'sco' => 'скотс',
 				'sd' => 'синдһи',
 				'se' => 'шимали сами',
 				'seh' => 'сена',
 				'ses' => 'којраборо сенни',
 				'sg' => 'санго',
 				'shi' => 'тачелит',
 				'shn' => 'шан',
 				'si' => 'синһала',
 				'sk' => 'словак',
 				'sl' => 'словен',
 				'sm' => 'самоа',
 				'sma' => 'ҹәнуби сами',
 				'smj' => 'луле сами',
 				'smn' => 'инари сами',
 				'sms' => 'сколт сами',
 				'sn' => 'шона',
 				'snk' => 'сонинке',
 				'so' => 'сомали',
 				'sq' => 'албан',
 				'sr' => 'серб',
 				'srn' => 'сранан тонго',
 				'ss' => 'свати',
 				'ssy' => 'саһо',
 				'st' => 'сесото',
 				'su' => 'сундан',
 				'suk' => 'сукума',
 				'sv' => 'исвеч',
 				'sw' => 'суаһили',
 				'sw_CD' => 'Конго суаһилиҹәси',
 				'swb' => 'комор',
 				'syr' => 'сурија',
 				'ta' => 'тамил',
 				'te' => 'телугу',
 				'tem' => 'тимне',
 				'teo' => 'тесо',
 				'tet' => 'тетум',
 				'tg' => 'таҹик',
 				'th' => 'тај',
 				'ti' => 'тигрин',
 				'tig' => 'тигре',
 				'tk' => 'түркмән',
 				'tlh' => 'клингон',
 				'tn' => 'свана',
 				'to' => 'тонган',
 				'tpi' => 'ток писин',
 				'tr' => 'түрк',
 				'trv' => 'тароко',
 				'ts' => 'сонга',
 				'tt' => 'татар',
 				'tum' => 'тумбука',
 				'tvl' => 'тувалу',
 				'twq' => 'тасаваг',
 				'ty' => 'тахити',
 				'tyv' => 'тувинјан',
 				'tzm' => 'Мәркәзи Атлас тамазиҹәси',
 				'udm' => 'удмурт',
 				'ug' => 'ујғур',
 				'uk' => 'украјна',
 				'umb' => 'умбунду',
 				'und' => 'намәлум дил',
 				'ur' => 'урду',
 				'uz' => 'өзбәк',
 				'vai' => 'ваи',
 				've' => 'венда',
 				'vi' => 'вјетнам',
 				'vo' => 'волапүк',
 				'vun' => 'вунјо',
 				'wa' => 'валун',
 				'wae' => 'валлес',
 				'wal' => 'валамо',
 				'war' => 'варај',
 				'wo' => 'волоф',
 				'xal' => 'калмык',
 				'xh' => 'хоса',
 				'xog' => 'сога',
 				'yav' => 'јангбен',
 				'ybb' => 'јемба',
 				'yi' => 'идиш',
 				'yo' => 'јоруба',
 				'yue' => 'кантон',
 				'zgh' => 'тамази',
 				'zh' => 'чин',
 				'zh_Hans' => 'садәләшмиш чин',
 				'zh_Hant' => 'әнәнәви чин',
 				'zu' => 'зулу',
 				'zun' => 'зуни',
 				'zxx' => 'дил мәзмуну јохдур',
 				'zza' => 'заза',

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
			'Cyrl' => 'Кирил',

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
			'001' => 'Дүнја',
 			'002' => 'Африка',
 			'003' => 'Шимали Америка',
 			'005' => 'Ҹәнуби Америка',
 			'009' => 'Океанија',
 			'011' => 'Гәрби Африка',
 			'013' => 'Мәркәзи Америка',
 			'014' => 'Шәрги Африка',
 			'015' => 'Шимали Африка',
 			'017' => 'Мәркәзи Африка',
 			'018' => 'Ҹәнуби Африка',
 			'019' => 'Америка',
 			'021' => 'Шимал Америкасы',
 			'029' => 'Кариб',
 			'030' => 'Шәрги Асија',
 			'034' => 'Ҹәнуби Асија',
 			'035' => 'Ҹәнуб-Шәрги Асија',
 			'039' => 'Ҹәнуби Авропа',
 			'053' => 'Австралазија',
 			'054' => 'Меланезија',
 			'057' => 'Микронезија Реҝиону',
 			'061' => 'Полинезија',
 			'142' => 'Асија',
 			'143' => 'Мәркәзи Асија',
 			'145' => 'Гәрби Асија',
 			'150' => 'Авропа',
 			'151' => 'Шәрги Авропа',
 			'154' => 'Шимали Авропа',
 			'155' => 'Гәрби Авропа',
 			'419' => 'Латын Америкасы',
 			'AC' => 'Аскенсон адасы',
 			'AD' => 'Андорра',
 			'AE' => 'Бирләшмиш Әрәб Әмирликләри',
 			'AF' => 'Әфганыстан',
 			'AG' => 'Антигуа вә Барбуда',
 			'AI' => 'Анҝилја',
 			'AL' => 'Албанија',
 			'AM' => 'Ермәнистан',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктика',
 			'AR' => 'Арҝентина',
 			'AS' => 'Америка Самоасы',
 			'AT' => 'Австрија',
 			'AU' => 'Австралија',
 			'AW' => 'Аруба',
 			'AX' => 'Аланд адалары',
 			'AZ' => 'Азәрбајҹан',
 			'BA' => 'Боснија вә Һерсеговина',
 			'BB' => 'Барбадос',
 			'BD' => 'Бангладеш',
 			'BE' => 'Белчика',
 			'BF' => 'Буркина Фасо',
 			'BG' => 'Болгарыстан',
 			'BH' => 'Бәһрејн',
 			'BI' => 'Бурунди',
 			'BJ' => 'Бенин',
 			'BL' => 'Сент-Бартелеми',
 			'BM' => 'Бермуд адалары',
 			'BN' => 'Брунеј',
 			'BO' => 'Боливија',
 			'BR' => 'Бразилија',
 			'BS' => 'Баһам адалары',
 			'BT' => 'Бутан',
 			'BV' => 'Буве адасы',
 			'BW' => 'Ботсвана',
 			'BY' => 'Беларус',
 			'BZ' => 'Белиз',
 			'CA' => 'Канада',
 			'CC' => 'Кокос (Килинг) адалары',
 			'CD' => 'Конго-Киншаса',
 			'CD@alt=variant' => 'Конго (КДР)',
 			'CF' => 'Мәркәзи Африка Республикасы',
 			'CG' => 'Конго-Браззавил',
 			'CG@alt=variant' => 'Конго (Республика)',
 			'CH' => 'Исвечрә',
 			'CI' => 'Kотд’ивуар',
 			'CK' => 'Кук адалары',
 			'CL' => 'Чили',
 			'CM' => 'Камерун',
 			'CN' => 'Чин',
 			'CO' => 'Колумбија',
 			'CP' => 'Клиппертон адасы',
 			'CR' => 'Коста Рика',
 			'CU' => 'Куба',
 			'CV' => 'Кабо-Верде',
 			'CW' => 'Курасао',
 			'CX' => 'Милад адасы',
 			'CY' => 'Кипр',
 			'CZ' => 'Чехија',
 			'CZ@alt=variant' => 'Чех Республикасы',
 			'DE' => 'Алманија',
 			'DG' => 'Диего Гарсија',
 			'DJ' => 'Ҹибути',
 			'DK' => 'Данимарка',
 			'DM' => 'Доминика',
 			'DO' => 'Доминикан Республикасы',
 			'DZ' => 'Әлҹәзаир',
 			'EA' => 'Сеута вә Мелилја',
 			'EC' => 'Еквадор',
 			'EE' => 'Естонија',
 			'EG' => 'Мисир',
 			'ER' => 'Еритреја',
 			'ES' => 'Испанија',
 			'ET' => 'Ефиопија',
 			'EU' => 'Авропа Бирлији',
 			'FI' => 'Финландија',
 			'FJ' => 'Фиҹи',
 			'FK' => 'Фолкленд адалары',
 			'FK@alt=variant' => 'Фолкленд адалары (Малвин адалары)',
 			'FM' => 'Микронезија',
 			'FO' => 'Фарер адалары',
 			'FR' => 'Франса',
 			'GA' => 'Габон',
 			'GB' => 'Бирләшмиш Краллыг',
 			'GB@alt=short' => 'БК',
 			'GD' => 'Гренада',
 			'GE' => 'Ҝүрҹүстан',
 			'GF' => 'Франса Гвианасы',
 			'GG' => 'Ҝернси',
 			'GH' => 'Гана',
 			'GI' => 'Ҹәбәллүтариг',
 			'GL' => 'Гренландија',
 			'GM' => 'Гамбија',
 			'GN' => 'Гвинеја',
 			'GP' => 'Гваделупа',
 			'GQ' => 'Екваториал Гвинеја',
 			'GR' => 'Јунаныстан',
 			'GS' => 'Ҹәнуби Ҹорҹија вә Ҹәнуби Сендвич адалары',
 			'GT' => 'Гватемала',
 			'GU' => 'Гуам',
 			'GW' => 'Гвинеја-Бисау',
 			'GY' => 'Гајана',
 			'HK' => 'Һонк Конг Хүсуси Инзибати Әрази Чин',
 			'HK@alt=short' => 'Һонг Конг',
 			'HM' => 'Һерд вә Макдоналд адалары',
 			'HN' => 'Һондурас',
 			'HR' => 'Хорватија',
 			'HT' => 'Һаити',
 			'HU' => 'Маҹарыстан',
 			'IC' => 'Канар адалары',
 			'ID' => 'Индонезија',
 			'IE' => 'Ирландија',
 			'IL' => 'Исраил',
 			'IM' => 'Мен адасы',
 			'IN' => 'Һиндистан',
 			'IO' => 'Британтјанын Һинд Океаны Әразиси',
 			'IQ' => 'Ираг',
 			'IR' => 'Иран',
 			'IS' => 'Исландија',
 			'IT' => 'Италија',
 			'JE' => 'Ҹерси',
 			'JM' => 'Јамајка',
 			'JO' => 'Иорданија',
 			'JP' => 'Јапонија',
 			'KE' => 'Кенија',
 			'KG' => 'Гырғызыстан',
 			'KH' => 'Камбоҹа',
 			'KI' => 'Кирибати',
 			'KM' => 'Комор адалары',
 			'KN' => 'Сент-Китс вә Невис',
 			'KP' => 'Шимали Кореја',
 			'KR' => 'Ҹәнуби Кореја',
 			'KW' => 'Күвејт',
 			'KY' => 'Кајман адалары',
 			'KZ' => 'Газахыстан',
 			'LA' => 'Лаос',
 			'LB' => 'Ливан',
 			'LC' => 'Сент-Лусија',
 			'LI' => 'Лихтенштејн',
 			'LK' => 'Шри-Ланка',
 			'LR' => 'Либерија',
 			'LS' => 'Лесото',
 			'LT' => 'Литва',
 			'LU' => 'Лүксембург',
 			'LV' => 'Латвија',
 			'LY' => 'Ливија',
 			'MA' => 'Мәракеш',
 			'MC' => 'Монако',
 			'MD' => 'Молдова',
 			'ME' => 'Монтенегро',
 			'MF' => 'Сент Мартин',
 			'MG' => 'Мадагаскар',
 			'MH' => 'Маршал адалары',
 			'MK@alt=variant' => 'Македонија (КЈРМ)',
 			'ML' => 'Мали',
 			'MM' => 'Мјанма',
 			'MN' => 'Монголустан',
 			'MO' => 'Макао Хүсуси Инзибати Әрази Чин',
 			'MO@alt=short' => 'Макао',
 			'MP' => 'Шимали Мариан адалары',
 			'MQ' => 'Мартиник',
 			'MR' => 'Мавританија',
 			'MS' => 'Монсерат',
 			'MT' => 'Малта',
 			'MU' => 'Маврики',
 			'MV' => 'Малдив адалары',
 			'MW' => 'Малави',
 			'MX' => 'Мексика',
 			'MY' => 'Малајзија',
 			'MZ' => 'Мозамбик',
 			'NA' => 'Намибија',
 			'NC' => 'Јени Каледонија',
 			'NE' => 'Ниҝер',
 			'NF' => 'Норфолк адасы',
 			'NG' => 'Ниҝерија',
 			'NI' => 'Никарагуа',
 			'NL' => 'Нидерланд',
 			'NO' => 'Норвеч',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NU' => 'Ниуе',
 			'NZ' => 'Јени Зеландија',
 			'OM' => 'Оман',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PF' => 'Франса Полинезијасы',
 			'PG' => 'Папуа-Јени Гвинеја',
 			'PH' => 'Филиппин',
 			'PK' => 'Пакистан',
 			'PL' => 'Полша',
 			'PM' => 'Мүгәддәс Пјер вә Микелон',
 			'PN' => 'Питкерн адалары',
 			'PR' => 'Пуерто Рико',
 			'PT' => 'Португалија',
 			'PW' => 'Палау',
 			'PY' => 'Парагвај',
 			'QA' => 'Гәтәр',
 			'QO' => 'Узаг Океанија',
 			'RE' => 'Рејунјон',
 			'RO' => 'Румынија',
 			'RS' => 'Сербија',
 			'RU' => 'Русија',
 			'RW' => 'Руанда',
 			'SA' => 'Сәудијјә Әрәбистаны',
 			'SB' => 'Соломон адалары',
 			'SC' => 'Сејшел адалары',
 			'SD' => 'Судан',
 			'SE' => 'Исвеч',
 			'SG' => 'Сингапур',
 			'SH' => 'Мүгәддәс Јелена',
 			'SI' => 'Словенија',
 			'SJ' => 'Свалбард вә Јан-Мајен',
 			'SK' => 'Словакија',
 			'SL' => 'Сјерра-Леоне',
 			'SM' => 'Сан-Марино',
 			'SN' => 'Сенегал',
 			'SO' => 'Сомали',
 			'SR' => 'Суринам',
 			'SS' => 'Ҹәнуби Судан',
 			'ST' => 'Сан-Томе вә Принсипи',
 			'SV' => 'Салвадор',
 			'SX' => 'Синт-Мартен',
 			'SY' => 'Сурија',
 			'SZ' => 'Свазиленд',
 			'TA' => 'Тристан да Кунја',
 			'TC' => 'Төркс вә Кајкос адалары',
 			'TD' => 'Чад',
 			'TF' => 'Франсанын Ҹәнуб Әразиләри',
 			'TG' => 'Того',
 			'TH' => 'Таиланд',
 			'TJ' => 'Таҹикистан',
 			'TK' => 'Токелау',
 			'TL' => 'Шәрги Тимор',
 			'TM' => 'Түркмәнистан',
 			'TN' => 'Тунис',
 			'TO' => 'Тонга',
 			'TR' => 'Түркијә',
 			'TT' => 'Тринидад вә Тобаго',
 			'TV' => 'Тувалу',
 			'TW' => 'Тајван',
 			'TZ' => 'Танзанија',
 			'UA' => 'Украјна',
 			'UG' => 'Уганда',
 			'UM' => 'АБШ-а бағлы кичик адаҹыглар',
 			'US' => 'Америка Бирләшмиш Штатлары',
 			'US@alt=short' => 'АБШ',
 			'UY' => 'Уругвај',
 			'UZ' => 'Өзбәкистан',
 			'VA' => 'Ватикан',
 			'VC' => 'Сент-Винсент вә Гренадинләр',
 			'VE' => 'Венесуела',
 			'VG' => 'Британијанын Вирҝин адалары',
 			'VI' => 'АБШ Вирҝин адалары',
 			'VN' => 'Вјетнам',
 			'VU' => 'Вануату',
 			'WF' => 'Уоллис вә Футуна',
 			'WS' => 'Самоа',
 			'XK' => 'Косово',
 			'YE' => 'Јәмән',
 			'YT' => 'Мајот',
 			'ZA' => 'Ҹәнуб Африка',
 			'ZM' => 'Замбија',
 			'ZW' => 'Зимбабве',
 			'ZZ' => 'Намәлум Реҝион',

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Дил: {0}',
 			'script' => 'Скрипт: {0}',
 			'region' => 'Реҝион: {0}',

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
			auxiliary => qr{[ц щ ъ ь э ю я]},
			index => ['А', 'Ә', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'Ј', 'К', 'Ҝ', 'Л', 'М', 'Н', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ч', 'Ҹ', 'Ш', 'Ы'],
			main => qr{[а ә б в г ғ д е ж з и й ј к ҝ л м н о ө п р с т у ү ф х һ ч ҹ ш ы]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Ә', 'Б', 'В', 'Г', 'Ғ', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'Ј', 'К', 'Ҝ', 'Л', 'М', 'Н', 'О', 'Ө', 'П', 'Р', 'С', 'Т', 'У', 'Ү', 'Ф', 'Х', 'Һ', 'Ч', 'Ҹ', 'Ш', 'Ы'], };
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
	default		=> qq{‹},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{›},
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
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
					'default' => '#,##0.###',
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
		'AZN' => {
			symbol => '₼',
			display_name => {
				'currency' => q(манат),
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
							'јан',
							'фев',
							'мар',
							'апр',
							'май',
							'ијн',
							'ијл',
							'авг',
							'сен',
							'окт',
							'ној',
							'дек'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'јанвар',
							'феврал',
							'март',
							'апрел',
							'май',
							'ијун',
							'ијул',
							'август',
							'сентјабр',
							'октјабр',
							'нојабр',
							'декабр'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'јан',
							'фев',
							'мар',
							'апр',
							'май',
							'ијн',
							'ијл',
							'авг',
							'сен',
							'окт',
							'ној',
							'дек'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Јанвар',
							'Феврал',
							'Март',
							'Апрел',
							'Май',
							'Ијун',
							'Ијул',
							'Август',
							'Сентјабр',
							'Октјабр',
							'Нојабр',
							'Декабр'
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
						mon => 'Б.Е.',
						tue => 'Ч.А.',
						wed => 'Ч.',
						thu => 'Ҹ.А.',
						fri => 'Ҹ.',
						sat => 'Ш.',
						sun => 'Б.'
					},
					narrow => {
						mon => '1',
						tue => '2',
						wed => '3',
						thu => '4',
						fri => '5',
						sat => '6',
						sun => '7'
					},
					short => {
						mon => 'Б.Е.',
						tue => 'Ч.А.',
						wed => 'Ч.',
						thu => 'Ҹ.А.',
						fri => 'Ҹ.',
						sat => 'Ш.',
						sun => 'Б.'
					},
					wide => {
						mon => 'базар ертәси',
						tue => 'чәршәнбә ахшамы',
						wed => 'чәршәнбә',
						thu => 'ҹүмә ахшамы',
						fri => 'ҹүмә',
						sat => 'шәнбә',
						sun => 'базар'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Б.Е.',
						tue => 'Ч.А.',
						wed => 'Ч.',
						thu => 'Ҹ.А.',
						fri => 'Ҹ.',
						sat => 'Ш.',
						sun => 'Б.'
					},
					narrow => {
						mon => '1',
						tue => '2',
						wed => '3',
						thu => '4',
						fri => '5',
						sat => '6',
						sun => '7'
					},
					short => {
						mon => 'Б.Е.',
						tue => 'Ч.А.',
						wed => 'Ч.',
						thu => 'Ҹ.А.',
						fri => 'Ҹ.',
						sat => 'Ш.',
						sun => 'Б.'
					},
					wide => {
						mon => 'базар ертәси',
						tue => 'чәршәнбә ахшамы',
						wed => 'чәршәнбә',
						thu => 'ҹүмә ахшамы',
						fri => 'ҹүмә',
						sat => 'шәнбә',
						sun => 'базар'
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
					abbreviated => {0 => '1-ҹи кв.',
						1 => '2-ҹи кв.',
						2 => '3-ҹү кв.',
						3 => '4-ҹү кв.'
					},
					wide => {0 => '1-ҹи квартал',
						1 => '2-ҹи квартал',
						2 => '3-ҹү квартал',
						3 => '4-ҹү квартал'
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
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'morning2' if $time >= 600
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
					'noon' => q{ҝүнорта},
					'night2' => q{ҝеҹә},
					'morning2' => q{сәһәр},
					'afternoon1' => q{ҝүндүз},
					'evening1' => q{ахшамүстү},
					'morning1' => q{сүбһ},
					'am' => q{АМ},
					'night1' => q{ахшам},
					'midnight' => q{ҝеҹәјары},
					'pm' => q{ПМ},
				},
				'wide' => {
					'night1' => q{ахшам},
					'midnight' => q{ҝеҹәјары},
					'pm' => q{ПМ},
					'noon' => q{ҝүнорта},
					'night2' => q{ҝеҹә},
					'morning2' => q{сәһәр},
					'evening1' => q{ахшамүстү},
					'afternoon1' => q{ҝүндүз},
					'morning1' => q{сүбһ},
					'am' => q{АМ},
				},
				'narrow' => {
					'night2' => q{ҝеҹә},
					'morning2' => q{сәһәр},
					'noon' => q{ҝ},
					'am' => q{а},
					'evening1' => q{ахшамүстү},
					'morning1' => q{сүбһ},
					'afternoon1' => q{ҝүндүз},
					'night1' => q{ахшам},
					'pm' => q{п},
					'midnight' => q{ҝеҹәјары},
				},
			},
			'stand-alone' => {
				'wide' => {
					'noon' => q{ҝүнорта},
					'morning2' => q{сәһәр},
					'night2' => q{ҝеҹә},
					'evening1' => q{ахшамүстү},
					'afternoon1' => q{ҝүндүз},
					'morning1' => q{сүбһ},
					'am' => q{АМ},
					'night1' => q{ахшам},
					'midnight' => q{ҝеҹәјары},
					'pm' => q{ПМ},
				},
				'narrow' => {
					'night2' => q{ҝеҹә},
					'morning2' => q{сәһәр},
					'noon' => q{ҝүнорта},
					'evening1' => q{ахшамүстү},
					'afternoon1' => q{ҝүндүз},
					'morning1' => q{сүбһ},
					'night1' => q{ахшам},
					'midnight' => q{ҝеҹәјары},
				},
				'abbreviated' => {
					'evening1' => q{ахшамүстү},
					'afternoon1' => q{ҝүндүз},
					'morning1' => q{сүбһ},
					'noon' => q{ҝүнорта},
					'night2' => q{ҝеҹә},
					'morning2' => q{сәһәр},
					'midnight' => q{ҝеҹәјары},
					'night1' => q{ахшам},
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
				'0' => 'е.ә.',
				'1' => 'ј.е.'
			},
			wide => {
				'0' => 'ерамыздан әввәл',
				'1' => 'јени ера'
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
			'full' => q{G d MMMM y, EEEE},
			'long' => q{G d MMMM, y},
			'medium' => q{G d MMM y},
			'short' => q{GGGGG dd.MM.y},
		},
		'gregorian' => {
			'full' => q{d MMMM y, EEEE},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.yy},
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
		'gregorian' => {
			Ed => q{d E},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			MEd => q{dd.MM, E},
			MMM => q{LLL},
			MMMEd => q{d MMM, E},
			MMMMW => q{MMM, W 'һәфтә'},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			yM => q{MM.y},
			yMEd => q{dd.MM.y, E},
			yMMM => q{MMM, y},
			yMMMEd => q{d MMM y, E},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yw => q{Y, w 'һәфтә'},
		},
		'generic' => {
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			MEd => q{dd.MM, E},
			MMM => q{LLL},
			MMMEd => q{d MMM, E},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			yyyyM => q{GGGGG MM y},
			yyyyMEd => q{GGGGG dd.MM.y, E},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G d MMM y, E},
			yyyyMMMd => q{G d MMM y},
			yyyyMd => q{GGGGG dd.MM.y},
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
				M => q{dd.MM, E – dd.MM, E},
				d => q{dd.MM, E – dd.MM, E},
			},
			MMMEd => {
				M => q{d MMM, E – d MMM, E},
				d => q{d MMM, E – d MMM, E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y, E – dd.MM.y, E},
				d => q{dd.MM.y, E – dd.MM.y, E},
				y => q{dd.MM.y, E – dd.MM.y, E},
			},
			yMMM => {
				M => q{MMM – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y, E – d MMM, E},
				d => q{d MMM y, E – d MMM, E},
				y => q{d MMM y, E – d MMM y, E},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM y – d MMM},
				d => q{y MMM d–d},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
		'generic' => {
			MEd => {
				M => q{dd.MM, E – dd.MM, E},
				d => q{dd.MM, E – dd.MM, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			yM => {
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			yMEd => {
				M => q{GGGGG dd/MM/y , E – dd/MM/y, E},
				d => q{GGGGG dd/MM/y , E – dd/MM/y, E},
				y => q{GGGGG dd/MM/y , E – dd/MM/y, E},
			},
			yMMM => {
				M => q{G MMM–MMM y},
				y => q{G MMM y – MMM y},
			},
			yMMMEd => {
				M => q{G d MMM y, E – d MMM, E},
				d => q{G d MMM y, E – d MMM, E},
				y => q{G d MMM y, E – d MMM y, E},
			},
			yMMMM => {
				M => q{G MMMM y –MMMM},
				y => q{G MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{G d MMM y – d MMM},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			yMd => {
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
