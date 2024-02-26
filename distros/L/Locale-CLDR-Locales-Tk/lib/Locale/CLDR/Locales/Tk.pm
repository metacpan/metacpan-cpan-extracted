=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tk - Package for language Turkmen

=cut

package Locale::CLDR::Locales::Tk;
# This file auto generated from Data\common\main\tk.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
 				'ann' => 'obolo dili',
 				'anp' => 'angika dili',
 				'ar' => 'arap dili',
 				'ar_001' => 'häzirki zaman standart arap dili',
 				'arn' => 'mapuçe dili',
 				'arp' => 'arapaho dili',
 				'ars' => 'nejdi arap dili',
 				'as' => 'assam dili',
 				'asa' => 'asu dili',
 				'ast' => 'asturiý dili',
 				'atj' => 'atikamekw dili',
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
 				'bgc' => 'harýanwi dili',
 				'bho' => 'bhojpuri dili',
 				'bi' => 'bislama dili',
 				'bin' => 'bini dili',
 				'bla' => 'siksika dili',
 				'bm' => 'bamana',
 				'bn' => 'bengal dili',
 				'bo' => 'tibet dili',
 				'br' => 'breton dili',
 				'brx' => 'bodo dili',
 				'bs' => 'bosniýa dili',
 				'bug' => 'bugiý dili',
 				'byn' => 'blin dili',
 				'ca' => 'katalan dili',
 				'cay' => 'kaýuga dili',
 				'ccp' => 'çakma dili',
 				'ce' => 'çeçen dili',
 				'ceb' => 'sebuan dili',
 				'cgg' => 'kiga',
 				'ch' => 'çamorro',
 				'chk' => 'çuuk dili',
 				'chm' => 'mariý dili',
 				'cho' => 'çokto',
 				'chp' => 'çipewýan dili',
 				'chr' => 'çeroki',
 				'chy' => 'şaýenn dili',
 				'ckb' => 'merkezi kürt dili',
 				'clc' => 'çilkotin dili',
 				'co' => 'korsikan dili',
 				'crg' => 'miçif dili',
 				'crj' => 'günorta-gündogar kri dili',
 				'crk' => 'düzdeçi kri dili',
 				'crl' => 'demirgazyk-gündogar kri dili',
 				'crm' => 'los-kri dili',
 				'crr' => 'karolina algonkin dili',
 				'crs' => 'seselwa kreole-fransuz dili',
 				'cs' => 'çeh dili',
 				'csw' => 'batgalyk kri dili',
 				'cu' => 'buthana slaw dili',
 				'cv' => 'çuwaş dili',
 				'cy' => 'walliý dili',
 				'da' => 'daniýa dili',
 				'dak' => 'dakota dili',
 				'dar' => 'dargi dili',
 				'dav' => 'taita dili',
 				'de' => 'nemes dili',
 				'de_CH' => 'ýokarky nemes dili (Şweýsariýa)',
 				'dgr' => 'dogrib dili',
 				'dje' => 'zarma dili',
 				'doi' => 'Dogri',
 				'dsb' => 'aşaky lužits dili',
 				'dua' => 'duala dili',
 				'dv' => 'diwehi dili',
 				'dyo' => 'ýola-fonýi dili',
 				'dz' => 'dzong-ke dili',
 				'dzg' => 'daza dili',
 				'ebu' => 'embu dili',
 				'ee' => 'ewe dili',
 				'efi' => 'efik dili',
 				'eka' => 'ekajuk dili',
 				'el' => 'grek dili',
 				'en' => 'iňlis dili',
 				'en_GB' => 'iňlis dili (Beýik Britaniýa)',
 				'en_US' => 'iňlis dili (Amerika)',
 				'en_US@alt=short' => 'iňlis dili (ABŞ)',
 				'eo' => 'esperanto dili',
 				'es' => 'ispan dili',
 				'es_ES' => 'ispan dili (Ýewropa)',
 				'et' => 'eston dili',
 				'eu' => 'bask dili',
 				'ewo' => 'ewondo dili',
 				'fa' => 'pars dili',
 				'fa_AF' => 'dari dili',
 				'ff' => 'fula dili',
 				'fi' => 'fin dili',
 				'fil' => 'filippin dili',
 				'fj' => 'fiji dili',
 				'fo' => 'farer dili',
 				'fon' => 'fon dili',
 				'fr' => 'fransuz dili',
 				'frc' => 'fransuz diliniň kajun şiwesi',
 				'frr' => 'demirgazyk friz dili',
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
 				'hai' => 'haýda dili',
 				'haw' => 'gawaý dili',
 				'hax' => 'günorta haýda dili',
 				'he' => 'ýewreý dili',
 				'hi' => 'hindi dili',
 				'hil' => 'hiligaýnon dili',
 				'hmn' => 'hmong dili',
 				'hr' => 'horwat dili',
 				'hsb' => 'ýokarky lužits dili',
 				'ht' => 'gaiti kreol dili',
 				'hu' => 'wenger dili',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem dili',
 				'hy' => 'ermeni dili',
 				'hz' => 'gerero dili',
 				'ia' => 'interlingwa dili',
 				'iba' => 'iban dili',
 				'ibb' => 'ibibio dili',
 				'id' => 'indonez dili',
 				'ig' => 'igbo dili',
 				'ii' => 'syçuan-i dili',
 				'ikt' => 'Günorta Kanada iniktitut dili',
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
 				'kgp' => 'kaýngang dili',
 				'kha' => 'khasi dili',
 				'khq' => 'koýra-çini dili',
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
 				'kwk' => 'kwakwala dili',
 				'ky' => 'gyrgyz dili',
 				'la' => 'latyn dili',
 				'lad' => 'ladino dili',
 				'lag' => 'langi dili',
 				'lb' => 'lýuksemburg dili',
 				'lez' => 'lezgin dili',
 				'lg' => 'ganda dili',
 				'li' => 'limburg dili',
 				'lil' => 'lilluet dili',
 				'lkt' => 'lakota dili',
 				'ln' => 'lingala dili',
 				'lo' => 'laos dili',
 				'lou' => 'Luiziana kreol dili',
 				'loz' => 'lozi dili',
 				'lrc' => 'demirgazyk luri dili',
 				'lsm' => 'samiýa dili',
 				'lt' => 'litwa dili',
 				'lu' => 'luba-katanga dili',
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
 				'mgh' => 'makuwa-mito dili',
 				'mgo' => 'meta dili',
 				'mh' => 'marşall dili',
 				'mi' => 'maori dili',
 				'mic' => 'mikmak dili',
 				'min' => 'minangkabau dili',
 				'mk' => 'makedon dili',
 				'ml' => 'malaýalam dili',
 				'mn' => 'mongol dili',
 				'mni' => 'manipuri dili',
 				'moe' => 'innu-aýmun dili',
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
 				'nds' => 'aşaky nemes dili',
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
 				'no' => 'norweg dili',
 				'nog' => 'nogaý dili',
 				'nqo' => 'nko dili',
 				'nr' => 'günorta ndebele dili',
 				'nso' => 'demirgazyk soto dili',
 				'nus' => 'nuer dili',
 				'nv' => 'nawaho dili',
 				'ny' => 'nýanja dili',
 				'nyn' => 'nýankole dili',
 				'oc' => 'oksitan dili',
 				'ojb' => 'demirgazyk-günbatar ojibwa dili',
 				'ojc' => 'merkezi ojibwa dili',
 				'ojs' => 'oji-kri dili',
 				'ojw' => 'günbatar ojibwa dili',
 				'oka' => 'okanagan dili',
 				'om' => 'oromo dili',
 				'or' => 'oriýa dili',
 				'os' => 'osetin dili',
 				'pa' => 'penjab dili',
 				'pag' => 'pangansinan dili',
 				'pam' => 'kapampangan dili',
 				'pap' => 'papýamento dili',
 				'pau' => 'palau dili',
 				'pcm' => 'nigeriýa-pijin dili',
 				'pis' => 'pijin dili',
 				'pl' => 'polýak dili',
 				'pqm' => 'malisit-passamakwodi dili',
 				'prg' => 'prussiýa dili',
 				'ps' => 'peştun dili',
 				'pt' => 'portugal dili',
 				'pt_PT' => 'portugal dili (Ýewropa)',
 				'qu' => 'keçua dili',
 				'quc' => 'kiçe dili',
 				'raj' => 'rajastani dili',
 				'rap' => 'rapanuý dili',
 				'rar' => 'kuk dili',
 				'rhg' => 'rohinýa dili',
 				'rm' => 'retoroman dili',
 				'rn' => 'rundi dili',
 				'ro' => 'rumyn dili',
 				'ro_MD' => 'moldaw dili',
 				'rof' => 'rombo dili',
 				'ru' => 'rus dili',
 				'rup' => 'arumyn dili',
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
 				'ses' => 'koýraboro-senni dili',
 				'sg' => 'sango dili',
 				'shi' => 'tahelhit dili',
 				'shn' => 'şan dili',
 				'si' => 'singal dili',
 				'sk' => 'slowak dili',
 				'sl' => 'slowen dili',
 				'slh' => 'günorta Luşutsid dili',
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
 				'st' => 'günorta soto dili',
 				'str' => 'demirgazyk bogaz saliş dili',
 				'su' => 'sundan dili',
 				'suk' => 'sukuma dili',
 				'sv' => 'şwed dili',
 				'sw' => 'suahili dili',
 				'sw_CD' => 'kongo suahili dili',
 				'swb' => 'komor dili',
 				'syr' => 'siriýa dili',
 				'ta' => 'tamil dili',
 				'tce' => 'günorta tutçone dili',
 				'te' => 'telugu dili',
 				'tem' => 'temne dili',
 				'teo' => 'teso dili',
 				'tet' => 'tetum dili',
 				'tg' => 'täjik dili',
 				'tgx' => 'tagiş dili',
 				'th' => 'taý dili',
 				'tht' => 'taltan dili',
 				'ti' => 'tigrinýa dili',
 				'tig' => 'tigre dili',
 				'tk' => 'türkmen dili',
 				'tlh' => 'klingon dili',
 				'tli' => 'tlinkit dili',
 				'tn' => 'tswana dili',
 				'to' => 'tongan dili',
 				'tok' => 'toki pona dili',
 				'tpi' => 'tok-pisin dili',
 				'tr' => 'türk dili',
 				'trv' => 'taroko dili',
 				'ts' => 'tsonga dili',
 				'tt' => 'tatar dili',
 				'ttm' => 'demirgazyk tutçone dili',
 				'tum' => 'tumbuka dili',
 				'tvl' => 'tuwalu dili',
 				'twq' => 'tasawak dili',
 				'ty' => 'taiti dili',
 				'tyv' => 'tuwa dili',
 				'tzm' => 'orta-atlas tamazight dili',
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
 				'wuu' => 'u hytaý dili',
 				'xal' => 'galmyk dili',
 				'xh' => 'kosa dili',
 				'xog' => 'soga dili',
 				'yav' => 'ýangben dili',
 				'ybb' => 'ýemba dili',
 				'yi' => 'idiş dili',
 				'yo' => 'ýoruba dili',
 				'yrl' => 'nhengatu dili',
 				'yue' => 'kanton dili',
 				'yue@alt=menu' => 'hytaý dili, kantonça',
 				'zgh' => 'standart Marokko tamazight dili',
 				'zh' => 'hytaý dili',
 				'zh@alt=menu' => 'hytaý dili, mandarin',
 				'zh_Hans' => 'ýönekeýleşdirilen hytaý dili',
 				'zh_Hans@alt=long' => 'ýönekeýleşdirilen hytaý diliniň mandarin şiwesi',
 				'zh_Hant' => 'adaty hytaý dili',
 				'zh_Hant@alt=long' => 'adaty hytaý diliniň mandarin şiwesi',
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
			'Adlm' => 'adlam',
 			'Arab' => 'Arap elipbiýi',
 			'Aran' => 'Nastalik ýazuwy',
 			'Armn' => 'Ermeni elipbiýi',
 			'Beng' => 'Bengal elipbiýi',
 			'Bopo' => 'Bopomofo elipbiýi',
 			'Brai' => 'Braýl elipbiýi',
 			'Cakm' => 'çakma',
 			'Cans' => 'Kanadanyň ýerlileriniň bogunlarynyň bitewileşdirilen ulgamy',
 			'Cher' => 'çeroki',
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
 			'Mtei' => 'meýteý-maýek',
 			'Mymr' => 'Mýanma elipbiýi',
 			'Nkoo' => 'nko',
 			'Olck' => 'ol-çiki',
 			'Orya' => 'Oriýa elipbiýi',
 			'Rohg' => 'hanifi',
 			'Sinh' => 'Singal elipbiýi',
 			'Sund' => 'Sundanez ýazuwy',
 			'Syrc' => 'Siriýa ýazuwy',
 			'Taml' => 'Tamil elipbiýi',
 			'Telu' => 'Telugu elipbiýi',
 			'Tfng' => 'Tifinag ýazuwy',
 			'Thaa' => 'Taana elipbiýi',
 			'Thai' => 'Taý elipbiýi',
 			'Tibt' => 'Tibet elipbiýi',
 			'Vaii' => 'Waý ýazuwy',
 			'Yiii' => 'Ýi ýazuwy',
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
			'001' => 'Dünýä',
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
 			'143' => 'Merkezi Aziýa',
 			'145' => 'Günbatar Aziýa',
 			'150' => 'Ýewropa',
 			'151' => 'Gündogar Ýewropa',
 			'154' => 'Demirgazyk Ýewropa',
 			'155' => 'Günbatar Ýewropa',
 			'202' => 'Saharadan aşakdaky Afrika',
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
 			'BB' => 'Barbados',
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
 			'BQ' => 'Karib Niderlandlary',
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
 			'CF' => 'Merkezi Afrika Respublikasy',
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
 			'EZ' => 'Ýewro sebiti',
 			'FI' => 'Finlýandiýa',
 			'FJ' => 'Fiji',
 			'FK' => 'Folklend adalary',
 			'FK@alt=variant' => 'Folklend (Malwina) adalary',
 			'FM' => 'Mikroneziýa',
 			'FO' => 'Farer adalary',
 			'FR' => 'Fransiýa',
 			'GA' => 'Gabon',
 			'GB' => 'Birleşen Patyşalyk',
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
 			'IO' => 'Britaniýanyň Hindi okeanyndaky territoriýalary',
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
 			'KM' => 'Komor adalary',
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
 			'ME' => 'Çernogoriýa',
 			'MF' => 'Sen-Marten',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marşall adalary',
 			'MK' => 'Demirgazyk Makedoniýa',
 			'ML' => 'Mali',
 			'MM' => 'Mýanma (Birma)',
 			'MN' => 'Mongoliýa',
 			'MO' => 'Makao AAS Hytaý',
 			'MO@alt=short' => 'Makao',
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
 			'NL' => 'Niderlandlar',
 			'NO' => 'Norwegiýa',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Täze Zelandiýa',
 			'NZ@alt=variant' => 'Aotearoa Täze Zelandiýa',
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
 			'SC' => 'Seýşel adalary',
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
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swazilend',
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
 			'XA' => 'psewdo-şiweler',
 			'XB' => 'psewdo-bidi',
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
 				'coptic' => q{Kopt senenamasy},
 				'dangi' => q{Dangi senenamasy},
 				'ethiopic' => q{Efiop senenamasy},
 				'ethiopic-amete-alem' => q{Efiopiýa Amete Alem senenamasy},
 				'gregorian' => q{Grigorian senenamasy},
 				'hebrew' => q{Ýewreý senenamasy},
 				'islamic' => q{Hijri-kamary senenamasy},
 				'islamic-civil' => q{Hijri-kamary senenamasy (tablisaly, raýat eýýamy)},
 				'islamic-tbla' => q{Hijri-kamary senenamasy (tablisaly, astronomik eýýam)},
 				'islamic-umalqura' => q{Hijri-kamary senenamasy (Umm al-Kura)},
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
 				'metric' => q{Metrik ulgam},
 				'uksystem' => q{Imperial ölçeg ulgamy},
 				'ussystem' => q{ABŞ ölçeg ulgamy},
 			},
 			'numbers' => {
 				'arab' => q{Arap-hindi sanlary},
 				'arabext' => q{Arap-hindi sanlarynyň giňeldilen görnüşi},
 				'armn' => q{Ermeni sanlary},
 				'armnlow' => q{Ermeni setir sanlary},
 				'beng' => q{Bengal sanlary},
 				'cakm' => q{Çakma sanlary},
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
 				'java' => q{Ýawa sanlary},
 				'jpan' => q{Ýapon sanlary},
 				'jpanfin' => q{Ýapon maliýe sanlary},
 				'khmr' => q{Khmer sanlary},
 				'knda' => q{Kannada sanlary},
 				'laoo' => q{Laos sanlary},
 				'latn' => q{Latyn sanlary},
 				'mlym' => q{Malaýalam sanlary},
 				'mtei' => q{Miteý Maýek sanlary},
 				'mymr' => q{Mýanma sanlary},
 				'olck' => q{Ol Çiki sanlary},
 				'orya' => q{Oriýa sanlary},
 				'roman' => q{Rim sanlary},
 				'romanlow' => q{Rim setir sanlary},
 				'taml' => q{Adaty tamil sanlary},
 				'tamldec' => q{Tamil sanlary},
 				'telu' => q{Telugu sanlary},
 				'thai' => q{Taý sanlary},
 				'tibt' => q{Tibet sanlary},
 				'vaii' => q{Waý sanlary},
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
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ – — , ; \: ! ? . … "“” ( ) \[ \] \{ \} § @ * #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ç', 'D', 'E', 'Ä', 'F', 'G', 'H', 'I', 'J', 'Ž', 'K', 'L', 'M', 'N', 'Ň', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'W', 'Y', 'Ý', 'Z'], };
},
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
				hms => 'hh:mm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(esasy ugur),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(esasy ugur),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(ýobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(ýobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ýokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ýokto{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(kwekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kwekto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(gekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(gekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ýotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ýotta{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(kwetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kwetta{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(erkin düşüş tizlenmesi),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(erkin düşüş tizlenmesi),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(inedördül sekuntda metr),
						'one' => q({0} metr/inedördül sekunt),
						'other' => q({0} metr/inedördül sekunt),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(inedördül sekuntda metr),
						'one' => q({0} metr/inedördül sekunt),
						'other' => q({0} metr/inedördül sekunt),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} burç minudy),
						'other' => q({0} burç minudy),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} burç minudy),
						'other' => q({0} burç minudy),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} burç sekundy),
						'other' => q({0} burç sekundy),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} burç sekundy),
						'other' => q({0} burç sekundy),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} dereje),
						'other' => q({0} dereje),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} dereje),
						'other' => q({0} dereje),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(aýlaw),
						'one' => q({0} aýlaw),
						'other' => q({0} aýlaw),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(aýlaw),
						'one' => q({0} aýlaw),
						'other' => q({0} aýlaw),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(gektar),
						'one' => q({0} gektar),
						'other' => q({0} gektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(gektar),
						'one' => q({0} gektar),
						'other' => q({0} gektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(inedördül santimetr),
						'one' => q({0} inedördül santimetr),
						'other' => q({0} inedördül santimetr),
						'per' => q({0}/inedördül santimetr),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(inedördül santimetr),
						'one' => q({0} inedördül santimetr),
						'other' => q({0} inedördül santimetr),
						'per' => q({0}/inedördül santimetr),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(inedördül fut),
						'one' => q({0} inedördül fut),
						'other' => q({0} inedördül fut),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(inedördül fut),
						'one' => q({0} inedördül fut),
						'other' => q({0} inedördül fut),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inedördül dýuým),
						'one' => q({0} inedördül dýuým),
						'other' => q({0} inedördül dýuým),
						'per' => q({0}/inedördül dýuým),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inedördül dýuým),
						'one' => q({0} inedördül dýuým),
						'other' => q({0} inedördül dýuým),
						'per' => q({0}/inedördül dýuým),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(inedördül kilometr),
						'one' => q({0} inedördül kilometr),
						'other' => q({0} inedördül kilometr),
						'per' => q({0} /inedördül kilometr),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(inedördül kilometr),
						'one' => q({0} inedördül kilometr),
						'other' => q({0} inedördül kilometr),
						'per' => q({0} /inedördül kilometr),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(inedördül metr),
						'one' => q({0} inedördül metr),
						'other' => q({0} inedördül metr),
						'per' => q({0}/inedördül metr),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(inedördül metr),
						'one' => q({0} inedördül metr),
						'other' => q({0} inedördül metr),
						'per' => q({0}/inedördül metr),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(inedördül mil),
						'one' => q({0} inedördül mil),
						'other' => q({0} inedördül mil),
						'per' => q({0} /inedördül mil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(inedördül mil),
						'one' => q({0} inedördül mil),
						'other' => q({0} inedördül mil),
						'per' => q({0} /inedördül mil),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(inedördül ýard),
						'one' => q({0} inedördül ýard),
						'other' => q({0} inedördül ýard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(inedördül ýard),
						'one' => q({0} inedördül ýard),
						'other' => q({0} inedördül ýard),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram/desilitr),
						'one' => q({0} milligram/desilitr),
						'other' => q({0} milligram/desilitr),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligram/desilitr),
						'one' => q({0} milligram/desilitr),
						'other' => q({0} milligram/desilitr),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mollar),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mollar),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} göterim),
						'other' => q({0} göterim),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} göterim),
						'other' => q({0} göterim),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0} bölejik/million),
						'other' => q({0} bölejik/million),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0} bölejik/million),
						'other' => q({0} bölejik/million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} permiriad),
						'other' => q({0} permiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} permiriad),
						'other' => q({0} permiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litr/100 kilometr),
						'one' => q({0} litr/100 kilometr),
						'other' => q({0} litr/100 kilometr),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litr/100 kilometr),
						'one' => q({0} litr/100 kilometr),
						'other' => q({0} litr/100 kilometr),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/gallon),
						'one' => q({0} mil/gallon),
						'other' => q({0} mil/gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gallon),
						'one' => q({0} mil/gallon),
						'other' => q({0} mil/gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp. gallon),
						'other' => q({0} mil/imp. gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp. gallon),
						'other' => q({0} mil/imp. gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} gündogar),
						'north' => q({0} demirgazyk),
						'south' => q({0} günorta),
						'west' => q({0} günbatar),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} gündogar),
						'north' => q({0} demirgazyk),
						'south' => q({0} günorta),
						'west' => q({0} günbatar),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(baýt),
						'one' => q({0} baýt),
						'other' => q({0} baýt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(baýt),
						'one' => q({0} baýt),
						'other' => q({0} baýt),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabaýt),
						'one' => q({0} gigabaýt),
						'other' => q({0} gigabaýt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabaýt),
						'one' => q({0} gigabaýt),
						'other' => q({0} gigabaýt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobaýt),
						'one' => q({0} kilobaýt),
						'other' => q({0} kilobaýt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobaýt),
						'one' => q({0} kilobaýt),
						'other' => q({0} kilobaýt),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabaýt),
						'one' => q({0} megabaýt),
						'other' => q({0} megabaýt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabaýt),
						'one' => q({0} megabaýt),
						'other' => q({0} megabaýt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabaýt),
						'one' => q({0} petabaýt),
						'other' => q({0} petabaýt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabaýt),
						'one' => q({0} petabaýt),
						'other' => q({0} petabaýt),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabaýt),
						'one' => q({0} terabaýt),
						'other' => q({0} terabaýt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabaýt),
						'one' => q({0} terabaýt),
						'other' => q({0} terabaýt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(asyr),
						'one' => q({0} asyr),
						'other' => q({0} asyr),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(asyr),
						'one' => q({0} asyr),
						'other' => q({0} asyr),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(onýyllyklar),
						'one' => q({0} onýyllyk),
						'other' => q({0} onýyllyk),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(onýyllyklar),
						'one' => q({0} onýyllyk),
						'other' => q({0} onýyllyk),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sagat),
						'one' => q({0} sagat),
						'other' => q({0} sagat),
						'per' => q({0}/sagat),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sagat),
						'one' => q({0} sagat),
						'other' => q({0} sagat),
						'per' => q({0}/sagat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekunt),
						'one' => q({0} mikrosekunt),
						'other' => q({0} mikrosekunt),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekunt),
						'one' => q({0} mikrosekunt),
						'other' => q({0} mikrosekunt),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekunt),
						'one' => q({0} millisekunt),
						'other' => q({0} millisekunt),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekunt),
						'one' => q({0} millisekunt),
						'other' => q({0} millisekunt),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minut),
						'one' => q({0} minut),
						'other' => q({0} minut),
						'per' => q({0}/minut),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minut),
						'one' => q({0} minut),
						'other' => q({0} minut),
						'per' => q({0}/minut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} aý),
						'other' => q({0} aý),
						'per' => q({0}/aý),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} aý),
						'other' => q({0} aý),
						'per' => q({0}/aý),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekunt),
						'one' => q({0} nanosekunt),
						'other' => q({0} nanosekunt),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekunt),
						'one' => q({0} nanosekunt),
						'other' => q({0} nanosekunt),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çärýek),
						'one' => q({0} çärýek),
						'other' => q({0} çärýek),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çärýek),
						'one' => q({0} çärýek),
						'other' => q({0} çärýek),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekunt),
						'one' => q({0} sekunt),
						'other' => q({0} sekunt),
						'per' => q({0}/sekunt),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekunt),
						'one' => q({0} sekunt),
						'other' => q({0} sekunt),
						'per' => q({0}/sekunt),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hepde),
						'one' => q({0} hepde),
						'other' => q({0} hepde),
						'per' => q({0}/hepde),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hepde),
						'one' => q({0} hepde),
						'other' => q({0} hepde),
						'per' => q({0}/hepde),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ýyl),
						'one' => q({0} ýyl),
						'other' => q({0} ýyl),
						'per' => q({0}/ý),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ýyl),
						'one' => q({0} ýyl),
						'other' => q({0} ýyl),
						'per' => q({0}/ý),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(wolt),
						'one' => q({0} wolt),
						'other' => q({0} wolt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(wolt),
						'one' => q({0} wolt),
						'other' => q({0} wolt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Britan ýylylyk birligi),
						'one' => q({0} Britan ýylylyk birligi),
						'other' => q({0} Britan ýylylyk birligi),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Britan ýylylyk birligi),
						'one' => q({0} Britan ýylylyk birligi),
						'other' => q({0} Britan ýylylyk birligi),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloriýa),
						'one' => q({0} kaloriýa),
						'other' => q({0} kaloriýa),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloriýa),
						'one' => q({0} kaloriýa),
						'other' => q({0} kaloriýa),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronwoltlar),
						'one' => q({0} elektronwolt),
						'other' => q({0} elektronwolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronwoltlar),
						'one' => q({0} elektronwolt),
						'other' => q({0} elektronwolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kaloriýa),
						'one' => q({0} Kaloriýa),
						'other' => q({0} Kaloriýa),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kaloriýa),
						'one' => q({0} Kaloriýa),
						'other' => q({0} Kaloriýa),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joul),
						'one' => q({0} joul),
						'other' => q({0} joul),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joul),
						'one' => q({0} joul),
						'other' => q({0} joul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloriýa),
						'one' => q({0} kilokaloriýa),
						'other' => q({0} kilokaloriýa),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloriýa),
						'one' => q({0} kilokaloriýa),
						'other' => q({0} kilokaloriýa),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0} kilojoul),
						'other' => q({0} kilojoul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kilojoul),
						'other' => q({0} kilojoul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowat-sagat),
						'one' => q({0} kilowat-sagat),
						'other' => q({0} kilowat-sagat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowat-sagat),
						'one' => q({0} kilowat-sagat),
						'other' => q({0} kilowat-sagat),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ABŞ termleri),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ABŞ termleri),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(100 kilometrde kilowatt-sagat),
						'one' => q(100 kilometrde {0} kilowatt-sagat),
						'other' => q(100 kilometrde {0} kilowatt-sagat),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(100 kilometrde kilowatt-sagat),
						'one' => q(100 kilometrde {0} kilowatt-sagat),
						'other' => q(100 kilometrde {0} kilowatt-sagat),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} nýuton),
						'other' => q({0} nýuton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} nýuton),
						'other' => q({0} nýuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(funt-güýçler),
						'one' => q({0} funt-güýç),
						'other' => q({0} funt-güýç),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(funt-güýçler),
						'one' => q({0} funt-güýç),
						'other' => q({0} funt-güýç),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigagers),
						'one' => q({0} gigagers),
						'other' => q({0} gigagers),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigagers),
						'one' => q({0} gigagers),
						'other' => q({0} gigagers),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(gers),
						'one' => q({0} gers),
						'other' => q({0} gers),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(gers),
						'one' => q({0} gers),
						'other' => q({0} gers),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilogers),
						'one' => q({0} kilogers),
						'other' => q({0} kilogers),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilogers),
						'one' => q({0} kilogers),
						'other' => q({0} kilogers),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megagers),
						'one' => q({0} megagers),
						'other' => q({0} megagers),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megagers),
						'one' => q({0} megagers),
						'other' => q({0} megagers),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(santimetr başyna nokat),
						'one' => q({0} santimetr başyna nokat),
						'other' => q({0} santimetr başyna nokat),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(santimetr başyna nokat),
						'one' => q({0} santimetr başyna nokat),
						'other' => q({0} santimetr başyna nokat),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nokat dýuým başyna),
						'one' => q({0} nokat dýuým başyna),
						'other' => q({0} nokat dýuým başyna),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nokat dýuým başyna),
						'one' => q({0} nokat dýuým başyna),
						'other' => q({0} nokat dýuým başyna),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografik em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografik em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikseller),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikseller),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(santimetr başyna piksel),
						'one' => q({0} santimetr başyna piksel),
						'other' => q({0} santimetr başyna piksel),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(santimetr başyna piksel),
						'one' => q({0} santimetr başyna piksel),
						'other' => q({0} santimetr başyna piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(dýuým başyna piksel),
						'one' => q({0} dýuým başyna piksel),
						'other' => q({0} dýuým başyna piksel),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(dýuým başyna piksel),
						'one' => q({0} dýuým başyna piksel),
						'other' => q({0} dýuým başyna piksel),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomik birlik),
						'one' => q({0} astronomik birlik),
						'other' => q({0} astronomik birlik),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomik birlik),
						'one' => q({0} astronomik birlik),
						'other' => q({0} astronomik birlik),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimetr),
						'one' => q({0} desimetr),
						'other' => q({0} desimetr),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimetr),
						'one' => q({0} desimetr),
						'other' => q({0} desimetr),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ýer togalagynyň radiusy),
						'one' => q({0} ýer togalagynyň radiusy),
						'other' => q({0} ýer togalagynyň radiusy),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ýer togalagynyň radiusy),
						'one' => q({0} ýer togalagynyň radiusy),
						'other' => q({0} ýer togalagynyň radiusy),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fatom),
						'other' => q({0} fatom),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fatom),
						'other' => q({0} fatom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0}/fut),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0}/fut),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(dýuým),
						'one' => q({0} dýuým),
						'other' => q({0} dýuým),
						'per' => q({0}/dýuým),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(dýuým),
						'one' => q({0} dýuým),
						'other' => q({0} dýuým),
						'per' => q({0}/dýuým),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/kilometr),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/kilometr),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ýagtylyk ýyly),
						'one' => q({0} ýagtylyk ýyly),
						'other' => q({0} ýagtylyk ýyly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ýagtylyk ýyly),
						'one' => q({0} ýagtylyk ýyly),
						'other' => q({0} ýagtylyk ýyly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metr),
						'one' => q({0} metr),
						'other' => q({0} metr),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metr),
						'one' => q({0} metr),
						'other' => q({0} metr),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometr),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometr),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(skandinaw mili),
						'one' => q({0} skandinaw mili),
						'other' => q({0} skandinaw mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(skandinaw mili),
						'one' => q({0} skandinaw mili),
						'other' => q({0} skandinaw mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometr),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometr),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(deňiz mili),
						'one' => q({0} deňiz mili),
						'other' => q({0} deňiz mili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(deňiz mili),
						'one' => q({0} deňiz mili),
						'other' => q({0} deňiz mili),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} punkt),
						'other' => q({0} punkt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} gün radiusy),
						'other' => q({0} gün radiusy),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} gün radiusy),
						'other' => q({0} gün radiusy),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ýard),
						'one' => q({0} ýard),
						'other' => q({0} ýard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ýard),
						'one' => q({0} ýard),
						'other' => q({0} ýard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lýumen),
						'one' => q({0} lýumen),
						'other' => q({0} lýumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lýumen),
						'one' => q({0} lýumen),
						'other' => q({0} lýumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lýuks),
						'one' => q({0} lýuks),
						'other' => q({0} lýuks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lýuks),
						'one' => q({0} lýuks),
						'other' => q({0} lýuks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} gün ýagtylygy),
						'other' => q({0} gün ýagtylygy),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} gün ýagtylygy),
						'other' => q({0} gün ýagtylygy),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Ýer massasy),
						'one' => q({0} Ýer massasy),
						'other' => q({0} Ýer massasy),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Ýer massasy),
						'one' => q({0} Ýer massasy),
						'other' => q({0} Ýer massasy),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0}/gram),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0}/gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0}/kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0}/kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unsiýa),
						'one' => q({0} unsiýa),
						'other' => q({0} unsiýa),
						'per' => q({0}/unsiýa),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unsiýa),
						'one' => q({0} unsiýa),
						'other' => q({0} unsiýa),
						'per' => q({0}/unsiýa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troý unsiýa),
						'one' => q({0} troý unsiýa),
						'other' => q({0} troý unsiýa),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troý unsiýa),
						'one' => q({0} troý unsiýa),
						'other' => q({0} troý unsiýa),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} gün massasy),
						'other' => q({0} gün massasy),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} gün massasy),
						'other' => q({0} gün massasy),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stoun),
						'other' => q({0} stoun),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stoun),
						'other' => q({0} stoun),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metrik tonna),
						'one' => q({0} metrik tonna),
						'other' => q({0} metrik tonna),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrik tonna),
						'one' => q({0} metrik tonna),
						'other' => q({0} metrik tonna),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({1} başyna {0}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({1} başyna {0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawat),
						'one' => q({0} gigawat),
						'other' => q({0} gigawat),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawat),
						'one' => q({0} gigawat),
						'other' => q({0} gigawat),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(at güýji),
						'one' => q({0} at güýji),
						'other' => q({0} at güýji),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(at güýji),
						'one' => q({0} at güýji),
						'other' => q({0} at güýji),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowat),
						'one' => q({0} kilowat),
						'other' => q({0} kilowat),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowat),
						'one' => q({0} kilowat),
						'other' => q({0} kilowat),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawat),
						'one' => q({0} megawat),
						'other' => q({0} megawat),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawat),
						'one' => q({0} megawat),
						'other' => q({0} megawat),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwat),
						'one' => q({0} milliwat),
						'other' => q({0} milliwat),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwat),
						'one' => q({0} milliwat),
						'other' => q({0} milliwat),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(wat),
						'one' => q({0} wat),
						'other' => q({0} wat),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(wat),
						'one' => q({0} wat),
						'other' => q({0} wat),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(kwadrat {0}),
						'other' => q(kwadrat {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(kwadrat {0}),
						'other' => q(kwadrat {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(kub {0}),
						'other' => q(kub {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(kub {0}),
						'other' => q(kub {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(barlar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(barlar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(gektopaskal),
						'one' => q({0} gektopaskal),
						'other' => q({0} gektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(gektopaskal),
						'one' => q({0} gektopaskal),
						'other' => q({0} gektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(dýuým simap sütüni),
						'one' => q({0} dýuým simap sütüni),
						'other' => q({0} dýuým simap sütüni),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(dýuým simap sütüni),
						'one' => q({0} dýuým simap sütüni),
						'other' => q({0} dýuým simap sütüni),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimetr simap sütüni),
						'one' => q({0} millimetr simap sütüni),
						'other' => q({0} millimetr simap sütüni),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetr simap sütüni),
						'one' => q({0} millimetr simap sütüni),
						'other' => q({0} millimetr simap sütüni),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskallar),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskallar),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(funt/inedördül dýuým),
						'one' => q({0} funt/inedördül dýuým),
						'other' => q({0} funt/inedördül dýuým),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(funt/inedördül dýuým),
						'one' => q({0} funt/inedördül dýuým),
						'other' => q({0} funt/inedördül dýuým),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Bofort),
						'one' => q(Bofort {0}),
						'other' => q(Bofort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bofort),
						'one' => q(Bofort {0}),
						'other' => q(Bofort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(sagatda kilometr),
						'one' => q({0} kilometr/sagat),
						'other' => q({0} kilometr/sagat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(sagatda kilometr),
						'one' => q({0} kilometr/sagat),
						'other' => q({0} kilometr/sagat),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(düwün),
						'one' => q({0} düwün),
						'other' => q({0} düwün),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(düwün),
						'one' => q({0} düwün),
						'other' => q({0} düwün),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metr/sekunt),
						'one' => q({0} metr/sekunt),
						'other' => q({0} metr/sekunt),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metr/sekunt),
						'one' => q({0} metr/sekunt),
						'other' => q({0} metr/sekunt),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(sagatda mil),
						'one' => q({0} mil/sagat),
						'other' => q({0} mil/sagat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(sagatda mil),
						'one' => q({0} mil/sagat),
						'other' => q({0} mil/sagat),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Selsiý gradusy),
						'one' => q({0} Selsiý gradusy),
						'other' => q({0} Selsiý gradusy),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Selsiý gradusy),
						'one' => q({0} Selsiý gradusy),
						'other' => q({0} Selsiý gradusy),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Farengeýt gradusy),
						'one' => q({0} Farengeýt gradusy),
						'other' => q({0} Farengeýt gradusy),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Farengeýt gradusy),
						'one' => q({0} Farengeýt gradusy),
						'other' => q({0} Farengeýt gradusy),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} dereje),
						'other' => q({0} dereje),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} dereje),
						'other' => q({0} dereje),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(Kelwin gradusy),
						'one' => q({0} Kelwin gradusy),
						'other' => q({0} Kelwin gradusy),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(Kelwin gradusy),
						'one' => q({0} Kelwin gradusy),
						'other' => q({0} Kelwin gradusy),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(nýuton-metrler),
						'one' => q({0} nýuton-metr),
						'other' => q({0} nýuton-metr),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(nýuton-metrler),
						'one' => q({0} nýuton-metr),
						'other' => q({0} nýuton-metr),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(funt-futlar),
						'one' => q({0} funt-fut),
						'other' => q({0} funt-fut),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(funt-futlar),
						'one' => q({0} funt-fut),
						'other' => q({0} funt-fut),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akr-fut),
						'one' => q({0} akr-fut),
						'other' => q({0} akr-fut),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akr-fut),
						'one' => q({0} akr-fut),
						'other' => q({0} akr-fut),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barreller),
						'one' => q({0} barrel),
						'other' => q({0} barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barreller),
						'one' => q({0} barrel),
						'other' => q({0} barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} buşel),
						'other' => q({0} buşel),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} buşel),
						'other' => q({0} buşel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/kub santimetr),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/kub santimetr),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kub dýuým),
						'one' => q({0} kub dýuým),
						'other' => q({0} kub dýuým),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kub dýuým),
						'one' => q({0} kub dýuým),
						'other' => q({0} kub dýuým),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/kub metr),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/kub metr),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kub ýard),
						'one' => q({0} kub ýard),
						'other' => q({0} kub ýard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kub ýard),
						'one' => q({0} kub ýard),
						'other' => q({0} kub ýard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} käse),
						'other' => q({0} käse),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} käse),
						'other' => q({0} käse),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik käse),
						'one' => q({0} metrik käse),
						'other' => q({0} metrik käse),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik käse),
						'one' => q({0} metrik käse),
						'other' => q({0} metrik käse),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitr),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitr),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(süýji çemçesi),
						'one' => q({0} süýji çemçesi),
						'other' => q({0} süýji çemçesi),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(süýji çemçesi),
						'one' => q({0} süýji çemçesi),
						'other' => q({0} süýji çemçesi),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. süýji çemçesi),
						'one' => q({0} Imp. süýji çemçesi),
						'other' => q({0} Imp. süýji çemçesi),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. süýji çemçesi),
						'one' => q({0} Imp. süýji çemçesi),
						'other' => q({0} Imp. süýji çemçesi),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(suwuklyk unsiýasy),
						'one' => q({0} suwuklyk unsiýasy),
						'other' => q({0} suwuklyk unsiýasy),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(suwuklyk unsiýasy),
						'one' => q({0} suwuklyk unsiýasy),
						'other' => q({0} suwuklyk unsiýasy),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. suwuklyk unsiýalary),
						'one' => q({0} imp. suwukluk unsiýasy),
						'other' => q({0} imp. suwuklyk unsiýasy),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. suwuklyk unsiýalary),
						'one' => q({0} imp. suwukluk unsiýasy),
						'other' => q({0} imp. suwuklyk unsiýasy),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0} /imp. gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0} /imp. gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(gektolitr),
						'one' => q({0} gektolitr),
						'other' => q({0} gektolitr),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(gektolitr),
						'one' => q({0} gektolitr),
						'other' => q({0} gektolitr),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} /litr),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} /litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitr),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitr),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinta),
						'one' => q({0} pinta),
						'other' => q({0} pinta),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinta),
						'one' => q({0} pinta),
						'other' => q({0} pinta),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik pinta),
						'one' => q({0} metrik pinta),
						'other' => q({0} metrik pinta),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik pinta),
						'one' => q({0} metrik pinta),
						'other' => q({0} metrik pinta),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kwarta),
						'one' => q({0} kwarta),
						'other' => q({0} kwarta),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kwarta),
						'one' => q({0} kwarta),
						'other' => q({0} kwarta),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. kwarta),
						'one' => q({0} Imp. kwarta),
						'other' => q({0} Imp. kwarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. kwarta),
						'one' => q({0} Imp. kwarta),
						'other' => q({0} Imp. kwarta),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(nahar çemçesi),
						'one' => q({0} nahar çemçesi),
						'other' => q({0} nahar çemçesi),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(nahar çemçesi),
						'one' => q({0} nahar çemçesi),
						'other' => q({0} nahar çemçesi),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(çaý çemçesi),
						'one' => q({0} çaý çemçesi),
						'other' => q({0} çaý çemçesi),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(çaý çemçesi),
						'one' => q({0} çaý çemçesi),
						'other' => q({0} çaý çemçesi),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(burç min.),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(burç min.),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(burç sek.),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(burç sek.),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}gd),
						'north' => q({0}dg),
						'south' => q({0}go),
						'west' => q({0}gb),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}gd),
						'north' => q({0}dg),
						'south' => q({0}go),
						'west' => q({0}gb),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sg),
						'one' => q({0}sg),
						'other' => q({0}sg),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sg),
						'one' => q({0}sg),
						'other' => q({0}sg),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0}ç),
						'other' => q({0}ç),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0}ç),
						'other' => q({0}ç),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(se),
						'one' => q({0}se),
						'other' => q({0}se),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(se),
						'one' => q({0}se),
						'other' => q({0}se),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ý),
						'one' => q({0}ý),
						'other' => q({0}ý),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ý),
						'one' => q({0}ý),
						'other' => q({0}ý),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWs),
						'one' => q({0}kWs),
						'other' => q({0}kWs),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWs),
						'one' => q({0}kWs),
						'other' => q({0}kWs),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWs/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWs/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(psb),
						'one' => q({0} psb),
						'other' => q({0} psb),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(psb),
						'one' => q({0} psb),
						'other' => q({0} psb),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pdb),
						'one' => q({0} pdb),
						'other' => q({0} pdb),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pdb),
						'one' => q({0} pdb),
						'other' => q({0} pdb),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/sag),
						'one' => q({0}km/sag),
						'other' => q({0}km/sag),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/sag),
						'one' => q({0}km/sag),
						'other' => q({0}km/sag),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(s. ç.),
						'one' => q({0} s. ç.),
						'other' => q({0} s. ç.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(s. ç.),
						'one' => q({0} s. ç.),
						'other' => q({0} s. ç.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(s.uns.),
						'one' => q({0}s.uns.),
						'other' => q({0}s.uns.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(s.uns.),
						'one' => q({0}s.uns.),
						'other' => q({0}s.uns.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0}galIm),
						'other' => q({0}galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}galIm),
						'other' => q({0}galIm),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pn),
						'one' => q({0}pn),
						'other' => q({0}pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pn),
						'one' => q({0}pn),
						'other' => q({0}pn),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0} kt-Imp.),
						'other' => q({0} kt-Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} kt-Imp.),
						'other' => q({0} kt-Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ugur),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ugur),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Ýi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Ýi{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(burç minudy),
						'one' => q({0} burç min.),
						'other' => q({0} burç min.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(burç minudy),
						'one' => q({0} burç min.),
						'other' => q({0} burç min.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(burç sekundy),
						'one' => q({0} burç sek.),
						'other' => q({0} burç sek.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(burç sekundy),
						'one' => q({0} burç sek.),
						'other' => q({0} burç sek.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(dereje),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(dereje),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(aýl.),
						'one' => q({0} aýl.),
						'other' => q({0} aýl.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(aýl.),
						'one' => q({0} aýl.),
						'other' => q({0} aýl.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunamlar),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunamlar),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ga),
						'one' => q({0} ga),
						'other' => q({0} ga),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ga),
						'one' => q({0} ga),
						'other' => q({0} ga),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(dý²),
						'one' => q({0} dý²),
						'other' => q({0} dý²),
						'per' => q({0}/dý²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(dý²),
						'one' => q({0} dý²),
						'other' => q({0} dý²),
						'per' => q({0}/dý²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ýd²),
						'one' => q({0} ýd²),
						'other' => q({0} ýd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ýd²),
						'one' => q({0} ýd²),
						'other' => q({0} ýd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/litr),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(göterim),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(göterim),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bölejik/million),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bölejik/million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litr/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litr/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/gal.),
						'one' => q({0} mil/gal.),
						'other' => q({0} mil/gal.),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gal.),
						'one' => q({0} mil/gal.),
						'other' => q({0} mil/gal.),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gal.),
						'one' => q({0} mil/imp. gal.),
						'other' => q({0} mil/imp. gal.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gal.),
						'one' => q({0} mil/imp. gal.),
						'other' => q({0} mil/imp. gal.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} gd),
						'north' => q({0} dg),
						'south' => q({0} go),
						'west' => q({0} gb),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} gd),
						'north' => q({0} dg),
						'south' => q({0} go),
						'west' => q({0} gb),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(as),
						'one' => q({0} as),
						'other' => q({0} as),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(as),
						'one' => q({0} as),
						'other' => q({0} as),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(oný),
						'one' => q({0} oný),
						'other' => q({0} oný),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(oný),
						'one' => q({0} oný),
						'other' => q({0} oný),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(sag),
						'one' => q({0} sag),
						'other' => q({0} sag),
						'per' => q({0}/sag),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(sag),
						'one' => q({0} sag),
						'other' => q({0} sag),
						'per' => q({0}/sag),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mks),
						'one' => q({0} mks),
						'other' => q({0} mks),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mks),
						'one' => q({0} mks),
						'other' => q({0} mks),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msek),
						'one' => q({0} msek),
						'other' => q({0} msek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msek),
						'one' => q({0} msek),
						'other' => q({0} msek),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(aý),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(aý),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(çär),
						'one' => q({0} çär),
						'other' => q({0} çär),
						'per' => q({0}/ç),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(çär),
						'one' => q({0} çär),
						'other' => q({0} çär),
						'per' => q({0}/ç),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hep),
						'one' => q({0} hep),
						'other' => q({0} hep),
						'per' => q({0}/hep),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hep),
						'one' => q({0} hep),
						'other' => q({0} hep),
						'per' => q({0}/hep),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ý.),
						'one' => q({0} ý.),
						'other' => q({0} ý.),
						'per' => q({0}/ý.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ý.),
						'one' => q({0} ý.),
						'other' => q({0} ý.),
						'per' => q({0}/ý.),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamp),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Om),
						'one' => q({0} Om),
						'other' => q({0} Om),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Om),
						'one' => q({0} Om),
						'other' => q({0} Om),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronwolt),
						'one' => q({0} eW),
						'other' => q({0} eW),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronwolt),
						'one' => q({0} eW),
						'other' => q({0} eW),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWt. sag),
						'one' => q({0} kWt. sag),
						'other' => q({0} kWt. sag),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWt. sag),
						'one' => q({0} kWt. sag),
						'other' => q({0} kWt. sag),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ABŞ termi),
						'one' => q({0} ABŞ termi),
						'other' => q({0} ABŞ termi),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ABŞ termi),
						'one' => q({0} ABŞ termi),
						'other' => q({0} ABŞ termi),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWs/100km),
						'one' => q({0} kWs/100km),
						'other' => q({0} kWs/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWs/100km),
						'one' => q({0} kWs/100km),
						'other' => q({0} kWs/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(nýuton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(nýuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(funt-güýç),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(funt-güýç),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GGs),
						'one' => q({0} GGs),
						'other' => q({0} GGs),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GGs),
						'one' => q({0} GGs),
						'other' => q({0} GGs),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Gs),
						'one' => q({0} Gs),
						'other' => q({0} Gs),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Gs),
						'one' => q({0} Gs),
						'other' => q({0} Gs),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kGs),
						'one' => q({0} kGs),
						'other' => q({0} kGs),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kGs),
						'one' => q({0} kGs),
						'other' => q({0} kGs),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MGs),
						'one' => q({0} MGs),
						'other' => q({0} MGs),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MGs),
						'one' => q({0} MGs),
						'other' => q({0} MGs),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(nokat),
						'one' => q({0} nokat),
						'other' => q({0} nokat),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(nokat),
						'one' => q({0} nokat),
						'other' => q({0} nokat),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nsmb),
						'one' => q({0} nsmb),
						'other' => q({0} nsmb),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nsmb),
						'one' => q({0} nsmb),
						'other' => q({0} nsmb),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ndb),
						'one' => q({0} ndb),
						'other' => q({0} ndb),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ndb),
						'one' => q({0} ndb),
						'other' => q({0} ndb),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikseller),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikseller),
						'one' => q({0} pks),
						'other' => q({0} pks),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(sbp),
						'one' => q({0} sbp),
						'other' => q({0} sbp),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(sbp),
						'one' => q({0} sbp),
						'other' => q({0} sbp),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(dbp),
						'one' => q({0} dbp),
						'other' => q({0} dbp),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(dbp),
						'one' => q({0} dbp),
						'other' => q({0} dbp),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ab),
						'one' => q({0} ab),
						'other' => q({0} ab),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ab),
						'one' => q({0} ab),
						'other' => q({0} ab),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatom),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(dý),
						'one' => q({0} dý),
						'other' => q({0} dý),
						'per' => q({0}/dý),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(dý),
						'one' => q({0} dý),
						'other' => q({0} dý),
						'per' => q({0}/dý),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ýý),
						'one' => q({0} ýý),
						'other' => q({0} ýý),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ýý),
						'one' => q({0} ýý),
						'other' => q({0} ýý),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(dmi),
						'one' => q({0} dmi),
						'other' => q({0} dmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(dmi),
						'one' => q({0} dmi),
						'other' => q({0} dmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punkt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punkt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(gün radiuslary),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(gün radiuslary),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ýd),
						'one' => q({0} ýd),
						'other' => q({0} ýd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ýd),
						'one' => q({0} ýd),
						'other' => q({0} ýd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kd),
						'one' => q({0} kd),
						'other' => q({0} kd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kd),
						'one' => q({0} kd),
						'other' => q({0} kd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lk),
						'one' => q({0} lk),
						'other' => q({0} lk),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lk),
						'one' => q({0} lk),
						'other' => q({0} lk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(gün ýagtylyklary),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(gün ýagtylyklary),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kar),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kar),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltonlar),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltonlar),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Ýer massalary),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Ýer massalary),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} gran),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} gran),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(uns.),
						'one' => q({0} uns.),
						'other' => q({0} uns.),
						'per' => q({0}/uns.),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(uns.),
						'one' => q({0} uns.),
						'other' => q({0} uns.),
						'per' => q({0}/uns.),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(gün massalary),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(gün massalary),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stoun),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stoun),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonna),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonna),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GWt),
						'one' => q({0} GWt),
						'other' => q({0} GWt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GWt),
						'one' => q({0} GWt),
						'other' => q({0} GWt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(a.g.),
						'one' => q({0} a.g.),
						'other' => q({0} a.g.),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(a.g.),
						'one' => q({0} a.g.),
						'other' => q({0} a.g.),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kWt),
						'one' => q({0} kWt),
						'other' => q({0} kWt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kWt),
						'one' => q({0} kWt),
						'other' => q({0} kWt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MWt),
						'one' => q({0} MWt),
						'other' => q({0} MWt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MWt),
						'one' => q({0} MWt),
						'other' => q({0} MWt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mWt),
						'one' => q({0} mWt),
						'other' => q({0} mWt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mWt),
						'one' => q({0} mWt),
						'other' => q({0} mWt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Wt),
						'one' => q({0} Wt),
						'other' => q({0} Wt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Wt),
						'one' => q({0} Wt),
						'other' => q({0} Wt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(gPa),
						'one' => q({0} gPa),
						'other' => q({0} gPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(gPa),
						'one' => q({0} gPa),
						'other' => q({0} gPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(dý sim.süt.),
						'one' => q({0} dý sim.süt.),
						'other' => q({0} dý sim.süt.),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(dý sim.süt.),
						'one' => q({0} dý sim.süt.),
						'other' => q({0} dý sim.süt.),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/sagat),
						'one' => q({0} km/sag),
						'other' => q({0} km/sag),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/sagat),
						'one' => q({0} km/sag),
						'other' => q({0} km/sag),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(dü.),
						'one' => q({0} dü.),
						'other' => q({0} dü.),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(dü.),
						'one' => q({0} dü.),
						'other' => q({0} dü.),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metr/sek),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metr/sek),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/sag),
						'one' => q({0} mil/sag),
						'other' => q({0} mil/sag),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/sag),
						'one' => q({0} mil/sag),
						'other' => q({0} mil/sag),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}.{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}.{1}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akr-ft),
						'one' => q({0} ak-ft),
						'other' => q({0} ak-ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akr-ft),
						'one' => q({0} ak-ft),
						'other' => q({0} ak-ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(buşel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(buşel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(dý³),
						'one' => q({0} dý³),
						'other' => q({0} dý³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(dý³),
						'one' => q({0} dý³),
						'other' => q({0} dý³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ýd³),
						'one' => q({0} ýd³),
						'other' => q({0} ýd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ýd³),
						'one' => q({0} ýd³),
						'other' => q({0} ýd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(käse),
						'one' => q({0} kä),
						'other' => q({0} kä),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(käse),
						'one' => q({0} kä),
						'other' => q({0} kä),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mkä),
						'one' => q({0} mkä),
						'other' => q({0} mkä),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mkä),
						'one' => q({0} mkä),
						'other' => q({0} mkä),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram suwuklyk),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram suwuklyk),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(damja),
						'one' => q({0} damja),
						'other' => q({0} damja),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(damja),
						'one' => q({0} damja),
						'other' => q({0} damja),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(suw. uns.),
						'one' => q({0} suw. uns.),
						'other' => q({0} suw. uns.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(suw. uns.),
						'one' => q({0} suw. uns.),
						'other' => q({0} suw. uns.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(imp. suw. uns.),
						'one' => q({0} imp. suw. uns.),
						'other' => q({0} imp. suw. uns.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(imp. suw. uns.),
						'one' => q({0} imp. suw. uns.),
						'other' => q({0} imp. suw. uns.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal.),
						'one' => q({0} gal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0} imp. gal.),
						'other' => q({0} imp.gal.),
						'per' => q({0}/imp.gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0} imp. gal.),
						'other' => q({0} imp.gal.),
						'per' => q({0}/imp.gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(gl),
						'one' => q({0} gl),
						'other' => q({0} gl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(gl),
						'one' => q({0} gl),
						'other' => q({0} gl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litr),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(çümmük),
						'one' => q({0} çümmük),
						'other' => q({0} çümmük),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(çümmük),
						'one' => q({0} çümmük),
						'other' => q({0} çümmük),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kwt),
						'one' => q({0} kwt),
						'other' => q({0} kwt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kwt),
						'one' => q({0} kwt),
						'other' => q({0} kwt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kt Imp),
						'one' => q({0} kt Imp.),
						'other' => q({0} kt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kt Imp),
						'one' => q({0} kt Imp.),
						'other' => q({0} kt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(n. ç.),
						'one' => q({0} n. ç.),
						'other' => q({0} n. ç.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(n. ç.),
						'one' => q({0} n. ç.),
						'other' => q({0} n. ç.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ç. ç.),
						'one' => q({0} ç. ç.),
						'other' => q({0} ç. ç.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ç. ç.),
						'one' => q({0} ç. ç.),
						'other' => q({0} ç. ç.),
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
				end => q({0} we {1}),
				2 => q({0} we {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'nan' => q(san däl),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
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
						'negative' => '(#,##0.00)',
						'positive' => '#,##0.00',
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
			display_name => {
				'currency' => q(BAE dirhemi),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Owgan afganisi),
				'one' => q(owgan afganisi),
				'other' => q(owgan afganisi),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Alban leki),
				'one' => q(alban leki),
				'other' => q(alban leki),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Ermeni dramy),
				'one' => q(ermeni dramy),
				'other' => q(ermeni dramy),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Niderland antil guldeni),
				'one' => q(niderland antil guldeni),
				'other' => q(niderland antil guldeni),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola kwanzasy),
				'one' => q(angola kwanzasy),
				'other' => q(angola kwanzasy),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentin pesosy),
				'one' => q(argentin pesosy),
				'other' => q(argentin pesosy),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Awstraliýa dollary),
				'one' => q(awstraliýa dollary),
				'other' => q(awstraliýa dollary),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba florini),
				'one' => q(aruba florini),
				'other' => q(aruba florini),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaýjan manady),
				'one' => q(azerbaýjan manady),
				'other' => q(azerbaýjan manady),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Konwertirlenýän Bosniýa we Gersegowina markasy),
				'one' => q(konwertirlenýän bosniýa we gersegowina markasy),
				'other' => q(konwertirlenýän bosniýa we gersegowina markasy),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados dollary),
				'one' => q(barbados dollary),
				'other' => q(barbados dollary),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeş takasy),
				'one' => q(bangladeş takasy),
				'other' => q(bangladeş takasy),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bolgar lewi),
				'one' => q(bolgar lewi),
				'other' => q(bolgar lewi),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahreýn dinary),
				'one' => q(bahreýn dinary),
				'other' => q(bahreýn dinary),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi franky),
				'one' => q(burundi franky),
				'other' => q(burundi franky),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda dollary),
				'one' => q(bermuda dollary),
				'other' => q(bermuda dollary),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Bruneý dollary),
				'one' => q(bruneý dollary),
				'other' => q(bruneý dollary),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliwiýa boliwianosy),
				'one' => q(boliwiýa boliwianosy),
				'other' => q(boliwiýa boliwianosy),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazil realy),
				'one' => q(brazil realy),
				'other' => q(brazil realy),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bagama dollary),
				'one' => q(bagama dollary),
				'other' => q(bagama dollary),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butan ngultrumy),
				'one' => q(butan ngultrumy),
				'other' => q(butan ngultrumy),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswana pulasy),
				'one' => q(botswana pulasy),
				'other' => q(botswana pulasy),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Belarus rubly),
				'one' => q(belarus rubly),
				'other' => q(belarus rubly),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belorus rubly \(2000–2016\)),
				'one' => q(belorus rubly \(2000–2016\)),
				'other' => q(belorus rubly \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Beliz dollary),
				'one' => q(beliz dollary),
				'other' => q(beliz dollary),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada dollary),
				'one' => q(kanada dollary),
				'other' => q(kanada dollary),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo franky),
				'one' => q(kongo franky),
				'other' => q(kongo franky),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Şweýsar franky),
				'one' => q(şweýsar franky),
				'other' => q(şweýsar franky),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Çili pesosy),
				'one' => q(çili pesosy),
				'other' => q(çili pesosy),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Hytaý ýuany \(ofşor\)),
				'one' => q(hytaý ýuany \(ofşor\)),
				'other' => q(hytaý ýuany \(ofşor\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Hytaý ýuany),
				'one' => q(hytaý ýuany),
				'other' => q(hytaý ýuany),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbiýa pesosy),
				'one' => q(kolumbiýa pesosy),
				'other' => q(kolumbiýa pesosy),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kosta-Rika kolony),
				'one' => q(kosta-rika kolony),
				'other' => q(kosta-rika kolony),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Konwertirlenýän kuba pesosy),
				'one' => q(konwertirlenýän kuba pesosy),
				'other' => q(konwertirlenýän kuba pesosy),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kuba pesosy),
				'one' => q(kuba pesosy),
				'other' => q(kuba pesosy),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kabo-Werde eskudosy),
				'one' => q(kabo-werde eskudosy),
				'other' => q(kabo-werde eskudosy),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Çeh kronasy),
				'one' => q(çeh kronasy),
				'other' => q(çeh kronasy),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Jibuti franky),
				'one' => q(jibuti franky),
				'other' => q(jibuti franky),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Daniýa kronasy),
				'one' => q(daniýa kronasy),
				'other' => q(daniýa kronasy),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikan pesosy),
				'one' => q(dominikan pesosy),
				'other' => q(dominikan pesosy),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Alžir dinary),
				'one' => q(alžir dinary),
				'other' => q(alžir dinary),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Müsür funty),
				'one' => q(müsür funty),
				'other' => q(müsür funty),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreýa nakfasy),
				'one' => q(eritreýa nakfasy),
				'other' => q(eritreýa nakfasy),
			},
		},
		'ETB' => {
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
			display_name => {
				'currency' => q(Fiji dollary),
				'one' => q(fiji dollary),
				'other' => q(fiji dollary),
			},
		},
		'FKP' => {
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
			display_name => {
				'currency' => q(Gruzin larisi),
				'one' => q(gruzin larisi),
				'other' => q(gruzin larisi),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Gano sedisi),
				'one' => q(gano sedisi),
				'other' => q(gano sedisi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar funty),
				'one' => q(gibraltar funty),
				'other' => q(gibraltar funty),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiýa dalasisi),
				'one' => q(gambiýa dalasisi),
				'other' => q(gambiýa dalasisi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Gwineý franky),
				'one' => q(gwineý franky),
				'other' => q(gwineý franky),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Gwatemala ketsaly),
				'one' => q(gwatemala ketsaly),
				'other' => q(gwatemala ketsaly),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Gaýana dollary),
				'one' => q(gaýana dollary),
				'other' => q(gaýana dollary),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Gonkong dollary),
				'one' => q(gonkong dollary),
				'other' => q(gonkong dollary),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Gonduras lempirasy),
				'one' => q(gonduras lempirasy),
				'other' => q(gonduras lempirasy),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Horwat kunasy),
				'one' => q(horwat kunasy),
				'other' => q(horwat kunasy),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gaiti gurdy),
				'one' => q(gaiti gurdy),
				'other' => q(gaiti gurdy),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Wenger forinti),
				'one' => q(wenger forinti),
				'other' => q(wenger forinti),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indoneziýa rupiýasy),
				'one' => q(indoneziýa rupiýasy),
				'other' => q(indoneziýa rupiýasy),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Täze Ysraýyl şekeli),
				'one' => q(täze ysraýyl şekeli),
				'other' => q(täze ysraýyl şekeli),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Hindi rupiýasy),
				'one' => q(hindi rupiýasy),
				'other' => q(hindi rupiýasy),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Yrak dinary),
				'one' => q(yrak dinary),
				'other' => q(yrak dinary),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Eýran rialy),
				'one' => q(eýran rialy),
				'other' => q(eýran rialy),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Islandiýa kronasy),
				'one' => q(islandiýa kronasy),
				'other' => q(islandiýa kronasy),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Ýamaýka dollary),
				'one' => q(ýamaýka dollary),
				'other' => q(ýamaýka dollary),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Iordan dinary),
				'one' => q(iordan dinary),
				'other' => q(iordan dinary),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Ýapon ýeni),
				'one' => q(ýapon ýeni),
				'other' => q(ýapon ýeni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniýa şillingi),
				'one' => q(keniýa şillingi),
				'other' => q(keniýa şillingi),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Gyrgyz somy),
				'one' => q(gyrgyz somy),
				'other' => q(gyrgyz somy),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kamboja riýeli),
				'one' => q(kamboja riýeli),
				'other' => q(kamboja riýeli),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komor adalarynyň franky),
				'one' => q(komor adalarynyň franky),
				'other' => q(komor adalarynyň franky),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Demirgazyk Koreý wony),
				'one' => q(demirgazyk koreý wony),
				'other' => q(demirgazyk koreý wony),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Günorta Koreý wony),
				'one' => q(günorta koreý wony),
				'other' => q(günorta koreý wony),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuweýt dinary),
				'one' => q(kuweýt dinary),
				'other' => q(kuweýt dinary),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaýman adalarynyň dollary),
				'one' => q(kaýman adalarynyň dollary),
				'other' => q(kaýman adalarynyň dollary),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Gazak teňňesi),
				'one' => q(gazak teňňesi),
				'other' => q(gazak teňňesi),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laos kipi),
				'one' => q(laos kipi),
				'other' => q(laos kipi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Liwan funty),
				'one' => q(liwan funty),
				'other' => q(liwan funty),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Şri-Lanka rupiýasy),
				'one' => q(şri-lanka rupiýasy),
				'other' => q(şri-lanka rupiýasy),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiýa dollary),
				'one' => q(liberiýa dollary),
				'other' => q(liberiýa dollary),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto lotisi),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Liwiýa dinary),
				'one' => q(liwiýa dinary),
				'other' => q(liwiýa dinary),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokko dirhamy),
				'one' => q(marokko dirhamy),
				'other' => q(marokko dirhamy),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldaw leýi),
				'one' => q(moldaw leýi),
				'other' => q(moldaw leýi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasiý ariarisi),
				'one' => q(malagasiý ariarisi),
				'other' => q(malagasiý ariarisi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedon dinary),
				'one' => q(makedon dinary),
				'other' => q(makedon dinary),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Mýanma kýaty),
				'one' => q(mýanma kýaty),
				'other' => q(mýanma kýaty),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongol tugrigi),
				'one' => q(mongol tugrigi),
				'other' => q(mongol tugrigi),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makao patakasy),
				'one' => q(makao patakasy),
				'other' => q(makao patakasy),
			},
		},
		'MRO' => {
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
			display_name => {
				'currency' => q(Mawrikiý rupiýasy),
				'one' => q(mawrikiý rupiýasy),
				'other' => q(mawrikiý rupiýasy),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldiw rufiýasy),
				'one' => q(maldiw rufiýasy),
				'other' => q(maldiw rufiýasy),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi kwaçasy),
				'one' => q(malawi kwaçasy),
				'other' => q(malawi kwaçasy),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksikan pesosy),
				'one' => q(meksikan pesosy),
				'other' => q(meksikan pesosy),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaýziýa ringgiti),
				'one' => q(malaýziýa ringgiti),
				'other' => q(malaýziýa ringgiti),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambik metikaly),
				'one' => q(mozambik metikaly),
				'other' => q(mozambik metikaly),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibiýa dollary),
				'one' => q(namibiýa dollary),
				'other' => q(namibiýa dollary),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriýa naýrasy),
				'one' => q(nigeriýa naýrasy),
				'other' => q(nigeriýa naýrasy),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragua kordobasy),
				'one' => q(nikaragua kordobasy),
				'other' => q(nikaragua kordobasy),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegiýa kronasy),
				'one' => q(norwegiýa kronasy),
				'other' => q(norwegiýa kronasy),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepal rupiýasy),
				'one' => q(nepal rupiýasy),
				'other' => q(nepal rupiýasy),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Täze Zelandiýa dollary),
				'one' => q(täze zelandiýa dollary),
				'other' => q(täze zelandiýa dollary),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Oman rialy),
				'one' => q(oman rialy),
				'other' => q(oman rialy),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama balboasy),
				'one' => q(panama balboasy),
				'other' => q(panama balboasy),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru soly),
				'one' => q(peru soly),
				'other' => q(peru soly),
			},
		},
		'PGK' => {
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
			display_name => {
				'currency' => q(Päkistan rupiýasy),
				'one' => q(päkistan rupiýasy),
				'other' => q(päkistan rupiýasy),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polýak zlotysy),
				'one' => q(polýak zlotysy),
				'other' => q(polýak zlotysy),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paragwaý guaranisi),
				'one' => q(paragwaý guaranisi),
				'other' => q(paragwaý guaranisi),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar rialy),
				'one' => q(katar rialy),
				'other' => q(katar rialy),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumyn leýi),
				'one' => q(rumyn leýi),
				'other' => q(rumyn leýi),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serb dinary),
				'one' => q(serb dinary),
				'other' => q(serb dinary),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rus rubly),
				'one' => q(rus rubly),
				'other' => q(rus rubly),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda franky),
				'one' => q(ruanda franky),
				'other' => q(ruanda franky),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saud rialy),
				'one' => q(saud rialy),
				'other' => q(saud rialy),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon adalarynyň dollary),
				'one' => q(solomon adalarynyň dollary),
				'other' => q(solomon adalarynyň dollary),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seýşel rupiýasy),
				'one' => q(seýşel rupiýasy),
				'other' => q(seýşel rupiýasy),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan funty),
				'one' => q(sudan funty),
				'other' => q(sudan funty),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Şwed kronasy),
				'one' => q(şwed kronasy),
				'other' => q(şwed kronasy),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapur dollary),
				'one' => q(singapur dollary),
				'other' => q(singapur dollary),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Keramatly Ýelena adasynyň funty),
				'one' => q(keramatly ýelena adasynyň funty),
				'other' => q(keramatly ýelena adasynyň funty),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sýerra-Leone leony),
				'one' => q(sýerra-leone leony),
				'other' => q(sýerra-leone leony),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sýerra-Leone leony \(1964—2022\)),
				'one' => q(sýerra-leone leony \(1964—2022\)),
				'other' => q(sýerra-leone leony \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali şillingi),
				'one' => q(somali şillingi),
				'other' => q(somali şillingi),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam dollary),
				'one' => q(surinam dollary),
				'other' => q(surinam dollary),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Günorta Sudan funty),
				'one' => q(günorta sudan funty),
				'other' => q(günorta sudan funty),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(San-Tome we Prinsipi dobrasy \(1977–2017\)),
				'one' => q(san-tome we prinsipi dobrasy \(1977–2017\)),
				'other' => q(san-tome we prinsipi dobrasy \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(San-Tome we Prinsipi dobrasy),
				'one' => q(san-tome we prinsipi dobrasy),
				'other' => q(san-tome we prinsipi dobrasy),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Siriýa funty),
				'one' => q(siriýa funty),
				'other' => q(siriýa funty),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazi lilangeni),
				'one' => q(swazi lilangeni),
				'other' => q(swazi lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Taýland baty),
				'one' => q(taýland baty),
				'other' => q(taýland baty),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Täjik somonisi),
				'one' => q(täjik somonisi),
				'other' => q(täjik somonisi),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Türkmen manady),
				'one' => q(türkmen manady),
				'other' => q(türkmen manady),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunis dinary),
				'one' => q(tunis dinary),
				'other' => q(tunis dinary),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonga paangasy),
				'one' => q(tonga paangasy),
				'other' => q(tonga paangasy),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Türk lirasy),
				'one' => q(türk lirasy),
				'other' => q(türk lirasy),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trininad we Tobago dollary),
				'one' => q(trininad we tobago dollary),
				'other' => q(trininad we tobago dollary),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Täze Taýwan dollary),
				'one' => q(täze taýwan dollary),
				'other' => q(täze taýwan dollary),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniýa şillingi),
				'one' => q(tanzaniýa şillingi),
				'other' => q(tanzaniýa şillingi),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrain griwnasy),
				'one' => q(ukrain griwnasy),
				'other' => q(ukrain griwnasy),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda şillingi),
				'one' => q(uganda şillingi),
				'other' => q(uganda şillingi),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ABŞ dollary),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Urugwaý pesosy),
				'one' => q(urugwaý pesosy),
				'other' => q(urugwaý pesosy),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Özbek somy),
				'one' => q(özbek somy),
				'other' => q(özbek somy),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Wenesuela boliwary \(2008–2018\)),
				'one' => q(wenesuela boliwary \(2008–2018\)),
				'other' => q(wenesuela boliwary \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Wenesuela boliwary),
				'one' => q(wenesuela boliwary),
				'other' => q(wenesuela boliwary),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Wýetnam dongy),
				'one' => q(wýetnam dongy),
				'other' => q(wýetnam dongy),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Wanuatu watusy),
				'one' => q(wanuatu watusy),
				'other' => q(wanuatu watusy),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa talasy),
				'one' => q(samoa talasy),
				'other' => q(samoa talasy),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(KFA BEAC franky),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Gündogar karib dollary),
				'one' => q(gündogar karib dollary),
				'other' => q(gündogar karib dollary),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(KFA BCEAO franky),
			},
		},
		'XPF' => {
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
			display_name => {
				'currency' => q(Ýemen rialy),
				'one' => q(ýemen rialy),
				'other' => q(ýemen rialy),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Günorta Afrika rendi),
				'one' => q(günorta afrika rendi),
				'other' => q(günorta afrika rendi),
			},
		},
		'ZMW' => {
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
							'Mar',
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
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Aşy',
							'Sap',
							'Tir I',
							'Tir II',
							'Tir III',
							'Tir IV',
							'Rej',
							'Mer',
							'Ora',
							'Baý',
							'Boş',
							'Gur'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Aşyr',
							'Sapar',
							'Dört tirkeşik 1',
							'Dört tirkeşik 2',
							'Dört tirkeşik 3',
							'Dört tirkeşik 4',
							'Rejep',
							'Meret',
							'Oraza',
							'Baýram',
							'Boş aý',
							'Gurban'
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
						mon => 'duş',
						tue => 'siş',
						wed => 'çar',
						thu => 'pen',
						fri => 'ann',
						sat => 'şen',
						sun => 'ýek'
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
				'abbreviated' => {
					'am' => q{g.öň},
					'pm' => q{g.soň},
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
		'islamic' => {
			abbreviated => {
				'0' => 'HS'
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
		'islamic' => {
			'full' => q{EEEE, d MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
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
		'islamic' => {
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			MEd => q{dd.MM E},
			MMMEd => q{d MMM E},
			MMMMEd => q{d MMMM E},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{dd.MM.y E},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
		},
		'gregorian' => {
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y E},
			GyMMMd => q{G d MMM y},
			GyMd => q{GGGGG dd.MM.y},
			MEd => q{dd.MM E},
			MMMEd => q{d MMM E},
			MMMMEd => q{d MMMM E},
			MMMMW => q{'hepde' W, MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			yM => q{MM.y},
			yMEd => q{dd.MM.y E},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y E},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yw => q{'hepde' w, Y},
		},
		'islamic' => {
			Ed => q{d, E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{d MMMM, E},
			Md => q{d/M},
			y => q{y G},
			yMMM => q{MMM, y},
			yMMMEd => q{d MMM, y, E},
			yMMMM => q{MMMM, y},
			yMMMd => q{d MMM, y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM, y G},
			yyyyMMMM => q{MMMM, y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ, y G},
			yyyyQQQQ => q{QQQQ, y G},
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
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{dd.MM E – dd.MM E},
				d => q{dd.MM E – dd.MM E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d MMM E – d MMM E},
				d => q{d MMM E – d MMM E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y E – dd.MM.y E},
				d => q{dd.MM.y E – dd.MM.y E},
				y => q{dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y E – d MMM y E},
				d => q{d MMM y E – d MMM y E},
				y => q{d MMM y E – d MMM y E},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
			},
			GyM => {
				G => q{GGGGG M/y – GGGGG M/y},
				M => q{GGGGG M/y – M/y},
				y => q{GGGGG M/y – M/y},
			},
			GyMEd => {
				G => q{GGGGG dd.MM.y, E – GGGGG dd.MM.y, E},
				M => q{GGGGG dd.MM.y, E – dd.MM.y, E},
				d => q{GGGGG dd.MM.y, E – dd.MM.y, E},
				y => q{GGGGG dd.MM.y, E – dd.MM.y, E},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM–MMM y},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G d MMM y, E – G d MMM y, E},
				M => q{G d MMM, E – d MMM, E y},
				d => q{G d MMM y, E – d MMM y, E},
				y => q{G d MMM y, E – d MMM y, E},
			},
			GyMMMd => {
				G => q{G d MMM y – G d MMM y},
				M => q{G d MMM – d MMM y},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			GyMd => {
				G => q{GGGGG dd.MM.y – GGGGG dd.MM.y},
				M => q{GGGGG dd.MM.y – dd.MM.y},
				d => q{GGGGG dd.MM.y – dd.MM.y},
				y => q{GGGGG dd.MM.y – dd.MM.y},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{dd.MM E – dd.MM E},
				d => q{dd.MM E – dd.MM E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{d MMM E – d MMM E},
				d => q{d MMM E – d MMM E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y E – dd.MM.y E},
				d => q{dd.MM.y E – dd.MM.y E},
				y => q{dd.MM.y E – dd.MM.y E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y E – d MMM y E},
				d => q{d MMM y E – d MMM y E},
				y => q{d MMM y E – d MMM y E},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} wagty),
		regionFormat => q({0} tomusky wagty),
		regionFormat => q({0} standart wagty),
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
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
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
		'Africa/Johannesburg' => {
			exemplarCity => q#Ýohannesburg#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Hartum#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinşasa#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librewil#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaşi#,
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
				'generic' => q#Amazon wagty#,
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
		'America/Araguaina' => {
			exemplarCity => q#Araguaýna#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La-Rioha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio-Galegos#,
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
		'America/Asuncion' => {
			exemplarCity => q#Asunsýon#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baiýa#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Baiýa-de-Banderas#,
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
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Sýudad-Huares#,
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
		'America/Eirunepe' => {
			exemplarCity => q#Eýrunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salwador#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Gleýs-Beý#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gus-Beý#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand-Terk#,
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
		'America/Marigot' => {
			exemplarCity => q#Marigo#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
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
		'America/New_York' => {
			exemplarCity => q#Nýu-Ýork#,
		},
		'America/Nome' => {
			exemplarCity => q#Nom#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Boýla, Demirgazyk Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sentr, Demirgazyk Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nýu-Salem, Demirgazyk Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ohinaga#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtang#,
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
			exemplarCity => q#Rezolýut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riu-Branku#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa-Izabel#,
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
		'America/St_Barthelemy' => {
			exemplarCity => q#Sen-Bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent-Jons#,
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
		'America/Vancouver' => {
			exemplarCity => q#Wankuwer#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Waýthors#,
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
		'Anadyr' => {
			long => {
				'generic' => q#Anadyr wagty#,
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
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdat#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahreýn#,
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
		'Asia/Dubai' => {
			exemplarCity => q#Dubaý#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duşanbe#,
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
		'Asia/Jayapura' => {
			exemplarCity => q#Jaýapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Iýerusalim#,
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
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiýa#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuznesk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnompen#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Phenýan#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaý#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Gyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ýangon#,
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
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Şanhaý#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taýbeý#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taşkent#,
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
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan-Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumçi#,
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
		'Australia/Eucla' => {
			exemplarCity => q#Ýukla#,
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
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Afiny#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
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
			long => {
				'daylight' => q#Irlandiýa standart wagty#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernsi#,
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
			long => {
				'daylight' => q#Beýik Britaniýa tomusky wagty#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lýuksemburg#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariýehamn#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
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
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
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
				'standard' => q#Grinwiç ortaça wagty#,
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
				'standard' => q#Gilbert adalary wagty#,
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
		'Kamchatka' => {
			long => {
				'generic' => q#Petropavlowsk-Kamçatskiý wagty#,
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
				'daylight' => q#Norfolk adasy tomusky wagty#,
				'generic' => q#Norfolk adasy wagty#,
				'standard' => q#Norfolk adasy standart wagty#,
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
			exemplarCity => q#Pasha adasy#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderberi#,
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
		'Pacific/Honolulu' => {
			exemplarCity => q#Gonolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jonston#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosraýe#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajaleýn#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz adalary#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midueý#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago-Pago#,
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
		'Pacific/Saipan' => {
			exemplarCity => q#Saýpan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taiti#,
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
		'Samara' => {
			long => {
				'generic' => q#Samara wagty#,
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
		'Yukon' => {
			long => {
				'standard' => q#Ýukon wagty#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
