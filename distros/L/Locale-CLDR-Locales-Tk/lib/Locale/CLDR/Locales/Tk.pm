=head1

Locale::CLDR::Locales::Tk - Package for language Turkmen

=cut

package Locale::CLDR::Locales::Tk;
# This file auto generated from Data\common\main\tk.xml
#	on Sun  5 Aug  6:24:30 pm GMT

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
				'aa' => 'afar dili',
 				'ab' => 'abhaz dili',
 				'ace' => 'açeh dili',
 				'ada' => 'adangme dili',
 				'ady' => 'adygeý dili',
 				'af' => 'afrikaans dili',
 				'agq' => 'ahem dili',
 				'ain' => 'aýn dili',
 				'ak' => 'akan dili',
 				'ale' => 'aleut dili',
 				'alt' => 'günorta Altaý dili',
 				'am' => 'amhar dili',
 				'an' => 'aragon dili',
 				'anp' => 'angika dili',
 				'ar' => 'arap dili',
 				'ar_001' => 'häzirki zaman standart arap dili',
 				'arn' => 'mapuçe dili',
 				'arp' => 'arapaho dili',
 				'as' => 'assam dili',
 				'asa' => 'asu dili',
 				'ast' => 'asturiý dili',
 				'av' => 'awar dili',
 				'awa' => 'awadhi dili',
 				'ay' => 'aýmara dili',
 				'az' => 'azerbaýjan dili',
 				'az@alt=short' => 'azeri dili',
 				'ba' => 'başgyrt dili',
 				'ban' => 'baliý dili',
 				'bas' => 'basaa dili',
 				'be' => 'belarus dili',
 				'bem' => 'bemba dili',
 				'bez' => 'bena dili',
 				'bg' => 'bolgar dili',
 				'bho' => 'bhojpuri dili',
 				'bi' => 'bislama dili',
 				'bin' => 'bini dili',
 				'bla' => 'siksika dili',
 				'bm' => 'bamana',
 				'bn' => 'bengal dili',
 				'bo' => 'tibet dili',
 				'br' => 'breton dili',
 				'brx' => 'bodo dili',
 				'bs' => 'boşnak dili',
 				'bug' => 'bugiý dili',
 				'byn' => 'blin dili',
 				'ca' => 'katalan dili',
 				'ce' => 'çeçen dili',
 				'ceb' => 'sebuan dili',
 				'cgg' => 'kiga',
 				'ch' => 'çamorro',
 				'chk' => 'çuuk dili',
 				'chm' => 'mariý dili',
 				'cho' => 'çokto',
 				'chr' => 'çeroki',
 				'chy' => 'şaýenn dili',
 				'ckb' => 'merkezi kürt dili',
 				'co' => 'korsikan dili',
 				'crs' => 'seselwa kreole-fransuz dili',
 				'cs' => 'çeh dili',
 				'cu' => 'buthana slaw dili',
 				'cv' => 'çuwaş dili',
 				'cy' => 'walliý dili',
 				'da' => 'daniýa dili',
 				'dak' => 'dakota dili',
 				'dar' => 'dargi dili',
 				'dav' => 'taita dili',
 				'de' => 'nemes dili',
 				'de_CH' => 'nemes dili (Daglyk Şweýsariýa)',
 				'dgr' => 'dogrib dili',
 				'dje' => 'zarma dili',
 				'dsb' => 'aşaky lužits dili',
 				'dua' => 'duala dili',
 				'dv' => 'diwehi dili',
 				'dyo' => 'ýola-Fonyi dili',
 				'dz' => 'dzong-ke dili',
 				'dzg' => 'daza dili',
 				'ebu' => 'embu dili',
 				'ee' => 'ewe dili',
 				'efi' => 'efik dili',
 				'eka' => 'ekajuk dili',
 				'el' => 'grek dili',
 				'en' => 'iňlis dili',
 				'en_GB' => 'iňlis dili (Beýik Britaniýa)',
 				'en_GB@alt=short' => 'iňlis dili (Birleşen Korollyk)',
 				'en_US' => 'iňlis dili (Amerika)',
 				'en_US@alt=short' => 'iňlis dili (ABŞ)',
 				'eo' => 'esperanto dili',
 				'es' => 'ispan dili',
 				'es_419' => 'ispan dili (Günorta Amerika)',
 				'es_ES' => 'ispan dili (Ýewropa)',
 				'et' => 'eston dili',
 				'eu' => 'bask dili',
 				'ewo' => 'ewondo dili',
 				'fa' => 'pars dili',
 				'ff' => 'fula dili',
 				'fi' => 'fin dili',
 				'fil' => 'filippin dili',
 				'fj' => 'fiji dili',
 				'fo' => 'farer dili',
 				'fon' => 'fon dili',
 				'fr' => 'fransuz dili',
 				'fur' => 'friul dili',
 				'fy' => 'günbatar friz dili',
 				'ga' => 'irland dili',
 				'gaa' => 'ga dili',
 				'gd' => 'şotland kelt dili',
 				'gez' => 'geez dili',
 				'gil' => 'gilbert dili',
 				'gl' => 'galisiý dili',
 				'gn' => 'guarani dili',
 				'gor' => 'gorontalo dili',
 				'gsw' => 'nemes dili (Şweýsariýa)',
 				'gu' => 'gujarati dili',
 				'guz' => 'gusii dili',
 				'gv' => 'men dili',
 				'gwi' => 'gwiçin dili',
 				'ha' => 'hausa dili',
 				'haw' => 'gawaý dili',
 				'he' => 'ýewreý dili',
 				'hi' => 'hindi dili',
 				'hil' => 'hiligaýnon dili',
 				'hmn' => 'hmong dili',
 				'hr' => 'horwat dili',
 				'hsb' => 'ýokarky lužits dili',
 				'ht' => 'gaiti kreol dili',
 				'hu' => 'wenger dili',
 				'hup' => 'hupa',
 				'hy' => 'ermeni dili',
 				'hz' => 'gerero dili',
 				'ia' => 'interlingwa dili',
 				'iba' => 'iban dili',
 				'ibb' => 'ibibio dili',
 				'id' => 'indonez dili',
 				'ig' => 'igbo dili',
 				'ii' => 'syçuan-i dili',
 				'ilo' => 'iloko dili',
 				'inh' => 'inguş dili',
 				'io' => 'ido dili',
 				'is' => 'island dili',
 				'it' => 'italýan dili',
 				'iu' => 'inuktitut dili',
 				'ja' => 'ýapon dili',
 				'jbo' => 'lojban dili',
 				'jgo' => 'ngomba dili',
 				'jmc' => 'maçame dili',
 				'jv' => 'ýawa dili',
 				'ka' => 'gruzin dili',
 				'kab' => 'kabil dili',
 				'kac' => 'kaçin dili',
 				'kaj' => 'ju dili',
 				'kam' => 'kamba dili',
 				'kbd' => 'kabardin dili',
 				'kcg' => 'tiap dili',
 				'kde' => 'makonde dili',
 				'kea' => 'kabuwerdianu dili',
 				'kfo' => 'koro dili',
 				'kha' => 'khasi dili',
 				'khq' => 'koýra-Çini dili',
 				'ki' => 'kikuýu dili',
 				'kj' => 'kwanýama dili',
 				'kk' => 'gazak dili',
 				'kkj' => 'kako dili',
 				'kl' => 'grenland dili',
 				'kln' => 'kalenjin dili',
 				'km' => 'khmer dili',
 				'kmb' => 'kimbundu dili',
 				'kn' => 'kannada dili',
 				'ko' => 'koreý dili',
 				'kok' => 'konkani dili',
 				'kpe' => 'kpelle dili',
 				'kr' => 'kanuri',
 				'krc' => 'karaçaý-balkar dili',
 				'krl' => 'karel dili',
 				'kru' => 'kuruh dili',
 				'ks' => 'kaşmiri dili',
 				'ksb' => 'şambala dili',
 				'ksf' => 'bafia dili',
 				'ksh' => 'keln dili',
 				'ku' => 'kürt dili',
 				'kum' => 'kumyk dili',
 				'kv' => 'komi dili',
 				'kw' => 'korn dili',
 				'ky' => 'gyrgyz dili',
 				'la' => 'latyn dili',
 				'lad' => 'ladino dili',
 				'lag' => 'langi dili',
 				'lb' => 'lýuksemburg dili',
 				'lez' => 'lezgin dili',
 				'lg' => 'ganda dili',
 				'li' => 'limburg dili',
 				'lkt' => 'lakota dili',
 				'ln' => 'lingala dili',
 				'lo' => 'laos dili',
 				'loz' => 'lozi dili',
 				'lrc' => 'demirgazyk luri dili',
 				'lt' => 'litwa dili',
 				'lu' => 'luba-Katanga dili',
 				'lua' => 'luba-Lulua dili',
 				'lun' => 'lunda dili',
 				'luo' => 'luo dili',
 				'lus' => 'mizo dili',
 				'luy' => 'luýýa dili',
 				'lv' => 'latyş dili',
 				'mad' => 'madur dili',
 				'mag' => 'magahi dili',
 				'mai' => 'maýthili dili',
 				'mak' => 'makasar dili',
 				'mas' => 'masai dili',
 				'mdf' => 'mokşa dili',
 				'men' => 'mende dili',
 				'mer' => 'meru dili',
 				'mfe' => 'morisýen dili',
 				'mg' => 'malagasiý dili',
 				'mgh' => 'makua-Mitto dili',
 				'mgo' => 'meta dili',
 				'mh' => 'marşall dili',
 				'mi' => 'maori dili',
 				'mic' => 'mikmak dili',
 				'min' => 'minangkabau dili',
 				'mk' => 'makedon dili',
 				'ml' => 'malaýalam dili',
 				'mn' => 'mongol dili',
 				'mni' => 'manipuri dili',
 				'moh' => 'mogauk dili',
 				'mos' => 'mossi dili',
 				'mr' => 'marathi dili',
 				'ms' => 'malaý dili',
 				'mt' => 'malta dili',
 				'mua' => 'mundang dili',
 				'mul' => 'birnäçe dil',
 				'mus' => 'krik dili',
 				'mwl' => 'mirand dili',
 				'my' => 'birma dili',
 				'myv' => 'erzýan dili',
 				'mzn' => 'mazanderan dili',
 				'na' => 'nauru dili',
 				'nap' => 'neapolitan dili',
 				'naq' => 'nama dili',
 				'nb' => 'norwegiýa bukmol dili',
 				'nd' => 'demirgazyk ndebele dili',
 				'ne' => 'nepal dili',
 				'new' => 'newari dili',
 				'ng' => 'ndonga dili',
 				'nia' => 'nias dili',
 				'niu' => 'niue dili',
 				'nl' => 'niderland dili',
 				'nl_BE' => 'flamand dili',
 				'nmg' => 'kwasio dili',
 				'nn' => 'norwegiýa nýunorsk dili',
 				'nnh' => 'ngembun dili',
 				'nog' => 'nogaý dili',
 				'nqo' => 'nko dili',
 				'nr' => 'günorta ndebele dili',
 				'nso' => 'demirgazyk soto dili',
 				'nus' => 'nuer dili',
 				'nv' => 'nawaho dili',
 				'ny' => 'nýanja dili',
 				'nyn' => 'nýankole dili',
 				'oc' => 'oksitan dili',
 				'om' => 'oromo dili',
 				'or' => 'oriýa dili',
 				'os' => 'osetin dili',
 				'pa' => 'penjab dili',
 				'pag' => 'pangansinan dili',
 				'pam' => 'kapampangan dili',
 				'pap' => 'papýamento dili',
 				'pau' => 'palau dili',
 				'pcm' => 'nigeriý-pijin dili',
 				'pl' => 'polýak dili',
 				'prg' => 'prussiýa dili',
 				'ps' => 'peştun dili',
 				'pt' => 'portugal dili',
 				'pt_PT' => 'portugal dili (Ýewropa)',
 				'qu' => 'keçua dili',
 				'quc' => 'kiçe dili',
 				'rap' => 'rapanuý dili',
 				'rar' => 'kuk dili',
 				'rm' => 'retoroman dili',
 				'rn' => 'rundi dili',
 				'ro' => 'rumyn dili',
 				'ro_MD' => 'moldaw dili',
 				'rof' => 'rombo dili',
 				'root' => 'kök',
 				'ru' => 'rus dili',
 				'rup' => 'aromun dili',
 				'rw' => 'kinýaruanda dili',
 				'rwk' => 'rwa dili',
 				'sa' => 'sanskrit dili',
 				'sad' => 'sandawe dili',
 				'sah' => 'ýakut dili',
 				'saq' => 'samburu dili',
 				'sat' => 'santali dili',
 				'sba' => 'ngambaý dili',
 				'sbp' => 'sangu dili',
 				'sc' => 'sardin dili',
 				'scn' => 'sisiliýa dili',
 				'sco' => 'şotland dili',
 				'sd' => 'sindhi dili',
 				'se' => 'demirgazyk saam dili',
 				'seh' => 'sena dili',
 				'ses' => 'koýraboro-Senni dili',
 				'sg' => 'sango dili',
 				'shi' => 'tahelhit dili',
 				'shn' => 'şan dili',
 				'si' => 'singal dili',
 				'sk' => 'slowak dili',
 				'sl' => 'slowen dili',
 				'sm' => 'samoa dili',
 				'sma' => 'günorta saam dili',
 				'smj' => 'lule-saam dili',
 				'smn' => 'inari-saam dili',
 				'sms' => 'skolt-saam dili',
 				'sn' => 'şona dili',
 				'snk' => 'soninke dili',
 				'so' => 'somali dili',
 				'sq' => 'alban dili',
 				'sr' => 'serb dili',
 				'srn' => 'sranan-tongo dili',
 				'ss' => 'swati dili',
 				'ssy' => 'saho dili',
 				'st' => 'günorta Soto dili',
 				'su' => 'sundan dili',
 				'suk' => 'sukuma dili',
 				'sv' => 'şwed dili',
 				'sw' => 'suahili dili',
 				'sw_CD' => 'kongo suahili dili',
 				'swb' => 'komor dili',
 				'syr' => 'siriýa dili',
 				'ta' => 'tamil dili',
 				'te' => 'telugu dili',
 				'tem' => 'temne dili',
 				'teo' => 'teso dili',
 				'tet' => 'tetum dili',
 				'tg' => 'täjik dili',
 				'th' => 'taý dili',
 				'ti' => 'tigrinýa dili',
 				'tig' => 'tigre dili',
 				'tk' => 'türkmen dili',
 				'tlh' => 'klingon dili',
 				'tn' => 'tswana dili',
 				'to' => 'tongan dili',
 				'tpi' => 'tok-pisin dili',
 				'tr' => 'türk dili',
 				'trv' => 'taroko dili',
 				'ts' => 'tsonga dili',
 				'tt' => 'tatar dili',
 				'tum' => 'tumbuka dili',
 				'tvl' => 'tuwalu dili',
 				'twq' => 'tasawak dili',
 				'ty' => 'taiti dili',
 				'tyv' => 'tuwa dili',
 				'tzm' => 'orta-Atlas tamazight dili',
 				'udm' => 'udmurt dili',
 				'ug' => 'uýgur dili',
 				'uk' => 'ukrain dili',
 				'umb' => 'umbundu dili',
 				'und' => 'näbelli dil',
 				'ur' => 'urdu',
 				'uz' => 'özbek dili',
 				'vai' => 'wai dili',
 				've' => 'wenda dili',
 				'vi' => 'wýetnam dili',
 				'vo' => 'wolapýuk dili',
 				'vun' => 'wunýo dili',
 				'wa' => 'wallon dili',
 				'wae' => 'walzer dili',
 				'wal' => 'wolaýta dili',
 				'war' => 'waraý dili',
 				'wo' => 'wolof dili',
 				'xal' => 'galmyk dili',
 				'xh' => 'kosa dili',
 				'xog' => 'soga dili',
 				'yav' => 'ýangben dili',
 				'ybb' => 'ýemba dili',
 				'yi' => 'idiş dili',
 				'yo' => 'ýoruba dili',
 				'yue' => 'kanton dili',
 				'zgh' => 'standart Marokko tamazight dili',
 				'zh' => 'hytaý dili',
 				'zh_Hans' => 'ýönekeýleşdirilen hytaý dili',
 				'zh_Hant' => 'adaty hytaý dili',
 				'zu' => 'zulu dili',
 				'zun' => 'zuni dili',
 				'zxx' => 'dilçilige degişli mazmun ýok',
 				'zza' => 'zazaki dili',

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
			'Arab' => 'Arap elipbiýi',
 			'Armn' => 'Ermeni elipbiýi',
 			'Beng' => 'Bengal elipbiýi',
 			'Bopo' => 'Bopomofo elipbiýi',
 			'Brai' => 'Braýl elipbiýi',
 			'Cyrl' => 'Kiril elipbiýi',
 			'Deva' => 'Dewanagari elipbiýi',
 			'Ethi' => 'Efiop elipbiýi',
 			'Geor' => 'Gruzin elipbiýi',
 			'Grek' => 'Grek elipbiýi',
 			'Gujr' => 'Gujarati elipbiýi',
 			'Guru' => 'Gurmuhi elipbiýi',
 			'Hanb' => 'Bopomofo han elipbiýi',
 			'Hang' => 'Hangyl elipbiýi',
 			'Hani' => 'Han elipbiýi',
 			'Hans' => 'Ýönekeýleşdirilen',
 			'Hans@alt=stand-alone' => 'Ýönekeýleşdirilen han elipbiýi',
 			'Hant' => 'Adaty',
 			'Hant@alt=stand-alone' => 'Adaty han elipbiýi',
 			'Hebr' => 'Ýewreý elipbiýi',
 			'Hira' => 'Hiragana elipbiýi',
 			'Hrkt' => 'Ýapon bogun elipbiýleri',
 			'Jamo' => 'Jamo elipbiýi',
 			'Jpan' => 'Ýapon elipbiýi',
 			'Kana' => 'Katakana elipbiýi',
 			'Khmr' => 'Khmer elipbiýi',
 			'Knda' => 'Kannada elipbiýi',
 			'Kore' => 'Koreý elipbiýi',
 			'Laoo' => 'Laos elipbiýi',
 			'Latn' => 'Latyn elipbiýi',
 			'Mlym' => 'Malaýalam elipbiýi',
 			'Mong' => 'Mongol elipbiýi',
 			'Mymr' => 'Mýanma elipbiýi',
 			'Orya' => 'Oriýa elipbiýi',
 			'Sinh' => 'Singal elipbiýi',
 			'Taml' => 'Tamil elipbiýi',
 			'Telu' => 'Telugu elipbiýi',
 			'Thaa' => 'Taana elipbiýi',
 			'Thai' => 'Taý elipbiýi',
 			'Tibt' => 'Tibet elipbiýi',
 			'Zmth' => 'Matematiki belgiler',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Nyşanlar',
 			'Zxxx' => 'Ýazuwsyz',
 			'Zyyy' => 'Umumy',
 			'Zzzz' => 'Näbelli elipbiý',

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
			'001' => 'Dunýä',
 			'002' => 'Afrika',
 			'003' => 'Demirgazyk Amerika',
 			'005' => 'Günorta Amerika',
 			'009' => 'Okeaniýa',
 			'011' => 'Günbatar Afrika',
 			'013' => 'Orta Amerika',
 			'014' => 'Gündogar Afrika',
 			'015' => 'Demirgazyk Afrika',
 			'017' => 'Orta Afrika',
 			'018' => 'Afrikanyň günorta sebitleri',
 			'019' => 'Amerika',
 			'021' => 'Amerikanyň demirgazyk ýurtlary',
 			'029' => 'Karib basseýni',
 			'030' => 'Gündogar Aziýa',
 			'034' => 'Günorta Aziýa',
 			'035' => 'Günorta-gündogar Aziýa',
 			'039' => 'Günorta Ýewropa',
 			'053' => 'Awstralaziýa',
 			'054' => 'Melaneziýa',
 			'057' => 'Mikroneziýa sebti',
 			'061' => 'Polineziýa',
 			'142' => 'Aziýa',
 			'143' => 'Orta Aziýa',
 			'145' => 'Günbatar Aziýa',
 			'150' => 'Ýewropa',
 			'151' => 'Gündogar Ýewropa',
 			'154' => 'Demirgazyk Ýewropa',
 			'155' => 'Günbatar Ýewropa',
 			'419' => 'Latyn Amerikasy',
 			'AC' => 'Beýgeliş adasy',
 			'AD' => 'Andorra',
 			'AE' => 'Birleşen Arap Emirlikleri',
 			'AF' => 'Owganystan',
 			'AG' => 'Antigua we Barbuda',
 			'AI' => 'Angilýa',
 			'AL' => 'Albaniýa',
 			'AM' => 'Ermenistan',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentina',
 			'AS' => 'Amerikan Samoasy',
 			'AT' => 'Awstriýa',
 			'AU' => 'Awstraliýa',
 			'AW' => 'Aruba',
 			'AX' => 'Aland adalary',
 			'AZ' => 'Azerbaýjan',
 			'BA' => 'Bosniýa we Gersegowina',
 			'BB' => 'Barbadow',
 			'BD' => 'Bangladeş',
 			'BE' => 'Belgiýa',
 			'BF' => 'Burkina-Faso',
 			'BG' => 'Bolgariýa',
 			'BH' => 'Bahreýn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sen-Bartelemi',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruneý',
 			'BO' => 'Boliwiýa',
 			'BQ' => 'Karib Niderlandy',
 			'BR' => 'Braziliýa',
 			'BS' => 'Bagama adalary',
 			'BT' => 'Butan',
 			'BV' => 'Buwe adasy',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CC' => 'Kokos (Kiling) adalary',
 			'CD' => 'Kongo - Kinşasa',
 			'CD@alt=variant' => 'Kongo (KDR)',
 			'CF' => 'Orta Afrika Respublikasy',
 			'CG' => 'Kongo - Brazzawil',
 			'CG@alt=variant' => 'Kongo (Respublika)',
 			'CH' => 'Şweýsariýa',
 			'CI' => 'Kot-d’Iwuar',
 			'CI@alt=variant' => 'Şirmaýy kenar',
 			'CK' => 'Kuk adalary',
 			'CL' => 'Çili',
 			'CM' => 'Kamerun',
 			'CN' => 'Hytaý',
 			'CO' => 'Kolumbiýa',
 			'CP' => 'Klipperton adasy',
 			'CR' => 'Kosta-Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabo-Werde',
 			'CW' => 'Kýurasao',
 			'CX' => 'Roždestwo adasy',
 			'CY' => 'Kipr',
 			'CZ' => 'Çehiýa',
 			'CZ@alt=variant' => 'Çeh Respublikasy',
 			'DE' => 'Germaniýa',
 			'DG' => 'Diýego-Garsiýa',
 			'DJ' => 'Jibuti',
 			'DK' => 'Daniýa',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikan Respublikasy',
 			'DZ' => 'Alžir',
 			'EA' => 'Seuta we Melilýa',
 			'EC' => 'Ekwador',
 			'EE' => 'Estoniýa',
 			'EG' => 'Müsür',
 			'EH' => 'Günbatar Sahara',
 			'ER' => 'Eritreýa',
 			'ES' => 'Ispaniýa',
 			'ET' => 'Efiopiýa',
 			'EU' => 'Ýewropa Bileleşigi',
 			'EZ' => 'Ýewro sebti',
 			'FI' => 'Finlandiýa',
 			'FJ' => 'Fiji',
 			'FK' => 'Folklend adalary',
 			'FK@alt=variant' => 'Folklend (Malwina) adalary',
 			'FM' => 'Mikroneziýa',
 			'FO' => 'Farer adalary',
 			'FR' => 'Fransiýa',
 			'GA' => 'Gabon',
 			'GB' => 'Birleşen Patyşalyk',
 			'GB@alt=short' => 'Birleşen Patyşalyk',
 			'GD' => 'Grenada',
 			'GE' => 'Gruziýa',
 			'GF' => 'Fransuz Gwianasy',
 			'GG' => 'Gernsi',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grenlandiýa',
 			'GM' => 'Gambiýa',
 			'GN' => 'Gwineýa',
 			'GP' => 'Gwadelupa',
 			'GQ' => 'Ekwatorial Gwineýa',
 			'GR' => 'Gresiýa',
 			'GS' => 'Günorta Georgiýa we Günorta Sendwiç adasy',
 			'GT' => 'Gwatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gwineýa-Bisau',
 			'GY' => 'Gaýana',
 			'HK' => 'Gonkong AAS Hytaý',
 			'HK@alt=short' => 'Gonkong',
 			'HM' => 'Herd we Makdonald adalary',
 			'HN' => 'Gonduras',
 			'HR' => 'Horwatiýa',
 			'HT' => 'Gaiti',
 			'HU' => 'Wengriýa',
 			'IC' => 'Kanar adalary',
 			'ID' => 'Indoneziýa',
 			'IE' => 'Irlandiýa',
 			'IL' => 'Ysraýyl',
 			'IM' => 'Men adasy',
 			'IN' => 'Hindistan',
 			'IO' => 'Britaniýanyň Hint okeanyndaky territoriýalary',
 			'IQ' => 'Yrak',
 			'IR' => 'Eýran',
 			'IS' => 'Islandiýa',
 			'IT' => 'Italiýa',
 			'JE' => 'Jersi',
 			'JM' => 'Ýamaýka',
 			'JO' => 'Iordaniýa',
 			'JP' => 'Ýaponiýa',
 			'KE' => 'Keniýa',
 			'KG' => 'Gyrgyzystan',
 			'KH' => 'Kamboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komor Adalary',
 			'KN' => 'Sent-Kits we Newis',
 			'KP' => 'Demirgazyk Koreýa',
 			'KR' => 'Günorta Koreýa',
 			'KW' => 'Kuweýt',
 			'KY' => 'Kaýman adalary',
 			'KZ' => 'Gazagystan',
 			'LA' => 'Laos',
 			'LB' => 'Liwan',
 			'LC' => 'Sent-Lýusiýa',
 			'LI' => 'Lihtenşteýn',
 			'LK' => 'Şri-Lanka',
 			'LR' => 'Liberiýa',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwa',
 			'LU' => 'Lýuksemburg',
 			'LV' => 'Latwiýa',
 			'LY' => 'Liwiýa',
 			'MA' => 'Marokko',
 			'MC' => 'Monako',
 			'MD' => 'Moldowa',
 			'ME' => 'Montenegro',
 			'MF' => 'Sen-Marten',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marşall adalary',
 			'MK' => 'Makedoniýa',
 			'MK@alt=variant' => 'Makedoniýa (ÖÝR)',
 			'ML' => 'Mali',
 			'MM' => 'Mýanma (Burma)',
 			'MN' => 'Mongoliýa',
 			'MO' => 'Makau AAS Hytaý',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Demirgazyk Mariana adalary',
 			'MQ' => 'Martinika',
 			'MR' => 'Mawritaniýa',
 			'MS' => 'Monserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mawrikiý',
 			'MV' => 'Maldiwler',
 			'MW' => 'Malawi',
 			'MX' => 'Meksika',
 			'MY' => 'Malaýziýa',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibiýa',
 			'NC' => 'Täze Kaledoniýa',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk adasy',
 			'NG' => 'Nigeriýa',
 			'NI' => 'Nikaragua',
 			'NL' => 'Niderlandiýa',
 			'NO' => 'Norwegiýa',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Täze Zelandiýa',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransuz Polineziýasy',
 			'PG' => 'Papua - Täze Gwineýa',
 			'PH' => 'Filippinler',
 			'PK' => 'Pakistan',
 			'PL' => 'Polşa',
 			'PM' => 'Sen-Pýer we Mikelon',
 			'PN' => 'Pitkern adalary',
 			'PR' => 'Puerto-Riko',
 			'PS' => 'Palestina territoriýasy',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugaliýa',
 			'PW' => 'Palau',
 			'PY' => 'Paragwaý',
 			'QA' => 'Katar',
 			'QO' => 'Daşky Okeaniýa',
 			'RE' => 'Reýunýon',
 			'RO' => 'Rumyniýa',
 			'RS' => 'Serbiýa',
 			'RU' => 'Russiýa',
 			'RW' => 'Ruanda',
 			'SA' => 'Saud Arabystany',
 			'SB' => 'Solomon adalary',
 			'SC' => 'Seýşel Adalary',
 			'SD' => 'Sudan',
 			'SE' => 'Şwesiýa',
 			'SG' => 'Singapur',
 			'SH' => 'Keramatly Ýelena adasy',
 			'SI' => 'Sloweniýa',
 			'SJ' => 'Şpisbergen we Ýan-Maýen',
 			'SK' => 'Slowakiýa',
 			'SL' => 'Sýerra-Leone',
 			'SM' => 'San-Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somali',
 			'SR' => 'Surinam',
 			'SS' => 'Günorta Sudan',
 			'ST' => 'San-Tome we Prinsipi',
 			'SV' => 'Salwador',
 			'SX' => 'Sint-Marten',
 			'SY' => 'Siriýa',
 			'SZ' => 'Swazilend',
 			'TA' => 'Tristan-da-Kunýa',
 			'TC' => 'Terks we Kaýkos adalary',
 			'TD' => 'Çad',
 			'TF' => 'Fransuz günorta territoriýalary',
 			'TG' => 'Togo',
 			'TH' => 'Taýland',
 			'TJ' => 'Täjigistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Gündogar Timor',
 			'TM' => 'Türkmenistan',
 			'TN' => 'Tunis',
 			'TO' => 'Tonga',
 			'TR' => 'Türkiýe',
 			'TT' => 'Trinidad we Tobago',
 			'TV' => 'Tuwalu',
 			'TW' => 'Taýwan',
 			'TZ' => 'Tanzaniýa',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'ABŞ-nyň daşarky adalary',
 			'UN' => 'Birleşen Milletler Guramasy',
 			'US' => 'Amerikanyň Birleşen Ştatlary',
 			'US@alt=short' => 'ABŞ',
 			'UY' => 'Urugwaý',
 			'UZ' => 'Özbegistan',
 			'VA' => 'Watikan',
 			'VC' => 'Sent-Winsent we Grenadinler',
 			'VE' => 'Wenesuela',
 			'VG' => 'Britan Wirgin adalary',
 			'VI' => 'ABŞ-nyň Wirgin adalary',
 			'VN' => 'Wýetnam',
 			'VU' => 'Wanuatu',
 			'WF' => 'Uollis we Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosowo',
 			'YE' => 'Ýemen',
 			'YT' => 'Maýotta',
 			'ZA' => 'Günorta Afrika',
 			'ZM' => 'Zambiýa',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Näbelli sebit',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Senenama',
 			'cf' => 'Pul birliginiň formaty',
 			'collation' => 'Tertip rejesi',
 			'currency' => 'Pul birligi',
 			'hc' => 'Sagat aýlawy (12–24 sagat)',
 			'lb' => 'Setirden setire geçiş stili',
 			'ms' => 'Ölçeg ulgamy',
 			'numbers' => 'Sanlar',

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
 				'buddhist' => q{Buddist senenamasy},
 				'chinese' => q{Hytaý senenamasy},
 				'dangi' => q{Dangi senenamasy},
 				'ethiopic' => q{Efiop senenamasy},
 				'gregorian' => q{Grigorian senenamasy},
 				'hebrew' => q{Ýewreý senenamasy},
 				'islamic' => q{Hijri-kamary senenamasy},
 				'iso8601' => q{ISO-8601 senenamasy},
 				'japanese' => q{Ýapon senenamasy},
 				'persian' => q{Pars senenamasy},
 				'roc' => q{Minguo senenamasy},
 			},
 			'cf' => {
 				'account' => q{Pul birliginiň buhgalterçilik formaty},
 				'standard' => q{Pul birliginiň standart formaty},
 			},
 			'collation' => {
 				'ducet' => q{Deslapky Ýunikod tertip rejesi},
 				'search' => q{Umumy maksatly gözleg},
 				'standard' => q{Standart tertip rejesi},
 			},
 			'hc' => {
 				'h11' => q{12 sagat ulgamy (0–11)},
 				'h12' => q{12 sagat ulgamy (1–12)},
 				'h23' => q{24 sagat ulgamy (0–23)},
 				'h24' => q{24 sagat ulgamy (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Setirden setire geçişiň gowşak stili},
 				'normal' => q{Setirden setire geçişiň adaty stili},
 				'strict' => q{Setirden setire geçişiň berk stili},
 			},
 			'ms' => {
 				'metric' => q{Metriki ulgam},
 				'uksystem' => q{Imperial ölçeg ulgamy},
 				'ussystem' => q{ABŞ ölçeg ulgamy},
 			},
 			'numbers' => {
 				'arab' => q{Arap-hindi sanlary},
 				'arabext' => q{Arap-hindi sanlarynyň giňeldilen görnüşi},
 				'armn' => q{Ermeni sanlary},
 				'armnlow' => q{Ermeni setir sanlary},
 				'beng' => q{Bengal sanlary},
 				'deva' => q{Dewanagari sanlary},
 				'ethi' => q{Efiop sanlary},
 				'fullwide' => q{Doly giňlikdäki sanlar},
 				'geor' => q{Gruzin sanlary},
 				'grek' => q{Grek sanlary},
 				'greklow' => q{Grek setir sanlary},
 				'gujr' => q{Gujarati sanlary},
 				'guru' => q{Gurmuhi sanlary},
 				'hanidec' => q{Hytaý onluk sanlary},
 				'hans' => q{Ýönekeýleşdirilen hytaý sanlary},
 				'hansfin' => q{Ýönekeýleşdirilen hytaý maliýe sanlary},
 				'hant' => q{Adaty hytaý sanlary},
 				'hantfin' => q{Adaty hytaý maliýe sanlary},
 				'hebr' => q{Ýewreý sanlary},
 				'jpan' => q{Ýapon sanlary},
 				'jpanfin' => q{Ýapon maliýe sanlary},
 				'khmr' => q{Khmer sanlary},
 				'knda' => q{Kannada sanlary},
 				'laoo' => q{Laos sanlary},
 				'latn' => q{Latyn sanlary},
 				'mlym' => q{Malaýalam sanlary},
 				'mymr' => q{Mýanma sanlary},
 				'orya' => q{Oriýa sanlary},
 				'roman' => q{Rim sanlary},
 				'romanlow' => q{Rim setir sanlary},
 				'taml' => q{Adaty tamil sanlary},
 				'tamldec' => q{Tamil sanlary},
 				'telu' => q{Telugu sanlary},
 				'thai' => q{Taý sanlary},
 				'tibt' => q{Tibet sanlary},
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
			'metric' => q{Metrik},
 			'UK' => q{Birleşen Patyşalyk},
 			'US' => q{ABŞ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Dil: {0}',
 			'script' => 'Elipbiý: {0}',
 			'region' => 'Sebit: {0}',

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
			auxiliary => qr{[c q v x]},
			index => ['A', 'B', 'Ç', 'D', 'E', 'Ä', 'F', 'G', 'H', 'I', 'J', 'Ž', 'K', 'L', 'M', 'N', 'Ň', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'W', 'Y', 'Ý', 'Z'],
			main => qr{[a b ç d e ä f g h i j ž k l m n ň o ö p r s ş t u ü w y ý z]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- – — , ; \: ! ? . … " “ ” ( ) \[ \] \{ \} § @ * #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ç', 'D', 'E', 'Ä', 'F', 'G', 'H', 'I', 'J', 'Ž', 'K', 'L', 'M', 'N', 'Ň', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'W', 'Y', 'Ý', 'Z'], };
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
				hms => 'hh:mm:ss',
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
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					'acre-foot' => {
						'name' => q(akr-fut),
						'one' => q({0} akr-fut),
						'other' => q({0} akr-fut),
					},
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					'arc-minute' => {
						'name' => q(burç minudy),
						'one' => q({0} burç minudy),
						'other' => q({0} burç minudy),
					},
					'arc-second' => {
						'name' => q(burç sekundy),
						'one' => q({0} burç sekundy),
						'other' => q({0} burç sekundy),
					},
					'astronomical-unit' => {
						'name' => q(astronomik birlik),
						'one' => q({0} astronomik birlik),
						'other' => q({0} astronomik birlik),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(baýt),
						'one' => q({0} baýt),
						'other' => q({0} baýt),
					},
					'calorie' => {
						'name' => q(kaloriýa),
						'one' => q({0} kaloriýa),
						'other' => q({0} kaloriýa),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(Selsiý gradusy),
						'one' => q({0} Selsiý gradusy),
						'other' => q({0} Selsiý gradusy),
					},
					'centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					'centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0}/sm),
					},
					'century' => {
						'name' => q(asyr),
						'one' => q({0} asyr),
						'other' => q({0} asyr),
					},
					'coordinate' => {
						'east' => q({0} gündogar),
						'north' => q({0} demirgazyk),
						'south' => q({0} günorta),
						'west' => q({0} günbatar),
					},
					'cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/kub santimetr),
					},
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					'cubic-inch' => {
						'name' => q(kub dýuým),
						'one' => q({0} kub dýuým),
						'other' => q({0} kub dýuým),
					},
					'cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					'cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/kub metr),
					},
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					'cubic-yard' => {
						'name' => q(kub ýard),
						'one' => q({0} kub ýard),
						'other' => q({0} kub ýard),
					},
					'cup' => {
						'name' => q(käse),
						'one' => q({0} käse),
						'other' => q({0} käse),
					},
					'cup-metric' => {
						'name' => q(metrik käse),
						'one' => q({0} metrik käse),
						'other' => q({0} metrik käse),
					},
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					'deciliter' => {
						'name' => q(desilitr),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
					},
					'decimeter' => {
						'name' => q(desimetr),
						'one' => q({0} desimetr),
						'other' => q({0} desimetr),
					},
					'degree' => {
						'name' => q(dereje),
						'one' => q({0} dereje),
						'other' => q({0} dereje),
					},
					'fahrenheit' => {
						'name' => q(Farangeýt gradusy),
						'one' => q({0} Farangeýt gradusy),
						'other' => q({0} Farangeýt gradusy),
					},
					'fluid-ounce' => {
						'name' => q(suwuklyk unsiý),
						'one' => q({0} suwuklyk unsiý),
						'other' => q({0} suwuklyk unsiý),
					},
					'foodcalorie' => {
						'name' => q(Kaloriýa),
						'one' => q({0} kaloriýa),
						'other' => q({0} kaloriýa),
					},
					'foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0}/fut),
					},
					'g-force' => {
						'name' => q(erkin düşüş tizlenmesi),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0} /imp. gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabaýt),
						'one' => q({0} gigabaýt),
						'other' => q({0} gigabaýt),
					},
					'gigahertz' => {
						'name' => q(gigagerts),
						'one' => q({0} gigagerts),
						'other' => q({0} gigagerts),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0}/gram),
					},
					'hectare' => {
						'name' => q(gektar),
						'one' => q({0} gektar),
						'other' => q({0} gektar),
					},
					'hectoliter' => {
						'name' => q(gektolitr),
						'one' => q({0} gektolitr),
						'other' => q({0} gektolitr),
					},
					'hectopascal' => {
						'name' => q(gektopaskal),
						'one' => q({0} gektopaskal),
						'other' => q({0} gektopaskal),
					},
					'hertz' => {
						'name' => q(gerts),
						'one' => q({0} gerts),
						'other' => q({0} gerts),
					},
					'horsepower' => {
						'name' => q(at güýji),
						'one' => q({0} at güýji),
						'other' => q({0} at güýji),
					},
					'hour' => {
						'name' => q(sagat),
						'one' => q({0} sagat),
						'other' => q({0} sagat),
						'per' => q({0}/sagat),
					},
					'inch' => {
						'name' => q(dýuým),
						'one' => q({0} dýuým),
						'other' => q({0} dýuým),
						'per' => q({0}/dýuým),
					},
					'inch-hg' => {
						'name' => q(simap sütüniň dýuýmy),
						'one' => q({0} simap sütüniň dýuýmy),
						'other' => q({0} simap sütüniň dýuýmy),
					},
					'joule' => {
						'name' => q(džul),
						'one' => q({0} džul),
						'other' => q({0} džul),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(Kelwin gradusy),
						'one' => q({0} Kelwin gradusy),
						'other' => q({0} Kelwin gradusy),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobaýt),
						'one' => q({0} kilobaýt),
						'other' => q({0} kilobaýt),
					},
					'kilocalorie' => {
						'name' => q(kilokaloriýa),
						'one' => q({0} kilokaloriýa),
						'other' => q({0} kilokaloriýa),
					},
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0}/kilogram),
					},
					'kilohertz' => {
						'name' => q(kilogerts),
						'one' => q({0} kilogerts),
						'other' => q({0} kilogerts),
					},
					'kilojoule' => {
						'name' => q(kilodžul),
						'one' => q({0} kilodžul),
						'other' => q({0} kilodžul),
					},
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/kilometr),
					},
					'kilometer-per-hour' => {
						'name' => q(sagatda kilometr),
						'one' => q({0} kilometr/sagat),
						'other' => q({0} kilometr/sagat),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilowat-sagat),
						'one' => q({0} kilowat-sagat),
						'other' => q({0} kilowat-sagat),
					},
					'knot' => {
						'name' => q(uzel),
						'one' => q({0} uzel),
						'other' => q({0} uzel),
					},
					'light-year' => {
						'name' => q(ýagtylyk ýyly),
						'one' => q({0} ýagtylyk ýyly),
						'other' => q({0} ýagtylyk ýyly),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} /litr),
					},
					'liter-per-100kilometers' => {
						'name' => q(litr/100 kilometr),
						'one' => q({0} litr/100 kilometr),
						'other' => q({0} litr/100 kilometr),
					},
					'liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					'lux' => {
						'name' => q(lýuks),
						'one' => q({0} lýuks),
						'other' => q({0} lýuks),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabaýt),
						'one' => q({0} megabaýt),
						'other' => q({0} megabaýt),
					},
					'megahertz' => {
						'name' => q(megagerts),
						'one' => q({0} megagerts),
						'other' => q({0} megagerts),
					},
					'megaliter' => {
						'name' => q(megalitr),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(sekuntda metr),
						'one' => q({0} metr/sekunt),
						'other' => q({0} metr/sekunt),
					},
					'meter-per-second-squared' => {
						'name' => q(inedördül sekuntda metr),
						'one' => q({0} metr/inedördül sekunt),
						'other' => q({0} metr/inedördül sekunt),
					},
					'metric-ton' => {
						'name' => q(metrik tonna),
						'one' => q({0} metrik tonna),
						'other' => q({0} metrik tonna),
					},
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					'micrometer' => {
						'name' => q(mikrometr),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
					},
					'microsecond' => {
						'name' => q(mikrosekunt),
						'one' => q({0} mikrosekunt),
						'other' => q({0} mikrosekunt),
					},
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil/gallon),
						'one' => q({0} mil/gallon),
						'other' => q({0} mil/gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp. gallon),
						'other' => q({0} mil/imp. gallon),
					},
					'mile-per-hour' => {
						'name' => q(sagatda mil),
						'one' => q({0} mil/sagat),
						'other' => q({0} mil/sagat),
					},
					'mile-scandinavian' => {
						'name' => q(skandinaw mili),
						'one' => q({0} skandinaw mili),
						'other' => q({0} skandinaw mili),
					},
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligram/desilitr),
						'one' => q({0} milligram/desilitr),
						'other' => q({0} milligram/desilitr),
					},
					'milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					'millimeter-of-mercury' => {
						'name' => q(simap sütüniň millimetri),
						'one' => q({0} simap sütüniň millimetri),
						'other' => q({0} simap sütüniň millimetri),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/litr),
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					'millisecond' => {
						'name' => q(millisekunt),
						'one' => q({0} millisekunt),
						'other' => q({0} millisekunt),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(minut),
						'one' => q({0} minut),
						'other' => q({0} minut),
						'per' => q({0}/minut),
					},
					'month' => {
						'name' => q(aý),
						'one' => q({0} aý),
						'other' => q({0} aý),
						'per' => q({0}/aý),
					},
					'nanometer' => {
						'name' => q(nanometr),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
					},
					'nanosecond' => {
						'name' => q(nanosekunt),
						'one' => q({0} nanosekunt),
						'other' => q({0} nanosekunt),
					},
					'nautical-mile' => {
						'name' => q(deňiz mili),
						'one' => q({0} deňiz mili),
						'other' => q({0} deňiz mili),
					},
					'ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					'ounce' => {
						'name' => q(unsiý),
						'one' => q({0} unsiý),
						'other' => q({0} unsiý),
						'per' => q({0}/unsiý),
					},
					'ounce-troy' => {
						'name' => q(troý unsiý),
						'one' => q({0} troý unsiý),
						'other' => q({0} troý unsiý),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(bölejik/million),
						'one' => q({0} bölejik/million),
						'other' => q({0} bölejik/million),
					},
					'per' => {
						'1' => q({1} başyna {0}),
					},
					'picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(metrik pint),
						'one' => q({0} metrik pint),
						'other' => q({0} metrik pint),
					},
					'point' => {
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					'pound-per-square-inch' => {
						'name' => q(funt/inedördül dýuým),
						'one' => q({0} funt/inedördül dýuým),
						'other' => q({0} funt/inedördül dýuým),
					},
					'quart' => {
						'name' => q(kwarta),
						'one' => q({0} kwarta),
						'other' => q({0} kwarta),
					},
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					'revolution' => {
						'name' => q(aýlaw),
						'one' => q({0} aýlaw),
						'other' => q({0} aýlaw),
					},
					'second' => {
						'name' => q(sekunt),
						'one' => q({0} sekunt),
						'other' => q({0} sekunt),
						'per' => q({0}/sekunt),
					},
					'square-centimeter' => {
						'name' => q(inedördül santimetr),
						'one' => q({0} inedördül santimetr),
						'other' => q({0} inedördül santimetr),
						'per' => q({0}/inedördül santimetr),
					},
					'square-foot' => {
						'name' => q(inedördül fut),
						'one' => q({0} inedördül fut),
						'other' => q({0} inedördül fut),
					},
					'square-inch' => {
						'name' => q(inedördül dýuým),
						'one' => q({0} inedördül dýuým),
						'other' => q({0} inedördül dýuým),
						'per' => q({0}/inedördül dýuým),
					},
					'square-kilometer' => {
						'name' => q(inedördül kilometr),
						'one' => q({0} inedördül kilometr),
						'other' => q({0} inedördül kilometr),
						'per' => q({0} /inedördül kilometr),
					},
					'square-meter' => {
						'name' => q(inedördül metr),
						'one' => q({0} inedördül metr),
						'other' => q({0} inedördül metr),
						'per' => q({0}/inedördül metr),
					},
					'square-mile' => {
						'name' => q(inedördül mil),
						'one' => q({0} inedördül mil),
						'other' => q({0} inedördül mil),
						'per' => q({0} /inedördül mil),
					},
					'square-yard' => {
						'name' => q(inedördül ýard),
						'one' => q({0} inedördül ýard),
						'other' => q({0} inedördül ýard),
					},
					'tablespoon' => {
						'name' => q(nahar çemçesi),
						'one' => q({0} nahar çemçesi),
						'other' => q({0} nahar çemçesi),
					},
					'teaspoon' => {
						'name' => q(çaý çemçesi),
						'one' => q({0} çaý çemçesi),
						'other' => q({0} çaý çemçesi),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabaýt),
						'one' => q({0} terabaýt),
						'other' => q({0} terabaýt),
					},
					'ton' => {
						'name' => q(tonna),
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					'volt' => {
						'name' => q(wolt),
						'one' => q({0} wolt),
						'other' => q({0} wolt),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(hepde),
						'one' => q({0} hepde),
						'other' => q({0} hepde),
						'per' => q({0}/hepde),
					},
					'yard' => {
						'name' => q(ýard),
						'one' => q({0} ýard),
						'other' => q({0} ýard),
					},
					'year' => {
						'name' => q(ýyl),
						'one' => q({0} ýyl),
						'other' => q({0} ýyl),
						'per' => q({0}/ý),
					},
				},
				'narrow' => {
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					'coordinate' => {
						'east' => q({0}gd),
						'north' => q({0}dg),
						'south' => q({0}go),
						'west' => q({0}gb),
					},
					'day' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hour' => {
						'name' => q(sg),
						'one' => q({0}sg),
						'other' => q({0}sg),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/sag),
						'one' => q({0}km/sag),
						'other' => q({0}km/sag),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'month' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'second' => {
						'name' => q(se),
						'one' => q({0}se),
						'other' => q({0}se),
					},
					'week' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					'year' => {
						'name' => q(ý),
						'one' => q({0}ý),
						'other' => q({0}ý),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					'acre-foot' => {
						'name' => q(akr-ft),
						'one' => q({0} ak-ft),
						'other' => q({0} ak-ft),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(burç minudy),
						'one' => q({0} minuta),
						'other' => q({0} minuta),
					},
					'arc-second' => {
						'name' => q(burç sekundy),
						'one' => q({0} burç sek.),
						'other' => q({0} burç sek.),
					},
					'astronomical-unit' => {
						'name' => q(ab),
						'one' => q({0} ab),
						'other' => q({0} ab),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'carat' => {
						'name' => q(kar),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					'century' => {
						'name' => q(as),
						'one' => q({0} as),
						'other' => q({0} as),
					},
					'coordinate' => {
						'east' => q({0} gd),
						'north' => q({0} dg),
						'south' => q({0} go),
						'west' => q({0} gb),
					},
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(dý³),
						'one' => q({0} dý³),
						'other' => q({0} dý³),
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
						'name' => q(ýd³),
						'one' => q({0} ýd³),
						'other' => q({0} ýd³),
					},
					'cup' => {
						'name' => q(käse),
						'one' => q({0} kä),
						'other' => q({0} kä),
					},
					'cup-metric' => {
						'name' => q(mkä),
						'one' => q({0} mkä),
						'other' => q({0} mkä),
					},
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(dereje),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(suw. uns.),
						'one' => q({0} suw. uns.),
						'other' => q({0} suw. uns.),
					},
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} imp. gal.),
						'other' => q({0} imp.gal.),
						'per' => q({0}/imp.gal.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GWt),
						'one' => q({0} GWt),
						'other' => q({0} GWt),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ga),
						'one' => q({0} ga),
						'other' => q({0} ga),
					},
					'hectoliter' => {
						'name' => q(gl),
						'one' => q({0} gl),
						'other' => q({0} gl),
					},
					'hectopascal' => {
						'name' => q(gPa),
						'one' => q({0} gPa),
						'other' => q({0} gPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(a.g.),
						'one' => q({0} a.g.),
						'other' => q({0} a.g.),
					},
					'hour' => {
						'name' => q(sag),
						'one' => q({0} sag),
						'other' => q({0} sag),
						'per' => q({0}/sag),
					},
					'inch' => {
						'name' => q(dý),
						'one' => q({0} dý),
						'other' => q({0} dý),
						'per' => q({0}/dý),
					},
					'inch-hg' => {
						'name' => q(dýHg),
						'one' => q({0} dýHg),
						'other' => q({0} dýHg),
					},
					'joule' => {
						'name' => q(dž),
						'one' => q({0} dž),
						'other' => q({0} dž),
					},
					'karat' => {
						'name' => q(karat),
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
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
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
						'name' => q(kdž),
						'one' => q({0} kdž),
						'other' => q({0} kdž),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/sagat),
						'one' => q({0} km/sag),
						'other' => q({0} km/sag),
					},
					'kilowatt' => {
						'name' => q(kWt),
						'one' => q({0} kWt),
						'other' => q({0} kWt),
					},
					'kilowatt-hour' => {
						'name' => q(kWt-sag),
						'one' => q({0} kWt-sag),
						'other' => q({0} kWt-sag),
					},
					'knot' => {
						'name' => q(uz.),
						'one' => q({0} uz.),
						'other' => q({0} uz.),
					},
					'light-year' => {
						'name' => q(ýý),
						'one' => q({0} ýý),
						'other' => q({0} ýý),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litr/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lk),
						'one' => q({0} lk),
						'other' => q({0} lk),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MWt),
						'one' => q({0} MWt),
						'other' => q({0} MWt),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(tn),
						'one' => q({0} m.tn),
						'other' => q({0} m.tn),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mil/gal.),
						'one' => q({0} mil/gal.),
						'other' => q({0} mil/gal.),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gal.),
						'one' => q({0} mil/imp. gal.),
						'other' => q({0} mil/imp. gal.),
					},
					'mile-per-hour' => {
						'name' => q(mil/sag),
						'one' => q({0} mil/sag),
						'other' => q({0} mil/sag),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
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
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
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
						'name' => q(millimol/litr),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(msek),
						'one' => q({0} msek),
						'other' => q({0} msek),
					},
					'milliwatt' => {
						'name' => q(mWt),
						'one' => q({0} mWt),
						'other' => q({0} mWt),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(aý),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
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
						'name' => q(dmi),
						'one' => q({0} dmi),
						'other' => q({0} dmi),
					},
					'ohm' => {
						'name' => q(Om),
						'one' => q({0} Om),
						'other' => q({0} Om),
					},
					'ounce' => {
						'name' => q(uns.),
						'one' => q({0} uns.),
						'other' => q({0} uns.),
						'per' => q({0}/uns.),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					'part-per-million' => {
						'name' => q(bölejik/million),
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
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(punkt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(kwt),
						'one' => q({0} kwt),
						'other' => q({0} kwt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(aýl.),
						'one' => q({0} aýl.),
						'other' => q({0} aýl.),
					},
					'second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(dý²),
						'one' => q({0} dý²),
						'other' => q({0} dý²),
						'per' => q({0}/dý²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(ýd²),
						'one' => q({0} ýd²),
						'other' => q({0} ýd²),
					},
					'tablespoon' => {
						'name' => q(n. ç.),
						'one' => q({0} n. ç.),
						'other' => q({0} n. ç.),
					},
					'teaspoon' => {
						'name' => q(ç. ç.),
						'one' => q({0} ç. ç.),
						'other' => q({0} ç. ç.),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tonna),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'watt' => {
						'name' => q(Wt),
						'one' => q({0} Wt),
						'other' => q({0} Wt),
					},
					'week' => {
						'name' => q(hep),
						'one' => q({0} hep),
						'other' => q({0} hep),
						'per' => q({0}/hep),
					},
					'yard' => {
						'name' => q(ýd),
						'one' => q({0} ýd),
						'other' => q({0} ýd),
					},
					'year' => {
						'name' => q(ý.),
						'one' => q({0} ý.),
						'other' => q({0} ý.),
						'per' => q({0}/ý.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hawa|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ýok|ý|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
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
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(san däl),
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
					'one' => '0 müň',
					'other' => '0 müň',
				},
				'10000' => {
					'one' => '00 müň',
					'other' => '00 müň',
				},
				'100000' => {
					'one' => '000 müň',
					'other' => '000 müň',
				},
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mlrd',
					'other' => '0 mlrd',
				},
				'10000000000' => {
					'one' => '00 mlrd',
					'other' => '00 mlrd',
				},
				'100000000000' => {
					'one' => '000 mlrd',
					'other' => '000 mlrd',
				},
				'1000000000000' => {
					'one' => '0 trln',
					'other' => '0 trln',
				},
				'10000000000000' => {
					'one' => '00 trln',
					'other' => '00 trln',
				},
				'100000000000000' => {
					'one' => '000 trln',
					'other' => '000 trln',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 müň',
					'other' => '0 müň',
				},
				'10000' => {
					'one' => '00 müň',
					'other' => '00 müň',
				},
				'100000' => {
					'one' => '000 müň',
					'other' => '000 müň',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 million',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 million',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 million',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliard',
				},
				'10000000000' => {
					'one' => '00 milliard',
					'other' => '00 milliard',
				},
				'100000000000' => {
					'one' => '000 milliard',
					'other' => '000 milliard',
				},
				'1000000000000' => {
					'one' => '0 trillion',
					'other' => '0 trillion',
				},
				'10000000000000' => {
					'one' => '00 trillion',
					'other' => '00 trillion',
				},
				'100000000000000' => {
					'one' => '000 trillion',
					'other' => '000 trillion',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 müň',
					'other' => '0 müň',
				},
				'10000' => {
					'one' => '00 müň',
					'other' => '00 müň',
				},
				'100000' => {
					'one' => '000 müň',
					'other' => '000 müň',
				},
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mlrd',
					'other' => '0 mlrd',
				},
				'10000000000' => {
					'one' => '00 mlrd',
					'other' => '00 mlrd',
				},
				'100000000000' => {
					'one' => '000 mlrd',
					'other' => '000 mlrd',
				},
				'1000000000000' => {
					'one' => '0 trln',
					'other' => '0 trln',
				},
				'10000000000000' => {
					'one' => '00 trln',
					'other' => '00 trln',
				},
				'100000000000000' => {
					'one' => '000 trln',
					'other' => '000 trln',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
				'currency' => q(BAE dirhemi),
				'one' => q(BAE dirhemi),
				'other' => q(BAE dirhemi),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Owgan afganisi),
				'one' => q(owgan afganisi),
				'other' => q(owgan afganisi),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Alban leki),
				'one' => q(alban leki),
				'other' => q(alban leki),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Ermeni dramy),
				'one' => q(ermeni dramy),
				'other' => q(ermeni dramy),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Niderland antil guldeni),
				'one' => q(niderland antil guldeni),
				'other' => q(niderland antil guldeni),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angol kwanzasy),
				'one' => q(angol kwanzasy),
				'other' => q(angol kwanzasy),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentin pesosy),
				'one' => q(argentin pesosy),
				'other' => q(argentin pesosy),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Awstraliýa dollary),
				'one' => q(awstraliýa dollary),
				'other' => q(awstraliýa dollary),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Aruba florini),
				'one' => q(aruba florini),
				'other' => q(aruba florini),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Azerbaýjan manady),
				'one' => q(azerbaýjan manady),
				'other' => q(azerbaýjan manady),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Konwertirlenýän Bosniýa we Gersogowina markasy),
				'one' => q(konwertirlenýän bosniýa we gersogowina markasy),
				'other' => q(konwertirlenýän bosniýa we gersogowina markasy),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbados dollary),
				'one' => q(barbados dollary),
				'other' => q(barbados dollary),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladeş takasy),
				'one' => q(bangladeş takasy),
				'other' => q(bangladeş takasy),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bolgar lewi),
				'one' => q(bolgar lewi),
				'other' => q(bolgar lewi),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahreýn dinary),
				'one' => q(bahreýn dinary),
				'other' => q(bahreýn dinary),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundi franky),
				'one' => q(burundi franky),
				'other' => q(burundi franky),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda dollary),
				'one' => q(bermuda dollary),
				'other' => q(bermuda dollary),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Bruneý dollary),
				'one' => q(bruneý dollary),
				'other' => q(bruneý dollary),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliwiýa boliwianosy),
				'one' => q(boliwiýa boliwianosy),
				'other' => q(boliwiýa boliwianosy),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brazil realy),
				'one' => q(brazil realy),
				'other' => q(brazil realy),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bagama dollary),
				'one' => q(bagama dollary),
				'other' => q(bagama dollary),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Butan ngultrumy),
				'one' => q(butan ngultrumy),
				'other' => q(butan ngultrumy),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botswana pulasy),
				'one' => q(botswana pulasy),
				'other' => q(botswana pulasy),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Belarus rubly),
				'one' => q(belarus rubly),
				'other' => q(belarus rubly),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Belorus rubly \(2000–2016\)),
				'one' => q(belorus rubly \(2000–2016\)),
				'other' => q(belorus rubly \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Beliz dollary),
				'one' => q(beliz dollary),
				'other' => q(beliz dollary),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanada dollary),
				'one' => q(kanada dollary),
				'other' => q(kanada dollary),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongo franky),
				'one' => q(kongo franky),
				'other' => q(kongo franky),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Şweýsar franky),
				'one' => q(şweýsar franky),
				'other' => q(şweýsar franky),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Çili pesosy),
				'one' => q(çili pesosy),
				'other' => q(çili pesosy),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(CNH),
				'one' => q(CNH),
				'other' => q(CNH),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Hytaý ýuany),
				'one' => q(hytaý ýuany),
				'other' => q(hytaý ýuany),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolumbiýa pesosy),
				'one' => q(kolumbiýa pesosy),
				'other' => q(kolumbiýa pesosy),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Kosta-Rika kolony),
				'one' => q(kosta-rika kolony),
				'other' => q(kosta-rika kolony),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Konwertirlenýän kuba pesosy),
				'one' => q(konwertirlenýän kuba pesosy),
				'other' => q(konwertirlenýän kuba pesosy),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuba pesosy),
				'one' => q(kuba pesosy),
				'other' => q(kuba pesosy),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Kabo-Werde eskudosy),
				'one' => q(kabo-werde eskudosy),
				'other' => q(kabo-werde eskudosy),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Çeh kronasy),
				'one' => q(çeh kronasy),
				'other' => q(çeh kronasy),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Jibuti franky),
				'one' => q(jibuti franky),
				'other' => q(jibuti franky),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Daniýa kronasy),
				'one' => q(daniýa kronasy),
				'other' => q(daniýa kronasy),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikan pesosy),
				'one' => q(dominikan pesosy),
				'other' => q(dominikan pesosy),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Alžir dinary),
				'one' => q(alžir dinary),
				'other' => q(alžir dinary),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Müsür funty),
				'one' => q(müsür funty),
				'other' => q(müsür funty),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritreýa nakfasy),
				'one' => q(eritreýa nakfasy),
				'other' => q(eritreýa nakfasy),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Efiopiýa byry),
				'one' => q(efiopiýa byry),
				'other' => q(efiopiýa byry),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(Ýewro),
				'one' => q(ýewro),
				'other' => q(ýewro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fiji dollary),
				'one' => q(fiji dollary),
				'other' => q(fiji dollary),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Folklend adalarynyň funty),
				'one' => q(folklend adalarynyň funty),
				'other' => q(folklend adalarynyň funty),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(Britan funt sterlingi),
				'one' => q(britan funt sterlingi),
				'other' => q(britan funt sterlingi),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Gruzin larisi),
				'one' => q(gruzin larisi),
				'other' => q(gruzin larisi),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Gano sedisi),
				'one' => q(gano sedisi),
				'other' => q(gano sedisi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltar funty),
				'one' => q(gibraltar funty),
				'other' => q(gibraltar funty),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambiýa dalasisi),
				'one' => q(gambiýa dalasisi),
				'other' => q(gambiýa dalasisi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Gwineý franky),
				'one' => q(gwineý franky),
				'other' => q(gwineý franky),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Gwatemala ketsaly),
				'one' => q(gwatemala ketsaly),
				'other' => q(gwatemala ketsaly),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Gaýana dollary),
				'one' => q(gaýana dollary),
				'other' => q(gaýana dollary),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Gonkong dollary),
				'one' => q(gonkong dollary),
				'other' => q(gonkong dollary),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Gonduras lempirasy),
				'one' => q(gonduras lempirasy),
				'other' => q(gonduras lempirasy),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Horwat kunasy),
				'one' => q(horwat kunasy),
				'other' => q(horwat kunasy),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gaiti gurdy),
				'one' => q(gaiti gurdy),
				'other' => q(gaiti gurdy),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Wenger forinti),
				'one' => q(wenger forinti),
				'other' => q(wenger forinti),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indoneziýa rupiýasy),
				'one' => q(indoneziýa rupiýasy),
				'other' => q(indoneziýa rupiýasy),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Täze Ysraýyl şekeli),
				'one' => q(täze ysraýyl şekeli),
				'other' => q(täze ysraýyl şekeli),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Hindi rupiýasy),
				'one' => q(hindi rupiýasy),
				'other' => q(hindi rupiýasy),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Yrak dinary),
				'one' => q(yrak dinary),
				'other' => q(yrak dinary),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Eýran rialy),
				'one' => q(eýran rialy),
				'other' => q(eýran rialy),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Islandiýa kronasy),
				'one' => q(islandiýa kronasy),
				'other' => q(islandiýa kronasy),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Ýamaýka dollary),
				'one' => q(ýamaýka dollary),
				'other' => q(ýamaýka dollary),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Iordan dinary),
				'one' => q(iordan dinary),
				'other' => q(iordan dinary),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Ýapon ýeni),
				'one' => q(ýapon ýeni),
				'other' => q(ýapon ýeni),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Keniýa şillingi),
				'one' => q(keniýa şillingi),
				'other' => q(keniýa şillingi),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Gyrgyz somy),
				'one' => q(gyrgyz somy),
				'other' => q(gyrgyz somy),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kamboja riýeli),
				'one' => q(kamboja riýeli),
				'other' => q(kamboja riýeli),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komor adalarynyň franky),
				'one' => q(komor adalarynyň franky),
				'other' => q(komor adalarynyň franky),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Demirgazyk Koreý wony),
				'one' => q(demirgazyk koreý wony),
				'other' => q(demirgazyk koreý wony),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Günorta Koreý wony),
				'one' => q(günorta koreý wony),
				'other' => q(günorta koreý wony),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuweýt dinary),
				'one' => q(kuweýt dinary),
				'other' => q(kuweýt dinary),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kaýman adalarynyň dollary),
				'one' => q(kaýman adalarynyň dollary),
				'other' => q(kaýman adalarynyň dollary),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Gazak teňňesi),
				'one' => q(gazak teňňesi),
				'other' => q(gazak teňňesi),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laos kipi),
				'one' => q(laos kipi),
				'other' => q(laos kipi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Liwan funty),
				'one' => q(liwan funty),
				'other' => q(liwan funty),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Şri-Lanka rupiýasy),
				'one' => q(şri-lanka rupiýasy),
				'other' => q(şri-lanka rupiýasy),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberiýa dollary),
				'one' => q(liberiýa dollary),
				'other' => q(liberiýa dollary),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Liwiýa dinary),
				'one' => q(liwiýa dinary),
				'other' => q(liwiýa dinary),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokko dirhamy),
				'one' => q(marokko dirhamy),
				'other' => q(marokko dirhamy),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldaw leýi),
				'one' => q(moldaw leýi),
				'other' => q(moldaw leýi),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Malagasiý ariarisi),
				'one' => q(malagasiý ariarisi),
				'other' => q(malagasiý ariarisi),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Makedon dinary),
				'one' => q(makedon dinary),
				'other' => q(makedon dinary),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Mýanma kýaty),
				'one' => q(mýanma kýaty),
				'other' => q(mýanma kýaty),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongol tugrigi),
				'one' => q(mongol tugrigi),
				'other' => q(mongol tugrigi),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Makao patakasy),
				'one' => q(makao patakasy),
				'other' => q(makao patakasy),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mawritan ugiýasy \(1973–2017\)),
				'one' => q(mawritan ugiýasy \(1973–2017\)),
				'other' => q(mawritan ugiýasy \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mawritan ugiýasy),
				'one' => q(mawritan ugiýasy),
				'other' => q(mawritan ugiýasy),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mawrikiý rupiýasy),
				'one' => q(mawrikiý rupiýasy),
				'other' => q(mawrikiý rupiýasy),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldiw rufiýasy),
				'one' => q(maldiw rufiýasy),
				'other' => q(maldiw rufiýasy),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malawi kwaçasy),
				'one' => q(malawi kwaçasy),
				'other' => q(malawi kwaçasy),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Meksikan pesosy),
				'one' => q(meksikan pesosy),
				'other' => q(meksikan pesosy),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malaýziýa ringgiti),
				'one' => q(malaýziýa ringgiti),
				'other' => q(malaýziýa ringgiti),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mozambik metikaly),
				'one' => q(mozambik metikaly),
				'other' => q(mozambik metikaly),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibiýa dollary),
				'one' => q(namibiýa dollary),
				'other' => q(namibiýa dollary),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigeriýa naýrasy),
				'one' => q(nigeriýa naýrasy),
				'other' => q(nigeriýa naýrasy),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikaragua kordobasy),
				'one' => q(nikaragua kordobasy),
				'other' => q(nikaragua kordobasy),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norwegiýa kronasy),
				'one' => q(norwegiýa kronasy),
				'other' => q(norwegiýa kronasy),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepal rupiýasy),
				'one' => q(nepal rupiýasy),
				'other' => q(nepal rupiýasy),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Täze Zelandiýa dollary),
				'one' => q(täze zelandiýa dollary),
				'other' => q(täze zelandiýa dollary),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Oman rialy),
				'one' => q(oman rialy),
				'other' => q(oman rialy),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panama balboasy),
				'one' => q(panama balboasy),
				'other' => q(panama balboasy),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peru soly),
				'one' => q(peru soly),
				'other' => q(peru soly),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papua - Täze Gwineýa kinasy),
				'one' => q(papua - täze gwineýa kinasy),
				'other' => q(papua - täze gwineýa kinasy),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippin pesosy),
				'one' => q(filippin pesosy),
				'other' => q(filippin pesosy),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Päkistan rupiýasy),
				'one' => q(päkistan rupiýasy),
				'other' => q(päkistan rupiýasy),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Polýak zlotysy),
				'one' => q(polýak zlotysy),
				'other' => q(polýak zlotysy),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paragwaý guaranisi),
				'one' => q(paragwaý guaranisi),
				'other' => q(paragwaý guaranisi),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Katar rialy),
				'one' => q(katar rialy),
				'other' => q(katar rialy),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Rumyn leýi),
				'one' => q(rumyn leýi),
				'other' => q(rumyn leýi),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serb dinary),
				'one' => q(serb dinary),
				'other' => q(serb dinary),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rus rubly),
				'one' => q(rus rubly),
				'other' => q(rus rubly),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruanda franky),
				'one' => q(ruanda franky),
				'other' => q(ruanda franky),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saud rialy),
				'one' => q(saud rialy),
				'other' => q(saud rialy),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Solomon adalarynyň dollary),
				'one' => q(solomon adalarynyň dollary),
				'other' => q(solomon adalarynyň dollary),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seýşel rupiýasy),
				'one' => q(seýşel rupiýasy),
				'other' => q(seýşel rupiýasy),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudan funty),
				'one' => q(sudan funty),
				'other' => q(sudan funty),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Şwed kronasy),
				'one' => q(şwed kronasy),
				'other' => q(şwed kronasy),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapur dollary),
				'one' => q(singapur dollary),
				'other' => q(singapur dollary),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Keramatly Ýelena adasynyň funty),
				'one' => q(keramatly ýelena adasynyň funty),
				'other' => q(keramatly ýelena adasynyň funty),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sýerra-Leone leony),
				'one' => q(sýerra-leone leony),
				'other' => q(sýerra-leone leony),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somali şillingi),
				'one' => q(somali şillingi),
				'other' => q(somali şillingi),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinam dollary),
				'one' => q(surinam dollary),
				'other' => q(surinam dollary),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Günorta Sudan funty),
				'one' => q(günorta sudan funty),
				'other' => q(günorta sudan funty),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(San-Tome we Prinsipi dobrasy \(1977–2017\)),
				'one' => q(san-tome we prinsipi dobrasy \(1977–2017\)),
				'other' => q(san-tome we prinsipi dobrasy \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
			display_name => {
				'currency' => q(San-Tome we Prinsipi dobrasy),
				'one' => q(san-tome we prinsipi dobrasy),
				'other' => q(san-tome we prinsipi dobrasy),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Siriýa funty),
				'one' => q(siriýa funty),
				'other' => q(siriýa funty),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Swazi lilangeni),
				'one' => q(swazi lilangeni),
				'other' => q(swazi lilangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Taýland baty),
				'one' => q(taýland baty),
				'other' => q(taýland baty),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Täjik somonisy),
				'one' => q(täjik somonisy),
				'other' => q(täjik somonisy),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Türkmen manady),
				'one' => q(türkmen manady),
				'other' => q(türkmen manady),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunis dinary),
				'one' => q(tunis dinary),
				'other' => q(tunis dinary),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tonga paangasy),
				'one' => q(tonga paangasy),
				'other' => q(tonga paangasy),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Türk lirasy),
				'one' => q(türk lirasy),
				'other' => q(türk lirasy),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trininad we Tobago dollary),
				'one' => q(trininad we tobago dollary),
				'other' => q(trininad we tobago dollary),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Täze Taýwan dollary),
				'one' => q(täze taýwan dollary),
				'other' => q(täze taýwan dollary),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzaniýa şillingi),
				'one' => q(tanzaniýa şillingi),
				'other' => q(tanzaniýa şillingi),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukrain griwnasy),
				'one' => q(ukrain griwnasy),
				'other' => q(ukrain griwnasy),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Uganda şillingi),
				'one' => q(uganda şillingi),
				'other' => q(uganda şillingi),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(ABŞ dollary),
				'one' => q(ABŞ dollary),
				'other' => q(ABŞ dollary),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Urugwaý pesosy),
				'one' => q(urugwaý pesosy),
				'other' => q(urugwaý pesosy),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Özbek somy),
				'one' => q(özbek somy),
				'other' => q(özbek somy),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Wenesuela boliwary),
				'one' => q(wenesuela boliwary),
				'other' => q(wenesuela boliwary),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Wýetnam dongy),
				'one' => q(wýetnam dongy),
				'other' => q(wýetnam dongy),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Wanuatu watusy),
				'one' => q(wanuatu watusy),
				'other' => q(wanuatu watusy),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoa talasy),
				'one' => q(samoa talasy),
				'other' => q(samoa talasy),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(KFA BEAC franky),
				'one' => q(KFA BEAC franky),
				'other' => q(KFA BEAC franky),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Gündogar karib dollary),
				'one' => q(gündogar karib dollary),
				'other' => q(gündogar karib dollary),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(KFA BCEAO franky),
				'one' => q(KFA BCEAO franky),
				'other' => q(KFA BCEAO franky),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Fransuz ýuwaş umman franky),
				'one' => q(fransuz ýuwaş umman franky),
				'other' => q(fransuz ýuwaş umman franky),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Näbelli pul birligi),
				'one' => q(näbelli pul birligi),
				'other' => q(näbelli pul birligi),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Ýemen rialy),
				'one' => q(ýemen rialy),
				'other' => q(ýemen rialy),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Günorta Afrika rendi),
				'one' => q(günorta afrika rendi),
				'other' => q(günorta afrika rendi),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zambiýa kwaçasy),
				'one' => q(zambiýa kwaçasy),
				'other' => q(zambiýa kwaçasy),
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
							'ýan',
							'few',
							'mart',
							'apr',
							'maý',
							'iýun',
							'iýul',
							'awg',
							'sen',
							'okt',
							'noý',
							'dek'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ý',
							'F',
							'M',
							'A',
							'M',
							'I',
							'I',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ýanwar',
							'fewral',
							'mart',
							'aprel',
							'maý',
							'iýun',
							'iýul',
							'awgust',
							'sentýabr',
							'oktýabr',
							'noýabr',
							'dekabr'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Ýan',
							'Few',
							'Mart',
							'Apr',
							'Maý',
							'Iýun',
							'Iýul',
							'Awg',
							'Sen',
							'Okt',
							'Noý',
							'Dek'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ý',
							'F',
							'M',
							'A',
							'M',
							'I',
							'I',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Ýanwar',
							'Fewral',
							'Mart',
							'Aprel',
							'Maý',
							'Iýun',
							'Iýul',
							'Awgust',
							'Sentýabr',
							'Oktýabr',
							'Noýabr',
							'Dekabr'
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
			'generic' => {
				'format' => {
					abbreviated => {
						mon => 'db',
						tue => 'sb',
						wed => 'çb',
						thu => 'pb',
						fri => 'an',
						sat => 'şb',
						sun => 'ýb'
					},
					wide => {
						mon => 'duşenbe',
						tue => 'sişenbe',
						wed => 'çarşenbe',
						thu => 'penşenbe',
						fri => 'anna',
						sat => 'şenbe',
						sun => 'ýekşenbe'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'A',
						sat => 'Ş',
						sun => 'Ý'
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'duş',
						tue => 'siş',
						wed => 'çar',
						thu => 'pen',
						fri => 'ann',
						sat => 'şen',
						sun => 'ýek'
					},
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'A',
						sat => 'Ş',
						sun => 'Ý'
					},
					short => {
						mon => 'db',
						tue => 'sb',
						wed => 'çb',
						thu => 'pb',
						fri => 'an',
						sat => 'şb',
						sun => 'ýb'
					},
					wide => {
						mon => 'duşenbe',
						tue => 'sişenbe',
						wed => 'çarşenbe',
						thu => 'penşenbe',
						fri => 'anna',
						sat => 'şenbe',
						sun => 'ýekşenbe'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Duş',
						tue => 'Siş',
						wed => 'Çar',
						thu => 'Pen',
						fri => 'Ann',
						sat => 'Şen',
						sun => 'Ýek'
					},
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'A',
						sat => 'Ş',
						sun => 'Ý'
					},
					short => {
						mon => 'Db',
						tue => 'Sb',
						wed => 'Çb',
						thu => 'Pb',
						fri => 'An',
						sat => 'Şb',
						sun => 'Ýb'
					},
					wide => {
						mon => 'Duşenbe',
						tue => 'Sişenbe',
						wed => 'Çarşenbe',
						thu => 'Penşenbe',
						fri => 'Anna',
						sat => 'Şenbe',
						sun => 'Ýekşenbe'
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
					abbreviated => {0 => '1Ç',
						1 => '2Ç',
						2 => '3Ç',
						3 => '4Ç'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-nji çärýek',
						1 => '2-nji çärýek',
						2 => '3-nji çärýek',
						3 => '4-nji çärýek'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1Ç',
						1 => '2Ç',
						2 => '3Ç',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-nji çärýek',
						1 => '2-nji çärýek',
						2 => '3-nji çärýek',
						3 => '4-nji çärýek'
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
					'am' => q{go.öň},
					'pm' => q{go.soň},
				},
				'narrow' => {
					'am' => q{öň},
					'pm' => q{soň},
				},
				'wide' => {
					'am' => q{günortadan öň},
					'pm' => q{günortadan soň},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{günortadan öň},
					'pm' => q{günortadan soň},
				},
				'narrow' => {
					'am' => q{öň},
					'pm' => q{soň},
				},
				'abbreviated' => {
					'am' => q{g.öň},
					'pm' => q{g.soň},
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
				'0' => 'B.e.öň',
				'1' => 'B.e.'
			},
			wide => {
				'0' => 'Isadan öň',
				'1' => 'Isadan soň'
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
			'full' => q{d MMMM y G EEEE},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd.MM.y GGGGG},
		},
		'gregorian' => {
			'full' => q{d MMMM y EEEE},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.y},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
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
			MEd => q{dd.MM E},
			MMM => q{LLL},
			MMMEd => q{d MMM E},
			MMMMEd => q{d MMMM E},
			MMMMW => q{'hepde' W, MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{dd.MM.y E},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yw => q{'hepde' w, Y},
		},
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{dd.MM E},
			MMM => q{LLL},
			MMMEd => q{d MMM E},
			MMMMEd => q{d MMMM E},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{dd.MM.y E},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
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
				M => q{MM – MM},
			},
			MEd => {
				M => q{dd.MM E – dd.MM E},
				d => q{dd.MM E – dd.MM E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d MMM E – d MMM E},
				d => q{d MMM E – d MMM E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y E – dd.MM.y E},
				d => q{dd.MM.y E – dd.MM.y E},
				y => q{dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y E – d MMM y E},
				d => q{d MMM y E – d MMM y E},
				y => q{d MMM y E – d MMM y E},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
		'generic' => {
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
				M => q{MM – MM},
			},
			MEd => {
				M => q{dd.MM E – dd.MM E},
				d => q{dd.MM E – dd.MM E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d MMM E – d MMM E},
				d => q{d MMM E – d MMM E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y E – dd.MM.y E},
				d => q{dd.MM.y E – dd.MM.y E},
				y => q{dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y E – d MMM y E},
				d => q{d MMM y E – d MMM y E},
				y => q{d MMM y E – d MMM y E},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
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
		regionFormat => q({0} wagty),
		regionFormat => q({0} tomusky wagty),
		regionFormat => q({0} standart wagty),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Owganystan wagty#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abijan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžir#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmera#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantaýr#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzawil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kair#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar-es-Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Aýun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Ýohannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Hartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinşasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librewil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaşi#,
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
			exemplarCity => q#Mogadişo#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrowiýa#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Naýrobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Jamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niameý#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakşot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Nowo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#San-Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Merkezi Afrika wagty#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Gündogar Afrika wagty#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Günorta Afrika standart wagty#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Günbatar Afrika tomusky wagty#,
				'generic' => q#Günbatar Afrika wagty#,
				'standard' => q#Günbatar Afrika standart wagty#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alýaska tomusky wagty#,
				'generic' => q#Alýaska wagty#,
				'standard' => q#Alýaska standart wagty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon tomusky wagty#,
				'generic' => q#Amazan wagty#,
				'standard' => q#Amazon standart wagty#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak adasy#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankoridž#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angilýa#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaýna#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La-Rioha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio-Galegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San-Huan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San-Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Uşuaýa#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsýon#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baiýa#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Baiýa-de-Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belen#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa-Wista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boýse#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos-Aýres#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembrij-Beý#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampu-Grandi#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kaýenna#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaýman adalary#,
		},
		'America/Chicago' => {
			exemplarCity => q#Çikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Çihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordowa#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta-Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuýaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kýurasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Denmarkshawn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Douson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Douson-Krik#,
		},
		'America/Denver' => {
			exemplarCity => q#Denwer#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroýt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eýrunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salwador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Gleýs-Beý#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gus-Beý#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand-Terk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gwadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gwatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guýakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gaýana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Galifaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Gawana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Ermosilo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Noks, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell-Siti, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Wiweý, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Winsens, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamak, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuwik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Ýamaýka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Žužuý#,
		},
		'America/Juneau' => {
			exemplarCity => q#Džuno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montisello, Kentuki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendeýk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La-Pas#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los-Anjeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luiswill#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower-Prinses-Kuorter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maseýo#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigo#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mehiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterreý#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montewideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Monserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#Nýu-Ýork#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Boýla, Demirgazyk Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sentr, Demirgazyk Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nýu-Salem, D.g. Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ohinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtang#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Feniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-o-Prens#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Speýn#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Portu-Welýu#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto-Riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta-Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reýni-Riwer#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin-Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Resifi#,
		},
		'America/Regina' => {
			exemplarCity => q#Rejaýna#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rozulýut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riu-Branku#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa-Izabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santýago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo-Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San-Paulu#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Illokkortoormiut#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sen-Bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent-Džons#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sent-Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sent-Lýusiýa#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sent-Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sent-Winsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift-Karent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tander-Beý#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tihuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Wankuwer#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Waýthors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Ýakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Ýellounaýf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Merkezi Amerika tomusky wagty#,
				'generic' => q#Merkezi Amerika#,
				'standard' => q#Merkezi Amerika standart wagty#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Demirgazyk Amerika gündogar tomusky wagty#,
				'generic' => q#Demirgazyk Amerika gündogar wagty#,
				'standard' => q#Demirgazyk Amerika gündogar standart wagty#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Demirgazyk Amerika dag tomusky wagty#,
				'generic' => q#Demirgazyk Amerika dag wagty#,
				'standard' => q#Demirgazyk Amerika dag standart wagty#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Demirgazyk Amerika Ýuwaş umman tomusky wagty#,
				'generic' => q#Demirgazyk Amerika Ýuwaş umman wagty#,
				'standard' => q#Demirgazyk Amerika Ýuwaş umman standart wagty#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keýsi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Deýwis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dýumon-d-Ýurwil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makkuori#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mouson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Mak-Merdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Sýowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Trol#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia tomusky wagty#,
				'generic' => q#Apia wagty#,
				'standard' => q#Apia standart wagty#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arap ýurtlary tomusky wagty#,
				'generic' => q#Arap ýurtlary wagty#,
				'standard' => q#Arap ýurtlary standart wagty#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longir#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina tomusky wagty#,
				'generic' => q#Argentina wagty#,
				'standard' => q#Argentina standart wagty#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Günbatar Argentina tomusky wagty#,
				'generic' => q#Günbatar Argentina wagty#,
				'standard' => q#Günbatar Argentina standart wagty#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ermenistan tomusky wagty#,
				'generic' => q#Ermenistan wagty#,
				'standard' => q#Ermenistan standart wagty#,
			},
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
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdat#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahreýn#,
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
			exemplarCity => q#Beýrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bişkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruneý#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Çita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Çoýbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damask#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dakka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaý#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duşanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hewron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Gonkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Howd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jaýapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Iýerusalim#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamçatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaçi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoýarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala-Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuçing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuweýt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiýa#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnompen#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Phenýan#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Gyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Er-Riýad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hoşimin#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Şanhaý#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taýbeý#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taşkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tähran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timpu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan-Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumçi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Wýentýan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Ýakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ýekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ýerewan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik tomusky wagty#,
				'generic' => q#Atlantik wagty#,
				'standard' => q#Atlantik standart wagty#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azor adalary#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanar adalary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kabo-Werde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Farer adalary#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeýra adalary#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reýkýawik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Günorta Georgiýa#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Keramatly Ýelena adasy#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisben#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken-Hil#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kerri#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Ýukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord-Hau#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidneý#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Merkezi Awstraliýa tomusky wagty#,
				'generic' => q#Merkezi Awstraliýa wagty#,
				'standard' => q#Merkezi Awstraliýa standart wagty#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Merkezi Awstraliýa günbatar tomusky wagty#,
				'generic' => q#Merkezi Awstraliýa günbatar wagty#,
				'standard' => q#Merkezi Awstraliýa günbatar standart wagty#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Gündogar Awstraliýa tomusky wagty#,
				'generic' => q#Gündogar Awstraliýa wagty#,
				'standard' => q#Gündogar Awstraliýa standart wagty#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Günbatar Awstraliýa tomusky wagty#,
				'generic' => q#Günbatar Awstraliýa wagty#,
				'standard' => q#Günbatar Awstraliýa standart wagty#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaýjan tomusky wagty#,
				'generic' => q#Azerbaýjan wagty#,
				'standard' => q#Azerbaýjan standart wagty#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azor adalary tomusky wagty#,
				'generic' => q#Azor adalary wagty#,
				'standard' => q#Azor adalary standart wagty#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladeş tomusky wagty#,
				'generic' => q#Bangladeş wagty#,
				'standard' => q#Bangladeş standart wagty#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan wagty#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliwiýa wagty#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Braziliýa tomusky wagty#,
				'generic' => q#Braziliýa wagty#,
				'standard' => q#Braziliýa standart wagty#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruneý-Darussalam wagty#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kabo-Werde tomusky wagty#,
				'generic' => q#Kabo-Werde wagty#,
				'standard' => q#Kabo-Werde standart wagty#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Çamorro wagty#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Çatem tomusky wagty#,
				'generic' => q#Çatem wagty#,
				'standard' => q#Çatem standart wagty#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Çili tomusky wagty#,
				'generic' => q#Çili wagty#,
				'standard' => q#Çili standart wagty#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hytaý tomusky wagty#,
				'generic' => q#Hytaý wagty#,
				'standard' => q#Hytaý standart wagty#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Çoýbalsan tomusky wagt#,
				'generic' => q#Çoýbalsan wagty#,
				'standard' => q#Çoýbalsan standart wagty#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Roždestwo adasy wagty#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokos adalary wagty#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbiýa tomusky wagty#,
				'generic' => q#Kolumbiýa wagty#,
				'standard' => q#Kolumbiýa standart wagty#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kuk adalary tomusky wagty#,
				'generic' => q#Kuk adalary wagty#,
				'standard' => q#Kuk adalary standart wagty#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba tomusky wagty#,
				'generic' => q#Kuba wagty#,
				'standard' => q#Kuba standart wagty#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Deýwis wagty#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dýumon-d-Ýurwil wagty#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Gündogar Timor wagty#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Pasha adasy tomusky wagty#,
				'generic' => q#Pasha adasy wagty#,
				'standard' => q#Pasha adasy standart wagty#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekwador wagty#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Utgaşdyrylýan ähliumumy wagt#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Näbelli şäher#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Afiny#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislawa#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brýussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Buharest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeşt#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Býuzingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kişinýow#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopengagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Irlandiýa standart wagty#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernsi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Men adasy#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Stambul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersi#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiýew#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirow#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lýublýana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Beýik Britaniýa tomusky wagty#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lýuksemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariýehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariž#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorisa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San-Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Saraýewo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratow#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopýe#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiýa#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokgolm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulýanowsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Waduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Watikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilnýus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warşawa#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporožýe#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Sýurih#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Merkezi Ýewropa tomusky wagty#,
				'generic' => q#Merkezi Ýewropa wagty#,
				'standard' => q#Merkezi Ýewropa standart wagty#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Gündogar Ýewropa tomusky wagty#,
				'generic' => q#Gündogar Ýewropa wagty#,
				'standard' => q#Gündogar Ýewropa standart wagty#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Uzak Gündogar Ýewropa wagty#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Günbatar Ýewropa tomusky wagty#,
				'generic' => q#Günbatar Ýewropa wagty#,
				'standard' => q#Günbatar Ýewropa standart wagty#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklend adalary tomusky wagty#,
				'generic' => q#Folklend adalary wagty#,
				'standard' => q#Folklend adalary standart wagty#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji tomusky wagty#,
				'generic' => q#Fiji wagty#,
				'standard' => q#Fiji standart wagty#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Fransuz Gwianasy wagty#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Fransuz Günorta we Antarktika ýerleri wagty#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Grinwiç boýunça orta wagt#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos adalary wagty#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambýe wagty#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruziýa tomusky wagty#,
				'generic' => q#Gruziýa wagty#,
				'standard' => q#Gruziýa standart wagty#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilberta adalary wagty#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Gündogar Grenlandiýa tomusky wagty#,
				'generic' => q#Gündogar Grenlandiýa wagty#,
				'standard' => q#Gündogar Grenlandiýa standart wagty#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Günbatar Grenlandiýa tomusky wagty#,
				'generic' => q#Günbatar Grenlandiýa wagty#,
				'standard' => q#Günbatar Grenlandiýa standart wagty#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Pars aýlagy standart wagty#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gaýana wagty#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Gawaý-Aleut tomusky wagty#,
				'generic' => q#Gawaý-Aleut wagty#,
				'standard' => q#Gawaý-Aleut standart wagty#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Gonkong tomusky wagty#,
				'generic' => q#Gonkong wagty#,
				'standard' => q#Gonkong standart wagty#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Howd tomusky wagty#,
				'generic' => q#Howd wagty#,
				'standard' => q#Howd standart wagty#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hindistan standart wagty#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananariwu#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Çagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Roždestwo#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komor adalary#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Maýe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiwler#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mawrikiý#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Maýotta#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reýunýon#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hindi ummany wagty#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hindihytaý wagty#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Merkezi Indoneziýa wagty#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Gündogar Indoneziýa wagty#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Günbatar Indoneziýa wagty#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Eýran tomusky wagty#,
				'generic' => q#Eýran wagty#,
				'standard' => q#Eýran standart wagty#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk tomusky wagty#,
				'generic' => q#Irkutsk wagty#,
				'standard' => q#Irkutsk standart wagty#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ysraýyl tomusky wagty#,
				'generic' => q#Ysraýyl wagty#,
				'standard' => q#Ysraýyl standart wagty#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ýaponiýa tomusky wagty#,
				'generic' => q#Ýaponiýa wagty#,
				'standard' => q#Ýaponiýa standart wagty#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Gündogar Gazagystan wagty#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Günbatar Gazagystan wagty#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreýa tomusky wagty#,
				'generic' => q#Koreýa wagty#,
				'standard' => q#Koreýa standart wagty#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraýe wagty#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoýarsk tomusky wagty#,
				'generic' => q#Krasnoýarsk wagty#,
				'standard' => q#Krasnoýarsk standart wagty#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Gyrgyzystan wagty#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Laýn adalary wagty#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord-Hau tomusky wagty#,
				'generic' => q#Lord-Hau wagty#,
				'standard' => q#Lord-Hau standart wagty#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Makkuori adasy wagty#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan tomusky wagty#,
				'generic' => q#Magadan wagty#,
				'standard' => q#Magadan standart wagty#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaýziýa wagty#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldiwler wagty#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markiz adalary wagty#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marşall adalary wagty#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mawrikiý tomusky wagty#,
				'generic' => q#Mawrikiý wagty#,
				'standard' => q#Mawrikiý standart wagty#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mouson wagty#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Demirgazyk-günbatar Meksika tomusky wagty#,
				'generic' => q#Demirgazyk-günbatar Meksika wagty#,
				'standard' => q#Demirgazyk-günbatar Meksika standart wagty#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksikan Ýuwaş umman tomusky wagty#,
				'generic' => q#Meksikan Ýuwaş umman wagty#,
				'standard' => q#Meksikan Ýuwaş umman standart wagty#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan-Bator tomusky wagty#,
				'generic' => q#Ulan-Bator wagty#,
				'standard' => q#Ulan-Bator standart wagty#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskwa tomusky wagty#,
				'generic' => q#Moskwa wagty#,
				'standard' => q#Moskwa standart wagty#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mýanma wagty#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru wagty#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal wagty#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Täze Kaledoniýa tomusky wagty#,
				'generic' => q#Täze Kaledoniýa wagty#,
				'standard' => q#Täze Kaledoniýa standart wagty#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Täze Zelandiýa tomusky wagty#,
				'generic' => q#Täze Zelandiýa wagty#,
				'standard' => q#Täze Zelandiýa standart wagty#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nýufaundlend tomusky wagty#,
				'generic' => q#Nýufaundlend wagty#,
				'standard' => q#Nýufaundlend standart wagty#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue wagty#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolk adasy wagty#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernandu-di-Noronýa tomusky wagty#,
				'generic' => q#Fernandu-di-Noronýa wagty#,
				'standard' => q#Fernandu-di-Noronýa standart wagty#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibisk tomusky wagty#,
				'generic' => q#Nowosibirsk wagty#,
				'standard' => q#Nowosibirsk standart wagty#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk tomusky wagty#,
				'generic' => q#Omsk wagty#,
				'standard' => q#Omsk standart wagty#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Oklend#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugenwil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Çatem#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pashi adasy#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderberi#,
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
			exemplarCity => q#Galapagos adalary#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambýe#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Gwadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Gonolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jonston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosraýe#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajaleýn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz adalary#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midueý#,
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
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago-Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponape#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port-Morsbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saýpan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Çuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Weýk#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Uollis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan tomusky wagty#,
				'generic' => q#Pakistan wagty#,
				'standard' => q#Pakistan standart wagty#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau wagty#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua - Täze Gwineýa wagty#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragwaý tomusky wagty#,
				'generic' => q#Paragwaý wagty#,
				'standard' => q#Paragwaý standart wagty#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru tomusky wagty#,
				'generic' => q#Peru wagty#,
				'standard' => q#Peru standart wagty#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippinler tomusky wagty#,
				'generic' => q#Filippinler wagty#,
				'standard' => q#Filippinler standart wagty#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Feniks adalary wagty#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sen-Pýer we Mikelon tomusky wagty#,
				'generic' => q#Sen-Pýer we Mikelon#,
				'standard' => q#Sen-Pýer we Mikelon standart wagty#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkern wagty#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape wagty#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Phenýan wagty#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reýunýon wagty#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera wagty#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sahalin tomusky wagty#,
				'generic' => q#Sahalin wagty#,
				'standard' => q#Sahalin standart wagty#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa tomusky wagty#,
				'generic' => q#Samoa wagty#,
				'standard' => q#Samoa standart wagty#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seýşel adalary wagty#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur wagty#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon adalary wagty#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Günorta Georgiýa wagty#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam wagty#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Sýowa wagty#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Taiti wagty#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taýbeý tomusky wagty#,
				'generic' => q#Taýbeý wagty#,
				'standard' => q#Taýbeý standart wagty#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Täjigistan wagty#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau wagty#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga tomusky wagty#,
				'generic' => q#Tonga wagty#,
				'standard' => q#Tonga standart wagty#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Çuuk wagty#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Türkmenistan tomusky wagty#,
				'generic' => q#Türkmenistan wagty#,
				'standard' => q#Türkmenistan standart wagty#,
			},
			short => {
				'daylight' => q#TMST#,
				'generic' => q#TMT#,
				'standard' => q#TMT#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuwalu wagty#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugwaý tomusky wagty#,
				'generic' => q#Urugwaý wagty#,
				'standard' => q#Urugwaý standart wagty#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Özbegistan tomusky wagty#,
				'generic' => q#Özbegistan wagty#,
				'standard' => q#Özbegistan standart wagty#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Wanuatu tomusky wagty#,
				'generic' => q#Wanuatu wagty#,
				'standard' => q#Wanuatu standart wagty#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wenesuela wagty#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostok tomusky wagty#,
				'generic' => q#Wladiwostok wagty#,
				'standard' => q#Wladiwostok standart wagty#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd tomusky wagty#,
				'generic' => q#Wolgograd wagty#,
				'standard' => q#Wolgograd standart wagty#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostok wagty#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Weýk adasy wagty#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Uollis we Futuna wagty#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ýakutsk tomusky wagty#,
				'generic' => q#Ýakutsk wagty#,
				'standard' => q#Ýakutsk standart wagty#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ýekaterinburg tomusky wagty#,
				'generic' => q#Ýekaterinburg wagty#,
				'standard' => q#Ýekaterinburg standart wagty#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
